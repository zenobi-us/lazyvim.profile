-- Custom keymaps. Loaded by LazyVim on VeryLazy.
local map = vim.keymap.set

-- Save, close current buffer, quit all.
map({ "n", "i", "v" }, "<C-s>", "<cmd>w<cr>", { desc = "Save" })
map({ "n", "i", "v" }, "<C-w>", "<cmd>bd<cr>", { desc = "Close buffer" })
map({ "n", "i", "v" }, "<C-q>", "<cmd>qa<cr>", { desc = "Quit Neovim" })

-- System clipboard. In normal mode, Ctrl+C copies the current line.
map("n", "<C-c>", "+yy", { desc = "Copy line" })
map("v", "<C-c>", '"+y', { desc = "Copy selection" })
map("v", "<C-x>", '"+d', { desc = "Cut selection" })
map("n", "<C-v>", '"+p', { desc = "Paste after cursor" })
map("i", "<C-v>", "<C-r>+", { desc = "Paste" })
map("v", "<C-v>", '"+p', { desc = "Paste over selection" })

-- Word navigation; terminal support for modified arrow keys varies.
map({ "n", "i" }, "<C-Left>", "<C-Left>", { desc = "Move back one word" })
map({ "n", "i" }, "<C-Right>", "<C-Right>", { desc = "Move forward one word" })

-- Mouse actions require terminal mouse support and a terminal that sends these keys.
map("n", "<C-LeftMouse>", vim.lsp.buf.definition, { desc = "Go to definition" })
map("n", "<A-LeftMouse>", vim.lsp.buf.type_definition, { desc = "Go to type definition" })
