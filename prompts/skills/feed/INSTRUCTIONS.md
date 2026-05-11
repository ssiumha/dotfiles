# Feed Skill

RSS/Atom 피드를 수집하고, 프로젝트 dependency와 대조하여 관련 있는 항목만 리포팅한다.

## Principles

1. **Speed over completeness**: 30초 스캔으로 critical CVE를 잡는 게, 완벽한 분석보다 낫다
2. **False positives > false negatives**: security 카테고리에서는 포함 쪽으로 판단. 오탐은 10초, 미탐은 7일
3. **Actionable output**: Directly Relevant 항목에는 반드시 다음 행동을 포함
4. **Transparent health**: 피드 에러는 항상 표시하여 소스 다운 여부를 알린다

## Workflow

### Step 1: Fetch feeds

`$ARGUMENTS`에서 카테고리를 파싱한다. 인자가 없거나 빈 문자열이면 기본값 `all`(전체).

```bash
ruby ~/dots/prompts/skills/feed/scripts/fetch-feeds.rb --category {$ARGUMENTS 또는 "all"}
```

스크립트 실패 시: 에러 메시지를 사용자에게 보여주고, 네트워크 문제인지 설정 문제인지 안내한다.

### Step 2: Extract dependencies

`~/pj/` 하위의 모든 프로젝트 디렉토리에서 dependency를 추출한다.

```bash
ruby ~/dots/prompts/skills/feed/scripts/extract-deps.rb --scan ~/pj
```

스크립트 실패 시: dependency 매칭 없이 피드 항목만 카테고리별로 리포팅한다.

### Step 3: Analyze and report

두 JSON 결과를 받아 아래 기준으로 분류한다.

#### 분류 기준

1. **Directly Relevant**: 피드 항목의 제목이나 요약에서 flat dependency 목록의 이름이 언급됨.
   - CVE, 보안 advisory, breaking change, deprecation notice를 우선 플래그
   - 매칭된 dependency 이름과 사용자가 취할 액션을 포함

2. **Worth Noting**: 카테고리에는 관련 있지만 dependency와 직접 매칭되지 않는 항목.
   - 한 줄 요약으로 제공

3. **Skip**: 무관하거나 노이즈. 포함하지 않음.

#### Security 카테고리 추가 기준

- CVE 식별자를 dependency 이름과 교차 대조
- Supply chain 공격 리포트 (compromised package, malicious version) 플래그
- Container image 취약점 (docker dependency와 매칭)
- GitHub Actions 취약점 (github-actions dependency와 매칭)

### Step 4: Output

```markdown
## Feed Report ({category}) — {날짜}

**Since**: {last-run} → **Now**: {fetched_at}
**Items**: {total}건 수집, {relevant}건 관련

### Directly Relevant
- **[제목]** — {매칭된 dependency}
  Source: {source} | {published}
  → {영향 및 권장 액션}

### Worth Noting
- **[제목]** — {한 줄 요약}
  Source: {source} | {published}

### Feed Health
- {성공}/{전체} 피드 정상 수집
- {에러가 있으면 표시}
```

관련 항목 0건이면: **"이상 없음"** 한 줄로 끝낸다.

### Step 5: Logseq 기록

결과 출력 후 당일 저널에 기록을 제안한다.

- 관련 항목 있을 때: `- DONE 보안 피드: {핵심 요약} #pj-{project}` + 링크
- 없을 때: `- DONE 보안 피드 체크 — 이상 없음 #feed`
- CRITICAL 항목 발견 시: incident 페이지 생성을 제안

Logseq 기록은 `/obsidian-write` skill을 호출하여 규격에 맞게 작성한다.

## Error Handling

| 상황 | 대응 |
|------|------|
| fetch-feeds.py 실패 (네트워크) | 에러 메시지 표시, 네트워크 확인 안내 |
| fetch-feeds.py 실패 (설정) | feeds.yaml 경로 확인 안내 |
| extract-deps.py 실패 | dependency 매칭 없이 피드만 리포팅 |
| 개별 피드 에러 | Feed Health 섹션에 표시, 나머지는 정상 진행 |
| 0건 수집 | "이상 없음" 출력 (정상 상태) |
