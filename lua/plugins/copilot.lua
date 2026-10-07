-- Keep profile-specific suggestion behavior. LazyVim's coding.copilot extra
-- owns plugin setup and completion integration (blink.cmp).
return {
  {
    "zbirenbaum/copilot.lua",
    opts = {
      suggestion = {
        enabled = true,
        auto_trigger = true,
        keymap = {
          accept = "<A-Right>",
          accept_word = false,
          accept_line = false,
          next = "<C-Down>",
          prev = "<C-Up>",
          dismiss = false,
        },
      },
      filetypes = {
        yaml = true,
        yml = true,
        markdown = true,
      },
    },
  },
}
