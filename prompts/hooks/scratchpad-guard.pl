#!/usr/bin/env perl
# 스크래치패드 다중 파일 가드 (PreToolUse + PostToolUse, matcher: Write).
#
# 합의 없는 다중 파일 검증 인프라(재현 하네스·스택 구성)가 스크래치패드에 조용히
# 자라는 것을 막는다.
#
# 판정 스코프는 Write 대상의 **직속 디렉토리**다. 하위 트리를 재귀로 세지 않으므로
# Bash가 만든 clone·빌드 산출물이 판정을 오염시키지 않는다.
#
# 승인은 디렉토리당 한 번이다. Pre가 물을 때 pending 마커를 남기고, Write가 실제로
# 실행되면(= 사용자가 승인했다는 유일한 증거) Post가 approved로 승격한다. 거부되면
# Post가 돌지 않으므로 승격도 없고 다음 Write에서 다시 묻는다.
#
# 사용:
#   stdin JSON           → Pre 판정 (ask일 때만 JSON 출력, 통과면 무출력 + exit 0)
#   --post + stdin JSON  → Post 승인 승격
#   --test               → 내장 회귀 테스트
use strict;
use warnings;
use utf8;
use JSON::PP;

my $THRESHOLD = 10;
my $PENDING   = '.scratch-ask';
my $APPROVED  = '.scratch-ack';

