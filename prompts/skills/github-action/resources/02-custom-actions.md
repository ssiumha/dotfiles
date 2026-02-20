# Custom Actions

## 액션 타입 선택

| 타입 | 장점 | 단점 | 적합한 경우 |
|------|------|------|-------------|
| Composite | 빠름, 빌드 불필요 | 복잡 로직 한계 | step 묶기, setup 자동화 |
| JavaScript | 빠른 시작, 풍부한 API | 빌드 필요 (ncc) | 복잡 로직, GitHub API 연동 |
| Docker | 완전 격리, 어떤 언어든 | 느림 (이미지 pull) | 특정 런타임 필요 |

---

## Composite Action

여러 step을 하나로 묶는 가장 간단한 방식.

```yaml
# .github/actions/setup-project/action.yml
name: 'Setup Project'
description: 'Install deps and prepare environment'

inputs:
  node-version:
    description: 'Node version'
    required: false
    default: '20'

outputs:
  cache-hit:
    description: 'Whether npm cache was hit'
    value: ${{ steps.cache.outputs.cache-hit }}

runs:
  using: 'composite'
  steps:
    - uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}

    - id: cache
      uses: actions/cache@v4
      with:
        path: ~/.npm
        key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}

    - run: npm ci
      shell: bash
```

사용:

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: ./.github/actions/setup-project
    with:
      node-version: '22'
```

**주의**: composite action의 `run` step에는 `shell:` 명시 필수.

---

## JavaScript Action

```yaml
# action.yml
name: 'PR Labeler'
description: 'Auto-label PRs based on changed files'

inputs:
  config-path:
    description: 'Path to label config'
    required: false
    default: '.github/labeler.yml'

outputs:
  labels-added:
    description: 'Labels that were added'

runs:
  using: 'node20'
  main: 'dist/index.js'
  post: 'dist/cleanup.js'     # 워크플로우 종료 시 실행
  post-if: always()
```

### 주요 패키지

```javascript
const core = require('@actions/core');
const github = require('@actions/github');

// Input 읽기
const configPath = core.getInput('config-path');

// Output 설정
core.setOutput('labels-added', JSON.stringify(labels));

// 로깅
core.info('Processing...');
core.warning('Deprecated config format');
core.error('Failed to label');

// GitHub API
const octokit = github.getOctokit(core.getInput('token'));
const { data: pr } = await octokit.rest.pulls.get({
  ...github.context.repo,
  pull_number: github.context.payload.pull_request.number,
});
```

빌드: `npx @vercel/ncc build src/index.js -o dist`

---

## Docker Action

```yaml
# action.yml
name: 'Security Scan'
description: 'Run security scanner'

inputs:
  scan-path:
    description: 'Path to scan'
    required: true
    default: '.'

runs:
  using: 'docker'
  image: 'Dockerfile'
  args:
    - ${{ inputs.scan-path }}
  env:
    LOG_LEVEL: info
```

Pre-built 이미지:

```yaml
runs:
  using: 'docker'
  image: 'docker://ghcr.io/my-org/scanner:latest'
```

---

## 액션 배포

### 같은 레포 내 (monorepo)

```
.github/
  actions/
    setup-project/
      action.yml
    deploy/
      action.yml
  workflows/
    ci.yml
```

```yaml
# ci.yml
steps:
  - uses: ./.github/actions/setup-project
```

### 별도 레포

```yaml
# 태그 기반
- uses: my-org/my-action@v1

# SHA 고정 (권장)
- uses: my-org/my-action@a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2  # v1.2.3
```

### 버전 관리

major 태그를 이동시키는 패턴:

```bash
git tag -fa v1 -m "Update v1 tag"
git push origin v1 --force
```
