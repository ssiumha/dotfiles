local engine = require('stargazer.engine')
require('stargazer.modes')
local parse = engine.parse_query
local dispatch = engine.dispatch

-- Mock contexts (no preset entries -> generic fallback commands)
local mock_ctx = {
  root = '/tmp/test',
  preset_name = 'test',
  preset = {},
  has_sg = false,
}

local mock_ctx_sg = {
  root = '/tmp/test',
  preset_name = 'test',
  preset = {},
  has_sg = true,
}

T.describe('dispatch: infer -> rank awk', function()
  local parsed = parse('Wallet')
  local cmd = dispatch(parsed, mock_ctx)
  T.ok(cmd ~= nil, 'cmd generated')
  T.match(cmd, '| awk', 'rank awk pipe appended')
  T.match(cmd, 'class|interface', 'rank pattern includes definitions')
end)

T.describe('dispatch: model -> no rank awk', function()
  local parsed = parse('m:User')
  local cmd = dispatch(parsed, mock_ctx)
  T.ok(cmd ~= nil, 'cmd generated')
  T.no_match(cmd, '| awk', 'no rank pipe for model mode')
end)

T.describe('dispatch: pipe_filter ordering', function()
  local parsed = parse('Wallet | client')
  local cmd = dispatch(parsed, mock_ctx)
  T.ok(cmd ~= nil, 'cmd generated')
  -- rank awk must precede pipe_filter grep
  T.match(cmd, 'awk.-grep.-client', 'rank awk before pipe_filter grep')
end)

T.describe('dispatch: nil for unmatched', function()
  local cmd = dispatch(nil, mock_ctx)
  T.eq(cmd, nil, 'nil parsed -> nil cmd')
end)

--------------------------------------------------------------------------------
-- symbol mode
--------------------------------------------------------------------------------

T.describe('dispatch: symbol AST -> sg cmd', function()
  local parsed = parse('$foo()')
  T.eq(parsed.mode, 'symbol', 'ast query -> symbol mode')
  T.ok(parsed.ast, 'ast flag set')
  local cmd = dispatch(parsed, mock_ctx_sg)
  T.match(cmd, 'sg run', 'uses ast-grep')
end)

T.describe('dispatch: symbol AST -> error when no sg', function()
  local parsed = parse('$foo()')
  local cmd = dispatch(parsed, mock_ctx)
  T.match(cmd, 'not found', 'error msg when sg missing')
end)

T.describe('dispatch: symbol rg fallback', function()
  local parsed = parse('s:create')
  local cmd = dispatch(parsed, mock_ctx)
  T.match(cmd, 'rg', 'uses ripgrep')
  T.match(cmd, 'create', 'query in command')
end)

--------------------------------------------------------------------------------
-- folder filter (@path/)
--------------------------------------------------------------------------------

T.describe('dispatch: folder filter with symbol mode', function()
  local parsed = parse('s:create @src/auth/')
  local cmd = dispatch(parsed, mock_ctx)
  T.ok(cmd ~= nil, 'cmd generated')
  T.match(cmd, 'rg', 'base: uses ripgrep')
  T.match(cmd, 'create', 'base: query present')
  T.match(cmd, "grep.*src/auth/", 'folder filter piped')
end)

T.describe('dispatch: folder filter ordering (rank → folder → pipe)', function()
  local parsed = parse('Wallet @src/ | client')
  local cmd = dispatch(parsed, mock_ctx)
  T.ok(cmd ~= nil, 'cmd generated')
  T.match(cmd, 'awk.-grep.-src/.-grep.-client', 'order: rank awk → folder grep → pipe grep')
end)

T.describe('dispatch: folder filter with git mode', function()
  local parsed = parse('! handler @vim/')
  local cmd = dispatch(parsed, mock_ctx)
  T.ok(cmd ~= nil, 'cmd generated')
  T.match(cmd, 'git diff', 'git: base command')
  T.match(cmd, "grep.*vim/", 'git: folder filter applied')
end)

T.describe('dispatch: folder filter with model mode', function()
  local parsed = parse('m:User @src/domain/')
  local cmd = dispatch(parsed, mock_ctx)
  T.ok(cmd ~= nil, 'cmd generated')
  T.match(cmd, 'User', 'model: query present')
  T.match(cmd, "grep.*src/domain/", 'model: folder filter piped')
end)

T.describe('dispatch: folder filter with router mode', function()
  local parsed = parse('r:users @src/routes/')
  local cmd = dispatch(parsed, mock_ctx)
  T.ok(cmd ~= nil, 'cmd generated')
  T.match(cmd, 'users', 'router: query present')
  T.match(cmd, "grep.*src/routes/", 'router: folder filter piped')
end)

--------------------------------------------------------------------------------
-- context mode
--------------------------------------------------------------------------------

T.describe('dispatch: context without domain', function()
  vim.api.nvim_buf_set_name(0, '')
  local parsed = parse('&')
  local cmd = dispatch(parsed, mock_ctx)
  T.match(cmd, 'echo', 'error when no domain extractable')
end)

