return {
  {
    name = "mousepeasant-popup",
    dir = vim.fn.stdpath("config") .. "/lua/custom/mouse-peasant/popup.nvim",
    event = "VeryLazy",
    opts = function()
      local items = { require("plugins.popups.lsp").menus }
      vim.list_extend(items, require("plugins.popups.neotree").menus)
      return { menus = { PopUp = items } }
    end,
    config = function(_, opts) require("mousepeasant-popup").setup(opts) end,
  },
}
