local map = vim.keymap.set
local function o(desc) return { desc = desc, silent = true, noremap = true } end

-- ===== 文件 / 缓冲区 =====
map("n", "<leader>w", "<cmd>write<cr>", o("保存"))
map("n", "<leader>q", "<cmd>bdelete<cr>", o("关闭当前缓冲区"))
map("n", "<leader>Q", "<cmd>qa!<cr>", o("退出 Neovim"))
map("n", "<S-l>", "<cmd>bnext<cr>", o("下一个缓冲区"))
map("n", "<S-h>", "<cmd>bprevious<cr>", o("上一个缓冲区"))

-- ===== 目录树 =====
map("n", "<M-b>", function() require("config.tree").toggle() end, o("目录树 显示/隐藏"))
map("n", "<leader>e", function() require("config.tree").focus() end, o("聚焦目录树"))

-- ===== 窗口 =====
map("n", "<C-h>", "<C-w>h", o("左边窗口"))
map("n", "<C-j>", "<C-w>j", o("下边窗口"))
map("n", "<C-k>", "<C-w>k", o("上边窗口"))
map("n", "<C-l>", "<C-w>l", o("右边窗口"))
map("n", "<leader>sv", "<cmd>vsplit<cr>", o("垂直分屏"))
map("n", "<leader>sh", "<cmd>split<cr>", o("水平分屏"))

-- ===== 搜索（telescope）=====
map("n", "<C-p>", "<cmd>Telescope find_files<cr>", o("查找文件"))
map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", o("全文搜索（当前仓库）"))
map("n", "<leader>fG", function()
  local dirs = require("config.repos").all()
  require("telescope.builtin").live_grep({
    search_dirs = dirs,
    prompt_title = ("全工作区搜索（%d 个仓库）"):format(#dirs),
  })
end, o("全文搜索（所有仓库）"))
map("n", "<leader>fb", "<cmd>Telescope buffers<cr>", o("切换缓冲区"))
map("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", o("最近打开的文件"))
map("n", "<leader>fd", "<cmd>Telescope diagnostics<cr>", o("问题列表"))

-- ===== 终端 =====
map("n", "<C-\\>", "<cmd>ToggleTerm<cr>", o("浮动终端"))
map("t", "<Esc>", [[<C-\><C-n>]], o("回到普通模式"))

-- ===== 其他 =====
map("n", "<leader>cf", function() vim.lsp.buf.format({ async = true }) end, o("格式化当前文件"))
map("n", "<leader>cd", vim.diagnostic.open_float, o("查看光标处诊断"))
map("n", "<leader>rn", vim.lsp.buf.rename, o("重命名符号"))
map("n", "<leader>ca", vim.lsp.buf.code_action, o("代码操作"))
map("n", "gd", vim.lsp.buf.definition, o("跳转定义"))
map("n", "gD", vim.lsp.buf.declaration, o("跳转声明"))
map("n", "gi", vim.lsp.buf.implementation, o("跳转实现"))
map("n", "gr", function()
  -- 用 telescope 列出所有引用（可搜索、带预览）；没装成就退回 quickfix
  local ok = pcall(function()
    require("telescope.builtin").lsp_references({ include_declaration = false, jump_type = "never" })
  end)
  if ok then return end
  vim.lsp.buf.references()
  vim.defer_fn(function() pcall(vim.cmd, "copen") end, 150)
end, o("查找引用（列表）"))
map("n", "gy", vim.lsp.buf.type_definition, o("跳转类型定义"))
map("n", "K", vim.lsp.buf.hover, o("悬停文档"))
map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, o("上一个问题"))
map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, o("下一个问题"))

-- ===== 多仓库工作区 =====
map("n", "<leader>gs", function() require("config.gitboard").toggle() end, o("Git 总览面板 开/关"))
map("n", "<leader>bb", function() require("config.bufpanel").toggle() end, o("打开的文件列表 开/关"))
map("n", "<leader>gr", function() require("config.repos").pick() end, o("切换 git 仓库"))
map("n", "<leader>gR", function() require("config.repos").back() end, o("返回上一个仓库/目录"))
map("n", "<leader>gT", function() require("config.repos").changed_all() end, o("跨仓库看所有改动"))

-- ===== 帮助 / 查看所有按键 =====
map("n", "<leader>ut", function()
  vim.ui.select({ "vscode", "tokyonight-moon", "habamax" }, { prompt = "选择主题" }, function(choice)
    if choice then pcall(vim.cmd.colorscheme, choice) end
  end)
end, o("切换主题"))
map("n", "<leader>?", function()
  require("config.cheatsheet").open()
end, o("按键速查表"))
map("n", "<leader>fk", "<cmd>Telescope keymaps<cr>", o("搜索所有按键"))
map("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", o("搜索 Neovim 帮助文档"))
