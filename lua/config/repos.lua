-- 多仓库工作区：在一个"装着很多仓库的目录"里开 nvim 时，快速切到某个仓库
local M = {}

local SKIP = { node_modules = true, vendor = true, __pycache__ = true, [".venv"] = true, venv = true, dist = true, build = true }

--- 扫描 root 下面（最多 3 层）所有包含 .git 的目录
function M.list(root, maxdepth)
  root = root or M._root or vim.fn.getcwd()
  maxdepth = maxdepth or 3
  local repos = {}

  local function scan(dir, depth)
    if depth > maxdepth then return end
    local ok, entries = pcall(vim.fn.readdir, dir)
    if not ok then return end
    for _, name in ipairs(entries) do
      if name:sub(1, 1) ~= "." and not SKIP[name] then
        local p = dir .. "/" .. name
        if vim.fn.isdirectory(p .. "/.git") == 1 then
          table.insert(repos, p)
        elseif vim.fn.isdirectory(p) == 1 then
          scan(p, depth + 1)
        end
      end
    end
  end

  if vim.fn.isdirectory(root .. "/.git") == 1 then
    table.insert(repos, root)
  end
  scan(root, 1)
  table.sort(repos)
  return repos
end


--- 从某个目录往上找最近的仓库根
local function nearest_repo(dir)
  local cur = vim.fn.fnamemodify(dir, ":p"):gsub("/$", "")
  for _ = 1, 6 do
    if vim.fn.isdirectory(cur .. "/.git") == 1 then return cur end
    local parent = vim.fn.fnamemodify(cur, ":h")
    if parent == cur then break end
    cur = parent
  end
  return nil
end

