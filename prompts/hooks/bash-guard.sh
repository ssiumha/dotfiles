#!/bin/bash
# PreToolUse hook for Bash: 위험/제약된 명령 패턴을 차단한다.
# - 디렉토리 우회 (cd worktree, git -C, GIT_DIR, --git-dir, --work-tree)
# - hook 우회 (--no-verify) / git checkout -b / commit --amend
# - 비효율 셸 명령 (cat/head/tail/echo)
# - 인프라 변경 (helmfile/kubectl/helm/terraform/argocd)
# - AWS 위험 명령 (데이터 삭제/IAM/시크릿/스택/DNS/방화벽/리소스 생성)
# 차단된 명령은 사용자가 ! 프리픽스로 직접 실행해야 한다.

# Read stdin (JSON with tool_name, tool_input)
input=$(cat)

tool_name=$(echo "$input" | jq -r '.tool_name // empty')
if [ "$tool_name" != "Bash" ]; then
  exit 0
fi

command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Block: cd to worktree path (agent is already in the worktree)
if echo "$command" | grep -qE '^cd\s+.*\.claude/worktrees'; then
  echo '{"decision":"block","reason":"worktree 경로로 cd 금지. 이미 worktree 안에 있습니다. cd 없이 명령만 실행하세요."}'
  exit 0
fi

# Block: git -C <path> ... (worktree 경로만 차단, 다른 프로젝트 접근은 허용)
if echo "$command" | grep -qE '^git\s+-C\s+.*\.claude/worktrees'; then
  echo '{"decision":"block","reason":"git -C로 worktree 접근 금지. worktree에서 직접 git 명령을 실행하세요."}'
  exit 0
fi

# Block: GIT_DIR= 환경변수로 다른 저장소 접근
if echo "$command" | grep -qE 'GIT_DIR='; then
  echo '{"decision":"block","reason":"GIT_DIR= 금지. worktree에서 직접 git 명령을 실행하세요."}'
  exit 0
fi

# Block: --git-dir 옵션으로 다른 저장소 접근
if echo "$command" | grep -qE 'git\s+.*--git-dir'; then
  echo '{"decision":"block","reason":"--git-dir 금지. worktree에서 직접 git 명령을 실행하세요."}'
  exit 0
fi

# Block: --work-tree 옵션으로 다른 작업 디렉토리 지정
if echo "$command" | grep -qE 'git\s+.*--work-tree'; then
  echo '{"decision":"block","reason":"--work-tree 금지. worktree에서 직접 git 명령을 실행하세요."}'
  exit 0
fi

# Block: git commit --amend — 사용자에게 직접 실행 요청
if echo "$command" | grep -qE 'git\s+commit\s+.*--amend'; then
  echo '{"decision":"block","reason":"git commit --amend는 직접 실행할 수 없습니다. 정말 필요한 경우, 사용자에게 ! git commit --amend 실행을 요청하세요."}'
  exit 0
fi

# Block: git checkout -b (branch creation should go through worktree)
if echo "$command" | grep -qE 'git\s+checkout\s+-b'; then
  echo '{"decision":"block","reason":"git checkout -b 금지. branch 생성은 worktree를 통해서만 가능합니다."}'
  exit 0
fi

# Block: git add 광범위 스테이징 (-A / --all / -a / . / *) — 의도하지 않은 파일 포함 위험
if echo "$command" | grep -qE '^\s*git\s+add\s+(-A|--all|-a|\.|\*)(\s|$)'; then
  add_msg=$(printf 'git add -A/./--all/* 금지. 의도하지 않은 파일까지 스테이징될 위험.\n조치:\n  1) git status 로 변경 파일 확인\n  2) 추적 안 할 파일은 .gitignore 에 추가\n  3) git add <path> 로 명시적으로 스테이징\n정말 모두 추가가 맞으면 사용자에게 ! git add -A 직접 실행 요청.')
  jq -n --arg r "$add_msg" '{decision:"block",reason:$r}'
  exit 0
fi

