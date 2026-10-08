local M = {}

local function get_state()
  if vim.bo.filetype ~= "neo-tree" then return nil end
  local ok, manager = pcall(require, "neo-tree.sources.manager")
  if not ok then return nil end
  local state = manager.get_state("filesystem")
  if not state or state.bufnr ~= vim.api.nvim_get_current_buf() or not state.tree then return nil end
  return state
end

local function has_node()
  local state = get_state()
  local node = state and state.tree:get_node()
  return node ~= nil and (node.type == "file" or node.type == "directory")
end

local function has_clipboard()
  local state = get_state()
  return state ~= nil and next(state.clipboard or {}) ~= nil
end

local function run(command)
  local state = get_state()
  if not state then return end
  local ok, err = pcall(function()
    require("neo-tree.sources.filesystem.commands")[command](state)
  end)
  if not ok then vim.notify("Neo-tree clipboard: " .. tostring(err), vim.log.levels.ERROR) end
end

-- Let Neo-tree own clipboard state, highlights, destination prompts and filesystem refreshes.
function M.cut_file() if has_node() then run("cut_to_clipboard") end end
function M.paste_file() if has_node() and has_clipboard() then run("paste_from_clipboard") end end
function M.clear_cut() run("clear_clipboard") end

M.menus = {
  { label = "Cut", command = "<Cmd>lua require('plugins.popups.neotree').cut_file()<CR>", condition = has_node, modes = { "n" } },
  { label = "Paste", command = "<Cmd>lua require('plugins.popups.neotree').paste_file()<CR>", condition = function() return has_node() and has_clipboard() end, modes = { "n" } },
  { label = "Clear clipboard", command = "<Cmd>lua require('plugins.popups.neotree').clear_cut()<CR>", condition = has_clipboard, modes = { "n" } },
}
return M
