-- 模糊搜索
return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    lazy = false,          -- 我们自己写的选择器要直接 require 它
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<C-p>", "<cmd>Telescope find_files<cr>", desc = "查找文件" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "全文搜索" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "缓冲区" },
      { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "最近文件" },
      { "<leader>fd", "<cmd>Telescope diagnostics<cr>", desc = "问题列表" },
      { "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>", desc = "当前文件符号" },
      { "<leader>gt", "<cmd>Telescope git_status<cr>", desc = "只看被改动的文件" },
      { "<leader>gl", "<cmd>Telescope git_commits<cr>", desc = "提交历史（可搜索）" },
      { "<leader>gb", "<cmd>Telescope git_branches<cr>", desc = "切换分支" },
    },
    opts = {
      defaults = {
        prompt_prefix = "  ",
        selection_caret = "▸ ",
        borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
        file_ignore_patterns = {
          "^.git/", "node_modules/", "__pycache__/", "%.pyc$", "%.o$",
          "%.so$", "%.a$", "vendor/", "dist/", "build/",
        },
        mappings = {
          i = {
            ["<C-j>"] = "move_selection_next",
            ["<C-k>"] = "move_selection_previous",
            ["<Esc>"] = "close",
          },
        },
      },
      pickers = {
        find_files = { hidden = true, find_command = { "rg", "--files", "--hidden", "--glob", "!.git" } },
      },
    },
  },
}
