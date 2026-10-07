local M = {}

-- Dark alternating bands scroll slowly to mimic CRT scan lines.
M.colors = {
  "#0d4d26",
  "#16802d",
  "#2dcc4b",
  "#0d4d26",
  "#0d4d26",
  "#0d4d26",
  "#0d4d26",
  "#0d4d26",
  "#0d4d26",
  "#176b35",
}
M.burn_colors = {
  "#b6ffbf",
  "#2dcc4b",
  "#16802d",
  "#0d4a1c",
  "#082b12",
}
M.interval = 90

local function linear(channel)
  channel = channel / 255
  return channel <= 0.04045 and channel / 12.92 or ((channel + 0.055) / 1.055) ^ 2.4
end

local function srgb(channel)
  channel = channel <= 0.0031308 and channel * 12.92 or 1.055 * channel ^ (1 / 2.4) - 0.055
  return math.floor(math.max(0, math.min(1, channel)) * 255 + 0.5)
end

local function luminance(color)
  local red, green, blue = color:match "^#(%x%x)(%x%x)(%x%x)$"
  assert(red, "invalid RGB colour: " .. tostring(color))
  red, green, blue = linear(tonumber(red, 16)), linear(tonumber(green, 16)), linear(tonumber(blue, 16))
  return 0.2126 * red + 0.7152 * green + 0.0722 * blue
end

local function luminances(colors)
  local values = {}
  for i, color in ipairs(colors) do values[i] = luminance(color) end
  return values
end

local color_luminance = luminances(M.colors)
local burn_luminance = luminances(M.burn_colors)

local function shade(color, target)
  local red, green, blue = color:match "^#(%x%x)(%x%x)(%x%x)$"
  assert(red, "invalid RGB colour: " .. tostring(color))
  local channels = { linear(tonumber(red, 16)), linear(tonumber(green, 16)), linear(tonumber(blue, 16)) }
  local source_luminance = 0.2126 * channels[1] + 0.7152 * channels[2] + 0.0722 * channels[3]

  if target <= source_luminance then
    local scale = source_luminance == 0 and 0 or target / source_luminance
    for i = 1, 3 do channels[i] = channels[i] * scale end
  else
    local mix = source_luminance == 1 and 0 or (target - source_luminance) / (1 - source_luminance)
    for i = 1, 3 do channels[i] = channels[i] + (1 - channels[i]) * mix end
  end

  return ("#%02x%02x%02x"):format(srgb(channels[1]), srgb(channels[2]), srgb(channels[3]))
end

local function palette(color, targets)
  local colors = {}
  for i, target in ipairs(targets) do colors[i] = shade(color, target) end
  return colors
end

function M.palette(color)
  if not color then return M.colors, M.burn_colors end
  return palette(color, color_luminance), palette(color, burn_luminance)
end

local function glitch_line(line, offset)
  if offset > 0 then return (" "):rep(offset) .. line end
  if offset < 0 then return line:sub(-offset + 1) end
  return line
end

local function glitch_segments(segments, offset)
  if offset == 0 then return segments end
  if offset > 0 then
    local shifted = { { text = (" "):rep(offset) } }
    for _, segment in ipairs(segments) do shifted[#shifted + 1] = segment end
    return shifted
  end

  local shifted = {}
  local remove = -offset
  for _, segment in ipairs(segments) do
    local text = segment.text
    if remove >= #text then
      remove = remove - #text
    else
      shifted[#shifted + 1] = { text = text:sub(remove + 1), color = segment.color }
      remove = 0
    end
  end
  if #shifted == 0 then shifted[1] = { text = "" } end
  return shifted
end

local function block_at(blocks, line)
  for _, block in ipairs(blocks) do
    if line >= block.first and line <= block.last then return block end
  end
end

local function burn_at(waves, line, burn_colors)
  local brightest
  for _, wave in ipairs(waves) do
    local rank
    if wave.age == 0 and line >= wave.first and line <= wave.last then
      rank = 1
    elseif line < wave.first then
      local head = wave.first - wave.age
      local distance = line - head
      if distance >= 0 and distance < #burn_colors then rank = distance + 1 end
    end
    if rank and (not brightest or rank < brightest) then brightest = rank end
  end
  return brightest and burn_colors[brightest]
end

function M.apply(frame, state)
  state.color_offset = state.color_offset or 0
  local blocks = state.glitch_blocks or {}
  local waves = state.burn_waves or {}
  local effected = {}
  if state._glitch_color ~= state.color then
    state._glitch_colors, state._glitch_burn_colors = M.palette(state.color)
    state._glitch_color = state.color
  end
  local colors = state._glitch_colors or M.colors
  local burn_colors = state._glitch_burn_colors or M.burn_colors

  for i, item in ipairs(frame) do
    local block = block_at(blocks, i)
    local offset = block and block.offset or (state.glitch_offsets and state.glitch_offsets[i]) or 0
    local burn_color = burn_at(waves, i, burn_colors)
    local filter = burn_color or colors[((i - 1 + state.color_offset) % #colors) + 1]
    effected[i] = {
      line = glitch_line(item.line, offset),
      segments = glitch_segments(item.segments, offset),
      color = filter,
      filter = filter,
      glitch = offset ~= 0,
      glow = burn_color ~= nil,
    }
  end
  return effected
end

function M.advance(state, frame)
  state.color_offset = ((state.color_offset or 0) + 1) % #M.colors

  local blocks = {}
  for _, block in ipairs(state.glitch_blocks or {}) do
    block.ttl = block.ttl - 1
    if block.ttl > 0 then blocks[#blocks + 1] = block end
  end

  for slot = 1, 3 do
    if #blocks < 3 and math.random() < (0.1 / slot) then
      local first = math.random(1, math.max(1, #frame - 1))
      local block = {
        first = first,
        last = math.min(#frame, first + math.random(1, 4)),
        offset = math.random(-4, 4),
        ttl = math.random(1, 3),
        burn = math.random() < 0.35,
      }
      if block.offset == 0 then block.offset = math.random() < 0.5 and -1 or 1 end
      blocks[#blocks + 1] = block
    end
  end
  state.glitch_blocks = blocks

  local waves = {}
  for _, wave in ipairs(state.burn_waves or {}) do
    wave.age = wave.age + 1
    if wave.first - wave.age + #M.burn_colors > 0 then waves[#waves + 1] = wave end
  end
  for _, block in ipairs(blocks) do
    if block.burn and not block.wave_started then
      waves[#waves + 1] = { first = block.first, last = block.last, age = 0 }
      block.wave_started = true
    end
  end
  state.burn_waves = waves
end

return M
