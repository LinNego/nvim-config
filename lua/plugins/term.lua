-- 浮动终端：编译 / 运行 / 测试都在小窗口里跑，跑完不会自己消失
local M = {}

local function project_root()
  local markers = { "go.mod", "pyproject.toml", "setup.py", "requirements.txt", "Makefile", ".git" }
  return vim.fs.root(0, markers) or vim.fn.getcwd()
end

local last_term = nil

local function open_float(cmd, dir, title)
  local Terminal = require("toggleterm.terminal").Terminal
  if last_term and last_term.bufnr and vim.api.nvim_buf_is_valid(last_term.bufnr) then
    pcall(function() last_term:close() end)
    pcall(vim.api.nvim_buf_delete, last_term.bufnr, { force = true })
  end
  local term = Terminal:new({
    cmd = cmd,
    dir = dir,
    direction = "float",
    close_on_exit = false,
    auto_scroll = true,
    count = 200,
    on_open = function(t)
      vim.cmd("startinsert!")
      pcall(function()
        vim.api.nvim_buf_set_name(t.bufnr, " terminal: " .. title .. " ")
      end)
    end,
  })
  last_term = term
  term:toggle()
end

local function python_bin(root)
  if vim.fn.executable(root .. "/.venv/bin/python") == 1 then
    return root .. "/.venv/bin/python"
  end
  if vim.fn.executable("python3.12") == 1 then
    return "python3.12"
  end
  return "python3"
end

--- 开/关最近那个浮窗终端（终端模式下也能直接用）
function M.toggle()
  local t = last_term
  if t and t.bufnr and vim.api.nvim_buf_is_valid(t.bufnr) then
    if t:is_open() then
      pcall(function() t:close() end)
    else
      t:open()
    end
    return
  end
  local Terminal = require("toggleterm.terminal").Terminal
  local term = Terminal:new({ direction = "float", count = 200, close_on_exit = false })
  last_term = term
  term:toggle()
end

function M.build()
  local root = project_root()
  local cmd
  if vim.fn.filereadable(root .. "/Makefile") == 1 then
    cmd = "make"
  elseif vim.fn.filereadable(root .. "/go.mod") == 1 then
    cmd = "go build ./..."
  else
    cmd = python_bin(root) .. " -m compileall -q ."
  end
  open_float(cmd, root, cmd)
end

function M.run()
  local root = project_root()
  local cmd
  if vim.fn.filereadable(root .. "/go.mod") == 1 then
    cmd = "go run ."
  else
    cmd = python_bin(root) .. " " .. vim.fn.expand("%:p")
  end
  open_float(cmd, root, cmd)
end

function M.test()
  local root = project_root()
  local cmd
  if vim.fn.filereadable(root .. "/go.mod") == 1 then
    cmd = "go test ./..."
  else
    cmd = python_bin(root) .. " -m pytest -q"
  end
  open_float(cmd, root, cmd)
end

function M.custom()
  vim.ui.input({ prompt = "在当前项目根目录执行: ", default = "" }, function(input)
    if not input or input == "" then return end
    open_float(input, project_root(), input)
  end)
end

return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = { "ToggleTerm", "ToggleTermToggleAll" },
    keys = {
      { "<C-\\>", "<cmd>ToggleTerm<cr>", desc = "开关浮动终端" },
      { "<F5>", function() M.build() end, desc = "编译（浮动窗口）" },
      { "<F6>", function() M.run() end, desc = "运行（浮动窗口）" },
      { "<F7>", function() M.test() end, desc = "测试（浮动窗口）" },
      { "<leader>rb", function() M.build() end, desc = "编译" },
      { "<leader>rr", function() M.run() end, desc = "运行" },
      { "<leader>rt", function() M.test() end, desc = "测试" },
      { "<leader>rc", function() M.custom() end, desc = "自定义命令" },
      { "<leader>tt", "<cmd>ToggleTerm<cr>", desc = "浮动终端" },
    },
    config = function()
      -- 终端模式里必须先退出终端态，才能执行 :ToggleTerm
      vim.keymap.set({ "n", "t" }, "<M-t>", function() M.toggle() end, { desc = "浮动终端 开/关" })
      require("toggleterm").setup({
        size = 20,
        open_mapping = nil,          -- 用上面的 keys 手动绑定
        hide_numbers = true,
        shade_filetypes = {},
        shade_terminals = false,
        start_in_insert = true,
        insert_mappings = true,
        persist_size = true,
        persist_mode = true,
        direction = "float",
        close_on_exit = false,
        shell = vim.o.shell,
        float_opts = {
          border = "rounded",
          winblend = 0,
          width = function() return math.floor(vim.o.columns * 0.78) end,
          height = function() return math.floor(vim.o.lines * 0.5) end,
        },
      })
    end,
  },
}
