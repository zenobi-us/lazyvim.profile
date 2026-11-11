-- Opaque shaded planets and their orbit hints share the star's depth buffer.
local R = require "dashboard-logo.shapes.raster"
local M = { interval = 80, period = 300 }
local tau = 2 * math.pi
local planets = {
  { radius = 4.5, ellipse = 0.88, size = 1.05, speed = 3, phase = 0.4, rotation = R.rotation(1.02, 0, 0.18) },
  { radius = 7.8, ellipse = 0.90, size = 1.35, speed = 2, phase = 2.2, rotation = R.rotation(0.65, 0, -0.2) },
  { radius = 11.2, ellipse = 0.91, size = 1.65, speed = 1, phase = 4.5, rotation = R.rotation(0.73, 0, 0.12) },
}
local orbit_point, prepare_orbits
local orbit_hints

function M.render(state)
  local step = (state.planetary_system_step or 0) % M.period
  local color = state.color or "#65ffc1"
  local cache = state._planetary_system
  if cache and cache.step == step and cache.color == color then return cache.frame end

  prepare_orbits()
  local canvas = R.new(state)
  for _, segment in ipairs(orbit_hints) do
    R.segment(canvas, segment[1], segment[2], 0.12, ".")
  end

  R.sphere(canvas, 0, 0, 0, 1.7, 0.94)
  local angle = tau * step / M.period
  for _, planet in ipairs(planets) do
    local point = orbit_point(planet, planet.phase + planet.speed * angle)
    R.sphere(canvas, point[1], point[2], point[3], planet.size)
  end

  local frame = R.frame(canvas)
  state._planetary_system = { step = step, color = color, frame = frame }
  return frame
end

function M.advance(state)
  state.planetary_system_step = ((state.planetary_system_step or 0) + 1) % M.period
end

orbit_point = function(planet, angle)
  local x, y, z = R.transform(
    planet.rotation,
    planet.radius * math.cos(angle),
    planet.radius * planet.ellipse * math.sin(angle),
    0
  )
  return { x, y, z }
end

prepare_orbits = function()
  if orbit_hints then return end
  orbit_hints = {}
  for _, planet in ipairs(planets) do
    for sample = 0, 95 do
      -- Gaps distinguish subdued orbit guides from the solid planetary silhouettes.
      if sample % 3 == 0 then
        orbit_hints[#orbit_hints + 1] = {
          orbit_point(planet, tau * sample / 96),
          orbit_point(planet, tau * (sample + 1) / 96),
        }
      end
    end
  end
end

return M
