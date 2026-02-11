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

  'hrsh7th/cmp-nvim-lsp',
  'hrsh7th/cmp-buffer',
  'hrsh7th/cmp-path',
  'hrsh7th/cmp-cmdline',
  'hrsh7th/cmp-vsnip',
  { 'hrsh7th/nvim-cmp', config = function()
    local cmp = require'cmp'
    cmp.setup{
      snippet = {
        expand = function(args)
          vim.fn["vsnip#anonymous"](args.body)
        end,
      },
      mapping = {
        ['<C-e>'] = cmp.mapping.abort(),
        ['<C-n>'] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
        ['<C-p>'] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
        ['<PageUp>'] = cmp.mapping.scroll_docs(-4),
        ['<PageDown>'] = cmp.mapping.scroll_docs(4),
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
      },
      sources = cmp.config.sources({
        { name = 'vsnip' },
        { name = 'nvim_lsp' },
        { name = 'path' },
      }, {
        { name = 'buffer' },
      }),
    }
  end },

  { 'nvim-treesitter/nvim-treesitter', branch = 'main' },
  'nvim-treesitter/nvim-treesitter-context',
  { 'nvim-treesitter/nvim-treesitter-textobjects', branch = 'main' },

  { 'shellRaining/hlchunk.nvim' },

  { 'lewis6991/gitsigns.nvim', config = function() require('gitsigns').setup() end },

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

  'MeanderingProgrammer/render-markdown.nvim',

  { 'WTFox/jellybeans.nvim', config = function()
    vim.cmd.colorscheme('jellybeans')
  end },
}

-- Neovim 0.11 defaults: K(hover), grr(references), gri(implementation),
-- grn(rename), gra(code_action), grt(type_definition), gO(document_symbol),
-- <C-s>(signature_help), <C-]>(definition via tagfunc), [d/]d(diagnostic nav)
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("user_lsp_config", { clear = true }),
  callback = function(ev)
    local opts = { buffer = ev.buf, silent = true, noremap = true }
    vim.keymap.set("n", "<space>lD", function() vim.diagnostic.setqflist({ open = true }) end, opts)
    vim.keymap.set("n", "<space>ld", vim.diagnostic.open_float, opts)
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

