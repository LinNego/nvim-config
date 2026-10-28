-- 基础选项：尽量贴近 VSCode 的手感
local opt = vim.opt

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- 让终端里启动的 shell 也能找到 go / gopls / pyright
vim.env.PATH = "/usr/local/go/bin:/root/go/bin:/usr/local/bin:" .. vim.env.PATH

-- 行号 / 光标
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.signcolumn = "yes"          -- 常驻符号列，git 改动标记不会让画面跳动
opt.wrap = false

-- 鼠标：终端里也能点、能滚、能拖分栏
opt.mouse = "a"
opt.termguicolors = true

-- 搜索
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = false
opt.inccommand = "split"        -- 替换时实时预览

-- 编辑
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.smartindent = true
opt.undofile = true             -- 关掉文件再打开还能撤销
opt.undodir = vim.fn.stdpath("state") .. "/undo"
opt.swapfile = false
opt.backup = false
opt.updatetime = 300            -- gitsigns / 诊断更快刷新
opt.timeoutlen = 400
opt.ttimeoutlen = 10          -- Alt 组合键（如 Alt+B）立即生效，不用等
opt.completeopt = "menuone,noselect"
opt.shortmess:append("c")
opt.splitright = true
opt.splitbelow = true
opt.laststatus = 3              -- 全局状态栏
opt.showmode = false
opt.fillchars = { eob = " ", fold = " ", diff = "╱" }

-- 复制到系统剪贴板：SSH 环境通常没有 provider，交给终端自己复制
if vim.fn.executable("xclip") == 1 or vim.fn.executable("wl-copy") == 1 then
  opt.clipboard = "unnamedplus"
end
