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
    '',
    '\027[36m$\027[90mpattern\027[0m    AST pattern (ast-grep)',
    '',
    '\027[33mword\027[0m           infer: find all related code (grouped)',
    '',
    '\027[90mpipe: query | filter  ─  folder: query @path/  ─  glob: *.ext  ─  exclude: @!path/ or | !filter\027[0m',
    '\027[33mctrl-g\027[0m  cycle group filter (define/config/schema/domain/method/reference)',
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
      local r = restore_entry(item)
      -- 헤더/separator 라인 제외 (file:line 패턴이 아닌 줄)
      if r:match('^[^:]+:%d+:') then
        table.insert(restored, r)
      end
    end
    if #restored > 0 then
      return action_fn(restored, opts)
    end
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

  -- g:stargazer_fzf_tmux — tmux popup 모드 (예: 'center,80%,70%')
  local tmux_val = vim.g.stargazer_fzf_tmux

  -- 그룹 필터 상태 (nil=전체, 1-6=특정 버킷)
  local filter_bucket = nil
  local group_names = engine.get_group_names('infer') or {}


  -- awk: 테스트 파일 라인을 버퍼에 저장, 일반 라인 먼저 출력, 끝에 버퍼 출력
  local TEST_REORDER = [[ | awk '/\/tests?\/|Test[^a-z]|_test\.|\.test\.|\.spec\./{buf[++n]=$0;next}{print}END{for(i=1;i<=n;i++)print buf[i]}']]

  local fzf_opts = {
    ['--multi'] = true,
    ['--ansi'] = true,
    ['--highlight-line'] = true,
    ['--bind'] = 'alt-a:select-all,alt-d:deselect-all',
  }
  if tmux_val then
    fzf_opts['--tmux'] = tmux_val
  end

  fzf_lua.fzf_live(function(args)
    -- fzf-lua는 query를 table로 전달: args = { "query_string" }
    local query = type(args) == 'table' and args[1] or args
    if not query or query == '' then return help_cmd() end
    query = tostring(query)

    local parsed = M.parse_query(query)
    local cmd = M.dispatch(parsed, ctx, { filter_bucket = filter_bucket })
    if not cmd then return cmd end
    -- grouped 모드(infer)는 자체 정렬 + awk가 상태줄 출력, 그 외는 테스트 파일 후순위
    if parsed and parsed.mode == 'infer' then
      return cmd
    end
    return cmd .. TEST_REORDER
  end, {
    prompt = 'Stargazer> ',
    query = opts.query or '',
    exec_empty_query = true,
    multiline = 2,
    actions = (function()
      local actions = shared_actions()
      -- F-key 그룹 필터 토글: 모드의 rank 배열에서 동적 생성
      if #group_names > 0 then
        -- ctrl-g: 그룹 순환 (define → config → ... → reference → all → ...)
        actions['ctrl-g'] = {
          fn = function()
            if filter_bucket and filter_bucket < #group_names then
              filter_bucket = filter_bucket + 1
            else
              filter_bucket = filter_bucket and nil or 1
            end
          end,
          reload = true,
        }
      end
      return actions
    end)(),
    previewer = 'builtin',
    _fmt = { from = restore_entry },
    winopts = {
      preview = {
        layout = 'vertical',
        vertical = 'down:60%',
      },
    },
    fzf_opts = fzf_opts,
    -- 디렉토리 dim 처리: 경로는 유지하되 시각적으로 파일명 강조
    fn_transform = function(line)
      -- 그룹 헤더/separator 라인 → 변환 없이 통과 (multiline=2 대응: 빈 줄 추가)
      if line:match('^\027%[') and line:match('──') then
        return line .. '\n '
      end
      -- "... +N more" 라인도 통과
      if line:match('^\027%[90m') and line:match('%. %. %. %+') then
        return line .. '\n '
      end
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
