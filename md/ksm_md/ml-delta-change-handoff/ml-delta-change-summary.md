# 자리난지 ML 변화량 전환 작업 정리

## 문서 목적
- ML 담당자가 `절대 점유 대수 예측`에서 `전 시간 대비 변화량 예측`으로 타깃을 변경해달라고 요청한 시점부터,
- FastAPI 반입 구조 수정, 예측 데이터 재적재, 실시간 기준값 수집 방식 결정, 자동 적재 설정까지의 내용을 한 문서에서 정리한다.

## 변경 요청 배경
- 기존 ML 구조:
  - 각 시점의 절대 점유 대수 예측
- 변경된 ML 구조:
  - 전 시간 대비 변화량 예측

즉 ML 출력이 더 이상 특정 시점의 절대 점유 대수가 아니라,
이전 시점 대비 몇 대가 증가하거나 감소하는지에 대한 값으로 바뀌었다.

## 왜 수정이 필요했는가
- 앱과 웹은 여전히 아래 절대값 필드를 사용한다.
  - `pp_predicted_occupied_spaces`
  - `pp_predicted_available_spaces`
  - `pp_predicted_occupancy_rate`
  - `pp_predicted_congestion_level`
- 따라서 변화량 예측값을 그대로 DB나 API에 넣으면 앱/웹 UI와 의미가 맞지 않는다.

## 최종 결정
- 앱 UI는 바꾸지 않는다.
- 관리자 웹 UI도 바꾸지 않는다.
- DB 스키마도 바꾸지 않는다.
- 대신 FastAPI 반입 단계에서
  - `predicted_delta`
  - `base_occupied_spaces`
  를 이용해 절대 점유 대수를 복원한 뒤 기존 `parking_prediction` 필드를 유지한다.

한 줄 요약:
- `ML 변화량 출력 -> FastAPI 누적 복원 -> DB 절대값 저장 -> 앱/웹 기존 구조 유지`

## hmw 저장소에서 확인한 변경점
- 변경 노트북:
  - `/Users/electrozone/Documents/GitHub/nanji_work/hmw/Note/nanji_ML_change.ipynb`
- 변경 산출물:
  - `/Users/electrozone/Documents/GitHub/nanji_work/hmw/Note/nanji_outputs_change/nanji_test_predictions.csv`
- 핵심 차이:
  - 예전: `estimated_active_cars`
  - 변경 후: `estimated_active_cars_change`

즉 컬럼 이름 수준이 아니라, 예측 결과의 의미 자체가 절대값에서 변화량으로 바뀌었다.

## base_occupied_spaces 확보 논의
처음에는 아래 후보를 검토했다.

1. ML 담당자가 `base_occupied_spaces`를 직접 포함해서 산출물 재전달
2. 서울 Open API를 이용해 현재값 수집
3. 한강공원 통합주차포털의 `주차가능대수`를 직접 수집
4. `hmw` 내부 가공 데이터셋의 `realtime_current_parking` 사용

### 중간에 확인한 내용
- 서울 Open API `GetParkingInfo`에서 `난지`로 잡히는 row는 `난지중앙로노상공영주차장(시)` 한 개뿐이었고,
  총 면수도 `34`로 나와 서비스에서 쓰는 `난지1,2,3,4주차장` 대표값으로 보기 어려웠다.
- 반면 한강공원 통합주차포털 `region9` 페이지에는 `난지1,2,3,4주차장` 행이 직접 내려오고,
  `주차가능대수`, `주차구획수(계)`를 바로 읽을 수 있었다.
- `hmw` 가공 데이터셋에도 아래 컬럼이 확인되었다.
  - `realtime_current_parking`
  - `realtime_total_capacity`

### 실제 반영된 결정
작업은 두 갈래로 나눴다.

1. **예측 데이터 재적재용 기준값**
- `hmw` 가공 데이터셋의 `realtime_current_parking`를 사용

2. **앞으로 주기적으로 쌓을 운영용 실시간 기준값**
- 한강공원 통합주차포털 `region9` 페이지의 `주차가능대수`를 크롤링해 `parking_status_log`에 적재

## 이번에 수정한 주요 코드

### 1. FastAPI 반입 스크립트
- [build_nanji_ml_import.py](/Users/electrozone/Documents/GitHub/nanji_app/Python/fastapi/scripts/build_nanji_ml_import.py)
  - `hmw` 변화량 산출물을 FastAPI 반입용 포맷으로 가공
  - `base_occupied_spaces`가 없으면
    `/Users/electrozone/Documents/GitHub/nanji_work/Data/processed/nanji_hourly_model_dataset_2020_2026_update.csv`
    의 `realtime_current_parking`를 사용

- [import_nanji_group_predictions.py](/Users/electrozone/Documents/GitHub/nanji_app/Python/fastapi/scripts/import_nanji_group_predictions.py)
  - `predicted_delta`를 시간순 누적으로 복원
  - 복원한 절대 점유 대수로 기존 `parking_prediction` 필드 채움

