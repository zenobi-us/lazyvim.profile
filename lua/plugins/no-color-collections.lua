-- Scheme repositories catalogued by mcchrish/vim-no-color-collections.
-- `:Lazy sync` installs them. Schemes load on demand by colorscheme name.
return {
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = vim.env.NEOVIM_THEME_NAME or "monoglow" },
  },

  -- lush.nvim is a colorscheme framework dependency used by some schemes.
  { "rktjmp/lush.nvim", lazy = true },
  {
    "wnkz/monoglow.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("monoglow").setup({
        on_colors = function(colors)
          colors.glow = "#d75f5f" -- mono-slate bad/red accent
        end,
      })
    end,
  },
}
