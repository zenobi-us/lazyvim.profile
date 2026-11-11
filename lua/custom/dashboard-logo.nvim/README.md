# dashboard-logo.nvim

Animated ANSI-art logos for Neovim dashboards and terminal previews.

`dashboard-logo.nvim` parses true-colour ANSI logos, applies animated effects, and renders the same output through either Snacks.nvim or a standalone Lua CLI. The default glitch effect uses a green CRT palette. A custom base colour can be supplied without losing the original palette's luminance gradient.

## Install

### lazy.nvim

Use the plugin from a local checkout:

```lua
{
  "dashboard-logo.nvim",
  dir = vim.fn.stdpath("config") .. "/lua/custom/dashboard-logo.nvim",
  dependencies = { "folke/snacks.nvim" },
}
```

The standalone renderer requires a Lua interpreter. Animated CLI previews also require `stty` and `sleep`.

## Usage

### Snacks.nvim

```lua
local dashboard_logo = require("dashboard-logo.snacks").setup {
  effect = "glitch",
  color = vim.api.nvim_get_hl(0, { name = "Special", link = false }).fg,
  update = function()
    require("snacks").dashboard.update()
  end,
}

require("snacks").setup {
  dashboard = {
    sections = {
      dashboard_logo.section,
      { section = "startup" },
    },
  },
}
```

`color` accepts either a `#rrggbb` string or a Neovim highlight colour integer. Omit it to use the default green palette.

Stop the animation timer when needed:

```lua
dashboard_logo.stop()
```

### Interactive animation gallery

This profile provides `:DashboardPick`. Plugin users can open the same gallery
after `setup()` with:

```lua
require("dashboard-logo.snacks").pick()
```

The Snacks picker lists every registered shape or logo paired with every effect.
Search for a combination such as `iris none`, `trefoil sonar`, or `logo glitch`.
The current choice starts first. Moving through results animates an isolated
preview without changing the dashboard.

| Input | Action |
| --- | --- |
| `Enter` | Apply the highlighted choice for this session and close. |
| `Ctrl-s` | Save the choice as the default, apply it, and close. |
| `Esc` | Close without changing the dashboard or saved default. |

The preview preserves the current tint and artwork dimensions. It is hidden
when the terminal cannot fit the full artwork. Its timer stops when the preview
is hidden or the picker closes; it does not depend on a visible dashboard.

Saved preferences live at `stdpath("state")/dashboard-logo.json`. Only `kind`,
`name`, and `effect` are saved; colour remains controlled by the configured tint.
Startup uses a valid saved choice before configured options, then core defaults.
An invalid saved preference produces a warning and leaves configured defaults
in use. Failed saves leave the picker open and preserve the previous preference.

### Core renderer

The core module has no Neovim dependency:

```lua
local logo = require "dashboard-logo"

local animation = logo.new {
  logo = "grudge_axe",
  effect = "glitch",
  color = "#c678dd",
  update = function(frame)
    -- Render frame through another frontend.
  end,
}

local frame = animation.frame()
animation.tick()
```

Available built-in effects:

- `glitch` — animated scan bands, displacement, and burn waves.
- `sonar` — expanding rings with fading trails and a dim, stationary logo.
- `none` — unchanged logo frame.

### Generated shapes

Shapes generate their own animated geometry instead of filtering a static logo:

```lua
local animation = require("dashboard-logo").new {
  shape = "globe",
  color = "#61afef",
  effect = "none", -- Use "sonar" to add an expanding pulse.
}
```

The globe rotates once every 20 seconds on a fixed 61-column, 25-row canvas.
It uses coarse continent outlines, latitude and longitude lines, and a fixed
light source. Only the front hemisphere is visible. Terminal-cell proportions
are corrected so the sphere looks round.

The gyroscope (`shape = "gyroscope"`) has three nested wireframe rings rotating
around different axes. Front edges are bright; rear edges are dim and dotted.
A depth buffer keeps the nearest ring visible at crossings. It uses the same
fixed canvas and terminal-cell correction as the globe, with a 24-second cycle.
Use `effect = "glitch"` for CRT distortion or `"sonar"` for an expanding pulse.

The crystal (`shape = "crystal"`) is a solid octahedron tumbling around three
axes. Visible triangular faces use fixed-source lighting; bright edges outline
the facets. Rear faces are culled, and face fills use a depth buffer. It uses
the same fixed canvas and terminal-cell correction, with a 24-second cycle.

The torus (`shape = "torus"`) spins around the view axis while rocking its tilt.
Its opening stays visible throughout the 24-second cycle. Fixed lighting and a
small specular highlight reveal the curved tube. View rays stop at the nearest
surface, so rear surfaces do not show through. It uses the same fixed canvas
and terminal-cell correction as the other shapes.

Eight additional shapes use the same canvas, tint, and a 24-second loop:

| Shape name | Geometry and motion |
| --- | --- |
| `trefoil` | A rotating, shaded tubular knot with three lobes and depth-tested crossings. |
| `mobius` | A broad half-twisted ribbon with a continuous seam and shading on both sides. |
| `wave_grid` | A perspective grid deformed by overlapping travelling waves. |
| `dna` | Two rotating helical tubes joined by rungs; near strands hide rear connections. |
| `accretion_disc` | Particles at different radii orbit a dark centre, leaving fading curved trails. |
| `planetary_system` | Three shaded planets orbit a luminous star at different speeds. |
| `superformula` | A shaded surface morphs between rounded, lobed, and star-like silhouettes. |
| `iris` | Eight overlapping blades rotate to open and close an octagonal aperture. |

