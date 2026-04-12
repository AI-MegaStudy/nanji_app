# 자리난지 실시간 기준 대수 수집 가이드

## 목적
- 변화량 예측 모델의 `predicted_delta`를 절대 점유 대수로 복원하려면 기준 시점 실제 점유 대수(`base_occupied_spaces`)가 필요하다.
- 이를 위해 난지 현재 주차 대수를 주기적으로 수집해 `parking_status_log`에 저장한다.

## 현재 기준 소스
- 한강공원 통합주차포털 난지 페이지의 `난지1,2,3,4주차장` 행을 직접 읽는다.
- 사용 필드:
  - `주차가능대수`
  - `주차구획수(계)`
- 계산 방식:
  - `occupied_spaces = total_spaces - available_spaces`
  - `available_spaces = 주차가능대수`

## 현재 구현 위치
- 스크립트: [collect_nanji_realtime_status.py](/Users/electrozone/Documents/GitHub/nanji_app/Python/fastapi/scripts/collect_nanji_realtime_status.py)
- 기본 대상 row: `난지1,2,3,4주차장`
- 기본 적재 대상 `parking_lot`: `p_id = 1`
- 기본 페이지 URL: `https://www.ihangangpark.kr/parking/region/region9`

## 실행 전 준비
- 별도 인증키는 필요하지 않다.

## 실행 방법
```bash
cd /Users/electrozone/Documents/GitHub/nanji_app/Python/fastapi
source .venv/bin/activate
python scripts/collect_nanji_realtime_status.py --dry-run
python scripts/collect_nanji_realtime_status.py
```

## 적재 방식
- 난지 페이지 HTML에서 `난지1,2,3,4주차장` 행을 찾는다.
- `주차가능대수`를 현재 남은 자리 수로 사용한다.
- `주차구획수(계)`를 총 주차면 수로 사용한다.
- 아래 필드를 계산해 `parking_status_log`에 저장한다.
  - `ps_occupied_spaces`
  - `ps_available_spaces`
  - `ps_occupancy_rate`
  - `ps_congestion_level`
  - `ps_source_type = ihangangpark_site`

## 변화량 예측과의 연결
- ML 모델은 `predicted_delta`를 낸다.
- FastAPI 반입 단계는 가장 가까운 기준 시점 실제 대수를 잡고 delta를 누적해 절대 점유 대수를 복원한다.
- 따라서 이 실시간 수집 로그는 앞으로 생성되는 예측의 기준값 풀로 사용된다.

## 주의사항
- 이 구조는 앞으로의 운영용 기준값을 쌓는 데 적합하다.
- 이미 만들어진 과거 배치 예측의 모든 `base_time`을 자동으로 복원해주지는 않는다.
- 과거 예측을 정확히 복원하려면 당시 시점의 기준값 로그가 이미 저장돼 있어야 한다.

## 권장 운영 방식
- 5분 또는 10분 주기로 스크립트를 실행한다.
- 최소 1시간 단위라도 꾸준히 쌓이면 변화량 예측 복원 안정성이 올라간다.
- 운영이 자리잡으면 cron 또는 배치 작업으로 자동화한다.
- 사이트 구조가 바뀌면 파싱 로직을 함께 점검한다.
