#!/usr/bin/env perl
# PreToolUse hook for Bash: 위험/제약된 명령 패턴을 차단한다.
# 단일 파일 안에 룰 테이블 + 매칭 엔진 + 동적 검사 + 셀프테스트 포함.
#
# 사용:
#   stdin JSON  →  block 결정 JSON 출력 (block일 때만, 통과면 무출력 + exit 0)
#   --test     →  내장 회귀 테스트 실행
use strict;
use warnings;
use utf8;
use JSON::PP;

binmode STDIN,  ':raw';
binmode STDOUT, ':raw';
binmode STDERR, ':utf8';

# ============================================================
# 룰 테이블
# ============================================================
# 각 룰:
#   name : 식별자 (테스트용)
#   re   : 1차 매치 정규식 (필수)
#   cond : 2차 매치 정규식 (선택) — re AND cond 모두 매치되어야 트리거
#   dyn  : 동적 검사 콜백 sub { my $cmd = shift; return ($block, $msg_override) }
#   msg  : block 시 사용자에게 표시할 reason
my @RULES;

# 카테고리 공통 꼬리말 (룰 메시지 prefix와 결합)
my $INFRA_TAIL  = '인프라 변경 명령은 직접 실행할 수 없습니다. 클러스터/배포 상태를 바꾸는 명령은 사용자만 호출할 수 있습니다. 사용자에게 ! <명령> 으로 실행을 요청하세요. 진단/조회는 read-only 명령(get/describe/logs/diff/template/plan/status)을 사용하세요.';
my $AWS_TAIL    = 'AWS 변경 명령은 직접 실행할 수 없습니다. 데이터/IAM/시크릿/스택/DNS/방화벽 등 클라우드 상태를 바꾸는 명령은 사용자만 호출할 수 있습니다. 사용자에게 ! <명령> 으로 실행을 요청하세요. 조회는 describe-*/list-*/get-* 명령을 사용하세요.';
my $SQL_TAIL    = 'DB 데이터/스키마 변경 명령은 직접 실행할 수 없습니다. DROP/TRUNCATE/DELETE/UPDATE/FLUSH 등은 사용자만 호출할 수 있습니다. 사용자에게 ! <명령> 으로 실행을 요청하세요. SELECT/SHOW/EXPLAIN 같은 read-only는 허용됩니다.';
my $MIG_TAIL    = 'DB 마이그레이션 변경 명령은 직접 실행할 수 없습니다. 스키마/데이터를 통째로 날리는 명령은 사용자만 호출할 수 있습니다. 사용자에게 ! <명령> 으로 실행을 요청하세요. status/diff 같은 read-only는 허용됩니다.';
my $DOCKER_TAIL = 'Docker 데이터 손실 명령은 직접 실행할 수 없습니다. 볼륨/이미지/네트워크 삭제는 사용자만 호출할 수 있습니다. 사용자에게 ! <명령> 으로 실행을 요청하세요. ps/logs/exec/inspect 같은 read-only는 허용됩니다.';

# ---------- 디렉토리/경로 우회 ----------
push @RULES, { name => 'cd-worktree',     re => qr{^cd\s+.*\.claude/worktrees},
  msg => 'worktree 경로로 cd 금지. 이미 worktree 안에 있습니다. cd 없이 명령만 실행하세요.' };
push @RULES, { name => 'git-C-worktree',  re => qr{^git\s+-C\s+.*\.claude/worktrees},
  msg => 'git -C로 worktree 접근 금지. worktree에서 직접 git 명령을 실행하세요.' };
push @RULES, { name => 'git-dir-env',     re => qr{GIT_DIR=},
  msg => 'GIT_DIR= 금지. worktree에서 직접 git 명령을 실행하세요.' };
push @RULES, { name => 'git-dir-flag',    re => qr{git\s+.*--git-dir},
  msg => '--git-dir 금지. worktree에서 직접 git 명령을 실행하세요.' };
