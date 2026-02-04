# Helmfile & K8s Patterns

## Helmfile 디렉토리 구조

```
helmfile/
├── helmfile.yaml              # 메인 Helmfile
├── environments/              # 환경별 설정
│   ├── dev.yaml
│   ├── staging.yaml
│   └── prod.yaml
├── charts/                    # 커스텀 차트
│   └── app/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
└── values/                    # 공통 values
    ├── common.yaml
    └── app/
        ├── dev.yaml
        ├── staging.yaml
        └── prod.yaml
```

## helmfile.yaml 기본 구조

```yaml
# helmfile.yaml
environments:
  dev:
    values:
      - environments/dev.yaml
  staging:
    values:
      - environments/staging.yaml
  prod:
    values:
      - environments/prod.yaml

repositories:
  - name: bitnami
    url: https://charts.bitnami.com/bitnami

releases:
  # Phase 1: Prerequisites
  - name: postgresql
    namespace: {{ .Environment.Name }}
    chart: bitnami/postgresql
    version: 15.5.0
    labels:
      phase: prerequisites
    values:
      - values/postgresql/common.yaml
      - values/postgresql/{{ .Environment.Name }}.yaml

  # Phase 2: Application
  - name: app
    namespace: {{ .Environment.Name }}
    chart: ./charts/app
    labels:
      phase: app
    needs:
      - postgresql
    values:
      - values/app/common.yaml
      - values/app/{{ .Environment.Name }}.yaml
```

## 배포 명령어

```bash
# 환경별 배포
helmfile -e dev apply
helmfile -e staging apply
helmfile -e prod diff && helmfile -e prod apply

# 단계별 배포 (Phase)
helmfile -e prod -l phase=prerequisites sync
helmfile -e prod -l phase=app sync

# 특정 릴리스만
helmfile -e prod -l name=app sync

# Dry-run
helmfile -e prod diff
helmfile -e prod template
```

## 환경별 values 분리 패턴

```yaml
# environments/dev.yaml
namespace: dev
replicas: 1
resources:
  limits:
    cpu: 500m
    memory: 512Mi

# environments/prod.yaml
namespace: prod
replicas: 3
resources:
  limits:
    cpu: 2000m
    memory: 2Gi
```

---

## K8s 보안 베이스라인

### Pod Security Standards (Restricted)

```yaml
# Pod Level
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  securityContext:
    runAsNonRoot: true        # 필수: root 실행 금지
    runAsUser: 1000           # 권장: 특정 UID
    fsGroup: 1000             # 권장: 파일시스템 그룹
    seccompProfile:
      type: RuntimeDefault    # 권장: seccomp 프로필

  containers:
    - name: app
      securityContext:
        allowPrivilegeEscalation: false  # 필수
        readOnlyRootFilesystem: true     # 권장
        capabilities:
          drop: [ALL]                     # 필수: 모든 권한 제거
```

### Deployment 예시

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  replicas: 3
  template:
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      containers:
        - name: app
          image: app:latest
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop: [ALL]
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 512Mi
          # 임시 쓰기 디렉토리 (readOnlyRootFilesystem 사용 시)
          volumeMounts:
            - name: tmp
              mountPath: /tmp
      volumes:
        - name: tmp
          emptyDir: {}
```

---

## NetworkPolicy (제로 트러스트)

### 1단계: 기본 거부

```yaml
# default-deny-all.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: prod
spec:
  podSelector: {}  # 모든 Pod에 적용
  policyTypes:
    - Ingress
    - Egress
```

### 2단계: 필요한 트래픽만 허용

```yaml
# allow-app-traffic.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-app-traffic
  namespace: prod
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
    - Ingress
    - Egress
  ingress:
    # Ingress Controller에서 오는 트래픽
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: ingress-nginx
      ports:
        - protocol: TCP
          port: 8080
  egress:
    # DNS (CoreDNS)
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
      ports:
        - protocol: UDP
          port: 53
    # PostgreSQL
    - to:
        - podSelector:
            matchLabels:
              app: postgresql
      ports:
        - protocol: TCP
          port: 5432
    # Redis
    - to:
        - podSelector:
            matchLabels:
              app: redis
      ports:
        - protocol: TCP
          port: 6379
```

### NetworkPolicy 체크리스트

- [ ] 네임스페이스에 default-deny 정책 먼저 적용
- [ ] DNS (UDP 53) 허용 필수 (CoreDNS)
- [ ] 필요한 서비스만 명시적으로 허용
- [ ] 허용된 트래픽 문서화

---

## 보안 체크리스트

### Pod Security

| 항목 | 필수 | 설정 |
|-----|------|------|
| runAsNonRoot | 필수 | `true` |
| allowPrivilegeEscalation | 필수 | `false` |
| capabilities.drop | 필수 | `[ALL]` |
| readOnlyRootFilesystem | 권장 | `true` |
| seccompProfile | 권장 | `RuntimeDefault` |

### NetworkPolicy

| 항목 | 설명 |
|-----|------|
| default-deny | 네임스페이스에 기본 거부 정책 |
| DNS 허용 | kube-system 네임스페이스 UDP 53 |
| 명시적 허용 | 필요한 트래픽만 화이트리스트 |

---

## Justfile 통합

```just
# helmfile 관련 태스크
[group('deploy')]
helm-diff env='dev':
    helmfile -e {{env}} diff

[group('deploy')]
helm-apply env='dev':
    helmfile -e {{env}} apply

[group('deploy')]
helm-sync env='dev' phase='':
    #!/usr/bin/env bash
    if [ -n "{{phase}}" ]; then
        helmfile -e {{env}} -l phase={{phase}} sync
    else
        helmfile -e {{env}} sync
    fi

[group('deploy')]
helm-destroy env='dev':
    helmfile -e {{env}} destroy
```
