-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

local autocmd = vim.api.nvim_create_autocmd

-- Save and Format on enter and exit
autocmd({ "BufEnter", "FocusLost" }, {
  callback = function()
    pcall(function()
      vim.cmd("silent update")
    end)
  end,
})

autocmd("FileType", {
  pattern = "help",
  callback = function()
    vim.cmd("wincmd H")
  end,
})
