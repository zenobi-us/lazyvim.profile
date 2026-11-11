-- Snacks owns the gallery windows; this module owns only its isolated animation.
-- Preview frames use the same renderer as the dashboard without applying a choice.
local M = {}
local active, closing_picker
local open_gallery, stop_preview, close_gallery

---@param controller {current: fun(): table, apply: fun(selection: table), color?: string}
---@return snacks.Picker
function M.open(controller)
  M.close()
  -- Snacks defers window destruction after close(). Remove the previous
  -- layout before creating another gallery, including close-then-open calls.
  if closing_picker and closing_picker.layout and not closing_picker.layout.closed then
    closing_picker.layout:close()
  end
  closing_picker = nil
  return open_gallery(controller)
end

function M.close()
  if not active then return end
  if active.picker and not active.picker.closed then
    active.picker:close()
  else
    close_gallery(active)
  end
end

local function selection(item)
  return { kind = item.kind, name = item.name, effect = item.effect }
end

local function same_selection(left, right)
  return left.kind == right.kind and left.name == right.name and left.effect == right.effect
end

local function gallery_items(current)
  local core = require "dashboard-logo"
  local items = {}
  for kind, registry in pairs({ shape = core.shapes, logo = core.logos }) do
    for name in pairs(registry) do
      if name ~= "default" then
        for effect in pairs(core.effects) do
          if effect ~= "default" then
            local item = { kind = kind, name = name, effect = effect }
            item.current = same_selection(item, current)
            item.text = (kind == "shape" and "Shape" or "Logo") .. " " .. name .. " " .. effect
            items[#items + 1] = item
          end
        end
      end
    end
  end
  table.sort(items, function(left, right)
    if left.current ~= right.current then return left.current end
    if left.kind ~= right.kind then return left.kind < right.kind end
    if left.name ~= right.name then return left.name < right.name end
    if left.effect == "none" then return right.effect ~= "none" end
    if right.effect == "none" then return false end
    return left.effect < right.effect
  end)
  return items
end

local function clear_buffer(buf)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
end

stop_preview = function(session, clear)
  -- A stopped uv timer may already have queued a scheduled Lua callback.
  session.generation = session.generation + 1
  if session.timer then
    session.timer:stop()
    if not session.timer:is_closing() then session.timer:close() end
    session.timer = nil
  end
  if clear then clear_buffer(session.buf) end
  session.buf, session.win = nil, nil
end

close_gallery = function(session)
  if session.closed then return end
  session.closed = true
  closing_picker = session.picker
  stop_preview(session, true)
  if session.group then vim.api.nvim_del_augroup_by_id(session.group) end
  session.animation, session.frame, session.item = nil, nil, nil
  if active == session then active = nil end
end

local function frame_size(frame)
  local width = 0
  for _, row in ipairs(frame) do
    width = math.max(width, vim.fn.strdisplaywidth(row.line))
  end
  return width, #frame
end

local list_width = 40

local function preview_fits(session)
  if not session.item or not session.frame or session.blocked then return false end
  local width, height = frame_size(session.frame)
  local tabline = vim.o.showtabline == 2 or (vim.o.showtabline == 1 and #vim.api.nvim_list_tabpages() > 1)
  local available_height = vim.o.lines - vim.o.cmdheight - (vim.o.laststatus == 0 and 0 or 1)
    - (tabline and 1 or 0) - 2
  return width <= vim.o.columns - list_width - 2 and height <= available_height
end

local function layout_config(session)
  return {
    cycle = false,
    hidden = preview_fits(session) and {} or { "preview" },
    layout = {
      box = "horizontal",
      width = 0,
      height = 0,
      border = "none",
      {
        box = "vertical",
        width = function() return preview_fits(session) and list_width or 0 end,
        border = true,
        title = " {title} ",
        { win = "input", height = 1, border = "bottom" },
        { win = "list", border = "none" },
      },
      { win = "preview", title = " {preview} ", border = true },
    },
  }
end

local function update_preview_visibility(session, picker)
  local show = preview_fits(session)
  if picker.layout:is_hidden("preview") == show then
    stop_preview(session, true)
    picker:toggle("preview", { enable = show })
  end
end

local function change_item(session, picker, item)
  session.picker = picker
  if session.closed then return end
  if session.item ~= item then
    stop_preview(session, true)
    session.item, session.animation, session.frame, session.blocked = item, nil, nil, nil
    if item then
      local opts = { effect = item.effect, color = session.controller.color }
      opts[item.kind == "shape" and "shape" or "logo"] = item.name
      session.animation = require("dashboard-logo").new(opts)
      session.frame = session.animation.frame()
    end
  elseif not item then
    stop_preview(session, true)
  end
  update_preview_visibility(session, picker)
end

local function preview_valid(session, generation, buf, win)
  local picker = session.picker
  return not session.closed and session.generation == generation
    and picker and not picker.closed and picker.preview
    and not picker.layout:is_hidden("preview")
    and picker.preview.win:valid()
    and picker.preview.win.buf == buf and picker.preview.win.win == win
    and vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_win_is_valid(win)
    and vim.api.nvim_win_get_buf(win) == buf
    and vim.api.nvim_win_get_tabpage(win) == vim.api.nvim_get_current_tabpage()
    and not vim.api.nvim_win_get_config(win).hide
    and picker:current() == session.item
end

local function hide_unfitted_preview(session)
  session.blocked = { columns = vim.o.columns, lines = vim.o.lines }
  stop_preview(session, true)
  local picker = session.picker
  if not session.closed and picker and not picker.closed then
    picker:toggle("preview", { enable = false })
  end
end

local function show_preview(session, ctx)
  if session.closed then return end
  change_item(session, ctx.picker, ctx.item)
  if not preview_fits(session) then return end
  stop_preview(session, true)
  ctx.preview:reset()
  ctx.preview:minimal()
  ctx.preview:wo({ wrap = false, foldenable = false, scrolloff = 0, sidescrolloff = 0 })
  ctx.preview:set_title(ctx.item.text)
  local buf, win = ctx.buf, ctx.win
  session.buf, session.win = buf, win
  local generation = session.generation
  if not preview_valid(session, generation, buf, win) then
    stop_preview(session, true)
    return
  end
  local display = require "dashboard-logo.display"
  if not display.draw(buf, win, session.frame) then
    hide_unfitted_preview(session)
    return
  end
  local timer = assert((vim.uv or vim.loop).new_timer())
  session.timer = timer
  local pending = false
  timer:start(session.animation.interval, session.animation.interval, function()
    if pending then return end
    pending = true
    vim.schedule(function()
      pending = false
      if session.generation ~= generation then return end
      if not preview_valid(session, generation, buf, win) then
        stop_preview(session, true)
        return
      end
      session.frame = session.animation.tick()
      if not display.draw(buf, win, session.frame) then hide_unfitted_preview(session) end
    end)
  end)
end

local function resize_preview(session)
  if session.closed then return end
  stop_preview(session, true)
  -- Hiding an unfitted preview itself resizes the list. Retry only when the
  -- terminal changes, rather than repeatedly reopening the same unfitted art.
  if session.blocked and (session.blocked.columns ~= vim.o.columns or session.blocked.lines ~= vim.o.lines) then
    session.blocked = nil
  end
  if session.resize_pending then return end
  session.resize_pending = true
  vim.schedule(function()
    session.resize_pending = false
    local picker = session.picker
    if session.closed or not picker or picker.closed then return end
    update_preview_visibility(session, picker)
    picker.preview.item = nil
    picker:show_preview()
  end)
end

local function attach_events(session)
  session.group = vim.api.nvim_create_augroup("DashboardLogoGallery", { clear = true })
  vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
    group = session.group,
    callback = function() resize_preview(session) end,
  })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = session.group,
    callback = function(event)
      if tonumber(event.match) == session.win then stop_preview(session, true) end
    end,
  })
  vim.api.nvim_create_autocmd({ "BufHidden", "BufWipeout" }, {
    group = session.group,
    callback = function(event)
      if event.buf == session.buf then stop_preview(session, event.event ~= "BufWipeout") end
    end,
  })
