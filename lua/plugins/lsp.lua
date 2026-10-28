-- LSP：Go(gopls) / Python(pyright) + 补全 + 语法高亮
return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "hrsh7th/cmp-nvim-lsp" },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      vim.lsp.config("*", { capabilities = capabilities })

      -- Go
      vim.lsp.config("gopls", {
        settings = {
          gopls = {
            usePlaceholders = true,
            completeUnimported = true,
            staticcheck = true,
            gofumpt = true,
            analyses = { unusedparams = true, shadow = true },
            hints = {
              assignVariableTypes = true,
              compositeLiteralFields = true,
              constantValues = true,
              functionTypeParameters = true,
              parameterNames = true,
              rangeVariableTypes = true,
            },
          },
        },
      })

      -- Python：pyright 管类型，ruff 管 lint + 格式化
      local py312 = "/opt/python/cpython-3.12.16-linux-x86_64-gnu/bin/python3.12"
      vim.lsp.config("pyright", {
        settings = {
          python = {
            pythonPath = py312,
            defaultInterpreterPath = py312,
            analysis = {
              typeCheckingMode = "basic",
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = "openFilesOnly",
            },
          },
        },
      })
      vim.lsp.config("ruff", {
        init_options = {
          settings = {
            lineLength = 100,
            fixAll = true,
          },
        },
      })

      vim.lsp.enable({ "gopls", "pyright", "ruff" })

      -- LSP 连上后补一些只在有语言服务器时才有意义的键位
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local map = vim.keymap.set
          local o = { buffer = args.buf, desc = "LSP", silent = true }
          map("n", "<leader>li", "<cmd>LspInfo<cr>", o)
          map("n", "<leader>lr", "<cmd>LspRestart<cr>", o)
          map("n", "<leader>lf", function() vim.lsp.buf.format({ async = true }) end, o)
          map("n", "<leader>lo", vim.diagnostic.open_float, o)
        end,
      })
    end,
  },

  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = false }),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        formatting = {
          fields = { "kind", "abbr", "menu" },
        },
      })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "go", "gomod", "gowork", "python",
          "lua", "vim", "vimdoc", "bash", "json", "yaml", "toml",
          "markdown", "markdown_inline", "gitcommit", "diff",
        },
        auto_install = false,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
}
