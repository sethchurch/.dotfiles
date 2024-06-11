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
    commit = "96368e13e9b1aaacc570e4825b8787307f0d05e1",
    config = function()
      local oil = require("oil")

      -- Keymaps
      vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })

      -- Opts
      oil.setup({
        view_options = {
          show_hidden = true,
        },
      })
    end,
  },
}