end

local function confirm(session, picker, save)
  local item = picker:current()
  if session.closed or not item then return end
  local chosen = selection(item)
  if save then
    local ok, err = require("dashboard-logo.selection").save(chosen)
    if not ok then
      vim.notify("Could not save dashboard logo: " .. tostring(err), vim.log.levels.ERROR, { title = "Dashboard gallery" })
      return
    end
  end
  session.controller.apply(chosen)
  picker:close()
end

open_gallery = function(controller)
  local session = { controller = controller, generation = 0, closed = false }
  active = session
  local items = gallery_items(controller.current())
  session.item = items[1]
  if session.item then
    local opts = { effect = session.item.effect, color = controller.color }
    opts[session.item.kind == "shape" and "shape" or "logo"] = session.item.name
    session.animation = require("dashboard-logo").new(opts)
    session.frame = session.animation.frame()
  end
  attach_events(session)
  local keys = {
    ["<Esc>"] = { "close", mode = { "n", "i" } },
    ["<CR>"] = { "confirm", mode = { "n", "i" } },
    ["<C-s>"] = { "dashboard_save", mode = { "n", "i" }, desc = "Save and apply dashboard logo" },
  }
  local picker = Snacks.picker.pick({
    title = "Gallery · Enter apply · C-s save",
    items = items,
    pattern = "",
    search = "",
    focus = "input",
    show_delay = 0,
    show_empty = true,
    auto_confirm = false,
    matcher = { sort_empty = false, filename_bonus = false, file_pos = false },
    sort = { fields = { "score:desc", "idx" } },
    layout = function() return layout_config(session) end,
    format = function(item)
      return {
        { item.current and "* " or "  ", "Special" },
        { item.kind == "shape" and "Shape " or "Logo  ", "Type" },
        { ("%-18s "):format(item.name), "SnacksPickerLabel" },
        { item.effect, "SnacksPickerComment" },
      }
    end,
    preview = function(ctx) show_preview(session, ctx) end,
    on_change = function(instance, item) change_item(session, instance, item) end,
    on_show = function(instance) session.picker = instance end,
    on_close = function() close_gallery(session) end,
    confirm = function(instance) confirm(session, instance, false) end,
    actions = {
      dashboard_save = function(instance) confirm(session, instance, true) end,
    },
    win = {
      input = { keys = keys },
      list = { keys = vim.deepcopy(keys) },
      preview = {
        minimal = true,
        keys = vim.deepcopy(keys),
        wo = { wrap = false, number = false, relativenumber = false, signcolumn = "no" },
      },
    },
  })
  session.picker = picker
  return picker
end

return M
