-- Cull rear faces, depth-test face fills, then highlight the visible edges.
local M = { interval = 80 }
local width, height, radius = 61, 25, 11
local steps = 300
local vertices = { {1,0,0}, {-1,0,0}, {0,1,0}, {0,-1,0}, {0,0,1}, {0,0,-1} }
-- Outward winding makes a positive normal Z face the viewer.
local faces = {
  {1,3,5}, {3,2,5}, {2,4,5}, {4,1,5},
  {3,1,6}, {2,3,6}, {4,2,6}, {1,4,6},
}
local palette, rotate, fill_face, draw_edge, frame_from_cells

function M.render(state)
  local step = state.crystal_step or 0
  local color = state.color or "#65ffc1"
  local cache = state._crystal
  if cache and cache.step == step and cache.color == color then return cache.frame end
  if not cache or cache.color ~= color then
    cache = { color = color, palette = palette(color) }
    state._crystal = cache
  end

  local transformed = rotate(step * 2 * math.pi / steps)
  local cells, edges, seen = {}, {}, {}
  for _, face in ipairs(faces) do
    if fill_face(cells, transformed[face[1]], transformed[face[2]], transformed[face[3]]) then
      for side = 1, 3 do
        local a, b = face[side], face[side % 3 + 1]
        local key = math.min(a, b) * #vertices + math.max(a, b)
        if not seen[key] then
          edges[#edges + 1] = { transformed[a], transformed[b] }
          seen[key] = true
        end
      end
    end
  end
  -- On a convex solid, every edge attached to a front face is visible.
  for _, edge in ipairs(edges) do draw_edge(cells, edge[1], edge[2]) end
  cache.frame = frame_from_cells(cells, cache.palette)
  cache.step = step
  return cache.frame
end

function M.advance(state)
  state.crystal_step = ((state.crystal_step or 0) + 1) % steps
end

palette = function(color)
  local red, green, blue = color:match "^#(%x%x)(%x%x)(%x%x)$"
  assert(red, "invalid RGB colour: expected #rrggbb")
  red, green, blue = tonumber(red, 16), tonumber(green, 16), tonumber(blue, 16)
  local colors = {}
  for level = 0, 15 do
    local light = 0.18 + 0.82 * level / 15
    colors[level] = ("#%02x%02x%02x"):format(
      math.floor(red * light + 0.5), math.floor(green * light + 0.5), math.floor(blue * light + 0.5)
    )
  end
  return colors
end

rotate = function(angle)
  local sx, cx = math.sin(0.45 + angle), math.cos(0.45 + angle)
  local sy, cy = math.sin(0.55 + 2 * angle), math.cos(0.55 + 2 * angle)
  local sz, cz = math.sin(0.2 + angle), math.cos(0.2 + angle)
  local transformed = {}
  for i, vertex in ipairs(vertices) do
    local x, y, z = vertex[1] * radius, vertex[2] * radius, vertex[3] * radius
    y, z = cx * y - sx * z, sx * y + cx * z
    x, z = cy * x + sy * z, -sy * x + cy * z
    x, y = cz * x - sz * y, sz * x + cz * y
    -- Two columns occupy approximately the height of one terminal row.
    transformed[i] = { x = x, y = y, z = z, column = (width + 1) / 2 + 2 * x, row = (height + 1) / 2 - y }
  end
  return transformed
end

fill_face = function(cells, a, b, c)
  local abx, aby, abz = b.x - a.x, b.y - a.y, b.z - a.z
  local acx, acy, acz = c.x - a.x, c.y - a.y, c.z - a.z
  local nx, ny, nz = aby * acz - abz * acy, abz * acx - abx * acz, abx * acy - aby * acx
  -- Skip edge-on faces as well as rear faces before dividing by projected area.
  if nz <= 1e-8 then return false end
  local normal_length = math.sqrt(nx * nx + ny * ny + nz * nz)
  local diffuse = math.max(0, (-0.4 * nx + 0.6 * ny + 0.7 * nz) / (normal_length * math.sqrt(1.01)))
  local level = math.min(12, math.floor(3 + 9 * diffuse + 0.5))
  local shades = ".:-=+*#"
  local glyph_index = math.floor(level / 15 * (#shades - 1)) + 1
  local glyph = shades:sub(glyph_index, glyph_index)
  local area = (b.row - c.row) * (a.column - c.column) + (c.column - b.column) * (a.row - c.row)
  local left = math.max(1, math.ceil(math.min(a.column, b.column, c.column)))
  local right = math.min(width, math.floor(math.max(a.column, b.column, c.column)))
  local top = math.max(1, math.ceil(math.min(a.row, b.row, c.row)))
  local bottom = math.min(height, math.floor(math.max(a.row, b.row, c.row)))
  for y = top, bottom do
    for x = left, right do
      local wa = ((b.row - c.row) * (x - c.column) + (c.column - b.column) * (y - c.row)) / area
      local wb = ((c.row - a.row) * (x - c.column) + (a.column - c.column) * (y - c.row)) / area
      local wc = 1 - wa - wb
      -- A small tolerance prevents round-off cracks along shared triangle edges.
      if wa >= -1e-9 and wb >= -1e-9 and wc >= -1e-9 then
        local depth = wa * a.z + wb * b.z + wc * c.z
        local index = (y - 1) * width + x
        if not cells[index] or depth > cells[index].depth then
          cells[index] = { depth = depth, glyph = glyph, level = level }
        end
      end
    end
  end
  return true
end

draw_edge = function(cells, a, b)
  local dx, dy = b.column - a.column, b.row - a.row
  local count = math.max(1, math.ceil(math.max(math.abs(dx), math.abs(dy)) * 2))
  local glyph = "-"
  if math.abs(dx) < math.abs(dy) * 0.45 then
    glyph = "|"
  elseif math.abs(dy) >= math.abs(dx) * 0.35 then
    glyph = dx * dy > 0 and "\\" or "/"
  end
  for sample = 0, count do
    local fraction = sample / count
    local x = math.floor(a.column + fraction * dx + 0.5)
    local y = math.floor(a.row + fraction * dy + 0.5)
    cells[(y - 1) * width + x] = { glyph = glyph, level = 15 }
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
