-- Git：行内改动标记、可视化 diff、冲突解决
return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "┃" },
        change = { text = "┃" },
        delete = { text = "▁" },
        topdelete = { text = "▔" },
        changedelete = { text = "┃" },
        untracked = { text = "┆" },
      },
      signs_staged = { add = { text = "┃" }, change = { text = "┃" } },
      signcolumn = true,
      numhl = false,
      linehl = false,
      word_diff = false,
      current_line_blame = false,
      current_line_blame_opts = { virt_text = true, virt_text_pos = "eol", delay = 500, ignore_whitespace = false },
      preview_config = { border = "rounded", style = "minimal", relative = "cursor", row = 0, col = 1 },
      diff_opts = { vertical = true },   -- 对比时左右分栏（而不是上下）
      attach_to_untracked = true,
    },
    config = function(_, opts)
      require("gitsigns").setup(opts)
      local gs = require("gitsigns")
      local map = vim.keymap.set
      local function o(desc) return { desc = desc, silent = true } end

      map("n", "]c", function() gs.nav_hunk("next") end, o("下一个 Git 改动"))
      map("n", "[c", function() gs.nav_hunk("prev") end, o("上一个 Git 改动"))

      map("n", "<leader>hs", gs.stage_hunk, o("暂存当前改动块"))
      map("n", "<leader>hr", gs.reset_hunk, o("撤销当前改动块"))
      map("n", "<leader>hS", gs.stage_buffer, o("暂存整个文件"))
      map("n", "<leader>hR", gs.reset_buffer, o("撤销整个文件"))
      map("n", "<leader>hp", gs.preview_hunk, o("预览改动块"))
      map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, o("查看该行是谁写的"))
      map("n", "<leader>hB", gs.toggle_current_line_blame, o("开关行尾 blame"))
      map("n", "<leader>hd", gs.diffthis, o("与该文件的历史版本对比"))
      map("n", "<leader>hD", function() gs.diffthis("~") end, o("与上一个提交对比"))
    end,
  },

  -- 可视化 diff：整个工作区 / 某次提交 / 某个文件的历史
  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles",
      "DiffviewFocusFiles", "DiffviewFileHistory", "DiffviewRefresh",
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        default = { layout = "diff2_horizontal" },
        merge_tool = { layout = "diff3_mixed" },
        file_history = { layout = "diff2_horizontal" },
      },
      -- 用扁平列表：一行一个改动文件 + 状态 + 增删行数，比目录树好认
      file_panel = {
        listing_style = "list",
        win_config = { position = "left", width = 52 },
        tree_options = { flatten_dirs = false, folder_statuses = "only_folded" },
      },
    },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "查看所有未提交改动" },
      { "<leader>gD", "<cmd>DiffviewOpen HEAD~1 -- .<cr>", desc = "与上一个提交对比" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "当前文件的历史" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "整个仓库的提交历史" },
      { "<leader>gc", "<cmd>DiffviewClose<cr>", desc = "关闭 diff 视图" },
    },
  },

  -- 冲突解决：co 用我的 / ct 用对方的 / cb 两个都要 / c0 两个都不要
  -- 实现在 lua/config/conflict.lua，不依赖插件

  {
    "tpope/vim-fugitive",
    cmd = { "Git", "G", "Gdiffsplit", "Ggrep", "Gread", "Gwrite", "GMove", "GDelete", "GBrowse" },
    keys = {
      { "<leader>gS", "<cmd>Git<cr>", desc = "当前仓库的 git 状态（暂存/提交用）" },
    },
  },
}
