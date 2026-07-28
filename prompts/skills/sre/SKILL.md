---
name: sre
description: >-
  프로젝트 운영 성숙도 순차 진단. 로깅 → 메트릭·트레이싱 → 알림·SLO →
  배포 안전성 → 운영 준비도 → 용량·비용 6축을 저장소 정적 분석으로 점검하여
  누락 항목과 개선 제안을 리포트.
  Use when SRE 점검, 운영 점검, 관측성 진단, observability audit, SLO 점검,
  알림 규칙 점검, 배포 안전성, 롤백 경로, 런북, 백업·복구 검증,
  에러 응답 계약 (problem details, RFC 9457), 운영 준비도,
  "이 프로젝트에 뭐가 빠졌는지 봐줘", 프로젝트 전체 진단.
  Do NOT use for CI/CD·Docker 설정 생성 (use devops), 보안 취약점 (use security),
  코드 품질·lint·타입 (use code-review), IaC 안전성 (use terraform).
argument-hint: "[axis,axis | path]"
user-invocable: true
---

상세 절차는 INSTRUCTIONS.md를 참조하세요.
