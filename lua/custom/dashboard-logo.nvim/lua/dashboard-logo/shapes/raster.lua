-- New mesh and particle shapes share one depth buffer and terminal projection.
local M = {}
local width, height = 61, 25
local shades = ".:;-=+*#%@"
local palette, put

function M.new(state)
  local color = state.color or "#65ffc1"
  if state._raster_color ~= color then
    state._raster_palette = palette(color)
    state._raster_color = color
  end
  return { cells = {}, palette = state._raster_palette }
end

function M.plot(canvas, x, y, z, brightness, glyph)
  local column = math.floor(31 + 2 * x + 0.5)
  local row = math.floor(13 - y + 0.5)
  put(canvas, column, row, z, brightness, glyph)
end

function M.segment(canvas, a, b, brightness, glyph)
  local count = math.max(1, math.ceil(math.max(math.abs(b[1] - a[1]) * 2, math.abs(b[2] - a[2])) * 2))
  for sample = 0, count do
    local t = sample / count
    M.plot(canvas, a[1] + t * (b[1] - a[1]), a[2] + t * (b[2] - a[2]),
      a[3] + t * (b[3] - a[3]), brightness, glyph)
  end
end

function M.triangle(canvas, a, b, c, brightness)
  local ax, ay, bx, by, cx, cy = 31 + 2 * a[1], 13 - a[2], 31 + 2 * b[1], 13 - b[2], 31 + 2 * c[1], 13 - c[2]
  local area = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
  if math.abs(area) < 1e-9 then return end
  local left, right = math.max(1, math.ceil(math.min(ax, bx, cx))), math.min(width, math.floor(math.max(ax, bx, cx)))
  local top, bottom = math.max(1, math.ceil(math.min(ay, by, cy))), math.min(height, math.floor(math.max(ay, by, cy)))
  for y = top, bottom do
    for x = left, right do
      local wa = ((by - cy) * (x - cx) + (cx - bx) * (y - cy)) / area
      local wb = ((cy - ay) * (x - cx) + (ax - cx) * (y - cy)) / area
      local wc = 1 - wa - wb
      -- Shared edges need a tolerance so floating-point rounding leaves no seams.
      if wa >= -1e-9 and wb >= -1e-9 and wc >= -1e-9 then
        put(canvas, x, y, wa * a[3] + wb * b[3] + wc * c[3], brightness)
      end
    end
  end
end

function M.sphere(canvas, x, y, z, radius, emission)
  local left, right = math.max(1, math.ceil(31 + 2 * (x - radius))), math.min(width, math.floor(31 + 2 * (x + radius)))
  local top, bottom = math.max(1, math.ceil(13 - y - radius)), math.min(height, math.floor(13 - y + radius))
  for row = top, bottom do
    for column = left, right do
      local nx, ny = ((column - 31) / 2 - x) / radius, (13 - row - y) / radius
      local squared_depth = 1 - nx * nx - ny * ny
      if squared_depth >= 0 then
        local nz = math.sqrt(squared_depth)
        put(canvas, column, row, z + radius * nz, math.max(emission or 0, M.light(nx, ny, nz)))
      end
    end
  end
end

function M.light(nx, ny, nz)
  local length = math.sqrt(nx * nx + ny * ny + nz * nz)
  if length < 1e-12 then return 0.16 end
  return 0.16 + 0.84 * math.max(0, (-0.4 * nx + 0.6 * ny + 0.7 * nz) / (length * math.sqrt(1.01)))
end

function M.rotation(ax, ay, az)
  local sx, cx, sy, cy, sz, cz = math.sin(ax), math.cos(ax), math.sin(ay), math.cos(ay), math.sin(az), math.cos(az)
  return {
    cz * cy, cz * sy * sx - sz * cx, cz * sy * cx + sz * sx,
    sz * cy, sz * sy * sx + cz * cx, sz * sy * cx - cz * sx,
    -sy, cy * sx, cy * cx,
  }
end

function M.transform(matrix, x, y, z)
  return matrix[1] * x + matrix[2] * y + matrix[3] * z,
    matrix[4] * x + matrix[5] * y + matrix[6] * z,
    matrix[7] * x + matrix[8] * y + matrix[9] * z
end

function M.frame(canvas)
  local frame = {}
  for y = 1, height do
    local text, colors = {}, {}
    for x = 1, width do
      local cell = canvas.cells[(y - 1) * width + x]
      text[x] = cell and cell.glyph or " "
      colors[x] = cell and canvas.palette[cell.level] or false
    end
    local line, segments, first = table.concat(text), {}, 1
    for x = 2, width + 1 do
      if x > width or colors[x] ~= colors[first] then
        segments[#segments + 1] = { text = line:sub(first, x - 1), color = colors[first] or nil }
        first = x
      end
    end
    frame[y] = { line = line, segments = segments }
  end
  return frame
end

palette = function(color)
  local red, green, blue = color:match "^#(%x%x)(%x%x)(%x%x)$"
  assert(red, "invalid RGB colour: expected #rrggbb")
  red, green, blue = tonumber(red, 16), tonumber(green, 16), tonumber(blue, 16)
  local colors = {}
  for level = 0, 15 do
    local light = level / 15
    colors[level] = ("#%02x%02x%02x"):format(
      math.floor(red * light + 0.5), math.floor(green * light + 0.5), math.floor(blue * light + 0.5)
    )
  end
  return colors
end

put = function(canvas, x, y, z, brightness, glyph)
  if x < 1 or x > width or y < 1 or y > height then return end
  local index = (y - 1) * width + x
  local previous = canvas.cells[index]
  if previous and previous.depth >= z then return end
  local level = math.max(0, math.min(15, math.floor(brightness * 15 + 0.5)))
  local glyph_index = math.floor(level / 15 * (#shades - 1)) + 1
  canvas.cells[index] = { depth = z, level = level, glyph = glyph or shades:sub(glyph_index, glyph_index) }
end

return M
