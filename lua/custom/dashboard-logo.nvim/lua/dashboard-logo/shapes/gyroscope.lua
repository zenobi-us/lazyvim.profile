-- A depth buffer keeps the nearest ring visible at projected crossings.
local M = { interval = 80 }
local width, height = 61, 25
local steps = 300
local rings = {
  { radius = 11, tilt = 0.65, turn = 0.35, x = 1, y = 1, z = 0 },
  { radius = 8, tilt = 1.15, turn = 1.05, x = -1, y = 2, z = 1 },
  { radius = 5.4, tilt = 0.3, turn = 0.85, x = 2, y = -1, z = -1 },
}
local samples
local palette, rasterize, frame_from_cells

function M.render(state)
  local step = state.gyroscope_step or 0
  local color = state.color or "#65ffc1"
  local cache = state._gyroscope
  if cache and cache.step == step and cache.color == color then return cache.frame end
  if not cache or cache.color ~= color then
    cache = { color = color, palette = palette(color) }
    state._gyroscope = cache
  end

  local cells = {}
  local angle = step * 2 * math.pi / steps
  for _, ring in ipairs(rings) do rasterize(cells, ring, angle) end
  cache.frame = frame_from_cells(cells, cache.palette)
  cache.step = step
  return cache.frame
end

function M.advance(state)
  state.gyroscope_step = ((state.gyroscope_step or 0) + 1) % steps
end

palette = function(color)
  local red, green, blue = color:match "^#(%x%x)(%x%x)(%x%x)$"
  assert(red, "invalid RGB colour: expected #rrggbb")
  red, green, blue = tonumber(red, 16), tonumber(green, 16), tonumber(blue, 16)
  local colors = {}
  for level = 0, 15 do
    local light = 0.25 + 0.75 * level / 15
    colors[level] = ("#%02x%02x%02x"):format(
      math.floor(red * light + 0.5), math.floor(green * light + 0.5), math.floor(blue * light + 0.5)
    )
  end
  return colors
end

rasterize = function(cells, ring, angle)
  if not samples then
    samples = {}
    -- Sub-cell spacing keeps even the largest ring continuous when projected.
    for index = 0, 255 do
      local phase = index * 2 * math.pi / 256
      samples[#samples + 1] = { cosine = math.cos(phase), sine = math.sin(phase) }
    end
  end

  local sx, cx = math.sin(ring.tilt + ring.x * angle), math.cos(ring.tilt + ring.x * angle)
  local sy, cy = math.sin(ring.turn + ring.y * angle), math.cos(ring.turn + ring.y * angle)
  local sz, cz = math.sin(ring.z * angle), math.cos(ring.z * angle)
  -- The first two columns of Rz * Ry * Rx transform each circle's local plane.
  local ux, uy, uz = cz * cy, sz * cy, -sy
  local vx, vy, vz = cz * sy * sx - sz * cx, sz * sy * sx + cz * cx, cy * sx
  for _, sample in ipairs(samples) do
    local cosine, sine = sample.cosine, sample.sine
    local x = math.floor((width + 1) / 2 + 2 * ring.radius * (ux * cosine + vx * sine) + 0.5)
    local y = math.floor((height + 1) / 2 - ring.radius * (uy * cosine + vy * sine) + 0.5)
    local depth = ring.radius * (uz * cosine + vz * sine)
    local index = (y - 1) * width + x
    local previous = cells[index]
    if not previous or depth > previous.depth then
      local dx, dy = 2 * (-ux * sine + vx * cosine), uy * sine - vy * cosine
      local glyph = "-"
      if math.abs(dx) < math.abs(dy) * 0.45 then
        glyph = "|"
      elseif math.abs(dy) >= math.abs(dx) * 0.35 then
        glyph = dx * dy > 0 and "\\" or "/"
      end
      cells[index] = {
        depth = depth,
        glyph = depth < 0 and "." or glyph,
        level = math.max(0, math.min(15, math.floor((depth / 22 + 0.5) * 15 + 0.5))),
      }
    end
  end
end

frame_from_cells = function(cells, colors)
  local frame = {}
  for y = 1, height do
    local text, segments = {}, {}
    for x = 1, width do
      local cell = cells[(y - 1) * width + x]
      local glyph, color = " ", nil
      if cell then glyph, color = cell.glyph, colors[cell.level] end
      text[x] = glyph
      local previous = segments[#segments]
      if previous and previous.color == color then
        previous.text = previous.text .. glyph
      else
        segments[#segments + 1] = { text = glyph, color = color }
      end
    end
    frame[y] = { line = table.concat(text), segments = segments }
  end
  return frame
end

return M