push @RULES, { name => 'work-tree-flag',  re => qr{git\s+.*--work-tree},
  msg => '--work-tree 금지. worktree에서 직접 git 명령을 실행하세요.' };

# ---------- Git 명령 ----------
push @RULES, { name => 'commit-amend',    re => qr{git\s+commit\s+.*--amend},
  msg => 'git commit --amend는 직접 실행할 수 없습니다. 정말 필요한 경우, 사용자에게 ! git commit --amend 실행을 요청하세요.' };
push @RULES, { name => 'checkout-b',      re => qr{git\s+checkout\s+-b},
  msg => 'git checkout -b 금지. branch 생성은 worktree를 통해서만 가능합니다.' };
push @RULES, { name => 'git-add-broad',   re => qr{^\s*git\s+add\s+(-A|--all|-a|\.|\*)(\s|$)},
  msg => "git add -A/./--all/* 금지. 의도하지 않은 파일까지 스테이징될 위험.\n조치:\n  1) git status 로 변경 파일 확인\n  2) 추적 안 할 파일은 .gitignore 에 추가\n  3) git add <path> 로 명시적으로 스테이징\n정말 모두 추가가 맞으면 사용자에게 ! git add -A 직접 실행 요청." };
push @RULES, { name => 'commit-binary',   re => qr{^\s*git\s+commit\b},
  dyn => \&check_commit_binary, msg => undef };
push @RULES, { name => 'no-verify',       re => qr{--no-verify},
  msg => '--no-verify 금지. hook을 우회할 수 없습니다. 문제를 직접 해결하세요.' };

# ---------- 기본 명령 ----------
push @RULES, { name => 'cat-head-tail',   re => qr{(^|[;&|]\s*)(cat|head|tail)\s},
  msg => 'cat/head/tail 금지. 파일은 Read로 직접 읽으세요(offset/limit 부분 읽기 가능, 라인 번호 포함). 출력을 자르고 싶으면 명령 자체에 limit을 거세요 — git log -n 5, rg -m 10, jq -c ".[0:5]". 잘린 컨텍스트로 잘못 판단하느니 전체를 보세요.' };
push @RULES, { name => 'echo',            re => qr{(^|[;&|]\s*)echo\s},
  msg => 'echo 금지. 사용자에게 보일 텍스트는 응답 본문에 직접 작성하세요. 파일 작성은 Write를 사용하고, 변수 값은 명령 인자에 직접 전달하세요.' };
push @RULES, { name => 'rm',              re => qr{(^|[;&|]\s*)rm(\s|$)},
  msg => "rm/rm -rf 금지. 파일 삭제는 git 추적 여부에 따라 처리 방식이 다릅니다.\n조치:\n  1) git ls-files --error-unmatch <path> 로 git 추적 여부 확인\n  2) git 추적 파일이면 → git rm <path> 사용 (이력 보존 + 스테이징, 이후 커밋)\n  3) git 추적 안 된 파일이면 → 사용자에게 처리 방식을 물어보세요:\n     - 직접 삭제 (! rm <path> 사용자 실행)\n     - .gitignore 추가 후 보존\n     - 그대로 두기\n임의로 rm/rm -rf 실행하지 마세요. 정말 필요하면 사용자에게 ! rm 직접 실행을 요청하세요." };

# ---------- K8s / Helmfile / Helm / Terraform / ArgoCD ----------
push @RULES, { name => 'helmfile',        re => qr{(^|[;&|]\s*)helmfile\s+(apply|sync|destroy|delete)\b},
  msg => "helmfile apply/sync/destroy/delete 금지. $INFRA_TAIL" };
push @RULES, { name => 'kubectl-mutating',re => qr{(^|[;&|]\s*)kubectl\s+(create|delete|apply|edit|patch|replace|scale|drain|cordon|uncordon|taint|label|annotate|expose|run|set|autoscale)\b},
  msg => "kubectl 상태 변경 명령 금지. $INFRA_TAIL" };
