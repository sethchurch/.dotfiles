-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- Save File
map({ "n" }, "<leader>ww", "<cmd>w<cr><esc>", { desc = "Save File" })

-- Command to toggle inline diagnostics
vim.api.nvim_create_user_command("DiagnosticsToggleVirtualText", function()
  vim.diagnostic.config({ virtual_text = not vim.diagnostic.config().virtual_text })
end, { desc = "Toggle Inline Diagnostics" })
map("n", "<Leader>uD", ':lua vim.cmd("DiagnosticsToggleVirtualText")<CR>', { desc = "Toggle Inline Diagnostics", noremap = true, silent = true })

-- Navigate splits
map("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
map("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
map("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
map("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- Resize Splits
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

-- Disable arrow keys in normal mode
map("n", "<left>", '<cmd>echo "Use h to move!!"<CR>')
map("n", "<right>", '<cmd>echo "Use l to move!!"<CR>')
map("n", "<up>", '<cmd>echo "Use k to move!!"<CR>')
map("n", "<down>", '<cmd>echo "Use j to move!!"<CR>')

-- tmux integration

map("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer.sh<CR>", { desc = "Open new tmux session" })

map("n", "<leader>rc", function()
  local command = vim.fn.input("Command - tmux window")
  if command:len() > 0 then
    vim.cmd("!tmux new-window -d " .. command)
  end
end, { desc = "Run command" })

map("n", "<leader>rd", "<cmd>!tmux new-window -d pnpm dev<CR>", { desc = "Run dev server" })
