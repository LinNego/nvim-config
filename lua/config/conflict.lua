-- 冲突处理：直接解析 <<<<<<< / ======= / >>>>>>> 标记
-- 键位：co 用我的 / ct 用对方的 / cb 两边都要 / c0 两边都不要
--       ]x 下一个冲突 / [x 上一个冲突
local M = {}

local ns = vim.api.nvim_create_namespace("user_conflict")

local MARK = {
  ours = "^<<<<<<<",
  base = "^|||||||",
  sep = "^=======[ \t]*$",
  theirs = "^>>>>>>>",
}

--- 找出缓冲区里所有冲突块（1 基行号）
function M.detect(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local out = {}
  local i = 1
  while i <= #lines do
    if lines[i]:find(MARK.ours) then
      local c = { start = i, base = nil, sep = nil, finish = nil }
      local j = i + 1
      while j <= #lines do
        if not c.sep and not c.base and lines[j]:find(MARK.base) then
          c.base = j
        elseif not c.sep and lines[j]:find(MARK.sep) then
          c.sep = j
        elseif lines[j]:find(MARK.theirs) then
          c.finish = j
          break
        end
        j = j + 1
      end
      if c.sep and c.finish then
        table.insert(out, c)
        i = c.finish
      end
    end
    i = i + 1
  end
  return out, lines
end

function M.count(buf)
  return #(M.detect(buf or 0))
end

local function content(lines, from, to, out)
  out = out or {}
  if from > to then return out end
  for i = from, to do
    out[#out + 1] = lines[i]
  end
  return out
end

--- 光标所在的冲突块；光标不在冲突里就取它后面第一个
local function current_conflict(buf)
  local conflicts = M.detect(buf)
  if #conflicts == 0 then return nil end
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  for _, c in ipairs(conflicts) do
    if lnum >= c.start and lnum <= c.finish then return c end
  end
  for _, c in ipairs(conflicts) do
    if c.start >= lnum then return c end
  end
  return conflicts[1]
end

--- side: "ours" | "theirs" | "both" | "none"
function M.choose(side)
  local buf = vim.api.nvim_get_current_buf()
  local conflicts, lines = M.detect(buf)
  if #conflicts == 0 then
    vim.notify("当前文件没有冲突标记", vim.log.levels.INFO)
    return
  end
  local c = current_conflict(buf)
  if not c then return end

  local ours_end = (c.base or c.sep) - 1
  local mine = content(lines, c.start + 1, ours_end)
  local theirs = content(lines, c.sep + 1, c.finish - 1)

  local repl
  if side == "ours" then
    repl = mine
  elseif side == "theirs" then
    repl = theirs
  elseif side == "both" then
    repl = vim.list_extend(vim.deepcopy(mine), theirs)
  else
    repl = {}
  end

  vim.api.nvim_buf_set_lines(buf, c.start - 1, c.finish, false, repl)
  local target = math.min(c.start, vim.api.nvim_buf_line_count(buf))
  vim.api.nvim_win_set_cursor(0, { target, 0 })
  M.refresh(buf)
end

function M.next()
  local buf = vim.api.nvim_get_current_buf()
  local conflicts = M.detect(buf)
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  for _, c in ipairs(conflicts) do
    if c.start > lnum then
      vim.api.nvim_win_set_cursor(0, { c.start, 0 })
      return
    end
  end
  if #conflicts > 0 then
    vim.api.nvim_win_set_cursor(0, { conflicts[1].start, 0 })
  end
end

function M.prev()
  local buf = vim.api.nvim_get_current_buf()
  local conflicts = M.detect(buf)
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  for i = #conflicts, 1, -1 do
    if conflicts[i].start < lnum then
      vim.api.nvim_win_set_cursor(0, { conflicts[i].start, 0 })
      return
    end
  end
  if #conflicts > 0 then
    vim.api.nvim_win_set_cursor(0, { conflicts[#conflicts].start, 0 })
  end
end

--- 上色：我的部分 / 对方部分 / 三行标记
function M.refresh(buf)
  buf = (buf and buf ~= 0) and buf or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) then return end
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local conflicts = M.detect(buf)
  if #conflicts == 0 then return end
  for _, c in ipairs(conflicts) do
    local ours_end = (c.base or c.sep) - 1
    if c.start < ours_end then
      vim.api.nvim_buf_set_extmark(buf, ns, c.start - 1, 0, {
        end_row = ours_end - 1,
        line_hl_group = "DiffText",
      })
    end
    if c.sep + 1 < c.finish then
      vim.api.nvim_buf_set_extmark(buf, ns, c.sep, 0, {
        end_row = c.finish - 2,
        line_hl_group = "DiffAdd",
      })
    end
    for _, line in ipairs({ c.start, c.sep, c.finish }) do
      vim.api.nvim_buf_set_extmark(buf, ns, line - 1, 0, {
        end_row = line - 1,
        line_hl_group = "WarningMsg",
      })
    end
  end
end

local map = vim.keymap.set

local function guarded(side)
  return function()
    M.choose(side)
  end
end

for lhs, side in pairs({ co = "ours", ct = "theirs", cb = "both", c0 = "none" }) do
  map({ "n", "v" }, lhs, guarded(side), { desc = "冲突：" .. side, silent = true })
end
map("n", "]x", M.next, { desc = "下一个冲突", silent = true })
map("n", "[x", M.prev, { desc = "上一个冲突", silent = true })

-- 打开/切回缓冲区时刷新高亮
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "TextChanged", "BufWritePost" }, {
  callback = function(args)
    local ok = pcall(M.refresh, args.buf)
    if not ok then return end
  end,
})

return M
