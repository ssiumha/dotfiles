-- nvim-colorizer.lua, treesitter highlights 등 true-color 기반 플러그인이 요구.
-- pckr/플러그인 config 실행 전에 설정해야 한다.
vim.opt.termguicolors = true

local function bootstrap_pckr()
  local pckr_path = vim.fn.stdpath('data') .. '/pckr/pckr.nvim'
  if not (vim.uv or vim.loop).fs_stat(pckr_path) then
    vim.fn.system({
      'git', 'clone', '--filter=blob:none',
      'https://github.com/lewis6991/pckr.nvim',
      pckr_path
    })
  end
  vim.opt.rtp:prepend(pckr_path)
end
bootstrap_pckr()

require('pckr').add{
  'neovim/nvim-lspconfig',

  { 'catgoose/nvim-colorizer.lua',
    config = function()
      require'colorizer'.setup({
        user_default_options = {
          tailwind = 'normal',
          mode        = 'virtualtext',
          virtualtext = '■',
          virtualtext_mode   = 'foreground',
          virtualtext_inline = 'before',
        }
      })
    end
  },

  { 'saghen/blink.cmp', tag = '*', config = function()
    require('blink.cmp').setup({
      keymap = {
        preset = 'default',
        ['<CR>'] = { 'accept', 'fallback' },
        ['<C-n>'] = { 'show', 'select_next', 'fallback' },
        ['<C-p>'] = { 'show', 'select_prev', 'fallback' },
      },
      completion = {
        documentation = { auto_show = true },
      },
      cmdline = {
        sources = function()
          local type = vim.fn.getcmdtype()
          if type == '/' or type == '?' then return { 'buffer' } end
          if type == ':' then return { 'cmdline' } end
          return {}
        end,
      },
      sources = {
        default = { 'lsp', 'snippets' },
        per_filetype = { toml = { 'mise', 'lsp', 'snippets' } },
        providers = {
          mise = { module = 'blink.mise', name = 'mise', async = true, timeout_ms = 5000 },
          snippets = {
            opts = {
              search_paths = { vim.fn.expand('~/dots/vim/snippets') },
            },
          },
        },
      },
      fuzzy = { implementation = 'prefer_rust' },
    })
  end },

  { 'nvim-treesitter/nvim-treesitter', branch = 'main' },
  { 'nvim-treesitter/nvim-treesitter-context', config = function()
    vim.api.nvim_set_hl(0, 'TreesitterContext', { ctermbg = 8, bg = '#393939' })
    require('treesitter-context').setup {
      enable = true,
      line_numbers = true,
      max_lines = 5,
      mode = 'cursor',
      trim_scope = 'inner',
      multiline_threshold = 10,
    }
  end },

  { 'nvim-treesitter/nvim-treesitter-textobjects', branch = 'main', config = function()
    local ts_select = require('nvim-treesitter-textobjects.select')
    local ts_move = require('nvim-treesitter-textobjects.move')
    require('nvim-treesitter-textobjects').setup {
      select = {
        lookahead = true,
        selection_modes = {
          ['@block.outer'] = 'V',
          ['@block.inner'] = 'V',
          ['@function.outer'] = 'V',
          ['@function.inner'] = 'V',
          ['@statement.outer'] = 'V',
        },
      },
      move = { set_jumps = true },
    }
    for lhs, query in pairs({
      ['ib'] = '@block.inner',
      ['ab'] = '@block.outer',
      ['if'] = '@function.inner',
      ['af'] = '@function.outer',
      ['ia'] = '@parameter.inner',
      ['aa'] = '@parameter.outer',
      ['ic'] = '@comment.outer',
      ['ac'] = '@comment.outer',
      ['aS'] = '@statement.outer',
    }) do
      vim.keymap.set({ 'x', 'o' }, lhs, function() ts_select.select_textobject(query) end)
    end
    vim.keymap.set({ 'n', 'x', 'o' }, ']m', function() ts_move.goto_next_start('@function.outer') end)
    vim.keymap.set({ 'n', 'x', 'o' }, ']M', function() ts_move.goto_next_end('@function.outer') end)
    vim.keymap.set({ 'n', 'x', 'o' }, '[m', function() ts_move.goto_previous_start('@function.outer') end)
    vim.keymap.set({ 'n', 'x', 'o' }, '[M', function() ts_move.goto_previous_end('@function.outer') end)
  end },

  { 'HiPhish/rainbow-delimiters.nvim', config = function()
    local rainbow = require('rainbow-delimiters')
    vim.api.nvim_set_hl(0, 'RainbowDelimiterRed',    { fg = '#d98870' })
    vim.api.nvim_set_hl(0, 'RainbowDelimiterYellow',  { fg = '#fad07a' })
    vim.api.nvim_set_hl(0, 'RainbowDelimiterBlue',    { fg = '#8fbfdc' })
    vim.api.nvim_set_hl(0, 'RainbowDelimiterOrange',  { fg = '#e6a75a' })
    vim.api.nvim_set_hl(0, 'RainbowDelimiterGreen',   { fg = '#99ad6a' })
    vim.api.nvim_set_hl(0, 'RainbowDelimiterViolet',  { fg = '#c6b6ee' })
    vim.api.nvim_set_hl(0, 'RainbowDelimiterCyan',    { fg = '#8197bf' })
    vim.g.rainbow_delimiters = {
      strategy = {
        [''] = function(bufnr)
          if vim.api.nvim_buf_line_count(bufnr) > 5000 then return nil end
          return rainbow.strategy['global']
        end,
        html = rainbow.strategy['local'],
        tsx = rainbow.strategy['local'],
        javascript = rainbow.strategy['local'],
      },
      query = {
        [''] = 'rainbow-delimiters',
        tsx = 'rainbow-delimiters',
        lua = 'rainbow-blocks',
      },
      highlight = {
        'RainbowDelimiterRed',
        'RainbowDelimiterYellow',
        'RainbowDelimiterBlue',
        'RainbowDelimiterOrange',
        'RainbowDelimiterGreen',
        'RainbowDelimiterViolet',
        'RainbowDelimiterCyan',
      },
    }
  end },

  { 'shellRaining/hlchunk.nvim', config = function()
    require('hlchunk').setup({
      chunk = { enable = true, delay = 0 },
      indent = { enable = true },
      line_num = { enable = false },
      blank = { enable = false },
    })
  end },

  { 'lewis6991/gitsigns.nvim', config = function()
    require('gitsigns').setup({
      on_attach = function(bufnr)
        local gs = require('gitsigns')
        local map = function(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
        end
        -- hunk navigation
        map('n', ']c', function() if vim.wo.diff then vim.cmd.normal({']c', bang=true}) else gs.nav_hunk('next') end end, 'Next hunk')
        map('n', '[c', function() if vim.wo.diff then vim.cmd.normal({'[c', bang=true}) else gs.nav_hunk('prev') end end, 'Prev hunk')
        -- hunk actions
        map({'n','v'}, 'ghs', ':Gitsigns stage_hunk<CR>', 'Stage hunk')
        map({'n','v'}, 'ghr', ':Gitsigns reset_hunk<CR>', 'Reset hunk')
        map('n', 'ghS', gs.stage_buffer, 'Stage buffer')
        map('n', 'ghu', gs.undo_stage_hunk, 'Undo stage hunk')
        map('n', 'ghp', gs.preview_hunk, 'Preview hunk')
        map('n', 'ghi', gs.preview_hunk_inline, 'Preview hunk inline (구↔신 펼치기)')
        map('n', 'ghb', function() gs.blame_line{full=true} end, 'Blame line')
        map('n', 'ghd', gs.diffthis, 'Diff this')
      end,
    })
  end },

  'ibhagwan/fzf-lua',

  { 'andymass/vim-matchup',
    config_pre = function()
      vim.g.matchup_matchparen_offscreen = { method = "popup" }
      vim.g.matchup_matchparen_deferred = 1
      vim.g.matchup_matchparen_hi_surround_always = 1
      vim.g.matchup_treesitter_enabled = 1
      vim.g.matchup_treesitter_disabled = { 'ruby' }
    end
  },

  { 'chrisgrieser/nvim-origami',
    config_pre = function()
      vim.opt.foldmethod = 'expr'
      vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
      vim.opt.foldtext = ''
      vim.opt.foldlevel = 99
      vim.opt.foldlevelstart = 99
    end,
    config = function()
      require('origami').setup({})
    end,
  },

  -- { 'MeanderingProgrammer/render-markdown.nvim',  -- markview.nvim 테스트 중
  --   cond = not vim.g.neovide,
  --   config = function()
  --     for i, bg in ipairs({'#2E3440','#3B4252','#434C5E','#4C566A','#4C566A','#5E81AC'}) do
  --       vim.api.nvim_set_hl(0, 'RenderMarkdownH'..i..'Bg', { bg = bg })
  --       vim.api.nvim_set_hl(0, 'RenderMarkdownH'..i, { fg = '#ECEFF4' })
  --       vim.api.nvim_set_hl(0, 'markdownH'..i, { fg = '#ECEFF4' })
  --     end
  --     require('render-markdown').setup({
  --       heading = { enabled = true, width = 'block', border = true, above = '' },
  --       indent = { enabled = true, width = 2, skip_level = 1, skip_heading = true },
  --     })
  --   end,
  -- },
  { 'OXY2DEV/markview.nvim', lazy = false, config = function()
    local icons = { '󰼏 ', '󰎨 ', '󰼑 ', '󰎲 ', '󰼓 ', '󰎴 ' }
    local headings = { enable = true, shift_width = 0 }
    for i = 1, 6 do
      headings['heading_' .. i] = {
        style = 'icon',
        icon = icons[i], hl = 'MarkviewHeading' .. i,
      }
    end
    require('markview').setup({
      markdown = { headings = headings },
    })
    local palette = {
      { '#ffd75f', '#4a3a20' },  -- H1: gold
      { '#ffb964', '#453020' },  -- H2: orange
      { '#8fbfdc', '#1e3050' },  -- H3: blue
      { '#99ad6a', '#1e3520' },  -- H4: green
      { '#d787ff', '#3a2050' },  -- H5: purple
      { '#8197bf', '#1e2840' },  -- H6: slate
    }
    local function set_markview_colors()
      for i, c in ipairs(palette) do
        vim.api.nvim_set_hl(0, 'MarkviewPalette'..i, { fg = c[1], bg = c[2] })
        vim.api.nvim_set_hl(0, 'MarkviewPalette'..i..'Fg', { fg = c[1] })
        vim.api.nvim_set_hl(0, 'MarkviewPalette'..i..'Bg', { bg = c[2] })
        vim.api.nvim_set_hl(0, 'MarkviewHeading'..i, { fg = c[1], bg = c[2] })
      end
    end
    set_markview_colors()
    vim.api.nvim_create_autocmd('ColorScheme', { callback = set_markview_colors })
  end },

  -- winbar: LSP breadcrumb (navic: symbol 수집, barbecue: winbar 렌더링)
  { 'SmiteshP/nvim-navic', config = function()
    require('nvim-navic').setup({ lsp = { auto_attach = true }, lazy_update_context = true })
  end },
  { 'utilyre/barbecue.nvim', requires = { 'SmiteshP/nvim-navic', 'nvim-tree/nvim-web-devicons' }, config = function()
    require('barbecue').setup()
  end },

  { 'stevearc/conform.nvim', config = function()
    require('conform').setup({
      formatters_by_ft = {
        typescript = { 'biome-check' },
        typescriptreact = { 'biome-check' },
      },
      formatters = {
        ['biome-check'] = {
          command = 'biome',
          args = { 'check', '--fix', '--unsafe', '--stdin-file-path', '$FILENAME' },
          stdin = true,
        },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_format = 'fallback',
      },
    })
  end },

  'WTFox/jellybeans.nvim',

}

vim.cmd.packadd('jellybeans.nvim')
require('jellybeans').setup({ transparent = true })
vim.cmd.colorscheme('jellybeans')

-- WinSeparator: split 경계선 가시성
-- NormalNC: 비활성 윈도우 배경 dim
vim.api.nvim_set_hl(0, 'WinSeparator', { fg = '#444444', bg = 'NONE' })
vim.api.nvim_set_hl(0, 'NormalNC', { bg = '#1a1a1a' })
vim.api.nvim_create_autocmd('ColorScheme', {
  callback = function()
    vim.api.nvim_set_hl(0, 'WinSeparator', { fg = '#444444', bg = 'NONE' })
    vim.api.nvim_set_hl(0, 'NormalNC', { bg = '#1a1a1a' })
  end,
})

-- neov-ime: Neovide IME preedit support (requires nvim 0.12.0+, neovide nightly)
if vim.g.neovide and vim.fn.has('nvim-0.12.0') == 1 then
  require('pckr').add{
    { 'sevenc-nanashi/neov-ime.nvim',
      config = function()
        require('neov-ime').setup({})
      end,
    },
  }
end

vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '●',
      [vim.diagnostic.severity.WARN]  = '●',
      [vim.diagnostic.severity.INFO]  = '·',
      [vim.diagnostic.severity.HINT]  = '·',
    },
  },
  virtual_text = { prefix = '■', spacing = 2 },
  underline = true,
  float = { border = 'rounded', source = true },
  severity_sort = true,
})

