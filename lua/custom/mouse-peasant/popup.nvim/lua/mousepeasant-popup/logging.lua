local M = {}

--- Get the init module (lazy-loaded to avoid circular dependencies)
local function get_init()
  return require "mousepeasant-popup"
end

--- Log a message if debug mode is enabled
--- @param message string The message to log
--- @param level? integer The log level (default: vim.log.levels.INFO)
M.log = function(message, level)
  local init = get_init()
  if not init.opts.debug then
    return
  end
  level = level or vim.log.levels.INFO
  vim.notify("[PopUp DEBUG] " .. message, level)
end

--- Log an error message if debug mode is enabled
--- @param message string The error message
M.error = function(message)
  M.log(message, vim.log.levels.ERROR)
end

--- Log a warning message if debug mode is enabled
--- @param message string The warning message
M.warn = function(message)
  M.log(message, vim.log.levels.WARN)
end

--- Log an info message if debug mode is enabled
--- @param message string The info message
M.info = function(message)
  M.log(message, vim.log.levels.INFO)
end

--- Log a debug message if debug mode is enabled
--- @param message string The debug message
M.debug = function(message)
  M.log(message, vim.log.levels.DEBUG)
end

--- Log a trace message if debug mode is enabled
--- @param message string The trace message
M.trace = function(message)
  M.log(message, vim.log.levels.TRACE)
end

return M
