-- stargazer/engine.lua — core engine: registry, parser, builder, dispatch, context
-- SECURITY: .stargazer.lua는 임의 Lua를 실행한다. 신뢰하는 저장소에서만 사용.
-- ARCHITECTURE: priority 기반 디스패치 (10/20/30... 간격으로 삽입 여유 확보)

local M = {}

-------------------------------------------------------------------------------
-- Mode Registry
-------------------------------------------------------------------------------

---@class StargazerMode
---@field name string
---@field priority number            -- 낮을수록 먼저 매치 (10, 20, 30 ...)
---@field prefix? string             -- 단축 prefix (r, m, d, s ...)
---@field keywords? string[]         -- 키워드 목록 (model, schema, ...)
---@field match fun(raw: string): table|nil  -- 매치 시 parsed 반환, 실패 시 nil
---@field rank? {pattern: string}[]  -- 결과 스코어링 패턴 (우선순위 순, {q}=쿼리 보간)
---@field build_cmd fun(parsed: table, ctx: table): string  -- shell 명령 생성

---@type StargazerMode[]
local modes = {}

--- priority 순으로 정렬된 상태 유지
local function sort_modes()
  table.sort(modes, function(a, b) return a.priority < b.priority end)
end

--- 새 모드 등록. 기존 코드 수정 없이 확장.
---@param mode StargazerMode
function M.register_mode(mode)
  assert(mode.name, 'mode requires name')
  assert(mode.priority, 'mode requires priority')
  assert(mode.match, 'mode requires match function')
  assert(mode.build_cmd, 'mode requires build_cmd function')

  for i, existing in ipairs(modes) do
    if existing.name == mode.name then
      vim.notify('[Stargazer] Overriding mode: ' .. mode.name, vim.log.levels.DEBUG)
      modes[i] = mode
      sort_modes()
      return
    end
  end

  modes[#modes + 1] = mode
  sort_modes()
end

-------------------------------------------------------------------------------
-- Preset Registry
-------------------------------------------------------------------------------

---@class StargazerPresetEntry
---@field glob string|string[]
---@field pattern string

---@class StargazerPreset
---@field detect? string|fun(): boolean  -- 파일명 또는 함수 (custom 프리셋은 생략 가능)
---@field detect_content? {file: string, pattern: string}  -- 파일 내 패턴 검사
---@field router? StargazerPresetEntry[]
---@field model? StargazerPresetEntry[]
---@field domain? StargazerPresetEntry[]

---@type table<string, StargazerPreset>
local presets = {}

local _merged_preset_cache = nil

--- 프레임워크 프리셋 등록
---@param name string
---@param preset StargazerPreset
function M.register_preset(name, preset)
  presets[name] = preset
  _merged_preset_cache = nil
end

-------------------------------------------------------------------------------
-- Merged Preset (모든 프리셋 합산 — preset 미감지 시 fallback)
-------------------------------------------------------------------------------

--- 등록된 모든 프리셋의 패턴을 병합하여 범용 프리셋 생성
---@return StargazerPreset
local function build_merged_preset()
  if _merged_preset_cache then return _merged_preset_cache end
  local merged = { router = {}, model = {}, domain = {} }
  for _, preset in pairs(presets) do
    for _, key in ipairs({ 'router', 'model', 'domain' }) do
      if preset[key] then
        for _, entry in ipairs(preset[key]) do
          merged[key][#merged[key] + 1] = entry
        end
      end
    end
  end
  _merged_preset_cache = merged
  return merged
end

-------------------------------------------------------------------------------
-- Framework Detection
-------------------------------------------------------------------------------

--- 프로젝트 루트에서 프레임워크 자동 감지
---@param root? string  프로젝트 루트 경로
---@return string|nil preset_name
---@return StargazerPreset|nil preset
local function detect_framework(root)
  root = root or vim.fn.getcwd()

  --- 루트 + 1단계 하위 디렉토리에서 파일 탐색 (모노레포 지원)
  ---@param pattern string
  ---@return string[]
  local function find_deep(pattern)
    local matches = vim.fn.glob(root .. '/' .. pattern, false, true)
    if #matches == 0 then
      matches = vim.fn.glob(root .. '/*/' .. pattern, false, true)
    end
    return matches
  end

  --- detect_content를 위한 파일 찾기
  ---@param filename string
  ---@return string|nil
  local function find_file(filename)
    if vim.fn.filereadable(root .. '/' .. filename) == 1 then
      return root .. '/' .. filename
    end
    local deep = vim.fn.glob(root .. '/*/' .. filename, false, true)
    return deep[1]
  end

  for name, preset in pairs(presets) do
    local detect = preset.detect
    if not detect then goto continue end

    local detected = false

    if type(detect) == 'function' then
      detected = detect()
    elseif type(detect) == 'string' then
      detected = #find_deep(detect) > 0
    end

    -- detect_content: 파일 내 패턴 추가 검사
    if detected and preset.detect_content then
      detected = false
      local dc = preset.detect_content
      local filepath = find_file(dc.file)
      if filepath then
        local ok, lines = pcall(vim.fn.readfile, filepath)
        if ok then
          detected = table.concat(lines, '\n'):find(dc.pattern) ~= nil
        end
      end
    end

    if detected then return name, preset end

    ::continue::
  end

  return nil, nil
end

-------------------------------------------------------------------------------
-- Query Parser (데이터 기반 디스패치)
-------------------------------------------------------------------------------

--- 모드 레지스트리를 priority 순으로 순회하며 첫 매치 반환
---@param raw string
---@return table {mode: string, query: string, ...}
local function parse_query(raw)
  if not raw or type(raw) ~= 'string' or raw == '' then
    return { mode = 'grep', query = '' }
  end

  -- 파이프: "POST /health | wallet" → 모드 검색 + grep 체인
  local base, pipe_filter = raw:match('^(.-)%s*|%s*(.*)$')
  if base and base ~= '' then
    raw = base
    if pipe_filter == '' then pipe_filter = nil end
  end

  local parsed
  for _, mode in ipairs(modes) do
    parsed = mode.match(raw)
    if parsed then
      parsed.mode = mode.name
      break
    end
  end

  if not parsed then return nil end
  parsed.pipe_filter = pipe_filter
  return parsed
end

-------------------------------------------------------------------------------
-- Command Builders (공용)
-------------------------------------------------------------------------------

--- 공통 제외 패턴 (빌드 산출물, 설정, 문서)
local RG_EXCLUDE = table.concat({
  '--glob !target/',
  '--glob !build/',
  '--glob !dist/',
  '--glob !node_modules/',
  '--glob !.git/',
  '--glob !**/logs/',
  '--glob !*.xml',
  '--glob !*.md',
  '--glob !*.json',
  '--glob !*.jsonl',
  '--glob !*.yaml',
  '--glob !*.yml',
  '--glob !*.lock',
  '--glob !*.log',
  '--glob !*.min.*',
}, ' ')

--- rg base flags (preset entries용 — column/smart-case 불필요)
local RG_BASE = 'rg --line-number --no-heading --color=never ' .. RG_EXCLUDE

--- rg search flags (직접 검색용 — column + smart-case 포함)
local RG_SEARCH = 'rg --line-number --column --no-heading --color=never --smart-case ' .. RG_EXCLUDE

--- rg 명령 빌드 (entries: {glob, pattern}[] + filter)
---@param entries StargazerPresetEntry[]
---@param filter? string
---@return string
local function build_rg_cmd(entries, filter)
  local parts = {}
  for _, entry in ipairs(entries) do
    local globs = type(entry.glob) == 'table' and entry.glob or { entry.glob }
    local glob_flags = {}
    for _, g in ipairs(globs) do
      glob_flags[#glob_flags + 1] = string.format('--glob %s', vim.fn.shellescape(g))
    end
    parts[#parts + 1] = string.format(
      '%s %s %s',
      RG_BASE,
      table.concat(glob_flags, ' '),
      vim.fn.shellescape(entry.pattern)
    )
  end

  -- ; 으로 연결: 하나 실패해도 나머지 계속 실행
  local cmd = table.concat(parts, '; ')

  if filter and filter ~= '' then
    -- content-only 필터: filepath:linenum: 이후만 매칭 (경로 오탐 방지)
    cmd = string.format(
      "{ %s; } | awk -v q=%s 'match($0,/:[0-9]+:/){if(index(tolower(substr($0,RSTART+RLENGTH)),q)>0)print}'",
      cmd, vim.fn.shellescape(filter:lower())
    )
  end

  return cmd
end

--- ast-grep 명령 빌드 (jq 대신 Lua 파싱으로 전환 — awk로 JSON 파싱)
---@param pattern string
---@param lang? string
---@return string
local function build_sg_cmd(pattern, lang)
  local cmd = string.format('sg run --pattern=%s --json=stream', vim.fn.shellescape(pattern, 1))
  if lang then
    cmd = cmd .. string.format(' --lang %s', vim.fn.shellescape(lang))
  end
  -- awk로 JSON 파싱 (jq 의존성 제거)
  cmd = cmd .. [[ 2>/dev/null | awk -F'"' ']]
    .. [[/"file":/{f=$4} /"line":/{gsub(/[^0-9]/,"",$0);l=$0} ]]
    .. [[/"column":/{gsub(/[^0-9]/,"",$0);c=$0} ]]
    .. [[/"text":/{t=$4; if(f!="" && l!="") print f":"l":"c":"t}']]
  return cmd
end

-------------------------------------------------------------------------------
-- Keyword Matcher Factory (OCP: 키워드 목록만 넘기면 매처 생성)
-- NOTE: 패턴은 클로저에 캐싱됨. 정적 등록 용도.
-------------------------------------------------------------------------------

--- 키워드 목록 기반 매처 생성 (정적 등록 시 한 번 생성, 이후 재사용)
---@param keywords string[]
---@return fun(raw: string): string|nil  매치 시 키워드 뒤 쿼리 반환
local function keyword_matcher(keywords)
  local patterns = {}
  for _, kw in ipairs(keywords) do
    patterns[#patterns + 1] = '^' .. kw .. '%s+(.+)'
  end
  return function(raw)
    local lower = raw:lower()
    for _, pat in ipairs(patterns) do
      local query = lower:match(pat)
      if query then return query end
    end
    return nil
  end
end

--- prefix + keyword 매칭 함수 생성 (model/domain/symbol 공통 패턴)
---@param prefix_char string  단축 prefix 문자 (m, d, s ...)
---@param kw_fn fun(raw: string): string|nil  keyword_matcher 클로저
---@return fun(raw: string): table|nil
local function prefix_keyword_match(prefix_char, kw_fn)
  local pat = '^' .. prefix_char .. ':(.+)'
  return function(raw)
    local rest = raw:match(pat)
    if rest then return { query = rest } end
    local q = kw_fn(raw)
    if q then return { query = q } end
    return nil
  end
end

-------------------------------------------------------------------------------
-- extract_domain
-------------------------------------------------------------------------------

--- 현재 버퍼 경로에서 모듈 디렉토리 추출
---@return string|nil domain
local function extract_domain()
  local path = vim.api.nvim_buf_get_name(0)
  if not path or path == '' then return nil end
  -- src/X/ 또는 modules/X/ 패턴
  local domain = path:match('/src/([^/]+)/')
    or path:match('/modules/([^/]+)/')
    or path:match('/app/[^/]+/([^_]+)')  -- Rails: app/controllers/admin_controller
  return domain
end

-------------------------------------------------------------------------------
-- Rank AWK Builder (콘텐츠 패턴 기반 스코어링 파이프라인)
-------------------------------------------------------------------------------

--- rank 패턴 → dedup + 버킷 스코어링 awk 파이프 생성
---@param patterns {pattern: string}[]  우선순위 순 (첫 번째가 최고)
---@param query? string                 검색어 ({q} 보간용)
---@return string  " | awk -F: '...'"
local function build_rank_awk(patterns, query)
  local q = query and query:lower() or ''

  local branches = {}
  for i, p in ipairs(patterns) do
    local pat = p.pattern:gsub('{q}', q)
    branches[#branches + 1] = string.format(
      '%sif(c~/%s/)a%d[++n%d]=$0',
      i == 1 and '' or 'else ',
      pat, i, i
    )
  end
  -- fallback 버킷
  local last = #patterns + 1
  branches[#branches + 1] = string.format('else a%d[++n%d]=$0', last, last)

  local end_parts = {}
  for i = 1, last do
    end_parts[#end_parts + 1] = string.format('for(i=1;i<=n%d;i++)print a%d[i]', i, i)
  end

  return string.format(
    [[ | awk -F: '!seen[$1":"$2]++{c=tolower($0);%s}END{%s}']],
    table.concat(branches, ';'),
    table.concat(end_parts, ';')
  )
end

-------------------------------------------------------------------------------
-- Dispatch (모드 이름으로 build_cmd 호출)
-------------------------------------------------------------------------------

--- parsed 결과로 shell 명령 생성
---@param parsed table  parse_query 결과
---@param ctx table     {preset, root, ...}
---@return string
local function dispatch(parsed, ctx)
  if not parsed then return nil end

  local cmd, mode_ref
  for _, mode in ipairs(modes) do
    if mode.name == parsed.mode then
      cmd = mode.build_cmd(parsed, ctx)
      mode_ref = mode
      break
    end
  end
  if not cmd then return nil end

  -- ranking (pipe_filter 이전에 적용)
  if mode_ref and mode_ref.rank then
    cmd = cmd .. build_rank_awk(mode_ref.rank, parsed.query)
  end

  -- 파이프 체인: "POST /health | wallet" → 결과 내 grep
  if parsed.pipe_filter and parsed.pipe_filter ~= '' then
    cmd = string.format('%s | grep -i %s', cmd, vim.fn.shellescape(parsed.pipe_filter))
  end
  return cmd
end

-------------------------------------------------------------------------------
-- User Config (.stargazer.lua)
-------------------------------------------------------------------------------

--- 프로젝트 루트에서 .stargazer.lua 로드
---@param root string
---@return table|nil
local function load_user_config(root)
  local config_path = root .. '/.stargazer.lua'
  if vim.fn.filereadable(config_path) == 1 then
    local ok, config = pcall(dofile, config_path)
    if ok and type(config) == 'table' then
      return config
    end
  end
  return nil
end

-------------------------------------------------------------------------------
-- Context Builder
-------------------------------------------------------------------------------

--- 검색 컨텍스트 생성 (프레임워크 감지 + 유저 설정 병합)
---@param root? string
---@return table ctx
local function build_context(root)
  root = root or vim.fn.getcwd()
  local preset_name, preset = detect_framework(root)

  -- preset 미감지 시 모든 프리셋 합산 fallback (shallow copy로 캐시 보호)
  if not preset then
    preset_name = '_merged'
    local merged = build_merged_preset()
    preset = { router = merged.router, model = merged.model, domain = merged.domain }
  end

  local user_config = load_user_config(root)

  -- 유저 설정이 프리셋을 오버라이드
  if user_config then
    if user_config.preset then
      preset_name = user_config.preset
      preset = presets[preset_name]
    end
    -- 유저가 직접 정의한 패턴으로 병합/교체
    if preset then
      for _, key in ipairs({ 'router', 'model', 'domain' }) do
        if user_config[key] then preset[key] = user_config[key] end
      end
    end
    -- 프리셋 없이 직접 정의한 경우
    if not preset and (user_config.router or user_config.model or user_config.domain) then
      preset = {
        router = user_config.router,
        model = user_config.model,
        domain = user_config.domain,
      }
      preset_name = 'custom'
    end
  end

  return {
    root = root,
    preset_name = preset_name,
    preset = preset,
    has_sg = vim.fn.executable('sg') == 1,
  }
end

-------------------------------------------------------------------------------
-- Exports
-------------------------------------------------------------------------------

-- Public API (init.lua에서 재export)
-- M.register_mode, M.register_preset — 이미 M에 정의됨

-- Internal API (modes.lua, init.lua에서 사용)
M.parse_query = parse_query
M.dispatch = dispatch
M.build_context = build_context
M.build_rg_cmd = build_rg_cmd
M.build_sg_cmd = build_sg_cmd
M.extract_domain = extract_domain
M.RG_SEARCH = RG_SEARCH
M.RG_BASE = RG_BASE
M.keyword_matcher = keyword_matcher
M.prefix_keyword_match = prefix_keyword_match

-- Testing
M._build_rank_awk = build_rank_awk
M._detect_framework = detect_framework
M._modes = modes
M._presets = presets

return M
