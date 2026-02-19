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
