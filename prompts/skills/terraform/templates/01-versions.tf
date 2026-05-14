# versions.tf — Phase 1 강제 항목 (1/4): 버전 pin
#
# 사용 전 채우기:
#   - required_version: `terraform -version` 확인 후 minor 고정
#   - required_providers[*].version: 각 provider registry latest의 minor 고정
#
# 권장: `~> X.Y.0` (minor 고정, patch 자동). exact pin도 허용: `= 1.9.5`
# 금지: `>= 1.0` 단독 (upper bound 없음 → silent breakage)

terraform {
  required_version = "~> 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70.0"
    }
    # 필요 시 추가:
    # random = { source = "hashicorp/random", version = "~> 3.6.0" }
    # null   = { source = "hashicorp/null",   version = "~> 3.2.0" }
  }
}
