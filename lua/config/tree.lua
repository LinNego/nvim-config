-- 目录树常驻逻辑：
--   1. 树里按 q / <C-w>c / <C-w>o 不会关掉它
--   2. 就算被 :close、插件或误操作关掉，也会自动拉回来
--   3. 只有 <C-b> 才算"有意隐藏"
local M = {}

local function tree_wins()
  local out = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "NvimTree" then
      out[#out + 1] = win
    end
  end
  return out
end

--- 确保目录树可见（除非用户按过 <C-b> 隐藏）
function M.ensure_open()
  if vim.g.tree_hidden == 1 then return end
  if #tree_wins() > 0 then return end
  local ok, api = pcall(require, "nvim-tree.api")
  if not ok then return end
  local prev = vim.api.nvim_get_current_win()
  pcall(api.tree.open, { focus = false })
  -- 树有时会抢走焦点，把光标还给原来的编辑窗口
  vim.schedule(function()
    if not vim.api.nvim_win_is_valid(prev) then return end
    local cur = vim.api.nvim_get_current_win()
    local cb = vim.api.nvim_win_get_buf(cur)
    if vim.bo[cb].filetype == "NvimTree" and cur ~= prev then
      vim.api.nvim_set_current_win(prev)
    end
  end)
end

--- 显示 / 隐藏目录树（唯一"合法"的关闭方式）
function M.toggle()
  local ok, api = pcall(require, "nvim-tree.api")
  if not ok then
    vim.notify("nvim-tree 还没加载完，稍等一下再按 <C-b>", vim.log.levels.WARN)
    return
  end
  if #tree_wins() > 0 then
    vim.g.tree_hidden = 1
    pcall(api.tree.close)
  else
    vim.g.tree_hidden = 0
    vim.g.tree_enabled = 1
    pcall(api.tree.open)
  end
end

--- 聚焦到目录树
function M.focus()
  vim.g.tree_hidden = 0
  vim.g.tree_enabled = 1
  local wins = tree_wins()
  if #wins > 0 then
    vim.api.nvim_set_current_win(wins[1])
  else
    pcall(function() require("nvim-tree.api").tree.open({ focus = true }) end)
  end
end

-- 树里的按键：屏蔽掉所有"会关窗口"的快捷键
vim.api.nvim_create_autocmd("FileType", {
  pattern = "NvimTree",
  callback = function(args)
    local o = { buffer = args.buf, silent = true, nowait = true }
    local hint = "<cmd>echo '目录树常驻，不会退出。按 Alt+B 可整栏隐藏'<cr>"
    for _, key in ipairs({ "q", "<C-w>c", "<C-w>o", "<C-w>q", "<C-w>z" }) do
      vim.keymap.set("n", key, hint, o)
    end
  end,
})

-- 被关掉就自动拉回来（退出 Neovim、或主动隐藏时除外）
local function is_exiting()
  local e = vim.v.exiting
  return e ~= vim.NIL and e ~= 0
end

vim.api.nvim_create_autocmd("WinClosed", {
  callback = function()
    if is_exiting() or vim.g.tree_hidden == 1 or vim.g.tree_enabled ~= 1 then return end
    vim.schedule(function()
      if is_exiting() or vim.g.tree_hidden == 1 then return end
      M.ensure_open()
    end)
  end,
})

-- 退出时不要再把树"拉回来"
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function() vim.g.tree_hidden = 1 end,
})

-- 启动时自动把树打开（VSCode 的感觉）
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.schedule(function()
      if vim.bo.filetype == "gitcommit" or vim.bo.filetype == "gitrebase" then return end
      vim.g.tree_enabled = 1
      vim.g.tree_hidden = 0
      M.ensure_open()
    end)
  end,
})

return M
