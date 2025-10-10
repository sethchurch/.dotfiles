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
map("n", "<leader>qq", "<cmd>qa!<cr>", { desc = "Force Quit" })

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
autocmd("BufWritePost", {
  callback = function()
    pcall(function() vim.cmd("LspEslintFixAll") end)
  end,
})

-- Tanstack start routing fixes
autocmd({ "BufWritePost" }, {
  pattern = { "**/routeTree.gen.ts" },
  callback = function() EnderVim.lsp.action["typescript.reloadProjects"]() end,
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

-- Advanced Flash.nvim usage patterns

map(
  "n",
  "<leader>fl",
  function()
    require("flash").jump({
      search = { mode = "search", max_length = 0 },
      label = { after = { 0, 0 } },
      pattern = "^",
    })
  end,
  { desc = "Flash: Jump to line start" }
)

map("n", "<leader>fw", function()
  require("flash").jump({
    search = {
      mode = function(str) return "\\<" .. str end,
    },
  })
end, { desc = "Flash: Jump to word boundaries" })

map("n", "<leader>fd", function()
  require("flash").jump({
    matcher = function(win)
      return vim.tbl_map(
        function(diag)
          return {
            pos = { diag.lnum + 1, diag.col },
            end_pos = { diag.end_lnum + 1, diag.end_col - 1 },
          }
        end,
        vim.diagnostic.get(vim.api.nvim_win_get_buf(win))
      )
    end,
    action = function(match, state)
      vim.api.nvim_win_call(match.win, function()
        vim.api.nvim_win_set_cursor(match.win, match.pos)
        vim.diagnostic.open_float()
      end)
      state:restore()
    end,
  })
end, { desc = "Flash: Jump to diagnostics" })

map("n", "<leader>fW", function()
  require("flash").jump({
    search = { multi_window = true },
    labels = "ASDFGHJKL", -- Capital letters for multi-window
  })
end, { desc = "Flash: Multi-window jump" })

map("n", "<leader>*", function()
  local word = vim.fn.expand("<cword>")
  require("flash").jump({
    pattern = "\\<" .. word .. "\\>",
    search = { multi_window = false },
  })
end, { desc = "Flash: Jump to word under cursor" })

map("n", "<leader>fz", function()
  require("flash").jump({
    search = { mode = "fuzzy" },
  })
end, { desc = "Flash: Fuzzy search jump" })

local flash_bookmarks = {}
map("n", "<leader>fm", function()
  require("flash").jump({
    action = function(match, state)
      local pos = { match.win, match.pos[1], match.pos[2] }
      table.insert(flash_bookmarks, pos)
      print("Bookmarked position " .. #flash_bookmarks)
      state:restore()
    end,
  })
end, { desc = "Flash: Bookmark position" })

map("n", "<leader>fb", function()
  if #flash_bookmarks == 0 then
    print("No bookmarks")
    return
  end

  require("flash").jump({
    matcher = function(win)
      local matches = {}
      for i, bookmark in ipairs(flash_bookmarks) do
        if bookmark[1] == win then
          table.insert(matches, {
            pos = { bookmark[2], bookmark[3] },
            end_pos = { bookmark[2], bookmark[3] + 1 },
          })
        end
      end
      return matches
    end,
    labeler = function(matches, state)
      local labels = {}
      for i, match in ipairs(matches) do
        labels[i] = tostring(i)
      end
      return labels
    end,
  })
end, { desc = "Flash: Jump to bookmarks" })

map(
  "x",
  "<leader>fs",
  function()
    require("flash").jump({
      search = { mode = "search" },
      jump = { pos = "range" },
    })
  end,
  { desc = "Flash: Visual selection jump" }
)

map(
  "n",
  "<leader>fi",
  function()
    require("flash").jump({
      search = { incremental = true },
      label = { after = false, before = true },
    })
  end,
  { desc = "Flash: Incremental search" }
)

map("n", "<leader>fc", function()
  local filetype = vim.bo.filetype
  local config = {
    search = { mode = "exact" },
  }

  if vim.tbl_contains({ "lua", "python", "javascript", "typescript", "rust", "go" }, filetype) then
    require("flash").treesitter()
    return
  end

  if vim.tbl_contains({ "markdown", "text", "org" }, filetype) then config.search.mode = "fuzzy" end

  require("flash").jump(config)
end, { desc = "Flash: Context-aware jump" })
