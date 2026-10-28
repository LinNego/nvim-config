# Neovim 开发环境（Python / Go）

> 从 VSCode 迁过来的配置：左边常驻目录树、Git 改动可视化、冲突一键解决、编译在浮窗里跑、Markdown 直接渲染。
> 全部是 Lua 配置，无 Nerd Font 依赖（终端没装字体也能正常显示）。

## 安装

```bash
git clone git@github.com:LinNego/nvim-config.git ~/nvim-config
cd ~/nvim-config && ./install.sh        # 需要代理：PROXY=http://host:7897 ./install.sh
nvim                                    # 首次启动会自动装插件（需要联网）
```

前置条件：Linux x86_64、Neovim **0.11+**、git、curl、node/npm（pyright 需要）。
`install.sh` 会把配置软链到 `~/.config/nvim`，并按需安装 ripgrep / ruff / pyright / gofumpt。

### glibc 太老（Neovim 官方包跑不起来）

报错类似 `GLIBC_2.34 not found`，说明系统太老（如 AlmaLinux 8 / CentOS 7），需要源码编译：

```bash
cd ~/nvim-config && ./scripts/build-nvim.sh      # 编到 ~/.local/opt/nvim
./install.sh
```

脚本会自动下载 cmake/ninja 二进制（不动系统包），编译内置依赖，约 5–15 分钟。

---

## 使用速查

> 所有插件都在 `~/.config/nvim` 下，改完重启 nvim 即生效。

## 0. 启动

```bash
cd /data/ljc/vigap/goproxy     # 进项目目录
nvim                           # 或者 nvim main.go
```

第一次进会自己装插件（已预装好，正常几秒内完成）。

## 0.1 忘了按键怎么办

- 直接按 **空格**（就是 `<leader>`）停一下，会弹出分组提示
- `<leader>?` 打开**按键速查浮窗**（就是本文件的精简版，`q` 关闭）
- `<leader>fk` 搜索所有按键、`<leader>fh` 搜索 Neovim 帮助文档
- `:DevKeys` 命令也能打开速查；纯文本版在 `~/.config/nvim/KEYS.md`

## 1. 文件树（常驻，q 不会关掉）

| 按键 | 作用 |
| --- | --- |
| `Alt+B` | 显示 / 隐藏整栏目录树（唯一能关掉它的方式） |
| `<leader>e` | 光标跳到目录树 |
| `Enter` / `l` | 打开文件/展开目录 |
| `h` | 收起当前目录 |
| `a` / `d` / `r` | 新建 / 删除 / 重命名 |
| `c` / `x` / `p` | 复制 / 剪切 / 粘贴 |
| `y` / `Y` | 复制文件名 / 相对路径 |
| `H` | 显示/隐藏点文件 |
| `s` / `i` | 垂直 / 水平分屏打开 |

树里按 `q`、`<C-w>c`、`<C-w>o` 都不会关闭；就算被 `:close` 掉了也会自动恢复（1 秒内弹回来）。

> 在 tmux 里，`<C-b>` 是 tmux 前缀，所以目录树改用 `Alt+B`（Ctrl+Shift+B 在多数终端会被压成 Ctrl+B，这里不适用）。

> `<leader>` 就是空格键。

## 2. 看 Git 改动（可视化）

| 按键 | 作用 |
| --- | --- |
| `<leader>gd` | 左右对比看所有未提交改动（最左文件列表，中间旧版，右边新版） |
| `<leader>gD` | 与上一个提交对比 |
| `<leader>gh` | 当前文件的历史（逐次提交） |
| `<leader>gH` | 整个仓库的提交历史 |
| `<leader>gc` | 关闭 diff 视图 |
| `<leader>gs` | Git 总览面板：所有仓库的改动，再按一次关闭；回车=左右对比，`o`=只看文件 |
| `]c` / `[c` | 跳到下 / 上一个改动块 |
| `<leader>hp` | 浮动预览当前改动块 |
| `<leader>hs` / `<leader>hr` | 暂存 / 撤销当前改动块 |
| `<leader>hb` | 这一行是谁、哪个提交写的 |
| `<leader>hB` | 开关行尾 blame |

**目录树里的状态字母**（父目录会汇总子项的字母，例如 `src  S M D ?`）：

