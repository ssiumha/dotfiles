-- stargazer.lua — fzf-lua 기반 올인원 코드베이스 검색
-- OCP: 모든 모드/프리셋/키워드는 데이터 레지스트리. 새 모드 = register_mode() 한 번.
--
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

--- 프레임워크 프리셋 등록
---@param name string
---@param preset StargazerPreset
function M.register_preset(name, preset)
  presets[name] = preset
end

-------------------------------------------------------------------------------
-- Default Presets (데이터 기반 — 패턴만 쌓으면 됨)
-------------------------------------------------------------------------------

M.register_preset('rails', {
  detect = 'Gemfile',
  router = {
    { glob = 'config/routes.rb', pattern = '(get|post|put|patch|delete|resources|resource|match)\\s' },
    { glob = 'app/controllers/**/*.rb', pattern = 'def\\s+(index|show|create|update|destroy|new|edit)' },
  },
  model = {
    { glob = 'app/models/**/*.rb', pattern = 'class\\s+\\w+' },
    { glob = 'db/migrate/**/*.rb', pattern = 'create_table|add_column|change_column' },
  },
  domain = {
    { glob = 'app/services/**/*.rb', pattern = 'class\\s+\\w+' },
    { glob = 'app/jobs/**/*.rb', pattern = 'class\\s+\\w+' },
  },
})

M.register_preset('spring', {
  detect = 'pom.xml',
  router = {
    { glob = '**/*.java', pattern = '@(Get|Post|Put|Delete|Patch|Request)Mapping' },
  },
  model = {
    { glob = '**/*.java', pattern = '@(Entity|Table|Document)' },
  },
  domain = {
    { glob = '**/*.java', pattern = '@(Service|Repository|Component)' },
  },
})

M.register_preset('express', {
  detect = 'package.json',
  detect_content = { file = 'package.json', pattern = '"express"' },
  router = {
    { glob = '**/*.{js,ts}', pattern = '(app|router)\\.(get|post|put|delete|patch|all)\\(' },
  },
  model = {
    { glob = '**/*.{js,ts}', pattern = '(mongoose\\.model|sequelize\\.define|Schema\\()' },
  },
  domain = {
    { glob = { '**/services/**/*.{js,ts}', '**/middleware/**/*.{js,ts}' }, pattern = '(class|export|module\\.exports)' },
  },
})

M.register_preset('fastapi', {
  detect = 'pyproject.toml',
  detect_content = { file = 'pyproject.toml', pattern = 'fastapi' },
  router = {
    { glob = '**/*.py', pattern = '@(app|router)\\.(get|post|put|delete|patch)' },
  },
  model = {
    { glob = '**/*.py', pattern = 'class\\s+\\w+.*Base\\)|class\\s+\\w+.*Model\\)' },
  },
  domain = {
    { glob = { '**/services/**/*.py', '**/repositories/**/*.py' }, pattern = '(class|def)\\s+\\w+' },
  },
})

M.register_preset('django', {
  detect = 'manage.py',
  router = {
    { glob = '**/urls.py', pattern = 'path\\(|re_path\\(|url\\(' },
    { glob = '**/views.py', pattern = 'def\\s+\\w+.*request' },
  },
  model = {
    { glob = '**/models.py', pattern = 'class\\s+\\w+.*models\\.Model' },
    { glob = '**/models/**/*.py', pattern = 'class\\s+\\w+.*models\\.Model' },
  },
  domain = {
    { glob = { '**/services/**/*.py', '**/serializers.py' }, pattern = '(class|def)\\s+\\w+' },
  },
})

M.register_preset('nextjs', {
  detect = 'next.config.*',
  router = {
    { glob = 'app/**/route.{js,ts}', pattern = 'export.*(GET|POST|PUT|DELETE|PATCH)' },
    { glob = 'pages/api/**/*.{js,ts}', pattern = 'export\\s+default' },
  },
  model = {
    { glob = '**/*.{js,ts}', pattern = '(prisma|mongoose|sequelize)' },
  },
  domain = {
    { glob = { 'lib/**/*.{js,ts}', 'services/**/*.{js,ts}' }, pattern = '(export|class)\\s+\\w+' },
  },
})

