#!/usr/bin/env lua

local script = arg[0]:gsub("\\", "/")
local root = script:match "^(.*)/[^/]+$" or "."
local module_path = root .. "/lua/dashboard-logo/init.lua"
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path

local watch = false
local reload = false
local effect = "glitch"
local color
for _, value in pairs(arg) do
  if value == "--watch" or value == "-w" then watch = true end
  if value == "--reload" then reload = true end
  effect = value:match "^%-%-effect=(.+)$" or effect
  color = value:match "^%-%-color=(#%x%x%x%x%x%x)$" or color
end

local state = { color_offset = 0, glitch_offsets = {}, color = color }

local function terminal_size()
  local handle = io.popen "stty size 2>/dev/null < /dev/tty"
  if not handle then return 24, 80 end
  local rows, columns = handle:read("*a"):match "(%d+)%s+(%d+)"
  handle:close()
  return tonumber(rows) or 24, tonumber(columns) or 80
end

local logo
local function load_logo()
  for name in pairs(package.loaded) do
    if name:match "^dashboard%-logo%." then package.loaded[name] = nil end
  end
  local ok, loaded = pcall(dofile, module_path)
  if ok then logo = loaded end
  return ok, loaded
end

local function render()
  local ok, loaded = true, logo
  if not logo or reload then ok, loaded = load_logo() end
  if not ok then
    io.write("\27[2J\27[H", loaded, "\n")
    io.flush()
    return 120
  end
  logo = loaded

  local frame = logo.generate(state, nil, effect)
  local rows, columns = terminal_size()
  local top = math.max(0, math.floor((rows - #frame) / 2))
  local output = { "\27[2J\27[H", ("\n"):rep(top) }
  for _, item in ipairs(frame) do
    local left = math.max(0, math.floor((columns - #item.line) / 2))
    output[#output + 1] = (" "):rep(left)
    local previous_color
    for _, segment in ipairs(item.segments) do
      local filtered = logo.filter_color(segment.color, item.filter)
      if filtered ~= previous_color then
        if filtered then
          local red, green, blue = filtered:match "#(%x%x)(%x%x)(%x%x)"
          output[#output + 1] = ("\27[38;2;%d;%d;%dm"):format(tonumber(red, 16), tonumber(green, 16), tonumber(blue, 16))
        else
          output[#output + 1] = "\27[0m"
        end
        previous_color = filtered
      end
      output[#output + 1] = segment.text
    end
    output[#output + 1] = "\27[0m\n"
  end
  io.write(table.concat(output))
  io.flush()
  logo.advance(state, nil, effect)
  return logo.effects[effect].interval or 120
end

repeat
  local interval = render()
  if watch then
    local ok = os.execute(("sleep %.3f"):format(interval / 1000))
    if ok ~= true and ok ~= 0 then watch = false end
  end
until not watch
