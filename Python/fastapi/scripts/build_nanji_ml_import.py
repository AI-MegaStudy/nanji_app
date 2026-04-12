from __future__ import annotations

import csv
import json
from dataclasses import asdict, dataclass
from datetime import datetime, timedelta
from pathlib import Path


SOURCE_CSV = Path("/Users/electrozone/Documents/GitHub/nanji_work/hmw/Note/nanji_outputs/nanji_test_predictions.csv")
OUTPUT_DIR = Path("/Users/electrozone/Documents/GitHub/nanji_app/Python/fastapi/data/ml_ready")
OUTPUT_CSV = OUTPUT_DIR / "nanji_group_predictions_for_fastapi.csv"
OUTPUT_JSON = OUTPUT_DIR / "nanji_group_predictions_for_fastapi.json"


@dataclass
class ServicePredictionRow:
    parking_group: str
    base_time: str
    predicted_time: str
    prediction_horizon_minutes: int
    estimated_active_cars: float
    confidence_score: str
    model_version: str
    source_file: str


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    rows: list[ServicePredictionRow] = []

    with SOURCE_CSV.open("r", encoding="utf-8-sig", newline="") as file:
        reader = csv.DictReader(file)
        for source_row in reader:
            predicted_at = datetime.strptime(source_row["datetime"], "%Y-%m-%d %H:%M:%S")

            # 현재 받은 산출물은 서비스용 배치 예측 포맷이 아니라 테스트 예측 결과라서
            # base_time이 명시되어 있지 않다. 일단 1시간 전 예측으로 가정해 FastAPI 테스트용
            # 포맷을 만든다. 운영 반영 전에는 ML 담당자에게 실제 base_time 제공을 요청해야 한다.
            base_time = predicted_at - timedelta(hours=1)

            rows.append(
                ServicePredictionRow(
                    parking_group="난지전체",
                    base_time=base_time.strftime("%Y-%m-%d %H:%M:%S"),
                    predicted_time=predicted_at.strftime("%Y-%m-%d %H:%M:%S"),
                    prediction_horizon_minutes=60,
                    estimated_active_cars=round(float(source_row["weighted_core_prediction"]), 4),
                    confidence_score="",
                    model_version="weighted_core_v1_test_import",
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
