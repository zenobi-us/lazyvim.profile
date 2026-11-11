-- Both Snacks surfaces use identical source shading, effect filters and highlights.
local logo = require "dashboard-logo"
local M = {}
local highlights, filtered_colors = {}, {}
local namespace = vim.api.nvim_create_namespace "dashboard-logo.preview"
local highlight, filtered_color

function M.chunks(frame)
  local text = {}
  for i, item in ipairs(frame) do
    for _, segment in ipairs(item.segments) do
      local hl = highlight(filtered_color(segment.color, item.filter), item.glow)
      local previous = text[#text]
      if previous and previous.hl == hl and not previous[1]:find("\n", 1, true) then
        previous[1] = previous[1] .. segment.text
      else
        text[#text + 1] = { segment.text, hl = hl }
      end
    end
    if i < #frame then text[#text][1] = text[#text][1] .. "\n" end
  end
  return text
end

function M.draw(buf, win, frame)
  if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win) then return false end
  local width, height = vim.api.nvim_win_get_width(win), vim.api.nvim_win_get_height(win)
  local frame_width = 0
  for _, item in ipairs(frame) do frame_width = math.max(frame_width, #item.line) end
  if frame_width > width or #frame > height then return false end
  local left, top = math.floor((width - frame_width) / 2), math.floor((height - #frame) / 2)
  local lines = {}
  for row = 1, height do lines[row] = "" end
  for row, item in ipairs(frame) do lines[top + row] = (" "):rep(left) .. item.line end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
  for row, item in ipairs(frame) do
    local column = left
    for _, segment in ipairs(item.segments) do
      local hl = highlight(filtered_color(segment.color, item.filter), item.glow)
      if hl and #segment.text > 0 then
        vim.api.nvim_buf_set_extmark(buf, namespace, top + row - 1, column, {
          end_col = column + #segment.text, hl_group = hl,
        })
      end
      column = column + #segment.text
    end
  end
  vim.bo[buf].modifiable = false
  return true
end

highlight = function(color, glow)
  if not color then return nil end
  local name = "DashboardLogo" .. color:sub(2) .. (glow and "Glow" or "")
  if not highlights[name] then
    vim.api.nvim_set_hl(0, name, { fg = color, ctermfg = glow and 120 or 37 })
    highlights[name] = true
  end
  return name
end

-- Filtering parses RGB values, so cache it across frames and both surfaces.
filtered_color = function(source, filter)
  if not filter then return source end
  local key = (source or "") .. "\0" .. filter
  local cached = filtered_colors[key]
  if cached == nil then
    cached = logo.filter_color(source, filter) or false
    filtered_colors[key] = cached
  end
  return cached ~= false and cached or nil
end

return M