| 字母 | 含义 | 字母 | 含义 |
| --- | --- | --- | --- |
| `M` | 改了，还没 `git add` | `S` | 已暂存 |
| `?` | 新文件，git 还没跟踪 | `D` | 删除（树里看不到这个文件本身，只能看到目录上的 `D`） |
| `U` | 合并冲突，待解决 | `R` | 重命名 |

编辑区的左符号列还会显示 `┃`（新增/修改）、`▁`（删除）、`┆`（未跟踪）。

> 注意：要在**具体仓库的根目录**里开 nvim（比如 `/data/ljc/vigap/goproxy`）。如果你在 `vigap` 这种"很多仓库的父目录"里开，git 功能会全部哑火，nvim 启动时会弹提醒告诉你有哪几个仓库。
>
> diff 视图默认是**扁平列表**（一行一个文件，前面是 `M`/`?`/`S` 加文件名），按 `i` 可以在列表和目录树之间切换。

**多仓库工作区**（`vigap` 这种下面并列很多仓库的目录）：

- `<leader>gT` 跨所有仓库列出改动文件（`M golangServer bin/xxx` 这样带仓库前缀，可搜索、带预览）
- `<leader>gr` 切换到某个仓库（改 cwd + 目录树根，之后 git 标记正常）；不管当前在哪个仓库里，都能看到全部 8 个（从工作区根 / 当前仓库的父目录找）
- `<leader>gR` 返回上一个仓库 / 目录（可连续回退）
- 在非仓库目录开 nvim 会提示，按上面两个键即可

**看整体 git 状态**：`<leader>gs` 打开状态面板（按 `s` 暂存光标处文件、`u` 取消暂存、`cc` 提交、`dv` 看某个文件的 diff）；`<leader>gd` 打开 diff 视图；`:Git` 直接敲命令也行。

## 3. 解决冲突（最省事的做法）

打开有冲突的文件，会看到：

```
<<<<<<< HEAD
   你的版本
=======
   对方的版本
>>>>>>> feature/xxx
```

光标放在冲突里，按：

| 按键 | 作用 |
| --- | --- |
| `co` | 用**我的**（ours / HEAD） |
| `ct` | 用**对方的**（theirs / 被合进来的分支） |
| `cb` | 两个都保留 |
| `c0` | 两个都不要 |
| `]x` / `[x` | 跳到下 / 一个冲突 |
| `<leader>gd` | 想整体看差异时打开 diff 视图 |

冲突处理完：`git add 文件`，然后 `:Git` 里 `cc` 提交。

也可以用 diffview 的三栏合并视图：`:DiffviewOpen` 后按 `<Tab>` 切文件列表，冲突文件打开即是三方对比。

## 4. 编译 / 运行 / 测试（浮窗）

| 按键 | 作用 |
| --- | --- |
| `F5` | 编译（Go: `go build ./...`；Python: 语法编译检查） |
| `F6` | 运行（Go: `go run .`；Python: 跑当前文件） |
| `F7` | 测试（Go: `go test ./...`；Python: `pytest`） |
| `<leader>rc` | 手输任意命令，在项目根目录的浮窗里跑 |
| `Alt+T` | 浮动终端 开/关（终端里也能直接按，内容保留） |
| `<C-\>` | 同上（普通模式下） |

浮窗跑完**不会自动消失**，方便看报错；按 `i` 可继续在终端里输入，`Esc` 回普通模式，`<C-\>` 关掉。

项目根目录按 `go.mod` / `Makefile` / `.git` 自动识别；Python 优先用项目里的 `.venv/bin/python`，没有就用 `python3.12`。

## 5. 查找 / 跳转

| 按键 | 作用 |
| --- | --- |
| `<C-p>` | 按文件名找文件 |
| `<leader>fg` | 全项目全文搜索（ripgrep） |
| `<leader>fb` | 切换已打开的文件 |
| `<leader>fr` | 最近打开过的文件 |
| `<leader>fd` | 所有报错/警告列表 |
| `gd` / `gr` / `K` | 跳定义 / 查引用 / 看文档 |
| `<leader>rn` / `<leader>ca` | 重命名 / 代码操作（如自动 import） |
| `]d` / `[d` | 下 / 上一个报错 |

Go 的自动 import 在保存时会做（gopls + gofumpt）；Python 用 pyright 做类型检查、ruff 可格式化。

## 6. 常用编辑

