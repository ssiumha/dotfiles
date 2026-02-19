-- stargazer/modes.lua — 모드 정의 (OCP: 이 파일만 수정)

local engine = require('stargazer.engine')
local register_mode = engine.register_mode
local build_rg_cmd = engine.build_rg_cmd
local build_sg_cmd = engine.build_sg_cmd
local RG_SEARCH = engine.RG_SEARCH
local RG_BASE = engine.RG_BASE
local keyword_matcher = engine.keyword_matcher
local prefix_keyword_match = engine.prefix_keyword_match
local extract_domain = engine.extract_domain

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
register_mode({
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
register_mode({
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
register_mode({
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
register_mode({
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
register_mode({
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

-- 6. Infer mode (priority 50) — PascalCase 단어 복합 검색
register_mode({
  name = 'infer',
  priority = 50,
  rank = {
    { pattern = '(class|interface|type|enum) \\w*{q}' },       -- 정의 + 이름에 쿼리
    { pattern = '(class|interface|type|enum) ' },               -- 정의 (이름에 쿼리 없음)
    { pattern = '@(entity|table|document|schema)' },            -- 모델 어노테이션
    { pattern = '@(service|repository|component|injectable|controller)' },  -- 도메인 어노테이션
    { pattern = '(def |function |fn )' },                       -- 메서드 정의
  },
  match = function(raw)
    if raw:match('^%u%w*$') then
      return { query = raw }
    end
    return nil
  end,
  build_cmd = function(parsed, ctx)
    local q = parsed.query
    local parts = {}

    -- 1. model 패턴 (가장 specific — 정의 위치)
    if ctx.preset and ctx.preset.model then
      parts[#parts + 1] = build_rg_cmd(ctx.preset.model, q)
    end

    -- 2. domain 패턴 (service, repository 등)
    if ctx.preset and ctx.preset.domain then
      parts[#parts + 1] = build_rg_cmd(ctx.preset.domain, q)
    end

    -- 3. 구조적 정의 (가장 broad — fallback)
    parts[#parts + 1] = string.format(
      '%s %s',
      RG_SEARCH,
      vim.fn.shellescape('(class|interface|type|enum)\\s+.*' .. q)
    )

    -- dedup은 dispatch의 build_rank_awk가 처리
    return "{ " .. table.concat(parts, '; ') .. "; }"
  end,
})
