---
name: data-investigation
description: >-
  데이터 조사/분석 파이프라인 생성.
  데이터 수집 -> Python 분석/차트(matplotlib) -> HTML 리포트.
  Use when 데이터 분석, 조사, investigation, 이상 탐지, 패턴 분석,
  리포트 생성, 차트 시각화, 데이터 수집 파이프라인 구축.
  Also use when 데이터를 모아서 분석하고 보고서를 만드는 작업.
  Do NOT use for 단순 DB 조회 (use db-irb), 단순 차트 하나 (use diagram).
argument-hint: "[investigation-name]"
---

# Data Investigation

데이터 수집 -> Python 분석/차트(matplotlib) -> Markdown + HTML 리포트 파이프라인.
조사 목적에 맞게 템플릿 기반으로 스크립트를 매번 커스터마이즈하여 생성한다.

## Phase 1: Setup

조사 범위 파악 + 작업 디렉토리 준비.

1. **조사 목적/대상 파악**
   - `$ARGUMENTS`가 있으면 조사명으로 사용, 없으면 사용자에게 질문
   - 무엇을 분석할 것인지, 어떤 결론을 도출할 것인지 정의

2. **작업 디렉토리 생성**
   ```bash
   mkdir -p docs/reports/{YYYY-MM-DD}-{investigation-name}/data
   mkdir -p docs/reports/{YYYY-MM-DD}-{investigation-name}/charts
   ```

3. **데이터 소스 협의** (AskUserQuestion)
   - 어떤 데이터가 필요한지
   - 어디서 가져올 수 있는지 (DB, API, 로그, CSV, 파일 등)
   - 사용자가 직접 제공할지, 수집 스크립트가 필요한지
   - 옵션:
     - [1] DB 조회 (db-irb 활용)
     - [2] CloudWatch 로그
     - [3] API / 외부 서비스
     - [4] 사용자가 직접 파일 제공
     - [5] 복합 (여러 소스)

4. **Phase 2로 진행**

---

## Phase 2: Collect

사용자가 지정한 방식으로 데이터 수집.

1. **수집 스크립트 생성** (필요한 경우)
   - 데이터 소스에 따라 커스텀 스크립트 작성
   - DB: `.rb` (db-irb 환경), API: `.py`, 로그: `.py` (boto3 등)
   - 출력은 항상 `data/` 하위에 JSON/CSV로 저장
   - 파일 네이밍: `00_xxx.json`, `01_xxx.json` (수집 순서 기반)

2. **사용자가 직접 데이터 제공하는 경우**
   - `data/` 경로 안내
   - 파일 포맷 확인 (JSON, CSV, 텍스트)

3. **복수 소스 매칭 전략** (소스가 2개 이상일 때)
   - 각 소스에서 사용 가능한 식별자 필드 확인
   - 소스 간 공통 키 결정 (exact match vs approximate match)
   - 매칭 불일치 가능성 사전 인지 (타임스탬프 오차, ID 체계 차이 등)

4. **수집 결과 검증**
   - 건수 확인: 기대값과 비교
   - 정합성 체크: 누락 필드, 이상값
   - 검증 결과 사용자에게 보고

5. **Phase 3로 진행**

---

## Phase 3: Analyze

`templates/analyze.py.tmpl` 기반으로 분석 스크립트 생성.

1. **analyze.py 생성**
   - Read `templates/analyze.py.tmpl` (이 skill 디렉토리에서)
   - 조사 목적에 맞게 구체적 내용을 채워넣어 `analyze.py` 생성
   - 작업 디렉토리에 저장

2. **분석 구현**
   - 데이터 로드 (JSON/CSV)
   - Enrichment: dedup, 필터, 타임스탬프 파싱, 추가 매핑
   - Cross Validation: 수집 건수 vs 기대값
   - 지표 계산 + 그룹별 집계

3. **차트 생성**
   - Read `resources/01-chart-patterns.md` → 조사 목적에 맞는 차트 패턴 선택
   - 파이차트는 카테고리 5개 이하 + 편중 없을 때만 사용. 편중 분포(80%+)는 수평 바차트 권장
   - 차트는 `charts/` 하위에 `{번호}_{이름}.png` 형식으로 저장
   - dpi=150, tight_layout 적용
   - 비교 대상이 있으면 side-by-side 레이아웃

4. **실행 및 검증**
   ```bash
   python3 analyze.py
   ```
   - stdout 확인 (summary stats)
   - 차트 파일 생성 확인
   - 이상 있으면 수정 후 재실행

5. **Phase 4로 진행**

---

## Phase 4: Report

리포트 생성 경로는 2가지. 조사 성격에 따라 선택:

- **경로 A (기본)**: `REPORT.md` → `to_html.py` → `REPORT.html` — 정적 리포트에 적합
- **경로 B**: `analyze.py`에서 직접 HTML 생성 — 동적 테이블, 조건부 섹션이 많을 때 적합. 이 경우 REPORT.md 생략 가능, README.md는 유지

