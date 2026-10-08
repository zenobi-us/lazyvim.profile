---@class MenuOptions
---@field condition? fun(predicates: table): boolean
---@field min_menu_item_width? integer
---@field submenu_indicator? string
---@field show_help? boolean

---@class MenuItem
---@field label? string Required for actions and submenus
---@field command? string Single-line menu RHS (key sequence or <Cmd> action)
---@field items? MenuItem[]
---@field separator? boolean
---@field condition? fun(predicates: table): boolean
---@field options? MenuOptions
---@field modes? string[]

---@class PopupOptions: MenuOptions
---@field menus table<string, MenuItem[]> Map of owned menu roots to ordered items
---@field debug? boolean

local M = {}
M.isMenuItemWithSubmenu = function(item) return type(item) == "table" and type(item.items) == "table" end
M.isMenuItemWithCommand = function(item) return type(item) == "table" and type(item.command) == "string" end
M.isMenuItemSeparator = function(item) return type(item) == "table" and item.separator == true end
M.isMenuItem = function(item)
  return M.isMenuItemWithSubmenu(item) or M.isMenuItemWithCommand(item) or M.isMenuItemSeparator(item)
end
M.isMenuOptions = function(options) return type(options) == "table" end
return M
