---
skill: skill-installer
description: 프로젝트별 외부 skill 설치 및 관리. Use when installing external skills, importing skills from other projects, or managing skill dependencies.
version: 1.0.0
author: Claude Code
created: 2026-01-19
tags: [skill-management, installation, registry]
---

# skill-installer

프로젝트별로 외부 skill을 탐색, 설치, 관리하는 워크플로우를 제공합니다.

## Overview

이 skill은 다음 기능을 제공합니다:
- GitHub 저장소에서 사용 가능한 skill 탐색
- 개별 skill 또는 전체 저장소 설치
- 설치된 skill 관리 (목록, 업데이트, 제거)
- `.registry.json`을 통한 skill 출처 추적

## Prerequisites

- 프로젝트가 git 저장소여야 함
- `npx` 명령어 사용 가능
- `.claude/skills/` 디렉토리 존재

## Workflows

### Workflow 1: 원격 Skill 탐색

**목적**: GitHub 저장소에서 설치 가능한 skill 목록 확인

**절차**:

1. **저장소 skill 목록 조회**:
   ```bash
   npx add-skill --list <repo-owner>/<repo-name>
   ```

   예시:
   ```bash
   npx add-skill --list vercel-labs/agent-skills
   ```

2. **출력 분석 및 사용자 제시**:
   - 사용자에게 발견된 skill 목록 제시
   - 각 skill의 이름과 설명 포함
   - 설치 가능 여부 확인

3. **대체 방법 (명령어 실패 시)**:
   - GitHub 저장소 직접 브라우징 (`WebFetch` 또는 `agent-browser` skill 사용)
   - `prompts/skills/` 디렉토리 구조 파악
   - 각 skill의 `SKILL.md` 파일에서 메타데이터 추출

**출력**: 설치 가능한 skill 목록 (이름, 설명, 경로)

---

### Workflow 2: Skill 설치

**목적**: 특정 skill을 프로젝트에 설치하고 registry에 기록

**절차**:

1. **프로젝트 루트 확인**:
   ```bash
   git rev-parse --show-toplevel
   ```
   - 현재 디렉토리가 git 저장소 내부인지 확인
   - 프로젝트 루트 경로 저장

2. **Skill 설치 실행**:
   ```bash
   npx add-skill <repo-owner>/<repo-name>/<skill-name>
   ```

   예시:
   ```bash
   npx add-skill vercel-labs/agent-skills/react-best-practices
   ```

3. **설치 검증**:
   - `.claude/skills/<skill-name>/` 디렉토리 생성 확인
   - `SKILL.md` 파일 존재 확인
   - 필수 리소스 파일 확인

4. **Registry 업데이트**:
   - `.claude/skills/.registry.json` 파일 읽기 (없으면 생성)
   - 새 skill 정보 추가:
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
   - 파일 저장

5. **설치 완료 보고**:
   - 사용자에게 설치 성공 알림
   - Skill 사용법 간단 안내 (SKILL.md의 주요 workflow 요약)

**에러 처리**:
- 네트워크 오류: 재시도 또는 수동 다운로드 안내
- 이미 설치됨: 덮어쓰기 또는 건너뛰기 옵션 제공
- 권한 오류: sudo 필요 여부 확인

---

### Workflow 3: 전체 저장소 설치

**목적**: 저장소의 모든 skill을 한 번에 설치

**절차**:

1. **전체 저장소 설치 명령**:
   ```bash
   npx add-skill <repo-owner>/<repo-name>
   ```

   예시:
   ```bash
   npx add-skill vercel-labs/agent-skills
   ```

2. **설치 가능 skill 목록 확인**:
   - Workflow 1 사용하여 전체 skill 목록 조회
   - 사용자에게 확인 요청: "총 N개 skill을 설치하시겠습니까?"

3. **개별 설치 반복**:
   - 각 skill에 대해 Workflow 2 실행
   - 진행 상황 표시 (예: "3/10 설치 중...")
   - 실패한 skill은 기록하고 계속 진행

4. **설치 요약 보고**:
   - 성공: N개
   - 실패: M개 (실패 목록 및 이유)
   - 건너뜀: K개 (이미 설치됨)

**최적화**:
- 병렬 설치 가능 여부 확인 (의존성 없는 경우)
- 사용자 선택적 설치 옵션 제공 (대화형 모드)

---

### Workflow 4: Skill 관리

**4.1 설치된 Skill 목록 조회**

```bash
# .registry.json 읽기
cat .claude/skills/.registry.json | jq '.'
```

**출력 형식**:
```
설치된 Skills:
1. react-best-practices (vercel-labs/agent-skills) - 2026-01-19
2. tdd-practices (local) - 2026-01-10
3. docker-setup (awesome-claude-skills/devops) - 2026-01-15
```

---

**4.2 Skill 업데이트**

1. **Registry에서 출처 확인**:
   ```json
   {
     "source": "vercel-labs/agent-skills",
     "installedAt": "2026-01-10T10:30:00Z"
   }
   ```

2. **최신 버전 확인**:
   - GitHub API로 최신 커밋 해시 조회
   - 현재 버전과 비교

3. **업데이트 실행**:
   ```bash
   # 기존 skill 백업 (선택 사항)
   mv .claude/skills/<skill-name> .claude/skills/<skill-name>.bak

   # 재설치
   npx add-skill <source>/<skill-name>
   ```

