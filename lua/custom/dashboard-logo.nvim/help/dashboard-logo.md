*dashboard-logo.txt*  Animated dashboard logo

===============================================================================
USAGE                                                     *dashboard-logo-usage*

Neovim: >lua
  local logo = require("dashboard-logo.snacks").setup {
    effect = "glitch", -- or "sonar", "none"
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

The sonar effect expands a ring from the centre of the logo, followed by a
fading trail and a short pause. It keeps the logo stationary and corrects for
terminal cell proportions. It accepts the same `color` option and defaults
to mint when no colour is supplied.

Effects live under `lua/dashboard-logo/effects/`. Add an effect to
`effects/init.lua`; select one with `setup { effect = "name" }`.

Generated shapes: >lua
  local logo = require("dashboard-logo.snacks").setup {
    shape = "globe",
    effect = "none", -- or "sonar"
    color = vim.api.nvim_get_hl(0, { name = "Special", link = false }).fg,
    update = function() require("snacks").dashboard.update() end,
  }
<
Select `shape` or `logo`, not both. Shapes default to no effect and a mint tint.
The globe rotates once every 20 seconds on a fixed 61-column, 25-row canvas.
It shows coarse land outlines and a latitude/longitude grid, with fixed
lighting and rear-surface hiding. Terminal-cell proportions are corrected.

Globe preview: >sh
  ./lua/custom/dashboard-logo.nvim/cli.lua --watch --shape=globe
  ./lua/custom/dashboard-logo.nvim/cli.lua --watch --shape=globe --effect=sonar
<

The gyroscope (`shape = "gyroscope"`) shows three nested wireframe rings
rotating around different axes on the same fixed canvas. Front edges are
bright; rear edges are dim and dotted. The nearest ring wins at crossings.
Its complete rotation cycle takes 24 seconds.

Gyroscope previews: >sh
  ./lua/custom/dashboard-logo.nvim/cli.lua --watch --shape=gyroscope
  ./lua/custom/dashboard-logo.nvim/cli.lua --watch --shape=gyroscope --effect=glitch
  ./lua/custom/dashboard-logo.nvim/cli.lua --watch --shape=gyroscope --effect=sonar
<

The crystal (`shape = "crystal"`) is a solid octahedron tumbling around three
axes on the same fixed canvas. A fixed light source shades the triangular
faces, and bright edges outline the facets. Rear faces are hidden. Its
complete rotation cycle takes 24 seconds.

Crystal previews: >sh
  ./lua/custom/dashboard-logo.nvim/cli.lua --watch --shape=crystal
  ./lua/custom/dashboard-logo.nvim/cli.lua --watch --shape=crystal --effect=glitch
  ./lua/custom/dashboard-logo.nvim/cli.lua --watch --shape=crystal --effect=sonar
<

The torus (`shape = "torus"`) spins around the view axis and rocks its tilt.
The opening stays visible throughout the 24-second cycle. Fixed lighting and
a specular highlight shade the curved surface. Only the nearest surface is
rendered. It uses the same fixed canvas and terminal-cell correction.

Torus preview: >sh
  ./lua/custom/dashboard-logo.nvim/cli.lua --watch --shape=torus
<

vim:tw=78:ts=8:noet:ft=help:norl: