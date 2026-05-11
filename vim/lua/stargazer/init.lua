-- stargazer/init.lua — thin wrapper: delegates to bin/stargazer (Ruby CLI)

local M = {}

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
    '\027[90mpipe: query | filter  ─  folder: query @path/  ─  glob: *.ext\027[0m',
    '\027[90mctrl-g\027[0m  cycle group filter  \027[90m-t\027[0m define/page/config/schema/domain/method',
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
      -- 헤더/separator/status 라인 제외 (file:line 패턴이 아닌 줄)
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

--- stargazer CLI 명령 빌드
---@param query string
---@param filter_bucket? number
---@return string
local function stargazer_cmd(query, filter_bucket)
  local parts = { 'stargazer', vim.fn.shellescape(query), '--color' }

  -- context: 현재 버퍼 경로 전달
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname ~= '' then
    table.insert(parts, '--context')
    table.insert(parts, vim.fn.shellescape(bufname))
  end

  -- 그룹 필터
  if filter_bucket then
    table.insert(parts, '-t')
    -- group_names를 Ruby CLI에서 가져오는 대신, 정적 목록 사용
    local group_names = { 'generated', 'page', 'define', 'config', 'schema', 'domain', 'method', 'reference' }
    local name = group_names[filter_bucket]
    if name then
      table.insert(parts, name)
    end
  end

  return table.concat(parts, ' ')
end

--- 메인 진입점
---@param opts? {query?: string}
function M.open(opts)
  opts = opts or {}
  local fzf_lua = require('fzf-lua')

  -- g:stargazer_fzf_tmux — tmux popup 모드
  local tmux_val = vim.g.stargazer_fzf_tmux

  -- 그룹 필터 상태
  local filter_bucket = nil
  local group_names = { 'generated', 'page', 'define', 'config', 'schema', 'domain', 'method', 'reference' }

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
    local query = type(args) == 'table' and args[1] or args
    if not query or query == '' then return help_cmd() end
    return stargazer_cmd(tostring(query), filter_bucket)
  end, {
    prompt = 'Stargazer> ',
    query = opts.query or '',
    exec_empty_query = true,
    multiline = 2,
    actions = (function()
      local actions = shared_actions()
      -- ctrl-g: 그룹 순환
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
    fn_transform = function(line)
      -- 그룹 헤더/separator/status 라인 → 통과
      if line:match('^\027%[') and (line:match('──') or line:match('%(') or line:match('%. %. %. %+')) then
        return line .. '\n '
      end
      -- file:line 컬러링은 Ruby CLI가 처리 (--color)
      -- multiline 2줄 표시: dir dim + 파일명 강조
      local dir, file, loc, text = line:match('^(\027%[[^m]*m[^:]+/)([^/]+)(:%d[%d:]*:)(.*)')
      if not dir then
        dir, file, loc, text = line:match('^(.*/)([^/]+)(:%d[%d:]*:)(.*)')
      end
      if dir then
        if is_test_path(dir, file) then
          return '\027[90m' .. dir .. '\n  ' .. file .. loc .. text .. '\027[0m'
        end
        return '\027[90m' .. dir .. '\027[0m\n  '
          .. file .. '\027[33m' .. loc .. '\027[0m' .. text
      end
      -- 루트 파일
      local file2, loc2, text2 = line:match('^([^/]+)(:%d[%d:]*:)(.*)')
      if file2 then
        return '\027[90m./\027[0m\n  '
          .. file2 .. '\027[33m' .. loc2 .. '\027[0m' .. text2
      end
      return line
    end,
  })
end

return M
