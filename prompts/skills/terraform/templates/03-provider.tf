# provider.tf — Phase 1 강제 항목 (3/4): provider profile/region 명시
#
# 원칙:
#   - region, profile은 환경변수가 아니라 코드에 명시 (`local.ctx` 참조)
#   - 다중 계정/리전은 `alias`로 분리, 모든 resource는 명시적 provider 지정
#
# 금지: `provider "aws" {}` (env 의존)

provider "aws" {
  region  = local.ctx.region
  profile = local.ctx.profile

  default_tags {
    tags = local.ctx.tags
  }
}

# 다중 리전 예시 (필요 시 주석 해제 후 채우기):
#
# provider "aws" {
#   alias   = "<alias-name>"
#   region  = "<another-region>"
#   profile = local.ctx.profile
#   default_tags { tags = local.ctx.tags }
# }
#
# resource "<type>" "<name>" {
#   provider = aws.<alias-name>
#   # ...
# }
