-- Project a connected wave mesh through a fixed camera so its far edge recedes.
local R = require "dashboard-logo.shapes.raster"
local M = { interval = 80, period = 300 }
local columns, rows = 16, 24
local project, draw_edge

function M.render(state)
  local step = (state.wave_grid_step or 0) % M.period
  local color = state.color or "#65ffc1"
  local cache = state._wave_grid
  if cache and cache.step == step and cache.color == color then return cache.frame end

  local canvas = R.new(state)
  local phase = step * 2 * math.pi / M.period
  local previous
  for row = 0, rows do
    local points = {}
    local distance = 12 + 38 * row / rows
    for column = 0, columns do
      local x = -12.8 + 25.6 * column / columns
      local point = project(x, distance, phase)
      points[column + 1] = point
      if column > 0 then draw_edge(canvas, points[column], point) end
      if previous then draw_edge(canvas, previous[column + 1], point) end
    end
    previous = points
  end

  local frame = R.frame(canvas)
  state._wave_grid = { step = step, color = color, frame = frame }
  return frame
end

function M.advance(state)
  state.wave_grid_step = ((state.wave_grid_step or 0) + 1) % M.period
end

project = function(x, distance, phase)
  local first = 0.42 * x + 0.31 * distance - phase
  local second = 0.27 * x - 0.43 * distance + 2 * phase
  local height = 0.95 * math.sin(first) + 0.65 * math.cos(second)
  local dx = 0.95 * 0.42 * math.cos(first) - 0.65 * 0.27 * math.sin(second)
  local dz = 0.95 * 0.31 * math.cos(first) + 0.65 * 0.43 * math.sin(second)
  local scale = 12 / distance
  -- A fixed eye height keeps the horizon still while only the surface moves.
  local light = R.light(-dx, 1, dz)
  return { x * scale, 9 - 17.5 * scale + height * scale, -distance,
    0.18 + 0.52 * scale + 0.22 * light }
end

draw_edge = function(canvas, a, b)
  local dx, dy = 2 * (b[1] - a[1]), b[2] - a[2]
  local glyph = "-"
  if math.abs(dx) < math.abs(dy) * 0.5 then
    glyph = "|"
  elseif math.abs(dy) > math.abs(dx) * 0.3 then
    glyph = dx * dy > 0 and "/" or "\\"
  end
  R.segment(canvas, a, b, (a[4] + b[4]) / 2, glyph)
end

return M
