vim.opt.runtimepath:append(vim.fn.getcwd() .. "/lua/custom/mouse-peasant/popup.nvim")
package.path = vim.fn.getcwd() .. "/lua/?.lua;" .. package.path
local popup = require("mousepeasant-popup")
local render = popup.render
local visible = true
local menus = {
  TestPopup = {
    { label = "文件", command = "<Nop>" },
    { label = "A.B | C & D\\E", command = "<Nop>" },
    { label = "Conditional", condition = function() return visible end, command = "<Nop>" },
    { separator = true },
    { separator = true },
    { label = "Sub", items = { { label = "Child", command = "<Nop>" } } },
    { label = "Sub", items = { { label = "Other", command = "<Nop>" } } },
  },
}
local snapshot = vim.deepcopy(menus)
assert(vim.fn.strdisplaywidth(render.label(menus.TestPopup[1])) == 30)
assert(render.label({ label = string.rep("X", 40), command = "<Nop>" }) == string.rep("X", 40))
assert(vim.fn.strdisplaywidth(render.label({ label = "Sub", items = {} })) == 30)
assert(render.label({ label = "Short", command = string.rep("X", 100) }):find("X") == nil)
local commands, roots = render.compile(menus)
assert(roots.TestPopup_submenu_6 and roots.TestPopup_submenu_7)
assert(vim.deep_equal(snapshot, menus), "Compiler mutated definitions")
popup.setup({ menus = menus })
assert(vim.deep_equal(snapshot, menus), "Setup mutated definitions")
local function dump(root)
  return vim.api.nvim_exec2("menu " .. root, { output = true }).output
end
assert(dump("TestPopup"):find("Conditional"))
assert(dump("TestPopup"):find("A.B | C & D\\E", 1, true))
visible = false
vim.api.nvim_exec_autocmds("MenuPopup", { group = "MousePeasantPopup" })
assert(not dump("TestPopup"):find("Conditional"), "Condition not refreshed")
popup.setup({ menus = menus })
assert(#vim.api.nvim_get_autocmds({ group = "MousePeasantPopup" }) == 1)
popup.setup({ menus = {} })
assert(not pcall(dump, "TestPopup_submenu_6"), "Stale submenu remains")
assert(not pcall(render.compile, { Bad = { { label = "Bad", command = "one\ntwo" } } }))
assert(not pcall(render.compile, { Bad = { { label = "Bad", command = "<Nop>", modes = { "invalid" } } } }))
local notices = {}
local notify = vim.notify
vim.notify = function(message) notices[#notices + 1] = message end
assert(not render.should_menu_item_display({ condition = function() error("test failure") end }))
vim.notify = notify
assert(#notices == 1)
-- Clipboard actions stay with Neo-tree, without touching files or installing BufLeave hooks.
local state = { bufnr = vim.api.nvim_get_current_buf(), clipboard = {} }
state.tree = { get_node = function() return { type = "file" } end }
local calls = {}
package.loaded["neo-tree.sources.manager"] = { get_state = function() return state end }
package.loaded["neo-tree.sources.filesystem.commands"] = {
  cut_to_clipboard = function(s) assert(s == state); calls[#calls + 1] = "cut"; s.clipboard.file = {} end,
  paste_from_clipboard = function(s) assert(s == state); calls[#calls + 1] = "paste" end,
  clear_clipboard = function(s) assert(s == state); calls[#calls + 1] = "clear"; s.clipboard = {} end,
}
vim.bo.filetype = "neo-tree"
local tree = require("plugins.popups.neotree")
assert(not tree.menus[2].condition())
tree.cut_file()
assert(tree.menus[2].condition())
tree.paste_file()
tree.clear_cut()
assert(vim.deep_equal(calls, { "cut", "paste", "clear" }))
vim.bo.filetype = "lua"
assert(not tree.menus[1].condition())
local get_clients = vim.lsp.get_clients
vim.lsp.get_clients = function() return {} end
local lsp = require("plugins.popups.lsp").menus
assert(not lsp.condition(popup.predicate))
assert(not lsp.items[1].condition())
vim.lsp.get_clients = function()
  return { { supports_method = function(_, method) return method == "textDocument/hover" end } }
end
assert(lsp.condition(popup.predicate))
assert(lsp.items[1].condition())
assert(not lsp.items[2].condition())
assert(lsp.items[1].command:find("vim.lsp.buf.hover()", 1, true))
vim.lsp.get_clients = get_clients
print("Popup tests passed")
