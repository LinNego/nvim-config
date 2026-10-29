-- 界面：主题、状态栏、目录树、快捷键提示
return {
  -- 默认用 VSCode Dark+ 的配色（最接近你原来用的 VSCode）
  {
    "Mofiqul/vscode.nvim",
    priority = 1000,
    lazy = false,
    config = function()
      require("vscode").setup({
        style = "dark",              -- dark / light
        transparent = false,
        italic_comments = true,
        italic_strings = false,
        underline_links = true,
      })
      pcall(vim.cmd.colorscheme, "vscode")
    end,
  },

  -- 备用主题，随时可切
  {
    "folke/tokyonight.nvim",
    priority = 990,
    lazy = false,
    config = function()
      require("tokyonight").setup({
        style = "moon",
        styles = { comments = { italic = true }, keywords = { italic = true } },
      })
    end,
  },

  { "nvim-tree/nvim-web-devicons", lazy = true },

  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    opts = {
      options = {
        theme = "auto",
        globalstatus = true,
        icons_enabled = false,        -- 状态栏也不要 nerd 图标
        section_separators = "",
        component_separators = "|",
        disabled_filetypes = { statusline = { "NvimTree" } },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff" },
        lualine_c = {
          { "filename", path = 1 },
          { function() return "  " .. vim.fn.fnamemodify(vim.fn.getcwd(), ":~") end },
        },
        lualine_x = { "diagnostics", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "classic",          -- 竖排列表，比横排格子好读
      delay = 200,
      -- 不混入 Vim 内置的 g / z 前缀命令（gg、ge、zz 那些），只看自己的键
      plugins = {
        presets = {
          g = false, z = false,
          operators = false, motions = false, text_objects = false, windows = false, nav = false,
        },
      },
      -- 全部用纯文本：不要 nerd 图标（Esc/Space 等特殊键不再显示成方块）
      icons = (function()
        local plain = {}
        for _, k in ipairs({ "Up", "Down", "Left", "Right", "C", "M", "D", "S", "CR", "Esc", "NL", "BS", "Space", "Tab" }) do
          plain[k] = ""
        end
        for i = 1, 12 do plain["F" .. i] = "" end
        return { mappings = false, group = "", keys = plain }
      end)(),
      win = { border = "rounded", padding = { 1, 2 }, title = " 按键 ", title_pos = "center" },
      -- 过滤掉 Vim 内置的几个噪声键（保留 gc 注释、gr 引用这些有用的）
      filter = function(mapping)
        local skip = { ["gO"] = 1, ["gx"] = 1, ["g%"] = 1, ["g'" ] = 1, ["g`"] = 1, ["g&"] = 1, ["g8"] = 1 }
        return skip[mapping.lhs] == nil
      end,
    },
    config = function(_, opts)
      require("which-key").setup(opts)
      -- 给每个分组起中文名，按空格后看到的就是 "g → Git" 而不是 "+12 keymaps"
      require("which-key").add({
        { "<leader>b", group = "文件列表 / 缓冲区" },
        { "<leader>c", group = "代码操作" },
        { "<leader>f", group = "查找" },
        { "<leader>g", group = "Git" },
        { "<leader>h", group = "Git 行内操作" },
        { "<leader>l", group = "LSP" },
        { "<leader>r", group = "运行 / 编译" },
        { "<leader>s", group = "分屏" },
        { "<leader>t", group = "终端" },
        { "<leader>m", group = "Markdown" },
        { "<leader>u", group = "界面 / 主题" },
        -- 普通前缀也起个名字，按 g 就知道这组是干嘛的
        { "g", group = "跳转 / 引用" },
        { "[", group = "上一个" },
        { "]", group = "下一个" },
      })
    end,
  },

  -- 文件树（常驻，见 lua/config/tree.lua）
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = false,
    config = function()
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
      require("nvim-tree").setup({
        sort = { sorter = "case_sensitive" },
        view = { width = 34, side = "left", preserve_window_proportions = true },
        renderer = {
          root_folder_label = false,
          indent_markers = { enable = true },
          -- 文件名 + 状态字母都按 git 状态上色
          highlight_git = "all",
          icons = {
            -- 终端没有 Nerd Font，关掉文件/文件夹图标（会显示成方块）
            show = { git = true, file = false, folder = false, folder_arrow = true },
            glyphs = {
              folder = { arrow_closed = "▸", arrow_open = "▾" },
              -- 用字母代替默认的 ✓ ✗ ★
              git = {
                unstaged = "M",     -- 改了没暂存
                staged = "S",       -- 已暂存
                unmerged = "U",     -- 冲突待解决
                renamed = "R",
                untracked = "?",    -- 新文件
                deleted = "D",
                ignored = "I",
              },
            },
          },
        },
        update_focused_file = { enable = true, update_root = false },
        git = { enable = true, ignore = false, timeout = 500, show_on_dirs = true, show_on_open_dirs = true },
        filters = {
          dotfiles = false,
          git_ignored = true,
          custom = { "^.git$", "node_modules", "__pycache__", "%.pyc$", ".venv", "venv" },
        },
        actions = {
          open_file = { quit_on_open = false, resize_window = false, window_picker = { enable = false } },
        },
        diagnostics = { enable = true, show_on_dirs = true },
        on_attach = function(bufnr)
          local api = require("nvim-tree.api")
          local function map(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
          end
          -- 打开方式：回车沿用默认（聚焦文件窗口），o 在树里开但焦点留在文件
          map("<CR>", api.node.open.edit, "打开")
          map("l", api.node.open.edit, "打开")
          map("h", api.node.navigate.parent_close, "收起目录")
          map("a", api.fs.create, "新建")
          map("d", api.fs.remove, "删除")
          map("r", api.fs.rename, "重命名")
          map("c", api.fs.copy.node, "复制")
          map("x", api.fs.cut, "剪切")
          map("p", api.fs.paste, "粘贴")
          map("y", api.fs.copy.filename, "复制文件名")
          map("Y", api.fs.copy.relative_path, "复制相对路径")
          map("R", api.tree.reload, "刷新")
          -- 在这个目录里搜索 / 找文件（不需要先切换 cwd）
          map("S", function()
            local node = api.tree.get_node_under_cursor()
            local dir = node and node.absolute_path or vim.fn.getcwd()
            if dir and vim.fn.isdirectory(dir) == 0 then dir = vim.fn.fnamemodify(dir, ":h") end
            require("telescope.builtin").live_grep({
              search_dirs = { dir },
              prompt_title = "搜索目录 " .. vim.fn.fnamemodify(dir, ":~"),
            })
          end, "在此目录搜索内容")
          map("F", function()
            local node = api.tree.get_node_under_cursor()
            local dir = node and node.absolute_path or vim.fn.getcwd()
            if dir and vim.fn.isdirectory(dir) == 0 then dir = vim.fn.fnamemodify(dir, ":h") end
            require("telescope.builtin").find_files({
              cwd = dir,
              prompt_title = "文件 " .. vim.fn.fnamemodify(dir, ":~"),
            })
          end, "在此目录找文件")
          map("H", api.tree.toggle_hidden_filter, "显示/隐藏点文件")
          map("s", api.node.open.vertical, "垂直分屏打开")
          map("i", api.node.open.horizontal, "水平分屏打开")
        end,
      })
    end,
  },
}
