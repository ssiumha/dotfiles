#!/usr/bin/env perl
# PreToolUse hook for Write: 스크래치패드 과다 산출물 가드.
# 스크래치패드에 파일이 임계치 이상 쌓인 상태에서 추가 Write가 오면
# permissionDecision=ask 로 사용자 확인을 요구한다 — 합의 없는 다중 파일
# 검증 인프라(재현 하네스·스택 구성)가 조용히 자라는 것을 막는 안전망.
# 백그라운드 서브에이전트는 프롬프트를 띄울 수 없으므로 사실상 차단된다.
use strict;
use warnings;
use utf8;
use JSON::PP;
use File::Find;

my $THRESHOLD = 5;

# 사용자가 다중 파일 작업을 승인한 세션에서는 CLAUDE_SCRATCHPAD_GUARD=0 으로 비활성화
exit 0 if ($ENV{CLAUDE_SCRATCHPAD_GUARD} // '') eq '0';

binmode STDIN,  ':raw';
binmode STDOUT, ':raw';

my $raw = do { local $/; <STDIN> };
exit 0 unless defined $raw && length $raw;

my $input = eval { decode_json($raw) };
exit 0 unless $input && ref($input) eq 'HASH';

my $path = $input->{tool_input}{file_path} // '';
exit 0 unless length $path;

# 경로에서 마지막 'scratchpad' 세그먼트를 루트로 잡는다
my @segs = split m{/}, $path;
my ($idx) = grep { $segs[$_] eq 'scratchpad' } reverse 0 .. $#segs;
exit 0 unless defined $idx;

my $root = join('/', @segs[0 .. $idx]);
exit 0 unless -d $root;

my $count = 0;
find(sub { $count++ if -f }, $root);
exit 0 if $count < $THRESHOLD;

print encode_json({
  hookSpecificOutput => {
    hookEventName            => 'PreToolUse',
    permissionDecision       => 'ask',
    permissionDecisionReason => "스크래치패드에 이미 ${count}개 파일이 있습니다. 합의 없는 다중 파일 산출물(검증 하네스·스택 구성)이 아닌지 확인하세요. 계획에 있는 작업이면 승인, 아니면 거부 후 접근 방식을 사용자와 먼저 합의하세요.",
  },
}), "\n";
exit 0;
