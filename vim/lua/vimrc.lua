local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

vim.cmd [[packadd packer.nvim]]

require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'

  use 'neovim/nvim-lspconfig'
  use 'williamboman/mason.nvim'
  use 'williamboman/mason-lspconfig.nvim'

  use { 'nvimdev/lspsaga.nvim',
    config = function()
      require('lspsaga').setup({
        symbol_in_winbar = {
          enable = false
        },
        lightbulb = {
          enable = false
        }
      })
    end
  }
  use { 'catgoose/nvim-colorizer.lua',
    config = function()
      require'colorizer'.setup({
        -- filetypes = { 'html', 'css', 'scss', 'javascript', 'typescript', 'typescriptreact', 'vue', 'yaml', 'json', 'markdown' },
        user_default_options = {
          tailwind = 'normal',
          mode        = 'virtualtext',
          virtualtext = '■',
          virtualtext_mode   = 'foreground',
          virtualtext_inline = 'before',
        }
      })
    end
  }
  use {
    'stevearc/quicker.nvim',
    disable = true,
    config = function()
      require("quicker").setup()
    end,
  }

  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-buffer'
  use 'hrsh7th/cmp-path'
  use 'hrsh7th/cmp-cmdline'
  use 'hrsh7th/cmp-vsnip'
  use { 'hrsh7th/nvim-cmp', config = function()
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
        -- ['<Tab>'] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
        -- ['<S-Tab>'] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
      },
      -- sources = cmp.config.sources(
      --   { { name = 'nvim_lsp' } },
      --   { { name = 'buffer' } }),
      sources = cmp.config.sources({
        { name = 'vsnip' },
        { name = 'nvim_lsp' },
        { name = 'path' },
        -- { name = 'buffer' },
        -- { name = 'cmdline' },
      }, {
        { name = 'buffer' },
      }),
    }
  end }

  use 'nvim-treesitter/nvim-treesitter'
  use 'nvim-treesitter/nvim-treesitter-context'
  use 'nvim-treesitter/nvim-treesitter-textobjects'

  use 'lukas-reineke/indent-blankline.nvim'
  use 'HiPhish/rainbow-delimiters.nvim'

  use { 'lewis6991/gitsigns.nvim', config = function() require('gitsigns').setup() end }

  use 'ibhagwan/fzf-lua'

  use {
    'andymass/vim-matchup',
    setup = function()
      vim.g.matchup_matchparen_offscreen = { method = "popup" }
      vim.g.matchup_matchparen_deferred = 1
      vim.g.matchup_matchparen_hi_surround_always = 1
      vim.g.matchup_treesitter_enabled = 1
      vim.g.matchup_treesitter_disabled = { 'ruby' }
    end
  }

  -- Require plugins for avante.nvim
  use 'stevearc/dressing.nvim'
  use 'nvim-lua/plenary.nvim'
  use 'MunifTanjim/nui.nvim'
  use 'MeanderingProgrammer/render-markdown.nvim'

  -- Optional dependencies for avante.nvim
  -- use 'nvim-tree/nvim-web-devicons' -- or use 'echasnovski/mini.icons'
  -- use 'HakonHarnes/img-clip.nvim'
  -- use 'zbirenbaum/copilot.lua'
  use {
    'yetone/avante.nvim',
    disable = true,
    branch = 'main',
    run = 'make',
    config = function()
      require('avante_lib').load()
      require('avante').setup{
        provider = 'copilot',
      }
    end
  }

  if packer_bootstrap then
    require('packer').sync()
  end
