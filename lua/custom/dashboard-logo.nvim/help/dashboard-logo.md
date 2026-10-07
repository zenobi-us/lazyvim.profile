*dashboard-logo.txt*  Animated dashboard logo

===============================================================================
USAGE                                                     *dashboard-logo-usage*

Neovim: >lua
  local logo = require("dashboard-logo.snacks").setup {
    effect = "glitch", -- or "none"
    color = vim.api.nvim_get_hl(0, { name = "Special", link = false }).fg,
    update = function() require("snacks").dashboard.update() end,
  }
  local section = logo.section
<

Standalone preview: >sh
  ./lua/custom/dashboard-logo.nvim/cli.lua --watch --color=#c678dd
<

The preview loads the logo module once and reuses parsed ANSI data in watch
mode. Pass `--reload` while editing to reload modules before every frame. It
uses plain Lua and ANSI terminal colours; Neovim is not loaded. Press CTRL-C
to stop it.

Logo data lives in ANSI files under `lua/dashboard-logo/logos/`. New logos
must be added to `logos/init.lua`; select one with `setup { logo = "name" }`.
True-colour SGR sequences are parsed as source colours. Effects tint their
luminance instead of replacing their shading.

The glitch effect accepts `color = "#rrggbb"`. The Snacks adapter also accepts
Neovim's integer highlight colours. It generates shades with the original
green palette's luminance; omitting `color` retains the original green palette.

Effects live under `lua/dashboard-logo/effects/`. Add an effect to
`effects/init.lua`; select one with `setup { effect = "name" }`.

vim:tw=78:ts=8:noet:ft=help:norl: