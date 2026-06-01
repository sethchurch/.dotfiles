local o = vim.opt

-- UI
o.number = true
-- o.relativenumber = true -- this kills the coworker
o.showmode = false
o.showtabline = 0
o.cursorline = true
o.signcolumn = "yes"
o.scrolloff = 10
o.list = true
o.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
o.inccommand = "split"

-- Mouse
o.mouse = ""

-- Editing
o.breakindent = true
o.undofile = true
o.autowriteall = true
o.swapfile = false

-- Search
o.ignorecase = true
o.smartcase = true

-- Splits
o.splitright = true
o.splitbelow = true

-- Timing
o.updatetime = 250
o.timeoutlen = 300

-- Clipboard (deferred to avoid startup delay)
vim.schedule(function() o.clipboard = "unnamedplus" end)

-- Auto-reload files changed on disk without prompting (e.g. when Claude Code edits them)
o.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  pattern = "*",
  callback = function()
    if vim.fn.mode() ~= "c" then pcall(vim.cmd, "checktime") end
  end,
})
