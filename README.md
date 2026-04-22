# PPT Translator for macOS

PowerPoint `.ppt` / `.pptx` 파일을 한국어로 번역하면서 레이아웃을 최대한 유지하도록 만든 워크스페이스입니다.

이 저장소는 두 가지를 함께 제공합니다.

- `ppt-translator` 스킬
  - 실제 번역 엔진입니다.
  - PowerPoint를 읽고, LLM으로 번역하고, 다시 `.pptx`를 생성합니다.
- macOS `launchd` 자동화
  - 지정한 inbox 폴더를 주기적으로 확인합니다.
  - 아직 번역되지 않은 파일만 찾아 스킬을 실행합니다.

즉, 이 저장소는 "수동 번역 도구"이면서 동시에 "맥용 10분 자동 번역기"입니다.

자세한 내부 구조 설명은 [docs/skill-and-automation.md](docs/skill-and-automation.md)에서 볼 수 있습니다.

## 주요 기능

- `.ppt`, `.pptx` 파일 번역
- 서식 최대한 유지
  - 폰트, 색상, 정렬, 표, 간격 등
- 폴더 단위 일괄 번역
- 파일 단위 병렬 처리
- 소스 언어 자동 감지
  - 예: 영어, 일본어, 프랑스어, 스페인어, 독일어 등
- 타겟 언어 한국어(`ko`) 기본 설정
- macOS `launchd` 기반 10분 주기 자동 번역
- 번역 성공/실패 후 XML 임시파일 자동 정리

## 요구사항

다른 맥 환경에서 사용하려면 아래 정도면 충분합니다.

- macOS
- Python 3.10 이상
- 인터넷 연결
- OpenAI API 키
- 기본 macOS 도구
  - `launchctl`
  - `rsync`
  - `zsh`

확인 예시:

```bash
python3 --version
rsync --version
launchctl version
```

## 저장소 구조

중요한 디렉터리만 보면 아래와 같습니다.

```text
.
├── .codex/skills/ppt-translator/
│   ├── SKILL.md
│   ├── agents/openai.yaml
│   └── scripts/
│       ├── bootstrap.sh
│       ├── translate_ppt.sh
│       ├── main.py
│       ├── requirements.txt
│       └── ppt_translator/
├── docs/
│   └── skill-and-automation.md
├── launchd/
│   └── com.ppt-translator.translate-inbox.plist
├── scripts/
│   ├── install_launch_agent.sh
│   ├── run_translate_inbox.sh
│   └── uninstall_launch_agent.sh
└── README.md
```

## 빠른 시작

### 1. 저장소 클론

```bash
git clone https://github.com/dontotl/ppt-translator.git
cd ppt-translator
```

### 2. 스킬 부트스트랩

```bash
cd .codex/skills/ppt-translator/scripts
./bootstrap.sh
```

### 3. `.env` 생성

```bash
cp example.env .env
```

`.env`에 최소한 아래 값을 넣어주세요.

```bash
OPENAI_API_KEY=YOUR_OPENAI_API_KEY
```

현재 자동화 기본값은 OpenAI를 사용합니다.

### 4. 수동 번역 테스트

```bash
cd .codex/skills/ppt-translator/scripts
./translate_ppt.sh "/absolute/path/to/file.pptx" \
  --provider openai \
  --source-lang auto \
  --target-lang ko
```

## 다른 맥에서 처음 세팅하는 방법

다른 MacBook이나 iMac에서도 아래 순서대로 하면 됩니다.

### 1. 저장소를 원하는 위치에 clone

```bash
git clone https://github.com/dontotl/ppt-translator.git
cd ppt-translator
```

중요한 점:

- 저장소 위치는 꼭 `Documents`일 필요가 없습니다.
- 설치 스크립트가 현재 저장소를 기준으로 런타임 미러를 자동 구성합니다.

### 2. Python 가상환경과 의존성 설치

```bash
cd .codex/skills/ppt-translator/scripts
./bootstrap.sh
```

설치되는 주요 파이썬 패키지:

- `openai`
- `anthropic`
- `google-genai`
- `python-pptx`
- `python-dotenv`
- `pytest`

### 3. API 키 설정

```bash
cd .codex/skills/ppt-translator/scripts
cp example.env .env
```

그다음 `.env`를 열어서 키를 넣습니다.

현재 기본 자동화 설정 기준 필수:

- `OPENAI_API_KEY`

선택:

- `OPENAI_ORG`
- `ANTHROPIC_API_KEY`
- `DEEPSEEK_API_KEY`
- `GROK_API_KEY`
- `GOOGLE_API_KEY`

### 4. 자동화 설치

저장소 루트에서:

```bash
./scripts/install_launch_agent.sh
```

설치되면 자동으로 아래가 구성됩니다.

- LaunchAgent 등록
- 런타임 미러 생성
  - 기본: `~/.codex/ppt-translator-runtime`
- inbox 폴더 생성
  - 기본: `~/ppt-translator-inbox`

### 5. 사용

이제 아래 폴더에 `.ppt` 또는 `.pptx`를 넣으면 됩니다.

```text
~/ppt-translator-inbox
```

자동화는 기본적으로 10분마다 이 폴더를 확인합니다.

번역이 끝나면 같은 위치에 아래처럼 결과물이 생깁니다.

```text
example.pptx
example_translated.pptx
```

## 수동 사용 방법

### 단일 파일 번역

```bash
cd .codex/skills/ppt-translator/scripts
./translate_ppt.sh "/absolute/path/to/file.pptx" \
  --provider openai \
  --source-lang auto \
  --target-lang ko
```

### 폴더 전체 번역

