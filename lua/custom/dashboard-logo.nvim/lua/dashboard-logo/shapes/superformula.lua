-- A shared-vertex superformula mesh changes its silhouette, not just its pose.
local R = require "dashboard-logo.shapes.raster"
local M = { interval = 80, period = 300 }
local longitude_count, latitude_count = 48, 16
local radius = 9.6
local longitudes, latitudes, faces
local prepare, deform, fill_face

function M.render(state)
  local step = state.superformula_step or 0
  local color = state.color or "#65ffc1"
  local cache = state._superformula
  if cache and cache.step == step and cache.color == color then return cache.frame end
  prepare()
  if not cache then
    cache = { vertices = {}, radial = {} }
    state._superformula = cache
  end

  local phase = 2 * math.pi * step / M.period
  local morph = (1 - math.cos(phase)) / 2
  local rotation = R.rotation(0.32 + 0.12 * math.sin(phase), 0.25 * math.sin(phase), phase)
  deform(cache, morph, rotation)
  local canvas = R.new(state)
  for _, face in ipairs(faces) do
    fill_face(canvas, cache.vertices[face[1]], cache.vertices[face[2]], cache.vertices[face[3]])
  end
  cache.step, cache.color, cache.frame = step, color, R.frame(canvas)
  return cache.frame
end

function M.advance(state)
  state.superformula_step = ((state.superformula_step or 0) + 1) % M.period
end

prepare = function()
  if longitudes then return end
  longitudes, latitudes, faces = {}, {}, {}
  for index = 0, longitude_count - 1 do
    local angle = 2 * math.pi * index / longitude_count
    longitudes[index + 1] = {
      math.cos(angle), math.sin(angle),
      math.abs(math.cos(6 * angle / 4)), math.abs(math.sin(6 * angle / 4)),
    }
  end
  for index = 1, latitude_count - 1 do
    local angle = -math.pi / 2 + math.pi * index / latitude_count
    latitudes[index] = { math.cos(angle), math.sin(angle) }
  end

  -- One vertex per pole and wrapped longitude indices close both mesh seams.
  local north = 2 + longitude_count * #latitudes
  for column = 1, longitude_count do
    local next_column = column % longitude_count + 1
    faces[#faces + 1] = { 1, 1 + next_column, 1 + column }
    for row = 1, #latitudes - 1 do
      local lower = 1 + (row - 1) * longitude_count
      local upper = lower + longitude_count
      faces[#faces + 1] = { lower + column, lower + next_column, upper + next_column }
      faces[#faces + 1] = { lower + column, upper + next_column, upper + column }
    end
    local last = 1 + (#latitudes - 1) * longitude_count
    faces[#faces + 1] = { last + column, last + next_column, north }
  end
end

deform = function(cache, morph, rotation)
  -- n=2 gives a circle; decreasing n and n1 deepens six valleys continuously.
  local exponent, power = 2 - 1.7 * morph, -1 / (2 - 1.25 * morph)
  for index, sample in ipairs(longitudes) do
    cache.radial[index] = (sample[3] ^ exponent + sample[4] ^ exponent) ^ power
  end

  local vertex_count = 2 + longitude_count * #latitudes
  for index = #cache.vertices + 1, vertex_count do cache.vertices[index] = {} end
  local south, north = cache.vertices[1], cache.vertices[vertex_count]
  south[1], south[2], south[3] = R.transform(rotation, 0, 0, -radius * 0.82)
  north[1], north[2], north[3] = R.transform(rotation, 0, 0, radius * 0.82)
  for row, latitude in ipairs(latitudes) do
    local cosine, sine = latitude[1], latitude[2]
    for column, longitude in ipairs(longitudes) do
      -- Fade the longitude deformation at the poles so their tangent is smooth.
      local ring_radius = radius * cosine * (1 + (cache.radial[column] - 1) * cosine * cosine)
      local vertex = cache.vertices[1 + (row - 1) * longitude_count + column]
      vertex[1], vertex[2], vertex[3] = R.transform(
        rotation, ring_radius * longitude[1], ring_radius * longitude[2], radius * 0.82 * sine
      )
    end
  end
end

fill_face = function(canvas, a, b, c)
  local abx, aby, abz = b[1] - a[1], b[2] - a[2], b[3] - a[3]
  local acx, acy, acz = c[1] - a[1], c[2] - a[2], c[3] - a[3]
  local nx, ny, nz = aby * acz - abz * acy, abz * acx - abx * acz, abx * acy - aby * acx
  if nz > 1e-9 then R.triangle(canvas, a, b, c, R.light(nx, ny, nz)) end
end

return M
