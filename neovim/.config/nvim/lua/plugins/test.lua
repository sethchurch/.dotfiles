return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "marilari88/neotest-vitest",
    },
    opts = {
      adapters = {
        ["neotest-vitest"] = {},
      },
    },
    keys = {
      {
        "<leader>tu",
        mode = { "n", "x" },
        "<cmd>!tmux new -d pnpm test:ui<CR>",
        desc = "Open Test UI",
      },
      {
        "<leader>tt",
        mode = { "n", "x" },
        "<cmd>TSC<CR>",
        desc = "Run Typescript Checks",
      },
    },
  },
}
