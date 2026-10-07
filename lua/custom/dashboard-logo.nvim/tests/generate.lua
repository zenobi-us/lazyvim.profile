local root = arg[0]:gsub("\\", "/"):match "^(.*)/tests/[^/]+$"
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path
local logo = dofile(root .. "/lua/dashboard-logo/init.lua")
local lines = logo.logos[logo.logos.default]
local frame = logo.generate { color_offset = 0, glitch_offsets = {} }
local rendered = logo.render()
local plain = logo.generate({}, nil, "none")

local function luminance(color)
  local channels = { color:match "#(%x%x)(%x%x)(%x%x)" }
  for i, channel in ipairs(channels) do
    channel = tonumber(channel, 16) / 255
    channels[i] = channel <= 0.04045 and channel / 12.92 or ((channel + 0.055) / 1.055) ^ 2.4
  end
  return 0.2126 * channels[1] + 0.7152 * channels[2] + 0.0722 * channels[3]
end

assert(logo.logos.default == "grudge_axe")
assert(#frame == #lines)
assert(rendered[1].line == lines[1] and rendered[1].color == nil)
assert(plain[1].line == lines[1] and plain[1].color == nil)
assert(frame[1].line == lines[1])
assert(frame[1].color == logo.effects.glitch.colors[1])
assert(frame[#logo.effects.glitch.colors + 1].color == logo.effects.glitch.colors[1])
assert(logo.filter_color("#ffffff", "#16802d") == "#16802d")
assert(logo.filter_color("#000000", "#16802d") == "#000000")

local custom_colors, custom_burn_colors = logo.effects.glitch.palette "#c678dd"
assert(#custom_colors == #logo.effects.glitch.colors)
assert(#custom_burn_colors == #logo.effects.glitch.burn_colors)
assert(custom_colors[1] ~= logo.effects.glitch.colors[1])
assert(logo.effects.glitch.palette() == logo.effects.glitch.colors)
for i, value in ipairs(custom_colors) do
  assert(math.abs(luminance(value) - luminance(logo.effects.glitch.colors[i])) < 0.003)
end
for i, value in ipairs(custom_burn_colors) do
  assert(math.abs(luminance(value) - luminance(logo.effects.glitch.burn_colors[i])) < 0.003)
end

local custom_frame = logo.generate({ color = "#c678dd" })
assert(custom_frame[1].color == custom_colors[1])

local ansi = logo.render "grudge_axe"
assert(ansi[1].segments[1].color == "#000000")

local block_frame = logo.generate({
  color_offset = 0,
  glitch_blocks = { { first = 4, last = 8, offset = 2, ttl = 2 } },
  burn_waves = {},
})
assert(block_frame[3].line == lines[3])
assert(block_frame[4].line == "  " .. lines[4])
assert(block_frame[8].line == "  " .. lines[8])
assert(block_frame[9].line == lines[9])

local neovim_lines = logo.logos.neovim
local clipped_frame = logo.generate({
  color_offset = 0,
  glitch_blocks = { { first = #neovim_lines, last = #neovim_lines, offset = -4, ttl = 2 } },
  burn_waves = {},
}, "neovim")
assert(clipped_frame[#neovim_lines].line == "")
assert(clipped_frame[#neovim_lines].segments[1].text == "")

local burn_frame = logo.generate({
  color_offset = 0,
  glitch_blocks = { { first = 4, last = 8, offset = -1, ttl = 2, burn = true } },
  burn_waves = { { first = 4, last = 8, age = 0 } },
})
assert(burn_frame[4].color == logo.effects.glitch.burn_colors[1])
assert(burn_frame[8].color == logo.effects.glitch.burn_colors[1])

local wave_frame = logo.generate({
  color_offset = 0,
  glitch_blocks = {},
  burn_waves = { { first = 4, last = 8, age = 2 } },
})
assert(wave_frame[2].color == logo.effects.glitch.burn_colors[1])
assert(wave_frame[3].color == logo.effects.glitch.burn_colors[2])
assert(wave_frame[4].color == logo.effects.glitch.colors[((4 - 1) % #logo.effects.glitch.colors) + 1])

local random = math.random
math.random = function() return 1 end
local wave_state = {
  glitch_blocks = { { first = 4, last = 8, offset = 1, ttl = 2, burn = true, wave_started = true } },
  burn_waves = { { first = 4, last = 8, age = 0 } },
}
logo.advance(wave_state)
math.random = random
assert(wave_state.burn_waves[1].age == 1)
assert(wave_state.glitch_blocks[1].ttl == 1)

local updated
local animation = logo.new { update = function(next_frame) updated = next_frame end }
assert(#animation.frame() == #lines)
animation.tick()
assert(updated and #updated == #lines)

local custom_animation = logo.new { color = "#c678dd" }
assert(custom_animation.frame()[1].color == custom_colors[1])

local no_effect = logo.new { effect = "none" }
assert(no_effect.frame()[1].color == nil)

print "dashboard logo generation: ok"
