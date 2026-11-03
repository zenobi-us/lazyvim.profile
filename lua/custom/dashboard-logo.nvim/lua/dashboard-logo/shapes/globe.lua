-- Ray-cast the visible hemisphere so rear land and grid lines never show through.
local M = { interval = 80 }
local width, height, radius = 61, 25, 12
local steps = 250 -- One revolution in 20 seconds at the shape's interval.
local cells, land_map
local prepare

function M.render(state)
  prepare()
  local step = state.globe_step or 0
  local color = state.color or "#65ffc1"
  local cache = state._globe
  if cache and cache.step == step and cache.color == color then return cache.frame end
  if not cache or cache.color ~= color then
    local red, green, blue = color:match "^#(%x%x)(%x%x)(%x%x)$"
    assert(red, "invalid RGB colour: expected #rrggbb")
    red, green, blue = tonumber(red, 16), tonumber(green, 16), tonumber(blue, 16)
    cache = { color = color, palette = {} }
    for level = 0, 15 do
      local light = 0.18 + 0.82 * level / 15
      cache.palette[level] = ("#%02x%02x%02x"):format(
        math.floor(red * light + 0.5), math.floor(green * light + 0.5), math.floor(blue * light + 0.5)
      )
    end
    state._globe = cache
  end

  local frame = {}
  local angle = step * 360 / steps
  for y, row in ipairs(cells) do
    local text, segments = {}, {}
    for x, cell in ipairs(row) do
      local character, tint = " ", nil
      if cell.visible then
        local longitude = (cell.longitude + angle + 180) % 360
        local column = math.floor(longitude / 2) + 1
        local land = land_map[cell.latitude_index][column]
        local grid = cell.latitude_grid or math.abs((longitude + 15) % 30 - 15) < 1.3
        local coast = land and (
          not land_map[cell.latitude_index][column % 180 + 1]
          or not land_map[cell.latitude_index][(column - 2) % 180 + 1]
        )
        character = coast and "#" or (grid and "+" or (land and "o" or "."))
        local level = math.max(0, cell.light - (not land and not grid and 5 or 0))
        tint = cache.palette[level]
      end
      text[x] = character
      local previous = segments[#segments]
      if previous and previous.color == tint then
        previous.text = previous.text .. character
      else
        segments[#segments + 1] = { text = character, color = tint }
      end
    end
    frame[y] = { line = table.concat(text), segments = segments }
  end
  cache.step, cache.frame = step, frame
  return frame
end

function M.advance(state)
  state.globe_step = ((state.globe_step or 0) + 1) % steps
end

-- Coarse, hand-drawn longitude/latitude outlines, not a political map.
local continents = {
  { {-168,72}, {-140,70}, {-125,60}, {-110,58}, {-95,72}, {-60,53}, {-53,47}, {-65,44},
    {-80,25}, {-87,21}, {-83,10}, {-98,17}, {-106,24}, {-117,32}, {-128,50}, {-155,58} },
  { {-81,12}, {-65,10}, {-50,1}, {-35,-6}, {-41,-22}, {-54,-34}, {-68,-55}, {-75,-44}, {-80,-10} },
  { {-73,60}, {-48,59}, {-20,72}, {-25,83}, {-50,84}, {-65,77} },
  { {-11,36}, {-10,44}, {-1,49}, {8,55}, {5,62}, {20,71}, {35,70}, {30,58}, {47,55},
    {60,68}, {100,77}, {145,72}, {179,66}, {179,51}, {155,55}, {140,45}, {130,34},
    {120,22}, {110,18}, {105,1}, {96,6}, {90,22}, {80,8}, {72,22}, {60,25}, {52,15},
    {43,12}, {35,30}, {28,41}, {20,39}, {12,45}, {3,42} },
  { {-17,35}, {10,37}, {33,31}, {43,12}, {51,12}, {43,-12}, {34,-25}, {19,-35},
    {11,-18}, {9,3}, {-4,5}, {-17,15} },
  { {113,-22}, {123,-14}, {135,-12}, {145,-17}, {154,-27}, {146,-39}, {130,-33}, {115,-35} },
  { {47,-13}, {51,-17}, {47,-26}, {43,-24} },
  { {130,32}, {142,45}, {145,43}, {138,34} },
  { {95,5}, {107,-6}, {119,-9}, {131,-3}, {141,-5}, {151,-10}, {145,-1}, {130,2}, {116,0}, {105,7} },
  { {166,-35}, {179,-38}, {170,-47}, {165,-45}, {174,-40} },
}

local function inside(longitude, latitude, polygon)
  local hit = false
  local previous = polygon[#polygon]
  for _, point in ipairs(polygon) do
    if (point[2] > latitude) ~= (previous[2] > latitude)
      and longitude < (previous[1] - point[1]) * (latitude - point[2]) / (previous[2] - point[2]) + point[1] then
      hit = not hit
    end
    previous = point
  end
  return hit
end

prepare = function()
  if cells then return end
  land_map = {}
  for row = 1, 90 do
    local latitude = 91 - row * 2
    land_map[row] = {}
    for column = 1, 180 do
      local longitude = column * 2 - 181
      local land = latitude < -70
      for _, polygon in ipairs(continents) do
        if land then break end
        land = inside(longitude, latitude, polygon)
      end
      land_map[row][column] = land
    end
  end

  cells = {}
  for y = 1, height do
    cells[y] = {}
    for x = 1, width do
      -- Two character columns occupy about the height of one terminal row.
      local nx, ny = (x - (width + 1) / 2) / (radius * 2), ((height + 1) / 2 - y) / radius
      local depth = 1 - nx * nx - ny * ny
      local cell = { visible = depth >= 0 }
      if cell.visible then
        local nz = math.sqrt(depth)
        local latitude = math.asin(ny) * 180 / math.pi
        -- asin avoids the incompatible atan2 APIs in Lua 5.1 and Lua 5.4.
        cell.longitude = nz == 0 and (nx >= 0 and 90 or -90) or math.asin(nx / math.sqrt(nx * nx + nz * nz)) * 180 / math.pi
        cell.latitude_index = math.max(1, math.min(90, math.floor((90 - latitude) / 2) + 1))
        cell.latitude_grid = math.abs((latitude + 15) % 30 - 15) < 1.3
        cell.light = math.floor(math.max(0, -0.4 * nx + 0.5 * ny + 0.75 * nz) * 15 + 0.5)
        cell.light = math.min(15, cell.light)
      end
      cells[y][x] = cell
    end
  end
end

return M
