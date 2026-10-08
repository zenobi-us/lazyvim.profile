-- Palette for the `mono-slate` colorscheme.
--
-- The nine anchor values come from the hrdx built-in theme "mono slate"
-- (hrdx/internal/ui/theme_presets.go). hrdx only needs nine roles for a
-- terminal multiplexer. An editor needs more steps, so the extra values below
-- extend the same xterm-256 greyscale ramp that hrdx already sits on.
--
-- hrdx role -> palette key
--   background -> bg        foreground -> fg
--   bar_bg     -> bg_bar    accent     -> accent
--   muted      -> muted     faint      -> faint
--   good       -> good      bad        -> bad        busy -> busy

return {
  -- anchors taken verbatim from hrdx "mono slate"
  bg = "#1c1c1c", -- 234
  fg = "#dadada", -- 253
  bg_bar = "#303030", -- 236
  accent = "#bcbcbc", -- 250
  muted = "#767676", -- 243
  faint = "#5f5f5f", -- 59
  good = "#a8a8a8", -- 248
  bad = "#d75f5f", -- 167
  busy = "#d7af5f", -- 179

  -- ramp extensions, same greyscale family
  bg_deep = "#121212", -- 233, sidebars and non-current windows
  bg_float = "#262626", -- 235, floats and popups
  bg_line = "#262626", -- 235, cursor line
  bg_sel = "#3a3a3a", -- 237, visual selection
  bg_high = "#444444", -- 238, search and matched text
  border = "#4e4e4e", -- 239, window and float borders
  comment = "#6c6c6c", -- 242
  fg_dim = "#c6c6c6", -- 251
  fg_bright = "#eeeeee", -- 255

  -- derived accents, kept inside the two warm hues hrdx already uses
  bad_dim = "#875f5f", -- 95, deleted git text and error underlines
  busy_dim = "#87875f", -- 101, changed git text
  none = "NONE",
}
