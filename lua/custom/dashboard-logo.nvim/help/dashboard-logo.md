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

INTERACTIVE GALLERY                                    *dashboard-logo-picker*

This profile registers :DashboardPick. After setup(), the same gallery opens
with: >lua
  require("dashboard-logo.snacks").pick()
<
Search shape/logo and effect together, for example "iris none" or "logo glitch".
The current choice starts first. Movement animates the preview only.
  Enter   Apply for this session and close.
  CTRL-S  Save as the default, apply, and close.
  Escape  Close without changing the dashboard.

The preview keeps the configured tint and original artwork size. It is hidden
on terminals too small for the artwork. Closing or hiding it stops its timer.

Saved choices use stdpath("state")/dashboard-logo.json. Startup prefers a valid
saved choice over configured source/effect options. Tint is not saved. Invalid
preferences warn and use configured defaults. Failed saves keep the picker open.

The setup() result also exposes current(), select({kind,name,effect}), and
pick(). select() keeps the section function stable and does not save a default.

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

Additional shapes (all use the same canvas and a 24-second loop):
  trefoil          Shaded tubular knot with depth-tested over/under crossings.
  mobius           Half-twisted ribbon, shaded on both sides.
  wave_grid        Perspective mesh deformed by travelling waves.
  dna              Rotating helical tubes with connecting rungs.
  accretion_disc   Orbiting particles with curved fading trails and a dark centre.
  planetary_system Three shaded planets orbiting a luminous star.
  superformula     Surface morphing between rounded, lobed, and star-like forms.
  iris             Overlapping blades opening and closing an aperture.

Use any name with `setup { shape = "name" }`. Omit `effect` for no overlay.
The default dashboard selection is not changed by registering a new shape.

Preview examples: >sh
  ./lua/custom/dashboard-logo.nvim/cli.lua --watch --shape=trefoil
  ./lua/custom/dashboard-logo.nvim/cli.lua --watch --shape=iris
<

vim:tw=78:ts=8:noet:ft=help:norl: