-- [[ Oil - File Management & Navigation ]]
return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local oil = require("oil")
    vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
    oil.setup({
      keymaps = { ["<C-s>"] = false },
      view_options = { show_hidden = true },
    })
  end,
}
