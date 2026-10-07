local M = {}

M.logos = require "dashboard-logo.logos"
M.effects = require "dashboard-logo.effects"

local function lines(name)
  name = name or M.logos.default
  assert(M.logos[name], "unknown dashboard logo: " .. name)
  return M.logos[name]
end

local function effect(name)
  name = name or M.effects.default
  assert(M.effects[name], "unknown dashboard logo effect: " .. name)
  return M.effects[name]
end

local function rgb(color)
  local red, green, blue = color:match "#(%x%x)(%x%x)(%x%x)"
  assert(red, "invalid RGB colour: " .. color)
  return tonumber(red, 16), tonumber(green, 16), tonumber(blue, 16)
end

---@param source? string
---@param filter? string
---@return string?
function M.filter_color(source, filter)
  if not filter then return source end
  local red, green, blue = rgb(source or "#ffffff")
  local filter_red, filter_green, filter_blue = rgb(filter)
  local luminance = (0.2126 * red + 0.7152 * green + 0.0722 * blue) / 255
  luminance = math.floor(luminance * 15 + 0.5) / 15
  return ("#%02x%02x%02x"):format(
    math.floor(filter_red * luminance + 0.5),
    math.floor(filter_green * luminance + 0.5),
    math.floor(filter_blue * luminance + 0.5)
  )
end

---@param name? string
---@return table[]
function M.render(name)
  local frame = {}
  local logo = lines(name)
  for i, line in ipairs(logo) do
    frame[i] = { line = line, segments = logo.segments[i] }
  end
  return frame
end

---@param state? table
---@param name? string
---@param effect_name? string
---@return table[]
function M.generate(state, name, effect_name)
  return effect(effect_name).apply(M.render(name), state or {})
end

---@param state? table
---@param name? string
---@param effect_name? string
---@return table
function M.advance(state, name, effect_name)
  state = state or {}
  local selected = effect(effect_name)
  if selected.advance then selected.advance(state, M.render(name)) end
  return state
end

---@param opts? { logo?: string, effect?: string, color?: string, update?: fun(frame: table[]) }
---@return table
function M.new(opts)
  opts = opts or {}
  local name = opts.logo or M.logos.default
  local effect_name = opts.effect or M.effects.default
  local selected = effect(effect_name)
  local rendered = M.render(name)
  local state = { color = opts.color }
  local update = opts.update or function() end
  local animation = { interval = selected.interval or 120 }

  function animation.frame() return selected.apply(rendered, state) end

  function animation.tick()
    if selected.advance then selected.advance(state, rendered) end
    local frame = animation.frame()
    update(frame)
    return frame
  end

  return animation
end

return M
