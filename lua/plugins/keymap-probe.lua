return {
  dir = vim.fn.stdpath("config") .. "/lua/custom/keymap-probe",
  name = "keymap-probe.nvim",
  lazy = false,
  config = function()
    vim.api.nvim_create_user_command("KeymapProbe", function()
      require("keymap-probe").open()
    end, { desc = "Open the keymap diagnostics probe" })
  end,
}