vim.api.nvim_set_keymap('n', '<space>ps', "<cmd>lua require('fzf-lua').lsp_live_workspace_symbols({ caseSensitive = true })<cr>", { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<space>pd', "<cmd>lua require('fzf-lua').lsp_document_symbols()<cr>", { noremap = true, silent = true })

vim.api.nvim_create_user_command('Lw', function() require('fzf-lua').loclist() end, {})

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
  lua_ls     = { tool = 'lua-language-server',              bin = 'lua-language-server',        ft = 'lua' },
  ts_ls      = { tool = 'npm:typescript-language-server',   bin = 'typescript-language-server', ft = 'typescript' },
  html       = { tool = 'npm:vscode-langservers-extracted', bin = 'vscode-html-language-server' },
  yamlls     = { tool = 'npm:yaml-language-server',         bin = 'yaml-language-server',       ft = 'yaml' },
  bashls     = { tool = 'npm:bash-language-server',         bin = 'bash-language-server',       ft = 'bash' },
  biome      = { tool = 'biome',                            bin = 'biome' },
  marksman   = { tool = 'marksman',                         bin = 'marksman',                   ft = 'markdown' },
  pyright    = { tool = 'npm:pyright',                      bin = 'pyright-langserver',         ft = 'python' },
  tombi      = { tool = 'tombi',                            bin = 'tombi',                      ft = 'toml' },
  tailwindcss = { tool = 'npm:@tailwindcss/language-server', bin = 'tailwindcss-language-server' },
  htmx       = { tool = 'npm:htmx-lsp',                    bin = 'htmx-lsp' },
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

local function lsp_do_install(entry)
  vim.cmd('!mise use --env local ' .. entry.tool)
end

vim.api.nvim_create_user_command('LspInstall', function()
  local ft = vim.bo.filetype
  local matched, rest = {}, {}
  for name, e in pairs(lsp_tools) do
    local mark = vim.fn.system('mise which ' .. e.bin .. ' 2>/dev/null'):find('^/') and '✓' or ' '
    local item = mark .. ' ' .. name
    if (e.ft or name) == ft then
      table.insert(matched, item)
    else
      table.insert(rest, item)
    end
  end
  table.sort(rest)
  local items = vim.list_extend(matched, rest)
  require('fzf-lua').fzf_exec(items, {
    prompt = 'LspInstall> ',
    actions = {
      ['default'] = function(selected)
        local sel = selected[1]:gsub('^[✓ ] +', '')
        if lsp_tools[sel] then lsp_do_install(lsp_tools[sel]) end
      end,
    },
  })
end, {})
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

-- nvim-treesitter-textobjects
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
  move = {
    set_jumps = true,
  },
}

-- textobjects select
for lhs, query in pairs({
  ['ib'] = '@block.inner',
  ['ab'] = '@block.outer',
  ['if'] = '@function.inner',
  ['af'] = '@function.outer',
  ['ip'] = '@parameter.inner',
  ['ap'] = '@parameter.outer',
  ['aS'] = '@statement.outer',
}) do
  vim.keymap.set({ 'x', 'o' }, lhs, function() ts_select.select(query) end)
end

-- textobjects move
vim.keymap.set({ 'n', 'x', 'o' }, ']m', function() ts_move.goto_next_start('@function.outer') end)
vim.keymap.set({ 'n', 'x', 'o' }, ']M', function() ts_move.goto_next_end('@function.outer') end)
vim.keymap.set({ 'n', 'x', 'o' }, '[m', function() ts_move.goto_previous_start('@function.outer') end)
vim.keymap.set({ 'n', 'x', 'o' }, '[M', function() ts_move.goto_previous_end('@function.outer') end)

vim.api.nvim_set_hl(0, "TreesitterContext", { ctermbg = 8, bg = "#393939" })
require'treesitter-context'.setup{
  enable = true,
  line_numbers = true,
  max_lines = 10,
  mode = 'topline',
  multiline_threshold = 1,
}

vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
-- Neovim 0.11: foldtext='' enables built-in treesitter-highlighted foldtext
vim.opt.foldtext = ''


--------------------------------------
--- render-markdown
--------------------------------------
vim.api.nvim_set_hl(0, 'RenderMarkdownH1Bg', { bg = '#2E3440' })
vim.api.nvim_set_hl(0, 'RenderMarkdownH2Bg', { bg = '#3B4252' })
vim.api.nvim_set_hl(0, 'RenderMarkdownH3Bg', { bg = '#434C5E' })
vim.api.nvim_set_hl(0, 'RenderMarkdownH4Bg', { bg = '#4C566A' })
vim.api.nvim_set_hl(0, 'RenderMarkdownH5Bg', { bg = '#4C566A' })
vim.api.nvim_set_hl(0, 'RenderMarkdownH6Bg', { bg = '#5E81AC' })
vim.api.nvim_set_hl(0, 'RenderMarkdownH1', { fg = '#ECEFF4' })
vim.api.nvim_set_hl(0, 'RenderMarkdownH2', { fg = '#ECEFF4' })
vim.api.nvim_set_hl(0, 'RenderMarkdownH3', { fg = '#ECEFF4' })
vim.api.nvim_set_hl(0, 'RenderMarkdownH4', { fg = '#ECEFF4' })
vim.api.nvim_set_hl(0, 'RenderMarkdownH5', { fg = '#ECEFF4' })
vim.api.nvim_set_hl(0, 'RenderMarkdownH6', { fg = '#ECEFF4' })
vim.api.nvim_set_hl(0, 'markdownH1', { fg = '#ECEFF4' })
vim.api.nvim_set_hl(0, 'markdownH2', { fg = '#ECEFF4' })
vim.api.nvim_set_hl(0, 'markdownH3', { fg = '#ECEFF4' })
vim.api.nvim_set_hl(0, 'markdownH4', { fg = '#ECEFF4' })
vim.api.nvim_set_hl(0, 'markdownH5', { fg = '#ECEFF4' })
vim.api.nvim_set_hl(0, 'markdownH6', { fg = '#ECEFF4' })


if not vim.g.neovide then
  require('render-markdown').setup({
    heading = {
      enabled = true,
      width = 'block',
      border = true,
      above = '',
    },
    indent = {
      enabled = true,
      width = 2,
      skip_level = 1,
      skip_heading = true,
    },
  })
end

--------------------------------------
-- shellRaining/hlchunk.nvim
--------------------------------------
require('hlchunk').setup({
  chunk = {
    enable = true,
    delay = 0,
  },
  indent = {
    enable = true,
  },
  line_num = {
    enable = false,
  },
  blank = {
    enable = false,
  },
})
