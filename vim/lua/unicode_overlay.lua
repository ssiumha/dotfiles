local M = {}

local ns = vim.api.nvim_create_namespace("unicode_escape_overlay")

local function decode_unicode_escapes(s)
  -- \uXXXX (4 hex)만 처리. (서로게이트 페어는 아래에서 설명)
  return (s:gsub("\\u(%x%x%x%x)", function(hex)
    local code = tonumber(hex, 16)
    if not code then return "\\u" .. hex end
    -- codepoint -> utf8
    return vim.fn.nr2char(code)
  end))
end

local function clear(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end

local function render(bufnr, start_line, end_line)
  clear(bufnr)

  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line, false)
  for i, line in ipairs(lines) do
    if line:find("\\u%x%x%x%x") then
      local decoded = decode_unicode_escapes(line)
      -- 원문과 같으면 굳이 표시 안 해도 됨
      if decoded ~= line then
        local lnum = start_line + (i - 1)
        vim.api.nvim_buf_set_extmark(bufnr, ns, lnum, 0, {
          virt_text = { { "  ⟶ " .. decoded, "Comment" } },
          virt_text_pos = "eol", -- end of line
        })
      end
    end
  end
end

-- 현재 창에 보이는 영역만 업데이트 (가볍게)
function M.refresh_visible()
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].buftype ~= "" then return end

  local top = vim.fn.line("w0") - 1
  local bot = vim.fn.line("w$")     -- end is exclusive in get_lines
  render(bufnr, top, bot)
end

function M.enable()
  -- 화면 스크롤/편집 시 갱신
  local group = vim.api.nvim_create_augroup("UnicodeEscapeOverlay", { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI", "WinScrolled" }, {
    group = group,
    callback = function()
      -- 너무 잦으면 느려질 수 있으니, 필요하면 debounce 추가
      M.refresh_visible()
    end,
  })
  M.refresh_visible()
end

function M.disable()
  local bufnr = vim.api.nvim_get_current_buf()
  clear(bufnr)
  pcall(vim.api.nvim_del_augroup_by_name, "UnicodeEscapeOverlay")
end

return M
