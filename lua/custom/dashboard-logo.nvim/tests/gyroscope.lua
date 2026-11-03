local root = arg[0]:gsub("\\", "/"):match "^(.*)/tests/[^/]+$"
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path
local logo = require "dashboard-logo"

local function inspect(frame, expected_width, expected_height)
  assert(#frame == expected_height, "rotation must not change canvas height")
  local text, occupied = {}, {}
  for y, item in ipairs(frame) do
    assert(#item.line == expected_width, "rotation must not change canvas width")
    local parts = {}
    for _, segment in ipairs(item.segments) do parts[#parts + 1] = segment.text end
    assert(table.concat(parts) == item.line, "segments must preserve ring geometry")
    assert(item.line:sub(1, 1) == " " and item.line:sub(-1) == " ", "rings must not clip at the canvas sides")
    for x = 1, expected_width do
      if item.line:sub(x, x) ~= " " then occupied[(y - 1) * expected_width + x] = { x, y } end
    end
    text[y] = item.line
  end
  assert(not frame[1].line:find("%S") and not frame[#frame].line:find("%S"), "rings must not clip at the top or bottom")

  -- Each continuous ring is one component; projected crossings may join them.
  local components = 0
  while next(occupied) do
    components = components + 1
    local key, start = next(occupied)
    occupied[key] = nil
    local queue, cursor = { start }, 1
    while cursor <= #queue do
      local point = queue[cursor]
      cursor = cursor + 1
      for dy = -1, 1 do
        for dx = -1, 1 do
          local neighbor = (point[2] + dy - 1) * expected_width + point[1] + dx
          if occupied[neighbor] then
            queue[#queue + 1] = occupied[neighbor]
            occupied[neighbor] = nil
          end
        end
      end
    end
  end
  assert(components >= 1 and components <= 3, "three rings must remain continuous during rotation")
  return table.concat(text, "\n")
end

local animation = logo.new { shape = "gyroscope" }
local first = animation.frame()
local width, height = #first[1].line, #first
local original = inspect(first, width, height)
local quarter
for tick = 1, math.floor(24000 / animation.interval) do
  local current = inspect(animation.tick(), width, height)
  if tick == math.floor(6000 / animation.interval) then quarter = current end
end
assert(quarter ~= original, "rings must rotate around their axes")
assert(inspect(animation.frame(), width, height) == original, "all rings must return smoothly after one cycle")
assert(inspect(first, width, height) == original, "later frames must not mutate earlier geometry")

local state = { color = "#ff0000" }
local red = logo.shapes.gyroscope.render(state)
local brightest_rear, dimmest_front, brightest_front = 0, 255, 0
for _, item in ipairs(red) do
  for _, segment in ipairs(item.segments) do
    if segment.color then
      assert(segment.color:sub(4) == "0000", "custom tint must apply to every ring")
      local brightness = tonumber(segment.color:sub(2, 3), 16)
      if segment.text:find("%.") then
        brightest_rear = math.max(brightest_rear, brightness)
      else
        dimmest_front = math.min(dimmest_front, brightness)
        brightest_front = math.max(brightest_front, brightness)
      end
    end
  end
end
assert(dimmest_front >= brightest_rear and brightest_front > brightest_rear, "rear edges must be dimmer than front edges")
state.color = "#0000ff"
for _, item in ipairs(logo.shapes.gyroscope.render(state)) do
  for _, segment in ipairs(item.segments) do
    if segment.color then assert(segment.color:sub(2, 5) == "0000", "changing tint must replace the cached palette") end
  end
end
print "dashboard gyroscope: continuous rings, rotation, depth shading, and tint passed"
