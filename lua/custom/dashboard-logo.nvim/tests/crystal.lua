local root = arg[0]:gsub("\\", "/"):match "^(.*)/tests/[^/]+$"
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path
local logo = require "dashboard-logo"

local function inspect(frame, width, height)
  assert(#frame == height, "tumbling must not change canvas height")
  local text, shades = {}, {}
  for y, item in ipairs(frame) do
    assert(#item.line == width, "tumbling must not change canvas width")
    local parts = {}
    for _, segment in ipairs(item.segments) do
      parts[#parts + 1] = segment.text
      if segment.color then
        assert(segment.color:sub(4) == "0000", "custom tint must apply to every face and edge")
        if segment.color == "#ff0000" then
          assert(not segment.text:find("[^/\\|%-]"), "full brightness must be reserved for visible edges")
        else
          shades[segment.color] = true
          assert(tonumber(segment.color:sub(2, 3), 16) < 255, "faces must stay dimmer than edges")
        end
      end
    end
    assert(table.concat(parts) == item.line, "colour segments must preserve crystal geometry")
    assert(item.line:sub(1, 1) == " " and item.line:sub(-1) == " ", "crystal must not clip at the canvas sides")
    local occupied = item.line:match "^%s*(.-)%s*$"
    assert(not occupied:find(" ", 1, true), "a solid crystal must not have gaps through its faces")
    text[y] = item.line
  end
  assert(not frame[1].line:find("%S") and not frame[#frame].line:find("%S"), "crystal must not clip at the top or bottom")
  local count = 0
  for _ in pairs(shades) do count = count + 1 end
  assert(count >= 1 and count <= 4, "a convex octahedron must expose at most four shaded faces")
  return table.concat(text, "\n"), count
end

local animation = logo.new { shape = "crystal", color = "#ff0000" }
local first = animation.frame()
local width, height = #first[1].line, #first
local original, initial_shades = inspect(first, width, height)
assert(initial_shades >= 2, "fixed lighting must distinguish adjacent faces")
local quarter
for tick = 1, math.floor(24000 / animation.interval) do
  local current = inspect(animation.tick(), width, height)
  if tick == math.floor(6000 / animation.interval) then quarter = current end
end
assert(quarter ~= original, "crystal geometry must tumble")
assert(inspect(animation.frame(), width, height) == original, "one cycle must restore the initial geometry")
assert(inspect(first, width, height) == original, "later frames must not mutate earlier geometry")

local state = { color = "#ff0000" }
logo.shapes.crystal.render(state)
state.color = "#0000ff"
for _, item in ipairs(logo.shapes.crystal.render(state)) do
  for _, segment in ipairs(item.segments) do
    if segment.color then assert(segment.color:sub(2, 5) == "0000", "a tint change must replace the cached palette") end
  end
end
print "dashboard crystal: solid faces, visible facets, bright edges, rotation, and tint passed"