### 2. 예측 API
- [prediction.py](/Users/electrozone/Documents/GitHub/nanji_app/Python/fastapi/app/api/v1/prediction.py)
  - 같은 주차장에 여러 `pp_model_version`이 있어도
  - 가장 최근에 적재된 버전만 `/api/v1/predictions/{parking_lot_id}`에서 반환하도록 수정

### 3. 실시간 기준값 수집 스크립트
- [collect_nanji_realtime_status.py](/Users/electrozone/Documents/GitHub/nanji_app/Python/fastapi/scripts/collect_nanji_realtime_status.py)
  - 서울 Open API 기반에서 한강공원 통합주차포털 난지 페이지 크롤링 방식으로 전환
  - `난지1,2,3,4주차장` 행의
    - `주차가능대수`
    - `주차구획수(계)`
    를 읽어 현재 상태를 `parking_status_log`에 적재
  - `ps_source_type = ihangangpark_site`

### 4. 자동 실행 템플릿
- [com.jarinanji.realtime-status-collector.plist](/Users/electrozone/Documents/GitHub/nanji_app/Python/fastapi/deploy/com.jarinanji.realtime-status-collector.plist)
  - 맥 `launchd` 기준 10분마다 자동 실행

## 이번에 수정한 문서
- [nanji-fastapi-import-guide.md](/Users/electrozone/Documents/GitHub/nanji_app/md/ksm_md/ml-handoff/nanji-fastapi-import-guide.md)
- [ml-data-request.md](/Users/electrozone/Documents/GitHub/nanji_app/md/ksm_md/ml-handoff/ml-data-request.md)
- [realtime-base-occupied-collection-guide.md](/Users/electrozone/Documents/GitHub/nanji_app/md/ksm_md/ml-handoff/realtime-base-occupied-collection-guide.md)
- [realtime-collector-scheduler-guide.md](/Users/electrozone/Documents/GitHub/nanji_app/md/ksm_md/ml-handoff/realtime-collector-scheduler-guide.md)
- [README.md](/Users/electrozone/Documents/GitHub/nanji_app/Python/fastapi/README.md)

## 실제로 확인한 결과

### 1. 변화량 기반 반입 파일 생성
- 생성 파일:
  - `Python/fastapi/data/ml_ready/nanji_group_predictions_for_fastapi.csv`
  - `Python/fastapi/data/ml_ready/nanji_group_predictions_for_fastapi.json`
- 생성 row 수:
  - `8760`

### 2. import dry-run 정상
- `import_nanji_group_predictions.py --dry-run` 기준
  - `inserted = 8760`
  - `skipped = 0`

### 3. 실제 적재 후 처리
- 초기에는 기존 절대값 기반 적재본과 함께 있어 총 row 수가 `17520`으로 보였다.
- 이후 예전 예측본을 삭제하고, 현재는 새 변화량 복원본만 남기는 방향으로 정리했다.

### 4. 실시간 크롤링 dry-run 정상
- 현재 확인된 값 예시:
  - `site_row_name = 난지1,2,3,4주차장`
  - `site_total_spaces = 618`
  - `site_available_spaces = 0`
  - `site_occupied_spaces = 618`
  - `ps_source_type = ihangangpark_site`

중요:
- 이 값은 파싱 오류가 아니라, 그 시점에 사이트가 그렇게 표시한 결과일 수 있다.

## 자동 적재 설정
- `launchd`에 `com.jarinanji.realtime-status-collector` 등록 완료
- 현재 개발자 맥에서 10분마다 자동으로 수집 스크립트가 실행되도록 설정됨

확인 명령:
```bash
launchctl list | grep jarinanji
```

로그 확인:
```bash
tail -f /tmp/jarinanji_realtime_status.log
tail -f /tmp/jarinanji_realtime_status.error.log
```

## 데이터 적재 방식에 대한 합의
- `parking_status_log`는 로그 테이블이므로
  - 값이 이전 row와 같아도
  - 시점이 다르면 새 row를 적재하는 것이 맞다.
- 따라서 중복방지를 강하게 넣지 않았다.
- 같은 값이어도 다른 시각의 관측이면 의미 있는 로그로 본다.

## 지금 상태에서 중요한 결론
1. ML 타깃이 변화량으로 바뀌어도 앱/웹 디자인은 바꾸지 않는다.
2. DB 스키마도 바꾸지 않는다.
3. FastAPI 반입 계층에서 절대값으로 복원한다.
4. 예측 데이터는 새 변화량 복원본 기준으로만 응답하도록 정리했다.
5. 앞으로의 기준값은 한강공원 사이트 크롤링으로 주기적으로 쌓는다.

## 다음에 이어서 볼 수 있는 작업
- `parking_status_log`에 실제로 10분 간격 row가 쌓이는지 장기 확인
- 이 수집 로그를 ML 재반입 시 `base_occupied_spaces` 기준값으로 활용하는 로직 확장
- 필요 시 운영 서버용 `cron` 버전 스케줄러 문서 추가
- 한강공원 사이트 HTML 구조가 바뀌었는지 주기 점검
