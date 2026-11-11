-- Adapter-side selection validation and persistence; the renderer stays independent of Neovim.
local M = {}
local logo = require "dashboard-logo"
local uv = vim.uv or vim.loop

---Return a normalized selection, or nil and an error. Extra fields are discarded.
function M.validate(value)
  if type(value) ~= "table" then return nil, "Dashboard selection must be an object" end
  if value.kind ~= "shape" and value.kind ~= "logo" then
    return nil, "Dashboard selection kind must be 'shape' or 'logo'"
  end
  local registry = value.kind == "shape" and logo.shapes or logo.logos
  if type(value.name) ~= "string" or value.name == "default" or type(registry[value.name]) ~= "table" then
    return nil, "Dashboard selection name must be a registered " .. value.kind .. " (not the 'default' alias)"
  end
  if type(value.effect) ~= "string" or value.effect == "default" or type(logo.effects[value.effect]) ~= "table" then
    return nil, "Dashboard selection effect must be a registered effect (not the 'default' alias)"
  end
  return { kind = value.kind, name = value.name, effect = value.effect }
end

---Resolve renderer options, or return nil and an error; shape and logo are mutually exclusive.
function M.from_options(opts)
  if opts == nil then opts = {} end
  if type(opts) ~= "table" then return nil, "Dashboard options must be a table" end
  if opts.shape ~= nil and opts.logo ~= nil then
    return nil, "Select either a dashboard logo or a shape, not both"
  end
  local is_shape = opts.shape ~= nil
  local name
  if is_shape then name = opts.shape else name = opts.logo end
  if name == nil then name = logo.logos.default end
  local effect = opts.effect
  if effect == nil then effect = is_shape and "none" or logo.effects.default end
  return M.validate {
    kind = is_shape and "shape" or "logo",
    name = name,
    effect = effect,
  }
end

function M.path()
  return vim.fn.stdpath "state" .. "/dashboard-logo.json"
end

---Return the saved selection; a missing file returns nil, nil. Other failures return nil, error.
function M.load()
  local path = M.path()
  local fd, err, code = uv.fs_open(path, "r", 0)
  if not fd then
    if code == "ENOENT" then return nil, nil end
    return nil, "Cannot read dashboard preference: " .. tostring(err)
  end
  local stat, stat_err = uv.fs_fstat(fd)
  local content, read_err
  if stat then content, read_err = uv.fs_read(fd, stat.size, 0) end
  local closed, close_err = uv.fs_close(fd)
  if not stat or not content or not closed then
    return nil, "Cannot read dashboard preference: " .. tostring(stat_err or read_err or close_err)
  end
  local decoded, value = pcall(vim.json.decode, content)
  if not decoded then return nil, "Dashboard preference contains invalid JSON; choose and save a selection again" end
  local selection, validation_err = M.validate(value)
  if not selection then return nil, "Invalid dashboard preference: " .. validation_err end
  return selection
end

---Atomically replace the preference with normalized JSON. Return true, or nil and an error.
---The existing preference is never removed before its replacement is ready.
function M.save(value)
  local selection, err = M.validate(value)
  if not selection then return nil, err end
  local encoded, content = pcall(vim.json.encode, selection)
  if not encoded then return nil, "Cannot encode dashboard preference: " .. tostring(content) end
  local path = M.path()
  local directory = vim.fn.fnamemodify(path, ":h")
  local made, mkdir_err = pcall(vim.fn.mkdir, directory, "p")
  if not made then return nil, "Cannot create dashboard preference directory: " .. tostring(mkdir_err) end
  local fd, temporary, temporary_err = uv.fs_mkstemp(path .. ".XXXXXX")
  if not fd then return nil, "Cannot create dashboard preference temporary file: " .. tostring(temporary or temporary_err) end

  local offset = 0
  while offset < #content do
    local written, write_err = uv.fs_write(fd, content:sub(offset + 1), offset)
    if not written or written == 0 then
      err = write_err or "no bytes written"
      break
    end
    offset = offset + written
  end
  if not err then
    local synced, sync_err = uv.fs_fsync(fd)
    if not synced then err = sync_err end
  end
  local closed, close_err = uv.fs_close(fd)
  if not closed then err = err or close_err end
  if not err then
    local renamed, rename_err = uv.fs_rename(temporary, path)
    if not renamed then err = rename_err end
  end
  if err then
    uv.fs_unlink(temporary)
    return nil, "Cannot save dashboard preference: " .. tostring(err)
  end
  return true
end

return M
