local logo = require "dashboard-logo"

local M = {}
local highlights = {}
local filtered_colors = {}

local function dashboard_visible()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "snacks_dashboard" then return true end
  end
  return false
end

local function color(value)
  if type(value) == "number" then return ("#%06x"):format(value) end
  return value
end

local function highlight(color, glow)
  if not color then return nil end
  local name = "DashboardLogo" .. color:sub(2) .. (glow and "Glow" or "")
  if not highlights[name] then
    vim.api.nvim_set_hl(0, name, { fg = color, ctermfg = glow and 120 or 37 })
    highlights[name] = true
  end
  return name
end

-- A frame is often requested more than once before the next timer tick. Keep
-- the tint calculation out of that hot path; filter_color parses both hex
-- colours and performs floating-point luminance math on every call.
local function filtered_color(source, filter)
  if not filter then return source end
  local key = (source or "") .. "\0" .. filter
  local cached = filtered_colors[key]
  if cached == nil then
    cached = logo.filter_color(source, filter) or false
    filtered_colors[key] = cached
  end
  return cached ~= false and cached or nil
end

function M.stop()
  if not _G.snacks_dashboard_logo_timer then return end
  _G.snacks_dashboard_logo_timer:stop()
  _G.snacks_dashboard_logo_timer:close()
  _G.snacks_dashboard_logo_timer = nil
end

---@param opts? { logo?: string, effect?: string, color?: string|integer, update?: fun(frame: table[]) }
---@return { section: fun(): table, stop: fun() }
function M.setup(opts)
  opts = opts or {}
  local frame
  local section_cache
  local section_cache_frame
  local animation = logo.new {
    logo = opts.logo,
    effect = opts.effect,
    color = color(opts.color),
    update = function(next_frame)
      frame = next_frame
      if opts.update then opts.update(next_frame) end
    end,
  }
  frame = animation.frame()

  local function start()
    if _G.snacks_dashboard_logo_timer then return end
    _G.snacks_dashboard_logo_timer = vim.uv.new_timer()
    _G.snacks_dashboard_logo_timer:start(animation.interval, animation.interval, vim.schedule_wrap(function()
      if not dashboard_visible() then
        M.stop()
        return
      end
      animation.tick()
    end))
  end

  local function section()
    start()
    if section_cache_frame == frame then return section_cache end

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
    section_cache_frame = frame
    section_cache = { text = text, pane = 1, align = "center", indent = 0, padding = 4 }
    return section_cache
  end

  M.stop()
  return { section = section, stop = M.stop }
end

return M