push @RULES, { name => 'kubectl-rollout', re => qr{(^|[;&|]\s*)kubectl\s+rollout\s+(restart|undo|pause|resume)\b},
  msg => "kubectl rollout 변경 금지. $INFRA_TAIL" };
push @RULES, { name => 'helm',            re => qr{(^|[;&|]\s*)helm\s+(install|upgrade|uninstall|delete|rollback)\b},
  msg => "helm 배포 변경 명령 금지. $INFRA_TAIL" };
push @RULES, { name => 'terraform',       re => qr{(^|[;&|]\s*)terraform\s+(apply|destroy|taint|untaint|import|state\s+(rm|mv|replace-provider))\b},
  msg => "terraform 변경 명령 금지. $INFRA_TAIL" };
push @RULES, { name => 'argocd',          re => qr{(^|[;&|]\s*)argocd\s+app\s+(sync|delete|rollback|patch|set|create|terminate-op)\b},
  msg => "argocd app 변경 명령 금지. $INFRA_TAIL" };

# ---------- AWS ----------
push @RULES, { name => 'aws-destructive', re => qr{(^|[;&|]\s*)aws\s+\S+\s+(delete|destroy|terminate|stop|reboot)-},
  msg => "AWS destructive 명령 금지. $AWS_TAIL" };
push @RULES, { name => 'aws-s3-rm',       re => qr{(^|[;&|]\s*)aws\s+s3\s+(rm|rb|mv)\b},
  msg => "aws s3 rm/rb/mv 금지. $AWS_TAIL" };
push @RULES, { name => 'aws-s3-sync-del', re => qr{(^|[;&|]\s*)aws\s+s3\s+sync\b.*--delete\b},
  msg => "aws s3 sync --delete 금지 — 대상 객체가 삭제됩니다. $AWS_TAIL" };
push @RULES, { name => 'aws-iam',         re => qr{(^|[;&|]\s*)aws\s+iam\s+(create|attach|detach|put|update)-},
  msg => "aws iam 변경 명령 금지 — 권한 정책 변경은 보안 critical입니다. $AWS_TAIL" };
push @RULES, { name => 'aws-secrets',     re => qr{(^|[;&|]\s*)aws\s+(secretsmanager|kms|ssm)\s+(put|update|create|disable|schedule|cancel|restore)-},
  msg => "aws secrets/kms/ssm 변경 명령 금지 — 시크릿/키/파라미터 변경은 사용자만. $AWS_TAIL" };
push @RULES, { name => 'aws-cfn',         re => qr{(^|[;&|]\s*)aws\s+cloudformation\s+(create-stack|update-stack|execute-change-set|create-change-set|cancel-update-stack|continue-update-rollback|rollback-stack)\b},
  msg => "aws cloudformation 스택 변경 금지. $AWS_TAIL" };
push @RULES, { name => 'aws-ec2-run',     re => qr{(^|[;&|]\s*)aws\s+ec2\s+(run|start)-instances\b},
  msg => "aws ec2 run/start-instances 금지 — 비용 발생. $AWS_TAIL" };
push @RULES, { name => 'aws-ec2-sg',      re => qr{(^|[;&|]\s*)aws\s+ec2\s+(authorize|revoke)-security-group-},
  msg => "aws ec2 security-group 변경 금지 — 방화벽 규칙은 사용자만. $AWS_TAIL" };
push @RULES, { name => 'aws-ec2-modify',  re => qr{(^|[;&|]\s*)aws\s+ec2\s+modify-},
  msg => "aws ec2 modify-* 금지 — 인스턴스/볼륨 속성 변경은 사용자만. $AWS_TAIL" };
push @RULES, { name => 'aws-rds',         re => qr{(^|[;&|]\s*)aws\s+rds\s+(modify|restore|reboot|create|promote|failover|start)-},
  msg => "aws rds 변경 금지. $AWS_TAIL" };
push @RULES, { name => 'aws-lambda',      re => qr{(^|[;&|]\s*)aws\s+lambda\s+(update|put|publish|invoke)-},
  msg => "aws lambda 변경/실행 금지. $AWS_TAIL" };
