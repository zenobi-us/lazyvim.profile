local root = arg[0]:gsub("\\", "/"):match "^(.*)/tests/[^/]+$"
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path
local logo = require "dashboard-logo"

local neighbors = { {1,0}, {-1,0}, {0,1}, {0,-1} }

local function inspect(frame, width, height)
  assert(#frame == height, "rotation must not change canvas height")
  local text, blank = {}, {}
  local dimmest, brightest = 255, 0
  for y, item in ipairs(frame) do
    assert(#item.line == width, "rotation must not change canvas width")
    local parts = {}
    for _, segment in ipairs(item.segments) do
      parts[#parts + 1] = segment.text
      if segment.color then
        assert(segment.color:sub(4) == "0000", "custom tint must apply to the whole surface")
        local brightness = tonumber(segment.color:sub(2, 3), 16)
        dimmest, brightest = math.min(dimmest, brightness), math.max(brightest, brightness)
      end
    end
    assert(table.concat(parts) == item.line, "colour segments must preserve torus geometry")
    assert(item.line:sub(1, 1) == " " and item.line:sub(-1) == " ", "torus must not clip at the canvas sides")
    for x = 1, width do
      if item.line:sub(x, x) == " " then blank[(y - 1) * width + x] = { x, y } end
    end
    text[y] = item.line
  end
  assert(not frame[1].line:find("%S") and not frame[#frame].line:find("%S"), "torus must not clip at the top or bottom")
  assert(brightest - dimmest > 100, "fixed lighting must distinguish highlights from the unlit surface")
  local center_x, center_y = (width + 1) / 2, (height + 1) / 2
  assert(blank[(center_y - 1) * width + center_x], "the centre must remain open throughout rotation")

  -- Only two blank regions may exist: outside the torus and its opening.
  -- Extra regions are pinholes; one region means the ring has a crack.
  local regions = 0
  while next(blank) do
    regions = regions + 1
    local key, start = next(blank)
    blank[key] = nil
    local queue, cursor = { start }, 1
    while cursor <= #queue do
      local point = queue[cursor]
      cursor = cursor + 1
      for _, offset in ipairs(neighbors) do
        local x, y = point[1] + offset[1], point[2] + offset[2]
        if x >= 1 and x <= width and y >= 1 and y <= height then
          local neighbor = (y - 1) * width + x
          if blank[neighbor] then
            queue[#queue + 1] = blank[neighbor]
            blank[neighbor] = nil
          end
        end
      end
    end
  end
  assert(regions == 2, "torus must have one opening and no surface cracks or pinholes")
  return table.concat(text, "\n")
end

local animation = logo.new { shape = "torus", color = "#ff0000" }
local first = animation.frame()
local width, height = #first[1].line, #first
local original = inspect(first, width, height)
local quarter
for tick = 1, math.floor(24000 / animation.interval) do
  local current = inspect(animation.tick(), width, height)
  if tick == math.floor(6000 / animation.interval) then quarter = current end
end
assert(quarter ~= original, "torus geometry and highlights must rotate")
assert(inspect(animation.frame(), width, height) == original, "one cycle must restore the initial surface")
assert(inspect(first, width, height) == original, "later frames must not mutate earlier geometry")

local state = { color = "#ff0000" }
logo.shapes.torus.render(state)
state.color = "#0000ff"
for _, item in ipairs(logo.shapes.torus.render(state)) do
  for _, segment in ipairs(item.segments) do
    if segment.color then assert(segment.color:sub(2, 5) == "0000", "a tint change must replace the cached palette") end
  end
end
print "dashboard torus: opening, solid surface, highlights, rotation, and tint passed"
