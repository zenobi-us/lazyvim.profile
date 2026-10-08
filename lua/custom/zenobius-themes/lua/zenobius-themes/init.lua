-- Loader for the themes in this directory.
--
-- Each file in `colors/` calls `load "<its own name>"`. Nothing else does.
--
-- A theme module lives in `highlights/` and exposes:
--   groups(variant)   -> table of highlight groups
--   terminal(variant) -> the 16 terminal colours, in order
--   setup()           -> optional, run after the groups are applied
--
-- `variant` is nil for single-variant themes such as mono-slate.

local M = {}

---@class ZenobiusThemeSpec
---@field module string module under `zenobius-themes.highlights`
---@field variant string|nil argument passed to `groups` and `terminal`
---@field background "dark"|"light"

---Every name that `:colorscheme` accepts, and what each one loads.
---Keep this table and the files in `colors/` in step.
---@type table<string, ZenobiusThemeSpec>
M.themes = {
  ["mono-slate"] = { module = "zenobius-themes.highlights.mono-slate", background = "dark" },
}

---Apply a theme by name.
---@param name string a key of `M.themes`
function M.load(name)
  local theme = assert(M.themes[name], "unknown theme: " .. tostring(name))

  vim.cmd.highlight("clear")
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd.syntax("reset")
  end

  vim.o.termguicolors = true
  vim.o.background = theme.background
  vim.g.colors_name = name

  local highlights = require(theme.module)

  for group, spec in pairs(highlights.groups(theme.variant)) do
    vim.api.nvim_set_hl(0, group, spec)
  end

  for index, color in ipairs(highlights.terminal(theme.variant)) do
    vim.g["terminal_color_" .. (index - 1)] = color
  end

  if highlights.setup then
    highlights.setup()
  end
end

return M
