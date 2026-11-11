-- Uses the installed Snacks dependency, real windows, timers and isolated preferences.
local script = arg[0]:gsub("\\", "/")
local root = script:match "^(.*)/tests/[^/]+$" or "."
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path
local snacks_path = vim.env.SNACKS_PATH or vim.fn.stdpath("data") .. "/lazy/snacks.nvim"
assert(vim.fn.isdirectory(snacks_path) == 1, "install Snacks or set SNACKS_PATH for this integration check")
vim.opt.rtp:append(snacks_path)
require("snacks").setup { picker = { enabled = true }, dashboard = { enabled = false }, notifier = { enabled = true } }
local adapter = require "dashboard-logo.snacks"
local gallery = require "dashboard-logo.picker"
local selection = require "dashboard-logo.selection"
local previous_home = vim.env.XDG_STATE_HOME
local temporary = vim.fn.tempname()
vim.env.XDG_STATE_HOME = temporary .. "/state"
vim.o.columns, vim.o.lines = 140, 50
local picker

local function await(predicate, message)
  assert(vim.wait(2000, predicate, 10), message)
end

local function preview_text(instance)
  local preview = instance.preview
  if instance.closed or not preview or not preview.win:valid() then return "" end
  return table.concat(vim.api.nvim_buf_get_lines(preview.win.buf, 0, -1, false), "\n")
end

local function choose(instance, query, kind, name, effect)
  instance.input:set(query)
  instance:find()
  await(function()
    local item = instance:current()
    return item and item.kind == kind and item.name == name and item.effect == effect and instance.list:count() == 1
  end, "gallery did not filter to " .. query)
  instance:show_preview()
end

local function visible(instance)
  await(function()
    return not instance.closed and not instance.layout:is_hidden("preview") and preview_text(instance):find("%S")
  end, "animated preview did not become visible")
end

local function timer_count()
  local count = 0
  vim.uv.walk(function(handle)
    if handle:get_type() == "timer" and not handle:is_closing() and handle:is_active() then
      count = count + 1
    end
  end)
  return count
end

local function run()
  local integration = adapter.setup { shape = "torus", effect = "none", color = "#61afef" }
  picker = adapter.pick()
  await(function() local item = picker:current(); return item and item.current and item.name == "torus" end,
    "gallery did not focus the current choice")
  choose(picker, "shape trefoil none", "shape", "trefoil", "none")
  visible(picker)
  local before = preview_text(picker)
  await(function() return preview_text(picker) ~= before end, "preview did not animate without a dashboard window")
  assert(integration.current().name == "torus", "browsing changed the dashboard")
  assert(selection.load() == nil, "browsing saved a default")
  picker:close()
  assert(integration.current().name == "torus", "cancelling applied the highlighted choice")
  vim.wait(200)

  picker = adapter.pick()
  choose(picker, "logo neovim sonar", "logo", "neovim", "sonar")
  picker:action("confirm")
  await(function() return picker.closed end, "confirmation did not close the gallery")
  assert(vim.deep_equal(integration.current(), { kind = "logo", name = "neovim", effect = "sonar" }), "confirmation did not apply both source and effect")
  assert(selection.load() == nil, "Enter persisted a session-only choice")

  picker = adapter.pick()
  choose(picker, "shape dna none", "shape", "dna", "none")
  picker:action("dashboard_save")
  await(function() return picker.closed end, "save did not close the gallery")
  assert(vim.deep_equal(selection.load(), { kind = "shape", name = "dna", effect = "none" }), "save did not persist the selected combination")
  integration = adapter.setup { shape = "iris", color = "#61afef" }
  assert(integration.current().name == "dna", "reloading the integration ignored the saved default")

  picker = adapter.pick()
  choose(picker, "shape trefoil none", "shape", "trefoil", "none")
  visible(picker)
  vim.o.columns, vim.o.lines = 80, 24
  vim.api.nvim_exec_autocmds("VimResized", {})
  await(function() return picker.layout:is_hidden("preview") end, "small terminal kept a cropped preview")
  vim.o.columns, vim.o.lines = 140, 50
  vim.api.nvim_exec_autocmds("VimResized", {})
  visible(picker)
  before = preview_text(picker)
  await(function() return preview_text(picker) ~= before end, "preview did not resume after resizing")
  picker.input:set("nothing-matches-this-dashboard")
  picker:find()
  await(function() return picker:current() == nil and picker.layout:is_hidden("preview") end, "empty results kept a stale preview")
  picker:close()

  local blocker = temporary .. "/blocked"
  vim.fn.writefile({ "keep this file" }, blocker)
  vim.env.XDG_STATE_HOME = blocker .. "/state"
  picker = adapter.pick()
  choose(picker, "shape globe glitch", "shape", "globe", "glitch")
  picker:action("dashboard_save")
  assert(not picker.closed and integration.current().name == "dna", "failed save applied or closed the gallery")
  assert(vim.fn.readfile(blocker)[1] == "keep this file", "failed save damaged an existing file")
  picker:close()
  vim.env.XDG_STATE_HOME = temporary .. "/state"
  assert(selection.load().name == "dna", "failed save damaged the previous preference")
  local reported = false
  for _, notification in ipairs(Snacks.notifier.get_history()) do
    if notification.msg:find("Could not save dashboard logo", 1, true) then reported = true end
  end
  assert(reported, "failed save did not report an error")
  Snacks.notifier.hide()
  vim.wait(200)
  -- Take the baseline after lazy notification timers have been initialized.
  local idle_timers = timer_count()

  for _ = 1, 3 do
    local previous = adapter.pick()
    visible(previous)
    picker = adapter.pick()
    assert(previous.closed, "opening another gallery left the previous one alive")
    visible(picker)
    picker:close()
    vim.wait(200)
  end
  assert(timer_count() <= idle_timers, "repeated galleries leaked active timers")
end

local ok, err = xpcall(run, debug.traceback)
gallery.close()
adapter.stop()
vim.env.XDG_STATE_HOME = previous_home
vim.fn.delete(temporary, "rf")
assert(ok, err)
print "Snacks gallery: live preview, cancel, apply, save, resize, empty results, failures and cleanup passed"
