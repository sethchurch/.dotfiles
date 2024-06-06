return {
  {
    "sindrets/diffview.nvim",
    config = function()
      require("diffview").setup()

      vim.keymap.set("n", "<leader>gD", "<cmd>:DiffviewFileHistory %<CR>", { desc = "Open [D]iff View" })
      vim.keymap.set("n", "<leader>gC", "<cmd>:DiffviewClose<CR>", { desc = "[C]lose Diff View" })
    end,
  },
}
