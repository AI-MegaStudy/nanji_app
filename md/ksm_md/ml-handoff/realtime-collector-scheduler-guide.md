# 자리난지 실시간 수집 자동 실행 가이드

## 목적
- 한강공원 통합주차포털 난지 페이지의 `주차가능대수`를 주기적으로 읽어 `parking_status_log`에 자동 적재한다.
- 수동 실행이 아니라, 개발자 맥에서 계속 켜두기만 하면 자동으로 10분마다 수집되게 하는 것이 목표다.

## 현재 사용 스크립트
- 수집 스크립트: [collect_nanji_realtime_status.py](/Users/electrozone/Documents/GitHub/nanji_app/Python/fastapi/scripts/collect_nanji_realtime_status.py)
- `launchd` 템플릿: [com.jarinanji.realtime-status-collector.plist](/Users/electrozone/Documents/GitHub/nanji_app/Python/fastapi/deploy/com.jarinanji.realtime-status-collector.plist)

## 기본 설정
- 현재 템플릿은 `600초(10분)` 간격으로 실행된다.
- 파이썬 경로와 프로젝트 경로는 현재 개발 환경 기준이다.
- 다른 팀원이 사용하면 아래 항목을 자기 로컬 경로에 맞게 바꿔야 한다.
  - `.venv/bin/python`
  - `scripts/collect_nanji_realtime_status.py`
  - `WorkingDirectory`

## 설치 방법
1. plist 파일을 사용자 LaunchAgents 폴더로 복사한다.

```bash
mkdir -p ~/Library/LaunchAgents
cp /Users/electrozone/Documents/GitHub/nanji_app/Python/fastapi/deploy/com.jarinanji.realtime-status-collector.plist ~/Library/LaunchAgents/
```

2. launchd에 등록한다.

```bash
launchctl load ~/Library/LaunchAgents/com.jarinanji.realtime-status-collector.plist
```

3. 바로 실행 상태를 확인한다.

```bash
launchctl list | grep jarinanji
```

## 재시작 / 갱신
- plist 내용을 바꾼 뒤에는 한 번 내렸다가 다시 올린다.

```bash
launchctl unload ~/Library/LaunchAgents/com.jarinanji.realtime-status-collector.plist
launchctl load ~/Library/LaunchAgents/com.jarinanji.realtime-status-collector.plist
```

## 중지 방법
```bash
launchctl unload ~/Library/LaunchAgents/com.jarinanji.realtime-status-collector.plist
```

## 로그 확인
- 표준 출력 로그:

```bash
tail -f /tmp/jarinanji_realtime_status.log
```

- 에러 로그:

```bash
tail -f /tmp/jarinanji_realtime_status.error.log
```

## DB 확인
- 최근 적재 row 확인:

```sql
SELECT *
FROM parking_status_log
ORDER BY ps_id DESC
LIMIT 20;
```

- 사이트 크롤링 적재본만 확인:

```sql
SELECT *
FROM parking_status_log
WHERE ps_source_type = 'ihangangpark_site'
ORDER BY ps_id DESC
LIMIT 20;
```

## 참고
- 지금 템플릿은 맥 개발 환경 기준이라 운영 서버에서는 `cron` 또는 서버용 스케줄러를 따로 쓰는 편이 더 자연스럽다.
- 수집값이 바로 0 또는 100%처럼 보일 수 있는데, 이건 파싱 오류가 아니라 실제 사이트가 그 시점에 그렇게 보여준 값일 수 있다.