4. **Registry 업데이트**:
   - `installedAt` 갱신
   - `version` 업데이트

---

**4.3 Skill 제거**

1. **Registry 확인**:
   - 제거할 skill이 registry에 등록되어 있는지 확인

2. **Skill 디렉토리 삭제**:
   ```bash
   rm -rf .claude/skills/<skill-name>
   ```

3. **Registry 갱신**:
   - `.registry.json`에서 해당 항목 제거
   - 파일 저장

4. **확인 메시지**:
   ```
   Skill '<skill-name>' 제거 완료
   - 디렉토리 삭제: .claude/skills/<skill-name>
   - Registry 갱신: .registry.json
   ```

---

### Workflow 5: 알려진 Registry

**목적**: 추천 skill 저장소 목록 제공

**절차**:

1. **Registry 리소스 파일 읽기**:
   ```bash
   # 이 skill의 리소스 디렉토리에서
   cat .claude/skills/skill-installer/resources/01-registries.md
   ```

2. **사용자에게 제시**:
   - 저장소 이름, URL, 설명
   - 포함된 주요 skill 목록
   - 추천 사용 케이스

3. **선택 및 설치 연계**:
   - 사용자가 저장소 선택 시 Workflow 1 또는 3으로 연결

**추천 Registry 예시**:
```markdown
## Vercel Labs Agent Skills
- URL: https://github.com/vercel-labs/agent-skills
- Skills: react-best-practices, nextjs-routing, typescript-patterns
- 추천 대상: React/Next.js 프로젝트

## Awesome Claude Skills - DevOps
- URL: https://github.com/awesome-claude/devops-skills
- Skills: docker-setup, kubernetes-deploy, ci-cd-pipelines
- 추천 대상: DevOps/인프라 작업
```

---

## Key Commands Reference

### 설치 관련
```bash
# 개별 skill 설치
npx add-skill <repo-owner>/<repo-name>/<skill-name>

# 전체 저장소 설치
npx add-skill <repo-owner>/<repo-name>

# 설치 가능 목록 조회
npx add-skill --list <repo-owner>/<repo-name>
```

### Registry 관리
```bash
# Registry 내용 확인
cat .claude/skills/.registry.json | jq '.'

# 특정 skill 정보 조회
cat .claude/skills/.registry.json | jq '."<skill-name>"'

# 모든 skill 출처 목록
cat .claude/skills/.registry.json | jq 'to_entries | .[] | .key + " (" + .value.source + ")"'
```

---

## .registry.json 구조

```json
{
  "react-best-practices": {
    "source": "vercel-labs/agent-skills",
    "installedAt": "2026-01-19T10:30:00Z",
    "method": "npx add-skill",
    "version": "abc123def456"
  },
  "tdd-practices": {
    "source": "local",
    "installedAt": "2026-01-10T08:00:00Z",
    "method": "manual",
    "notes": "Custom skill for project-specific TDD workflow"
  },
  "docker-setup": {
    "source": "awesome-claude-skills/devops",
    "installedAt": "2026-01-15T14:20:00Z",
    "method": "npx add-skill",
    "version": "xyz789abc012"
  }
}
```

**필드 설명**:
- `source`: 원본 저장소 경로 또는 "local"
- `installedAt`: ISO-8601 형식 설치 시각
- `method`: 설치 방법 (npx add-skill, manual, git clone 등)
- `version`: 커밋 해시 또는 버전 태그 (선택 사항)
- `notes`: 추가 메모 (선택 사항)

---

## Best Practices

1. **설치 전 확인**:
   - 프로젝트 루트에서 실행
   - 기존 skill과 이름 충돌 확인

2. **Registry 유지 관리**:
   - 모든 설치/제거 작업 후 registry 업데이트
   - 정기적으로 출처 확인 (보안)

3. **업데이트 주기**:
   - 월 1회 또는 주요 프로젝트 마일스톤 전
   - 변경 사항 확인 후 적용

4. **로컬 커스터마이징**:
   - 외부 skill 수정 시 registry에 `customized: true` 추가
   - 업데이트 시 덮어쓰기 주의

---

## Troubleshooting

### npx add-skill 명령어가 없는 경우
- 수동 설치 방법:
  ```bash
  git clone https://github.com/<repo> /tmp/skills
  cp -r /tmp/skills/prompts/skills/<skill-name> .claude/skills/
  ```

### Registry 파일 손상
- 백업에서 복구 또는 재생성:
  ```bash
  # 설치된 skill 목록에서 재구성
  ls .claude/skills/ | jq -R -s 'split("\n") | map(select(length > 0)) | map({(.): {source: "unknown", installedAt: now | todate, method: "recovered"}}) | add'
  ```

### 권한 오류
- 프로젝트 디렉토리 쓰기 권한 확인
- `.claude/skills/` 디렉토리 소유자 확인

---

## Related Skills

- **skill-creator**: 새 skill 제작 시 사용
- **agent-creator**: Skill을 agent로 변환
- **claude-guide**: Claude Code 프로젝트 초기 설정

---

## Resources

- `resources/01-registries.md`: 추천 skill 저장소 목록
- `.registry.json`: 현재 프로젝트의 설치된 skill 기록