### 경로 A: Markdown → HTML

1. **REPORT.md 생성**
   - Read `templates/report.md.tmpl` (이 skill 디렉토리에서)
   - 조사 목적에 맞게 구체적 내용을 채워넣어 `REPORT.md` 생성
   - 차트 이미지 참조 (`![alt](charts/xx.png)`)
   - 리스트 형식 설명, 사견 없이 데이터만
   - 각 차트에 Source, 처리 방법, 주요 수치 명시
   - `데이터 범위` 서브섹션 필수 작성: 대상(전체/조건), 제외(사유 포함), 주의(누락/장애 등)

2. **to_html.py 생성**
   - Read `templates/to_html.py.tmpl` (이 skill 디렉토리에서)
   - `REPORT.md` -> HTML 변환 (차트 base64 embed)
   - print/PDF 최적화 CSS 포함

3. **HTML 생성 + 브라우저 열기**
   ```bash
   python3 to_html.py
   open REPORT.html
   ```

4. **README.md 생성**
   - Read `templates/readme.md.tmpl` (이 skill 디렉토리에서)
   - 조사 메타데이터 채워넣기: 목적/배경, 데이터 소스 테이블, 파일 구조, 재실행 가이드
   - Phase 1~3에서 확인한 정보(소스, 건수, 스크립트명, 수집 기간)를 정리

### 경로 B: Direct HTML

동적 테이블, 조건부 섹션이 많아 Markdown 중간 단계가 비효율적일 때 사용.

1. **analyze.py에서 HTML 직접 생성**
   - 차트는 `charts/` 상대경로 참조 (base64 임베딩은 선택)
   - REPORT.md 생략 가능
   - CSS는 to_html.py.tmpl의 스타일을 참고하되 inline으로 포함

2. **README.md 생성** (경로 A와 동일)

3. **브라우저 열기**
   ```bash
   open REPORT.html
   ```

### 공통

5. **사용자 안내**
   - 브라우저에서 Cmd+P -> PDF 저장 안내
   - Logseq 기록 제안 (debrief skill 연계)

---

## 중요 원칙

1. **데이터 우선**: 리포트는 사견 없이 데이터/수치만 기술한다. 해석은 사용자 몫.
2. **검증 가능**: 각 차트에 데이터 소스, 처리 방법, 건수를 명시하여 제3자가 재현 가능하도록 한다.
3. **수집과 분석 분리**: 수집 스크립트와 분석 스크립트를 분리하여, 데이터 갱신 시 수집만 재실행하면 된다.
4. **차트 목적 적합**: `resources/01-chart-patterns.md`에서 조사 목적에 맞는 차트 패턴을 선택한다. 불필요한 차트를 남발하지 않는다.
5. **증분 실행**: 각 Phase는 독립적으로 재실행 가능해야 한다. 데이터 추가 → analyze.py 재실행 → 리포트 재생성.

## Examples

### 슈퍼매치 투표 분석
User: "{이벤트ID} 매치 투표 분석해줘"
→ Phase 1: `docs/reports/{YYYY-MM-DD}-vote-analysis/` 생성, DB+CloudWatch 수집 협의
→ Phase 2: collect.rb (DB), collect_logs.py (CloudWatch) 생성/실행
→ Phase 3: analyze.py 생성 (투표 timeline, signup-to-vote, OAuth, IP clustering 등 14개 차트)
→ Phase 4: REPORT.md + HTML + README.md (메타데이터) 생성 → 브라우저 오픈

### 사용자 행동 패턴 분석
User: "최근 한 달 사용자 가입/이탈 패턴 분석해줘"
→ Phase 1: `docs/reports/2026-03-19-user-churn-analysis/` 생성, DB 수집 협의
→ Phase 2: collect.rb (가입/탈퇴 데이터) 실행
→ Phase 3: analyze.py (일별 가입 추이, 코호트, 리텐션 곡선 등)
→ Phase 4: REPORT.md + HTML + README.md

### CSV 데이터 분석
User: "이 CSV 파일 분석해줘" (사용자가 파일 제공)
→ Phase 1: `docs/reports/2026-03-19-csv-analysis/` 생성, 사용자 파일을 data/로 복사
→ Phase 2: 수집 불필요, 데이터 검증만
→ Phase 3: analyze.py (분포, 상관관계, 이상값 등)
→ Phase 4: REPORT.md + HTML + README.md

## Technical Details

- 템플릿: `templates/` 하위 4개 파일 (readme.md.tmpl, analyze.py.tmpl, to_html.py.tmpl, report.md.tmpl)
- 차트 패턴: `resources/01-chart-patterns.md`
- Python 의존성: matplotlib, numpy (표준 데이터 분석 환경)
- 수집 스크립트 템플릿 없음 — 데이터 소스가 매번 다르므로 Phase 1에서 직접 작성
