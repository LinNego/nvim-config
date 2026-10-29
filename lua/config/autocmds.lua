-- 自动行为：缩进、保存时格式化、诊断样式等

-- Go 用 tab（gofmt 要求），Python 用 4 空格
vim.api.nvim_create_autocmd("FileType", {
  pattern = "go",
  callback = function()
    vim.opt_local.expandtab = false
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
  end,
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "python", "pyi" },
  callback = function()
    vim.opt_local.expandtab = true
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
  end,
})

-- 保存时自动格式化（Go / Python），<leader>fa 可临时关掉
vim.g.autoformat = true
vim.keymap.set("n", "<leader>fa", function()
  vim.g.autoformat = not vim.g.autoformat
  vim.notify("保存自动格式化：" .. (vim.g.autoformat and "开" or "关"))
end, { desc = "切换保存时格式化" })

vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function(args)
    if not vim.g.autoformat then return end
    local ft = vim.bo[args.buf].filetype
    if ft ~= "go" and ft ~= "python" then return end
    pcall(vim.lsp.buf.format, {
      bufnr = args.buf,
      async = false,
      timeout_ms = 4000,
      filter = function(client)
        return client.name == "ruff" or client.name == "gopls"
      end,
    })
  end,
})

-- 复制时短暂高亮
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    local on_yank = (vim.hl and vim.hl.on_yank) or vim.highlight.on_yank
    on_yank({ higroup = "IncSearch", timeout = 150 })
  end,
})

-- 重新打开文件时回到上次光标位置
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local lcount = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- 终端窗口大小变化时分屏自适应
vim.api.nvim_create_autocmd("VimResized", {
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
})

-- 诊断信息的显示样式
vim.diagnostic.config({
  virtual_text = { spacing = 2, prefix = "●" },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = { border = "rounded", source = true, header = "" },
})

-- 目录里没有 .git 但子目录有一堆仓库时，提醒一下（否则 git 相关按键全部哑火）
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.schedule(function()
      local cwd = vim.fn.getcwd()
      if vim.fn.isdirectory(cwd .. "/.git") == 1 then return end
      local repos = {}
      for _, name in ipairs(vim.fn.readdir(cwd)) do
        if name:sub(1, 1) ~= "." and vim.fn.isdirectory(("%s/%s/.git"):format(cwd, name)) == 1 then
          repos[#repos + 1] = name
        end
      end
      if #repos > 0 then
        vim.notify(
          ("⚠ 当前目录不是 git 仓库（下面有 %d 个仓库）：按 <leader>gr 切换"):format(#repos),
          vim.log.levels.WARN,
          { title = "Git" }
        )
      end
    end)
  end,
})


-- diff 窗口里 q = 关闭对比（默认 q 是录宏，容易误触退出）
local function close_diff_view()
  local cur = vim.api.nvim_get_current_win()
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if w ~= cur and vim.wo[w].diff then
      pcall(vim.api.nvim_win_close, w, true)
    end
  end
  pcall(function() vim.wo[cur].diff = false end)
  pcall(vim.cmd, "diffoff!")
end

vim.api.nvim_create_autocmd("OptionSet", {
  pattern = "diff",
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    if vim.wo.diff then
      vim.keymap.set("n", "q", close_diff_view, { buffer = buf, desc = "关闭对比", silent = true })
      vim.keymap.set("n", "<Esc>", close_diff_view, { buffer = buf, desc = "关闭对比", silent = true })
    else
      pcall(vim.keymap.del, "n", "q", { buffer = buf })
    end
  end,
})

-- 当前行高亮：主题自带的值太淡（#222222 vs 背景 #1f1f1f，几乎看不出），
-- 这里按当前主题的背景色自动提亮，并把行号标成醒目色
local function tune_cursorline()
  local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
  local bg = normal.bg
  if type(bg) ~= "number" then return end
  local r = math.floor(bg / 65536) % 256
  local g = math.floor(bg / 256) % 256
  local b = bg % 256
  local function up(v) return math.min(255, v + 16) end
  vim.api.nvim_set_hl(0, "CursorLine", {
    bg = string.format("#%02x%02x%02x", up(r), up(g), up(b)),
  })
  vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#d7ba7d", bold = true })
end

tune_cursorline()
vim.api.nvim_create_autocmd("ColorScheme", { callback = tune_cursorline })
