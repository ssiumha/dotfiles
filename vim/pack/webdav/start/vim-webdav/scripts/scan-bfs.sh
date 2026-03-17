#!/bin/bash
# Streaming BFS scanner for WebDAV directories
# Outputs files as discovered — designed to pipe into fzf
#
# Usage: scan-bfs.sh <base_url> <base_path> <max_depth> [auth_arg]
# Example: scan-bfs.sh "http://host:8080" "/vault/" 3 "-u user:pass"

set -euo pipefail

BASE_URL="$1"
BASE_PATH="$2"
MAX_DEPTH="${3:-3}"
AUTH_ARG="${4:-}"

propfind() {
  local path="$1"
  local encoded
  encoded=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe='/'))" "$path")
  curl -s --max-time 10 -X PROPFIND -H "Depth: 1" $AUTH_ARG "${BASE_URL}${encoded}" \
  | perl -MURI::Escape -e '
    my $first=1; my $base=""; my @d=(); my @f=();
    while(<STDIN>) {
      while(/<D:href>([^<]*)<\/D:href>/g) {
        my $p=uri_unescape($1);
        if($first){$first=0;$base=$p;next}
        $p=~s/^\Q$base\E//;
        if($p=~m{/$}){push @d,$p}else{push @f,$p}
      }
    }
    print "$_\n" for sort @f;
    print "DIR:$_\n" for sort @d;
  ' 2>/dev/null
}

# BFS with depth limit
# Queue entries: tab-separated "depth\tpath"
TAB=$'\t'
declare -a queue
queue+=("0${TAB}${BASE_PATH}")

while [ ${#queue[@]} -gt 0 ]; do
  entry="${queue[0]}"
  queue=("${queue[@]:1}")

  depth="${entry%%${TAB}*}"
  current_path="${entry#*${TAB}}"

  while IFS= read -r line; do
    [ -z "$line" ] && continue
    if [[ "$line" == DIR:* ]]; then
      dir="${line#DIR:}"
      next_depth=$((depth + 1))
      if [ "$next_depth" -lt "$MAX_DEPTH" ]; then
        queue+=("${next_depth}${TAB}${current_path}${dir}")
      fi
    else
      # Output path relative to BASE_PATH
      rel="${current_path#"$BASE_PATH"}"
      echo "${rel}${line}"
    fi
  done < <(propfind "$current_path")
done
