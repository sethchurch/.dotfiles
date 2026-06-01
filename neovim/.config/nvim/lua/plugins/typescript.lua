return {
  -- [[ TypeScript Integration ]]
  {
    "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    opts = {
      settings = {
        tsserver_file_preferences = {
          importModuleSpecifierPreference = "non-relative",
        },
      },
    },
  },
  {
    "OlegGulevskyy/better-ts-errors.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {
      keymaps = {
        toggle = "<leader>dd", -- default '<leader>dd'
        go_to_definition = "<leader>dx", -- default '<leader>dx'
      },
    },
  },
}
