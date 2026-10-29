-- 通用的小帮助浮窗（给各个面板用）
local M = {}

--- @param title string
--- @param lines string[]
function M.float(title, lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "help"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false

  local width = math.min(76, vim.o.columns - 6)
  local height = math.min(#lines + 1, vim.o.lines - 6)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " " .. title .. " · q 关闭 ",
    title_pos = "center",
  })
  local close = function() pcall(vim.api.nvim_win_close, win, true) end
  vim.keymap.set("n", "q", close, { buffer = buf, desc = "关闭帮助" })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, desc = "关闭帮助" })
  return win
end

return M
