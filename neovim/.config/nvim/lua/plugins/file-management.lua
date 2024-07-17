return {
  {
    "otavioschwanck/arrow.nvim",
    opts = {
      show_icons = true,
      leader_key = "<C-e>",
      buffer_leader_key = "m",
    },
  },
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local oil = require("oil")

      -- Keymaps
      vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })

      -- Opts
      oil.setup({
        keymaps = {
          ["<C-s>"] = false,
        },
        view_options = {
          show_hidden = true,
        },
      })
    end,
  },
}
