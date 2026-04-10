local engine = require('stargazer.engine')
local build_rank_awk = engine._build_rank_awk

--------------------------------------------------------------------------------
-- Helper: run shell command with input via temp file
--------------------------------------------------------------------------------

local function run_awk(input, awk_pipe)
  local tmp = os.tmpname()
  local f = io.open(tmp, 'w')
  f:write(input)
  f:close()
  local result = vim.fn.systemlist('cat ' .. tmp .. awk_pipe)
  os.remove(tmp)
  return result
end

--------------------------------------------------------------------------------
-- Tests
--------------------------------------------------------------------------------

T.describe('rank_awk: generation', function()
  local awk = build_rank_awk({
    { pattern = '(class|interface) \\w*{q}' },
    { pattern = '@(entity|table)' },
  }, 'wallet')

  T.match(awk, 'seen%[', 'dedup included')
  T.match(awk, 'wallet', '{q} interpolated')
  T.match(awk, 'a1%[', 'bucket 1 exists')
  T.match(awk, 'a2%[', 'bucket 2 exists')
  T.match(awk, 'a3%[', 'fallback bucket exists')
end)

T.describe('rank_awk: no query interpolation', function()
  local awk = build_rank_awk({
    { pattern = '@service' },
  }, nil)

  T.no_match(awk, '{q}', '{q} removed when no query')
  T.match(awk, '@service', 'pattern preserved')
  T.match(awk, 'a2%[', 'fallback bucket (patterns=1 -> a2)')
end)