# Block: git commit 시 staged 영역에 빌드 산출물/바이너리/대용량 파일이 있으면 차단
# 이미지(png/jpg/gif/webp/svg/ico/bmp)는 정상 커밋 대상으로 분류 — 차단하지 않는다
if echo "$command" | grep -qE '^\s*git\s+commit\b'; then
  staged=$(git diff --cached --name-only 2>/dev/null)
  if [ -n "$staged" ]; then
    img_re='\.(png|jpe?g|gif|webp|svg|ico|bmp)$'
    bad_re='\.(so|dylib|dll|exe|bin|pyc|class|jar|wasm|zip|tar|t?gz|7z|rar|sqlite3?|db|lockb|mp4|mov|mp3|wav)$|(^|/)\.DS_Store$'

    bad_ext=$(echo "$staged" | grep -iE "$bad_re")
    bins=$(git diff --cached --numstat 2>/dev/null | awk '$1=="-" && $2=="-" {print $3}' | grep -ivE "$img_re" | grep -ivE "$bad_re")
    big=$(echo "$staged" | grep -ivE "$img_re" | while read -r f; do
      if [ -f "$f" ]; then
        sz=$(stat -f%z "$f" 2>/dev/null)
        [ -n "$sz" ] && [ "$sz" -gt 1048576 ] && printf '%s (%dKB)\n' "$f" $((sz/1024))
      fi
    done)

    if [ -n "$bad_ext$bins$big" ]; then
      cm_msg=""
      [ -n "$bad_ext" ] && cm_msg=$(printf '%s\n[빌드/압축/DB/미디어 파일 — .gitignore 권장]\n%s\n조치: .gitignore 에 패턴 추가 + git rm --cached <path>\n' "$cm_msg" "$bad_ext")
      [ -n "$big" ]     && cm_msg=$(printf '%s\n[1MB 초과 — 저장소 비대화 위험]\n%s\n조치: .gitignore 추가 또는 Git LFS 검토 (git lfs track)\n' "$cm_msg" "$big")
      [ -n "$bins" ]    && cm_msg=$(printf '%s\n[git binary 판정 — 비이미지]\n%s\n조치: .gitattributes 확인 또는 Git LFS 검토\n' "$cm_msg" "$bins")
      cm_msg=$(printf '%s\n의도적 커밋이면 사용자에게 ! git commit 직접 실행 요청.' "$cm_msg")
      jq -n --arg r "$cm_msg" '{decision:"block",reason:$r}'
      exit 0
    fi
  fi
fi

# Block: --no-verify (hook 우회 금지)
if echo "$command" | grep -qE '\-\-no-verify'; then
  echo '{"decision":"block","reason":"--no-verify 금지. hook을 우회할 수 없습니다. 문제를 직접 해결하세요."}'
  exit 0
fi

# Block: cat/head/tail/echo (파이프 뒤 사용도 차단)
# - 파일 읽기 → Read (offset/limit 부분 읽기, 라인 번호 포함)
# - 출력 자르기 → 명령 옵션 사용 (git log -n 5, rg -m 10, jq '.[0:5]')
# - 사용자 메시지 → 응답 본문에 직접 작성
if echo "$command" | grep -qE '(^|[;&|]\s*)(cat|head|tail)\s'; then
  echo '{"decision":"block","reason":"cat/head/tail 금지. 파일은 Read로 직접 읽으세요(offset/limit 부분 읽기 가능, 라인 번호 포함). 출력을 자르고 싶으면 명령 자체에 limit을 거세요 — git log -n 5, rg -m 10, jq -c \".[0:5]\". 잘린 컨텍스트로 잘못 판단하느니 전체를 보세요."}'
  exit 0
fi

if echo "$command" | grep -qE '(^|[;&|]\s*)echo\s'; then
  echo '{"decision":"block","reason":"echo 금지. 사용자에게 보일 텍스트는 응답 본문에 직접 작성하세요. 파일 작성은 Write를 사용하고, 변수 값은 명령 인자에 직접 전달하세요."}'
  exit 0
fi

# Block: rm / rm -rf — 파일 삭제는 git 추적 여부에 따라 처리 방식이 다름
# - git 추적 파일: git rm 사용 (이력 보존 + 스테이징)
# - git 추적 안 된 파일: 사용자에게 처리 방식 확인 (직접 삭제 / .gitignore / 보존)
# xargs/find -exec 등 우회 호출은 명령 시작 위치 매칭으로는 못 잡지만, 직접 호출만 차단해도 대부분 커버됨
if echo "$command" | grep -qE '(^|[;&|]\s*)rm(\s|$)'; then
  rm_msg=$(printf 'rm/rm -rf 금지. 파일 삭제는 git 추적 여부에 따라 처리 방식이 다릅니다.\n조치:\n  1) git ls-files --error-unmatch <path> 로 git 추적 여부 확인\n  2) git 추적 파일이면 → git rm <path> 사용 (이력 보존 + 스테이징, 이후 커밋)\n  3) git 추적 안 된 파일이면 → 사용자에게 처리 방식을 물어보세요:\n     - 직접 삭제 (! rm <path> 사용자 실행)\n     - .gitignore 추가 후 보존\n     - 그대로 두기\n임의로 rm/rm -rf 실행하지 마세요. 정말 필요하면 사용자에게 ! rm 직접 실행을 요청하세요.')
  jq -n --arg r "$rm_msg" '{decision:"block",reason:$r}'
  exit 0
