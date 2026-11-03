local root = arg[0]:gsub("\\", "/"):match "^(.*)/tests/[^/]+$"
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path
local logo = require "dashboard-logo"
local sonar = logo.effects.sonar

local function color_at(frame, x, y)
  for _, segment in ipairs(frame[y].segments) do
    if x <= #segment.text then return segment.color end
    x = x - #segment.text
  end
  error "cell outside frame"
end

local source = {}
for y = 1, 9 do
  source[y] = { line = ("X"):rep(17), segments = { { text = ("X"):rep(17), color = "#ffffff" } } }
end
local state = {}
local start = sonar.apply(source, state)
for _ = 1, 4 do sonar.advance(state, source) end
local ring = sonar.apply(source, state)
assert(color_at(ring, 15, 5) == color_at(ring, 9, 8), "ring must correct for terminal cell proportions")
assert(color_at(ring, 15, 5) == color_at(ring, 3, 5), "ring must be symmetric")
assert(color_at(ring, 15, 5) > color_at(ring, 9, 5), "wavefront must be brighter than its trail")
assert(color_at(ring, 9, 5) > color_at(ring, 1, 1), "trail must be brighter than untouched cells")
assert(color_at(start, 9, 5) > color_at(ring, 9, 5), "centre must fade after the pulse passes")
for _ = 1, 200 do
  sonar.advance(state, source)
  if state.sonar_step == 0 then break end
end
assert(state.sonar_step == 0, "pulse must repeat")
assert(color_at(sonar.apply(source, state), 9, 5) == color_at(start, 9, 5), "new pulse must restore the centre")

local themed = sonar.apply(source, { color = "#ff0000" })
assert(color_at(themed, 9, 5) == "#ff0000", "custom colour must reach the wavefront")
source[5].segments = { { text = ("X"):rep(8), color = "#000000" }, { text = ("X"):rep(9), color = "#ffffff" } }
local shaded = sonar.apply(source, { sonar_step = 4 })
assert(color_at(shaded, 3, 5) == "#000000", "black source cells must stay black")
assert(source[5].segments[2].color == "#ffffff", "effect must not mutate the source palette")

for name in pairs(logo.logos) do
  if name ~= "default" then
    local animation = logo.new { logo = name, effect = "sonar" }
    local original = logo.render(name)
    for _ = 1, 100 do
      for y, item in ipairs(animation.tick()) do
        local text = {}
        for _, segment in ipairs(item.segments) do text[#text + 1] = segment.text end
        assert(item.line == original[y].line, "sonar must not move the logo")
        assert(table.concat(text) == item.line, "colour segments must preserve every character")
      end
    end
  end
end
print "dashboard logo sonar: ok"
