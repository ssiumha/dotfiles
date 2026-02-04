# Observability Patterns

## Observability 3 Pillars

| Pillar | 목적 | 도구 |
|--------|------|------|
| Logging | 이벤트 기록 | Structured Logging, Logback |
| Metrics | 수치 측정 | Prometheus, Micrometer |
| Tracing | 요청 추적 | OpenTelemetry, Jaeger |

> **Logging 패턴**: Spring Boot 로깅 표준은 `spring-boot-standards` 스킬의 `02-logging.md` 참조

---

## 1. Metrics (Prometheus + Spring Boot Actuator)

### Spring Boot 설정

```yaml
# application.yaml
management:
  endpoints:
    web:
      exposure:
        include: health, info, prometheus, metrics
      base-path: /actuator
  endpoint:
    health:
      show-details: when_authorized
    prometheus:
      enabled: true
  metrics:
    tags:
      application: ${spring.application.name}
    distribution:
      percentiles-histogram:
        http.server.requests: true
```

### build.gradle 의존성

```groovy
implementation 'org.springframework.boot:spring-boot-starter-actuator'
implementation 'io.micrometer:micrometer-registry-prometheus'
```

### 커스텀 메트릭 등록

```java
@Component
@RequiredArgsConstructor
public class OrderMetrics {

    private final MeterRegistry meterRegistry;
    private Counter orderCounter;
    private Timer orderProcessingTimer;

    @PostConstruct
    public void init() {
        orderCounter = Counter.builder("orders.created")
            .description("Number of orders created")
            .tag("service", "order")
            .register(meterRegistry);

        orderProcessingTimer = Timer.builder("orders.processing.time")
            .description("Order processing time")
            .publishPercentiles(0.5, 0.95, 0.99)
            .register(meterRegistry);
    }

    public void incrementOrderCount() {
        orderCounter.increment();
    }

    public void recordProcessingTime(long millis) {
        orderProcessingTimer.record(millis, TimeUnit.MILLISECONDS);
    }
}
```

---

## 2. Prometheus Scrape 설정

### K8s ServiceMonitor

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: app-monitor
  namespace: monitoring
  labels:
    release: prometheus  # Prometheus Operator 레이블
spec:
  selector:
    matchLabels:
      app: api
  namespaceSelector:
    matchNames:
      - prod
  endpoints:
    - port: http
      path: /actuator/prometheus
      interval: 15s
      scrapeTimeout: 10s
```

### prometheus.yml (직접 설정)

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'spring-boot-app'
    metrics_path: /actuator/prometheus
    static_configs:
      - targets: ['app:8080']
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
```

---

## 3. Tracing (OpenTelemetry)

### Spring Boot 설정

```yaml
# application.yaml (Spring Boot 3.2+)
management:
  tracing:
    sampling:
      probability: 1.0  # 개발: 1.0, 운영: 0.1
  otlp:
    tracing:
      endpoint: http://otel-collector:4318/v1/traces

spring:
  application:
    name: my-app  # trace의 service.name으로 사용됨
```

### build.gradle 의존성

```groovy
implementation 'io.micrometer:micrometer-tracing-bridge-otel'
implementation 'io.opentelemetry:opentelemetry-exporter-otlp'
```

### OpenTelemetry Collector 설정

```yaml
# otel-collector-config.yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 1s
    send_batch_size: 1024
  memory_limiter:
    check_interval: 1s
    limit_mib: 512

exporters:
  # Jaeger 1.35+는 OTLP 네이티브 지원 (권장)
  otlp/jaeger:
    endpoint: jaeger:4317
    tls:
      insecure: true
  prometheus:
    endpoint: 0.0.0.0:8889

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [otlp/jaeger]
    metrics:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [prometheus]
```

---

## 4. Grafana Dashboard

### 주요 패널 구성

```
+--------------------------------------------------+
|                 Service Overview                  |
+--------------------------------------------------+
| Request Rate | Error Rate | P95 Latency | Uptime |
+--------------------------------------------------+
|                  Request Rate Graph              |
+--------------------------------------------------+
|          Latency Histogram | Error Breakdown     |
+--------------------------------------------------+
|              JVM Memory | GC Pause Time          |
+--------------------------------------------------+
```

### PromQL 예시