fi

# Block: 인프라 사이드를 직접 변경하는 명령 — 사용자만 실행 가능
# 차단 대상은 mutating 동사만. read-only(get/describe/logs/diff/template/plan/list/status 등)는 허용
infra_msg='인프라 변경 명령은 직접 실행할 수 없습니다. 클러스터/배포 상태를 바꾸는 명령은 사용자만 호출할 수 있습니다. 사용자에게 ! <명령> 으로 실행을 요청하세요. 진단/조회는 read-only 명령(get/describe/logs/diff/template/plan/status)을 사용하세요.'

# helmfile: apply / sync / destroy / delete
if echo "$command" | grep -qE '(^|[;&|]\s*)helmfile\s+(apply|sync|destroy|delete)\b'; then
  printf '{"decision":"block","reason":"helmfile apply/sync/destroy/delete 금지. %s"}\n' "$infra_msg"
  exit 0
fi

# kubectl: 상태 변경 동사
if echo "$command" | grep -qE '(^|[;&|]\s*)kubectl\s+(create|delete|apply|edit|patch|replace|scale|drain|cordon|uncordon|taint|label|annotate|expose|run|set|autoscale)\b'; then
  printf '{"decision":"block","reason":"kubectl 상태 변경 명령 금지. %s"}\n' "$infra_msg"
  exit 0
fi

# kubectl rollout: restart / undo / pause / resume (status는 허용)
if echo "$command" | grep -qE '(^|[;&|]\s*)kubectl\s+rollout\s+(restart|undo|pause|resume)\b'; then
  printf '{"decision":"block","reason":"kubectl rollout 변경 금지. %s"}\n' "$infra_msg"
  exit 0
fi

# helm: 배포 변경 동사
if echo "$command" | grep -qE '(^|[;&|]\s*)helm\s+(install|upgrade|uninstall|delete|rollback)\b'; then
  printf '{"decision":"block","reason":"helm 배포 변경 명령 금지. %s"}\n' "$infra_msg"
  exit 0
fi

# terraform: 인프라 변경
if echo "$command" | grep -qE '(^|[;&|]\s*)terraform\s+(apply|destroy|taint|untaint|import|state\s+(rm|mv|replace-provider))\b'; then
  printf '{"decision":"block","reason":"terraform 변경 명령 금지. %s"}\n' "$infra_msg"
  exit 0
fi

# argocd: 앱 상태 변경
if echo "$command" | grep -qE '(^|[;&|]\s*)argocd\s+app\s+(sync|delete|rollback|patch|set|create|terminate-op)\b'; then
  printf '{"decision":"block","reason":"argocd app 변경 명령 금지. %s"}\n' "$infra_msg"
  exit 0
fi

# Block: AWS 위험 명령 — 사용자만 직접 실행
# read-only(describe-*/list-*/get-*)는 허용. mutating 동사와 데이터 위험 패턴만 차단.
aws_msg='AWS 변경 명령은 직접 실행할 수 없습니다. 데이터/IAM/시크릿/스택/DNS/방화벽 등 클라우드 상태를 바꾸는 명령은 사용자만 호출할 수 있습니다. 사용자에게 ! <명령> 으로 실행을 요청하세요. 조회는 describe-*/list-*/get-* 명령을 사용하세요.'

# 보편 destructive 동사 — 모든 서비스 (delete-*/destroy-*/terminate-*/stop-*/reboot-*)
if echo "$command" | grep -qE '(^|[;&|]\s*)aws\s+\S+\s+(delete|destroy|terminate|stop|reboot)-'; then
  printf '{"decision":"block","reason":"AWS destructive 명령 금지. %s"}\n' "$aws_msg"
  exit 0
fi

