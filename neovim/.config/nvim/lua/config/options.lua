-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

--  Disable tabline
vim.opt.showtabline = 0

-- Disable mouse support
vim.opt.mouse = ""

-- Remove whitespace characters
vim.opt.list = false

-- Autowrite
vim.opt.autowriteall = true

-- WSL clipboard integration
if vim.fn.has("wsl") == 1 then
  vim.g.clipboard = {
    name = "xclip-wsl",
    copy = {
      ["+"] = "xclip -selection clipboard",
      ["*"] = "xclip -selection clipboard",
    },
    paste = {
      ["+"] = "xclip -selection clipboard -o",
      ["*"] = "xclip -selection clipboard -o",
    },
    cache_enabled = 0,
  }
end

-- Dotenv
vim.filetype.add({
  extension = {
    conf = "conf",
    env = "dotenv",
    tiltfile = "tiltfile",
    Tiltfile = "tiltfile",
  },
  filename = {
    [".env"] = "dotenv",
    ["tsconfig.json"] = "jsonc",
    [".yamlfmt"] = "yaml",
  },
  pattern = {
    ["%.env%.[%w_.-]+"] = "dotenv",
  },
})