end)

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("user_lsp_config", { clear = true }),
  callback = function(ev)
    local opts = { buffer = ev.buf, silent = true, noremap = true }

    -- vim.lsp.buf.document_symbol -> vista
    -- vim.lsp.buf.workspace_symbol
    -- vim.lsp.buf.signature_help -- function arguments
    -- vim.lsp.buf.rename
    -- vim.diagnostic.open_float
    vim.keymap.set("n", "gd",         vim.lsp.buf.declaration, opts)
    vim.keymap.set("n", "gi",         vim.lsp.buf.implementation, opts)
    vim.keymap.set("n", "gI",         vim.lsp.buf.type_definition, opts)
    vim.keymap.set("n", "gr",         vim.lsp.buf.references, opts)
    vim.keymap.set("n", "<c-]>",      vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "K",          vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<space>lD",  function() vim.diagnostic.setqflist({ open = true }) end, opts)
    vim.keymap.set('n', '<space>ld', ':Lspsaga show_cursor_diagnostics<cr>', opts)
    vim.keymap.set('n', '<space>lp', ':Lspsaga diagnostic_jump_prev<cr>', opts)
    vim.keymap.set('n', '<space>ln', ':Lspsaga diagnostic_jump_next<cr>', opts)
    vim.keymap.set('n', '<space>la', ':Lspsaga code_action<cr>', opts)
    -- vim.keymap.set("n", "<space>la", vim.lsp.buf.code_action, opts)
  end,
})

-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
-- TODO: add auto installer
--   scripting: python deno bash
--   devops: terraform yaml dockerfile compose bash
--   rails: MasonInstall ruby-lsp stimulus tailwind rubocop...
--   nestjs: tsserver vue
--   web: css sjon nginx perl postgres prisma sql syntax_tree html htmx
--   markdown: unison
--   vim: lua, vimls
--   ttags, typst, unison

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

vim.api.nvim_create_user_command('FzfLuaTest', function()
  fzf_command({
    ['print'] = function() print('test') end,
    ['open'] = function() vim.cmd('edit ~/.config') end,
  })
end, {})

function CloseAllFunctionFolds()
  local ts = vim.treesitter
  local parsers = require("nvim-treesitter.parsers")

  local bufnr = vim.api.nvim_get_current_buf()
  if not parsers.has_parser() then
    print("No Treesitter parser found for current buffer")
    return
  end

  local parser = parsers.get_parser(bufnr)
  local tree = parser:parse()[1]
  local root = tree:root()

  local query = ts.query.parse(
    vim.bo.filetype,
    [[
      (function_declaration) @func
      (method_signature) @func
    ]]
    -- [[
    --   (function_declaration) @func
    --   (method_declaration) @func
    -- ]]
  )

  for _, node, _ in query:iter_captures(root, bufnr, 0, -1) do
    local start_line, _, _, _ = node:range()
    vim.cmd(start_line + 1 .. "foldclose")
  end
end

