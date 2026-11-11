local script = arg[0]:gsub("\\", "/")
local root = script:match "^(.*)/tests/[^/]+$" or "."
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path
local logo = require "dashboard-logo"
local R = require "dashboard-logo.shapes.raster"
local names = { "trefoil", "mobius", "wave_grid", "dna", "accretion_disc", "planetary_system", "superformula", "iris" }

local function inspect(frame)
  assert(#frame == 25, "shape changed canvas height")
  local result = { text = {}, signature = {}, area = 0, brightness = {}, top = 25, bottom = 1, left = 61, right = 1 }
  for y, item in ipairs(frame) do
    assert(#item.line == 61 and not item.line:find("[^ -~]"), "shape changed canvas width or emitted non-ASCII text")
    local parts, column = {}, 1
    for _, segment in ipairs(item.segments) do
      parts[#parts + 1] = segment.text
      result.signature[#result.signature + 1] = (segment.color or "default") .. ":" .. segment.text
      if segment.color then assert(segment.color:match "^#%x%x0000$", "theme tint leaked another hue") end
      for x = 1, #segment.text do
        if segment.text:sub(x, x) ~= " " then
          assert(segment.color, "a visible surface lost its tint")
          result.area = result.area + 1
          result.top, result.bottom = math.min(result.top, y), math.max(result.bottom, y)
          result.left, result.right = math.min(result.left, column), math.max(result.right, column)
          result.brightness[(y - 1) * 61 + column] = tonumber(segment.color:sub(2, 3), 16)
        end
        column = column + 1
      end
    end
    assert(table.concat(parts) == item.line, "colour segments no longer reproduce the shape")
    assert(item.line:sub(1, 1) == " " and item.line:sub(-1) == " ", "shape clipped a side margin")
    result.text[y] = item.line
  end
  assert(not frame[1].line:find("%S") and not frame[25].line:find("%S"), "shape clipped a vertical margin")
  result.signature = table.concat(result.signature, "\n")
  return result
end

local function aperture(frame)
  local start = { 31, 13 }
  assert(frame[13].line:sub(31, 31) == " ", "central aperture was filled")
  local queue, seen, cursor = { start }, { [12 * 61 + 31] = true }, 1
  local directions = { {1,0}, {-1,0}, {0,1}, {0,-1} }
  while cursor <= #queue do
    local point = queue[cursor]
    cursor = cursor + 1
    for _, direction in ipairs(directions) do
      local x, y = point[1] + direction[1], point[2] + direction[2]
      assert(x > 1 and x < 61 and y > 1 and y < 25, "aperture opened a crack to the canvas border")
      local key = (y - 1) * 61 + x
      if not seen[key] and frame[y].line:sub(x, x) == " " then
        seen[key] = true
        queue[#queue + 1] = { x, y }
      end
    end
  end
  return #queue
end

local function verify_depth()
  local front = { {-3,-3,2}, {3,-3,2}, {0,3,2} }
  local back = { {-3,-3,-2}, {3,-3,-2}, {0,3,-2} }
  local first, second = R.new { color = "#ff0000" }, R.new { color = "#ff0000" }
  R.triangle(first, back[1], back[2], back[3], 0.2)
  R.triangle(first, front[1], front[2], front[3], 0.8)
  R.triangle(second, front[1], front[2], front[3], 0.8)
  R.triangle(second, back[1], back[2], back[3], 0.2)
  local a, b = inspect(R.frame(first)), inspect(R.frame(second))
  assert(a.signature == b.signature and a.brightness[12 * 61 + 31] == 204, "rear faces showed through a nearer surface")
  R.sphere(second, 0, 0, 3, 1.2, 1)
  assert(inspect(R.frame(second)).brightness[12 * 61 + 31] == 255, "nearer opaque sphere did not hide the mesh")
end

local function verify(name)
  local shape = logo.shapes[name]
  local animation = logo.new { shape = name, color = "#ff0000" }
  local first = animation.frame()
  local initial = inspect(first)
  local metrics = { initial }
  local minimum_area, maximum_area = initial.area, initial.area
  local minimum_aperture, maximum_aperture = math.huge, 0
  local changed = false
  for tick = 1, shape.period do
    local frame = animation.tick()
    local current = inspect(frame)
    minimum_area, maximum_area = math.min(minimum_area, current.area), math.max(maximum_area, current.area)
    if tick % 25 == 0 then metrics[#metrics + 1] = current end
    if current.signature ~= initial.signature then changed = true end
    if name == "accretion_disc" then
      for y = 11, 15 do
        for x = 26, 36 do
          if ((x - 31) / 2) ^ 2 + (13 - y) ^ 2 <= 6.25 then
            assert(frame[y].line:sub(x, x) == " ", "particle trails filled the dark centre")
          end
        end
      end
    elseif name == "iris" then
      local opening = aperture(frame)
      minimum_aperture, maximum_aperture = math.min(minimum_aperture, opening), math.max(maximum_aperture, opening)
    elseif name == "planetary_system" then
      assert(frame[13].line:sub(31, 31) ~= " ", "the central star disappeared")
    end
  end
  assert(changed, "shape did not animate geometry or shading")
  assert(inspect(animation.frame()).signature == initial.signature, "animation did not close its loop")
  assert(inspect(first).signature == initial.signature, "a later frame mutated the retained first frame")
  if name == "mobius" then
    assert(maximum_area > minimum_area * 1.25, "ribbon did not turn between broad and edge views")
  elseif name == "superformula" then
    assert(maximum_area > minimum_area * 1.2, "morph did not change the silhouette")
  elseif name == "iris" then
    assert(maximum_aperture > minimum_aperture * 2, "blades did not open and close the aperture")
  elseif name == "dna" then
    for _, current in ipairs(metrics) do
      assert(current.bottom - current.top >= 16, "helical strands broke their vertical span")
      assert(current.right - current.left >= 8, "two-strand helix collapsed into a single line")
    end
  elseif name == "trefoil" then
    for _, current in ipairs(metrics) do
      assert(current.bottom - current.top >= 10 and current.right - current.left >= 15, "knot collapsed instead of retaining tubular loops")
    end
  end
  local state = { color = "#ff0000" }
  local original = shape.render(state)
  local old = inspect(original).signature
  state.color = "#0000ff"
  for _, item in ipairs(shape.render(state)) do
    for _, segment in ipairs(item.segments) do
      if segment.color then assert(segment.color:match "^#0000%x%x$", "theme change left stale surface colours") end
    end
  end
  assert(inspect(original).signature == old, "theme change mutated an earlier frame")
  print(name .. ": geometry, animation, loop, tint and frame invariants passed")
end

verify_depth()
local failures = {}
for _, name in ipairs(names) do
  if not arg[1] or arg[1] == name then
    local ok, message = pcall(verify, name)
    if not ok then failures[#failures + 1] = name .. ": " .. tostring(message) end
  end
end
assert(#failures == 0, table.concat(failures, "\n"))
print "dashboard generated shapes: all requested checks passed"