```promql
# Request Rate (per second)
rate(http_server_requests_seconds_count{application="app"}[5m])

# Error Rate (%)
sum(rate(http_server_requests_seconds_count{status=~"5.."}[5m]))
/ sum(rate(http_server_requests_seconds_count[5m])) * 100

# P95 Latency
histogram_quantile(0.95,
  sum(rate(http_server_requests_seconds_bucket[5m])) by (le, uri)
)

# JVM Memory Used
jvm_memory_used_bytes{area="heap"}
/ jvm_memory_max_bytes{area="heap"} * 100
```

### Dashboard JSON 예시 (ConfigMap)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboard-app
  labels:
    grafana_dashboard: "1"
data:
  app-dashboard.json: |
    {
      "title": "Application Dashboard",
      "panels": [
        {
          "title": "Request Rate",
          "type": "graph",
          "targets": [
            {
              "expr": "rate(http_server_requests_seconds_count[5m])",
              "legendFormat": "{{uri}}"
            }
          ]
        }
      ]
    }
```

---

## 5. AlertManager 규칙

### PrometheusRule (K8s)

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: app-alerts
  namespace: monitoring
spec:
  groups:
    - name: app.rules
      rules:
        # High Error Rate
        - alert: HighErrorRate
          expr: |
            sum(rate(http_server_requests_seconds_count{status=~"5.."}[5m]))
            / sum(rate(http_server_requests_seconds_count[5m])) > 0.05
          for: 5m
          labels:
            severity: critical
          annotations:
            summary: "High error rate detected"
            description: "Error rate is {{ $value | humanizePercentage }}"

        # High Latency
        - alert: HighLatency
          expr: |
            histogram_quantile(0.95,
              sum(rate(http_server_requests_seconds_bucket[5m])) by (le)
            ) > 1
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "High latency detected"
            description: "P95 latency is {{ $value }}s"

        # Pod Not Ready
        - alert: PodNotReady
          expr: kube_pod_status_ready{condition="false"} == 1
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "Pod {{ $labels.pod }} not ready"
```

---

## 6. Docker Compose (로컬 개발)

```yaml
# compose.yaml
services:
  app:
    build: .
    environment:
      OTEL_EXPORTER_OTLP_ENDPOINT: http://otel-collector:4317
    depends_on:
      - otel-collector

  prometheus:
    image: prom/prometheus:v2.48.0
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"

  grafana:
    image: grafana/grafana:10.2.0
    environment:
      # ⚠️ SECURITY: 로컬 개발 전용! 운영환경에서는 절대 사용 금지
      # 운영: K8s Secret, AWS Secrets Manager, Vault 등 사용 필수
      GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_PASSWORD:-admin}
    ports:
      - "3000:3000"
    volumes:
      - grafana-data:/var/lib/grafana

  jaeger:
    image: jaegertracing/all-in-one:1.52
    environment:
      COLLECTOR_OTLP_ENABLED: "true"
    ports:
      - "16686:16686"  # UI
      - "4317:4317"    # OTLP gRPC

  otel-collector:
    image: otel/opentelemetry-collector-contrib:0.91.0
    volumes:
      - ./otel-collector-config.yaml:/etc/otel/config.yaml
    command: ["--config=/etc/otel/config.yaml"]

volumes:
  grafana-data:
```

---

## 7. Justfile 통합

```just
# observability 관련 태스크
[group('observability')]
obs-up:
    docker compose up -d prometheus grafana jaeger otel-collector

[group('observability')]
obs-stop:
    docker compose stop prometheus grafana jaeger otel-collector

[group('observability')]
grafana:
    open http://localhost:3000

[group('observability')]
jaeger:
    open http://localhost:16686

[group('observability')]
prometheus:
    open http://localhost:9090
```

---

## 체크리스트

### Spring Boot 설정

- [ ] actuator 의존성 추가
- [ ] micrometer-registry-prometheus 의존성 추가
- [ ] `/actuator/prometheus` 엔드포인트 노출
- [ ] 적절한 메트릭 태그 설정 (application, environment)

### K8s 배포

- [ ] ServiceMonitor 생성 (Prometheus Operator)
- [ ] PrometheusRule 작성 (알림 규칙)
- [ ] Grafana Dashboard ConfigMap 생성

### 로컬 개발

- [ ] compose.yaml에 observability 스택 추가
- [ ] Justfile에 obs-* 태스크 추가

### Tracing

- [ ] micrometer-tracing-bridge-otel 의존성 추가
- [ ] sampling probability 환경별 설정 (dev: 1.0, prod: 0.1)
- [ ] OTel Collector 배포