vim.api.nvim_create_autocmd('CursorHold', {
  callback = function()
    vim.diagnostic.open_float({ focusable = false })
  end,
})

-- Neovim 0.11 defaults: K(hover), grr(references), gri(implementation),
-- grn(rename), gra(code_action), grt(type_definition), gO(document_symbol),
-- <C-s>(signature_help), <C-]>(definition via tagfunc), [d/]d(diagnostic nav)
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("user_lsp_config", { clear = true }),
  callback = function(ev)
    local opts = { buffer = ev.buf, silent = true, noremap = true }
    vim.bo[ev.buf].tagfunc = 'v:lua.vim.lsp.tagfunc'
    vim.keymap.set("n", "<space>lD", function() vim.diagnostic.setqflist({ open = true }) end, opts)
    vim.keymap.set("n", "<space>ld", vim.diagnostic.open_float, opts)
    vim.keymap.set({ "n", "v" }, "gra", function() require('fzf-lua').lsp_code_actions({ silent = true, previewer = false }) end, opts)
    vim.keymap.set("n", "<space>ps", function() require('fzf-lua').lsp_live_workspace_symbols({ caseSensitive = true }) end, opts)
    vim.keymap.set("n", "<space>pd", function() require('fzf-lua').lsp_document_symbols() end, opts)
  end,
})

