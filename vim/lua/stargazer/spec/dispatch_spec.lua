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
