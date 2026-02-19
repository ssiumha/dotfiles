--- stargazer/spec/runner.lua -- nvim -l test runner
--- Usage: nvim --headless --noplugin -u NONE -l vim/lua/stargazer/spec/runner.lua

local source = debug.getinfo(1, 'S').source:sub(2)
local spec_dir = vim.fn.fnamemodify(source, ':p:h')
local lua_dir = vim.fn.fnamemodify(spec_dir, ':h:h')

-- require('stargazer.*') path setup
package.path = lua_dir .. '/?.lua;' .. lua_dir .. '/?/init.lua;' .. package.path

--------------------------------------------------------------------------------
-- Minimal test framework
--------------------------------------------------------------------------------

local _pass, _fail = 0, 0

local T = {}

function T.describe(name, fn)
  local bp, bf = _pass, _fail
  fn()
  local sp = _pass - bp
  local sf = _fail - bf
  local total = sp + sf
  if sf == 0 then
    io.write(string.format('\027[32m[PASS]\027[0m %s (%d/%d)\n', name, sp, total))
  else
    io.write(string.format('\027[31m[FAIL]\027[0m %s (%d/%d passed)\n', name, sp, total))
  end
end

local function fail_msg(info, msg, detail)
  io.write(string.format(
    '\027[31m  FAIL\027[0m %s:%d %s\n%s\n',
    info.short_src, info.currentline, msg or '', detail
  ))
end

function T.eq(actual, expected, msg)
  if actual == expected then _pass = _pass + 1; return end
  _fail = _fail + 1
  fail_msg(debug.getinfo(2, 'Sl'), msg or '', string.format(
    '    expected: %s\n    actual:   %s', tostring(expected), tostring(actual)
  ))
end

function T.match(str, pattern, msg)
  if type(str) == 'string' and str:find(pattern) then _pass = _pass + 1; return end
  _fail = _fail + 1
  fail_msg(debug.getinfo(2, 'Sl'), msg or '', string.format(
    '    pattern: %s\n    string:  %s', pattern, tostring(str)
  ))
end

function T.no_match(str, pattern, msg)
  if type(str) ~= 'string' or not str:find(pattern) then _pass = _pass + 1; return end
  _fail = _fail + 1
  fail_msg(debug.getinfo(2, 'Sl'), msg or '', string.format(
    '    should NOT match: %s\n    string: %s', pattern, tostring(str)
  ))
end

function T.ok(cond, msg)
  if cond then _pass = _pass + 1; return end
  _fail = _fail + 1
  fail_msg(debug.getinfo(2, 'Sl'), msg or 'assertion failed', '')
end

-- Globals for spec files
_G.T = T
_G.SPEC_DIR = spec_dir

--------------------------------------------------------------------------------
-- Load and run specs
--------------------------------------------------------------------------------

-- NOTE: 각 spec 파일이 자체적으로 require('stargazer.modes') 호출.
-- Lua require 캐싱으로 중복 등록 없음.

local specs = {
  spec_dir .. '/parse_query_spec.lua',
  spec_dir .. '/rank_awk_spec.lua',
  spec_dir .. '/dispatch_spec.lua',
}

for _, path in ipairs(specs) do
  local ok, err = pcall(dofile, path)
  if not ok then
    io.write(string.format('\027[31mERROR\027[0m %s:\n  %s\n', vim.fn.fnamemodify(path, ':t'), err))
    _fail = _fail + 1
  end
end

--------------------------------------------------------------------------------
-- Summary
--------------------------------------------------------------------------------

local total = _pass + _fail
io.write('\n')
if _fail == 0 then
  io.write(string.format('\027[32mAll %d tests passed.\027[0m\n', total))
  os.exit(0)
else
  io.write(string.format('\027[31m%d/%d tests failed.\027[0m\n', _fail, total))
  os.exit(1)
end
