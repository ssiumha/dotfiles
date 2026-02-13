-- blink.mise: blink.cmp custom source for mise.toml tool version & name completion
-- Provides autocompletion for tool versions (`mise ls-remote`) and
-- tool names (`mise registry`) in mise config files.

local source = {}
local version_cache = {} -- { [tool_name] = CompletionItem[] }
local tools_cache = nil  -- CompletionItem[] | nil

function source.new()
  return setmetatable({}, { __index = source })
end

function source:enabled()
  local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':t')
  return name:match('mise') ~= nil and name:match('%.toml$') ~= nil
end

function source:get_trigger_characters()
  return { '"', "'" }
end

--- Extract tool name from current line (version context)
local function extract_tool(line)
  local tool = line:match('^%s*tools%.([%w_-]+)%s*=%s*["\']')
  if tool then return tool, true end
  tool = line:match('^%s*([%w_-]+)%s*=%s*["\']')
  return tool, false
end

--- Find the nearest section header above row (0-indexed)
local function find_section(bufnr, row)
  for i = row, 0, -1 do
    local l = vim.api.nvim_buf_get_lines(bufnr, i, i + 1, false)[1] or ''
    local header = l:match('^%s*%[([^%]]+)%]')
    if header then return header end
  end
  return nil
end

local function in_tools_section(bufnr, row)
  local s = find_section(bufnr, row)
  return s == 'tools' or (s and s:match('^tools%.') ~= nil)
end

local function make_response(items)
  return { items = items, is_incomplete_forward = false, is_incomplete_backward = false }
end

local function fetch_versions(tool, callback)
  if version_cache[tool] then return callback(version_cache[tool]) end
  vim.system({ 'mise', 'ls-remote', tool }, { text = true }, function(result)
    if result.code ~= 0 or not result.stdout then
      return vim.schedule(function() callback(nil) end)
    end
    local lines = vim.split(vim.trim(result.stdout), '\n')
    local items = {
      { label = 'latest', kind = vim.lsp.protocol.CompletionItemKind.Keyword, sortText = '00000000' },
    }
    for i = #lines, 1, -1 do
      local ver = vim.trim(lines[i])
      if ver ~= '' then
        items[#items + 1] = {
          label = ver,
          kind = vim.lsp.protocol.CompletionItemKind.Value,
          sortText = string.format('%08d', #lines - i + 1),
        }
      end
    end
    version_cache[tool] = items
    vim.schedule(function() callback(items) end)
  end)
end

local function fetch_tools(callback)
  if tools_cache then return callback(tools_cache) end
  vim.system({ 'mise', 'registry' }, { text = true }, function(result)
    if result.code ~= 0 or not result.stdout then
      return vim.schedule(function() callback(nil) end)
    end
    local items = {}
    for line in result.stdout:gmatch('[^\n]+') do
      local short, full = line:match('^(%S+)%s+(%S+)')
      if short then
        items[#items + 1] = {
          label = short,
          detail = full,
          kind = vim.lsp.protocol.CompletionItemKind.Module,
        }
      end
    end
    tools_cache = items
    vim.schedule(function() callback(items) end)
  end)
end

function source:get_completions(ctx, callback)
  local bufnr = vim.api.nvim_get_current_buf()
  local row = ctx.cursor[1] - 1

  -- 1) Version completion: `node = "` or `tools.node = "`
  local tool, is_inline = extract_tool(ctx.line)
  if tool then
    if not is_inline and not in_tools_section(bufnr, row) then
      return callback()
    end
    return fetch_versions(tool, function(items)
      if not items then return callback() end
      callback(make_response(items))
    end)
  end

  -- 2) Tool name completion: under [tools], typing a key name (no `=` yet)
  if ctx.line:match('^%s*[%w_-]+$') and in_tools_section(bufnr, row) then
    return fetch_tools(function(items)
      if not items then return callback() end
      callback(make_response(items))
    end)
  end

  callback()
end

return source
