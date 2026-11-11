-- Tilted particle orbits share the raster depth buffer and a dark central aperture.
local R = require "dashboard-logo.shapes.raster"
local M = { interval = 80, period = 300 }
local tau = 2 * math.pi
local disc_rotation = R.rotation(0.95, 0, 0.18)
local particles = {}
local orbit_point, draw_particle, mask_centre

function M.render(state)
  local step = (state.accretion_disc_step or 0) % M.period
  local color = state.color or "#65ffc1"
  local cache = state._accretion_disc
  if cache and cache.step == step and cache.color == color then return cache.frame end

  local canvas = R.new(state)
  local angle = tau * step / M.period
  for _, particle in ipairs(particles) do
    draw_particle(canvas, particle, angle)
  end
  mask_centre(canvas)

  local frame = R.frame(canvas)
  state._accretion_disc = { step = step, color = color, frame = frame }
  return frame
end

function M.advance(state)
  state.accretion_disc_step = ((state.accretion_disc_step or 0) + 1) % M.period
end

orbit_point = function(radius, angle)
  local x, y, z = R.transform(disc_rotation, radius * math.cos(angle), radius * math.sin(angle), 0)
  return { x, y, z }
end

draw_particle = function(canvas, particle, angle)
  local head_angle = particle.phase + particle.speed * angle
  local previous = orbit_point(particle.radius, head_angle - particle.trail)
  for sample = 1, 7 do
    local fraction = sample / 7
    local point = orbit_point(particle.radius, head_angle - particle.trail * (1 - fraction))
    local near_side = 0.5 + 0.5 * point[3] / particle.radius
    local brightness = (0.24 + 0.65 * near_side) * (0.25 + 0.75 * fraction)
    R.segment(canvas, previous, point, brightness)
    previous = point
  end
  local near_side = 0.5 + 0.5 * previous[3] / particle.radius
  R.plot(canvas, previous[1], previous[2], previous[3], 0.45 + 0.55 * near_side, "*")
end

mask_centre = function(canvas)
  -- Mask terminal cell centres, so even rounded trail samples cannot fill the aperture.
  for row = -2, 2 do
    for column = -5, 5 do
      local x = column / 2
      if x * x + row * row <= 2.5 * 2.5 then
        R.plot(canvas, x, row, 20, 0, " ")
      end
    end
  end
end

-- Unequal phases and radii keep the flow visible instead of producing a static band.
for ring = 1, 4 do
  local count = 8 + ring * 2
  for index = 1, count do
    particles[#particles + 1] = {
      radius = 3.8 + (ring - 1) * 2.45 + 0.25 * math.sin(index * 2.399 + ring),
      phase = tau * (index - 1) / count + 0.13 * math.sin(index * 1.7 + ring),
      speed = 5 - ring,
      trail = 0.26 + 0.035 * (5 - ring) + 0.04 * math.sin(index * 1.3),
    }
  end
end

return M
