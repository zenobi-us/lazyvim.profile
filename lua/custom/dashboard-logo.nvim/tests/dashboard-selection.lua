-- Run with Neovim; preferences and animated buffers are isolated from the user session.
local script = arg[0]:gsub("\\", "/")
local root = script:match "^(.*)/tests/[^/]+$" or "."
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path
local previous_home = vim.env.XDG_STATE_HOME
local temporary = vim.fn.tempname()
vim.env.XDG_STATE_HOME = temporary
local adapter = require "dashboard-logo.snacks"
local selection = require "dashboard-logo.selection"

local function text(section)
  local parts = {}
  for _, chunk in ipairs(section.text) do parts[#parts + 1] = chunk[1] end
  return table.concat(parts)
end

local function run()
  vim.bo.filetype = "snacks_dashboard"
  local updates = 0
  local first = adapter.setup {
    shape = "torus", color = "#61afef",
    update = function() updates = updates + 1 end,
  }
  local provider = first.section
  local original = text(provider())
  local old_timer = _G.snacks_dashboard_logo_timer
  first.select { kind = "shape", name = "iris", effect = "none" }
  assert(text(provider()) ~= original, "the dashboard's stored section still rendered the old animation")
  assert(old_timer:is_closing(), "replacing the animation leaked the old timer")
  assert(vim.wait(800, function() return updates >= 3 end), "the replacement animation did not run")
  assert(selection.load() == nil, "session-only selection wrote a saved default")

  local timer = _G.snacks_dashboard_logo_timer
  local ok = pcall(first.select, { kind = "shape", name = "missing", effect = "none" })
  assert(not ok and timer == _G.snacks_dashboard_logo_timer and not timer:is_closing(), "invalid selection destroyed the current animation")
  first.select { kind = "logo", name = "neovim", effect = "sonar" }
  assert(first.current().kind == "logo" and first.current().effect == "sonar", "shape-to-logo switch retained incompatible selection state")
  assert(text(provider()) ~= original, "logo selection did not reach the stable dashboard section")

  assert(selection.save { kind = "shape", name = "globe", effect = "none" })
  local second = adapter.setup { shape = "iris" }
  assert(second.current().name == "globe", "saved preference did not override configured shape")
  second.section()
  local second_timer = _G.snacks_dashboard_logo_timer
  first.stop()
  provider()
  assert(_G.snacks_dashboard_logo_timer == second_timer and not second_timer:is_closing(), "an obsolete integration disrupted the new timer")
  assert(not pcall(first.select, { kind = "shape", name = "torus", effect = "none" }), "an obsolete integration accepted a new selection")
  second.select { kind = "shape", name = "torus", effect = "none" }
  assert(selection.load().name == "globe", "session selection overwrote a saved preference")

  vim.bo.filetype = "text"
  assert(vim.wait(800, function() return _G.snacks_dashboard_logo_timer == nil end), "hidden dashboard retained its timer")
  second.select { kind = "shape", name = "trefoil", effect = "none" }
  assert(_G.snacks_dashboard_logo_timer == nil, "selecting away from the dashboard started a background animation")
  vim.bo.filetype = "snacks_dashboard"
  second.section()
  assert(_G.snacks_dashboard_logo_timer, "the chosen animation did not resume when the dashboard reopened")
end

local ok, err = xpcall(run, debug.traceback)
adapter.stop()
vim.env.XDG_STATE_HOME = previous_home
vim.fn.delete(temporary, "rf")
assert(ok, err)
print "dashboard selection: stable provider, replacement, persistence precedence and timer ownership passed"
