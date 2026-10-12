return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.icons" },
    opts = {
      code = {
        width = "full",
        highlight = "RenderMarkdownCode",
        conceal_delimiters = false,
        language = true,
        language_icon = true,
        language_pad = 2,
        left_pad = 2,
        border = "thin",
      },
    },
  },
}
