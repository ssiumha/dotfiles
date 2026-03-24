# Terraform / IaC Checklist

Terraform HCL 코드의 안전성과 운영 안정성을 검증하는 체크리스트.

## Checks

### Critical
- **Data source로 AMI 참조 시 lifecycle 누락**: `data "aws_ami"` + `most_recent = true`로 AMI를 조회하면서 `lifecycle { ignore_changes = [ami] }`가 없으면, 새 AMI 퍼블리시 시 plan에 replace가 발생하여 인스턴스가 재생성됨
- **user_data 변경으로 인한 인스턴스 교체**: `user_data` 수정 시 EC2가 destroy + create됨. 의도하지 않은 교체 방지를 위해 `ignore_changes = [user_data]` 검토
- **Stateful 리소스 force replacement**: RDS, ElastiCache 등 stateful 리소스에서 `engine_version`, `instance_class` 변경 시 교체 여부 확인

### High
- **prevent_destroy 미설정**: 프로덕션 DB, S3 버킷 등 삭제 불가 리소스에 `lifecycle { prevent_destroy = true }` 누락
- **create_before_destroy 미설정**: 무중단 교체가 필요한 리소스(ASG, LB target group)에 `create_before_destroy = true` 누락
- **Hardcoded credentials**: `access_key`, `secret_key`, 비밀번호가 HCL에 직접 기입

### Medium
- **Remote state 미설정**: `terraform { backend }` 없이 로컬 state 사용
- **State locking 미설정**: DynamoDB 테이블 없이 S3 backend 사용
- **Provider version pinning 누락**: `required_providers`에 버전 제약 없음
- **Module version pinning 누락**: `source`에 ref/version 없는 모듈 참조

## Detection Patterns

```hcl
# Critical - AMI data source가 있으면서 lifecycle이 없는 경우
data "aws_ami" ... { most_recent = true }
# + aws_instance에 lifecycle { ignore_changes = [ami] } 없으면 위험

# Critical - user_data가 있으면서 ignore_changes에 없는 경우
user_data = ...
# + lifecycle { ignore_changes = [user_data] } 없으면 검토 필요

# High
prevent_destroy       # 있어야 할 곳에 없는지 확인
create_before_destroy # 무중단 교체 필요 리소스에 있는지 확인
access_key            # HCL에 직접 기입 금지
secret_key            # HCL에 직접 기입 금지

# Medium
backend "local"       # 프로덕션에서 로컬 state 사용
dynamodb_table        # S3 backend에 locking 설정 확인
required_providers    # 버전 제약 확인
```

## Grep Patterns

```
# AMI data source 사용 확인
data\s+"aws_ami"

# lifecycle 블록 존재 확인
lifecycle\s*\{

# ignore_changes에 ami 포함 확인
ignore_changes\s*=.*ami

# user_data 사용 확인
user_data\s*=

# Hardcoded credentials
(access_key|secret_key)\s*=\s*"[^$]

# prevent_destroy 확인
prevent_destroy\s*=\s*true

# Provider version pinning
required_providers
```
