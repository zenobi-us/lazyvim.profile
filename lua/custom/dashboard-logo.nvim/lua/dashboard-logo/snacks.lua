local logo = require "dashboard-logo"
local display = require "dashboard-logo.display"
local selection = require "dashboard-logo.selection"

local M = {}
local active

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


function M.stop()
  if active then active.stop() end
end

function M.pick()
  assert(active, "call dashboard-logo.snacks.setup before opening the picker")
  return active.pick()
end

---@param opts? { logo?: string, shape?: string, effect?: string, color?: string|integer, update?: fun(frame: table[]) }
---@return table integration
function M.setup(opts)
  opts = opts or {}
  local configured, config_error = selection.from_options(opts)
  assert(configured, config_error)
  local saved, error_message = selection.load()
  if error_message then vim.notify("Ignoring saved dashboard selection: " .. error_message, vim.log.levels.WARN) end
  M.stop()

  local selected = saved or configured
  local tint = color(opts.color)
  local animation, frame, timer
  local section_cache, section_cache_frame
  local integration = {}
  local start

  local function stop()
    if not timer then return end
    timer:stop()
    timer:close()
    if _G.snacks_dashboard_logo_timer == timer then _G.snacks_dashboard_logo_timer = nil end
    timer = nil
  end

  local function replace(value)
    assert(active == integration, "this dashboard integration is no longer active")
    local validated, err = selection.validate(value)
    assert(validated, err)
    local next_animation = logo.new {
      shape = validated.kind == "shape" and validated.name or nil,
      logo = validated.kind == "logo" and validated.name or nil,
      effect = validated.effect,
      color = tint,
      update = function(next_frame)
        frame = next_frame
        if opts.update then opts.update(next_frame) end
      end,
    }
    stop()
    selected, animation = validated, next_animation
    frame = animation.frame()
    section_cache, section_cache_frame = nil, nil
  end

  start = function()
    if timer or active ~= integration then return end
    timer = vim.uv.new_timer()
    local running = timer
    _G.snacks_dashboard_logo_timer = running
    running:start(animation.interval, animation.interval, vim.schedule_wrap(function()
      -- A cancelled timer may already have a callback queued on Neovim's loop.
      if timer ~= running or running:is_closing() then return end
      if not dashboard_visible() then stop(); return end
      animation.tick()
    end))
  end

  function integration.section()
    start()
    if section_cache_frame == frame then return section_cache end
    section_cache_frame = frame
    section_cache = { text = display.chunks(frame), pane = 1, align = "center", indent = 0, padding = 4 }
    return section_cache
  end

  function integration.current()
    return { kind = selected.kind, name = selected.name, effect = selected.effect }
  end

  function integration.select(value)
    replace(value)
    if dashboard_visible() then
      start()
      if opts.update then opts.update(frame) end
    end
  end

  function integration.pick()
    return require("dashboard-logo.picker").open {
      current = integration.current, apply = integration.select, color = tint,
    }
  end

  integration.stop = stop
  active = integration
  replace(selected)
  return integration
end

return M