T.describe('dispatch: context with query', function()
  vim.api.nvim_buf_set_name(0, '/project/src/auth/controller.lua')
  local parsed = parse('& handler')
  local cmd = dispatch(parsed, mock_ctx)
  T.match(cmd, 'auth', 'domain extracted from buffer path')
  T.match(cmd, 'handler', 'query passed to rg')
  vim.api.nvim_buf_set_name(0, '')
end)

T.describe('dispatch: context fallback pattern (& alone)', function()
  vim.api.nvim_buf_set_name(0, '/project/src/auth/controller.lua')
  local parsed = parse('&')
  local cmd = dispatch(parsed, mock_ctx)
  T.match(cmd, 'auth', 'domain extracted')
  T.match(cmd, 'class|interface', 'structural fallback pattern')
  vim.api.nvim_buf_set_name(0, '')
end)

--------------------------------------------------------------------------------
-- router mode
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- git mode
--------------------------------------------------------------------------------

T.describe('dispatch: git ! -> status listing', function()
  local parsed = parse('!')
  local cmd = dispatch(parsed, mock_ctx)
  T.ok(cmd ~= nil, 'cmd generated')
  T.match(cmd, 'git status', 'uses git status')
  T.match(cmd, 'porcelain', 'porcelain format')
end)

-- NOTE: 내부 커맨드 구조(xargs, --cached 등)보다 의미 단위로 검증
T.describe('dispatch: git ! query -> rg in changed files', function()
  local parsed = parse('! handler')
  local cmd = dispatch(parsed, mock_ctx)
  T.ok(cmd ~= nil, 'cmd generated')
  T.match(cmd, 'git diff', 'sources files from git diff')
  T.match(cmd, 'rg', 'searches with ripgrep')
  T.match(cmd, 'handler', 'query in command')
end)

T.describe('dispatch: git keyword -> same as ! prefix', function()
  local keywords = { 'diff', 'staged', 'changed' }
  for _, kw in ipairs(keywords) do
    local parsed = parse(kw .. ' handler')
    local cmd = dispatch(parsed, mock_ctx)
    T.ok(cmd ~= nil, kw .. ': cmd generated')
    T.match(cmd, 'git diff', kw .. ': triggers git mode')
    T.match(cmd, 'handler', kw .. ': query passed through')
  end
end)

T.describe('dispatch: git pipe filter', function()
  local parsed = parse('! handler | auth')
  local cmd = dispatch(parsed, mock_ctx)
  T.ok(cmd ~= nil, 'cmd generated')
  T.match(cmd, 'grep.-auth', 'pipe filter applied')
end)

--------------------------------------------------------------------------------
-- exclude filters (@!path/, | !filter)
--------------------------------------------------------------------------------

T.describe('dispatch: folder exclude @!path/', function()
  local parsed = parse('Wallet @!test/')
  local cmd = dispatch(parsed, mock_ctx)
  T.ok(cmd ~= nil, 'cmd generated')
  T.match(cmd, 'grep %-v.*test/', 'folder exclude: grep -v present')
end)

T.describe('dispatch: pipe exclude | !filter', function()
  local parsed = parse('s:create | !Test')
  local cmd = dispatch(parsed, mock_ctx)
  T.ok(cmd ~= nil, 'cmd generated')
  T.match(cmd, 'grep %-v %-i.*Test', 'pipe exclude: grep -v -i present')
end)

T.describe('dispatch: include filters unchanged (regression)', function()
  local p1 = parse('s:create @src/auth/')
  local cmd1 = dispatch(p1, mock_ctx)
  T.no_match(cmd1, 'grep %-v', 'folder include: no -v flag')

  local p2 = parse('Wallet | client')
  local cmd2 = dispatch(p2, mock_ctx)
  T.no_match(cmd2, 'grep %-v', 'pipe include: no -v flag')
end)

T.describe('dispatch: combo exclude @!path/ | !filter', function()
  local parsed = parse('Wallet @!test/ | !Mock')
  local cmd = dispatch(parsed, mock_ctx)
  T.ok(cmd ~= nil, 'cmd generated')
  T.match(cmd, 'grep %-v.*test/', 'combo: folder exclude')
  T.match(cmd, 'grep %-v %-i.*Mock', 'combo: pipe exclude')
end)

T.describe('dispatch: router GET /path generic', function()
  local parsed = parse('GET /api/users')
  local cmd = dispatch(parsed, mock_ctx)
  T.match(cmd, 'rg', 'uses ripgrep')
  T.match(cmd, 'get', 'method in filter')
  T.match(cmd, '/api/users', 'path in filter')
end)

T.describe('dispatch: router r: prefix generic', function()
  local parsed = parse('r:users')
  local cmd = dispatch(parsed, mock_ctx)
  T.match(cmd, 'rg', 'uses ripgrep')
  T.match(cmd, 'users', 'query in filter')
end)