push @RULES, { name => 'aws-route53',     re => qr{(^|[;&|]\s*)aws\s+route53\s+(change-resource-record-sets|create-|update-|associate-vpc-with-hosted-zone)},
  msg => "aws route53 DNS 변경 금지 — 레코드 변경은 사용자만. $AWS_TAIL" };
push @RULES, { name => 'aws-dynamodb',    re => qr{(^|[;&|]\s*)aws\s+dynamodb\s+(put|update|batch-write)-},
  msg => "aws dynamodb put/update/batch-write 금지 — 데이터 변경은 사용자만. $AWS_TAIL" };
push @RULES, { name => 'aws-ses',         re => qr{(^|[;&|]\s*)aws\s+(ses|sesv2)\s+send-},
  msg => "aws ses send-* 금지 — 이메일 발송은 사용자만. $AWS_TAIL" };
push @RULES, { name => 'aws-sns',         re => qr{(^|[;&|]\s*)aws\s+sns\s+publish\b},
  msg => "aws sns publish 금지 — 알림 발송은 사용자만. $AWS_TAIL" };
push @RULES, { name => 'aws-ecs',         re => qr{(^|[;&|]\s*)aws\s+ecs\s+(update|run)-},
  msg => "aws ecs update/run 금지. $AWS_TAIL" };
push @RULES, { name => 'aws-eks',         re => qr{(^|[;&|]\s*)aws\s+eks\s+(update|associate|disassociate)-},
  msg => "aws eks 변경 금지. $AWS_TAIL" };

# ---------- DB CLI ----------
push @RULES, { name => 'sql-cli-mutating',
  re   => qr{(^|[;&|]\s*)(psql|mysql|mariadb|sqlite3|cqlsh)\b},
  cond => qr{\b(drop\s+(table|database|schema|index|view|materialized)|truncate|delete\s+from|update\s+\w+\s+set|alter\s+table\s+\w+\s+drop)\b}i,
  msg  => "SQL DROP/TRUNCATE/DELETE/UPDATE/ALTER DROP 금지. $SQL_TAIL" };
