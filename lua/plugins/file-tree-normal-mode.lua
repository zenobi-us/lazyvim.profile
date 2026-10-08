-- Always enter the Snacks file tree in Normal mode.
return {
  {
    "folke/snacks.nvim",
    init = function()
      local group = vim.api.nvim_create_augroup("FileTreeNormalMode", { clear = true })

      local function leave_insert_in_tree()
        -- Defer until Neovim has completed the mouse/window-enter processing.
        vim.schedule(function()
          if vim.bo.filetype == "snacks_picker_list" and vim.api.nvim_get_mode().mode:sub(1, 1) == "i" then
            vim.cmd("stopinsert")
          end
        end)
      end

      vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
        group = group,
        callback = leave_insert_in_tree,
        desc = "Enter Snacks explorer in Normal mode",
      })
    end,
  },
}