M.register_preset('nestjs', {
  detect = 'nest-cli.json',
  router = {
    { glob = '**/*.ts', pattern = '@(Get|Post|Put|Delete|Patch|All|Head|Options)\\(' },
    { glob = '**/*.ts', pattern = '@Controller\\(' },
  },
  model = {
    { glob = '**/*.ts', pattern = '@(Entity|Schema)\\(' },
  },
  domain = {
    { glob = '**/*.ts', pattern = '@(Injectable|Controller)\\(' },
  },
})

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
  '--glob !*.xml',
  '--glob !*.md',
  '--glob !*.json',
  '--glob !*.yaml',
  '--glob !*.yml',
  '--glob !*.lock',
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
    cmd = string.format('{ %s; } | grep -i %s', cmd, vim.fn.shellescape(filter))
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
-- Default Modes (데이터 레지스트리 — register_mode으로 등록)
-------------------------------------------------------------------------------

-- 1. Router mode (priority 10)
local HTTP_METHODS = { GET = true, POST = true, PUT = true, DELETE = true, PATCH = true }
local router_kw = keyword_matcher({ 'route', 'endpoint' })
--- 프레임워크 미감지 시 공통 라우터 패턴
local GENERIC_ROUTER_PATTERN = table.concat({
  '@(Get|Post|Put|Delete|Patch|Request)Mapping',  -- Spring
  '@(Get|Post|Put|Delete|Patch|All)\\(',  -- NestJS
  '(app|router)\\.(get|post|put|delete|patch|all)\\(',  -- Express
  '@(app|router)\\.(get|post|put|delete|patch)',  -- FastAPI
  'path\\(|re_path\\(',  -- Django
  'export.*(GET|POST|PUT|DELETE|PATCH)',  -- Next.js
  '(get|post|put|patch|delete|resources)\\s',  -- Rails
}, '|')
M.register_mode({
  name = 'router',
  priority = 10,
  prefix = 'r',
  keywords = { 'route', 'endpoint' },
  match = function(raw)
    -- HTTP method prefix: GET /api/users
    local first_space = raw:find('%s')
    if first_space then
      local method = raw:sub(1, first_space - 1):upper()
      if HTTP_METHODS[method] then
        local path = raw:sub(first_space):match('^%s+(/.*)')
        if path then
          return { method = method, query = path }
        end
      end
    end
    -- Path prefix: /api/users
    if raw:match('^/%w') then
      return { query = raw }
    end
    -- Short prefix: r:users
    local rest = raw:match('^r:(.+)')
    if rest then return { query = rest } end
    -- Keyword: route users, endpoint users
    local q = router_kw(raw)
    if q then return { query = q } end
    return nil
  end,
  build_cmd = function(parsed, ctx)
    local preset = ctx.preset
    if preset and preset.router then
      if parsed.method then
        -- method + query 분리 grep: { 복합명령; } | grep method | grep query
        local cmd = build_rg_cmd(preset.router)
        cmd = string.format('{ %s; } | grep -i %s', cmd, vim.fn.shellescape(parsed.method))
        if parsed.query and parsed.query ~= '' then
          cmd = string.format('%s | grep -i %s', cmd, vim.fn.shellescape(parsed.query))
        end
        return cmd
      end
      return build_rg_cmd(preset.router, parsed.query)
    end
    -- Generic fallback
    local method = parsed.method and parsed.method:lower() or ''
    local filter = parsed.query
    if method ~= '' then
      filter = method .. '.*' .. parsed.query
    end
    return string.format(
      '%s %s | grep -iE %s',
      RG_BASE,
      vim.fn.shellescape(GENERIC_ROUTER_PATTERN),
      vim.fn.shellescape(filter)
    )
  end,
})

