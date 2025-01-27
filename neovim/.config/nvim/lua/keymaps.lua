-- [[ Commands ]]
local map = vim.keymap.set

-- Escape Highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Open Tmux Session
map("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer.sh<CR>", { desc = "Open new tmux session" })

-- Save File and Reset
map({ "n" }, "<leader>ww", "<cmd>w<cr><esc>", { desc = "Save File" })
map({ "n", "i" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })

-- Diagnostics
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })
map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, {})
map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, {})

-- Escape Terminal Mode
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Split Navigation
map("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
map("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
map("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
map("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

map("n", "<C-L>", "<cmd>vertical resize +20<cr>", { desc = "Increase Vertical Split Size" })
map("n", "<C-H>", "<cmd>vertical resize -20<cr>", { desc = "Decrease Vertical Split Size" })

-- Quickfix navigation
map("n", "]q", "<cmd>cnext<cr>", { desc = "Next Item" })
map("n", "[q", "<cmd>cprev<cr>", { desc = "Previous Item" })

-- Open Lazy
map("n", "<leader>ol", "<cmd>Lazy<cr>", { desc = "[O]pen Lazy" })
map("n", "<leader>om", "<cmd>Mason<cr>", { desc = "[O]pen Mason" })

-- Lint
map("n", "<leader>cl", function()
  -- @stylua ignore
  vim.cmd("set makeprg=npx\\ eslint\\ -f\\ unix\\ --quiet\\ 'app/**/*.{js,ts,jsx,tsx}'")
  vim.cmd("make")
end, { desc = "Get Eslint Errors" })

-- [[ Auto Commands ]]
local autocmd = vim.api.nvim_create_autocmd

-- Highlight on Yank
autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function() vim.highlight.on_yank() end,
})

-- Side Panel Help
autocmd("FileType", {
  pattern = "help",
  callback = function() vim.cmd("wincmd H") end,
})

-- Fix all Eslint Errors
autocmd("BufWritePre", {
  callback = function()
    pcall(function() vim.cmd("EslintFixAll") end)
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = {
    "help",
    "startuptime",
    "qf",
    "lspinfo",
    "man",
    "checkhealth",
    "neotest-output-panel",
    "neotest-summary",
    "lazy",
    "Avante",
    "AvanteSelectedFiles",
    "AvanteInput",
  },
  command = [[
          nnoremap <buffer><silent> q :close<CR>
          nnoremap <buffer><silent> <ESC> :close<CR>
          set nobuflisted
      ]],
})