# S3 데이터 삭제/이동 (high-level)
if echo "$command" | grep -qE '(^|[;&|]\s*)aws\s+s3\s+(rm|rb|mv)\b'; then
  printf '{"decision":"block","reason":"aws s3 rm/rb/mv 금지. %s"}\n' "$aws_msg"
  exit 0
fi
if echo "$command" | grep -qE '(^|[;&|]\s*)aws\s+s3\s+sync\b.*--delete\b'; then
  printf '{"decision":"block","reason":"aws s3 sync --delete 금지 — 대상 객체가 삭제됩니다. %s"}\n' "$aws_msg"
  exit 0
fi

# IAM 변경 (보안 critical)
if echo "$command" | grep -qE '(^|[;&|]\s*)aws\s+iam\s+(create|attach|detach|put|update)-'; then
  printf '{"decision":"block","reason":"aws iam 변경 명령 금지 — 권한 정책 변경은 보안 critical입니다. %s"}\n' "$aws_msg"
  exit 0
fi

# Secrets / KMS / SSM Parameter — 시크릿/키 변경
if echo "$command" | grep -qE '(^|[;&|]\s*)aws\s+(secretsmanager|kms|ssm)\s+(put|update|create|disable|schedule|cancel|restore)-'; then
  printf '{"decision":"block","reason":"aws secrets/kms/ssm 변경 명령 금지 — 시크릿/키/파라미터 변경은 사용자만. %s"}\n' "$aws_msg"
  exit 0
fi

# CloudFormation 스택 배포
if echo "$command" | grep -qE '(^|[;&|]\s*)aws\s+cloudformation\s+(create-stack|update-stack|execute-change-set|create-change-set|cancel-update-stack|continue-update-rollback|rollback-stack)\b'; then
  printf '{"decision":"block","reason":"aws cloudformation 스택 변경 금지. %s"}\n' "$aws_msg"
  exit 0
fi

# EC2 — 인스턴스 시작 (비용 발생) / 보안그룹 / 속성 변경
if echo "$command" | grep -qE '(^|[;&|]\s*)aws\s+ec2\s+(run|start)-instances\b'; then
  printf '{"decision":"block","reason":"aws ec2 run/start-instances 금지 — 비용 발생. %s"}\n' "$aws_msg"
  exit 0
fi
if echo "$command" | grep -qE '(^|[;&|]\s*)aws\s+ec2\s+(authorize|revoke)-security-group-'; then
  printf '{"decision":"block","reason":"aws ec2 security-group 변경 금지 — 방화벽 규칙은 사용자만. %s"}\n' "$aws_msg"
  exit 0
fi
if echo "$command" | grep -qE '(^|[;&|]\s*)aws\s+ec2\s+modify-'; then
  printf '{"decision":"block","reason":"aws ec2 modify-* 금지 — 인스턴스/볼륨 속성 변경은 사용자만. %s"}\n' "$aws_msg"
  exit 0
fi

# RDS / Lambda 등 mutating
if echo "$command" | grep -qE '(^|[;&|]\s*)aws\s+rds\s+(modify|restore|reboot|create|promote|failover|start)-'; then
  printf '{"decision":"block","reason":"aws rds 변경 금지. %s"}\n' "$aws_msg"
  exit 0
fi
if echo "$command" | grep -qE '(^|[;&|]\s*)aws\s+lambda\s+(update|put|publish|invoke)-'; then
  printf '{"decision":"block","reason":"aws lambda 변경/실행 금지. %s"}\n' "$aws_msg"
  exit 0
fi

# Route53 DNS 레코드 변경
if echo "$command" | grep -qE '(^|[;&|]\s*)aws\s+route53\s+(change-resource-record-sets|create-|update-|associate-vpc-with-hosted-zone)'; then
  printf '{"decision":"block","reason":"aws route53 DNS 변경 금지 — 레코드 변경은 사용자만. %s"}\n' "$aws_msg"
  exit 0
fi

# DynamoDB 데이터/테이블 변경
if echo "$command" | grep -qE '(^|[;&|]\s*)aws\s+dynamodb\s+(put|update|batch-write)-'; then
  printf '{"decision":"block","reason":"aws dynamodb put/update/batch-write 금지 — 데이터 변경은 사용자만. %s"}\n' "$aws_msg"
  exit 0
fi

# SES/SNS — 외부에 메시지 발송
if echo "$command" | grep -qE '(^|[;&|]\s*)aws\s+(ses|sesv2)\s+send-'; then
  printf '{"decision":"block","reason":"aws ses send-* 금지 — 이메일 발송은 사용자만. %s"}\n' "$aws_msg"
  exit 0
