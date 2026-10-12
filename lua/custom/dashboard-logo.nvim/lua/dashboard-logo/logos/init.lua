local segment = require "dashboard-logo.segments"

local source = debug.getinfo(1, "S").source:sub(2):gsub("\\", "/")
local directory = assert(source:match "^(.*)/[^/]+$")

local function parse_line(line)
  local plain = {}
  local segments = {}
  local color
  local position = 1

  local function append(text)
    if text == "" then return end
    plain[#plain + 1] = text
    local previous = segments[#segments]
    if previous and previous.color == color then
      previous.text = previous.text .. text
    else
      segments[#segments + 1] = { text = text, color = color }
    end
  end

  while position <= #line do
    local first, last, codes = line:find("\27%[([%d;]*)m", position)
    if not first then
      append(line:sub(position))
      break
    end
    append(line:sub(position, first - 1))

    local values = {}
    for value in (codes .. ";"):gmatch "(%d*);" do
      values[#values + 1] = tonumber(value) or 0
    end
    local i = 1
    while i <= #values do
      if values[i] == 0 or values[i] == 39 then
        color = nil
      elseif values[i] == 38 and values[i + 1] == 2 then
        assert(values[i + 4], "incomplete ANSI RGB colour")
        color = ("#%02x%02x%02x"):format(values[i + 2], values[i + 3], values[i + 4])
        i = i + 4
      end
      i = i + 1
    end
    position = last + 1
  end

  local text = table.concat(plain)
  assert(not text:find("\27", 1, true), "unsupported ANSI escape sequence")
  if #segments == 0 then segments[1] = { text = "" } end
  return text, segments
end

-- Trim the trailing blanks and the shared left margin, then pad every line to
-- one width. The block then centres on the art itself, and each line keeps its
-- column positions relative to the others.
local function normalise(lines)
  local margin, width = math.huge, 0
  for i = 1, #lines do
    local text = (lines[i]:gsub(" +$", ""))
    lines[i] = text
    lines.segments[i] = segment.fit(lines.segments[i], #text)
    if #text > 0 then
      margin = math.min(margin, #text:match "^ *")
      width = math.max(width, #text)
    end
  end
  if margin == math.huge then margin = 0 end
  width = math.max(0, width - margin)

  for i = 1, #lines do
    local text = lines[i]:sub(margin + 1)
    lines[i] = text .. (" "):rep(width - #text)
    lines.segments[i] = segment.fit(segment.drop(lines.segments[i], margin), width)
  end
  lines.width = width
  return lines
end

local function load(name)
  local file = assert(io.open(directory .. "/" .. name .. ".ansi", "rb"))
  local content = file:read "*a"
  file:close()
  content = content:gsub("\r\n", "\n"):gsub("\n$", "")

  local lines = { segments = {} }
  for line in (content .. "\n"):gmatch "(.-)\n" do
    local text, segments = parse_line(line)
    lines[#lines + 1] = text
    lines.segments[#lines] = segments
  end
  return normalise(lines)
end

return {
  default = "grudge_axe",
  neovim = load "neovim",
  grudge_axe = load "grudge_axe",
  ancestor_core = load "ancestor_core",
  data_beard = load "data_beard",
  orbit = load "orbit",
}
