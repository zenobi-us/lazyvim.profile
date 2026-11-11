-- Overlapping blade meshes sweep around a real, uncovered polygonal aperture.
local R = require "dashboard-logo.shapes.raster"
local M = { interval = 80, period = 300 }
local blade_count, blade_samples, rim_samples = 8, 24, 64
local blade_radius, rim_inner, rim_outer = 9.45, 9, 10.3
local sector = 2 * math.pi / blade_count
local offsets, rim
local prepare, draw_blade, draw_rim, highlight

function M.render(state)
  local step = state.iris_step or 0
  local color = state.color or "#65ffc1"
  local cache = state._iris
  if cache and cache.step == step and cache.color == color then return cache.frame end
  prepare()
  if not cache then
    cache = { blades = {} }
    state._iris = cache
    for blade = 1, blade_count do
      local vertices = {}
      for index = 1, #offsets do vertices[index] = {} end
      cache.blades[blade] = vertices
    end
  end

  local phase = 2 * math.pi * step / M.period
  local opening = (1 - math.cos(phase)) / 2
  local aperture = 1.2 + 4.2 * opening
  -- A cutting edge one unit inside a fixed radius-eight pivot rotates rigidly.
  local sweep = math.acos((aperture + 1) / 8)
  local canvas = R.new(state)
  for blade = 1, blade_count do
    draw_blade(canvas, cache.blades[blade], (blade - 1) * sector + sweep, aperture, blade)
  end
  draw_rim(canvas)
  cache.step, cache.color, cache.frame = step, color, R.frame(canvas)
  return cache.frame
end

function M.advance(state)
  state.iris_step = ((state.iris_step or 0) + 1) % M.period
end

prepare = function()
  if offsets then return end
  offsets, rim = {}, {}
  for index = 0, blade_samples do offsets[index + 1] = index / blade_samples end
  for index = 0, rim_samples - 1 do
    local angle = 2 * math.pi * index / rim_samples
    local cosine, sine = math.cos(angle), math.sin(angle)
    rim[index + 1] = {
      { rim_inner * cosine, rim_inner * sine, 1.8 },
      { rim_outer * cosine, rim_outer * sine, 1.8 },
    }
  end
end

draw_blade = function(canvas, vertices, angle, aperture, blade)
  local nx, ny = math.cos(angle), math.sin(angle)
  local tx, ty = -ny, nx
  local half_arc = math.acos(aperture / blade_radius)
  for index, fraction in ipairs(offsets) do
    -- Sample the blade's visible circular clip; its actual tail is under the rim.
    local offset = half_arc * (2 * fraction - 1)
    local radial, lateral = blade_radius * math.cos(offset), blade_radius * math.sin(offset)
    local vertex = vertices[index]
    vertex[1], vertex[2], vertex[3] = radial * nx + lateral * tx, radial * ny + lateral * ty, 0.12 * lateral
  end

  -- A shallow slope gives cyclic shingle overlaps without a special top blade.
  local brightness = 0.34 + 0.5 * R.light(-0.12 * tx, -0.12 * ty, 1) + 0.055 * (blade % 2)
  for index = 2, #vertices - 1 do
    R.triangle(canvas, vertices[1], vertices[index], vertices[index + 1], brightness)
  end
  -- The closing chord lies on n dot p = aperture and cannot cross the hole.
  highlight(canvas, vertices[1], vertices[#vertices], 0.96)
end

draw_rim = function(canvas)
  for index, points in ipairs(rim) do
    local next_points = rim[index % #rim + 1]
    local middle_x = points[2][1] + next_points[2][1]
    local middle_y = points[2][2] + next_points[2][2]
    local brightness = 0.35 + 0.5 * R.light(middle_x, middle_y, 15)
    R.triangle(canvas, points[1], points[2], next_points[2], brightness)
    R.triangle(canvas, points[1], next_points[2], next_points[1], brightness)
    highlight(canvas, points[1], next_points[1], 0.91)
  end
end

highlight = function(canvas, a, b, brightness)
  -- Lift only the boundary enough to survive its own face's depth test.
  R.segment(canvas, { a[1], a[2], a[3] + 0.015 }, { b[1], b[2], b[3] + 0.015 }, brightness)
end

return M