-- TODO
function CloseAllStyleFolds()
  local ts_utils = require('nvim-treesitter.ts_utils')
  local parser = vim.treesitter.get_parser(0, "typescript")
  local tree = parser:parse()[1]
  local root = tree:root()

  local query = vim.treesitter.query.parse("typescript", [[
    (
      (jsx_attribute
        name: (property_identifier) @style_name
        value: (jsx_expression
                (object
                  (pair)*)) @fold
        (#eq? @style_name "style"))
    )
  ]])

  for _, match in query:iter_matches(root, 0) do
    local node = match[1]
    local start_row, _, _, _ = node:range()
    vim.api.nvim_win_set_cursor(0, { start_row + 1, 0 })
    vim.cmd("normal! zc")
  end
end

-------------------
-- williamboman/mason.nvim
-- neovim/nvim-lspconfig
-- nvimdev/lspsaga.nvim
-------------------
require('mason').setup {
  PATH = "prepend"
}
require("mason-lspconfig").setup {
  ensure_installed = {},
  handlers = {
    function(server_name)
      require("lspconfig")[server_name].setup {}
    end,
    ["html"] = function()
      require("lspconfig").html.setup {
        filetypes = { "html", "eruby" }
      }
    end,
    ["yamlls"] = function()
      require("lspconfig").yamlls.setup {
        settings = {
          yaml = {
            schemas = {
              -- TODO: use environment variable?
              ["https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.29.2-standalone-strict/deployment.json"] = "deployment/**/deployment/*.yaml",
              ["https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.29.2-standalone-strict/statefulset.json"] = "deployment/**/statefulset/*.yaml",
              ["https://json.schemastore.org/github-workflow.json"] = ".github/workflows/*",
              ["https://json.schemastore.org/github-action.json"] = ".github/actions/*",
            }
          }
        }
      }
    end,
    ["docker_compose_language_service"] = function()
      require("lspconfig").docker_compose_language_service.setup {
        filetypes = { "yaml" }
      }
    end,
    ["biome"] = function()
      local lspconfig = require("lspconfig")
      lspconfig.biome.setup {
        root_dir = lspconfig.util.root_pattern("biome.json")
      }
    end,
    ["ts_ls"] = function()
      local lspconfig = require("lspconfig")
      lspconfig.ts_ls.setup {
        root_dir = lspconfig.util.root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git"),
        init_options = {
          plugins = {
            -- {
            --   name = "@vue/typescript-plugin",
            --   location = "/usr/local/lib/node_modules/@vue/typescript-plugin",
            --   languages = {"javascript", "typescript", "vue"},
            -- },
          },
          preferences = {
            includeCompletionsForModuleExports = true,
            includeCompletionsForImportStatements = true,
          },
        },
      }
    end
  }
}

----------------------------------
-- nvim-treesitter/nvim-treesitter
----------------------------------
-- Neovim 0.11+: treesitter highlighting is built-in
-- nvim-treesitter is now only needed for parser installation
require('nvim-treesitter').setup {
  ensure_installed = { 'ruby', 'yaml' },
  auto_install = true,
}

-- nvim-treesitter-textobjects
require('nvim-treesitter-textobjects').setup {
  select = {
    enable = true,
    lookahead = true,
    keymaps = {
      ['ib'] = '@block.inner',
      ['ab'] = '@block.outer',
      ['if'] = '@function.inner',
      ['af'] = '@function.outer',
      ['ip'] = '@parameter.inner',
      ['ap'] = '@parameter.outer',
      ['aS'] = '@statement.outer',
    },
    selection_modes = {
      ['@block.outer'] = 'V',
      ['@block.inner'] = 'V',
      ['@function.outer'] = 'V',
      ['@function.inner'] = 'V',
      ['@statement.outer'] = 'V',
    },
  },
  move = {
    enable = true,
    set_jumps = true,
    goto_next_start     = { [']m'] = '@function.outer', },
    goto_next_end       = { [']M'] = '@function.outer', },
    goto_previous_start = { ['[m'] = '@function.outer', },
    goto_previous_end   = { ['[M'] = '@function.outer', },
  },
}

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
vim.opt.foldtext = "v:lua.neovim_foldtext()"

-- ref: https://github.com/neovim/neovim/pull/25391/files
---@package
---@return { [1]: string, [2]: string[] }[]|string
function neovim_foldtext()
  local ts = vim.treesitter
  local api = vim.api
  ---

  local foldstart = vim.v.foldstart
  local bufnr = api.nvim_get_current_buf()

  ---@type boolean, LanguageTree
  local ok, parser = pcall(ts.get_parser, bufnr)
  if not ok then
    return vim.fn.foldtext()
  end

  local query = ts.query.get(parser:lang(), 'highlights')
  if not query then
    return vim.fn.foldtext()
  end

  local tree = parser:parse({ foldstart - 1, foldstart })[1]

  local line = api.nvim_buf_get_lines(bufnr, foldstart - 1, foldstart, false)[1]
  if not line then
    return vim.fn.foldtext()
  end

  ---@type { [1]: string, [2]: string[], range: { [1]: integer, [2]: integer } }[] | { [1]: string, [2]: string[] }[]
  local result = {}

  local line_pos = 0

  for id, node, metadata in query:iter_captures(tree:root(), 0, foldstart - 1, foldstart) do
    local name = query.captures[id]
    local start_row, start_col, end_row, end_col = node:range()

    local priority = tonumber(metadata.priority or vim.highlight.priorities.treesitter)

    if start_row == foldstart - 1 and end_row == foldstart - 1 then
      -- check for characters ignored by treesitter
      if start_col > line_pos then
        table.insert(result, {
          line:sub(line_pos + 1, start_col),
          { { 'Folded', priority } },
          range = { line_pos, start_col },
        })
      end
      line_pos = end_col

      local text = line:sub(start_col + 1, end_col)
      table.insert(result, { text, { { '@' .. name, priority } }, range = { start_col, end_col } })
    end
  end

  local i = 1
  while i <= #result do
    -- find first capture that is not in current range and apply highlights on the way
    local j = i + 1
    while
      j <= #result
      and result[j].range[1] >= result[i].range[1]
      and result[j].range[2] <= result[i].range[2]
    do
      for k, v in ipairs(result[i][2]) do
        if not vim.tbl_contains(result[j][2], v) then
          table.insert(result[j][2], k, v)
        end
      end
      j = j + 1
    end

    -- remove the parent capture if it is split into children
    if j > i + 1 then
      table.remove(result, i)
    else
      -- highlights need to be sorted by priority, on equal prio, the deeper nested capture (earlier
      -- in list) should be considered higher prio
      if #result[i][2] > 1 then
        table.sort(result[i][2], function(a, b)
          return a[2] < b[2]
        end)
      end

      result[i][2] = vim.tbl_map(function(tbl)
        return tbl[1]
      end, result[i][2])
      result[i] = { result[i][1], result[i][2] }

      i = i + 1
    end
  end

  -- custom
  local count = vim.v.foldend - vim.v.foldstart + 1
  if count > 0 then
    --  '| ' .. vim.v.foldlevel .. ' dpeth'
    local endline = api.nvim_buf_get_lines(bufnr, vim.v.foldend - 1, vim.v.foldend, false)[1]
    endline = endline:gsub('^%s+', '')

    table.insert(result, i, { ' ...' .. count .. ' lines... ' .. endline, { 'Folded' } })
  end

  return result
end

----------------------------------
-- HiPhish/rainbow-delimiters.nvim
----------------------------------
local rainbow_delimiters = require 'rainbow-delimiters'

---@type rainbow_delimiters.config
vim.g.rainbow_delimiters = {
  strategy = {
    [''] = rainbow_delimiters.strategy['global'],
    vim = rainbow_delimiters.strategy['local'],
  },
  query = {
    [''] = 'rainbow-delimiters',
    lua = 'rainbow-blocks',
  },
  priority = {
    [''] = 110,
    lua = 210,
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
-- lukas-reineke/indent-blankline.nvim
--------------------------------------
-- local highlight = {
--     "RainbowRed",
--     "RainbowYellow",
--     "RainbowBlue",
--     "RainbowOrange",
--     "RainbowGreen",
--     "RainbowViolet",
--     "RainbowCyan",
-- }

-- local hooks = require "ibl.hooks"
-- hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
--     vim.api.nvim_set_hl(0, "RainbowRed",    { bg = "#E06C75" })
--     vim.api.nvim_set_hl(0, "RainbowYellow", { bg = "#E5C07B" })
--     vim.api.nvim_set_hl(0, "RainbowBlue",   { bg = "#61AFEF" })
--     vim.api.nvim_set_hl(0, "RainbowOrange", { bg = "#D19A66" })
--     vim.api.nvim_set_hl(0, "RainbowGreen",  { bg = "#98C379" })
--     vim.api.nvim_set_hl(0, "RainbowViolet", { bg = "#C678DD" })
--     vim.api.nvim_set_hl(0, "RainbowCyan",   { bg = "#56B6C2" })
-- end)
-- require("ibl").setup {
--     indent = { char = "" },
--     whitespace = { highlight = highlight, remove_blankline_trail = true },
--     scope = { highlight = highlight, enabled = true, char = "▎", show_exact_scope = true },
-- }
