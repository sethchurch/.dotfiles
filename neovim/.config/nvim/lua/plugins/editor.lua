return {
  {
    "nvim-telescope/telescope.nvim",
    opts = {
      defaults = {
        sorting_strategy = "descending",
        path_display = function(_, path)
          local tail = require("telescope.utils").path_tail(path)
          return string.format("%s (%s)", tail, path)
        end,
      },
    },
  },
  {
    "tpope/vim-sleuth",
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        ["<leader>r"] = { name = "+run" },
      },
    },
  },
}
