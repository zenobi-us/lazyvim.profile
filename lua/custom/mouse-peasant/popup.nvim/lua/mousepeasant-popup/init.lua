local M = {}
M.constants = require("mousepeasant-popup.constants")
M.predicate = require("mousepeasant-popup.predicate")
M.render = require("mousepeasant-popup.render")
M.opts = vim.deepcopy(M.constants.DEFAULTS)
local owned_roots = {}

function M.refresh()
  -- Compile first: invalid definitions must not destroy the existing menus.
  local ok, commands, roots = pcall(M.render.compile, M.opts.menus, M.opts)
  if not ok then
    vim.notify("Popup configuration error: " .. tostring(commands), vim.log.levels.ERROR)
    return false
  end
  for root in pairs(owned_roots) do vim.cmd(M.render.clear_menu(root)) end
  for root in pairs(roots) do vim.cmd(M.render.clear_menu(root)) end
  owned_roots = roots
  for _, command in ipairs(commands) do vim.cmd(command) end
  return true
end

function M.setup(opts)
  M.opts = vim.tbl_extend("force", M.constants.DEFAULTS, opts or {})
  local group = vim.api.nvim_create_augroup("MousePeasantPopup", { clear = true })
  vim.api.nvim_create_autocmd("MenuPopup", {
    group = group,
    callback = function() M.refresh() end,
    desc = "Rebuild contextual mouse menus before opening",
  })
  M.refresh()
end
M.config = M.setup
return M
