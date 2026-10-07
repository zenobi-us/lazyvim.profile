local script = debug.getinfo(1, "S").source:sub(2):gsub("\\", "/")
local root = script:match "^(.*)/tests/[^/]+$"
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path

local logo = require("dashboard-logo.snacks").setup()

logo.section()
assert(_G.snacks_dashboard_logo_timer)
assert(vim.wait(500, function() return _G.snacks_dashboard_logo_timer == nil end), "timer stayed active without dashboard")

vim.bo.filetype = "snacks_dashboard"
logo.section()
assert(_G.snacks_dashboard_logo_timer)
vim.wait(200)
assert(_G.snacks_dashboard_logo_timer, "timer stopped while dashboard was visible")

vim.bo.filetype = ""
assert(vim.wait(500, function() return _G.snacks_dashboard_logo_timer == nil end), "timer stayed active after dashboard closed")

print "dashboard logo lifecycle: ok"
