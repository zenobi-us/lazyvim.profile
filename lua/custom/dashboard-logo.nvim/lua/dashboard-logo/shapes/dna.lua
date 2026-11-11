-- Opaque helical tubes share the rung depth buffer, hiding rear connections.
local R = require "dashboard-logo.shapes.raster"
local M = { interval = 80, period = 300 }
local radius, tube_radius, half_height = 4.5, 0.52, 9
local sections, sides = 96, 8
local twist = 4 * math.pi
local slope = radius * twist / (2 * half_height)
local tangent_length = math.sqrt(1 + slope * slope)
local cross_section = {}
for side = 1, sides do
  local angle = (side - 1) * 2 * math.pi / sides
  cross_section[side] = { math.cos(angle), math.sin(angle) }
end
local draw_rungs, draw_strand, ring, shade_triangle

function M.render(state)
  local step = (state.dna_step or 0) % M.period
  local color = state.color or "#65ffc1"
  local cache = state._dna
  if cache and cache.step == step and cache.color == color then return cache.frame end

  local canvas = R.new(state)
  local phase = step * 2 * math.pi / M.period
  draw_rungs(canvas, phase)
  draw_strand(canvas, phase, 1)
  -- Different strand luminance makes a full turn distinct from a half turn.
  draw_strand(canvas, phase + math.pi, 0.82)

  local frame = R.frame(canvas)
  state._dna = { step = step, color = color, frame = frame }
  return frame
end

function M.advance(state)
  state.dna_step = ((state.dna_step or 0) + 1) % M.period
end

draw_rungs = function(canvas, phase)
  for index = 0, 11 do
    local y = -8.25 + 1.5 * index
    local angle = twist * (y + half_height) / (2 * half_height) + phase
    local x, z = radius * math.cos(angle), radius * math.sin(angle)
    local a = { -x, y, -z }
    for sample = 1, 24 do
      local fraction = -1 + 2 * sample / 24
      local b = { fraction * x, y, fraction * z }
      local nearness = 0.5 + (a[3] + b[3]) / (4 * radius)
      R.segment(canvas, a, b, 0.22 + 0.4 * nearness, "-")
      a = b
    end
  end
end

draw_strand = function(canvas, phase, brightness)
  local previous = ring(0, phase)
  for section = 1, sections do
    local current = ring(section / sections, phase)
    for side = 1, sides do
      local next_side = side % sides + 1
      shade_triangle(canvas, previous[side], current[side], current[next_side], brightness)
      shade_triangle(canvas, previous[side], current[next_side], previous[next_side], brightness)
    end
    previous = current
  end
end

ring = function(fraction, phase)
  local angle = twist * fraction + phase
  local sine, cosine = math.sin(angle), math.cos(angle)
  local x, y, z = radius * cosine, -half_height + 2 * half_height * fraction, radius * sine
  local points = {}
  for side, section in ipairs(cross_section) do
    local radial, across = section[1], section[2]
    -- The second tube axis is perpendicular to both the radius and tangent.
    local nx = radial * cosine + across * sine / tangent_length
    local ny = -across * slope / tangent_length
    local nz = radial * sine - across * cosine / tangent_length
    points[side] = { x + tube_radius * nx, y + tube_radius * ny, z + tube_radius * nz, nx, ny, nz }
  end
  return points
end

shade_triangle = function(canvas, a, b, c, brightness)
  local light = R.light(a[4] + b[4] + c[4], a[5] + b[5] + c[5], a[6] + b[6] + c[6])
  local nearness = 0.5 + (a[3] + b[3] + c[3]) / (6 * (radius + tube_radius))
  local level = brightness * (0.35 + 0.65 * light) * (0.35 + 0.65 * nearness)
  R.triangle(canvas, a, b, c, level)
end

return M
