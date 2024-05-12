-- ==========================
-- == Leader & Globals
-- ==========================
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true

-- ==========================
-- == Nvim Options
-- ==========================
require('core.options')

-- ==========================
-- == Keymaps & Auto Commands
-- ==========================
require('core.keymaps')
require('core.autocmds')

-- ==========================
-- == Lazy Plugins
-- ==========================
require('core.lazy-bootstrap')
require('core.lazy-plugins')

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
