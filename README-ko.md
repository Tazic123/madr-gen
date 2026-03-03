# madr-gen

Claude Code 세션을 자동으로 분석해서 아키텍처 결정을 탐지하고, [mADR (Markdown Any Decision Records)](https://github.com/adr/madr) 문서를 생성하는 Claude Code 플러그인입니다.

## 무엇을 해주나요?

Claude Code 세션 중 중요한 아키텍처 결정을 내릴 때마다 — 라이브러리 선택, 패턴 도입, 구조 결정 — `madr-gen`이 이를 감지하고 문서화할지 물어봅니다. 문서는 MADR 4.0 형식으로 `docs/decisions/` 디렉토리에 저장됩니다.

## 설치

Claude Code는 플러그인 시스템을 내장하고 있습니다. Claude Code 안에서 아래 두 커맨드를 실행하면 `madr-gen`을 설치할 수 있습니다.

**Step 1 — 이 저장소를 마켓플레이스로 등록**

```
/plugin marketplace add JiHongKim98/madr-gen
```

**Step 2 — 플러그인 설치**

```
/plugin install madr-gen@JiHongKim98/madr-gen
```

이것으로 끝입니다. 이후 모든 세션에서 `/madr` 커맨드를 사용할 수 있습니다.

### 설치 범위(scope) 옵션

기본값은 현재 사용자 전체에 적용됩니다. `--scope` 옵션으로 범위를 변경할 수 있습니다:

| 범위 | 커맨드 | 설명 |
|------|--------|------|
| `user` *(기본값)* | `--scope user` | 모든 프로젝트에서 사용 가능 |
| `project` | `--scope project` | `.claude/settings.json` 에 저장, git으로 팀 공유 가능 |
| `local` | `--scope local` | 현재 프로젝트 로컬 전용, gitignore 처리됨 |

```
# 예시: 팀원과 플러그인 공유
/plugin install madr-gen@JiHongKim98/madr-gen --scope project
```

### 플러그인 관리 커맨드

```
/plugin                                           # 플러그인 UI 열기
/plugin marketplace list                          # 등록된 마켓플레이스 목록
/plugin update madr-gen@JiHongKim98/madr-gen     # 최신 버전으로 업데이트
/plugin uninstall madr-gen@JiHongKim98/madr-gen  # 플러그인 제거
/plugin disable madr-gen@JiHongKim98/madr-gen    # 제거하지 않고 비활성화
```

## 사용법

세션 중 또는 세션 종료 시점에 `/madr` 커맨드를 실행합니다:

```
/madr          # 인터랙티브: 세션 분석 후 생성할 ADR 선택
/madr scan     # 빠른 스캔: 파일 작성 없이 탐지된 결정만 표시
/madr init     # 현재 프로젝트에 docs/decisions/ 디렉토리 초기화
```

## 작동 원리

`madr-gen`은 4단계 파이프라인으로 동작합니다:

```
Phase 1: 탐지 (병렬)
  └─ decision-detector (Sonnet)
     ├─ ~/.claude/projects/<project>/ 에서 JSONL 세션 로그 읽기
     ├─ User/Assistant 대화 텍스트 추출
     └─ git diff/log 와 교차 분석

Phase 2: 검증 (순차)
  └─ duplicate-checker (Haiku)
     └─ 기존 docs/decisions/*.md 와 제안 내용 비교
        → 각 항목을 분류: 신규 / 업데이트 / 대체 / 중복

Phase 3: 선택 (인터랙티브)
  └─ AskUserQuestion (다중 선택)
     └─ 카테고리, 액션 유형, 신뢰도와 함께 탐지된 결정 목록 표시

Phase 4: 작성 (병렬)
  └─ madr-writer (Sonnet) × N
     └─ docs/decisions/ 에 NNNN-kebab-case-title.md 생성 또는 수정
```

## 출력 형식

ADR 파일은 [MADR 4.0](https://github.com/adr/madr) 템플릿을 따릅니다:

```
docs/decisions/
├── 0001-react-프론트엔드-채택.md
├── 0002-repository-패턴-도입.md
└── 0003-vitest-테스트-도구-선택.md
```

각 파일의 내용:

```markdown
---
status: accepted
date: 2026-03-04
decision-makers: kimjihong
---

# React를 프론트엔드 프레임워크로 채택

## Context and Problem Statement
클라이언트 사이드 UI 구현을 위한 프레임워크가 필요했습니다...

## Decision Drivers
* 팀의 기존 경험
* 생태계 성숙도

## Considered Options
* React
* Vue
* Svelte

## Decision Outcome
Chosen option: "React", because 팀 경험과 생태계가 가장 풍부하기 때문

### Consequences
* Good, because 다양한 라이브러리 활용 가능
* Bad, because 보일러플레이트 코드가 많음
```

## 탐지 가능한 결정 유형

| 카테고리 | 예시 |
|----------|------|
| **기술 선택** | 라이브러리 선택, 프레임워크 결정, 빌드 도구 |
| **아키텍처** | 디자인 패턴, 모듈 구조, API 설계 방식 |
| **컨벤션** | 네이밍 규칙, 에러 처리 전략, 코드 스타일 |
| **인프라** | CI/CD 파이프라인, 배포 방식, 클라우드 서비스 |
| **리팩토링** | 마이그레이션 전략, 기능 제거 결정 |

## 설정

프로젝트 루트에 `.madr-gen.json` 파일을 만들어 동작을 커스터마이즈할 수 있습니다:

```json
{
  "adrDirectory": "docs/decisions",
  "templateStyle": "full",
  "language": "auto",
  "autoSuggest": true,
  "categories": [
    "technology",
    "architecture",
    "convention",
    "infrastructure",
    "refactoring"
  ]
}
```

| 옵션 | 기본값 | 설명 |
|------|--------|------|
| `adrDirectory` | `docs/decisions` | ADR 파일이 저장될 경로 |
| `templateStyle` | `full` | `"full"` (전체 섹션) 또는 `"minimal"` (핵심 섹션만) |
| `language` | `auto` | `"auto"` 는 세션 언어 자동 감지, 또는 `"en"`, `"ko"` 등으로 강제 지정 |
| `autoSuggest` | `true` | 기존 ADR 업데이트 제안 포함 여부 |

## 헬퍼 스크립트

두 가지 bash 스크립트가 포함되어 있어 직접 사용하거나 다른 도구와 연동할 수 있습니다:

```bash
# 특정 프로젝트의 세션 JSONL 로그 탐색
./scripts/find-session-logs.sh /path/to/project [최대-시간-범위]

# 세션 JSONL 파일에서 대화 텍스트 추출
./scripts/extract-decisions.sh ~/.claude/projects/.../session.jsonl [최대-라인-수]
```

## 권장 워크플로우

프로젝트의 `CLAUDE.md`에 다음 내용을 추가하면 세션 종료 시 자동으로 안내됩니다:

```markdown
## 세션 워크플로우
중요한 변경사항이 있는 세션을 종료하기 전에 `/madr` 를 실행해서
이번 세션에서 내린 아키텍처 결정을 문서화하세요.
```

이렇게 하면 `docs/decisions/` 가 항상 최신 상태로 유지되어 다음 세션이나 팀원들이 왜 그런 선택을 했는지 이해할 수 있습니다.

## 실전 활용 시나리오

### 시나리오 1: 새 프로젝트 시작
```
1. 새 프로젝트에서 Claude Code 세션 시작
2. 기술 스택 결정 (React, TypeScript, Vitest 등)
3. 세션 중 /madr 실행 → 3개 ADR 자동 탐지
4. 모두 선택 → docs/decisions/ 에 0001, 0002, 0003 생성
```

### 시나리오 2: 기존 결정 변경
```
1. 기존에 Redux를 쓰다가 Zustand로 전환하는 작업
2. 세션 종료 전 /madr 실행
3. decision-detector가 "Zustand 도입" 결정 탐지
4. duplicate-checker가 기존 0004-redux-상태관리.md 발견
5. "supersede" 분류 → 기존 ADR 상태를 "superseded"로 업데이트 + 새 ADR 생성
```

### 시나리오 3: 컨벤션 문서화
```
1. 에러 처리 방식, 폴더 구조 등 논의
2. /madr 실행 → convention 카테고리 결정들 탐지
3. 선택적으로 문서화 → 에이전트가 다음 세션에서 참조 가능
```

## 플러그인 구조

```
madr-gen/
├── .claude-plugin/plugin.json    # 플러그인 매니페스트
├── commands/madr.md              # /madr 커맨드 정의
├── agents/
│   ├── decision-detector.md      # 세션 + git에서 결정 탐지
│   ├── duplicate-checker.md      # 중복 ADR 방지
│   └── madr-writer.md            # MADR 4.0 형식 파일 작성
├── skills/madr-gen/SKILL.md      # 전체 워크플로우 오케스트레이션
├── scripts/
│   ├── find-session-logs.sh      # 세션 로그 탐색 스크립트
│   └── extract-decisions.sh      # JSONL 대화 추출 스크립트
└── .madr-gen.json                # 기본 설정 파일
```

## 라이선스

MIT