--- 汇总所有能找到的仓库：
---   1. 启动 nvim 时的工作区根（不管当前切到哪）
---   2. 当前仓库的兄弟仓库（在仓库里启动 nvim 的情况）
function M.all()
  local seen, out = {}, {}
  local function add(list)
    for _, p in ipairs(list) do
      if not seen[p] then
        seen[p] = true
        out[#out + 1] = p
      end
    end
  end

  add(M.list(M._root, 3))

  local cur_repo = nearest_repo(vim.fn.getcwd())
  if cur_repo then
    add(M.list(vim.fn.fnamemodify(cur_repo, ":h"), 1))
  end

  if #out == 0 then add({ vim.fn.getcwd() }) end
  table.sort(out)
  return out
end

--- 真正执行切换（不记历史）
local function do_switch(path)
  path = vim.fn.fnamemodify(path, ":p"):gsub("/$", "")
  vim.cmd("cd " .. vim.fn.fnameescape(path))
  local ok, api = pcall(require, "nvim-tree.api")
  if ok then
    pcall(api.tree.change_root, path)
    pcall(api.tree.open)
  end
  pcall(function() require("gitsigns").refresh() end)
  vim.notify("当前目录：" .. path, vim.log.levels.INFO, { title = "Git" })
end
M._do_switch = do_switch

--- 切换历史（用于返回上一个）
M.history = {}

--- 切到某个仓库：改 cwd、换目录树根、刷新 git 标记
function M.switch(path)
  local cur = vim.fn.getcwd()
  path = vim.fn.fnamemodify(path, ":p"):gsub("/$", "")
  if cur ~= path then
    local top = M.history[#M.history]
    if top ~= cur then table.insert(M.history, cur) end
  end
  do_switch(path)
end

--- 回到上一个仓库 / 目录
function M.back()
  local prev = table.remove(M.history)
  if not prev then
    vim.notify("没有上一个仓库了", vim.log.levels.WARN, { title = "Git" })
    return
  end
  do_switch(prev)
end

--- 回到最初打开 nvim 的目录（工作区根）
function M.root()
  return M._root or vim.fn.getcwd()
end

--- 用 telescope 弹选择器；返回 false 表示没装上
local function telescope_pick(items, title, on_select)
  local ok, pickers = pcall(require, "telescope.pickers")
  if not ok then return false end
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  pickers.new({}, {
    prompt_title = title,
    finder = finders.new_table({
      results = items,
      entry_maker = function(item)
        return {
          value = item,
          display = item.label,
          ordinal = item.label,
          path = item.file or item.path,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    previewer = conf.file_previewer({}),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local sel = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if sel then on_select(sel.value) end
      end)
      return true
    end,
  }):find()
  return true
end

function M.pick()
  M._root = M._root or vim.fn.getcwd()
  local repos = M.all()
  if #repos == 0 then
    vim.notify("当前目录下面没找到 git 仓库", vim.log.levels.WARN)
    return
  end
  local cwd = vim.fn.getcwd()
  local items = {}
  local prev = M.history[#M.history]
  if prev then
    table.insert(items, { label = "← 返回上一个：" .. vim.fn.fnamemodify(prev, ":~"), path = prev, file = prev, back = true })
  end
  if M._root ~= cwd and M._root ~= prev then
    table.insert(items, { label = "⌂ 工作区根：" .. vim.fn.fnamemodify(M._root, ":~"), path = M._root, file = M._root })
  end
  for _, p in ipairs(repos) do
    local label = p == cwd and (vim.fn.fnamemodify(p, ":t") .. "（当前）") or vim.fn.fnamemodify(p, ":.")
    table.insert(items, { label = label, path = p, file = p })
  end
  local on_select = function(item)
    if item.back then M.back() else M.switch(item.path) end
  end
  if telescope_pick(items, ("选择仓库（共 %d 个）"):format(#items), on_select) then
    return
  end
  vim.ui.select(items, {
    prompt = ("选择仓库（共 %d 个）"):format(#items),
    format_item = function(item) return item.label end,
  }, function(choice)
    if choice then on_select(choice) end
  end)
end


--- 读某个仓库的改动列表（用 -z，避免路径被转义/加引号）
--- @return table[] { xy = " M", path = "a/b.go" }
function M.status(repo)
  local cmd = {
    "git", "-C", repo,
    "-c", "core.quotepath=false",
    "--no-pager", "status", "--porcelain=v1", "-z", "--untracked-files=all",
  }
  local ok, res = pcall(function() return vim.system(cmd):wait() end)
  if not ok or not res or res.code ~= 0 then return {} end
  local raw = res.stdout or ""
  local items, i = {}, 1
  local records = {}
  for part in raw:gmatch("([^%z]*)%z") do records[#records + 1] = part end
  while i <= #records do
    local rec = records[i]
    if rec == "" then break end
    local xy = rec:sub(1, 2)
    local path = rec:sub(4)
    if xy:sub(1, 1) == "R" or xy:sub(1, 1) == "C" then
      i = i + 1 -- 跳过 rename/copy 的原始路径
    end
    if path ~= "" and xy ~= "!!" then
      items[#items + 1] = { xy = xy, path = path }
    end
    i = i + 1
  end
  return items
end

--- 跨所有仓库列出改动文件（VSCode 多根工作区那种视角）
function M.changed_all()
  local repos = M.all()
  if #repos == 0 then repos = { vim.fn.getcwd() } end
  local items = {}
  for _, repo in ipairs(repos) do
    local repo_name = vim.fn.fnamemodify(repo, ":t")
    for _, it in ipairs(M.status(repo)) do
      items[#items + 1] = {
        status = it.xy,
        file = repo .. "/" .. it.path,
        label = ("%-2s %-14s %s"):format(it.xy, repo_name, it.path),
      }
    end
  end
  if #items == 0 then
    vim.notify("这些仓库都没有未提交改动", vim.log.levels.INFO, { title = "Git" })
    return
  end
  table.sort(items, function(a, b) return a.label < b.label end)
  local open_item = function(item)
    local root = M.repo_root(vim.fn.fnamemodify(item.file, ":h"))
    if root ~= vim.fn.getcwd() then vim.cmd("cd " .. vim.fn.fnameescape(root)) end
    vim.cmd("edit " .. vim.fn.fnameescape(item.file))
  end
  if telescope_pick(items, ("跨仓库改动：%d 个文件 / %d 个仓库"):format(#items, #repos), open_item) then
    return
  end
  vim.ui.select(items, {
    prompt = ("跨仓库改动：%d 个文件"):format(#items),
    format_item = function(i) return i.label end,
  }, function(choice) if choice then open_item(choice) end end)
end

--- 找某个目录所属的仓库根
function M.repo_root(dir)
  for _, repo in ipairs(M.all()) do
    if dir == repo or vim.startswith(dir .. "/", repo .. "/") then return repo end
  end
  return dir
end

M._root = M._root or vim.fn.getcwd()

vim.api.nvim_create_user_command("RepoChanges", M.changed_all, { desc = "跨仓库改动列表" })
vim.api.nvim_create_user_command("RepoPick", M.pick, { desc = "切换 git 仓库" })

return M
