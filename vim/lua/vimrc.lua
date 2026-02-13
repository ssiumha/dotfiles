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

  { 'WTFox/jellybeans.nvim', config = function()
    vim.cmd.colorscheme('jellybeans')
  end },

}

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
  ts_ls      = { tool = 'npm:typescript-language-server',   bin = 'typescript-language-server', ft = 'typescript', tags = { 'web' } },
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

do
  local names = {}
  for name, e in pairs(lsp_tools) do
    if vim.fn.executable(e.bin) == 1 then
      names[#names + 1] = name
    end
  end
  vim.lsp.enable(names)
end

local function lsp_do_install(entries)
  local mise, brew = {}, {}
  for _, e in ipairs(entries) do
    if e.via == 'brew' then brew[#brew + 1] = e.tool else mise[#mise + 1] = e.tool end
  end
  if #mise > 0 then vim.cmd('!mise use --env local ' .. table.concat(mise, ' ')) end
  if #brew > 0 then vim.cmd('!brew install ' .. table.concat(brew, ' ')) end
end

vim.api.nvim_create_user_command('LspInstall', function(opts)
  local filter_tag = opts.args ~= '' and opts.args or nil
  local ft = vim.bo.filetype
  local matched, rest = {}, {}
  for name, e in pairs(lsp_tools) do
    if not filter_tag or vim.tbl_contains(e.tags or {}, filter_tag) then
      local mark = vim.fn.executable(e.bin) == 1 and '✓' or ' '
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
          local name = s:gsub('^[✓ ] +', ''):gsub('%s+%[.*%]$', '')
          if lsp_tools[name] then entries[#entries + 1] = lsp_tools[name] end
        end
        if #entries > 0 then lsp_do_install(entries) end
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
  root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
  init_options = {
    preferences = {
      includeCompletionsForModuleExports = true,
      includeCompletionsForImportStatements = true,
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

-- nvim-treesitter: auto-install parser on filetype enter (once per lang per session)
do
  local checked = {}
  local available = nil -- lazy-load available parsers list

  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('ts_auto_install', { clear = true }),
    callback = function(ev)
      local lang = vim.treesitter.language.get_lang(ev.match) or ev.match
      -- already installed → start treesitter highlighting
      if pcall(vim.treesitter.language.inspect, lang) then
        vim.treesitter.start(ev.buf, lang)
        return
      end
      -- auto-install: check once per lang per session
      if checked[lang] then return end
      checked[lang] = true
      if not available then
        local ok, parsers = pcall(require, 'nvim-treesitter.parsers')
        available = ok and parsers or {}
      end
      if available[lang] then
        require('nvim-treesitter').install { lang }
      end
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