| 按键 | 作用 |
| --- | --- |
| `<leader>w` | 保存 |
| `<leader>q` | 关当前文件（不关编辑器） |
| `<leader>Q` | 退出 |
| `<S-h>` / `<S-l>` | 上一个 / 下一个打开的文件 |
| `<C-h/j/k/l>` | 在分屏间移动 |
| `<leader>cf` | 手动格式化 |
| `<leader>fa` | 开关"保存自动格式化" |
| `u` / `<C-r>` | 撤销 / 重做（关掉文件再开也能撤销） |

## 6.1 Markdown 渲染

打开 `.md` 会在编辑器里直接渲染（标题、加粗/斜体、列表、引用、表格、代码块、任务框），不需要浏览器。
- `<leader>mp` 开/关渲染
- 光标所在行会临时显示原始 `#`、`**` 等，移开就恢复——方便边看边改
- 终端限制：图片、真实链接、内嵌 HTML 不会渲染

## 7. 环境说明

- Neovim 0.11.4，编译安装在 `/opt/nvim-0.11`（系统自带 vim 8 未改动）
- Go 1.24.5：`/usr/local/go/bin`，gopls、gofumpt 在 `/root/go/bin`
- Python：**3.12.16**（portable 构建，装在 `/opt/python`，命令是 `python3.12` / `pip3.12`）
  系统自带的 `python3` 仍是 3.6，没动它（yum 等系统脚本依赖它）
- Python 语言服务：`pyright`（类型检查）+ `ruff`（lint + 保存时格式化），都已接进 nvim
- 包管理：`uv`（比 pip 快很多），见下面第 9 节
- 代理：已写好 `proxy_on` / `proxy_off` 两个命令（在 `.bashrc` 里），需要联网时装插件/拉依赖前先 `proxy_on`
- 插件目录：`~/.local/share/nvim/lazy`；`:Lazy` 查看/更新插件

### 在 tmux 里用

- tmux 前缀保持默认 **`C-b`**；nvim 的目录树改用 `Alt+B`；`~/.tmux.conf` 已备份为 `~/.tmux.conf.bak-*`
- 原来的全局 `C-h/j/k/l`（切 tmux pane）会抢 nvim 的分屏键，已解绑；切 pane 用 `前缀 + h/j/k/l`
- 真彩色已打开（`screen-256color` + `Tc`），主题不会掉色；`escape-time 10` 让 Esc 立即生效
- `set-clipboard on`：程序可以用 OSC52 往你本地剪贴板写
- 已有 tmux 会话执行 `tmux source-file ~/.tmux.conf`，或直接开新会话

### 主题

默认 **VSCode Dark+**（`Mofiqul/vscode.nvim`，背景 #1f1f1f），和 VSCode 观感一致。
- `<leader>ut` 切换主题（vscode / tokyonight-moon / habamax）
- 想换浅色：改 `lua/plugins/ui.lua` 里 `style = "dark"` → `"light"`

### 界面约定

不使用 Nerd Font 图标（终端没装也能显示）：文件/文件夹不带图标，git 状态用字母 `M/S/U/D/?/R`，目录用 `▸ / ▾` 表示展开状态。

## 8. Python 项目怎么跑

新项目 / 已有项目，二选一：

```bash
# 方式一：标准 venv（pip 走代理前先 proxy_on）
python3.12 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# 方式二：uv，快很多（推荐）
uv venv                 # 用 3.12 建 .venv
uv pip install -r requirements.txt
```

建好 `.venv` 后直接在项目里 `nvim`：F6 会用 `.venv/bin/python` 跑当前文件，F7 跑 pytest，保存时 ruff 自动格式化。

想让 pyright 也用项目的 `.venv`（默认用的是 3.12 全局解释器），在项目里加个 `pyrightconfig.json`：

```json
{ "venvPath": ".", "venv": ".venv" }
```

## 9. 出问题时

- `:Lazy` → `X` 清理、`S` 同步插件
- `:checkhealth` 看 LSP / 插件状态
- `:LspInfo` 看语言服务器是否连上
- 想回到几乎裸的 nvim：`nvim -u NONE`
- 想让 git 提交时也用 nvim 写说明：`git config --global core.editor nvim`
- 配置文件都在 `~/.config/nvim`：`init.lua`、`lua/config/*.lua`（基础）、`lua/plugins/*.lua`（插件清单）