-- 2. Model mode (priority 20)
local model_kw = keyword_matcher({ 'model', 'schema', 'entity', 'table' })
M.register_mode({
  name = 'model',
  priority = 20,
  prefix = 'm',
  keywords = { 'model', 'schema', 'entity', 'table' },
  match = prefix_keyword_match('m', model_kw),
  build_cmd = function(parsed, ctx)
    local preset = ctx.preset
    if not preset or not preset.model then
      return string.format(
        '%s %s',
        RG_SEARCH,
        vim.fn.shellescape('(class|model|schema|entity|table)\\s+' .. parsed.query)
      )
    end
    return build_rg_cmd(preset.model, parsed.query)
  end,
})

-- 3. Domain mode (priority 30)
local domain_kw = keyword_matcher({ 'service', 'repository', 'repo', 'usecase', 'handler', 'middleware' })
M.register_mode({
  name = 'domain',
  priority = 30,
  prefix = 'd',
  keywords = { 'service', 'repository', 'repo', 'usecase', 'handler', 'middleware' },
  match = prefix_keyword_match('d', domain_kw),
  build_cmd = function(parsed, ctx)
    local preset = ctx.preset
    if not preset or not preset.domain then
      return string.format(
        '%s --glob %s --glob %s --glob %s %s',
        RG_SEARCH,
        vim.fn.shellescape('**/services/**'),
        vim.fn.shellescape('**/repositories/**'),
        vim.fn.shellescape('**/handlers/**'),
        vim.fn.shellescape(parsed.query)
      )
    end
    return build_rg_cmd(preset.domain, parsed.query)
  end,
})

-- 4. Symbol mode (priority 40)
local symbol_kw = keyword_matcher({
  'def', 'fn', 'function', 'class', 'type', 'interface', 'enum', 'struct', 'trait', 'impl',
})
local symbol_base_match = prefix_keyword_match('s', symbol_kw)
M.register_mode({
  name = 'symbol',
  priority = 40,
  prefix = 's',
  keywords = { 'def', 'fn', 'function', 'class', 'type', 'interface', 'enum', 'struct', 'trait', 'impl' },
  match = function(raw)
    -- AST pattern: $ 포함 (prefix/keyword 매칭보다 우선)
    if raw:find('%$') then return { query = raw, ast = true } end
    return symbol_base_match(raw)
  end,
  build_cmd = function(parsed, ctx)
    if parsed.ast then
      if not ctx.has_sg then
        return 'echo "[Stargazer] ast-grep (sg) not found — install: npm i -g @ast-grep/cli"'
      end
      return build_sg_cmd(parsed.query)
    end
    return string.format(
      '%s %s',
      RG_SEARCH,
      vim.fn.shellescape(
        '(function|class|def|fn|type|interface|enum|struct|trait|impl)\\s+' .. parsed.query
      )
    )
  end,
})

-- 5. Context mode (priority 5) — 현재 파일의 도메인 기반 검색
-- 6. Infer mode (priority 50) — PascalCase 단어 복합 검색

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

M.register_mode({
  name = 'context',
  priority = 5,
  prefix = '&',
  match = function(raw)
    if raw:sub(1, 1) ~= '&' then return nil end
    local rest = raw:sub(2):match('^%s*(.*)')
    return { query = rest or '' }
  end,
  build_cmd = function(parsed, _ctx)
    local domain = extract_domain()
    if not domain then return 'echo "[Stargazer] context: 도메인을 추출할 수 없습니다"' end

    local glob = string.format('**/%s/**', domain)
    local q = parsed.query

    if q and q ~= '' then
      return string.format(
        '%s --glob %s %s',
        RG_SEARCH,
        vim.fn.shellescape(glob),
        vim.fn.shellescape(q)
      )
    end

    return string.format(
      '%s --glob %s %s',
      RG_SEARCH,
      vim.fn.shellescape(glob),
      vim.fn.shellescape('(class|interface|def|function|type|export)\\s+\\w+')
    )
  end,
})