-------------------
-- CUSTOM
-------------------
local function get_keys(t)
  local keys = {}
  for k, _ in pairs(t) do table.insert(keys, k) end
  return keys
end

-- @param commands table
-- @usage
-- local commands = {
--   ['Test'] = function() print('test') end,
--   ['Open'] = function() vim.cmd('edit ~/.config') end,
-- }
-- @return nil
local function fzf_command(commands)
  vim.fn['fzf#run']({
    source = get_keys(commands),
    -- window = { width = 0.9, height = 0.6 },
    tmux = '90%,70%',
    sink = function(selected)
      if commands[selected] then
        commands[selected]()
      else
        vim.print('command not found: ' .. selected)
      end
    end,
  })
end


vim.api.nvim_create_user_command('Lw', function() require('fzf-lua').loclist() end, {})

vim.g.stargazer_fzf_tmux = 'center,95%,90%'
vim.keymap.set('n', '<space>s', function() require('stargazer').open() end)

vim.api.nvim_create_user_command('FzfLuaTest', function()
  fzf_command({
    ['print'] = function() print('test') end,
    ['open'] = function() vim.cmd('edit ~/.config') end,
  })
end, {})


-------------------
-- neovim/nvim-lspconfig
-- LSP servers: :LspInstall → mise use
-------------------
local lsp_tools = {
  lua_ls     = { tool = 'lua-language-server',              bin = 'lua-language-server',        ft = 'lua',        tags = { 'lua' } },
  ts_ls      = { tool = 'npm:typescript-language-server',   bin = 'typescript-language-server', ft = 'typescript', tags = { 'web', 'ts' } },
  vtsls      = { tool = 'npm:@vtsls/language-server',       bin = 'vtsls',                     ft = 'typescript', tags = { 'web', 'ts' } },
  html       = { tool = 'npm:vscode-langservers-extracted', bin = 'vscode-html-language-server',                  tags = { 'web' } },
  cssls      = { tool = 'npm:vscode-langservers-extracted', bin = 'vscode-css-language-server',  ft = 'css',       tags = { 'web' } },
  jsonls     = { tool = 'npm:vscode-langservers-extracted', bin = 'vscode-json-language-server', ft = 'json',      tags = { 'web' } },
  eslint     = { tool = 'npm:vscode-langservers-extracted', bin = 'vscode-eslint-language-server',                  tags = { 'web' } },
  dockerls   = { tool = 'npm:dockerfile-language-server-nodejs', bin = 'docker-langserver',      ft = 'dockerfile', tags = { 'infra' } },
  yamlls     = { tool = 'npm:yaml-language-server',         bin = 'yaml-language-server',       ft = 'yaml',      tags = { 'infra' } },
  bashls     = { tool = 'npm:bash-language-server',         bin = 'bash-language-server',       ft = 'bash',      tags = { 'shell' } },
  biome      = { tool = 'biome',                            bin = 'biome',                                        tags = { 'web' } },
  marksman   = { tool = 'marksman',                         bin = 'marksman',                   ft = 'markdown',  tags = { 'docs' } },
  pyright    = { tool = 'npm:pyright',                      bin = 'pyright-langserver',         ft = 'python',    tags = { 'python' } },
  tombi      = { tool = 'tombi',                            bin = 'tombi',                      ft = 'toml',      tags = { 'infra' } },
  tailwindcss = { tool = 'npm:@tailwindcss/language-server', bin = 'tailwindcss-language-server',                  tags = { 'web' } },
  htmx       = { tool = 'npm:htmx-lsp',                    bin = 'htmx-lsp',                                     tags = { 'web' } },
  emmet_language_server = { tool = 'npm:@olrtg/emmet-language-server', bin = 'emmet-language-server',              tags = { 'web' } },
  typos_lsp  = { tool = 'typos-lsp',                           bin = 'typos-lsp',                                    tags = { 'spell' } },
  jdtls      = { tool = 'jdtls',                               bin = 'jdtls',                      ft = 'java',      tags = { 'java' }, via = 'brew' },
}

