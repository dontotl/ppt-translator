# 스킬과 자동화 구조

이 문서는 `ppt-translator` 스킬과 macOS `launchd` 자동화가 어떻게 연결되는지 설명합니다.

## 전체 구조

이 저장소는 두 층으로 나뉩니다.

- 번역 스킬
  - `.ppt` / `.pptx`를 읽고 번역해서 다시 저장
- 자동화 래퍼
  - inbox를 주기적으로 확인
  - 번역이 필요한 파일만 골라 스킬 호출

## 스킬 위치

스킬 본체:

- `.codex/skills/ppt-translator/`

핵심 파일:

- `.codex/skills/ppt-translator/SKILL.md`
- `.codex/skills/ppt-translator/scripts/translate_ppt.sh`
- `.codex/skills/ppt-translator/scripts/main.py`
- `.codex/skills/ppt-translator/scripts/ppt_translator/`

## 자동화 위치

자동화 관련 파일:

- `scripts/run_translate_inbox.sh`
- `scripts/install_launch_agent.sh`
- `scripts/uninstall_launch_agent.sh`
- `launchd/com.ppt-translator.translate-inbox.plist`

## 실행 흐름

기본 흐름은 다음과 같습니다.

1. `launchd`가 일정 주기로 실행됨
2. `run_translate_inbox.sh`가 inbox 폴더 스캔
3. `_translated.pptx`가 없는 원본만 추림
4. `translate_ppt.sh` 실행
5. 내부 Python CLI가 번역 수행
6. 결과 `.pptx` 저장
7. XML 임시파일 정리

## 왜 런타임 미러를 쓰는가

백그라운드 실행은 macOS 권한 정책 때문에 `Documents` 같은 경로에서 제약을 받을 수 있습니다.

그래서 현재 구조는:

- 저장소 원본은 원하는 위치에 둠
- 실제 백그라운드 실행은 `~/.codex/ppt-translator-runtime`에서 수행

이렇게 나누어 두었습니다.

즉:

- 저장소는 수정용
- 런타임 미러는 자동화 실행용

입니다.

## 재사용 포인트

다른 맥에서도 재사용할 수 있도록 다음 값들이 환경변수화되어 있습니다.

- `PPT_TRANSLATOR_RUNTIME_DIR`
- `PPT_TRANSLATOR_INBOX_DIR`
- `PPT_TRANSLATOR_LAUNCH_LABEL`
- `PPT_TRANSLATOR_INTERVAL_SECONDS`
- `PPT_TRANSLATOR_PROVIDER`
- `PPT_TRANSLATOR_SOURCE_LANG`
- `PPT_TRANSLATOR_TARGET_LANG`
- `PPT_TRANSLATOR_MAX_FILE_WORKERS`

즉, 같은 코드베이스를 쓰되:

- inbox 위치를 다르게 두거나
- 주기를 다르게 두거나
- 언어/병렬도/레이블을 다르게 두는 식으로

쉽게 재활용할 수 있습니다.

## 수동 실행과 자동 실행 차이

수동 실행:

- 개발/디버깅/즉시 테스트용
- 사용자가 원하는 경로를 바로 지정

자동 실행:

- 정해진 inbox를 주기적으로 감시
- 이미 번역된 파일은 건너뜀
- 백그라운드 운영용

## 권장 운영 방식

운영은 아래처럼 하는 것을 권장합니다.

1. 저장소는 개발용으로 관리
2. `.env`에 API 키 설정
3. `install_launch_agent.sh`로 launchd 등록
4. 사용자는 inbox에 파일만 넣음
5. 로그는 runtime 쪽에서 확인

## 관련 문서

- 메인 사용 설명: [`README.md`](../README.md)
- 스킬 사용 규칙: [`.codex/skills/ppt-translator/SKILL.md`](../.codex/skills/ppt-translator/SKILL.md)