fi
if echo "$command" | grep -qE '(^|[;&|]\s*)aws\s+sns\s+publish\b'; then
  printf '{"decision":"block","reason":"aws sns publish 금지 — 알림 발송은 사용자만. %s"}\n' "$aws_msg"
  exit 0
fi

# ECS/EKS 클러스터·서비스 업데이트
if echo "$command" | grep -qE '(^|[;&|]\s*)aws\s+ecs\s+(update|run)-'; then
  printf '{"decision":"block","reason":"aws ecs update/run 금지. %s"}\n' "$aws_msg"
  exit 0
fi
if echo "$command" | grep -qE '(^|[;&|]\s*)aws\s+eks\s+(update|associate|disassociate)-'; then
  printf '{"decision":"block","reason":"aws eks 변경 금지. %s"}\n' "$aws_msg"
  exit 0
fi

# Block: SQL/NoSQL 직접 변경 명령 — 사용자만 실행 가능
# psql/mysql/sqlite3/cqlsh의 -c, -e, -f, heredoc, stdin 모두 명령 문자열에 포함되므로 grep으로 검출 가능.
sql_msg='DB 데이터/스키마 변경 명령은 직접 실행할 수 없습니다. DROP/TRUNCATE/DELETE/UPDATE/FLUSH 등은 사용자만 호출할 수 있습니다. 사용자에게 ! <명령> 으로 실행을 요청하세요. SELECT/SHOW/EXPLAIN 같은 read-only는 허용됩니다.'

# SQL CLI: DROP/TRUNCATE/DELETE FROM/UPDATE … SET/ALTER … DROP
if echo "$command" | grep -qE '(^|[;&|]\s*)(psql|mysql|mariadb|sqlite3|cqlsh)\b'; then
  if echo "$command" | grep -qiE '\bdrop\s+(table|database|schema|index|view|materialized)\b' \
     || echo "$command" | grep -qiE '\btruncate\b' \
     || echo "$command" | grep -qiE '\bdelete\s+from\b' \
     || echo "$command" | grep -qiE '\bupdate\s+\w+\s+set\b' \
     || echo "$command" | grep -qiE '\balter\s+table\s+\w+\s+drop\b'; then
    printf '{"decision":"block","reason":"SQL DROP/TRUNCATE/DELETE/UPDATE/ALTER DROP 금지. %s"}\n' "$sql_msg"
    exit 0
  fi
fi

# Mongo: collection.drop / dropDatabase / deleteMany / deleteOne / remove
if echo "$command" | grep -qE '(^|[;&|]\s*)(mongo|mongosh)\b'; then
  if echo "$command" | grep -qiE '(\.drop\(|dropDatabase|deleteMany|deleteOne|\.remove\()'; then
    printf '{"decision":"block","reason":"mongo drop/deleteMany/remove 금지. %s"}\n' "$sql_msg"
    exit 0
  fi
fi

# Redis: FLUSHDB / FLUSHALL / DEBUG FLUSHALL — 데이터 통째 삭제
if echo "$command" | grep -qiE '(^|[;&|]\s*)redis-cli\b[^|;&]*\b(flushdb|flushall)\b'; then
  printf '{"decision":"block","reason":"redis FLUSHDB/FLUSHALL 금지 — 데이터 통째 삭제. %s"}\n' "$sql_msg"
  exit 0
fi

# Block: DB 마이그레이션 도구 — 스키마/데이터 통째 날리는 명령
mig_msg='DB 마이그레이션 변경 명령은 직접 실행할 수 없습니다. 스키마/데이터를 통째로 날리는 명령은 사용자만 호출할 수 있습니다. 사용자에게 ! <명령> 으로 실행을 요청하세요. status/diff 같은 read-only는 허용됩니다.'

# Prisma: migrate reset / db push --force-reset|--accept-data-loss
if echo "$command" | grep -qE '(^|[;&|]\s*)(npx\s+|pnpm\s+|yarn\s+|bun(x)?\s+)?prisma\s+migrate\s+reset\b'; then
  printf '{"decision":"block","reason":"prisma migrate reset 금지. %s"}\n' "$mig_msg"
  exit 0