M.register_mode({
  name = 'infer',
  priority = 50,
  match = function(raw)
    if raw:match('^%u%w*$') then
      return { query = raw }
    end
    return nil
  end,
  build_cmd = function(parsed, ctx)
    local q = parsed.query
    local parts = {}

    -- 1. 구조적 정의 검색
    parts[#parts + 1] = string.format(
      '%s %s',
      RG_SEARCH,
      vim.fn.shellescape('(class|interface|type|enum|entity|schema|model)\\s+.*' .. q)
    )

    -- 2. 프리셋 model 패턴
    if ctx.preset and ctx.preset.model then
      parts[#parts + 1] = build_rg_cmd(ctx.preset.model, q)
    end

    -- 3. 프리셋 domain 패턴
    if ctx.preset and ctx.preset.domain then
      parts[#parts + 1] = build_rg_cmd(ctx.preset.domain, q)
    end

    return '{ ' .. table.concat(parts, '; ') .. '; } | sort -t: -k1,1 -k2,2n -u'
  end,
})

-------------------------------------------------------------------------------
-- Dispatch (모드 이름으로 build_cmd 호출)
-------------------------------------------------------------------------------

--- parsed 결과로 shell 명령 생성
---@param parsed table  parse_query 결과
---@param ctx table     {preset, root, ...}
---@return string
local function dispatch(parsed, ctx)
  if not parsed then return nil end

  local cmd
  for _, mode in ipairs(modes) do
    if mode.name == parsed.mode then
      cmd = mode.build_cmd(parsed, ctx)
      break
    end
  end
  if not cmd then return nil end

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
    '\027[90mpipe: query | filter  ─  keywords: model, service, route ...\027[0m',
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
  local ctx = build_context()

  -- awk: 테스트 파일 라인을 버퍼에 저장, 일반 라인 먼저 출력, 끝에 버퍼 출력
  local TEST_REORDER = [[ | awk '/\/tests?\/|Test[^a-z]|_test\.|\.test\.|\.spec\./{buf[++n]=$0;next}{print}END{for(i=1;i<=n;i++)print buf[i]}']]

  fzf_lua.fzf_live(function(args)
    -- fzf-lua는 query를 table로 전달: args = { "query_string" }
    local query = type(args) == 'table' and args[1] or args
    if not query or query == '' then return help_cmd() end
    query = tostring(query)

    local parsed = parse_query(query)
    local cmd = dispatch(parsed, ctx)
    if not cmd then return cmd end
    return cmd .. TEST_REORDER
  end, {
    prompt = 'Stargazer> ',
    query = opts.query or '',
    exec_empty_query = true,
    multiline = 2,
    actions = shared_actions(),
    previewer = 'builtin',
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
      local dir, rest = line:match('^(.*/)(.+)$')
      if dir and rest:match('^[^/]+:%d+:') then
        local file, loc, text = rest:match('^([^:]+)(:%d[%d:]*:)(.*)')
        if file and is_test_path(dir, file) then
          return '\027[90m' .. dir .. '\n  ' .. file .. loc .. text .. '\027[0m'
        end
        if file then
          return '\027[90m' .. dir .. '\027[0m\n  '
            .. file .. '\027[33m' .. loc .. '\027[0m' .. text
        end
        return '\027[90m' .. dir .. '\027[0m\n  ' .. rest
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

-------------------------------------------------------------------------------
-- Expose internals for testing / composition
-------------------------------------------------------------------------------

M._parse_query = parse_query
M._detect_framework = detect_framework
M._build_rg_cmd = build_rg_cmd
M._build_sg_cmd = build_sg_cmd
M._dispatch = dispatch
M._build_context = build_context
M._extract_domain = extract_domain
M._modes = modes
M._presets = presets

return M
