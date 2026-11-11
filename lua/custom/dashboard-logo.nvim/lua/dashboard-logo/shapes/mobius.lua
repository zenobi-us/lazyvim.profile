-- The seam reverses the ribbon width, making one continuous half-twisted surface.
local R = require 'dashboard-logo.shapes.raster'
local M = { interval = 80, period = 300 }
local vertices, faces, transformed = {}, {}, {}
local prepare, add_face

function M.render(state)
  prepare()
  local step = (state.mobius_step or 0) % M.period
  local color = state.color or '#65ffc1'
  local cache = state._mobius
  if cache and cache.step == step and cache.color == color then return cache.frame end

  local angle = step * 2 * math.pi / M.period
  local rotation = R.rotation(0.65 + angle, 0.3 * math.sin(angle), 0.45 + angle)
  local canvas = R.new(state)
  for index, vertex in ipairs(vertices) do
    local point = transformed[index]
    point[1], point[2], point[3] = R.transform(rotation, vertex[1], vertex[2], vertex[3])
  end
  for _, face in ipairs(faces) do
    local nx, ny, nz = R.transform(rotation, face[4], face[5], face[6])
    -- A Mobius surface has no global outside; light whichever side faces the viewer.
    if nz < 0 then nx, ny, nz = -nx, -ny, -nz end
    R.triangle(canvas, transformed[face[1]], transformed[face[2]], transformed[face[3]], R.light(nx, ny, nz))
  end
  local frame = R.frame(canvas)
  state._mobius = { step = step, color = color, frame = frame }
  return frame
end

function M.advance(state)
  state.mobius_step = ((state.mobius_step or 0) + 1) % M.period
end

add_face = function(a, b, c)
  local first, second, third = vertices[a], vertices[b], vertices[c]
  local ux, uy, uz = second[1] - first[1], second[2] - first[2], second[3] - first[3]
  local vx, vy, vz = third[1] - first[1], third[2] - first[2], third[3] - first[3]
  faces[#faces + 1] = { a, b, c, uy * vz - uz * vy, uz * vx - ux * vz, ux * vy - uy * vx }
end

prepare = function()
  if #vertices > 0 then return end
  local rings, strips = 144, 8
  local radius, half_width = 6.3, 3.2
  local stride = strips + 1
  for ring = 0, rings - 1 do
    local angle = ring * 2 * math.pi / rings
    local cosine, sine = math.cos(angle), math.sin(angle)
    local half_cosine, half_sine = math.cos(angle / 2), math.sin(angle / 2)
    for strip = 0, strips do
      local width = half_width * (2 * strip / strips - 1)
      local radial = radius + width * half_cosine
      vertices[#vertices + 1] = { radial * cosine, radial * sine, width * half_sine }
      transformed[#transformed + 1] = { 0, 0, 0 }
    end
  end
  for ring = 0, rings - 1 do
    for strip = 0, strips - 1 do
      local a = ring * stride + strip + 1
      local b = a + 1
      local c, d
      if ring == rings - 1 then
        -- P(2*pi, v) = P(0, -v): share the first ring in reversed order.
        c, d = strips - strip, strips - strip + 1
      else
        c = (ring + 1) * stride + strip + 2
        d = c - 1
      end
      add_face(a, b, c)
      add_face(a, c, d)
    end
  end
end

return M
