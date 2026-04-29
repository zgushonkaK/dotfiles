vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.cmd("set number")
vim.cmd("set signcolumn=yes")
vim.keymap.set('i', 'jk', '<Esc>')

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local plugins = {
  {
    'sainnhe/gruvbox-material',
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.gruvbox_material_enable_italic = true
      vim.cmd.colorscheme('gruvbox-material')
    end
  },
  { "nvim-tree/nvim-web-devicons", opts = {} },
  {
    'nvim-telescope/telescope.nvim', version = '*',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    }
  },
  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate'
  },
  {
    "kdheepak/lazygit.nvim",
    lazy = false,
    cmd = {
      "LazyGit", "LazyGitConfig", "LazyGitCurrentFile",
      "LazyGitFilter", "LazyGitFilterCurrentFile",
    },
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
    },
    keys = { { "<leader>lg", "<cmd>LazyGit<cr>", desc = "LazyGit" } },
    config = function()
      require("telescope").load_extension("lazygit")
    end,
  },
  {
    "mgierada/lazydocker.nvim",
    dependencies = { "akinsho/toggleterm.nvim" },
    config = function()
      require("lazydocker").setup({ border = "curved", width = 0.9, height = 0.9 })
    end,
    event = "BufRead",
    keys = {
      { "<leader>ld", function() require("lazydocker").open() end, desc = "Open Lazydocker" },
    },
  },

  -- Mason: ставится первым, до всего LSP
  {
    "mason-org/mason.nvim",
    lazy = false,
    priority = 100,
    opts = {},
  },
  {
    "mason-org/mason-lspconfig.nvim",
    lazy = false,
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
    opts = {
      ensure_installed = { "gopls", "clangd", "pyright", "lua_ls" },
      automatic_installation = true,
    },
  },
  -- nvim-lspconfig нужен только как поставщик дефолтных конфигов в vim.lsp.config
  { "neovim/nvim-lspconfig", lazy = false },

  -- Автодополнение
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
  },
  {
    {
      "nvim-neo-tree/neo-tree.nvim",
      branch = "v3.x",
      dependencies = {
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
        "nvim-tree/nvim-web-devicons",
      },
      lazy = false,
    }
  }
}

require("lazy").setup(plugins, {})

-- Telescope
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep,  { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers,    { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags,  { desc = 'Telescope help tags' })

-- Treesitter
require('nvim-treesitter').setup { install_dir = vim.fn.stdpath('data') .. '/site' }
require('nvim-treesitter').install { 'lua', 'c', 'cpp', 'go', 'python', 'html', 'sql' }
require('telescope').load_extension('lazygit')

-- Neotree 
vim.keymap.set("n", "<leader>t", "<Cmd>Neotree<CR>")
require("neo-tree").setup({
  close_if_last_window = false,
  clipboard = {sync = "universal"},
  enable_git_status = true,
  sort_function = nil,
})

-----------------------------------------------------------
-- Делаем бинари из Mason видимыми для Neovim (важно для macOS)
-----------------------------------------------------------
local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
vim.env.PATH = mason_bin .. ":" .. vim.env.PATH

-----------------------------------------------------------
-- Автодополнение
-----------------------------------------------------------
local cmp = require('cmp')
local luasnip = require('luasnip')

cmp.setup({
  snippet = {
    expand = function(args) luasnip.lsp_expand(args.body) end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>']     = cmp.mapping.scroll_docs(-4),
    ['<C-f>']     = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<CR>']      = cmp.mapping.confirm({ select = true }),
    ['<Tab>']     = cmp.mapping.select_next_item(),
    ['<S-Tab>']   = cmp.mapping.select_prev_item(),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  }, {
    { name = 'buffer' },
    { name = 'path' },
  }),
})

local capabilities = require('cmp_nvim_lsp').default_capabilities()

-----------------------------------------------------------
-- Биндинги навешиваем при подключении LSP к буферу через autocmd
-- (заменяет старый on_attach)
-----------------------------------------------------------
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local bufnr = args.buf
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
    end

    -- Навигация
    map('n', 'gd',         vim.lsp.buf.definition,      'LSP: goto definition')
    map('n', 'gD',         vim.lsp.buf.declaration,     'LSP: goto declaration')
    map('n', 'gi',         vim.lsp.buf.implementation,  'LSP: goto implementation')
    map('n', 'gt',         vim.lsp.buf.type_definition, 'LSP: goto type definition')
    map('n', 'gr',         vim.lsp.buf.references,      'LSP: list references')

    -- Информация
    map('n', 'K',          vim.lsp.buf.hover,           'LSP: hover documentation')
    map('n', '<C-k>',      vim.lsp.buf.signature_help,  'LSP: signature help')

    -- Действия
    map('n', '<leader>rn', vim.lsp.buf.rename,          'LSP: rename')
    map({'n','v'}, '<leader>ca', vim.lsp.buf.code_action, 'LSP: code action')
    map('n', '<leader>fm', function() vim.lsp.buf.format({ async = true }) end, 'LSP: format')

    -- Диагностика
    map('n', '[d',         function() vim.diagnostic.jump({ count = -1, float = true }) end, 'Diag prev')
    map('n', ']d',         function() vim.diagnostic.jump({ count =  1, float = true }) end, 'Diag next')
    map('n', '<leader>e',  vim.diagnostic.open_float,   'Diag float')
    map('n', '<leader>q',  vim.diagnostic.setloclist,   'Diag loclist')

    -- Telescope-варианты
    map('n', '<leader>gr', builtin.lsp_references,       'LSP refs (telescope)')
    map('n', '<leader>gd', builtin.lsp_definitions,      'LSP defs (telescope)')
    map('n', '<leader>gi', builtin.lsp_implementations,  'LSP impls (telescope)')
    map('n', '<leader>ds', builtin.lsp_document_symbols, 'Doc symbols')
  end,
})

-----------------------------------------------------------
-- LSP-конфиги через новый API: vim.lsp.config + vim.lsp.enable
-----------------------------------------------------------

-- Общие настройки для всех серверов (capabilities из nvim-cmp)
vim.lsp.config('*', {
  capabilities = capabilities,
})

vim.lsp.config('gopls', {
  settings = {
    gopls = {
      analyses = { unusedparams = true },
      staticcheck = true,
      gofumpt = true,
    },
  },
})

vim.lsp.config('clangd', {
  cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=iwyu" },
})

vim.lsp.config('pyright', {
  settings = {
    python = {
      analysis = {
        typeCheckingMode = "basic",
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
      },
    },
  },
})

vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      diagnostics = { globals = { 'vim' } },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
        checkThirdParty = false,
      },
      telemetry = { enable = false },
    },
  },
})

-- Включаем сервера (это запустит их при открытии соответствующих filetype)
vim.lsp.enable({ 'gopls', 'clangd', 'pyright', 'lua_ls' })

-- Диагностика
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = { border = "rounded", source = "if_many" },
})

vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = '*.go',
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})

-- Поиск .clang-format вверх по дереву от текущего файла
local function has_clang_format(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == '' then return false end
  local found = vim.fs.find(
    { '.clang-format', '_clang-format' },
    { upward = true, path = vim.fs.dirname(path), stop = vim.uv.os_homedir() }
  )
  return #found > 0
end

-- Format on save для C/C++ только при наличии .clang-format
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = { '*.c', '*.h', '*.cpp', '*.cc', '*.cxx', '*.hpp', '*.hxx' },
  callback = function(args)
    if not has_clang_format(args.buf) then return end
    vim.lsp.buf.format({
      async = false,
      bufnr = args.buf,
      filter = function(client) return client.name == 'clangd' end,
    })
  end,
})
