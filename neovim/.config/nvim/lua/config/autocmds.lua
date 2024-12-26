-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

local autocmd = vim.api.nvim_create_autocmd

autocmd("FileType", {
  pattern = "help",
  callback = function()
    vim.cmd("wincmd H")
  end,
})

-- vim.api.nvim_create_autocmd("BufWritePre", {
--   pattern = { "*.js", "*.jsx", "*.ts", "*.tsx" },
--   callback = function()
--     vim.lsp.buf.code_action({ context = { only = { "source.addMissingImports.ts" }, diagnostics = {} }, apply = true })
--     vim.lsp.buf.code_action({ context = { only = { "source.removeUnused.ts" }, diagnostics = {} }, apply = true })
--   end,
-- })
