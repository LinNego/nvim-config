-- Markdown 渲染：在编辑器里把 markdown 显示成接近渲染后的样子（不需要浏览器）
-- 终端没有 Nerd Font，所以全部用普通 Unicode / ASCII，不用私有区图标
return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "markdown.mdx", "rmd", "quarto" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      indent = { enabled = false },                     -- 不要左侧竖线缩进，太花
      heading = {
        icons = { "", "", "", "", "", "" },             -- 标题前不加图标
        sign = false,
        width = "block",
        left_pad = 2,
        right_pad = 0,
      },
      bullet = { icons = { "•", "◦", "▪" } },
      checkbox = {
        unchecked = { icon = "[ ] " },
        checked = { icon = "[x] " },
      },
      quote = { icon = "│" },
      code = {
        style = "normal",                               -- 隐掉 ``` 围栏，只留代码+底色
        border = "none",
        sign = false,
        left_pad = 2,
        right_pad = 2,
      },
      dash = { icon = "─" },
      link = { enabled = true },
      table = { enabled = true },
      win_options = {
        conceallevel = { default = 2, rendered = 2 },
      },
    },
    keys = {
      { "<leader>mp", "<cmd>RenderMarkdown toggle<cr>", desc = "Markdown 渲染 开/关" },
    },
  },
}
