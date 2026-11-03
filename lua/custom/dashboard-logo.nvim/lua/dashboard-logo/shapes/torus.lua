-- Trace the nearest surface along each view ray to avoid rear-surface bleed.
local M = { interval = 80 }
local width, height = 61, 25
local major_radius, tube_radius = 7.5, 3
local outer_radius = major_radius + tube_radius
local steps = 300
local shades = ".,:;-=+*#%@"
local rays
local prepare, palette, trace, lighting

function M.render(state)
  prepare()
  local step = state.torus_step or 0
  local color = state.color or "#65ffc1"
  local cache = state._torus
  if cache and cache.step == step and cache.color == color then return cache.frame end
  if not cache or cache.color ~= color then
    cache = { color = color, palette = palette(color) }
    state._torus = cache
  end

  local angle = step * 2 * math.pi / steps
  -- Spin around the view axis while rocking the tilt. The opening stays visible.
  local tilt = 0.8 + 0.12 * math.sin(2 * angle)
  local axis_x = math.sin(angle) * math.sin(tilt)
  local axis_y = -math.cos(angle) * math.sin(tilt)
  local axis_z = math.cos(tilt)
  local frame = {}
  for y, row in ipairs(rays) do
    local text, segments = {}, {}
    for x, ray in ipairs(row) do
      local level = ray.visible and trace(ray, axis_x, axis_y, axis_z) or nil
      local glyph, tint = " ", nil
      if level then
        local index = math.floor(level / 15 * (#shades - 1)) + 1
        glyph, tint = shades:sub(index, index), cache.palette[level]
      end
      text[x] = glyph
      local previous = segments[#segments]
      if previous and previous.color == tint then
        previous.text = previous.text .. glyph
      else
        segments[#segments + 1] = { text = glyph, color = tint }
      end
    end
    frame[y] = { line = table.concat(text), segments = segments }
  end
  cache.step, cache.frame = step, frame
  return frame
end

function M.advance(state)
  state.torus_step = ((state.torus_step or 0) + 1) % steps
end

palette = function(color)
  local red, green, blue = color:match "^#(%x%x)(%x%x)(%x%x)$"
  assert(red, "invalid RGB colour: expected #rrggbb")
  red, green, blue = tonumber(red, 16), tonumber(green, 16), tonumber(blue, 16)
  local colors = {}
  for level = 0, 15 do
    local light = 0.14 + 0.86 * level / 15
    colors[level] = ("#%02x%02x%02x"):format(
      math.floor(red * light + 0.5), math.floor(green * light + 0.5), math.floor(blue * light + 0.5)
    )
  end
  return colors
end

trace = function(ray, ax, ay, az)
  local z = ray.front
  local planar_axis = ray.x * ax + ray.y * ay
  for _ = 1, 128 do
    local axial = planar_axis + z * az
    local radial = math.sqrt(math.max(0, ray.squared_radius + z * z - axial * axial))
    local distance = math.sqrt((radial - major_radius) ^ 2 + axial * axial) - tube_radius
    if distance < 0.01 then
      local ratio = major_radius / radial
      local nx = ray.x * (1 - ratio) + ax * axial * ratio
      local ny = ray.y * (1 - ratio) + ay * axial * ratio
      local nz = z * (1 - ratio) + az * axial * ratio
      return lighting(nx, ny, nz)
    end
    z = z - distance
    if z < -ray.front then return nil end
  end
  return nil
end

lighting = function(nx, ny, nz)
  local length = math.sqrt(nx * nx + ny * ny + nz * nz)
  nx, ny, nz = nx / length, ny / length, nz / length
  local diffuse = math.max(0, (-0.4 * nx + 0.6 * ny + 0.7 * nz) / math.sqrt(1.01))
  local reflection = math.max(0, 2 * diffuse * nz - 0.7 / math.sqrt(1.01))
  local brightness = 0.84 * diffuse + 0.16 * reflection ^ 16
  return math.max(0, math.min(15, math.floor(brightness * 15 + 0.5)))
end

prepare = function()
  if rays then return end
  rays = {}
  for y = 1, height do
    rays[y] = {}
    for x = 1, width do
      -- Two columns occupy about the height of one terminal row.
      local px, py = (x - (width + 1) / 2) / 2, (height + 1) / 2 - y
      local squared_radius = px * px + py * py
      local visible = squared_radius <= outer_radius * outer_radius
      rays[y][x] = {
        x = px, y = py, squared_radius = squared_radius, visible = visible,
        front = visible and math.sqrt(outer_radius * outer_radius - squared_radius) or 0,
      }
    end
  end
end

return M
