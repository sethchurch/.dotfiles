return {
  { -- autoformat
    "stevearc/conform.nvim",
    opts = {
      stop_after_first = true,
      formatters_by_ft = {
        lua = { "stylua" },
        javascript = { "prettierd", "prettier" },
        javascriptreact = { "prettierd", "prettier" },
        typescript = { "prettierd", "prettier" },
        typescriptreact = { "prettierd", "prettier" },
        jsonc = { "prettierd", "prettier" },
        json = { "prettierd", "prettier" },
        prisma = { "prisma-language-server" },
      },
    },
  },
}
