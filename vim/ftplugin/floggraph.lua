local lines = {
  " flog cheat sheet             ? to close",
  "─────────────────────────────────────────",
  " View",
  "  <CR>    커밋 상세 (접힌 stat 뷰)",
  "  zo/zR   개별/전체 펼치기",
  "  <Tab>   커밋 상세 + 파일 목록",
  "  gp      patch 토글",
  "  gs/gu/gU staged/untracked/unstaged diff",
  "  =       접기/펼치기 토글",
  "",
  " Navigate",
  "  )/(     다음/이전 커밋",
  "  ]/[     다음/이전 ref",
  "  }/{     부모/자식",
  "  ^       커밋 시작으로",
  "",
  " Diff",
  "  dd      HEAD와 diff",
  "  DD      HEAD와 diff + paths",
  "  v선택 dd  범위 diff",
  "",
  " Toggle",
  "  a  --all    gb bisect    gm merges",
  "  gr reflog   gx graph     g/ search",
  "",
  " Commit",
  "  cc commit   ca amend     cf fixup",
  "  cob 브랜치 checkout      coo 커밋 checkout",
  "",
  " Rebase",
  "  ri interactive   rf autosquash",
  "  rr continue      ra abort    rw reword",
  "",
  " Git command",
  "  git  :Floggit 입력   .  커밋 hash로 명령",
  "",
  " Misc",
  "  u  새로고침   y<C-G> hash 복사",
  "  dq 사이드창 닫기   ZZ/gq 종료",
  "  g? vim help (전체 문서)",
}

local function show_cheatsheet()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  local width = 0
  for _, l in ipairs(lines) do
    local w = vim.fn.strdisplaywidth(l)
    if w > width then width = w end
  end
  width = width + 2
  local height = #lines

  local ui = vim.api.nvim_list_uis()[1]
  local row = math.floor((ui.height - height) / 2)
  local col = math.floor((ui.width - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
  })

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  for _, key in ipairs({ "q", "?", "<Esc>" }) do
    vim.keymap.set("n", key, close, { buffer = buf, nowait = true })
  end

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = buf,
    once = true,
    callback = close,
  })
end

vim.keymap.set("n", "?", show_cheatsheet, { buffer = 0, nowait = true })