-- WHY: mise shims exist in PATH even for inactive tools,
-- causing vim.fn.executable() false positives.
-- Use `mise ls --current --json` to check actually active tools.
local function lsp_active_tools()
  local tools = {}
  local out = vim.fn.system('mise ls --current --json 2>/dev/null')
  if vim.v.shell_error == 0 then
    local ok, data = pcall(vim.json.decode, out)
    if ok and type(data) == 'table' then
      for name, entries in pairs(data) do
        if type(entries) == 'table' and entries[1] and entries[1].installed then
          tools[name] = true
          local short = name:match('^[^:]+:(.+)$')
          if short then tools[short] = true end
        end
      end
    end
  end
  return tools
end

local function lsp_is_installed(e, active)
  if e.via then return vim.fn.executable(e.bin) == 1 end
  if vim.tbl_isempty(active) then return vim.fn.executable(e.bin) == 1 end
  local short = e.tool:match('^[^:]+:(.+)$')
  return active[e.tool] == true or (short ~= nil and active[short] == true)
end

do
  local active = lsp_active_tools()
  local names = {}
  for name, e in pairs(lsp_tools) do
    if lsp_is_installed(e, active) then
      names[#names + 1] = name
    end
  end
  if vim.tbl_contains(names, 'vtsls') then
    names = vim.tbl_filter(function(n) return n ~= 'ts_ls' end, names)
  end
  vim.lsp.enable(names)
end

local function lsp_parse_name(s)
  return s:gsub('^[✓ ] +', ''):gsub('%s+.*$', '')
end

local function lsp_do_install(entries)
  local mise, brew = {}, {}
  for _, e in ipairs(entries) do
    if e.via == 'brew' then brew[#brew + 1] = e.tool else mise[#mise + 1] = e.tool end
  end
  if #mise > 0 then vim.cmd('!mise use --env local ' .. table.concat(mise, ' ')) end
  if #brew > 0 then vim.cmd('!brew install ' .. table.concat(brew, ' ')) end
end

local function lsp_do_uninstall(entries)
  local mise, brew = {}, {}
  for _, e in ipairs(entries) do
    if e.via == 'brew' then brew[#brew + 1] = e.tool else mise[#mise + 1] = e.tool end
  end
  if #mise > 0 then vim.cmd('!mise rm ' .. table.concat(mise, ' ')) end
  if #brew > 0 then vim.cmd('!brew uninstall ' .. table.concat(brew, ' ')) end
end

vim.api.nvim_create_user_command('LspInstall', function(opts)
  local filter_tag = opts.args ~= '' and opts.args or nil
  local ft = vim.bo.filetype
  local active = lsp_active_tools()
  local matched, rest = {}, {}
  for name, e in pairs(lsp_tools) do
    if not filter_tag or vim.tbl_contains(e.tags or {}, filter_tag) then
      local mark = lsp_is_installed(e, active) and '✓' or ' '
      local tag_str = e.tags and '[' .. table.concat(e.tags, ',') .. ']' or ''
      local via_str = e.via and ('(' .. e.via .. ') ') or ''
      local item = mark .. ' ' .. name .. '  ' .. via_str .. tag_str
      if (e.ft or name) == ft then
        table.insert(matched, item)
      else
        table.insert(rest, item)
      end
    end
  end
  table.sort(rest)
  local items = vim.list_extend(matched, rest)
  require('fzf-lua').fzf_exec(items, {
    prompt = 'LspInstall> ',
    fzf_opts = { ['--multi'] = true },
    actions = {
      ['default'] = function(selected)
        local entries = {}
        for _, s in ipairs(selected) do
          local name = lsp_parse_name(s)
          if lsp_tools[name] then entries[#entries + 1] = lsp_tools[name] end
        end
        if #entries > 0 then lsp_do_install(entries) end
      end,
      ['ctrl-x'] = function(selected)
        local entries = {}
        for _, s in ipairs(selected) do
          local name = lsp_parse_name(s)
          if lsp_tools[name] then entries[#entries + 1] = lsp_tools[name] end
        end
        if #entries > 0 then lsp_do_uninstall(entries) end
      end,
    },
  })
end, {
  nargs = '?',
  complete = function()
    local tags = {}
    for _, e in pairs(lsp_tools) do
      for _, t in ipairs(e.tags or {}) do tags[t] = true end
    end
    return vim.tbl_keys(tags)
  end,
})
vim.lsp.config('html', {
  filetypes = { "html", "eruby" },
})

vim.lsp.config('yamlls', {
  settings = {
    yaml = {
      schemaStore = { enable = true, url = 'https://www.schemastore.org/api/json/catalog.json' },
      validate = true,
      kubernetes = "globPattern",
      schemas = {
        kubernetes = "deployment/**/*.yaml",
      },
    }
  },
})

vim.lsp.config('docker_compose_language_service', {
  filetypes = { "yaml" },
})


vim.lsp.config('typos_lsp', {
  init_options = {
    config = '~/dots/config/typos/typos.toml',
  },
  root_markers = { '.git' },
})

vim.lsp.config('biome', {
  root_markers = { "biome.json" },
})

vim.lsp.config('ts_ls', {
  filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
  root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
  init_options = {
    preferences = {
      includeCompletionsForModuleExports = true,
      includeCompletionsForImportStatements = true,
    },
  },
})

vim.lsp.config('vtsls', {
  filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
  root_markers = { 'tsconfig.json', 'package.json', 'jsconfig.json', '.git' },
  settings = {
    vtsls = { autoUseWorkspaceTsdk = true },
    typescript = {
      preferences = { includePackageJsonAutoImports = 'auto' },
    },
  },
})

do
  local lombok_jar = vim.fn.expand('~/.local/share/java/lombok.jar')
  vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if not client or client.name ~= 'jdtls' then return end
      if not vim.uv.fs_stat(lombok_jar) then
        vim.fn.mkdir(vim.fn.fnamemodify(lombok_jar, ':h'), 'p')
        vim.fn.system({ 'curl', '-fSL', '-o', lombok_jar, 'https://projectlombok.org/downloads/lombok.jar' })
        vim.notify('lombok.jar downloaded — restart jdtls (:LspRestart)', vim.log.levels.WARN)
      end
    end,
  })
  vim.lsp.config('jdtls', {
    cmd = { 'jdtls', '--jvm-arg=-javaagent:' .. lombok_jar },
    root_markers = { '.git', 'pom.xml', 'build.gradle', 'build.gradle.kts', 'settings.gradle' },
  })
end

----------------------------------
-- nvim-treesitter/nvim-treesitter
----------------------------------
-- Neovim 0.11+: highlight/indent are built-in

-- mise.toml: treesitter injection for run fields (bash highlighting)
do
  local ensured = {}
  vim.treesitter.query.add_predicate('is-mise?', function(_, _, bufnr, _)
    local filepath = vim.api.nvim_buf_get_name(tonumber(bufnr) or 0)
    local filename = vim.fn.fnamemodify(filepath, ':t')
    local is_mise = string.match(filename, '.*mise.*%.toml$') ~= nil
    if is_mise and not ensured.bash then
      ensured.bash = true
      if not pcall(vim.treesitter.language.inspect, 'bash') then
        require('nvim-treesitter').install { 'bash' }
      end
    end
    return is_mise
  end, { force = true, all = false })

end

-- nvim-treesitter: auto-install parser on filetype enter (once per lang per session).
-- Also auto-recovers when the installed parser is older than the bundled queries
-- (e.g. query references a node type the parser doesn't expose) by reinstalling.
do
  local checked = {}
  local available = nil -- lazy-load available parsers list

  local function ensure_install(lang)
    if checked[lang] then return end
    checked[lang] = true
    if not available then
      local ok, parsers = pcall(require, 'nvim-treesitter.parsers')
      available = ok and parsers or {}
    end
    if available[lang] then
      require('nvim-treesitter').install { lang }
    end
  end

  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('ts_auto_install', { clear = true }),
    callback = function(ev)
      local lang = vim.treesitter.language.get_lang(ev.match) or ev.match
      if pcall(vim.treesitter.language.inspect, lang) then
        local ok, err = pcall(vim.treesitter.start, ev.buf, lang)
        if ok then return end
        -- "Invalid node type" = query expects a node the installed parser lacks.
        -- Trigger a reinstall; other errors are left alone to avoid install loops.
        if type(err) == 'string' and err:find('Invalid node type', 1, true) then
          ensure_install(lang)
        end
        return
      end
      ensure_install(lang)
    end,
  })
end

-------------------
-- dedoc (devdocs)
-------------------
do
  -- filetype → docset resolution
  -- fmt: %s = prefix, %d = version parts (major, minor)
  local docset_map = {
    python     = { tool = 'python', prefix = 'python',     fmt = '%s~%d.%d' },
    javascript = { tool = 'node',   prefix = 'node',       fmt = '%s~%d_lts' },
    typescript = { prefix = 'typescript' },
    java       = { tool = 'java',   prefix = 'openjdk',    fmt = '%s~%d' },
    go         = { prefix = 'go' },
    rust       = { prefix = 'rust' },
    lua        = { prefix = 'lua',  fmt = '%s~%d.%d' },
    c          = { prefix = 'c' },
    cpp        = { prefix = 'cpp' },
    ruby       = { tool = 'ruby',   prefix = 'ruby',       fmt = '%s~%d.%d' },
    css        = { prefix = 'css' },
    html       = { prefix = 'html' },
  }

  -- find best installed docset matching prefix (e.g. "openjdk" → "openjdk~21")
  local function find_installed(prefix)
    local installed = vim.split(vim.trim(vim.fn.system('dedoc ls -l --porcelain 2>/dev/null')), '\n')
    for _, name in ipairs(installed) do
      if name == prefix or name:find('^' .. vim.pesc(prefix) .. '~') then return name end
    end
    return nil
  end

  local function resolve_docset(ft)
    local entry = docset_map[ft]
    if not entry then return nil end
    if not entry.tool or not entry.fmt then return entry.prefix end
    local version = vim.trim(vim.fn.system('mise current ' .. entry.tool .. ' 2>/dev/null'))
    if version ~= '' then
      local major, minor = version:match('^(%d+)%.(%d+)')
      if major then
        local candidate = string.format(entry.fmt, entry.prefix, tonumber(major), tonumber(minor))
        vim.fn.system('dedoc ls --exists ' .. candidate .. ' 2>/dev/null')
        if vim.v.shell_error == 0 then return candidate end
      end
    end
    -- fallback: unversioned prefix, or best installed match
    vim.fn.system('dedoc ls --exists ' .. entry.prefix .. ' 2>/dev/null')
    if vim.v.shell_error == 0 then return entry.prefix end
    return find_installed(entry.prefix)
  end

  -- auto-download docset on FileType (once per session)
  local checked = {}
  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('dedoc_auto_install', { clear = true }),
    callback = function(ev)
      if vim.fn.executable('dedoc') ~= 1 then return end
      local docset = resolve_docset(ev.match)
      if not docset or checked[docset] then return end
      checked[docset] = true
      local installed = vim.trim(vim.fn.system('dedoc ls -l --porcelain 2>/dev/null'))
      if installed:find(docset, 1, true) then return end
      vim.fn.system('dedoc ls --exists ' .. docset .. ' 2>/dev/null')
      if vim.v.shell_error ~= 0 then return end
      vim.notify('dedoc: downloading ' .. docset .. '...', vim.log.levels.INFO)
      vim.fn.jobstart({ 'dedoc', 'download', docset }, {
        on_exit = function(_, code)
          if code == 0 then
            vim.notify('dedoc: ' .. docset .. ' ready', vim.log.levels.INFO)
          end
        end,
      })
    end,
  })

  local function dedoc_open_page(ds, page)
    local content = vim.fn.systemlist({ 'dedoc', 'open', ds, page })
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
    vim.bo[buf].filetype = 'markdown'
    vim.bo[buf].bufhidden = 'wipe'
    vim.cmd('botright split')
    vim.api.nvim_win_set_buf(0, buf)
  end

  local function dedoc_search(ds)
    require('fzf-lua').fzf_live(function(args)
      local query = type(args) == 'table' and args[1] or args
      if not query or query == '' then return '' end
      return 'dedoc search ' .. ds .. ' ' .. vim.fn.shellescape(query) .. ' --porcelain'
    end, {
      prompt = ds .. '> ',
      exec_empty_query = false,
      preview = 'dedoc open ' .. ds .. ' {} 2>/dev/null',
      actions = { ['default'] = function(sel)
        if sel[1] then dedoc_open_page(ds, sel[1]) end
      end },
    })
  end

  -- <space>k: search docs via fzf-lua
  vim.keymap.set('n', '<space>k', function()
    if vim.fn.executable('dedoc') ~= 1 then
      vim.notify('dedoc not found', vim.log.levels.WARN)
      return
    end
    local docset = resolve_docset(vim.bo.filetype)
    if not docset then
      -- fallback: pick from installed docsets
      local installed = vim.split(vim.trim(vim.fn.system('dedoc ls -l --porcelain 2>/dev/null')), '\n')
      if #installed == 0 or installed[1] == '' then
        vim.notify('dedoc: no docsets installed', vim.log.levels.WARN)
        return
      end
      require('fzf-lua').fzf_exec(installed, {
        prompt = 'Docset> ',
        actions = { ['default'] = function(selected)
          if selected[1] then vim.schedule(function() dedoc_search(selected[1]) end) end
        end },
      })
      return
    end
    dedoc_search(docset)
  end)
