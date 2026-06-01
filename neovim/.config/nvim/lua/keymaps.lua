local map = vim.keymap.set

-- Editor
map("n", "<Esc>", "<cmd>nohlsearch<CR>")
map({ "n" }, "<leader>ww", "<cmd>w<cr><esc>", { desc = "Save File" })
map({ "n", "i" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })
map("n", "<leader>qq", "<cmd>qa!<cr>", { desc = "Force Quit" })

map("n", "<C-L>", "<cmd>vertical resize +20<cr>", { desc = "Increase Vertical Split Size" })
map("n", "<C-H>", "<cmd>vertical resize -20<cr>", { desc = "Decrease Vertical Split Size" })

-- Quickfix navigation
map("n", "]q", "<cmd>cnext<cr>", { desc = "Next Item" })
map("n", "[q", "<cmd>cprev<cr>", { desc = "Previous Item" })

-- Diagnostics
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })
map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, {})
map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, {})

-- Terminal
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Open tools
map("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer.sh<CR>", { desc = "Open new tmux session" })
map("n", "<leader>ol", "<cmd>Lazy<cr>", { desc = "[O]pen Lazy" })
map("n", "<leader>oq", "<cmd>copen<cr>", { desc = "[O]pen Quickfix List" })
map("n", "<leader>om", "<cmd>Mason<cr>", { desc = "[O]pen Mason" })

-- [[ Auto Commands ]]
local autocmd = vim.api.nvim_create_autocmd

-- Highlight on yank
autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function() vim.highlight.on_yank() end,
})

-- Open help in a vertical split
autocmd("FileType", {
  pattern = "help",
  callback = function() vim.cmd("wincmd H") end,
})

-- Fix all ESLint errors on save
autocmd("BufWritePost", {
  callback = function()
    pcall(function() vim.cmd("LspEslintFixAll") end)
  end,
})

-- Reload TS projects when TanStack route tree is regenerated
autocmd({ "BufWritePost" }, {
  pattern = { "**/routeTree.gen.ts" },
  callback = function() EnderVim.lsp.action["typescript.reloadProjects"]() end,
})

-- Close popup windows with q or <Esc>
autocmd("FileType", {
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
