---
name: data-investigation
description: >-
  데이터 조사/분석 파이프라인 생성.
  데이터 수집 -> Python 분석/차트(matplotlib) -> HTML 리포트.
  Use when 데이터 분석, 조사, investigation, 이상 탐지, 패턴 분석,
  리포트 생성, 차트 시각화, 데이터 수집 파이프라인 구축.
  Also use when 데이터를 모아서 분석하고 보고서를 만드는 작업.
  Do NOT use for 단순 DB 조회 (use gandy), 단순 차트 하나 (use diagram).
argument-hint: "[investigation-name]"
---

# Data Investigation

데이터 수집 → Python 분석/차트(matplotlib) → Markdown + HTML 리포트 파이프라인.
작업 디렉토리: `docs/reports/{YYYY-MM-DD}-{investigation-name}/` (하위 `data/`, `charts/`).
스크립트는 `templates/*.tmpl`을 조사 목적에 맞게 채워 매번 생성한다.

## Pipeline

| Phase | 산출물 | 요점 |
|-------|--------|------|
| 1 Setup | 작업 디렉토리 | 조사 목적·도출할 결론 정의. 데이터 소스 협의(AskUserQuestion): DB(gandy) / CloudWatch / API / 사용자 제공 파일 / 복합 |
| 2 Collect | `data/00_*.json` 등 | 소스별 수집 스크립트 (DB: `.rb` gandy, API·로그: `.py`). 순번 네이밍. 수집 후 건수·정합성 검증 결과 보고 |
| 3 Analyze | `analyze.py`, `charts/*.png` | `templates/analyze.py.tmpl` 기반. 로드 → enrichment(dedup·필터·타임스탬프) → cross validation(건수 vs 기대값) → 집계 → 차트 |
| 4 Report | `REPORT.html`, `README.md` | 경로 A(기본): `REPORT.md` → `to_html.py` → HTML. 경로 B: 동적 테이블·조건부 섹션 많으면 analyze.py에서 직접 HTML. README는 목적/소스 테이블/재실행 가이드 (`templates/readme.md.tmpl`) |

각 Phase는 독립 재실행 가능해야 한다 (데이터 추가 → analyze.py 재실행 → 리포트 재생성).

## 도메인 지식

### gandy `to_json` 함정

gandy의 `to_json`은 `Hash#values`를 호출하여 **키를 삭제**한다 (쿼리 결과가 배열로 변환됨).
collect.rb에서는 키를 보존하는 헬퍼를 정의할 것:

```ruby
require 'json'
def save_json(data, path)
  rows = data.is_a?(Array) ? data : [data]
  rows = rows.map { |r| r.is_a?(Sequel::Model) ? r.values : r }
  rows = rows.map { |r| r.is_a?(Hash) ? r.transform_values { |v| v.is_a?(Time) ? v.to_s : v } : r }
  File.write(File.expand_path(path), JSON.pretty_generate(rows))
  puts "Saved to #{path} (#{rows.size} rows)"
end
```

### 복수 소스 매칭

소스가 2개 이상이면: 소스별 식별자 필드 확인 → 공통 키 결정(exact vs approximate) → 매칭 불일치 가능성(타임스탬프 오차, ID 체계 차이) 사전 인지.

### SPA Page View 클러스터링 (웹/앱 접속 로그)

React/SPA는 한 화면 진입에 여러 API를 동시 호출한다(평균 3~6 calls). raw request count는 사용량을 과대 표기하므로, **2초 이내 연속 요청을 1 page view로 클러스터링**하고 리포트에 "page views"로 표기:

```python
def cluster_to_pageviews(entries, gap=2.0):
    """Cluster sorted entries into page views using gap threshold."""
    page_views, current = [], []
    for e in entries:
        if not current:
            current = [e]
        elif (e['ts'] - current[-1]['ts']).total_seconds() <= gap:
            current.append(e)
        else:
            page_views.append(current)
            current = [e]
    if current:
        page_views.append(current)
    return page_views
```

### 차트

- `resources/01-chart-patterns.md`에서 조사 목적에 맞는 패턴 선택. 불필요한 차트 남발 금지
- 파이차트는 카테고리 5개 이하 + 편중 없을 때만. 편중 분포(80%+)는 수평 바차트
- `charts/{번호}_{이름}.png`, dpi=150, tight_layout. 비교 대상은 side-by-side

### REPORT 필수 요소

- 각 차트에 Source, 처리 방법, 주요 수치 명시 (제3자 재현 가능하게)
- `데이터 범위` 서브섹션 필수: 대상(전체/조건), 제외(사유 포함), 주의(누락/장애)
- 완료 시 `open REPORT.html` → Cmd+P PDF 저장 안내, Obsidian 기록 제안 (debrief 연계)

## 중요 원칙

1. **데이터 우선**: 사견 없이 데이터/수치만. 해석은 사용자 몫
2. **수집과 분석 분리**: 데이터 갱신 시 수집만 재실행하면 되도록
3. **session duration 사용 금지**: "첫 요청 ~ 마지막 요청" 간격은 실사용 시간이 아님 (하루 2번 접속 = 24시간 오해). page view 수, 방문 시간대 히트맵, 재방문 일수로 표현
4. **리포트 정제** (읽는 사람 관점): 차트에 있는 데이터를 테이블로 중복 금지, 개발 용어(API 경로·내부 ID) 비노출, 주관적 해석 표현 금지("anomalous", "suggesting" 등), 민감 표현("automated", "bot", "abuse") 절대 금지. v1→v2→final 반복 정제가 기본

## Example

```
User: "{이벤트ID} 투표 데이터 분석해줘"
→ Setup: docs/reports/{YYYY-MM-DD}-vote-analysis/ + DB·CloudWatch 소스 협의
→ Collect: collect.rb (DB), collect_logs.py (CloudWatch)
→ Analyze: analyze.py (투표 timeline, signup-to-vote, IP clustering 등)
→ Report: REPORT.md + HTML + README.md → 브라우저 오픈
```

## Technical Details

- 템플릿: `templates/` 4개 (readme.md.tmpl, analyze.py.tmpl, to_html.py.tmpl, report.md.tmpl)
- 차트 패턴: `resources/01-chart-patterns.md`
- Python 의존성: matplotlib, numpy
- 수집 스크립트 템플릿 없음 — 소스가 매번 다르므로 직접 작성