end

-------------------
-- ReviewDiff: remote 대비 변경 파일을 좌측 읽기전용 패널로 띄우고,
-- 선택 시 전체 파일 + inline diff(붉은 배경, 삭제줄 인라인)로 연다. LSP는 실파일 버퍼라 그대로 동작.
-------------------
do
  local function gitline(cmd)
    local out = vim.trim(vim.fn.system(cmd))
    if vim.v.shell_error ~= 0 then return '' end
    return out
  end

  -- origin의 기본 브랜치 (origin/HEAD). 없으면 origin/master 폴백.
  local function default_ref()
    local head = gitline('git rev-parse --abbrev-ref origin/HEAD')
    if head ~= '' then return head end
    return 'origin/master'
  end

  -- review mode 진입: gitsigns base를 remote merge-base로, 시각 토글 ON (global)
  local function enter_review(base)
    local gs = require('gitsigns')
    -- change_base(global) 자체가 이미 열린 버퍼까지 새 base로 재diff한다.
    -- gs.refresh()를 추가로 부르면 async 재diff와 레이스가 나 git_obj revision이
    -- 기본값으로 되돌아가 hunk가 0이 되므로 호출하지 않는다.
    gs.toggle_linehl(true)
    gs.toggle_deleted(true)
    gs.toggle_word_diff(true)
    gs.change_base(base, true)
  end

  -- 채색 하이라이트. jellybeans엔 GitSigns*Ln 배경이 없어 linehl/삭제줄이 안 보임 → 직접 부여.
  -- colorscheme이 덮을 수 있어 ColorScheme에도 재적용.
  local function set_reviewdiff_hl()
    local set = function(g, o) vim.api.nvim_set_hl(0, g, o) end
    -- 패널 리스트용
    set('ReviewDiffAdd', { fg = '#99ad6a' })  -- +N (green)
    set('ReviewDiffDel', { fg = '#d98870' })  -- -N (red)
    set('ReviewDiffBin', { fg = '#fad07a' })  -- [bin] (yellow)
    set('ReviewDiffHeader',  { fg = '#8fbfdc', bold = true })          -- 섹션 헤더 (blue)
    set('ReviewDiffFileAdd', { fg = '#a8d76a' })                       -- 추가된 파일명 (bright green)
    set('ReviewDiffFileDel', { fg = '#e07a6a', strikethrough = true }) -- 삭제된 파일명 (red, 취소선)
    -- 변경/추가 라인 배경 (linehl) — transparent 테마에서도 또렷하게
    set('GitSignsAddLn',    { bg = '#2f5026' })
    set('GitSignsChangeLn', { bg = '#54501f' })
    -- 삭제된 줄 (show_deleted: virtual line) — 붉은 배경 + 붉은 글자
    set('GitSignsDeleteVirtLn', { bg = '#5a2626', fg = '#ff9d8a' })
    set('GitSignsDeleteVirtLnInLine', { bg = '#7a3030', fg = '#ffc4b8' })
    -- word_diff: 라인 내 바뀐 글자 강조 (가장 진하게)
    set('GitSignsAddInline',    { bg = '#3f7a35' })
    set('GitSignsChangeInline', { bg = '#7a7028' })
    set('GitSignsDeleteInline', { bg = '#8a3535' })
  end
  set_reviewdiff_hl()
  vim.api.nvim_create_autocmd('ColorScheme', { callback = set_reviewdiff_hl })

  -- ── 읽기 전용 파일 리스트 패널 (qf 대신: qfedit/qfreplace 등 간섭 회피) ──
  -- entries[lnum] = { path=절대경로, rel=상대경로, status='A'|'M'|'D'|'R' } 또는 false(헤더/help)
  local panel = { buf = nil, win = nil, target = nil, entries = nil, base = nil, root = nil, layout = nil }
  local ns_panel = vim.api.nvim_create_namespace('reviewdiff_panel')

  -- 파일을 열 대상(메인) 창으로 포커스. 없으면 레이아웃 방향으로 생성.
  local function focus_target()
    if panel.target and vim.api.nvim_win_is_valid(panel.target)
        and panel.target ~= panel.win then
      vim.api.nvim_set_current_win(panel.target)
      return
    end
    local nav = ({ left = 'l', top = 'j', bottom = 'k' })[panel.layout] or 'k'
    local mk = ({ left = 'rightbelow vsplit', top = 'belowright split',
      bottom = 'aboveleft split' })[panel.layout] or 'aboveleft split'
    vim.api.nvim_set_current_win(panel.win)
    vim.cmd('wincmd ' .. nav)
    if vim.api.nvim_get_current_win() == panel.win then
      vim.cmd(mk)
    end
  end

  -- 삭제된 파일: 작업트리에 없으니 base 버전 내용을 읽기전용으로 대상 창에 띄운다.
  local function show_deleted_file(rel)
    local content = vim.fn.systemlist({ 'git', '-C', panel.root, 'show', panel.base .. ':' .. rel })
    if vim.v.shell_error ~= 0 then
      vim.notify('ReviewDiff: cannot show deleted ' .. rel, vim.log.levels.WARN)
      return
    end
    focus_target()
    local b = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(b, 0, -1, false, content)
    local ft = vim.filetype.match({ filename = rel, contents = content })
    if ft then vim.bo[b].filetype = ft end
    vim.bo[b].modifiable = false
    vim.bo[b].buftype = 'nofile'
    vim.bo[b].bufhidden = 'wipe'
    vim.api.nvim_win_set_buf(0, b)
    pcall(vim.api.nvim_buf_set_name, b, rel .. ' (deleted@' .. panel.base:sub(1, 7) .. ')')
    panel.target = vim.api.nvim_get_current_win()
  end

  -- 커서 줄 열기. mode: 'edit'(대상창+포커스) | 'preview'(대상창, 포커스는 패널 유지)
  --                    | 'vsplit'(우측 분할) | 'tab'
  local function open_under_cursor(mode)
    if not (panel.win and vim.api.nvim_win_is_valid(panel.win)) then return end
    local lnum = vim.api.nvim_win_get_cursor(panel.win)[1]
    local e = panel.entries and panel.entries[lnum]
    if not e then return end  -- 헤더/빈줄/help
    if e.status == 'D' then
      show_deleted_file(e.rel)
    else
      local esc = vim.fn.fnameescape(e.path)
      if mode == 'tab' then
        vim.cmd('tabedit ' .. esc)
      elseif mode == 'vsplit' then
        focus_target(); vim.cmd('vsplit ' .. esc)
      else
        focus_target(); vim.cmd('edit ' .. esc)
      end
      panel.target = vim.api.nvim_get_current_win()
    end
    -- preview: diff만 우측에 띄우고 커서는 패널로 복귀 (netrw 스타일)
    if mode == 'preview' and panel.win and vim.api.nvim_win_is_valid(panel.win) then
      vim.api.nvim_set_current_win(panel.win)
    end
  end

  local function close_panel()
    if panel.win and vim.api.nvim_win_is_valid(panel.win) then
      vim.api.nvim_win_close(panel.win, true)
    end
    if panel.buf and vim.api.nvim_buf_is_valid(panel.buf) then
      pcall(vim.api.nvim_buf_delete, panel.buf, { force = true })
    end
    panel.buf, panel.win, panel.entries = nil, nil, nil
  end

  -- :ReviewDiff [ref]   ref 대비 변경 파일을 좌측 패널로. <CR>=열기, s=우측분할, t=탭, q=닫기
  -- :ReviewDiff! [ref]  먼저 git fetch 후 동일 동작
  vim.api.nvim_create_user_command('ReviewDiff', function(opts)
    -- `nvim +ReviewDiff!` 처럼 startup 중(+cmd)에 호출되면 VimEnter(플러그인 로드 완료)
    -- 보다 먼저 실행돼 gitsigns가 아직 attach되지 않는다. VimEnter 후로 한 번 미뤄 재실행.
    if vim.v.vim_did_enter == 0 then
      vim.api.nvim_create_autocmd('VimEnter', { once = true, callback = function()
        vim.cmd((opts.bang and 'ReviewDiff! ' or 'ReviewDiff ') .. opts.args)
      end })
      return
    end
    local root = gitline('git rev-parse --show-toplevel')
    if root == '' then
      vim.notify('ReviewDiff: not a git repo', vim.log.levels.WARN)
      return
    end
    if opts.bang then
      vim.notify('ReviewDiff: fetching origin...', vim.log.levels.INFO)
      vim.fn.system({ 'git', '-C', root, 'fetch', '--quiet' })
    end
    local ref = opts.args ~= '' and opts.args or default_ref()
    -- 3-dot(merge-base) 기준 → GitHub PR diff와 일치. 실패 시 ref 직접 비교로 폴백.
    local base = gitline('git merge-base ' .. vim.fn.shellescape(ref) .. ' HEAD')
    if base == '' then base = ref end

    enter_review(base)

    -- 상태 분류: name-status (R/C는 새 경로). 삭제 파일도 포함.
    local stat_lines = vim.fn.systemlist({
      'git', '-C', root, 'diff', '--name-status', base,
    })
    if vim.v.shell_error ~= 0 or #stat_lines == 0 then
      vim.notify('ReviewDiff: no changed files vs ' .. ref, vim.log.levels.INFO)
      return
    end
    -- +/- 라인수: numstat `adds\tdels\tpath` (rename은 path가 달라 누락 가능)
    local counts = {}
    for _, line in ipairs(vim.fn.systemlist({
      'git', '-C', root, 'diff', '--numstat', base,
    })) do
      local a, d, p = line:match('^(%S+)\t(%S+)\t(.+)$')
      if p then counts[p] = { a = a, d = d } end
    end
    -- 상태별 그룹: Modified(M/R/C/T) / Added(A) / Deleted(D)
    local mod, add, del = {}, {}, {}
    for _, line in ipairs(stat_lines) do
      local code, rest = line:match('^(%S+)\t(.+)$')
      if code then
        local c0 = code:sub(1, 1)
        local rel = rest
        if c0 == 'R' or c0 == 'C' then rel = rest:match('\t(.+)$') or rest end
        local e = { rel = rel, status = c0, c = counts[rel] }
        if c0 == 'A' then add[#add + 1] = e
        elseif c0 == 'D' then del[#del + 1] = e
        else mod[#mod + 1] = e end
      end
    end
    -- 각 그룹 path 순 정렬 (결정적)
    local by_rel = function(x, y) return x.rel < y.rel end
    table.sort(mod, by_rel); table.sort(add, by_rel); table.sort(del, by_rel)

    -- 패널 라인/채색/엔트리 빌드. entry=false → 헤더/빈줄/help(열기 대상 아님)
    -- 명시적 카운터 사용: seg=nil 을 #segs+1 로 넣으면 저장이 안 돼 인덱스가 어긋난다.
    local lines, segs, entries = {}, {}, {}
    local n = 0
    local function push(text, seg, entry)
      n = n + 1
      lines[n] = text
      segs[n] = seg or false
      entries[n] = entry
    end
    local function header(title, n)
      if #lines > 0 then push('', nil, false) end
      local s = title .. ' (' .. n .. ')'
      push(s, { { 0, #s, 'ReviewDiffHeader' } }, false)
    end
    local function file_row(e, path_hl)
      local c = e.c
      local a_s, d_s
      if c and c.a == '-' then a_s, d_s = '[bin]', ''
      elseif c then a_s, d_s = '+' .. c.a, '-' .. c.d
      else a_s, d_s = '', '' end
      local text = string.format('%-6s%-6s%s', a_s, d_s, e.rel)
      local seg = {}
      if a_s == '[bin]' then seg[#seg + 1] = { 0, 5, 'ReviewDiffBin' }
      elseif a_s ~= '' then seg[#seg + 1] = { 0, #a_s, 'ReviewDiffAdd' } end
      if d_s ~= '' then seg[#seg + 1] = { 6, 6 + #d_s, 'ReviewDiffDel' } end
      if path_hl then seg[#seg + 1] = { 12, #text, path_hl } end
      push(text, seg, { path = root .. '/' .. e.rel, rel = e.rel, status = e.status })
    end

    local help = '<CR>/o open · O preview · s split · t tab · q quit'
    push(help, { { 0, #help, 'Comment' } }, false)
    if #mod > 0 then header('Modified', #mod); for _, e in ipairs(mod) do file_row(e, nil) end end
    if #add > 0 then header('Added', #add); for _, e in ipairs(add) do file_row(e, 'ReviewDiffFileAdd') end end
    if #del > 0 then header('Deleted', #del); for _, e in ipairs(del) do file_row(e, 'ReviewDiffFileDel') end end

    -- 기존 패널이 떠 있으면 정리 후 새로 생성
    close_panel()
    local prev = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    for i, seg in ipairs(segs) do
      if seg then
        for _, r in ipairs(seg) do
          vim.api.nvim_buf_set_extmark(buf, ns_panel, i - 1, r[1],
            { end_col = r[2], hl_group = r[3] })
        end
      end
    end
    vim.bo[buf].modifiable = false
    vim.bo[buf].buftype = 'nofile'
    vim.bo[buf].bufhidden = 'wipe'
    vim.bo[buf].swapfile = false
    vim.bo[buf].filetype = 'reviewdiff'

    -- 레이아웃: vim.g.reviewdiff_panel = 'bottom'(기본) | 'top' | 'left'
    -- 크기: vim.g.reviewdiff_size (기본 가로 14줄 / 세로 52칸)
    local layout = vim.g.reviewdiff_panel or 'bottom'
    local opencmd = ({ left = 'topleft vsplit', top = 'topleft split',
      bottom = 'botright split' })[layout] or 'botright split'
    vim.cmd(opencmd)
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
    local wo = vim.wo[win]
    if layout == 'left' then
      vim.cmd('vertical resize ' .. (vim.g.reviewdiff_size or 52))
      wo.winfixwidth = true
    else
      vim.cmd('resize ' .. (vim.g.reviewdiff_size or 14))
      wo.winfixheight = true
    end
    wo.number, wo.relativenumber = false, false
    wo.cursorline, wo.wrap = true, false
    wo.signcolumn = 'no'

    panel.buf, panel.win, panel.target, panel.layout = buf, win, prev, layout
    panel.entries, panel.base, panel.root = entries, base, root

    -- 첫 파일 행으로 커서 이동 (헤더 건너뜀)
    for i, e in ipairs(entries) do
      if e then vim.api.nvim_win_set_cursor(win, { i, 0 }); break end
    end

    local map = function(lhs, fn, desc)
      vim.keymap.set('n', lhs, fn, { buffer = buf, nowait = true, silent = true, desc = desc })
    end
    map('<CR>', function() open_under_cursor('edit') end, 'open')
    map('o',    function() open_under_cursor('edit') end, 'open')
    map('O',    function() open_under_cursor('preview') end, 'preview (커서 유지)')
    map('s',    function() open_under_cursor('vsplit') end, 'open (vsplit)')
    map('t',    function() open_under_cursor('tab') end, 'open (tab)')
    map('q',    close_panel, 'close panel')
  end, {
    nargs = '?',
    bang = true,
    complete = function() return { 'origin/master', 'origin/main', 'origin/develop' } end,
  })

  -- :ReviewDiffDebug  현재 버퍼의 gitsigns/렌더 상태를 한 번에 출력 (원인 진단용)
  vim.api.nvim_create_user_command('ReviewDiffDebug', function()
    local gs = require('gitsigns')
    local c = require('gitsigns.config').config
    local buf = vim.api.nvim_get_current_buf()
    local hunks = gs.get_hunks(buf)
    local em = 0
    for n, id in pairs(vim.api.nvim_get_namespaces()) do
      if n:match('gitsigns') then
        em = em + #vim.api.nvim_buf_get_extmarks(buf, id, 0, -1, {})
      end
    end
    print(vim.inspect({
      buf = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ':.'),
      attached = hunks ~= nil,
      hunks = hunks and #hunks or 'nil(not attached)',
      base = c.base,
      linehl = c.linehl,
      show_deleted = c.show_deleted,
      word_diff = c.word_diff,
      signcolumn = vim.wo.signcolumn,
      termguicolors = vim.o.termguicolors,
      gitsigns_extmarks = em,
      ChangeLn_bg = vim.api.nvim_get_hl(0, { name = 'GitSignsChangeLn' }).bg,
      AddLn_bg = vim.api.nvim_get_hl(0, { name = 'GitSignsAddLn' }).bg,
      max_file_length = c.max_file_length,
      line_count = vim.api.nvim_buf_line_count(buf),
    }))
  end, {})

  -- :ReviewDiffEnd  review mode 종료 (패널 닫기 + base/시각 토글 원복)
  vim.api.nvim_create_user_command('ReviewDiffEnd', function()
    close_panel()
    local gs = require('gitsigns')
    gs.reset_base(true)
    gs.toggle_linehl(false)
    gs.toggle_deleted(false)
    gs.toggle_word_diff(false)
  end, {})
end

-------------------
-- misc
-------------------
require('unicode_overlay').enable()
