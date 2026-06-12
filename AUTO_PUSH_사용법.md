# 자동 푸시(감시) 사용법

이 폴더(`베트남`) 안에서 파일을 수정하면, 일정 시간(기본 10초) 동안 변경이 멈췄을 때 자동으로 `git add/commit/push`를 수행합니다.

## 1) 1회 설정(이미 푸시는 완료됨)

이미 원격 저장소는 아래로 연결되어 있습니다.

- `https://github.com/hanhwasung32421-source/vietnamplan.git`

## 2) 실행 방법

PowerShell에서 이 폴더에서 아래를 실행하세요.

- `powershell -ExecutionPolicy Bypass -File .\auto_push.ps1`

종료는 `Ctrl + C` 입니다.

## 3) 동작 방식

- 파일 변경을 감지합니다. (하위 폴더 포함)
- 변경 이벤트가 연속으로 발생할 수 있으니, **마지막 변경 이후 10초(기본값)** 대기 후 한 번에 커밋합니다.
- 커밋 메시지는 `auto: YYYY-MM-DD HH:MM:SS` 형식입니다.

## 4) 주의(중요)

- 이 폴더에는 연락처/아이디로 보이는 내용이 포함되어 있을 수 있습니다. 공개 저장소에 푸시하면 그대로 노출될 수 있어요.
- 외부 공유 목적이면 `*_masked.csv` 같은 마스킹 파일을 우선 사용/공유하는 것을 권장합니다.

## 5) 옵션

- 디바운스 시간 변경(예: 30초)
  - `powershell -ExecutionPolicy Bypass -File .\auto_push.ps1 -DebounceSeconds 30`

