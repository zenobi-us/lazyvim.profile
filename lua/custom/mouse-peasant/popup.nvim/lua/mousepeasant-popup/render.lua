local Constants = require("mousepeasant-popup.constants")
local Predicates = require("mousepeasant-popup.predicate")
local R = {}
local valid_modes = { n = true, v = true, x = true, s = true, o = true, i = true, c = true, a = true, t = true }

local function text(value, name)
  assert(type(value) == "string" and value ~= "" and not value:find("[%c]"), name .. " must be a nonempty single-line string")
  return value
end

local function escape_label(label)
  text(label, "Menu label")
  return (label:gsub("([\\ .|<>&])", "\\%1"))
end
R.escape_label = escape_label

R.clear_menu = function(root)
  return "silent! aunmenu " .. escape_label(root)
end

R.label = function(item, defaults)
  local options = vim.tbl_extend("force", Constants.DEFAULTS, defaults or {}, item.options or {})
  local label = text(item.label, "Menu label")
  local suffix = item.items and (options.submenu_indicator or "")
    or (options.show_help and item.command ~= "<Nop>" and item.command or "")
  local padding = math.max(0, options.min_menu_item_width - vim.fn.strdisplaywidth(label) - vim.fn.strdisplaywidth(suffix))
  return label .. string.rep(" ", padding) .. suffix
end

R.should_menu_item_display = function(item)
  local condition = item.condition or (item.options and item.options.condition)
  if condition == nil then return true end
  assert(type(condition) == "function", "Menu condition must be a function")
  local ok, result = pcall(condition, Predicates)
  if not ok then
    vim.notify("Popup condition failed: " .. tostring(result), vim.log.levels.ERROR)
    return false
  end
  return not not result
end

-- Compile without changing user definitions. Separate popup roots retain mouse-openable submenus.
R.compile = function(menus, options)
  local commands, roots = {}, {}
  local function walk(root, items, inherited, inherited_modes)
    assert(type(items) == "table", "Menu items must be a list")
    local output = {}
    for index, item in ipairs(items) do
      assert(type(item) == "table", "Menu item must be a table")
      if R.should_menu_item_display(item) then
        local opts = vim.tbl_extend("force", inherited, item.options or {})
        local modes = item.modes or inherited_modes or Constants.MODES
        local label, command
        if item.separator == true then
          label, command = "-separator" .. index .. "-", "<Nop>"
        elseif item.items ~= nil then
          local child_root = root .. "_submenu_" .. index
          local children = walk(child_root, item.items, opts, modes)
          if #children > 0 then
            roots[child_root] = true
            vim.list_extend(output, children)
            label = R.label(item, opts)
            command = "<Cmd>popup " .. escape_label(child_root) .. "<CR>"
          end
        else
          command = text(item.command, "Menu command")
          label = R.label(item, opts)
        end
        if label then
          for _, mode in ipairs(modes) do
            assert(valid_modes[mode], "Invalid menu mode: " .. tostring(mode))
            output[#output + 1] = mode .. "menu " .. escape_label(root) .. "." .. escape_label(label) .. " " .. command
          end
        end
      end
    end
    return output
  end
  local groups = vim.tbl_keys(menus)
  table.sort(groups)
  for _, root in ipairs(groups) do
    text(root, "Menu root")
    roots[root] = true
    vim.list_extend(commands, walk(root, menus[root], options or {}, nil))
  end
  return commands, roots
end

return R
