local M = {}

local ns = vim.api.nvim_create_namespace("keymap-probe")
local state

local groups = {
  { "NAVIGATION", { "h", "j", "k", "l", "w", "b", "g", "G", "<Left>", "<Right>", "<Home>", "<End>" } },
  { "MODIFIERS", { "<C-a>", "<C-S-a>", "<M-a>", "<C-Left>", "<M-Left>", "<S-Tab>" } },
  { "SEQUENCES", { "gg", "dd", "<C-w>h" } },
  { "SPECIAL", { "<Esc>", "<CR>", "<BS>", "<F1>", "<F5>", "<F12>" } },
}

local function termcode(key)
  return vim.api.nvim_replace_termcodes(key, true, true, true)
end

local function display(key)
  return key:gsub("<CR>", "<Enter>"):gsub("<BS>", "<Backspace>")
end

local function append(lines, text)
  lines[#lines + 1] = text
end

local function render()
  if not state or not vim.api.nvim_buf_is_valid(state.buf) then return end
  local lines = {
    "Keymap Probe  ·  press the selected key to test it",
    "Terminal: " .. (vim.env.TERM_PROGRAM or vim.env.TERM or "unknown") .. " · " .. (vim.uv.os_uname().sysname or "unknown") .. " · Neovim " .. vim.version().major .. "." .. vim.version().minor,
    "Keys: j/k move · Enter test selected · s start capture · c clear · y copy report · q close",
    "",
  }
  local positions = {}
  for _, group in ipairs(groups) do
    append(lines, "  " .. group[1])
    local row = "  "
    for _, key in ipairs(group[2]) do
      local cell = "[ " .. display(key) .. " ]"
      local col = #row
      row = row .. cell .. "  "
      positions[#positions + 1] = { key = key, row = #lines, col = col, len = #cell }
    end
    append(lines, row)
  end
  append(lines, "")
  append(lines, "Selected: " .. display(state.selected) .. "    Status: " .. state.status)
  append(lines, "Last received: " .. (state.last or "—") .. "    Mapping: " .. (state.mapping or "—") .. "    Result: " .. (state.result or "—"))
  append(lines, "")
  append(lines, "TIME      TESTED KEY       RECEIVED         MAPPED TO        RESULT")
  append(lines, string.rep("─", 76))
  for _, entry in ipairs(state.log) do
    append(lines, string.format("%-9s %-16s %-16s %-16s %s", entry.time, entry.tested, entry.received, entry.mapping, entry.result))
  end
  vim.bo[state.buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false
  state.positions = positions
  vim.api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)
  local selected = positions[state.index]
  if selected then
    vim.api.nvim_buf_add_highlight(state.buf, ns, "Visual", selected.row - 1, selected.col, selected.col + selected.len)
  end
  vim.api.nvim_buf_add_highlight(state.buf, ns, "Title", 0, 0, -1)
  vim.api.nvim_buf_add_highlight(state.buf, ns, "DiagnosticInfo", 1, 0, -1)
end

local function mapping_for(key)
  local ok, result = pcall(vim.fn.maparg, key, "n", false, true)
  if ok and type(result) == "table" and result.rhs and result.rhs ~= "" then return result.rhs end
  return "—"
end

local function log_result(received, result)
  local tested = state.selected
  local mapping = mapping_for(termcode(tested))
  state.last, state.mapping, state.result = received, mapping, result
  state.log[#state.log + 1] = {
    time = os.date("%H:%M:%S"), tested = display(tested), received = received,
    mapping = mapping, result = result,
  }
  state.status = "ready"
  render()
end

local function start_capture()
  if not state then return end
  state.status, state.last = "waiting for input…", nil
  render()
  local started = vim.uv.hrtime()
  local timer = vim.uv.new_timer()
  local finished = false
  local captured = {}
  local expected_count = (not state.selected:match("^<") and #state.selected > 1) and #state.selected or 1
  local function finish(key)
    if finished then return end
    finished = true
    pcall(vim.on_key, nil, ns)
    if not timer:is_closing() then timer:stop(); timer:close() end
    vim.schedule(function()
      if not state then return end
      if key then
        local received = vim.fn.keytrans(key)
        local expected = vim.fn.keytrans(termcode(state.selected))
        local result = received == expected and "received" or "different input"
        log_result(received, result)
      else
        log_result("(timeout)", "no input")
      end
    end)
  end
  vim.on_key(function(key)
    if key == "" or key == "\n" then return end
    captured[#captured + 1] = key
    if #captured >= expected_count then finish(table.concat(captured)) end
  end, ns)
  timer:start(2500, 0, function()
    if vim.uv.hrtime() - started >= 0 then finish(nil) end
  end)
end

local function close()
  if state then
    pcall(vim.on_key, nil, ns)
    if vim.api.nvim_buf_is_valid(state.buf) then vim.api.nvim_buf_delete(state.buf, { force = true }) end
    state = nil
  end
end

function M.open()
  if state and vim.api.nvim_buf_is_valid(state.buf) then
    vim.api.nvim_set_current_buf(state.buf)
    return
  end
  local buf = vim.api.nvim_create_buf(false, true)
  state = { buf = buf, index = 1, selected = groups[1][2][1], status = "ready", log = {} }
  vim.api.nvim_buf_set_name(buf, "Keymap Probe")
  vim.bo[buf].filetype = "keymapprobe"
  vim.bo[buf].buftype = "nofile"
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  local function map(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { buffer = buf, silent = true, desc = desc })
  end
  map("q", close, "Close keymap probe")
  map("<Esc>", close, "Close keymap probe")
  map("j", function() state.index = math.min(#state.positions, state.index + 1); state.selected = state.positions[state.index].key; render() end, "Next probe key")
  map("k", function() state.index = math.max(1, state.index - 1); state.selected = state.positions[state.index].key; render() end, "Previous probe key")
  map("<CR>", start_capture, "Test selected key")
  map("s", start_capture, "Start key capture")
  map("c", function() state.log = {}; state.status = "ready"; state.last = nil; render() end, "Clear probe log")
  map("y", function()
    local report = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
    vim.fn.setreg("+", report)
    vim.notify("Keymap Probe report copied", vim.log.levels.INFO)
  end, "Copy report")
  render()
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
end

return M