# 전역 kill switch. 훅은 Claude Code 프로세스의 env를 상속하므로 셸 export로는
# 전달되지 않는다 — settings.json 의 "env" 에 설정할 것.
my $DISABLED = ($ENV{CLAUDE_SCRATCHPAD_GUARD} // '') eq '0';

# ============================================================
# 판정
# ============================================================

# Write 대상 경로 → 판정 대상 디렉토리(직속 부모). 스크래치패드 밖이면 undef.
# 'scratchpad'는 디렉토리 세그먼트여야 한다 — basename이 scratchpad인 파일은 제외.
sub guard_dir {
  my ($path) = @_;
  return undef unless defined $path && length $path;
  my @segs = split m{/}, $path;
  return undef if @segs < 2;
  my ($idx) = grep { $segs[$_] eq 'scratchpad' } reverse 0 .. $#segs - 1;
  return undef unless defined $idx;
  my $dir = join('/', @segs[0 .. $#segs - 1]);
  return length($dir) ? $dir : '/';
}

# 직속 디렉토리의 일반 파일 수. 하위 디렉토리와 마커는 세지 않는다.
sub file_count {
  my ($dir) = @_;
  opendir(my $dh, $dir) or return 0;
  my $n = 0;
  while (defined(my $entry = readdir $dh)) {
    next if $entry eq '.' || $entry eq '..';
    next if $entry eq $PENDING || $entry eq $APPROVED;
    $n++ if -f "$dir/$entry";
  }
  closedir $dh;
  return $n;
}

# ask 해야 하면 (디렉토리, 파일 수), 통과면 빈 리스트.
sub evaluate {
  my ($path) = @_;
  return () if $DISABLED;
  my $dir = guard_dir($path);
  return () unless defined $dir && -d $dir;
  return () if -e "$dir/$APPROVED";
  my $count = file_count($dir);
  return () if $count < $THRESHOLD;
  return ($dir, $count);
}

# ============================================================
# 승인 마커
# ============================================================

sub mark_pending {
  my ($dir) = @_;
  return 0 if -e "$dir/$PENDING";
  open(my $fh, '>', "$dir/$PENDING") or return 0;
  close $fh;
  return 1;
}

sub promote_pending {
  my ($path) = @_;
  my $dir = guard_dir($path);
  return 0 unless defined $dir && -d $dir;
  return 0 unless -e "$dir/$PENDING";
  return rename("$dir/$PENDING", "$dir/$APPROVED") ? 1 : 0;
}

# 세션 스크래치패드 절대경로는 길다 — scratchpad 이하만 보여준다.
sub display_dir {
  my ($dir) = @_;
  my @segs = split m{/}, $dir;
  my ($idx) = grep { $segs[$_] eq 'scratchpad' } reverse 0 .. $#segs;
  return $dir unless defined $idx;
  return join('/', @segs[$idx .. $#segs]);
}

# ============================================================
# 셀프테스트
# ============================================================
sub run_tests {
  require File::Temp;
  require File::Path;
  binmode STDOUT, ':utf8';

  my ($pass, $fail) = (0, 0);
  my @failures;
  my $ok = sub {
    my ($cond, $desc, $detail) = @_;
    if ($cond) { $pass++; return }
    $fail++;
    push @failures, "FAIL  $desc" . (defined $detail ? "\n  $detail" : '');
  };

  my $tmp = File::Temp::tempdir(CLEANUP => 1);

  # 파일 $n개를 담은 스크래치패드 하위 디렉토리를 만든다.
  my $build = sub {
    my ($case, $sub, $n) = @_;
    my $dir = join('/', $tmp, $case, 'scratchpad', grep { length } ($sub // ''));
    File::Path::make_path($dir);
    for my $i (1 .. $n) {
      open(my $fh, '>', sprintf('%s/f%03d.txt', $dir, $i)) or die "$dir: $!";
      close $fh;
    }
    return $dir;
  };

  # --- guard_dir: 스코프 판정 ---
  $ok->(!defined guard_dir('/Users/x/repo/src/a.txt'),
        'guard_dir 스크래치패드 밖 → undef');
  $ok->(!defined guard_dir(''),
        'guard_dir 빈 경로 → undef');
  $ok->(!defined guard_dir('/tmp/x/scratchpad'),
        'guard_dir basename이 scratchpad → undef (디렉토리 세그먼트만 인정)');
  $ok->((guard_dir('/tmp/s/scratchpad/a.txt') // '') eq '/tmp/s/scratchpad',
        'guard_dir 루트 직속 → 스크래치패드 루트');
  $ok->((guard_dir('/tmp/s/scratchpad/sub/deep/a.txt') // '') eq '/tmp/s/scratchpad/sub/deep',
        'guard_dir 중첩 → 직속 부모');

  # --- file_count: 무엇을 세는가 ---
  my $mixed = $build->('count', '', 3);
  File::Path::make_path("$mixed/noise");
  open(my $nf, '>', "$mixed/noise/x.txt") or die $!; close $nf;
  open(my $pf, '>', "$mixed/$PENDING")    or die $!; close $pf;
  $ok->(file_count($mixed) == 3,
        'file_count 하위 디렉토리·마커 제외', 'got ' . file_count($mixed));

  # --- 임계치 ---
  my $under = $build->('under', '', $THRESHOLD - 1);
  $ok->(scalar(() = evaluate("$under/new.txt")) == 0,
        "임계치 미만 → 통과");

  my $at = $build->('at', '', $THRESHOLD);
  my ($at_dir, $at_count) = evaluate("$at/new.txt");
  $ok->(defined $at_dir && $at_count == $THRESHOLD,
        '임계치 도달 → ask', 'got ' . ($at_count // 'undef'));

  # --- 회귀: 하위 트리 노이즈는 판정에 영향을 주지 않는다 ---
  # git clone 한 번으로 수백 개가 쌓여 루트 Write가 전부 ask 되던 케이스.
  my $noisy = $build->('noisy', '', 3);
  $build->('noisy', 'orig-check', 200);
  $ok->(scalar(() = evaluate("$noisy/new.txt")) == 0,
        '하위 트리 200개가 있어도 루트 3개면 통과 (재귀 카운트 회귀)');

  # 하위 디렉토리는 자기 기준으로 판정된다
  my ($deep_dir, $deep_count) = evaluate("$noisy/orig-check/new.txt");
  $ok->(defined $deep_dir && $deep_count == 200,
        '하위 디렉토리는 자기 파일 수로 판정', 'got ' . ($deep_count // 'undef'));

  # --- 승인 latch: ask → 승인 → 이후 통과 ---
  my $latch = $build->('latch', '', $THRESHOLD);
  my ($latch_dir) = evaluate("$latch/new.txt");
  $ok->(defined $latch_dir, 'latch 최초 Write → ask');
  mark_pending($latch_dir);
  $ok->(-e "$latch/$PENDING", 'ask 시 pending 마커 생성');
  $ok->(promote_pending("$latch/new.txt") == 1, 'Write 실행 → pending 승격');
  $ok->(-e "$latch/$APPROVED" && !-e "$latch/$PENDING", '승격 후 approved만 남는다');
  $ok->(scalar(() = evaluate("$latch/new2.txt")) == 0,
        '승인된 디렉토리는 이후 Write에서 다시 묻지 않는다');

  # --- 거부: Post가 돌지 않으므로 승격도 없다 ---
  my $deny = $build->('deny', '', $THRESHOLD);
  my ($deny_dir) = evaluate("$deny/new.txt");
  mark_pending($deny_dir);
  # (Post 미실행 — 사용자가 거부한 상황)
  $ok->(scalar(() = evaluate("$deny/new.txt")) == 2,
        '거부 후에는 계속 ask');

  # --- 승인은 디렉토리 단위다 ---
  my $sibling = $build->('latch', 'other', $THRESHOLD);
  $ok->(scalar(() = evaluate("$sibling/new.txt")) == 2,
        '형제 디렉토리에 승인이 전파되지 않는다');
  $ok->(promote_pending("$sibling/new.txt") == 0,
        'pending 없는 디렉토리 승격은 no-op');

  # --- display_dir ---
  $ok->(display_dir('/private/tmp/claude-501/proj/sid/scratchpad/sub') eq 'scratchpad/sub',
        'display_dir scratchpad 이하만 표시');

  print "$_\n" for @failures;
  print "\n" if @failures;
  printf "%d passed, %d failed (%d cases)\n", $pass, $fail, $pass + $fail;
  exit($fail ? 1 : 0);
}

# ============================================================
# 메인
# ============================================================
sub read_path {
  binmode STDIN, ':raw';
  my $raw = do { local $/; <STDIN> };
  return undef unless defined $raw && length $raw;
  my $input = eval { decode_json($raw) };
  return undef unless $input && ref($input) eq 'HASH';
  my $path = $input->{tool_input}{file_path};
  return (defined $path && length $path) ? $path : undef;
}

run_tests() if @ARGV && ($ARGV[0] eq '--test' || $ARGV[0] eq '-t');

binmode STDOUT, ':raw';

if (@ARGV && $ARGV[0] eq '--post') {
  my $path = read_path();
  promote_pending($path) if defined $path;
  exit 0;
}

my $path = read_path();
exit 0 unless defined $path;

my ($dir, $count) = evaluate($path);
exit 0 unless defined $dir;

mark_pending($dir);

print encode_json({
  hookSpecificOutput => {
    hookEventName            => 'PreToolUse',
    permissionDecision       => 'ask',
    permissionDecisionReason => sprintf(
      "%s 에 이미 %d개 파일이 있습니다. 합의 없는 다중 파일 산출물(검증 하네스·스택 구성)이 아닌지 확인하세요. 승인하면 이 디렉토리에서는 다시 묻지 않습니다. 계획에 없는 작업이면 거부 후 접근 방식을 사용자와 먼저 합의하세요.",
      display_dir($dir), $count),
  },
}), "\n";
exit 0;
