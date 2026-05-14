# backend.tf — Phase 1 강제 항목 (2/4): S3 backend 고정
#
# 사용자에게 입력받아 치환 (Skill Step 3):
#   REPLACE-state-bucket : tfstate 전용 S3 버킷 (사전 생성, versioning + encryption ON)
#   REPLACE-state-key    : "<project>/<env>/terraform.tfstate" 권장
#   REPLACE-region       : tfstate 버킷의 region
#   REPLACE-profile      : tfstate 접근 AWS profile
#
# 잠금(둘 중 하나, 기본은 use_lockfile):
#   - use_lockfile = true        (terraform ≥ 1.10, S3 native locking)
#   - dynamodb_table = "..."     (legacy, 사전 생성된 잠금 테이블)
#
# 주의: backend 블록은 변수 보간 불가 — 리터럴만.

terraform {
  backend "s3" {
    bucket  = "REPLACE-state-bucket"
    key     = "REPLACE-state-key"
    region  = "REPLACE-region"
    profile = "REPLACE-profile"
    encrypt = true

    use_lockfile = true
    # dynamodb_table = "REPLACE-lock-table"  # legacy 사용 시 use_lockfile 제거하고 이 줄 사용
  }
}
