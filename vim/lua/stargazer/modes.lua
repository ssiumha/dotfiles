-- stargazer/modes.lua — 모드 정의 (OCP: 이 파일만 수정)

local engine = require('stargazer.engine')
local register_mode = engine.register_mode
local build_rg_cmd = engine.build_rg_cmd
local build_sg_cmd = engine.build_sg_cmd
local RG_SEARCH = engine.RG_SEARCH
local RG_BASE = engine.RG_BASE
local RG_PLAIN = engine.RG_PLAIN
local keyword_matcher = engine.keyword_matcher
local extract_domain = engine.extract_domain

-------------------------------------------------------------------------------
-- Default Modes (데이터 레지스트리 — register_mode으로 등록)
-------------------------------------------------------------------------------

-- 0. Git mode (priority 3) — git diff/staged 파일 검색
local git_kw = keyword_matcher({ 'diff', 'staged', 'changed' })
register_mode({
  name = 'git',
  priority = 3,
  prefix = '!',
  keywords = { 'diff', 'staged', 'changed' },
  match = function(raw)
    if raw:sub(1, 1) == '!' then
      local rest = raw:sub(2):match('^%s*(.*)')
      return { query = rest or '' }
    end
    local q = git_kw(raw)
    if q then return { query = q } end
    return nil
  end,
  build_cmd = function(parsed, _ctx)
    local q = parsed.query
    local git_files = [[{ git diff --name-only; git diff --cached --name-only; } 2>/dev/null | sort -u]]

    if not q or q == '' then
      -- No query: list changed/staged files with status
      return [[git status --porcelain -uno 2>/dev/null | awk '{s=substr($0,1,2); f=substr($0,4); n=index(f," -> "); if(n>0) f=substr(f,n+4); gsub(/"/,"",f); print f":1:"s}']]
    end

    -- With query: search within changed/staged files
    return string.format(
      [[f=$(%s); [ -z "$f" ] && echo "[Stargazer] No git changes" || echo "$f" | tr '\n' '\0' | xargs -0 %s %s 2>/dev/null]],
      git_files,
      RG_SEARCH,
      vim.fn.shellescape(q)
    )
  end,
})

-- 1. Context mode (priority 5) — 현재 파일의 도메인 기반 검색
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

-- 2. Router mode (priority 10)
local HTTP_METHODS = { GET = true, POST = true, PUT = true, DELETE = true, PATCH = true }
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
    -- Path prefix: /api/users → query에서 leading / 제거 (검색 유연성)
    if raw:match('^/%w') then
      return { query = raw:sub(2), is_path = true }
    end
    return nil
  end,
  build_cmd = function(parsed, ctx)
    local preset = ctx.preset
    if preset and preset.router then
      if parsed.method then
        local cmd = build_rg_cmd(preset.router)
        cmd = string.format('{ %s; } | grep -i %s', cmd, vim.fn.shellescape(parsed.method))
        if parsed.query and parsed.query ~= '' then
          cmd = string.format('%s | grep -i %s', cmd, vim.fn.shellescape(parsed.query))
        end
        return cmd
      end
      if parsed.is_path then
        local preset_cmd = build_rg_cmd(preset.router, parsed.query, { path_match = true })
        local merged = ctx.merged_router
        if merged and #merged > 0 then
          local merged_cmd = build_rg_cmd(merged, parsed.query, { path_match = true })
          return string.format("{ %s; %s; } 2>/dev/null | awk -F: '!seen[$1]++'", preset_cmd, merged_cmd)
        end
        return preset_cmd
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

-- 3. AST pattern mode (priority 40) — $ 접두사로 ast-grep 실행
register_mode({
  name = 'ast',
  priority = 40,
  match = function(raw)
    if raw:find('%$') then return { query = raw } end
    return nil
  end,
  build_cmd = function(parsed, ctx)
    if not ctx.has_sg then
      return 'echo "[Stargazer] ast-grep (sg) not found — install: npm i -g @ast-grep/cli"'
    end
    return build_sg_cmd(parsed.query)
  end,
})

-- 6. Infer mode (priority 50) — PascalCase 단어 복합 검색 (역할별 그룹핑)
register_mode({
  name = 'infer',
  priority = 50,
  rank_grouped = true,
  rank = {
    { pattern = '(class|interface|type|enum) [a-zA-Z]*{q}', header = 'define' },
    { pattern = '\\.(yml|yaml|xml|json|properties|toml):', header = 'config' },
    { pattern = '@(entity|table|document|schema)|create.table|add.column', header = 'schema' },
    { pattern = '@(service|repository|component|injectable|controller)', header = 'domain' },
    { pattern = '(def |function |fn )', header = 'method' },
  },
  match = function(raw)
    if raw:match('^%w+$') then
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

    -- 4. config 파일 검색 (RG_PLAIN: 확장자 제외 없음)
    parts[#parts + 1] = string.format(
      '%s --glob %s --glob %s --glob %s --glob %s --glob %s %s',
      RG_PLAIN,
      vim.fn.shellescape('*.yml'), vim.fn.shellescape('*.yaml'),
      vim.fn.shellescape('*.xml'), vim.fn.shellescape('*.json'),
      vim.fn.shellescape('*.toml'),
      vim.fn.shellescape(q)
    )

    return "{ " .. table.concat(parts, '; ') .. "; }"
  end,
})

-- 7. Default mode (priority 100) — fallback to symbol search
register_mode({
  name = 'default',
  priority = 100,
  match = function(raw)
    if raw and raw ~= '' then
      return { query = raw }
    end
    return nil
  end,
  build_cmd = function(parsed, _ctx)
    return string.format(
      '%s %s',
      RG_SEARCH,
      vim.fn.shellescape(
        '(function|class|def|fn|type|interface|enum|struct|trait|impl)\\s+' .. parsed.query
      )
    )
  end,
})
