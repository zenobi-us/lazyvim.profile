return {
  {
    "folke/snacks.nvim",
    dependencies = { "custom/dashboard-logo.nvim" },
    opts = function(_, opts)
      local logo = require("dashboard-logo.snacks").setup({
        logo = "orbit",
        color = vim.api.nvim_get_hl(0, { name = "Special", link = false }).fg,
        update = function()
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "snacks_dashboard" then
              local snacks = rawget(_G, "Snacks")
              if snacks and snacks.dashboard then snacks.dashboard.update() end
              return
            end
          end
        end,
      })
      opts = opts or {}
      opts.dashboard = { sections = { logo.section, { section = "startup" } } }
      opts.picker = opts.picker or {}
      opts.picker.sources = opts.picker.sources or {}
      opts.picker.sources.explorer = opts.picker.sources.explorer or {}
      opts.picker.sources.explorer.layout = {
        preview = false,
        layout = {
          box = "vertical",
          width = 40,
          min_width = 40,
          height = 0,
          position = "left",
          border = "none",
          { win = "list", border = "none" },
        },
      }
      opts.picker.actions = opts.picker.actions or {}
      opts.picker.actions.save_theme = function(picker)
        local item = picker:current()
        local theme = item and (item.text or item.name)
        if not theme or not theme:match "^[%w_%-]+$" then
          vim.notify("No valid colorscheme selected", vim.log.levels.WARN)
          return
        end
        local mise_file = vim.fn.stdpath("config") .. "/.mise.toml"
        vim.system({ "mise", "set", "--file", mise_file, "NEOVIM_THEME_NAME=" .. theme }, { text = true }, function(result)
          vim.schedule(function()
            if result.code == 0 then
              vim.env.NEOVIM_THEME_NAME = theme
              vim.notify("Saved default colorscheme: " .. theme)
            else
              vim.notify("Could not save colorscheme: " .. (result.stderr or "mise failed"), vim.log.levels.ERROR)
            end
          end)
        end)
      end
      opts.picker.win = opts.picker.win or {}
      opts.picker.win.input = opts.picker.win.input or {}
      opts.picker.win.input.keys = opts.picker.win.input.keys or {}
      opts.picker.win.input.keys["<C-s>"] = { "save_theme", mode = { "n", "i" }, desc = "Save theme as mise default" }
      return opts
    end,
  },
}