T.describe('rank_awk: actual sort', function()
  local fixture = SPEC_DIR .. '/fixtures/rg_infer_wallet.txt'
  local lines = vim.fn.readfile(fixture)
  local input = table.concat(lines, '\n') .. '\n'

  -- Simplified patterns (no \w for broad awk compat)
  local awk = build_rank_awk({
    { pattern = 'class [a-zA-Z]*{q}' },
    { pattern = '@(entity|table)' },
  }, 'wallet')

  local result = run_awk(input, awk)

  -- 8 input lines, 1 duplicate (Wallet.java:10) -> 7 output
  T.eq(#result, 7, 'dedup: 8 input -> 7 (one duplicate removed)')

  -- Bucket 1: class + wallet in name (fixture order: Wallet then WalletsClient)
  T.match(result[1] or '', 'class Wallet extends', '1st: class Wallet (exact)')
  T.match(result[2] or '', 'class WalletsClient', '2nd: class WalletsClient (partial)')

  -- Bucket 2: @Entity / @Table
  local bucket2 = (result[3] or '') .. (result[4] or '')
  T.match(bucket2, '@Table', '@Table in bucket 2')
  T.match(bucket2, '@Entity', '@Entity in bucket 2')

  -- Bucket 3 (fallback): remaining lines
  T.ok(#result >= 5, 'fallback lines present')
end)

T.describe('rank_awk: dedup same file:line', function()
  local awk = build_rank_awk({ { pattern = 'class' } }, nil)
  local input = table.concat({
    'foo.java:10:1:class Foo',
    'foo.java:10:1:class Foo',
    'bar.java:5:1:class Bar',
  }, '\n') .. '\n'
  local result = run_awk(input, awk)
  T.eq(#result, 2, 'dedup: exact same file:line collapsed')
end)

--------------------------------------------------------------------------------
-- grouped mode
--------------------------------------------------------------------------------

T.describe('rank_awk: grouped header generation', function()
  local awk = build_rank_awk({
    { pattern = '(class|interface) [a-zA-Z]*{q}', header = 'define' },
    { pattern = '@(entity|table)', header = 'schema' },
  }, 'wallet', true)

  T.match(awk, 'define', 'header: define present')
  T.match(awk, 'schema', 'header: schema present')
  T.match(awk, 'reference', 'header: reference (fallback) present')
  T.match(awk, '033%[1;36m', 'ANSI cyan bold for headers')
end)

T.describe('rank_awk: grouped actual sort with headers', function()
  local fixture = SPEC_DIR .. '/fixtures/rg_infer_oracle.txt'
  local lines = vim.fn.readfile(fixture)
  local input = table.concat(lines, '\n') .. '\n'

  local awk = build_rank_awk({
    { pattern = '(class|interface|type|enum) [a-zA-Z]*{q}', header = 'define' },
    { pattern = '\\.(yml|yaml|xml|json|properties|toml):', header = 'config' },
    { pattern = '@(entity|table|document|schema)|create.table|add.column', header = 'schema' },
    { pattern = '@(service|repository|component|injectable|controller)', header = 'domain' },
    { pattern = '(def |function |fn )', header = 'method' },
  }, 'oracle', true)

  local result = run_awk(input, awk)

  -- 헤더 라인 찾기
  local headers = {}
  for i, line in ipairs(result) do
    if line:match('──') then
      headers[#headers + 1] = { idx = i, name = line:match('── (.+) ──') }
    end
  end

  T.ok(#headers >= 3, 'at least 3 group headers present')

  -- define 그룹이 첫 번째
  T.eq(headers[1].name, 'define', 'first group: define')

  -- 빈 그룹은 헤더 없음 (method 그룹에 def/function/fn 없음 → 표시 안됨은 fixture 의존)
end)

T.describe('rank_awk: grouped empty group suppressed', function()
  local input = table.concat({
    'a.java:1:1:class Oracle',
    'b.java:2:1:oracleService.call()',
  }, '\n') .. '\n'

  local awk = build_rank_awk({
    { pattern = 'class [a-zA-Z]*{q}', header = 'define' },
    { pattern = '@entity', header = 'schema' },
  }, 'oracle', true)

  local result = run_awk(input, awk)

  -- schema 그룹 헤더(── schema ──)가 없어야 함 (상태줄에는 카운트로 나올 수 있음)
  local has_schema_header = false
  for _, line in ipairs(result) do
    if line:match('── schema ──') then has_schema_header = true end
  end
  T.eq(has_schema_header, false, 'empty schema group: no section header')
end)

T.describe('rank_awk: filter_bucket single group', function()
  local fixture = SPEC_DIR .. '/fixtures/rg_infer_oracle.txt'
  local lines = vim.fn.readfile(fixture)
  local input = table.concat(lines, '\n') .. '\n'

  -- filter_bucket=1 → define 그룹만 (class/interface/type/enum + oracle)
  local awk = build_rank_awk({
    { pattern = '(class|interface|type|enum) [a-zA-Z]*{q}', header = 'define' },
    { pattern = '\\.(yml|yaml|xml|json|properties|toml):', header = 'config' },
    { pattern = '@(entity|table|document|schema)|create.table|add.column', header = 'schema' },
    { pattern = '@(service|repository|component|injectable|controller)', header = 'domain' },
    { pattern = '(def |function |fn )', header = 'method' },
  }, 'oracle', true, 1)

  local result = run_awk(input, awk)

  -- 첫 줄은 상태줄, 나머지는 define 그룹만
  T.ok(#result > 1, 'filter_bucket=1: has results (status + data)')
  -- 상태줄 이후의 결과가 class/interface 정의여야 함
  for i = 2, #result do
    T.match(result[i], 'class', 'filter_bucket=1: only define lines')
  end
end)

T.describe('rank_awk: filter_bucket fallback (reference)', function()
  local input = table.concat({
    'a.java:1:1:class Oracle',
    'b.java:2:1:use oracle somewhere',
    'c.java:3:1:oracle.call()',
  }, '\n') .. '\n'

  -- filter_bucket=2 (fallback) → reference 라인만
  local awk = build_rank_awk({
    { pattern = 'class [a-zA-Z]*{q}', header = 'define' },
  }, 'oracle', true, 2)

  local result = run_awk(input, awk)
  -- 상태줄 1 + reference 2줄 = 3
  T.eq(#result, 3, 'filter fallback: status + 2 reference lines')
  T.no_match(result[2] or '', 'class Oracle', 'filter fallback: no define lines')
end)

T.describe('rank_awk: grouped reference cap', function()
  -- reference 버킷에 25줄 넣기 (cap=20)
  local lines = {}
  for i = 1, 25 do
    lines[#lines + 1] = string.format('ref%d.java:%d:1:use oracle', i, i)
  end
  local input = table.concat(lines, '\n') .. '\n'

  local awk = build_rank_awk({
    { pattern = 'class', header = 'define' },
  }, 'oracle', true)

  local result = run_awk(input, awk)

  -- 상태줄 + reference 헤더 + 20줄 + "... +5 more" = 23줄
  T.eq(#result, 23, 'reference cap: status + 1 header + 20 lines + 1 more line')
  T.match(result[#result] or '', 'more', 'last line shows remaining count')
end)

T.describe('rank_awk: multi-pattern first match wins', function()
  local awk = build_rank_awk({
    { pattern = 'class' },
    { pattern = '@entity' },
  }, nil)
  local input = table.concat({
    'a.java:1:1:@Entity class Foo',
    'b.java:2:1:@Entity',
    'c.java:3:1:other line',
  }, '\n') .. '\n'
  local result = run_awk(input, awk)
  T.eq(#result, 3, 'all 3 lines present')
  T.match(result[1] or '', '@Entity class Foo', 'multi-match: first pattern wins')
  T.match(result[2] or '', '@Entity', 'single match: correct bucket')
  T.match(result[3] or '', 'other', 'no match: fallback')
end)
