-- Jump to whatever is under the cursor.
--
-- Order of attempts:
--   1. LSP definition, when an attached client supports it.
--   2. The file path under the cursor, for import statements.
--   3. The declaration in the current file (`gd`).
--
-- Step 2 exists because a buffer with no language server still shows import
-- paths, and a path is enough to open the file.

local M = {}

-- Tried in order against the resolved path, before the index names below.
local SUFFIXES = {
  "",
  ".ts",
  ".tsx",
  ".d.ts",
  ".js",
  ".jsx",
  ".mjs",
  ".cjs",
  ".lua",
  ".json",
  ".css",
  ".scss",
  ".vue",
  ".svelte",
  ".md",
}

local INDEXES = {
  "/index.ts",
  "/index.tsx",
  "/index.js",
  "/index.jsx",
  "/index.lua",
}

local QUOTES = { "'", '"', "`" }

local function lsp_supports_definition(bufnr)
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if client:supports_method("textDocument/definition", bufnr) then return true end
  end
  return false
end

local function first_readable(base)
  for _, suffix in ipairs(SUFFIXES) do
    local candidate = base .. suffix
    if vim.fn.filereadable(candidate) == 1 then return candidate end
  end
  if vim.fn.isdirectory(base) == 1 then
    for _, index in ipairs(INDEXES) do
      local candidate = base .. index
      if vim.fn.filereadable(candidate) == 1 then return candidate end
    end
  end
  return nil
end

-- `expand("<cfile>")` stops at any character outside `isfname`, which drops the
-- leading `@` of a scoped package. Read the quoted span around the cursor first.
local function quoted_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  for _, quote in ipairs(QUOTES) do
    local from = 1
    while true do
      local open_at = line:find(quote, from, true)
      if not open_at then break end
      local close_at = line:find(quote, open_at + 1, true)
      if not close_at then break end
      if col > open_at and col < close_at then return line:sub(open_at + 1, close_at - 1) end
      from = close_at + 1
    end
  end
  return nil
end

-- A package entry point. `source` first, because monorepo packages point it at
-- TypeScript while `main` points at a build output that may not exist yet.
local ENTRY_FIELDS = { "source", "module", "main", "types" }

local function package_entry(package_json)
  local ok, text = pcall(vim.fn.readfile, package_json)
  if not ok then return nil end
  local decoded, manifest = pcall(vim.json.decode, table.concat(text, "\n"))
  if not decoded or type(manifest) ~= "table" then return nil end
  local dir = vim.fs.dirname(package_json)
  for _, field in ipairs(ENTRY_FIELDS) do
    local value = manifest[field]
    if type(value) == "string" then
      local entry = first_readable(vim.fs.normalize(dir .. "/" .. value))
      if entry then return entry end
    end
  end
  return first_readable(dir .. "/src")
end

-- A bare specifier such as `@balance-web/checkbox` lives in a `node_modules`
-- directory somewhere above the current file. Workspace packages are symlinked
-- there, so this reaches monorepo source as well as published packages.
local function resolve_package(spec, start_dir)
  local found = vim.fs.find("node_modules", { path = start_dir, upward = true, type = "directory", limit = 10 })
  for _, modules in ipairs(found) do
    local base = modules .. "/" .. spec
    local file = first_readable(base)
    if file then return file end
    local package_json = base .. "/package.json"
    if vim.fn.filereadable(package_json) == 1 then return package_entry(package_json) or package_json end
  end
  return nil
end

local function resolve_path(thing, bufnr)
  if not thing or thing == "" then return nil end
  local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
  if dir == "" then dir = assert(vim.uv.cwd()) end

  if thing:sub(1, 1) == "/" then return first_readable(thing) end
  if thing:sub(1, 1) == "~" then return first_readable(vim.fn.expand(thing)) end
  if thing:sub(1, 1) == "." then return first_readable(vim.fs.normalize(dir .. "/" .. thing)) end

  -- Relative to the current file first, then as a package specifier.
  return first_readable(vim.fs.normalize(dir .. "/" .. thing)) or resolve_package(thing, dir)
end

--- Jump to the definition, the imported file, or the local declaration.
--- @param method string LSP method: "definition" or "type_definition".
function M.goto_thing(method)
  method = method or "definition"
  local bufnr = vim.api.nvim_get_current_buf()

  if lsp_supports_definition(bufnr) then
    vim.lsp.buf[method]()
    return
  end

  local thing = quoted_under_cursor() or vim.fn.expand("<cfile>")
  local target = resolve_path(thing, bufnr)
  if target then
    vim.cmd.edit(vim.fn.fnameescape(target))
    return
  end

  local before = vim.api.nvim_win_get_cursor(0)
  pcall(vim.cmd, "normal! gd")
  local after = vim.api.nvim_win_get_cursor(0)
  if before[1] == after[1] and before[2] == after[2] then
    vim.notify("No definition and no file for " .. tostring(thing), vim.log.levels.WARN, { title = "goto-thing" })
  end
end

return M
