return {
  -- [[ TypeScript Integration ]]
  {
    "dmmulroy/tsc.nvim",
    config = function() require("tsc").setup() end,
    keys = {
      { "<leader>tt", "<cmd>TSC<cr>" },
    },
  },
  {
    "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    opts = { settings = {
      tsserver_file_preferences = {
        importModuleSpecifierPreference = "non-relative",
      },
    } },
  },
}
