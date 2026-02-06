# Claude Context Watch

Claude Code의 컨텍스트 윈도우 사용량을 실시간으로 모니터링하는 CLI 도구입니다.

![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Version](https://img.shields.io/badge/version-1.0.0-brightgreen)

## 주요 기능

- **실시간 모니터링** - StatusLine을 통해 300ms마다 업데이트
- **시각적 그리드 표시** - 색상으로 구분된 10x10 그리드
- **완전한 메트릭** - 토큰, 캐시, 비용, 사용률 표시
- **크로스 플랫폼** - macOS 및 Linux 지원
- **간편한 설정** - 한 번의 명령으로 구성

## 사전 요구 사항

- [Claude Code](https://github.com/anthropics/claude-code) CLI 설치
- `jq` JSON 프로세서
- Bash 4.0+

## 설치

### Homebrew (macOS)

```bash
brew tap InjunH/claude-context-watch
brew install claude-context-watch
claude-context-watch --setup
```

### 수동 설치

```bash
git clone https://github.com/InjunH/claude-context-watch.git
cd claude-context-watch
./install.sh
```

### 빠른 설치 (curl)

```bash
curl -fsSL https://raw.githubusercontent.com/InjunH/claude-context-watch/main/install.sh | bash
```

## 사용법

```bash
# 모니터링 시작 (TUI)
claude-context-watch

# 세션 목록에서 선택 후 모니터링
claude-context-watch -s

# StatusLine 설정/재설정
claude-context-watch --setup

# 도움말 표시
claude-context-watch -h
```

### 모니터링 중 단축키

| 키 | 동작 |
|----|------|
| `s` | 다른 세션으로 전환 |
| `q` | 종료 |

## 작동 원리

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Claude Code    │────▶│  StatusLine      │────▶│  ~/.claude/     │
│  (300ms 주기)   │     │  context-writer  │     │  context.json   │
└─────────────────┘     └──────────────────┘     └────────┬────────┘
                               │                          │
                               ▼                          │
                        ┌──────────────────┐              │
                        │  터미널 하단     │              │
                        │  상태바 표시     │              │
                        └──────────────────┘              │
                                                          │
                        ┌──────────────────┐              │
                        │  claude-context  │◀─────────────┘
                        │  -watch (TUI)    │  (0.3초 읽기)
                        └──────────────────┘
```

1. **Claude Code**가 ~300ms마다 StatusLine으로 컨텍스트 데이터 전송
2. **context-writer.sh**가 데이터를 받아 파일에 저장하고 상태 텍스트 출력
3. **claude-context-watch**가 파일을 읽어 TUI 모니터에 표시

## 화면 표시

```
  ╔════════════════════════════════════════════════╗
  ║     🔍 Claude Context Monitor v1.0.0          ║
  ╚════════════════════════════════════════════════╝

  Model: Opus
  Session: a1b2c3d4...

  Context Usage
     ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁   Context Monitor
     ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁
     ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁   ⛁ 낮음
     ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁   ⛁ 중간
     ⛁ ⛁ ⛁ ⛁ ⛁ ⛶ ⛶ ⛶ ⛶ ⛶   ⛁ 높음
     ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶
     ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶   ⛶ 여유
     ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶   ⛝ 버퍼
     ⛶ ⛶ ⛶ ⛝ ⛝ ⛝ ⛝ ⛝ ⛝ ⛝
     ⛝ ⛝ ⛝ ⛝ ⛝ ⛝ ⛝ ⛝ ⛝ ⛝

  45k / 200k tokens  (45%)
  Cache read: 12k tokens

  ✅ 양호

  Cost: $0.0142
  Updated: 2025-02-05T10:30:00
  Ctrl+C 종료 | -s 세션 선택
```

## StatusLine 출력

설정 후 Claude Code 터미널에 간략한 상태가 표시됩니다:

```
🟢 45.2k/200k (22%) 📦12.5k $0.01
```

- 🟢/🟡/🟠/🔴 - 사용량 표시기
- 토큰 사용량 / 전체
- 캐시 읽기량 (있는 경우)
- 세션 비용

## 상태 표시기

| 사용량 | 상태 | 표시기 |
|--------|------|--------|
| < 60% | 양호 | 🟢 |
| 60-80% | 보통 | 🟡 |
| 80-90% | 높음 | 🟠 |
| > 90% | 위험 | 🔴 |

## 설정

### 환경 변수

```bash
# 커스텀 컨텍스트 파일 경로
export CLAUDE_CONTEXT_FILE="/path/to/context.json"
```

### 수동 StatusLine 설정

`--setup`이 작동하지 않으면 `~/.claude/settings.json`을 직접 편집하세요:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/context-writer.sh"
  }
}
```

## 제거

```bash
./uninstall.sh
```

또는 수동으로:

```bash
sudo rm /usr/local/bin/claude-context-watch
sudo rm -rf /usr/local/share/claude-context-watch
rm ~/.claude/context-writer.sh
# 선택적으로 ~/.claude/settings.json에서 statusLine 제거
```

## 문제 해결

### "Waiting for Claude Code..."

1. StatusLine이 설정되었는지 확인: `claude-context-watch --setup`
2. Claude Code 재시작
3. 메시지를 보내 세션 시작

### StatusLine이 표시되지 않음

1. `~/.claude/settings.json`에 statusLine 설정이 있는지 확인
2. `~/.claude/context-writer.sh`가 존재하고 실행 가능한지 확인
3. Claude Code 재시작

### 권한 거부

```bash
chmod +x ~/.claude/context-writer.sh
```

## 프로젝트 구조

```
claude-context-watch/
├── bin/
│   └── claude-context-watch      # 메인 TUI 모니터
├── lib/
│   ├── context-writer.sh         # StatusLine 스크립트
│   └── platform.sh               # 크로스 플랫폼 유틸리티
├── install.sh                    # 설치 스크립트
├── uninstall.sh                  # 제거 스크립트
├── Formula/
│   └── claude-context-watch.rb   # Homebrew formula
└── README.md
```

## 라이선스

MIT 라이선스 - 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 기여

기여를 환영합니다! Pull Request를 자유롭게 제출해 주세요.

## 관련 링크

- [Claude Code](https://github.com/anthropics/claude-code) - Claude 공식 CLI
