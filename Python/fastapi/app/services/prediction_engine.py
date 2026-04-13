from __future__ import annotations

from dataclasses import dataclass
from datetime import date, datetime, time, timedelta
from decimal import Decimal
from functools import lru_cache
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.linear_model import Ridge
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler

from app.models.parking import ParkingLot, ParkingStatusLog
from app.schemas.prediction import ParkingPredictionItem


NANJI_WORK_ROOT = Path("/Users/electrozone/Documents/GitHub/nanji_work")
DATASET_PATH = NANJI_WORK_ROOT / "ksm/nanji_hourly_modeling/nanji_hourly_model_dataset_2020_2026.csv"
WEATHER_DIR = NANJI_WORK_ROOT / "ose/Data"
WEIGHT_TABLE_PATH = NANJI_WORK_ROOT / "hmw/Note/nanji_outputs_change/nanji_weight_table.csv"

MODEL_VERSION = "weather_only_extended_final_live"
OPERATING_HOURS = set(range(6, 24))
MODEL_ALPHA = 100.0
FEATURE_COLUMNS = [
    "pattern_prior",
    "month_weight",
    "hour_weight",
    "day_type_offday",
    "hour_sin",
    "hour_cos",
    "month_sin",
    "month_cos",
    "is_holiday",
    "wind_gusts_10m",
]


@dataclass(frozen=True)
class GeneratedPrediction:
    base_time: datetime
    predicted_time: datetime
    occupied_spaces: int
    available_spaces: int
    occupancy_rate: Decimal
    congestion_level: str


