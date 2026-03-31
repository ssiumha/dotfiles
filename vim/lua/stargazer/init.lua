-- stargazer/init.lua — 진입점: open, setup, fzf-lua UI
-- OCP: 모든 모드/프리셋/키워드는 데이터 레지스트리. 새 모드 = register_mode() 한 번.

local engine = require('stargazer.engine')
require('stargazer.presets')
require('stargazer.modes')

local M = engine

-------------------------------------------------------------------------------
-- fzf-lua Integration
-------------------------------------------------------------------------------

--- 테스트 파일 경로인지 판별
local function is_test_path(dir, file)
  if dir:match('/tests?/') or dir:match('/__tests__/') or dir:match('/specs?/') then
    return true
  end
  if not file then return false end
  return file:match('Test[^a-z]') ~= nil
    or file:match('_test%.') ~= nil
    or file:match('%.test%.') ~= nil
    or file:match('%.spec%.') ~= nil
end

--- 빈 쿼리 시 도움말 출력 명령
---@return string
local function help_cmd()
  -- \027[1m = bold, \027[36m = cyan, \027[33m = yellow, \027[90m = dim
  local lines = {
    '\027[1m── Stargazer ──\027[0m',
    '',
    '\027[36m!\027[0m              git: changed & staged files',
    '\027[36m! \027[90mquery\027[0m      git: search within changes',
    '',
    '\027[36m&\027[0m              context: definitions in current domain',
    '\027[36m& \027[90mquery\027[0m      context: search within current domain',
    '',
    '\027[36mGET \027[90m/path\027[0m    router: HTTP method + path',
    '\027[36m/\027[90mpath\027[0m        router: path lookup',
    '\027[36mr:\027[90mquery\027[0m      router: route search',
    '',
    '\027[36mm:\027[90mquery\027[0m      model / schema / entity',
    '\027[36md:\027[90mquery\027[0m      domain: service / repository',
    '\027[36ms:\027[90mquery\027[0m      symbol: function / class / type',
    '\027[36m$\027[90mpattern\027[0m    symbol: AST pattern (ast-grep)',
    '',
    '\027[33mPascalCase\027[0m     infer: find all related code',
    '',
    '\027[90mpipe: query | filter  ─  folder: query @path/  ─  exclude: @!path/ or | !filter\027[0m',
  }
  return 'printf ' .. vim.fn.shellescape(table.concat(lines, '\n'))
end

--- multiline 선택 결과를 원본 file:line:col 포맷으로 복원
local function restore_entry(item)
  local first, second = item:match('^(.-)\n%s*(.+)$')
  if first and second then
    local dir = require('fzf-lua.utils').strip_ansi_coloring(first)
    return dir .. second
  end
  return item
end

local function wrap_action(action_fn)
  return function(selected, opts)
    local restored = {}
    for _, item in ipairs(selected) do
      table.insert(restored, restore_entry(item))
    end
    return action_fn(restored, opts)
  end
end

--- fzf-lua 공통 액션
---@return table
local function shared_actions()
  local fzf_actions = require('fzf-lua.actions')
  return {
    ['default'] = wrap_action(fzf_actions.file_edit_or_qf),
    ['ctrl-q'] = wrap_action(fzf_actions.file_sel_to_qf),
    ['ctrl-t'] = wrap_action(fzf_actions.file_tabedit),
    ['ctrl-v'] = wrap_action(fzf_actions.file_vsplit),
    ['ctrl-x'] = wrap_action(fzf_actions.file_split),
  }
end

--- 메인 진입점
---@param opts? {initial_mode?: string, query?: string}
function M.open(opts)
  opts = opts or {}
  local fzf_lua = require('fzf-lua')
  local ctx = M.build_context()

  -- awk: 테스트 파일 라인을 버퍼에 저장, 일반 라인 먼저 출력, 끝에 버퍼 출력
  local TEST_REORDER = [[ | awk '/\/tests?\/|Test[^a-z]|_test\.|\.test\.|\.spec\./{buf[++n]=$0;next}{print}END{for(i=1;i<=n;i++)print buf[i]}']]

  fzf_lua.fzf_live(function(args)
    -- fzf-lua는 query를 table로 전달: args = { "query_string" }
    local query = type(args) == 'table' and args[1] or args
    if not query or query == '' then return help_cmd() end
    query = tostring(query)

    local parsed = M.parse_query(query)
    local cmd = M.dispatch(parsed, ctx)
    if not cmd then return cmd end
    return cmd .. TEST_REORDER
  end, {
    prompt = 'Stargazer> ',
    query = opts.query or '',
    exec_empty_query = true,
    multiline = 2,
    actions = shared_actions(),
    previewer = 'builtin',
    _fmt = { from = restore_entry },
    winopts = {
      preview = {
        layout = 'vertical',
        vertical = 'down:60%',
      },
    },
    fzf_opts = {
      ['--multi'] = true,
      ['--ansi'] = true,
      ['--highlight-line'] = true,
      ['--bind'] = 'alt-a:select-all,alt-d:deselect-all',
    },
    -- 디렉토리 dim 처리: 경로는 유지하되 시각적으로 파일명 강조
    fn_transform = function(line)
      -- 1-step 4-group 매치: 내용에 / 포함되어도 backtrack으로 올바른 분리
      local dir, file, loc, text = line:match('^(.*/)([^/]+)(:%d[%d:]*:)(.*)')
      if dir then
        if is_test_path(dir, file) then
          return '\027[90m' .. dir .. '\n  ' .. file .. loc .. text .. '\027[0m'
        end
        return '\027[90m' .. dir .. '\027[0m\n  '
          .. file .. '\027[33m' .. loc .. '\027[0m' .. text
      end
      -- dir 없지만 file:line: 패턴 (루트 파일) → 2줄 통일
      local file2, loc2, text2 = line:match('^([^/]+)(:%d[%d:]*:)(.*)')
      if file2 then
        return '\027[90m./\027[0m\n  '
          .. file2 .. '\027[33m' .. loc2 .. '\027[0m' .. text2
      end
      return line
    end,
  })
end

-------------------------------------------------------------------------------
-- Setup
-------------------------------------------------------------------------------

---@class StargazerSetupOpts
---@field presets? table<string, StargazerPreset>  추가 프리셋
---@field modes? StargazerMode[]                   추가 모드

--- 초기 설정
---@param opts? StargazerSetupOpts
function M.setup(opts)
  opts = opts or {}

  if opts.presets then
    for name, preset in pairs(opts.presets) do
      M.register_preset(name, preset)
    end
  end

  if opts.modes then
    for _, mode in ipairs(opts.modes) do
      M.register_mode(mode)
    end
  end
end

return M
