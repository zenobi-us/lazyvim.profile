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
      return opts
    end,
  },
}