class NanjiPredictionEngine:
    def __init__(self) -> None:
        self.weight_maps = self._load_weight_maps()
        self.base_value_map = self._build_base_value_map()
        self.dataset = self._load_dataset()
        self.weather_lookup = self._build_weather_lookup()
        self.feature_medians = self.dataset[FEATURE_COLUMNS].median(numeric_only=True).to_dict()
        self.model = self._train_model()

    def _load_dataset(self) -> pd.DataFrame:
        df = pd.read_csv(
            DATASET_PATH,
            parse_dates=["datetime", "date"],
            usecols=[
                "datetime",
                "date",
                "hour",
                "year",
                "month",
                "is_weekend",
                "is_holiday",
                "is_holiday_or_weekend",
                "estimated_active_cars_change",
            ],
        )
        df = df[df["year"].between(2022, 2025)].copy()

        weather_frames = []
        for year in range(2022, 2027):
            weather_path = WEATHER_DIR / f"open_meteo_nanji_{year}.csv"
            if weather_path.exists():
                weather_frames.append(
                    pd.read_csv(weather_path, parse_dates=["datetime"], usecols=["datetime", "wind_gusts_10m"])
                )

        weather_df = pd.concat(weather_frames, ignore_index=True).drop_duplicates("datetime")
        df = df.merge(weather_df, on="datetime", how="left")

        df["day_type_offday"] = df["is_holiday_or_weekend"].astype(int)
        df["month_weight"] = df["month"].map(self.weight_maps["month_weight"]).fillna(1.0)
        df["hour_weight"] = df["hour"].map(self.weight_maps["hour_weight"]).fillna(1.0)
        df["base_value"] = [
            self.base_value_map.get((int(day_type_offday), int(hour)), 0.0)
            for day_type_offday, hour in zip(df["day_type_offday"], df["hour"])
        ]
        df["pattern_prior"] = df["base_value"] * df["month_weight"] * df["hour_weight"]
        df["hour_sin"] = np.sin(2 * np.pi * df["hour"] / 24.0)
        df["hour_cos"] = np.cos(2 * np.pi * df["hour"] / 24.0)
        df["month_sin"] = np.sin(2 * np.pi * df["month"] / 12.0)
        df["month_cos"] = np.cos(2 * np.pi * df["month"] / 12.0)
        df["is_holiday"] = df["is_holiday"].astype(int)
        df["wind_gusts_10m"] = pd.to_numeric(df["wind_gusts_10m"], errors="coerce")
        return df

    def _load_weight_maps(self) -> dict[str, dict[int, float]]:
        weight_df = pd.read_csv(WEIGHT_TABLE_PATH)
        month_weight = (
            weight_df[weight_df["weight_type"] == "month_weight"]
            .set_index("key")["value"]
            .astype(float)
            .to_dict()
        )
        hour_weight = (
            weight_df[weight_df["weight_type"] == "hour_weight"]
            .set_index("key")["value"]
            .astype(float)
            .to_dict()
        )
        return {
            "month_weight": {int(key): float(value) for key, value in month_weight.items()},
            "hour_weight": {int(key): float(value) for key, value in hour_weight.items()},
        }

    def _build_base_value_map(self) -> dict[tuple[int, int], float]:
        base_df = self.dataset if hasattr(self, "dataset") else pd.read_csv(
            DATASET_PATH,
            usecols=["hour", "year", "is_holiday_or_weekend", "estimated_active_cars_change"],
        )
        train_df = base_df[base_df["year"].between(2022, 2023)].copy()
        train_df["day_type_offday"] = train_df["is_holiday_or_weekend"].astype(int)
        grouped = (
            train_df.groupby(["day_type_offday", "hour"], as_index=False)["estimated_active_cars_change"]
            .mean()
        )
        return {
            (int(row.day_type_offday), int(row.hour)): float(row.estimated_active_cars_change)
            for row in grouped.itertuples(index=False)
        }

    def _build_weather_lookup(self) -> dict[str, object]:
        weather_frames = []
        for year in range(2022, 2027):
            weather_path = WEATHER_DIR / f"open_meteo_nanji_{year}.csv"
            if weather_path.exists():
                weather_frames.append(
                    pd.read_csv(weather_path, parse_dates=["datetime"], usecols=["datetime", "wind_gusts_10m"])
                )

        weather_df = pd.concat(weather_frames, ignore_index=True).drop_duplicates("datetime")
        weather_df["month"] = weather_df["datetime"].dt.month
        weather_df["day"] = weather_df["datetime"].dt.day
        weather_df["hour"] = weather_df["datetime"].dt.hour

        exact = (
            weather_df.dropna(subset=["wind_gusts_10m"])
            .set_index("datetime")["wind_gusts_10m"]
            .astype(float)
            .to_dict()
        )
        month_day_hour = (
            weather_df.groupby(["month", "day", "hour"], as_index=False)["wind_gusts_10m"]
            .median()
        )
        hour_only = weather_df.groupby("hour", as_index=False)["wind_gusts_10m"].median()

        return {
            "exact": exact,
            "month_day_hour": {
                (int(row.month), int(row.day), int(row.hour)): float(row.wind_gusts_10m)
                for row in month_day_hour.itertuples(index=False)
                if not pd.isna(row.wind_gusts_10m)
            },
            "hour_only": {
                int(row.hour): float(row.wind_gusts_10m)
                for row in hour_only.itertuples(index=False)
                if not pd.isna(row.wind_gusts_10m)
            },
        }

    def _train_model(self) -> Pipeline:
        train_df = self.dataset.copy()
        feature_frame = train_df[FEATURE_COLUMNS].copy()
        for column, median in self.feature_medians.items():
            feature_frame[column] = feature_frame[column].fillna(median)

        model = Pipeline(
            steps=[
                ("scaler", StandardScaler()),
                ("ridge", Ridge(alpha=MODEL_ALPHA)),
            ]
        )
        model.fit(feature_frame, train_df["estimated_active_cars_change"].astype(float))
        return model

    def _wind_gust_for(self, timestamp: datetime) -> float:
        exact = self.weather_lookup["exact"].get(timestamp)
        if exact is not None:
            return float(exact)

        month_day_hour = self.weather_lookup["month_day_hour"].get((timestamp.month, timestamp.day, timestamp.hour))
        if month_day_hour is not None:
            return float(month_day_hour)

        return float(self.weather_lookup["hour_only"].get(timestamp.hour, 0.0))

    def _is_holiday(self, timestamp: datetime) -> int:
        exact_row = self.dataset[self.dataset["datetime"] == timestamp]
        if not exact_row.empty:
            return int(exact_row.iloc[0]["is_holiday"])
        return 0

    def _is_offday(self, timestamp: datetime) -> int:
        exact_row = self.dataset[self.dataset["datetime"] == timestamp]
        if not exact_row.empty:
            return int(exact_row.iloc[0]["day_type_offday"])
        return 1 if timestamp.weekday() >= 5 else 0

    def _feature_row_for(self, timestamp: datetime) -> pd.DataFrame:
        day_type_offday = self._is_offday(timestamp)
        hour = timestamp.hour
        month = timestamp.month
        feature_row = {
            "pattern_prior": self.base_value_map.get((day_type_offday, hour), 0.0)
            * self.weight_maps["month_weight"].get(month, 1.0)
            * self.weight_maps["hour_weight"].get(hour, 1.0),
            "month_weight": self.weight_maps["month_weight"].get(month, 1.0),
            "hour_weight": self.weight_maps["hour_weight"].get(hour, 1.0),
            "day_type_offday": day_type_offday,
            "hour_sin": float(np.sin(2 * np.pi * hour / 24.0)),
            "hour_cos": float(np.cos(2 * np.pi * hour / 24.0)),
            "month_sin": float(np.sin(2 * np.pi * month / 12.0)),
            "month_cos": float(np.cos(2 * np.pi * month / 12.0)),
            "is_holiday": self._is_holiday(timestamp),
            "wind_gusts_10m": self._wind_gust_for(timestamp),
        }
        frame = pd.DataFrame([feature_row], columns=FEATURE_COLUMNS)
        for column, median in self.feature_medians.items():
            frame[column] = frame[column].fillna(median)
        return frame

    def generate_predictions(
        self,
        parking_lot: ParkingLot,
        latest_status: ParkingStatusLog,
        target_date: date,
        limit: int,
    ) -> list[GeneratedPrediction]:
        base_hour = latest_status.ps_recorded_at.replace(minute=0, second=0, microsecond=0)
        end_time = datetime.combine(target_date, time(hour=23))
        if end_time <= base_hour:
            return []

        total_spaces = max(
            0,
            latest_status.ps_occupied_spaces + latest_status.ps_available_spaces,
        ) or int(parking_lot.p_total_spaces)
        current_occupied = int(latest_status.ps_occupied_spaces)
        generated: list[GeneratedPrediction] = []
        cursor = base_hour

        while cursor < end_time and len(generated) < limit:
            predicted_time = cursor + timedelta(hours=1)
            delta = float(self.model.predict(self._feature_row_for(predicted_time))[0])
            current_occupied = max(0, min(total_spaces, int(round(current_occupied + delta))))
            occupancy_rate = (
                Decimal("0.00")
                if total_spaces == 0
                else (Decimal(current_occupied) * Decimal("100") / Decimal(total_spaces)).quantize(Decimal("0.01"))
            )
            available_spaces = max(0, total_spaces - current_occupied)

            if predicted_time.date() == target_date:
                generated.append(
                    GeneratedPrediction(
                        base_time=cursor,
                        predicted_time=predicted_time,
                        occupied_spaces=current_occupied,
                        available_spaces=available_spaces,
                        occupancy_rate=occupancy_rate,
                        congestion_level=self._classify_congestion(occupancy_rate),
                    )
                )

            cursor = predicted_time

        return generated

    @staticmethod
    def _classify_congestion(occupancy_rate: Decimal) -> str:
        if occupancy_rate >= Decimal("90"):
            return "very_busy"
        if occupancy_rate >= Decimal("70"):
            return "busy"
        if occupancy_rate >= Decimal("40"):
            return "normal"
        return "free"


def generated_prediction_to_item(
    parking_lot_id: int,
    generated_prediction: GeneratedPrediction,
    index: int,
) -> ParkingPredictionItem:
    return ParkingPredictionItem(
        pp_id=-(index + 1),
        pp_parking_lot_id=parking_lot_id,
        pp_base_time=generated_prediction.base_time.strftime("%Y-%m-%d %H:%M:%S"),
        pp_predicted_time=generated_prediction.predicted_time.strftime("%Y-%m-%d %H:%M:%S"),
        pp_prediction_horizon_minutes=int((generated_prediction.predicted_time - generated_prediction.base_time).total_seconds() // 60),
        pp_predicted_occupied_spaces=generated_prediction.occupied_spaces,
        pp_predicted_available_spaces=generated_prediction.available_spaces,
        pp_predicted_occupancy_rate=generated_prediction.occupancy_rate,
        pp_predicted_congestion_level=generated_prediction.congestion_level,
        pp_confidence_score=None,
        pp_model_version=MODEL_VERSION,
    )


@lru_cache(maxsize=1)
def get_prediction_engine() -> NanjiPredictionEngine:
    return NanjiPredictionEngine()
