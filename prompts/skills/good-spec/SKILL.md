---
name: good-spec
description: Provides spec writing guidelines with 6 core areas and boundary system. Use when writing SPEC.md, defining requirements, creating project specifications, 요구사항 정의, or 스펙 작성.
---

# Good Spec

Addy Osmani의 "Good Spec" 원칙에 기반한 프로젝트 스펙 작성 가이드입니다.

**핵심 철학**:
- 고수준 비전 제시 → AI에게 세부사항 위임
- 모듈식 분할: 한 번에 한 가지 focused 작업
- 자체 검증: 체크리스트 + LLM-as-a-Judge
- 스펙 진화: 버전 관리, SPEC.md로 저장

## 6가지 핵심 영역

| 영역 | 해결하는 질문 | 핵심 요소 |
|------|--------------|----------|
| Commands | "어떻게 실행하나요?" | 개발/테스트/빌드 명령어 + 결과 |
| Testing | "어떻게 검증하나요?" | 프레임워크 + 커버리지 기준 |
| Project Structure | "어디에 작성하나요?" | 디렉토리 역할 + 파일 명명규칙 |
| Code Style | "어떻게 작성하나요?" | ✅/❌ 예시 (설명 < 예시) |
| Git Workflow | "어떻게 협업하나요?" | 브랜치/커밋/PR 규칙 |
| Boundaries | "무엇을 하면/말아야 하나요?" | Always/Ask/Never 3단계 |

**상세 작성 가이드**: `resources/01-spec-template.md`
**복사용 템플릿**: `templates/SPEC-template.md`

## 3단계 경계 시스템

스펙의 가장 중요한 부분은 **경계 정의**입니다:

| 레벨 | 의미 | 예시 |
|------|------|------|
| ✅ **Always** | 항상 실행 | 테스트 실행, 컨벤션 준수, 린트 검사 |
| ⚠️ **Ask First** | 승인 필요 | DB 스키마 변경, 의존성 추가, API 변경 |
| 🚫 **Never** | 절대 금지 | 시크릿 커밋, vendor 폴더 편집, --force 옵션 |

## Phase 1: Discovery (요구사항 파악)

새 프로젝트 또는 기존 프로젝트 스펙 작성 시:

1. **프로젝트 컨텍스트 파악**
   - 프로젝트 목적과 범위
   - 기술 스택 확인
   - 팀 구성 (개발자 수, 역할)
   - 기존 문서 검토 (README.md, package.json 등)

2. **현재 상태 분석**
   - 기존 SPEC.md 또는 CLAUDE.md 존재 여부
   - 프로젝트 구조 파악 (`Glob`, `ls` 활용)
   - 주요 명령어 확인 (package.json scripts, Makefile 등)

3. **핵심 질문 도출**
   - "어떤 명령어로 테스트하나요?"
   - "코드 스타일 가이드가 있나요?"
   - "AI가 수정하면 안 되는 파일이 있나요?"

4. **사용자 확인**
   - 파악한 컨텍스트 공유
   - 누락된 정보 확인
   - Phase 2로 진행 동의

## 중요 원칙

1. **예시 우선**: 설명 3단락 < 예시 1개
2. **구체성**: "적절히" "가능하면" 금지, 구체적 기준 명시
3. **경계가 핵심**: Always/Ask/Never 명확히 구분
4. **실행 가능**: 모든 명령어 검증 가능
5. **진화**: 스펙은 살아있는 문서, 정기 업데이트

---

## Phase 2: Formulation (스펙 작성)

6개 영역을 순서대로 작성합니다. 각 영역의 **상세 예시와 작성 가이드**는 `resources/01-spec-template.md`를 참조하세요.

### 영역 1: Commands
- 개발/테스트/빌드 명령어 나열
- 주석으로 포트, 경로, 기대 결과 명시
- 최소 요구사항 기재 (예: coverage 80%)

### 영역 2: Testing
- 프레임워크 명시 (Jest, Vitest, Playwright 등)
- 테스트 파일 위치 패턴 (`src/**/*.test.ts`)
- 커버리지 기대치 (전체, critical paths 구분)
- 테스트 명명 규칙

### 영역 3: Project Structure
- 주요 디렉토리만 (3-7개)
- 각 디렉토리 역할 주석
- 자동 생성 폴더 표시 (`dist/`, `node_modules/`)

### 영역 4: Code Style
- **설명 3단락보다 예시 1개가 효과적**
- ✅/❌ 비교 형식 필수
- 실제 프로젝트 코드에서 추출
- 함수, 컴포넌트, 에러 처리 등 카테고리별 예시

### 영역 5: Git Workflow
- 브랜치 명명 패턴 (`feat/`, `fix/`, `refactor/`)
- 커밋 메시지 형식 (Conventional Commits)
- PR 체크리스트
- 머지 전략 (Squash/Merge/Rebase)

### 영역 6: Boundaries (가장 중요!)

3단계 경계 시스템 (상단 테이블 참조) 적용:
- 3단계 명확히 구분 (Always/Ask First/Never)
- 구체적 파일/명령어 명시 ("중요한 파일" ❌ → "src/config/*.json" ✅)
- Never 항목은 보안/안정성 중심

