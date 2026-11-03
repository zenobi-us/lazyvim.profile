-- Per-cell colours let both frontends draw a ring without moving the ASCII art.
local M = { interval = 80 }

local levels = 24
local trail = 5
local speed = 0.75
local default_color = "#65ffc1"
local prepare

function M.apply(frame, state)
  local cache = prepare(frame, state)
  local radius = (state.sonar_step or 0) * speed
  local effected = {}
  for i, item in ipairs(frame) do
    local segments = {}
    local row = cache.rows[i]
    local first, previous_color = 1, nil
    for x, cell in ipairs(row.cells) do
      local age = radius - cell.distance
      local strength = age >= -speed and age < 0 and (1 + age / speed)
        or (age >= 0 and math.max(0, 1 - age / trail) ^ 2 or 0)
      local level = math.floor(strength * (levels - 1) + 0.5) + 1
      local color = cell.palette[level]
      if x > 1 and color ~= previous_color then
        segments[#segments + 1] = { text = item.line:sub(first, x - 1), color = previous_color }
        first = x
      end
      previous_color = color
    end
    segments[#segments + 1] = { text = item.line:sub(first), color = previous_color }
    effected[i] = { line = item.line, segments = segments }
  end
  return effected
end

function M.advance(state, frame)
  local cache = prepare(frame, state)
  state.sonar_step = ((state.sonar_step or 0) + 1) % cache.period
end

local function rgb(color)
  local red, green, blue = color:match "^#(%x%x)(%x%x)(%x%x)$"
  assert(red, "invalid RGB colour: expected #rrggbb")
  return tonumber(red, 16), tonumber(green, 16), tonumber(blue, 16)
end

local function palette(source, red, green, blue)
  local r, g, b = rgb(source)
  local luminance = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255
  local colors = {}
  for level = 1, levels do
    local brightness = luminance * (0.16 + 0.84 * (level - 1) / (levels - 1))
    colors[level] = ("#%02x%02x%02x"):format(
      math.floor(red * brightness + 0.5),
      math.floor(green * brightness + 0.5),
      math.floor(blue * brightness + 0.5)
    )
  end
  return colors
end

-- Cache geometry and palettes, not animation frames. generate() wraps the same
-- source segments in new tables; new() reuses the frame itself.
prepare = function(frame, state)
  local color = state.color or default_color
  local cache = state._sonar
  if cache and cache.color == color and #cache.rows == #frame then
    local unchanged = true
    for i, item in ipairs(frame) do
      if cache.rows[i].source ~= item.segments or cache.rows[i].line ~= item.line then
        unchanged = false
        break
      end
    end
    if unchanged then return cache end
  end

  local width = 0
  for _, item in ipairs(frame) do width = math.max(width, #item.line) end
  local center_x, center_y = (width + 1) / 2, (#frame + 1) / 2
  local red, green, blue = rgb(color)
  cache = { color = color, rows = {} }
  local palettes, farthest = {}, 0
  for i, item in ipairs(frame) do
    local row = { source = item.segments, line = item.line, cells = {} }
    local x = 0
    for _, segment in ipairs(item.segments) do
      local source = segment.color or "#ffffff"
      if not palettes[source] then palettes[source] = palette(source, red, green, blue) end
      for _ = 1, #segment.text do
        x = x + 1
        -- Terminal cells are roughly twice as tall as they are wide.
        local distance = math.sqrt(((x - center_x) / 2) ^ 2 + (i - center_y) ^ 2)
        row.cells[x] = { distance = distance, palette = palettes[source] }
        farthest = math.max(farthest, distance)
      end
    end
    cache.rows[i] = row
  end
  -- Let the trail leave the corners before the next pulse starts.
  cache.period = math.ceil((farthest + trail) / speed) + 8
  state._sonar = cache
  return cache
end

return M