fi
if echo "$command" | grep -qE '(^|[;&|]\s*)(npx\s+|pnpm\s+|yarn\s+|bun(x)?\s+)?prisma\s+db\s+push\b.*(--force-reset|--accept-data-loss)'; then
  printf '{"decision":"block","reason":"prisma db push --force-reset/--accept-data-loss 금지. %s"}\n' "$mig_msg"
  exit 0
fi

# Rails / rake: db:drop / db:reset / db:rollback / db:migrate:reset / db:schema:load
if echo "$command" | grep -qE '(^|[;&|]\s*)(bundle\s+exec\s+)?(rails|rake)\s+db:(drop|reset|rollback|migrate:reset|schema:load|structure:load|truncate_all|seed:replant)\b'; then
  printf '{"decision":"block","reason":"rails/rake db:drop|reset|rollback|migrate:reset 금지. %s"}\n' "$mig_msg"
  exit 0
fi

# Alembic: downgrade
if echo "$command" | grep -qE '(^|[;&|]\s*)alembic\s+downgrade\b'; then
  printf '{"decision":"block","reason":"alembic downgrade 금지. %s"}\n' "$mig_msg"
  exit 0
fi

# Knex: migrate:rollback
if echo "$command" | grep -qE '(^|[;&|]\s*)(npx\s+|pnpm\s+|yarn\s+)?knex\s+migrate:rollback\b'; then
  printf '{"decision":"block","reason":"knex migrate:rollback 금지. %s"}\n' "$mig_msg"
  exit 0
fi

# TypeORM: migration:revert / schema:drop
if echo "$command" | grep -qE '(^|[;&|]\s*)(npx\s+|pnpm\s+|yarn\s+)?typeorm\s+(migration:revert|schema:drop)\b'; then
  printf '{"decision":"block","reason":"typeorm migration:revert / schema:drop 금지. %s"}\n' "$mig_msg"
  exit 0
fi

# Sqitch: revert
if echo "$command" | grep -qE '(^|[;&|]\s*)sqitch\s+revert\b'; then
  printf '{"decision":"block","reason":"sqitch revert 금지. %s"}\n' "$mig_msg"
  exit 0
fi

# Flyway: clean / undo
if echo "$command" | grep -qE '(^|[;&|]\s*)flyway\s+(clean|undo)\b'; then
  printf '{"decision":"block","reason":"flyway clean/undo 금지. %s"}\n' "$mig_msg"
  exit 0
fi

# Block: Docker 데이터 손실 명령
docker_msg='Docker 데이터 손실 명령은 직접 실행할 수 없습니다. 볼륨/이미지/네트워크 삭제는 사용자만 호출할 수 있습니다. 사용자에게 ! <명령> 으로 실행을 요청하세요. ps/logs/exec/inspect 같은 read-only는 허용됩니다.'

# docker rm / rmi (컨테이너/이미지 삭제)
if echo "$command" | grep -qE '(^|[;&|]\s*)docker\s+(rm|rmi)\b'; then
  printf '{"decision":"block","reason":"docker rm/rmi 금지 — 컨테이너/이미지 삭제는 사용자만. %s"}\n' "$docker_msg"
  exit 0
fi

# docker (volume|network|image|container|builder|system) (rm|prune)
if echo "$command" | grep -qE '(^|[;&|]\s*)docker\s+(volume|network|image|container|builder|system)\s+(rm|prune)\b'; then
  printf '{"decision":"block","reason":"docker volume/network/image/system rm|prune 금지 — 데이터/캐시 삭제는 사용자만. %s"}\n' "$docker_msg"
  exit 0
fi

# docker (compose|-compose) down -v / --volumes — 볼륨 삭제 = DB 데이터 손실
if echo "$command" | grep -qE '(^|[;&|]\s*)docker(\s+compose|-compose)\s+down\b[^;&|]*(\s-v\b|\s--volumes\b)'; then
  printf '{"decision":"block","reason":"docker compose down -v/--volumes 금지 — 볼륨 삭제로 DB 데이터 손실. -v 없이 down은 허용. %s"}\n' "$docker_msg"
  exit 0
fi

# docker kill (graceful stop과 다르게 SIGKILL)
if echo "$command" | grep -qE '(^|[;&|]\s*)docker(\s+compose|-compose)?\s+kill\b'; then
  printf '{"decision":"block","reason":"docker kill 금지 — SIGKILL은 사용자만. graceful 종료는 docker stop을 사용. %s"}\n' "$docker_msg"
  exit 0
fi

exit 0
