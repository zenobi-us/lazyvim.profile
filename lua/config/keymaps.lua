-- Custom keymaps. Loaded by LazyVim on VeryLazy.
local map = vim.keymap.set

-- Comment current line or selected lines.
map("n", "<leader>/", "gcc", { remap = true, desc = "Comment line" })
map("v", "<leader>/", "gc", { remap = true, desc = "Comment selection" })

-- Save, close current buffer, quit all.
map({ "n", "i", "v" }, "<C-s>", "<cmd>w<cr>", { desc = "Save" })
map({ "n", "i", "v" }, "<C-w>", "<cmd>bd<cr>", { desc = "Close buffer" })
map({ "n", "i", "v" }, "<C-q>", "<cmd>qa<cr>", { desc = "Quit Neovim" })

-- System clipboard. Copy or cut the current line when no text is selected.
map("n", "<C-c>", '"+yy', { desc = "Copy line" })
map("v", "<C-c>", '"+y', { desc = "Copy selection" })
map("n", "<C-x>", '"+dd', { desc = "Cut line" })
map("v", "<C-x>", '"+d', { desc = "Cut selection" })
map("n", "<C-v>", '"+p', { desc = "Paste after cursor" })
map("i", "<C-v>", "<C-r>+", { desc = "Paste" })
map("v", "<C-v>", '"+p', { desc = "Paste over selection" })

-- Extend a linewise selection with Shift+Up/Down.
map("n", "<S-Up>", "V<Up>", { desc = "Select lines up" })
map("n", "<S-Down>", "V<Down>", { desc = "Select lines down" })
map("x", "<S-Up>", "<Up>", { desc = "Extend selection up" })
map("x", "<S-Down>", "<Down>", { desc = "Extend selection down" })

-- Move the current line or selected lines with Ctrl+Shift+Up/Down.
map("n", "<C-S-Up>", ":move .-2<cr>==", { desc = "Move line up" })
map("n", "<C-S-Down>", ":move .+1<cr>==", { desc = "Move line down" })
map("v", "<C-S-Up>", ":move '<-2<cr>gv=gv", { desc = "Move selection up" })
map("v", "<C-S-Down>", ":move '>+1<cr>gv=gv", { desc = "Move selection down" })

-- Word navigation; terminal support for modified arrow keys varies.
map({ "n", "i" }, "<C-Left>", "<C-Left>", { desc = "Move back one word" })
map({ "n", "i" }, "<C-Right>", "<C-Right>", { desc = "Move forward one word" })

-- Mouse actions require terminal mouse support and a terminal that sends these keys.
map("n", "<C-LeftMouse>", vim.lsp.buf.definition, { desc = "Go to definition" })
map("n", "<A-LeftMouse>", vim.lsp.buf.type_definition, { desc = "Go to type definition" })
