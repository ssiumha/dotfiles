---
name: arch
description: Creates and maintains project ARCHITECTURE.md documenting structure, constraints, data flow, and decisions. Use when setting up new projects, reviewing architecture, or providing architecture context for agent delegation.
---

# Arch

프로젝트의 아키텍처를 ARCHITECTURE.md로 정리하고 유지합니다.

코드 구조(codemap)가 아닌 **아키텍처 의도** — 왜 이 구조인가, 무엇이 깨지면 안 되는가, 어디로 확장할 것인가.

## ARCHITECTURE.md 구조

| 섹션 | 내용 | 핵심 질문 |
|------|------|----------|
| **Overview** | 한 줄 요약 + 기술 스택 | 이 프로젝트는 무엇인가? |
| **Structure** | 모듈/디렉토리별 책임 | 어디에 무엇이 있는가? |
| **Constraints** | 깨지면 안 되는 규칙 | 무엇을 지켜야 하는가? |
| **Data Flow** | 주요 데이터 흐름 경로 | 데이터가 어떻게 흐르는가? |
| **Extension Points** | 확장 예정/허용 지점 | 앞으로 어떻게 변할 것인가? |
| **Decisions** | 핵심 결정 + WHY | 왜 이렇게 했는가? |

## Instructions

### 생성 (ARCHITECTURE.md가 없을 때)

1. **코드베이스 분석**
   - 디렉토리 구조 파악 (Glob, ls)
   - 주요 설정 파일 확인 (package.json, go.mod, pyproject.toml 등)
   - 진입점/라우팅/모듈 경계 식별

2. **사용자와 대화로 의도 파악**
   - "이 프로젝트에서 가장 중요한 제약은?"
   - "앞으로 확장할 계획이 있는 부분은?"
   - "이 구조를 선택한 이유는?"
   - 코드만으로 알 수 없는 **WHY**를 사용자에게 질문

3. **ARCHITECTURE.md 초안 생성**
   - 템플릿: `templates/ARCHITECTURE.md` 참조
   - 프로젝트 루트에 생성
   - 코드에서 파악한 사실 + 사용자에게 확인한 의도를 결합
   - 빈 섹션은 비워두기보다 `[TODO]`로 표시

4. **반복 협의**
   - 초안 제시 → 사용자 피드백 → 수정 (2-3 라운드)
   - 완료 조건: 사용자가 승인 ("ok", "좋아", "이 정도면 됐어")

### 갱신 (ARCHITECTURE.md가 있을 때)

1. **현재 문서 읽기**
2. **사용자 요청에 따라 수정**
   - 섹션 추가/수정/삭제
   - 새로운 제약/결정 반영
   - 코드 변경으로 인한 구조 업데이트
3. **변경 사항 요약 제시**

### Orchestrator 연동

에이전트에게 작업 위임 시 ARCHITECTURE.md를 활용하는 패턴:

```
위임 프롬프트에 포함할 컨텍스트:
- Constraints 섹션의 관련 규칙
- Structure 섹션에서 작업 대상 모듈의 책임
- Data Flow에서 영향받는 경로
```

orchestrator가 위임 전 ARCHITECTURE.md를 읽고 관련 제약을 프롬프트에 첨부할 것을 권장.

## 중요 원칙

1. **의도 기록**: 코드에서 읽을 수 있는 "무엇"이 아닌, 코드에 없는 "왜"를 기록
2. **간결함**: 각 섹션 10-20줄 이내. 상세 설명은 코드/ADR에 위임
3. **살아있는 문서**: 아키텍처 변경 시 반드시 갱신. 오래된 문서는 없는 것보다 나쁨
4. **제약 중심**: Constraints가 가장 중요한 섹션. 에이전트가 지켜야 할 규칙
5. **git 관리**: 프로젝트 루트에 커밋. 코드와 함께 버전 관리

## Examples

### 새 프로젝트 아키텍처 정리
```
User: "이 프로젝트 아키텍처 정리해줘"
→ 코드베이스 분석 (구조, 설정, 진입점)
→ 사용자에게 제약/의도 질문
→ ARCHITECTURE.md 초안 생성
→ 사용자 피드백 반영
```

### 에이전트 위임 시 활용
```
User: "인증 모듈 리팩토링해줘"
→ orchestrator가 ARCHITECTURE.md 확인
→ Constraints: "auth → 외부 의존 허용, 외부 → auth 금지"
→ 위임 프롬프트에 제약 첨부
→ 에이전트가 제약 준수하며 구현
```

### 아키텍처 갱신
```
User: "DB 분리했으니 아키텍처 업데이트해줘"
→ 기존 ARCHITECTURE.md 읽기
→ Structure, Data Flow, Decisions 섹션 갱신
→ 변경 요약 제시
```

## 연동

| 도구 | 대상 | arch와의 차이 |
|------|------|--------------|
| `codemap` | 코드 구조 맵 (파일/함수/클래스) | arch는 **의도**, codemap은 **사실** |
| `ldoc` ADR | 개별 결정 기록 (1 ADR = 1 결정) | arch는 **전체 그림**, ADR은 **상세** |
| `orchestrator` | 위임 시 Constraints/Structure 참조 | 위임 프롬프트에 제약 첨부 |
| `prompt-review` | 정제된 프롬프트 | 아키텍처 제약 포함 가능 |

**언제 뭘 쓰는가:**

| 요청 | 도구 | 이유 |
|------|------|------|
| "AuthService는 어디 있어?" | codemap | 파일 위치 탐색 |
| "왜 Redis를 선택했어?" | ldoc ADR | 개별 결정 상세 |
| "이 프로젝트 전체 구조는?" | arch | 전체 아키텍처 맥락 |
| "인증 모듈 리팩토링 제약은?" | arch Constraints | 위임 시 제약 확인 |