push @RULES, { name => 'mongo-mutating',
  re   => qr{(^|[;&|]\s*)(mongo|mongosh)\b},
  cond => qr{(\.drop\(|dropDatabase|deleteMany|deleteOne|\.remove\()},
  msg  => "mongo drop/deleteMany/remove 금지. $SQL_TAIL" };
push @RULES, { name => 'redis-flush',
  re   => qr{(^|[;&|]\s*)redis-cli\b[^|;&]*\b(flushdb|flushall)\b}i,
  msg  => "redis FLUSHDB/FLUSHALL 금지 — 데이터 통째 삭제. $SQL_TAIL" };

# ---------- DB 마이그레이션 ----------
push @RULES, { name => 'prisma-reset',    re => qr{(^|[;&|]\s*)(npx\s+|pnpm\s+|yarn\s+|bunx?\s+)?prisma\s+migrate\s+reset\b},
  msg => "prisma migrate reset 금지. $MIG_TAIL" };
push @RULES, { name => 'prisma-push',     re => qr{(^|[;&|]\s*)(npx\s+|pnpm\s+|yarn\s+|bunx?\s+)?prisma\s+db\s+push\b.*(--force-reset|--accept-data-loss)},
  msg => "prisma db push --force-reset/--accept-data-loss 금지. $MIG_TAIL" };
push @RULES, { name => 'rails-db',        re => qr{(^|[;&|]\s*)(bundle\s+exec\s+)?(rails|rake)\s+db:(drop|reset|rollback|migrate:reset|schema:load|structure:load|truncate_all|seed:replant)\b},
  msg => "rails/rake db:drop|reset|rollback|migrate:reset 금지. $MIG_TAIL" };
push @RULES, { name => 'alembic',         re => qr{(^|[;&|]\s*)alembic\s+downgrade\b},
  msg => "alembic downgrade 금지. $MIG_TAIL" };
push @RULES, { name => 'knex',            re => qr{(^|[;&|]\s*)(npx\s+|pnpm\s+|yarn\s+)?knex\s+migrate:rollback\b},
  msg => "knex migrate:rollback 금지. $MIG_TAIL" };
push @RULES, { name => 'typeorm',         re => qr{(^|[;&|]\s*)(npx\s+|pnpm\s+|yarn\s+)?typeorm\s+(migration:revert|schema:drop)\b},
  msg => "typeorm migration:revert / schema:drop 금지. $MIG_TAIL" };
push @RULES, { name => 'sqitch',          re => qr{(^|[;&|]\s*)sqitch\s+revert\b},
  msg => "sqitch revert 금지. $MIG_TAIL" };
push @RULES, { name => 'flyway',          re => qr{(^|[;&|]\s*)flyway\s+(clean|undo)\b},
  msg => "flyway clean/undo 금지. $MIG_TAIL" };

# ---------- Docker ----------
push @RULES, { name => 'docker-rm',       re => qr{(^|[;&|]\s*)docker\s+(rm|rmi)\b},
  msg => "docker rm/rmi 금지 — 컨테이너/이미지 삭제는 사용자만. $DOCKER_TAIL" };
push @RULES, { name => 'docker-prune',    re => qr{(^|[;&|]\s*)docker\s+(volume|network|image|container|builder|system)\s+(rm|prune)\b},
  msg => "docker volume/network/image/system rm|prune 금지 — 데이터/캐시 삭제는 사용자만. $DOCKER_TAIL" };
push @RULES, { name => 'docker-down-v',   re => qr{(^|[;&|]\s*)docker(\s+compose|-compose)\s+down\b[^;&|]*(\s-v\b|\s--volumes\b)},
  msg => "docker compose down -v/--volumes 금지 — 볼륨 삭제로 DB 데이터 손실. -v 없이 down은 허용. $DOCKER_TAIL" };
push @RULES, { name => 'docker-kill',     re => qr{(^|[;&|]\s*)docker(\s+compose|-compose)?\s+kill\b},
  msg => "docker kill 금지 — SIGKILL은 사용자만. graceful 종료는 docker stop을 사용. $DOCKER_TAIL" };

# ============================================================
# 동적 검사 콜백
# ============================================================
# git commit 시 staged 영역에 빌드 산출물/바이너리/대용량 파일이 있으면 차단.
# 이미지(png/jpg/gif/webp/svg/ico/bmp)는 정상 커밋 대상으로 분류.
sub check_commit_binary {
  my $staged = `git diff --cached --name-only 2>/dev/null`;
  return (0, undef) unless length $staged;

  my @files = grep { length } split /\n/, $staged;
  return (0, undef) unless @files;

  my $img_re = qr{\.(png|jpe?g|gif|webp|svg|ico|bmp)$}i;
  my $bad_re = qr{\.(so|dylib|dll|exe|bin|pyc|class|jar|wasm|zip|tar|t?gz|7z|rar|sqlite3?|db|lockb|mp4|mov|mp3|wav)$|(^|/)\.DS_Store$}i;

  my (@bad_ext, @big);
  for my $f (@files) {
    push @bad_ext, $f if $f =~ $bad_re;
    next if $f =~ $img_re;
    if (-f $f) {
      my $sz = (stat $f)[7] // 0;
      push @big, sprintf('%s (%dKB)', $f, int($sz/1024)) if $sz > 1048576;
    }
  }

  my @bins;
  my $numstat = `git diff --cached --numstat 2>/dev/null`;
  for my $line (split /\n/, $numstat) {
    if ($line =~ /^-\s+-\s+(.+)$/) {
      my $f = $1;
      next if $f =~ $img_re || $f =~ $bad_re;
      push @bins, $f;
    }
  }

  return (0, undef) unless @bad_ext || @big || @bins;

  my $msg = '';
  if (@bad_ext) {
    $msg .= "\n[빌드/압축/DB/미디어 파일 — .gitignore 권장]\n" . join("\n", @bad_ext) . "\n조치: .gitignore 에 패턴 추가 + git rm --cached <path>\n";
  }
  if (@big) {
    $msg .= "\n[1MB 초과 — 저장소 비대화 위험]\n" . join("\n", @big) . "\n조치: .gitignore 추가 또는 Git LFS 검토 (git lfs track)\n";
  }
  if (@bins) {
    $msg .= "\n[git binary 판정 — 비이미지]\n" . join("\n", @bins) . "\n조치: .gitattributes 확인 또는 Git LFS 검토\n";
  }
  $msg .= "\n의도적 커밋이면 사용자에게 ! git commit 직접 실행 요청.";
  return (1, $msg);
}

# ============================================================
# 엔진
# ============================================================
sub match_rule {
  my ($cmd, $rule) = @_;
  return (0, undef) unless $cmd =~ $rule->{re};
  if ($rule->{cond}) {
    return (0, undef) unless $cmd =~ $rule->{cond};
  }
  if ($rule->{dyn}) {
    my ($block, $msg_override) = $rule->{dyn}->($cmd);
    return (0, undef) unless $block;
    return (1, $msg_override // $rule->{msg});
  }
  return (1, $rule->{msg});
}

sub evaluate {
  my ($cmd) = @_;
  for my $rule (@RULES) {
    my ($blocked, $msg) = match_rule($cmd, $rule);
    return ($rule->{name}, $msg) if $blocked;
  }
  return (undef, undef);
}

# ============================================================
# 셀프테스트
# ============================================================
sub run_tests {
  # 각 케이스: [command, expected_rule_name_or_undef, description]
  # 외부 git 상태에 의존하는 동적 룰(commit-binary)은 통합 테스트에서 제외.
  my @cases = (
    # 디렉토리/경로
    ['cd /Users/x/.claude/worktrees/abc',          'cd-worktree',     'cd worktree 차단'],
    ['cd /some/other/path',                        undef,             'cd 일반 경로 통과'],
    ['git -C /Users/x/.claude/worktrees/abc status','git-C-worktree', 'git -C worktree 차단'],
    ['git -C /Users/x/other status',               undef,             'git -C 다른 경로 통과'],
    ['GIT_DIR=/tmp git log',                       'git-dir-env',     'GIT_DIR env'],
    ['git --git-dir=/tmp log',                     'git-dir-flag',    '--git-dir'],
    ['git --work-tree=/tmp status',                'work-tree-flag',  '--work-tree'],
    # Git
    ['git commit --amend',                         'commit-amend',    'commit --amend'],
    ['git checkout -b new',                        'checkout-b',      'checkout -b'],
    ['git checkout main',                          undef,             'checkout 일반 통과'],
    ['git add -A',                                 'git-add-broad',   'git add -A'],
    ['git add --all',                              'git-add-broad',   'git add --all'],
    ['git add .',                                  'git-add-broad',   'git add .'],
    ['git add file.txt',                           undef,             'git add 명시 통과'],
    ['git push --no-verify',                       'no-verify',       '--no-verify'],
    # 기본 명령
    ['cat foo',                                    'cat-head-tail',   'cat'],
    ['head -n 5 file',                             'cat-head-tail',   'head'],
    ['tail file',                                  'cat-head-tail',   'tail'],
    ['ls | cat file',                              'cat-head-tail',   'pipe cat'],
    ['echo hi',                                    'echo',            'echo'],
    ['rm file',                                    'rm',              'rm'],
    ['rm -rf dir',                                 'rm',              'rm -rf'],
    ['rmdir foo',                                  undef,             'rmdir 통과'],
    ['npm rm foo',                                 undef,             'npm rm 통과'],
    ['git rm file',                                undef,             'git rm 통과'],
    # K8s/IaC
    ['helmfile apply',                             'helmfile',        'helmfile apply'],
    ['helmfile diff',                              undef,             'helmfile diff 통과'],
    ['kubectl apply -f x.yaml',                    'kubectl-mutating','kubectl apply'],
    ['kubectl get pods',                           undef,             'kubectl get 통과'],
    ['kubectl rollout restart deploy/foo',         'kubectl-rollout', 'rollout restart'],
    ['kubectl rollout status deploy/foo',          undef,             'rollout status 통과'],
    ['helm install foo bar',                       'helm',            'helm install'],
    ['helm list',                                  undef,             'helm list 통과'],
    ['terraform apply',                            'terraform',       'terraform apply'],
    ['terraform plan',                             undef,             'terraform plan 통과'],
    ['argocd app sync myapp',                      'argocd',          'argocd sync'],
    ['argocd app get myapp',                       undef,             'argocd get 통과'],
    # AWS
    ['aws ec2 delete-snapshot --snapshot-id snap', 'aws-destructive', 'aws delete-snapshot'],
    ['aws ec2 describe-instances',                 undef,             'aws describe 통과'],
    ['aws s3 rm s3://bkt/obj',                     'aws-s3-rm',       'aws s3 rm'],
    ['aws s3 cp file s3://bkt/',                   undef,             'aws s3 cp 통과'],
    ['aws s3 sync . s3://bkt --delete',            'aws-s3-sync-del', 's3 sync --delete'],
    ['aws s3 sync . s3://bkt',                     undef,             's3 sync 일반 통과'],
    ['aws iam create-user --user-name foo',        'aws-iam',         'iam create-user'],
    ['aws iam list-users',                         undef,             'iam list 통과'],
    ['aws secretsmanager put-secret-value',        'aws-secrets',     'secrets put'],
    ['aws kms describe-key',                       undef,             'kms describe 통과'],
    ['aws cloudformation create-stack',            'aws-cfn',         'cfn create-stack'],
    ['aws cloudformation describe-stacks',         undef,             'cfn describe 통과'],
    ['aws ec2 run-instances --image-id ami',       'aws-ec2-run',     'ec2 run-instances'],
    ['aws ec2 authorize-security-group-ingress',   'aws-ec2-sg',      'ec2 authorize-sg'],
    ['aws ec2 modify-instance-attribute',          'aws-ec2-modify',  'ec2 modify'],
    ['aws rds modify-db-instance',                 'aws-rds',         'rds modify'],
    ['aws rds describe-db-instances',              undef,             'rds describe 통과'],
    ['aws lambda update-function-code',            'aws-lambda',      'lambda update'],
    ['aws lambda list-functions',                  undef,             'lambda list 통과'],
    ['aws route53 change-resource-record-sets',    'aws-route53',     'route53 change'],
    ['aws route53 list-hosted-zones',              undef,             'route53 list 통과'],
    ['aws dynamodb put-item',                      'aws-dynamodb',    'dynamodb put'],
    ['aws dynamodb get-item',                      undef,             'dynamodb get 통과'],
    ['aws ses send-email',                         'aws-ses',         'ses send'],
    ['aws sns publish --topic-arn arn',            'aws-sns',         'sns publish'],
    ['aws ecs update-service',                     'aws-ecs',         'ecs update'],
    ['aws ecs list-services',                      undef,             'ecs list 통과'],
    ['aws eks update-cluster-config',              'aws-eks',         'eks update'],
    ['aws eks describe-cluster',                   undef,             'eks describe 통과'],
    # DB CLI
    ['psql -c "DROP TABLE users"',                 'sql-cli-mutating','psql DROP'],
    ['psql -c "SELECT * FROM users"',              undef,             'psql SELECT 통과'],
    ['mysql -e "TRUNCATE TABLE x"',                'sql-cli-mutating','mysql TRUNCATE'],
    ['mysql -e "DELETE FROM x WHERE id=1"',        'sql-cli-mutating','mysql DELETE'],
    ['mysql -e "UPDATE x SET a=1"',                'sql-cli-mutating','mysql UPDATE'],
    ['sqlite3 db.sqlite "DROP TABLE t"',           'sql-cli-mutating','sqlite DROP'],
    ['mongosh --eval "db.x.drop()"',               'mongo-mutating',  'mongo drop'],
    ['mongosh --eval "db.x.find()"',               undef,             'mongo find 통과'],
    ['redis-cli FLUSHALL',                         'redis-flush',     'redis flushall'],
    ['redis-cli GET foo',                          undef,             'redis GET 통과'],
    # 마이그레이션
    ['prisma migrate reset',                       'prisma-reset',    'prisma reset'],
    ['npx prisma migrate reset',                   'prisma-reset',    'npx prisma reset'],
    ['prisma db push --force-reset',               'prisma-push',     'prisma push --force-reset'],
    ['prisma db push',                             undef,             'prisma push 일반 통과'],
    ['rails db:drop',                              'rails-db',        'rails db:drop'],
    ['bundle exec rake db:reset',                  'rails-db',        'rake db:reset'],
    ['rails db:migrate',                           undef,             'rails db:migrate 통과'],
    ['alembic downgrade -1',                       'alembic',         'alembic downgrade'],
    ['alembic upgrade head',                       undef,             'alembic upgrade 통과'],
    ['knex migrate:rollback',                      'knex',            'knex rollback'],
    ['typeorm migration:revert',                   'typeorm',         'typeorm revert'],
    ['typeorm schema:drop',                        'typeorm',         'typeorm schema:drop'],
    ['sqitch revert',                              'sqitch',          'sqitch revert'],
    ['flyway clean',                               'flyway',          'flyway clean'],
    ['flyway migrate',                             undef,             'flyway migrate 통과'],
    # Docker
    ['docker rm abc',                              'docker-rm',       'docker rm'],
    ['docker rmi img',                             'docker-rm',       'docker rmi'],
    ['docker ps',                                  undef,             'docker ps 통과'],
    ['docker volume rm v',                         'docker-prune',    'docker volume rm'],
    ['docker system prune',                        'docker-prune',    'docker system prune'],
    ['docker compose down -v',                     'docker-down-v',   'compose down -v'],
    ['docker compose down',                        undef,             'compose down 통과'],
    ['docker kill abc',                            'docker-kill',     'docker kill'],
    ['docker stop abc',                            undef,             'docker stop 통과'],
  );

  my ($pass, $fail) = (0, 0);
  my @failures;
  for my $c (@cases) {
    my ($cmd, $expected, $desc) = @$c;
    my ($got) = evaluate($cmd);
    my $ok = (!defined $expected && !defined $got)
          || (defined $expected && defined $got && $got eq $expected);
    if ($ok) {
      $pass++;
    } else {
      $fail++;
      push @failures, sprintf("FAIL  %-40s expected=%-22s got=%-22s\n  cmd: %s",
        $desc, ($expected // '(pass)'), ($got // '(pass)'), $cmd);
    }
  }
  binmode STDOUT, ':utf8';
  print "$_\n" for @failures;
  print "\n" if @failures;
  printf "%d passed, %d failed (%d cases, %d rules)\n",
    $pass, $fail, $pass+$fail, scalar(@RULES);
  exit($fail ? 1 : 0);
}

# ============================================================
# 메인
# ============================================================
if (@ARGV && ($ARGV[0] eq '--test' || $ARGV[0] eq '-t')) {
  run_tests();
  exit 0;
}

my $raw = do { local $/; <STDIN> };
exit 0 unless defined $raw && length $raw;

my $input = eval { decode_json($raw) };
exit 0 unless $input && ref($input) eq 'HASH';
exit 0 unless ($input->{tool_name} // '') eq 'Bash';

my $cmd = $input->{tool_input}{command} // '';
exit 0 unless length $cmd;

my ($rule_name, $msg) = evaluate($cmd);
if ($rule_name) {
  print encode_json({ decision => 'block', reason => $msg }), "\n";
}
exit 0;
