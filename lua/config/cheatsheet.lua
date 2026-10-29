-- 按键速查：:DevKeys 或 <leader>? 打开，q 关闭
local M = {}

M.groups = {
  { title = "文件 / 缓冲区", keys = {
    { "<leader>w", "保存" },
    { "<leader>q", "关闭当前缓冲区（不退出 nvim）" },
    { "<leader>Q", "退出 nvim" },
    { "<S-h> / <S-l>", "上一个 / 下一个缓冲区" },
    { "<leader>bb", "打开的文件列表（底部面板，回车切换）" },
    { "<C-p>", "按文件名查找" },
    { "<leader>fg", "全文搜索（当前仓库）" },
    { "<leader>fG", "全文搜索（所有仓库 / 全工作区）" },
    { "<leader>fb", "切换已打开的文件" },
    { "<leader>fr", "最近打开的文件" },
    { "<leader>fs", "当前文件里的函数/符号" },
    { "<leader>fd", "所有报错和警告" },
  } },
  { title = "目录树（常驻，q 关不掉）", keys = {
    { "Alt+B", "整栏显示 / 隐藏" },
    { "<leader>e", "把光标移到目录树" },
    { "Enter / l", "打开文件或展开目录" },
    { "h", "收起当前目录" },
    { "a / d / r", "新建 / 删除 / 重命名" },
    { "c / x / p", "复制 / 剪切 / 粘贴" },
    { "y / Y", "复制文件名 / 相对路径" },
    { "s / i", "垂直 / 水平分屏打开" },
    { "H", "显示 / 隐藏点文件" },
    { "R", "刷新" },
    { "S / F", "在这个目录里搜内容 / 找文件" },
  } },
  { title = "Git 查看", keys = {
    { "<leader>gs", "Git 总览面板 开/关（所有仓库）" },
    { "面板内 ]f / [f", "跳到下一个 / 上一个文件" },
    { "面板内 回车", "左右对比这个文件（o 只看文件）" },
    { "面板内 s / u", "暂存 / 取消暂存" },
    { "<leader>gS", "当前仓库的 git 状态（提交用）" },
    { "<leader>gd", "左右对比看所有未提交改动" },
    { "<leader>gD", "与上一个提交对比" },
    { "<leader>gh", "当前文件的提交历史" },
    { "<leader>gH", "整个仓库的提交历史" },
    { "<leader>gc", "关闭 diff 视图" },
    { "<leader>gt", "只看被改动的文件（可搜索，带 diff 预览）" },
    { "<leader>gl", "提交历史（可搜索）" },
    { "<leader>gb", "切换分支" },
    { "<leader>gT", "跨所有仓库看改动（多仓库工作区用）" },
    { "<leader>gr", "切换仓库（改 cwd + 目录树根）" },
    { "<leader>gR", "返回上一个仓库 / 目录" },
    { "]c / [c", "跳到下 / 上一个改动块" },
    { "<leader>hp", "预览当前改动块" },
    { "<leader>hs", "暂存当前改动块" },
    { "<leader>hr", "撤销当前改动块" },
    { "<leader>hS / <leader>hR", "暂存 / 撤销整个文件" },
    { "<leader>hb", "这一行是谁写的" },
    { "<leader>hB", "开关行尾 blame" },
    { "<leader>hd / <leader>hD", "与该文件历史版本对比" },
  } },
  { title = "冲突解决", keys = {
    { "co", "用我的（ours）" },
    { "ct", "用对方的（theirs）" },
    { "cb", "两边都保留" },
    { "c0", "两边都不要" },
    { "]x / [x", "下 / 上一个冲突" },
  } },
  { title = "编译 / 运行（浮窗）", keys = {
    { "F5", "编译（Go: go build ./...）" },
    { "F6", "运行（Go: go run . / Python: 当前文件）" },
    { "F7", "测试（go test ./... / pytest）" },
    { "Alt+T", "浮动终端 开/关（终端里也能按）" },
    { "<C-\\>", "浮动终端（普通模式）" },
    { "<leader>rc", "自己输命令，在项目根目录跑" },
    { "<leader>tt", "浮动终端" },
  } },
  { title = "代码 / LSP", keys = {
    { "gd / gD", "跳转定义 / 声明" },
    { "gi", "跳转实现" },
    { "gr", "查找引用" },
    { "K", "看文档" },
    { "<leader>rn", "重命名符号" },
    { "<leader>ca", "代码操作（自动 import 等）" },
    { "]d / [d", "下 / 上一个报错" },
    { "<leader>cd", "浮窗看当前诊断" },
    { "<leader>cf", "手动格式化" },
    { "<leader>fa", "开关\"保存自动格式化\"" },
    { "<leader>li / <leader>lr", "LSP 信息 / 重启 LSP" },
  } },
  { title = "Markdown", keys = {
    { "<leader>mp", "渲染 开/关（打开 .md 默认已渲染）" },
    { "光标所在行", "临时显示原始 markdown，方便编辑" },
  } },
  { title = "窗口", keys = {
    { "<C-h/j/k/l>", "在各分屏之间移动" },
    { "<leader>sv / <leader>sh", "垂直 / 水平分屏" },
  } },
  { title = "帮助", keys = {
    { "<leader>?", "打开这份速查" },
    { "<leader>ut", "切换主题（vscode / tokyonight）" },
    { "<leader>fk", "搜索所有按键" },
    { "<leader>fh", "搜索 Neovim 帮助文档" },
    { ":checkhealth", "检查插件 / LSP 状态" },
  } },
}

function M.lines()
  local out = {
    "  Neovim 速查表    （<leader> 就是空格键）",
    "",
  }
  for _, g in ipairs(M.groups) do
    table.insert(out, "  ── " .. g.title .. " " .. string.rep("─", math.max(4, 46 - #g.title)))
    for _, k in ipairs(g.keys) do
      table.insert(out, string.format("    %-18s %s", k[1], k[2]))
    end
    table.insert(out, "")
  end
  return out
end

function M.open()
  local lines = M.lines()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "help"
  local width = math.min(86, vim.o.columns - 6)
  local height = math.min(#lines, vim.o.lines - 6)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " 按键速查 · q 关闭 ",
    title_pos = "center",
  })
  local close = function() pcall(vim.api.nvim_win_close, win, true) end
  vim.keymap.set("n", "q", close, { buffer = buf, desc = "关闭速查" })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, desc = "关闭速查" })
end

vim.api.nvim_create_user_command("DevKeys", M.open, { desc = "按键速查表" })

return M
