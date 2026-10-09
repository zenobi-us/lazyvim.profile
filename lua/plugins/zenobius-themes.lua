-- Local colorscheme plugin: zenobius-themes.
--
-- `dir` puts `lua/custom/zenobius-themes` on the runtimepath, which makes two
-- paths reachable:
--
--   colors/<name>.lua            -> `:colorscheme <name>`
--   lua/zenobius-themes/*.lua    -> `require "zenobius-themes"`
--
-- Themes in here:
--
--   mono-slate   dark, greyscale, two hues (hrdx "mono slate")
--
-- `lua/zenobius-themes/init.lua` holds the list of names `:colorscheme`
-- accepts. Keep that list and `colors/` in step.

---@type LazySpec
return {
  {
    "custom/zenobius-themes",
    dir = vim.fn.stdpath("config") .. "/lua/custom/zenobius-themes",
    lazy = false,
    priority = 1000,
  },
}
