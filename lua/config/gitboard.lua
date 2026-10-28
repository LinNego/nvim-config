-- Git 总览面板（类 VSCode 源代码管理）：跨仓库列出所有改动
-- <leader>gs 打开；回车 打开文件 · d 看 diff · s 暂存 · u 取消暂存 · R 刷新 · q 关闭
local M = {}

local ns = vim.api.nvim_create_namespace("gitboard")

local HL = {
  ["?"] = "DiagnosticOk",
  ["M"] = "DiagnosticWarn",
  ["S"] = "DiagnosticInfo",
  ["D"] = "DiagnosticError",
  ["U"] = "DiagnosticError",
  ["R"] = "DiagnosticHint",
}

--- 把 porcelain 的 XY 归一成一个好认的字母
local function label(xy)
  local x, y = xy:sub(1, 1), xy:sub(2, 2)
  if xy == "??" then return "?" end
  if x == "U" or y == "U" or xy == "AA" or xy == "DD" then return "U" end
  if x == "D" or y == "D" then return "D" end
  if x == "R" or y == "R" then return "R" end
  if x ~= " " then return "S" end -- 已暂存
  if y == "M" then return "M" end
  if y == "A" then return "S" end
  return (xy:gsub(" ", ""))
end

local function collect()
  local repos = require("config.repos")
  local list = repos.list()
  if #list == 0 then list = { vim.fn.getcwd() } end
  local groups, total = {}, 0
  for _, repo in ipairs(list) do
    local items = {}
    for _, it in ipairs(repos.status(repo)) do
      items[#items + 1] = { status = label(it.xy), raw = it.xy, path = it.path }
    end
    if #items > 0 then
      table.sort(items, function(a, b)
        if a.status ~= b.status then return a.status < b.status end
        return a.path < b.path
      end)
      groups[#groups + 1] = { repo = repo, name = vim.fn.fnamemodify(repo, ":t"), items = items }
      total = total + #items
    end
  end
  return groups, total, #list
end

local function refresh(buf, win)
  local groups, total, repo_count = collect()
  local lines, targets = {}, {}
  if total == 0 then
    lines = { "", "  所有仓库都干净，没有未提交改动", "", "  R 刷新   q 关闭" }
  else
    for _, g in ipairs(groups) do
      lines[#lines + 1] = (" %s  (%d)"):format(g.name, #g.items)
      targets[#lines] = { kind = "header", repo = g.repo }
      for _, it in ipairs(g.items) do
        lines[#lines + 1] = ("  %s  %s"):format(it.status, it.path)
        targets[#lines] = { kind = "file", repo = g.repo, path = it.path, status = it.status }
      end
      lines[#lines + 1] = ""
    end
    lines[#lines + 1] = (" 合计 %d 个文件 / %d 个仓库"):format(total, repo_count)
    lines[#lines + 1] = " 回车 左右对比 · o 只看文件 · s 暂存 · u 取消暂存 · R 刷新 · q 关闭"
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  for i, t in ipairs(targets) do
    if t.kind == "header" then
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, {
        end_row = i - 1, end_col = #lines[i], hl_group = "Title",
      })
    elseif t.kind == "file" then
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 2, {
        end_col = 3, hl_group = HL[t.status] or "Normal",
      })
    end
  end

  vim.b[buf].gitboard_targets = targets
  if win and vim.api.nvim_win_is_valid(win) then
    local cur = vim.api.nvim_win_get_cursor(win)[1]
    vim.api.nvim_win_set_cursor(win, { math.min(cur, math.max(1, #lines)), 0 })
  end
end

local function target_at(buf)
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local targets = vim.b[buf].gitboard_targets or {}
  return targets[lnum]
end

local function editor_win(panel)
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    local ft = vim.bo[vim.api.nvim_win_get_buf(w)].filetype
    if w ~= panel and ft ~= "gitboard" and ft ~= "NvimTree" and ft ~= "bufpanel" then
      return w
    end
  end
  return vim.api.nvim_get_current_win()
end

--- 清掉对比时残留的空窗口（[No Name] 之类）
local function cleanup_empty_windows()
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if not vim.wo[w].diff then
      local b = vim.api.nvim_win_get_buf(w)
      local ft = vim.bo[b].filetype
      if vim.bo[b].buftype == ""
        and vim.api.nvim_buf_get_name(b) == ""
        and not vim.bo[b].modified
        and ft ~= "NvimTree" and ft ~= "gitboard" and ft ~= "bufpanel"
      then
        pcall(vim.api.nvim_win_close, w, true)
      end
    end
  end
end

local function open_file(t, panel, focus)
  local target = editor_win(panel)
  local file = t.repo .. "/" .. t.path
  vim.api.nvim_win_call(target, function()
    vim.cmd("cd " .. vim.fn.fnameescape(t.repo))
    vim.cmd("edit " .. vim.fn.fnameescape(file))
  end)
  if focus then vim.api.nvim_set_current_win(target) end
  return target, file
end

--- 打开文件并进入左右对比（新文件没有历史，直接打开）
local function open_diff(t, panel)
  open_file(t, panel, true)
  if t.status == "?" then
    vim.notify("这是新文件，没有可对比的历史版本", vim.log.levels.INFO, { title = "Git" })
    return
  end
  if vim.api.nvim_win_is_valid(panel) then pcall(vim.api.nvim_win_close, panel, true) end
  vim.cmd("vertical Gdiffsplit")
  cleanup_empty_windows()
end

local function git(repo, ...)
  local args = { "git", "-C", repo, "-c", "core.quotepath=false", "--no-pager" }
  for _, a in ipairs({ ... }) do table.insert(args, a) end
  return vim.fn.systemlist(args)
end

local function board_win()
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "gitboard" then return w end
  end
end

--- 在"目录树和编辑区之间"开一个面板；不打扰目录树
local function open_split()
  -- 先切到编辑窗口（不是树、也不是面板）
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    local ft = vim.bo[vim.api.nvim_win_get_buf(w)].filetype
    if ft ~= "NvimTree" and ft ~= "gitboard" then
      vim.api.nvim_set_current_win(w)
      break
    end
  end
  vim.cmd("leftabove 64vsplit")
  return vim.api.nvim_get_current_win()
end

--- 跳到下 / 上一个文件行（跳过仓库标题和空行）
local function jump_file(buf, dir)
  local targets = vim.b[buf].gitboard_targets or {}
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local i = lnum + dir
  while i >= 1 and i <= #targets do
    if targets[i] and targets[i].kind == "file" then
      vim.api.nvim_win_set_cursor(0, { i, 0 })
      return
    end
    i = i + dir
  end
  if dir > 0 then
    vim.notify("已经是最后一个文件了", vim.log.levels.INFO)
  else
    vim.notify("已经是第一个文件了", vim.log.levels.INFO)
  end
end

function M.open()
  local win = open_split()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "gitboard"
  vim.api.nvim_buf_set_name(buf, "git-board")
  vim.api.nvim_win_set_buf(win, buf)
  vim.wo[win].winfixwidth = true
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].foldcolumn = "0"
  vim.wo[win].wrap = false
  vim.wo[win].cursorline = true

  local function close()
    if not vim.api.nvim_win_is_valid(win) then return end
    if #vim.api.nvim_list_wins() <= 1 then
      vim.notify("这是最后一个窗口，用 :q 退出", vim.log.levels.WARN)
      return
    end
    pcall(vim.api.nvim_win_close, win, true)
  end

  vim.keymap.set("n", "q", close, { buffer = buf, desc = "关闭", silent = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, desc = "关闭", silent = true })
  vim.keymap.set("n", "R", function() refresh(buf, win) end, { buffer = buf, desc = "刷新", silent = true })
  vim.keymap.set("n", "]f", function() jump_file(buf, 1) end, { buffer = buf, desc = "下一个文件", silent = true })
  vim.keymap.set("n", "[f", function() jump_file(buf, -1) end, { buffer = buf, desc = "上一个文件", silent = true })
  vim.keymap.set("n", "<Tab>", function() jump_file(buf, 1) end, { buffer = buf, desc = "下一个文件", silent = true })
  vim.keymap.set("n", "<S-Tab>", function() jump_file(buf, -1) end, { buffer = buf, desc = "上一个文件", silent = true })
  -- 回车 = 直接左右对比（像 VSCode 点开改动文件）
  vim.keymap.set("n", "<CR>", function()
    local t = target_at(buf)
    if t and t.kind == "file" then open_diff(t, win) end
  end, { buffer = buf, desc = "左右对比", silent = true })
  -- o = 只看文件内容，不对比
  vim.keymap.set("n", "o", function()
    local t = target_at(buf)
    if t and t.kind == "file" then open_file(t, win, true) end
  end, { buffer = buf, desc = "打开文件", silent = true })
  vim.keymap.set("n", "d", function()
    local t = target_at(buf)
    if t and t.kind == "file" then open_diff(t, win) end
  end, { buffer = buf, desc = "左右对比", silent = true })
  vim.keymap.set("n", "s", function()
    local t = target_at(buf)
    if t and t.kind == "file" then
      git(t.repo, "add", "--", t.path)
      refresh(buf, win)
      vim.notify("已暂存 " .. t.path, vim.log.levels.INFO, { title = "Git" })
    end
  end, { buffer = buf, desc = "暂存文件", silent = true })
  vim.keymap.set("n", "u", function()
    local t = target_at(buf)
    if t and t.kind == "file" then
      git(t.repo, "reset", "--", t.path)
      refresh(buf, win)
      vim.notify("已取消暂存 " .. t.path, vim.log.levels.INFO, { title = "Git" })
    end
  end, { buffer = buf, desc = "取消暂存", silent = true })

  refresh(buf, win)
end

--- <leader>gs：开/关（再按一次关掉）
function M.toggle()
  local w = board_win()
  if w then
    pcall(vim.api.nvim_win_close, w, true)
    return
  end
  M.open()
end

vim.api.nvim_create_user_command("GitBoard", M.toggle, { desc = "Git 总览面板（所有仓库）开/关" })

return M