---

## Phase 3: Validation (검증)

스펙 작성 후 자체 검증:

### 체크리스트
- [ ] 6개 영역 모두 작성됨
- [ ] 각 명령어에 설명 포함 (포트, 경로, 결과)
- [ ] Code Style에 ✅/❌ 예시 포함
- [ ] Boundaries 3단계 (Always/Ask/Never) 명확히 구분
- [ ] 모든 명령어 실제 실행 가능
- [ ] 모호한 표현 없음 ("적절히", "가능하면" 금지)

### AI Red Flags 🚨
다음 징후 발견 시 즉시 중단하고 Phase 2로 돌아가기:

- 🚨 **Boundaries 없음** - 스펙의 가장 중요한 부분 누락
- 🚨 **설명만 있고 예시 없음** - Code Style은 반드시 코드 예시 포함
- 🚨 **실행 불가능한 명령어** - 모든 Commands는 검증 가능해야 함
- 🚨 **모호한 Boundaries** - "중요한 파일 수정 금지" ❌ → "src/config/*.json 수정 금지" ✅

### LLM-as-a-Judge (선택)
```
다음 스펙을 검토하고 개선점을 제안해주세요:
1. 누락된 정보가 있나요?
2. 모호한 표현이 있나요?
3. 예시가 충분한가요?
```

---

## Phase 4: Evolution (스펙 진화)

스펙은 프로젝트와 함께 진화해야 합니다:

1. **버전 관리**
   ```markdown
   # SPEC.md
   Version: 2.1.0
   Last Updated: 2026-01-19
   ```

2. **변경 이력**
   ```markdown
   ## Changelog

   ### 2.1.0 (2026-01-19)
   - Added E2E testing with Playwright
   - Updated Node.js version to 20.x

   ### 2.0.0 (2025-12-01)
   - Migrated to TypeScript
   - Introduced strict boundary rules
   ```

3. **정기 리뷰**
   - 월 1회 또는 major change 시
   - 새 팀원 온보딩 후 피드백 반영
   - AI 사용 중 반복되는 문제 발견 시

4. **스펙 개선 트리거**
   - AI가 Ask First를 자주 위반 → Never로 승격
   - 새로운 도구 도입 (예: 새 테스트 프레임워크)
   - 팀 컨벤션 변경


## Examples

### 신규 프로젝트 스펙 작성

```
User: "새 Next.js 프로젝트 스펙 작성해줘"

AI 명령 흐름:
1. Glob "package.json" + Read package.json (기술 스택 파악)
2. Glob "**/*" (프로젝트 구조 파악)
3. Phase 1: 사용자에게 컨텍스트 확인
   - "Next.js 14, TypeScript, Tailwind CSS 사용 중이시네요"
   - "테스트 프레임워크는 어떤 걸 사용하시나요? (Jest/Vitest)"
4. Phase 2: 6개 영역 작성
   - Commands: package.json scripts 기반
   - Testing: 답변받은 프레임워크 기반
   - Project Structure: 현재 디렉토리 구조 반영
   - Code Style: Next.js 모범 사례 + TypeScript
   - Git Workflow: Conventional Commits
   - Boundaries: Next.js 특수 파일 (next.config.js 등) 보호
5. Phase 3: 검증 체크리스트 확인
6. Write SPEC.md
```

### 기존 프로젝트 스펙 개선

```
User: "SPEC.md에 E2E 테스트 정책 추가해줘"

AI 명령 흐름:
1. Read SPEC.md (현재 스펙 파악)
2. Phase 1: 현재 E2E 테스트 상태 확인
   - "Playwright 사용하시나요, Cypress인가요?"
   - "E2E 테스트 파일은 어디에 위치하나요?"
3. Phase 2: 관련 영역 업데이트
   - Testing 영역: E2E 프레임워크, 파일 위치, 커버리지 추가
   - Commands 영역: E2E 실행 명령 추가 (`npm run test:e2e`)
   - Boundaries: E2E 테스트 Always 규칙 추가
4. Phase 3: 검증
5. Phase 4: 버전 업데이트 (1.0.0 → 1.1.0), Changelog 추가
6. Edit SPEC.md
```

### Boundaries 강화

```
User: "AI가 자꾸 .env 파일 수정하려고 해"

AI 명령 흐름:
1. Read SPEC.md
2. Phase 1: 현재 Boundaries 확인
3. Phase 2: Never 섹션에 명시적 추가
   ```
   🚫 Never (절대 금지)
   - ❌ Commit or edit `.env` files (use `.env.example` for templates)
   - ❌ Hardcode API keys, passwords, tokens
   ```
4. Phase 3: 검증
5. Edit SPEC.md
6. 사용자에게 변경사항 공유

---

## Technical Details

### 상세 템플릿
- `resources/01-spec-template.md`: 6개 영역 상세 설명 + 작성 예시
- `templates/SPEC-template.md`: 복사해서 바로 사용 가능한 템플릿

### 참조 리소스
- Addy Osmani의 원본 가이드: https://addyosmani.com/blog/good-spec/
- ldoc skill: 요구사항 문서화와 연계
- bdd-practices: Testing 영역 작성 시 시나리오 활용