```bash
cd .codex/skills/ppt-translator/scripts
./translate_ppt.sh "/absolute/path/to/folder" \
  --provider openai \
  --source-lang auto \
  --target-lang ko \
  --skip-existing-translated \
  --max-file-workers 3
```

### 직접 실행되는 옵션 의미

- `--provider`
  - 사용할 모델 provider
- `--source-lang auto`
  - 소스 언어 자동 감지
- `--target-lang ko`
  - 한국어 번역
- `--skip-existing-translated`
  - 이미 번역된 결과가 있으면 건너뜀
- `--max-file-workers 3`
  - 여러 파일을 병렬 처리

## 자동화 사용 방법

자동화는 `launchd`로 돌아갑니다.

흐름은 아래와 같습니다.

1. `launchd`가 10분마다 실행
2. `run_translate_inbox.sh`가 inbox 스캔
3. 아직 `_translated.pptx`가 없는 원본만 추림
4. `ppt-translator` 스킬 실행
5. 결과 `.pptx` 생성
6. XML 임시파일 정리

### 즉시 1회 실행

다음 실행 주기를 기다리지 않고 바로 돌리고 싶으면:

```bash
~/.codex/ppt-translator-runtime/scripts/run_translate_inbox.sh
```

## 재활용 가능하게 만든 포인트

이 저장소는 다른 Mac에서 그대로 재사용할 수 있도록 몇 가지를 일반화해 두었습니다.

### 1. 하드코딩 경로 제거

설치 스크립트가 현재 사용자와 현재 저장소 기준으로 아래 값을 자동 계산합니다.

- LaunchAgent label
- 런타임 경로
- inbox 경로
- 로그 경로

### 2. 환경변수 기반 커스터마이징

설치 시 아래 값을 바꿀 수 있습니다.

- `PPT_TRANSLATOR_RUNTIME_DIR`
- `PPT_TRANSLATOR_INBOX_DIR`
- `PPT_TRANSLATOR_LAUNCH_LABEL`
- `PPT_TRANSLATOR_INTERVAL_SECONDS`
- `PPT_TRANSLATOR_PROVIDER`
- `PPT_TRANSLATOR_SOURCE_LANG`
- `PPT_TRANSLATOR_TARGET_LANG`
- `PPT_TRANSLATOR_MAX_FILE_WORKERS`

예시:

```bash
PPT_TRANSLATOR_INBOX_DIR="$HOME/Desktop/my-ppt-inbox" \
PPT_TRANSLATOR_INTERVAL_SECONDS=300 \
PPT_TRANSLATOR_TARGET_LANG=ko \
PPT_TRANSLATOR_MAX_FILE_WORKERS=4 \
./scripts/install_launch_agent.sh
```

위 예시는:

- inbox를 `~/Desktop/my-ppt-inbox`로 바꾸고
- 5분 주기로 실행하고
- 파일 병렬도를 4로 설정합니다.

### 3. `Documents` 회피용 런타임 미러

macOS 백그라운드 작업은 `Documents` 아래 경로에서 권한 문제를 만날 수 있습니다.

그래서 이 프로젝트는:

- 편집용 원본 저장소
- 백그라운드 실행용 런타임 미러

를 분리합니다.

기본 런타임:

```text
~/.codex/ppt-translator-runtime
```

이 구조 덕분에 저장소 위치와 상관없이 자동화가 비교적 안정적으로 동작합니다.

## 로그 확인

기본 로그 위치:

- `~/.codex/ppt-translator-runtime/logs/translate-inbox.stdout.log`
- `~/.codex/ppt-translator-runtime/logs/translate-inbox.stderr.log`

실시간 확인:

```bash
tail -f ~/.codex/ppt-translator-runtime/logs/translate-inbox.stdout.log
tail -f ~/.codex/ppt-translator-runtime/logs/translate-inbox.stderr.log
```

LaunchAgent 상태 확인:

```bash
launchctl print "gui/$(id -u)/com.$(id -un).ppt-translator.translate-inbox"
```

## 제거 방법

자동화를 제거하려면:

```bash
./scripts/uninstall_launch_agent.sh
```

주의:

- LaunchAgent만 제거합니다.
- 런타임 디렉터리와 inbox는 남겨둡니다.

## 트러블슈팅

### 1. 번역이 안 시작됨

확인 순서:

1. `OPENAI_API_KEY`가 `.env`에 있는지
2. `launchctl print`에서 agent가 등록됐는지
3. stdout/stderr 로그에 에러가 있는지

### 2. XML 파일이 남음

현재 기본 동작은:

- 성공 시 XML 삭제
- 실패 시에도 가능한 XML 삭제

그래도 남는다면 로그를 먼저 확인하세요.

### 3. 특정 폴더를 inbox로 쓰고 싶음

설치할 때 환경변수로 지정하면 됩니다.

```bash
PPT_TRANSLATOR_INBOX_DIR="$HOME/Desktop/ppt-inbox" \
./scripts/install_launch_agent.sh
```

### 4. 언어를 한국어 말고 다른 언어로 바꾸고 싶음

예:

```bash
PPT_TRANSLATOR_TARGET_LANG=ja ./scripts/install_launch_agent.sh
```

### 5. 자동화 주기를 바꾸고 싶음

예: 15분

```bash
PPT_TRANSLATOR_INTERVAL_SECONDS=900 ./scripts/install_launch_agent.sh
```

## 참고

- 앱 heartbeat 자동화 대신 `launchd`를 쓰는 이유는 네트워크/샌드박스 제약을 피하기 위해서입니다.
- 현재 저장소는 macOS 자동화 기준으로 맞춰져 있습니다.
- 스킬 자체는 수동 실행 기준으로는 다른 환경에서도 재사용 가능합니다.
