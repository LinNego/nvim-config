-- 底部"打开的文件"面板：列出所有已打开的文件，键盘切换
-- <leader>bb 开/关；j/k 移动，回车切换，x 关闭文件，q 关闭面板
local M = {}

local ns = vim.api.nvim_create_namespace("bufpanel")

local function listed_buffers()
  local out = {}
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[b].buflisted
      and vim.bo[b].buftype == ""
      and vim.api.nvim_buf_get_name(b) ~= "" then
      out[#out + 1] = b
    end
  end
  return out
end

local function label(b)
  local name = vim.api.nvim_buf_get_name(b)
  local rel = vim.fn.fnamemodify(name, ":.")
  if #rel > 70 then rel = "…" .. rel:sub(-69) end
  local mark = vim.bo[b].modified and " [+]" or ""
  local cur = (b == vim.api.nvim_get_current_buf()) and "▸ " or "  "
  return ("%s%-4d %s%s"):format(cur, vim.fn.bufnr(b), rel, mark)
end

local function refresh(state)
  if not vim.api.nvim_buf_is_valid(state.buf) then return end
  local buffers = listed_buffers()
  state.buffers = buffers
  local lines = {}
  if #buffers == 0 then
    lines = { "  （没有打开的文件）" }
  else
    for _, b in ipairs(buffers) do
      lines[#lines + 1] = label(b)
    end
  end
  vim.bo[state.buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)

  -- 高亮当前文件那一行
  local cur = vim.api.nvim_get_current_buf()
  for i, b in ipairs(buffers) do
    local hl = (b == cur) and "Visual" or (vim.bo[b].modified and "DiagnosticWarn" or nil)
    if hl then
      vim.api.nvim_buf_set_extmark(state.buf, ns, i - 1, 0, {
        end_row = i - 1, end_col = #lines[i], hl_group = hl,
      })
    end
  end
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    local row = math.min(vim.api.nvim_win_get_cursor(state.win)[1], math.max(1, #lines))
    vim.api.nvim_win_set_cursor(state.win, { row, 0 })
    local h = math.max(3, math.min(#lines + 1, 12))
    pcall(vim.api.nvim_win_set_height, state.win, h)
  end
end

local function current_entry(state)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  return state.buffers[row]
end

local function editor_win(state)
  if state.editor and vim.api.nvim_win_is_valid(state.editor) then return state.editor end
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if w ~= state.win then return w end
  end
end

local function open_panel()
  local editor = vim.api.nvim_get_current_win()
  vim.cmd("botright 12split")
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "bufpanel"
  vim.api.nvim_buf_set_name(buf, "buffers")
  vim.api.nvim_win_set_buf(win, buf)
  vim.wo[win].winfixheight = true
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].foldcolumn = "0"
  vim.wo[win].wrap = false
  vim.wo[win].cursorline = true

  local state = { buf = buf, win = win, editor = editor, buffers = {} }
  M._state = state

  local function close()
    if not vim.api.nvim_win_is_valid(win) then M._state = nil; return end
    if #vim.api.nvim_list_wins() <= 1 then
      vim.notify("这是最后一个窗口，用 :q 退出", vim.log.levels.WARN)
      return
    end
    pcall(vim.api.nvim_win_close, win, true)
    M._state = nil
  end

  local function pick()
    local b = current_entry(state)
    if not b or not vim.api.nvim_buf_is_valid(b) then return end
    local target = editor_win(state)
    if target and vim.api.nvim_win_is_valid(target) then
      vim.api.nvim_win_set_buf(target, b)
      vim.api.nvim_set_current_win(target)
    else
      vim.cmd("buffer " .. b)
    end
    refresh(state)
  end

  vim.keymap.set("n", "q", close, { buffer = buf, desc = "关闭面板", silent = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, desc = "关闭面板", silent = true })
  vim.keymap.set("n", "<CR>", pick, { buffer = buf, desc = "切换到该文件", silent = true })
  vim.keymap.set("n", "o", pick, { buffer = buf, desc = "切换到该文件", silent = true })
  vim.keymap.set("n", "x", function()
    local b = current_entry(state)
    if b and vim.api.nvim_buf_is_valid(b) then
      vim.cmd("bdelete! " .. b)
      refresh(state)
    end
  end, { buffer = buf, desc = "关闭该文件", silent = true })
  vim.keymap.set("n", "R", function() refresh(state) end, { buffer = buf, desc = "刷新", silent = true })

  refresh(state)
  return state
end

function M.toggle()
  local st = M._state
  if st and st.win and vim.api.nvim_win_is_valid(st.win) then
    pcall(vim.api.nvim_win_close, st.win, true)
    M._state = nil
    return
  end
  open_panel()
end

-- 缓冲区变化时自动刷新
vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete", "BufEnter", "BufWritePost", "BufModifiedSet" }, {
  callback = function()
    local st = M._state
    if st and st.win and vim.api.nvim_win_is_valid(st.win) then
      vim.schedule(function() refresh(st) end)
    end
  end,
})

vim.api.nvim_create_user_command("BufPanel", M.toggle, { desc = "打开的文件面板 开/关" })

return M
