# Skill 설치/관리 가이드

프로젝트별로 외부 skill을 탐색, 설치, 관리하는 워크플로우.

## Prerequisites

- 프로젝트가 git 저장소여야 함
- `npx` 명령어 사용 가능
- `.claude/skills/` 디렉토리 존재

---

## 설치 명령어

```bash
# 개별 skill 설치
npx add-skill <repo-owner>/<repo-name>/<skill-name>

# 전체 저장소 설치
npx add-skill <repo-owner>/<repo-name>

# 설치 가능 목록 조회
npx add-skill --list <repo-owner>/<repo-name>
```

**예시**:
```bash
npx add-skill vercel-labs/agent-skills/react-best-practices
npx add-skill --list vercel-labs/agent-skills
```

---

## 설치 워크플로우

1. **프로젝트 루트 확인**: `git rev-parse --show-toplevel`
2. **설치 실행**: `npx add-skill <source>/<skill-name>`
3. **검증**: `.claude/skills/<skill-name>/SKILL.md` 존재 확인
4. **Registry 업데이트**: `.claude/skills/.registry.json`에 기록

---

## .registry.json 스키마

```json
{
  "<skill-name>": {
    "source": "<repo-owner>/<repo-name>",
    "installedAt": "<ISO-8601-timestamp>",
    "method": "npx add-skill",
    "version": "<commit-hash-or-version>"
  }
}
```

**필드**: `source` (원본 경로 또는 "local"), `installedAt` (ISO-8601), `method` (설치 방법), `version` (선택), `notes` (선택)

---

## 관리 워크플로우

### 목록 조회

```bash
# 스크립트 사용
scripts/list-installed.sh [--json] [--quiet]

# 직접 조회
cat .claude/skills/.registry.json | jq '.'
```

### 업데이트

1. Registry에서 출처 확인
2. 기존 skill 백업: `mv .claude/skills/<name> .claude/skills/<name>.bak`
3. 재설치: `npx add-skill <source>/<skill-name>`
4. Registry의 `installedAt`, `version` 갱신

### 제거

1. 디렉토리 삭제: `rm -rf .claude/skills/<skill-name>`
2. `.registry.json`에서 해당 항목 제거

---

## 트러블슈팅

### npx add-skill 실패 시 수동 설치

```bash
git clone https://github.com/<repo> /tmp/skills
cp -r /tmp/skills/prompts/skills/<skill-name> .claude/skills/
rm -rf /tmp/skills
```

### Registry 파일 손상

```bash
# 설치된 skill 목록에서 재구성
ls .claude/skills/ | jq -R -s 'split("\n") | map(select(length > 0)) | map({(.): {source: "unknown", installedAt: now | todate, method: "recovered"}}) | add'
```

---

## Best Practices

1. **설치 전**: 프로젝트 루트에서 실행, 기존 skill과 이름 충돌 확인
2. **Registry 유지**: 모든 설치/제거 후 registry 업데이트, 정기 출처 확인 (보안)
3. **로컬 커스터마이징**: 외부 skill 수정 시 registry에 `customized: true` 추가
4. **추천 저장소**: `resources/09-registries.md` 참조
