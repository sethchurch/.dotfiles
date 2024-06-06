-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- open tmux sessionizer
map("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")

-- Save File
map({ "n" }, "<leader>ww", "<cmd>w<cr><esc>", { desc = "Save File" })

-- Command to toggle inline diagnostics
vim.api.nvim_create_user_command("DiagnosticsToggleVirtualText", function()
  local current_value = vim.diagnostic.config().virtual_text
  if current_value then
    vim.diagnostic.config({ virtual_text = false })
  else
    vim.diagnostic.config({ virtual_text = true })
  end
end, {})

map(
  "n",
  "<Leader>td",
  ':lua vim.cmd("DiagnosticsToggleVirtualText")<CR>',
  { desc = "Toggle Inline Diagnostics", noremap = true, silent = true }
)
