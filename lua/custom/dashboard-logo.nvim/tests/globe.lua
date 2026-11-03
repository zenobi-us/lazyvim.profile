local root = arg[0]:gsub("\\", "/"):match "^(.*)/tests/[^/]+$"
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path
local logo = require "dashboard-logo"

local function text(frame)
  local lines = {}
  for y, item in ipairs(frame) do
    local parts = {}
    for _, segment in ipairs(item.segments) do parts[#parts + 1] = segment.text end
    assert(table.concat(parts) == item.line, "segments must preserve globe text")
    assert(#item.line == #frame[1].line, "globe canvas must remain rectangular")
    lines[y] = item.line
  end
  return table.concat(lines, "\n")
end

local animation = logo.new { shape = "globe" }
local first = animation.frame()
local original = text(first)
local halfway
for tick = 1, math.floor(20000 / animation.interval) do
  local next_frame = animation.tick()
  assert(#next_frame == #first, "rotation must not resize the canvas")
  text(next_frame)
  for y, item in ipairs(next_frame) do
    for x = 1, #item.line do
      assert((item.line:sub(x, x) == " ") == (first[y].line:sub(x, x) == " "), "rotation must keep the sphere silhouette fixed")
    end
  end
  if tick == math.floor(10000 / animation.interval) then halfway = text(next_frame) end
end
assert(halfway ~= original, "land and longitude lines must rotate")
assert(text(animation.frame()) == original, "one revolution must return to the initial geography")
assert(text(first) == original, "later frames must not mutate an earlier frame")

local center_y = (#first + 1) / 2
local center_x = (#first[1].line + 1) / 2
local left = first[center_y].line:find "[^ ]"
local right = #first[center_y].line:gsub(" +$", "")
assert(math.abs((right - left) / 2 - (#first - 1)) < 1, "sphere must correct for terminal cell proportions")
for y, item in ipairs(first) do
  for x = 1, #item.line do
    local inside = ((x - center_x) / 2) ^ 2 + (y - center_y) ^ 2 <= ((#first - 1) / 2) ^ 2
    assert((item.line:sub(x, x) ~= " ") == inside, "rear geometry must not project outside the visible sphere")
  end
end

local red = logo.new { shape = "globe", color = "#ff0000" }.frame()
for _, item in ipairs(red) do
  for _, segment in ipairs(item.segments) do
    if segment.color then assert(segment.color:sub(4) == "0000", "theme tint must apply to the entire sphere") end
  end
end

local clean = logo.new { shape = "globe", color = "#61afef" }
local sonar = logo.new { shape = "globe", effect = "sonar", color = "#61afef" }
for _ = 1, 30 do
  local plain_frame, sonar_frame = clean.tick(), sonar.tick()
  assert(text(plain_frame) == text(sonar_frame), "sonar must not change globe geometry or rotation speed")
end
local ok, error_message = pcall(logo.new, { shape = "globe", logo = "orbit" })
assert(not ok and error_message:find("not both", 1, true), "ambiguous shape and logo selection must fail")
local unknown, unknown_error = pcall(logo.new, { shape = "missing" })
assert(not unknown and unknown_error:find("unknown dashboard shape", 1, true), "unknown shapes must fail explicitly")
print "dashboard globe: rotation, silhouette, tint, and sonar passed"