Select any shape with `new { shape = "trefoil" }` or the same option in
`require("dashboard-logo.snacks").setup`. Shapes can also use the existing
`sonar` and `glitch` effects; omit `effect` for unfiltered geometry.

Select either `shape` or `logo`, not both. Shapes default to `effect = "none"`
and a mint tint. The Snacks adapter accepts the same shape options.


## API

### `require("dashboard-logo")`

#### `render(name?) -> frame`

Parses a named logo into lines and colour segments. Uses the default logo when `name` is omitted.

#### `generate(state?, name?, effect?, shape?) -> frame`

Renders one frame using the supplied mutable state. For a generated shape, pass `nil` for `name` and `"globe"` as the fourth argument.

```lua
local state = { color = "#61afef" }
local frame = logo.generate(state, "grudge_axe", "glitch")
```

#### `advance(state?, name?, effect?, shape?) -> state`

Advances shape and effect state by one animation step. Use the same selection arguments as `generate`.

#### `new(opts?) -> animation`

Creates an animation object.

| Option | Type | Description |
| --- | --- | --- |
| `logo` | `string` | Registered logo name. |
| `shape` | `string` | Registered generated shape name from the catalogue above. Mutually exclusive with `logo`. |
| `effect` | `string` | Registered effect name. Defaults to `none` for shapes, `glitch` for logos. |
| `color` | `string` | Shape or effect base colour in `#rrggbb` format. |
| `update` | `function(frame)` | Called after each `tick()`. |

Returned animation fields:

| Field | Description |
| --- | --- |
| `interval` | Animation interval in milliseconds. |
| `frame()` | Returns current frame without advancing state. |
| `tick()` | Advances state, calls `update`, and returns new frame. |

#### `filter_color(source?, filter?) -> color?`

Tints a source colour with an effect filter while retaining source shading.

#### `logos`

Table of registered logos. `logos.default` contains the default logo name.

#### `effects`

Table of registered effects. `effects.default` contains the default effect name.

#### `shapes`

Table of registered shape renderers. Includes all names in the generated-shape catalogue above.

### `require("dashboard-logo.snacks")`

#### `setup(opts?) -> integration`

Creates a stable Snacks dashboard section. Supports `logo`, `shape`, `effect`, `color`, and `update` options. A valid saved choice overrides the configured source and effect. Neovim integer colours are converted to `#rrggbb` before reaching the core renderer.

Returns:

- `section()` — Snacks dashboard section provider.
- `stop()` — stops and closes the animation timer.
- `current()` — returns a copy of the current `{ kind, name, effect }` selection.
- `select(selection)` — replaces the animation without replacing the section provider or saving a default.
- `pick()` — opens the gallery for this integration and returns the Snacks picker.

#### `stop()`

Stops the active global dashboard-logo timer.

#### `pick() -> snacks.Picker`

Opens the gallery for the active integration. Call `setup()` first.

## CLI

Render one frame:

```sh
./cli.lua
```

Run an animated preview:

```sh
./cli.lua --watch
```

Use another effect or colour:

```sh
./cli.lua --watch --effect=glitch --color=#c678dd
./cli.lua --effect=none
./cli.lua --watch --effect=sonar --color=#61afef
./cli.lua --watch --shape=globe --color=#61afef
./cli.lua --watch --shape=globe --effect=sonar
./cli.lua --watch --shape=gyroscope --effect=glitch --color=#61afef
./cli.lua --watch --shape=crystal --effect=glitch --color=#61afef
./cli.lua --watch --shape=torus --color=#61afef
./cli.lua --watch --shape=trefoil
./cli.lua --watch --shape=mobius
./cli.lua --watch --shape=wave_grid
./cli.lua --watch --shape=dna
./cli.lua --watch --shape=accretion_disc
./cli.lua --watch --shape=planetary_system
./cli.lua --watch --shape=superformula
./cli.lua --watch --shape=iris
```

| Option | Description |
| --- | --- |
| `-w`, `--watch` | Keep rendering frames until interrupted. |
| `--reload` | Reload Lua modules before every frame (useful while editing). |
| `--shape=NAME` | Select any registered shape from the generated-shape catalogue above. |
| `--effect=NAME` | Select an effect. Defaults to `none` for shapes, `glitch` for logos. |
| `--color=#rrggbb` | Set the shape or effect base colour. Shapes and sonar default to mint; glitch defaults to green. |

The CLI loads dashboard-logo once and reuses the parsed logo in watch mode, avoiding repeated ANSI parsing and module initialization. Pass `--reload` when developing logos or effects to reload the Lua modules before every frame. Press `Ctrl-C` to stop watch mode.

## Verification

From the plugin directory, run the new shape behavior checks with both runtimes:

```sh
lua tests/shapes.lua
luajit tests/shapes.lua
```

These checks cover all eight new shapes, including animation loops, canvas and
segment invariants, tint changes, depth ordering, morphing, and aperture motion.
For a focused run, append one shape name, for example `lua tests/shapes.lua iris`.

Neovim integration checks use isolated temporary preference directories:

```sh
nvim --headless -u NONE -l tests/selection.lua
nvim --headless -u NONE -l tests/dashboard-selection.lua
```
                                                                                                                                                                                                                                                                                                                                                   