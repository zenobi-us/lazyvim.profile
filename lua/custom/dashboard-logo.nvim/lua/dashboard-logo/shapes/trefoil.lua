-- A closed tube mesh gives the knot real crossings in the shared depth buffer.
local R = require 'dashboard-logo.shapes.raster'
local M = { interval = 80, period = 300 }
local vertices, faces, transformed = {}, {}, {}
local prepare, add_face

function M.render(state)
  prepare()
  local step = (state.trefoil_step or 0) % M.period
  local color = state.color or '#65ffc1'
  local cache = state._trefoil
  if cache and cache.step == step and cache.color == color then return cache.frame end

  local angle = step * 2 * math.pi / M.period
  local rotation = R.rotation(0.45 + 0.55 * math.sin(angle), angle, 0.35 + angle)
  local canvas = R.new(state)
  for index, vertex in ipairs(vertices) do
    local point = transformed[index]
    point[1], point[2], point[3] = R.transform(rotation, vertex[1], vertex[2], vertex[3])
  end
  for _, face in ipairs(faces) do
    local nx, ny, nz = R.transform(rotation, face[4], face[5], face[6])
    if nz < 0 then nx, ny, nz = -nx, -ny, -nz end
    R.triangle(canvas, transformed[face[1]], transformed[face[2]], transformed[face[3]], R.light(nx, ny, nz))
  end
  local frame = R.frame(canvas)
  state._trefoil = { step = step, color = color, frame = frame }
  return frame
end

function M.advance(state)
  state.trefoil_step = ((state.trefoil_step or 0) + 1) % M.period
end

add_face = function(a, b, c)
  local first, second, third = vertices[a], vertices[b], vertices[c]
  local ux, uy, uz = second[1] - first[1], second[2] - first[2], second[3] - first[3]
  local vx, vy, vz = third[1] - first[1], third[2] - first[2], third[3] - first[3]
  faces[#faces + 1] = { a, b, c, uy * vz - uz * vy, uz * vx - ux * vz, ux * vy - uy * vx }
end

prepare = function()
  if #vertices > 0 then return end
  local rings, sides = 144, 12
  local scale, tube_radius = 3, 1.05
  for ring = 0, rings - 1 do
    local t = ring * 2 * math.pi / rings
    local c2, s2, c3, s3 = math.cos(2 * t), math.sin(2 * t), math.cos(3 * t), math.sin(3 * t)
    local radius = 2 + c3
    local cx, cy, cz = scale * radius * c2, scale * radius * s2, scale * s3
    local tx, ty, tz = -3 * s3 * c2 - 2 * radius * s2, -3 * s3 * s2 + 2 * radius * c2, 3 * c3
    local tangent_length = math.sqrt(tx * tx + ty * ty + tz * tz)
    tx, ty, tz = tx / tangent_length, ty / tangent_length, tz / tangent_length

    -- Projecting the radial direction avoids frame flips and closes without a seam.
    local radial_dot = c2 * tx + s2 * ty
    local nx, ny, nz = c2 - radial_dot * tx, s2 - radial_dot * ty, -radial_dot * tz
    local normal_length = math.sqrt(nx * nx + ny * ny + nz * nz)
    nx, ny, nz = nx / normal_length, ny / normal_length, nz / normal_length
    local bx, by, bz = ty * nz - tz * ny, tz * nx - tx * nz, tx * ny - ty * nx
    for side = 0, sides - 1 do
      local around = side * 2 * math.pi / sides
      local normal_weight, binormal_weight = tube_radius * math.cos(around), tube_radius * math.sin(around)
      vertices[#vertices + 1] = {
        cx + normal_weight * nx + binormal_weight * bx,
        cy + normal_weight * ny + binormal_weight * by,
        cz + normal_weight * nz + binormal_weight * bz,
      }
      transformed[#transformed + 1] = { 0, 0, 0 }
    end
  end
  for ring = 0, rings - 1 do
    local next_ring = (ring + 1) % rings
    for side = 0, sides - 1 do
      local next_side = (side + 1) % sides
      local a, b = ring * sides + side + 1, ring * sides + next_side + 1
      local c, d = next_ring * sides + next_side + 1, next_ring * sides + side + 1
      add_face(a, b, c)
      add_face(a, c, d)
    end
  end
end

return M
