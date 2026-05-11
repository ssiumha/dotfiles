# PPT Architecture Diagram Generator

ELKjs(레이아웃) + PPTXGenJS(렌더링) + XML 후처리(커넥터)로 아키텍처 다이어그램 .pptx를 자동 생성합니다.

## 모듈 구조

```
templates/
├── pipeline.mjs    ← 오케스트레이터 (흐름만)
├── spec.mjs        ← 도메인 모델 + 검증 + SERVICE_CATEGORY
├── elk-layout.mjs  ← ELKjs 레이아웃 (zone 내부 + cross-zone 라우팅)
├── renderer.mjs    ← PPTXGenJS 도형 + XML 커넥터 렌더링
├── theme.mjs       ← 테마 프리셋 (aws-default, corporate-blue, minimal-gray)
└── package.json    ← pptxgenjs + elkjs
```

## Phase 1: Parse — Arch Spec 생성

사용자 입력을 분석하여 **Arch Spec JSON**을 생성합니다.

```typescript
interface ArchSpec {
  title: string;
  subtitle?: string;
  theme?: string;  // "aws-default" | "corporate-blue" | "minimal-gray"
  zones: Zone[];
  nodes: Node[];
  connections: Connection[];
}

interface Zone {
  id: string;
  label: string;
  type: "region" | "vpc" | "subnet-public" | "subnet-private" | "az" | "group" | "custom";
  parentId: string | null;
}

interface Node {
  id: string;
  label: string;
  service: string;  // AWS 서비스 키 (spec.mjs의 SERVICE_CATEGORY 참조)
  zoneId: string;
}

interface Connection {
  from: string;
  to: string;
  label?: string;
  style?: { color?: string; dash?: string; arrow?: boolean };
}
```

**Arch Spec 원칙:**
- 좌표를 지정하지 않는다. ELK가 자동 계산.
- zone의 `parentId`로 중첩 표현 (subnet → vpc → region).
- node의 `zoneId`로 소속 zone 지정. ELK가 zone 내부 배치.
- connection의 `from`/`to`는 node id.

## Phase 2: Setup — 작업 환경

```bash
mkdir -p {output-dir}
```

`{output-dir}/node_modules/pptxgenjs`가 없으면:
```bash
cp {SKILL_DIR}/templates/package.json.tmpl {output-dir}/package.json
cd {output-dir} && npm install
```

## Phase 3: Generate — 스크립트 생성 및 실행

1. `templates/` 에서 5개 모듈 복사 (.tmpl → .mjs):
   - `spec.mjs`, `elk-layout.mjs`, `renderer.mjs`, `pipeline.mjs`, `theme.mjs`

2. Arch Spec을 포함한 `generate.mjs` 작성:

```javascript
import { generate } from "./pipeline.mjs";
import { resolve, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));

const SPEC = {
  // Claude가 Phase 1에서 생성한 Arch Spec
};

await generate(SPEC, resolve(__dirname, "output.pptx"));
```

3. 실행: `cd {output-dir} && node generate.mjs`
4. 확인: `open {output-dir}/output.pptx`

## Phase 4: Iterate

사용자 수정 요청 시 `generate.mjs`의 SPEC만 수정 → 재실행.

## 현재 제한사항

- **cross-zone 커넥터**: zone gap 통과하는 Z자 직각 경로. 중간에 다른 zone을 시각적으로 관통할 수 있음.
  사용자가 PPT에서 수동으로 선을 조정하는 것을 권장.
- **같은 zone 내 커넥터**: ELK가 orthogonal 라우팅 처리 — 품질 양호.
- **슬라이드 활용도**: ELK 결과를 슬라이드에 맞게 스케일링. aspect ratio 유지.

## 테마

| 테마 | 특징 |
|------|------|
| `aws-default` | AWS 공식 색상, 밝은 배경 |
| `corporate-blue` | 기업용 파란색 톤 |
| `minimal-gray` | 흑백 미니멀 |

## 서비스 키

`spec.mjs`의 `SERVICE_CATEGORY` 참조:

| 카테고리 | 서비스 키 |
|----------|-----------|
| compute | ec2, ecs, eks, lambda, fargate |
| database | rds, dynamodb, elasticache, aurora |
| network | alb, nlb, cloudfront, route53, igw, nat |
| storage | s3, efs, ebs, ecr |
| security | iam, waf, kms, cognito, secrets_manager |
| integration | sqs, sns, eventbridge |
| management | cloudwatch, xray, config |
