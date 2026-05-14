# ctx.tf — Phase 1 강제 항목 (4/4): locals.ctx로 컨텍스트 단일화
#
# 사용자에게 입력받아 치환 (Skill Step 3):
#   REPLACE-project  : 프로젝트 식별자 ([a-z0-9-]+)
#   REPLACE-env      : dev | staging | prod
#   REPLACE-owner    : 팀명 또는 이메일
#   REPLACE-region   : AWS region
#   REPLACE-profile  : AWS profile
#
# 원칙:
#   - 모든 resource가 참조하는 컨텍스트를 한 곳에 모은다
#   - 다른 환경으로 복제 시 이 파일만 바꾸면 되도록 설계
#   - tags는 항상 ctx.tags 참조 (provider default_tags + 리소스별 tags 머지)

locals {
  ctx = {
    project = "REPLACE-project"
    env     = "REPLACE-env"
    owner   = "REPLACE-owner"
    region  = "REPLACE-region"
    profile = "REPLACE-profile"

    name_prefix = "REPLACE-project-REPLACE-env"

    tags = {
      Project   = "REPLACE-project"
      Env       = "REPLACE-env"
      Owner     = "REPLACE-owner"
      ManagedBy = "terraform"
    }
  }
}
