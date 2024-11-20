return {
  { "pmizio/typescript-tools.nvim", dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" }, opts = {} },
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- make sure mason installs the server
      inlay_hints = { enabled = false },
      servers = {
        tsserver = {
          enabled = false,
        },
        vtsls = {
          enabled = false,
          filetypes = {
            "javascript",
            "javascriptreact",
            "javascript.jsx",
            "typescript",
            "typescriptreact",
            "typescript.tsx",
          },
          autoUseWorkspaceTsdk = true,
          settings = {
            complete_function_calls = true,
            vtsls = {
              enableMoveToFileCodeAction = true,
              autoUseWorkspaceTsdk = true,
              maxTsServerMemory = 8192,
              experimental = {
                completion = {
                  enableServerSideFuzzyMatch = true,
                },
              },
            },
            typescript = {
              maxTsServerMemory = 8192,
              updateImportsOnFileMove = { enabled = "always" },
              preferences = {
                importModuleSpecifier = "non-relative",
              },
              suggest = {
                completeFunctionCalls = true,
              },
              inlayHints = {
                enumMemberValues = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                parameterNames = { enabled = "literals" },
                parameterTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                variableTypes = { enabled = false },
              },
            },
          },
        },
      },
    },
  },
}
