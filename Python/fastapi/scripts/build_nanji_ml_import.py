from __future__ import annotations

import csv
import json
from dataclasses import asdict, dataclass
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional


SOURCE_CSV = Path("/Users/electrozone/Documents/GitHub/nanji_work/hmw/Note/nanji_outputs_change/nanji_test_predictions.csv")
BASE_SOURCE_CSV = Path("/Users/electrozone/Documents/GitHub/nanji_work/Data/processed/nanji_hourly_model_dataset_2020_2026_update.csv")
OUTPUT_DIR = Path("/Users/electrozone/Documents/GitHub/nanji_app/Python/fastapi/data/ml_ready")
OUTPUT_CSV = OUTPUT_DIR / "nanji_group_predictions_for_fastapi.csv"
OUTPUT_JSON = OUTPUT_DIR / "nanji_group_predictions_for_fastapi.json"


@dataclass
class ServicePredictionRow:
    parking_group: str
    base_time: str
    predicted_time: str
    prediction_horizon_minutes: int
    predicted_delta: float
    base_occupied_spaces: float
    confidence_score: str
    model_version: str
    source_file: str


def _pick_first(source_row: dict[str, str], *keys: str) -> Optional[str]:
    for key in keys:
        value = source_row.get(key)
        if value is not None and str(value).strip() != "":
            return str(value).strip()
    return None


def load_base_occupied_map() -> dict[str, float]:
    if not BASE_SOURCE_CSV.exists():
        raise FileNotFoundError(f"Base source CSV not found: {BASE_SOURCE_CSV}")

    occupied_by_datetime: dict[str, float] = {}

    with BASE_SOURCE_CSV.open("r", encoding="utf-8-sig", newline="") as file:
        reader = csv.DictReader(file)
        for row in reader:
            dt_key = str(row.get("datetime", "")).strip()
            occupied_raw = _pick_first(row, "realtime_current_parking")
            if not dt_key or occupied_raw is None:
                continue
            occupied_by_datetime[dt_key] = float(occupied_raw)

    if not occupied_by_datetime:
        raise ValueError("Base source CSV에서 realtime_current_parking 기준값을 찾지 못했습니다.")

    return occupied_by_datetime


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    rows: list[ServicePredictionRow] = []
    occupied_by_datetime = load_base_occupied_map()

    with SOURCE_CSV.open("r", encoding="utf-8-sig", newline="") as file:
        reader = csv.DictReader(file)
        for source_row in reader:
            predicted_at = datetime.strptime(source_row["datetime"], "%Y-%m-%d %H:%M:%S")

            # 현재 받은 산출물은 테스트 예측 결과라서 base_time이 없으므로
            # predicted_time 기준 1시간 전을 base_time으로 사용한다.
            base_time = predicted_at - timedelta(hours=1)

            delta_value = _pick_first(source_row, "predicted_delta", "delta_from_previous_hour", "weighted_core_prediction")
            if delta_value is None:
                raise ValueError(
                    "변화량 기반 반입을 위해 source CSV에 `predicted_delta` 또는 "
                    "`weighted_core_prediction` 컬럼이 필요합니다."
                )

            base_occupied_value = _pick_first(source_row, "base_occupied_spaces")
            if base_occupied_value is None:
                base_time_key = base_time.strftime("%Y-%m-%d %H:%M:%S")
                matched_value = occupied_by_datetime.get(base_time_key)
                if matched_value is None:
                    raise ValueError(
                        "변화량 기반 예측을 절대 점유 대수로 복원하려면 "
                        f"base_time={base_time_key} 기준의 realtime_current_parking 값이 필요합니다."
                    )
                base_occupied_value = str(matched_value)

            horizon_minutes = int(_pick_first(source_row, "prediction_horizon_minutes") or "60")
            confidence_score = _pick_first(source_row, "confidence_score") or ""
            model_version = _pick_first(source_row, "model_version") or "weighted_delta_v1_test_import"

            rows.append(
                ServicePredictionRow(
                    parking_group="난지전체",
                    base_time=base_time.strftime("%Y-%m-%d %H:%M:%S"),
                    predicted_time=predicted_at.strftime("%Y-%m-%d %H:%M:%S"),
                    prediction_horizon_minutes=horizon_minutes,
                    predicted_delta=round(float(delta_value), 4),
                    base_occupied_spaces=round(float(base_occupied_value), 4),
                    confidence_score=confidence_score,
                    model_version=model_version,
                    source_file=SOURCE_CSV.name,
                )
            )

    with OUTPUT_CSV.open("w", encoding="utf-8", newline="") as file:
        writer = csv.DictWriter(file, fieldnames=list(asdict(rows[0]).keys()))
        writer.writeheader()
        for row in rows:
            writer.writerow(asdict(row))

    with OUTPUT_JSON.open("w", encoding="utf-8") as file:
        json.dump([asdict(row) for row in rows], file, ensure_ascii=False, indent=2)

    print(f"source_rows={len(rows)}")
    print(f"csv={OUTPUT_CSV}")
    print(f"json={OUTPUT_JSON}")


if __name__ == "__main__":
    main()
