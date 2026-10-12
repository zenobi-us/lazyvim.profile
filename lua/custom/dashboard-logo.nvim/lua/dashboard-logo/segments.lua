-- Segment helpers that keep a line's coloured segments in step with its plain
-- text. Every logo line is padded to one canvas width, because both frontends
-- centre each line on its own extent; a ragged canvas therefore shears the art
-- and pushes the block off centre.
local M = {}

---Remove `count` leading characters from a segment list.
---@param segments table[]
---@param count integer
---@return table[]
function M.drop(segments, count)
  if count <= 0 then return segments end
  local kept = {}
  for _, segment in ipairs(segments) do
    if count >= #segment.text then
      count = count - #segment.text
    else
      kept[#kept + 1] = { text = segment.text:sub(count + 1), color = segment.color }
      count = 0
    end
  end
  if #kept == 0 then kept[1] = { text = "" } end
  return kept
end

---Truncate or space-pad a segment list so it measures exactly `width`.
---The logos are ASCII, so a byte count is the display width.
---@param segments table[]
---@param width integer
---@return table[]
function M.fit(segments, width)
  local kept = {}
  local length = 0
  for _, segment in ipairs(segments) do
    if length >= width then break end
    local text = segment.text
    if length + #text > width then text = text:sub(1, width - length) end
    if #text > 0 then
      kept[#kept + 1] = { text = text, color = segment.color }
      length = length + #text
    end
  end
  if length < width then kept[#kept + 1] = { text = (" "):rep(width - length) } end
  if #kept == 0 then kept[1] = { text = "" } end
  return kept
end

return M
