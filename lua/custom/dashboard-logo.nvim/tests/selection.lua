-- Run with: nvim -u NONE -l tests/selection.lua (from the plugin directory).
-- Every filesystem operation stays beneath a temporary XDG_STATE_HOME.
local script = arg[0]:gsub("\\", "/")
local root = script:match "^(.*)/tests/[^/]+$" or "."
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path
local selection = require "dashboard-logo.selection"
local logo = require "dashboard-logo"
local uv = vim.uv or vim.loop
local previous_state_home = vim.env.XDG_STATE_HOME
local temporary = vim.fn.tempname()
assert(vim.fn.mkdir(temporary, "p") == 1)
vim.env.XDG_STATE_HOME = temporary .. "/state"

local function equal(actual, expected)
  assert(vim.deep_equal(actual, expected), "expected " .. vim.inspect(expected) .. ", got " .. vim.inspect(actual))
end

local function rejected(value, err, field)
  assert(value == nil, "invalid selection was accepted")
  assert(type(err) == "string" and #err > 0, "failure did not return an error")
  if field then assert(err:find(field, 1, true), "error did not identify " .. field .. ": " .. err) end
end

local function write_file(path, content)
  local file = assert(io.open(path, "wb"))
  assert(file:write(content))
  assert(file:close())
end

local function read_file(path)
  local file = assert(io.open(path, "rb"))
  local content = assert(file:read "*a")
  assert(file:close())
  return content
end

local function run()
  local path = selection.path()
  assert(path:sub(1, #temporary + 1) == temporary .. "/", "state escaped the isolated directory")
  assert(path == vim.fn.stdpath "state" .. "/dashboard-logo.json")
  local missing, missing_err = selection.load()
  assert(missing == nil and missing_err == nil, "missing state is not an error")

  equal(assert(selection.from_options()), { kind = "logo", name = logo.logos.default, effect = "glitch" })
  equal(assert(selection.from_options { shape = "torus" }), { kind = "shape", name = "torus", effect = "none" })
  equal(assert(selection.from_options { logo = "neovim" }), { kind = "logo", name = "neovim", effect = "glitch" })
  equal(assert(selection.from_options { shape = "torus", effect = "sonar", color = "#aabbcc" }),
    { kind = "shape", name = "torus", effect = "sonar" })
  local value, err = selection.from_options { shape = "torus", logo = "neovim" }
  rejected(value, err, "not both")
  value, err = selection.from_options(false)
  rejected(value, err, "options")
  value, err = selection.from_options { shape = false }
  rejected(value, err, "name")
  value, err = selection.from_options { effect = false }
  rejected(value, err, "effect")

  local normalized = { kind = "shape", name = "torus", effect = "sonar" }
  local input = { kind = "shape", name = "torus", effect = "sonar", color = "#abcdef", extra = true }
  equal(assert(selection.validate(input)), normalized)
  assert(input.color == "#abcdef", "validation mutated its input")

  local invalid = {
    false,
    {},
    { kind = "other", name = "torus", effect = "none" },
    { kind = "shape", name = "removed_shape", effect = "none" },
    { kind = "logo", name = "removed_logo", effect = "none" },
    { kind = "logo", name = "default", effect = "none" },
    { kind = "logo", name = "neovim", effect = "default" },
    { kind = "logo", name = "neovim", effect = "removed_effect" },
    { kind = "logo", name = "neovim" },
  }
  for _, candidate in ipairs(invalid) do
    value, err = selection.validate(candidate)
    rejected(value, err)
  end

  local saved, save_err = selection.save(input)
  assert(saved == true and save_err == nil, tostring(save_err))
  local original = read_file(path)
  equal(vim.json.decode(original), normalized)
  assert(not original:find("color", 1, true) and not original:find("extra", 1, true), "persisted transient fields")
  local loaded, load_err = selection.load()
  equal(loaded, normalized)
  assert(load_err == nil)
  for _, candidate in ipairs(invalid) do
    value, err = selection.save(candidate)
    rejected(value, err)
    assert(read_file(path) == original, "failed validation destroyed the saved preference")
  end

  -- A real write failure must not truncate the old preference. Root bypasses these permissions.
  local directory = vim.fn.fnamemodify(path, ":h")
  if uv.getuid() ~= 0 then
    assert(uv.fs_chmod(directory, 320)) -- 0500: readable/searchable, but no temporary file creation.
    local called, result, failure = pcall(selection.save, { kind = "logo", name = "neovim", effect = "none" })
    assert(uv.fs_chmod(directory, 448)) -- 0700, restored before any assertions can fail.
    assert(called, tostring(result))
    rejected(result, failure, "temporary")
    assert(read_file(path) == original, "failed write destroyed the saved preference")
  end

  write_file(path, "{broken JSON")
  value, err = selection.load()
  rejected(value, err, "JSON")
  for _, candidate in ipairs(invalid) do
    write_file(path, vim.json.encode(candidate))
    value, err = selection.load()
    rejected(value, err, "preference")
  end
  write_file(path, "null")
  value, err = selection.load()
  rejected(value, err, "preference")
  write_file(path, "[]")
  value, err = selection.load()
  rejected(value, err, "preference")

  assert(selection.save(normalized))
  original = read_file(path)
  -- A regular-file ancestor prevents directory creation without relying on permissions.
  local blocker = temporary .. "/blocked"
  write_file(blocker, "leave this file intact")
  vim.env.XDG_STATE_HOME = blocker .. "/state"
  value, err = selection.save(normalized)
  rejected(value, err)
  assert(read_file(blocker) == "leave this file intact")
  vim.env.XDG_STATE_HOME = temporary .. "/state"
  assert(read_file(path) == original, "failed directory creation touched the old preference")

  -- Force rename failure after writing the temporary file; the target and its content survive.
  assert(uv.fs_unlink(path))
  assert(uv.fs_mkdir(path, 448))
  write_file(path .. "/marker", original)
  value, err = selection.save(normalized)
  rejected(value, err, "save")
  assert(read_file(path .. "/marker") == original, "failed rename destroyed its destination")
  equal(vim.fn.glob(path .. ".*", false, true), {})

  assert(vim.fn.delete(path, "rf") == 0)
  local replacement = { kind = "logo", name = "neovim", effect = "none" }
  assert(selection.save(normalized))
  assert(selection.save(replacement))
  equal(assert(selection.load()), replacement)
  equal(vim.fn.glob(path .. ".*", false, true), {})
end

local ok, err = xpcall(run, debug.traceback)
vim.env.XDG_STATE_HOME = previous_state_home
local cleaned = vim.fn.delete(temporary, "rf")
assert(ok, err)
assert(cleaned == 0, "could not remove isolated state")
print("selection: defaults, validation, isolated persistence, corruption and failed-save preservation passed")
