-- LSP Plugins
return {
  { "folke/lazydev.nvim", ft = "lua", opts = { library = { { path = "luvit-meta/library", words = { "vim%.uv" } } } } },
  { "Bilal2453/luvit-meta", lazy = true },
  {
    -- Main LSP Configuration
    "neovim/nvim-lspconfig",
    dependencies = {
      { "williamboman/mason.nvim", config = true },
      "williamboman/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      { "j-hui/fidget.nvim", opts = {} },
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
        callback = function(event)
          local builtin = require("telescope.builtin")
          local map = function(keys, func, desc, mode)
            mode = mode or "n"
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
          end

          map("gd", builtin.lsp_definitions, "[G]oto [D]efinition")
          map("gr", builtin.lsp_references, "[G]oto [R]eferences")
          map("gI", builtin.lsp_implementations, "[G]oto [I]mplementation")
          map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

          map("<leader>D", builtin.lsp_type_definitions, "Type [D]efinition")
          map("<leader>ds", builtin.lsp_document_symbols, "[D]ocument [S]ymbols")
          map("<leader>ws", builtin.lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

          -- [[ Code Based Actions ]]
          map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction", { "n", "x" })
          map("<leader>cM", EnderVim.lsp.action["source.addMissingImports"], "Add [M]issing Imports", { "n", "x" })
          map("<leader>cu", EnderVim.lsp.action["source.removeUnusedImports"], "Removed [U]nused Imports", { "n", "x" })
          map("<leader>co", EnderVim.lsp.action["source.organizeImports"], "[O]rganize Imports", { "n", "x" })
          map("<leader>cA", EnderVim.lsp.action["source.fixAll"], "Fix All", { "n", "x" })
          map("<leader>cr", vim.lsp.buf.rename, "[R]ename")
          map("<leader>cR", "<cmd>LspRestart<cr>", "[R]estart LSP")

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
            local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
            vim.api.nvim_create_autocmd(
              { "CursorHold", "CursorHoldI" },
              { buffer = event.buf, group = highlight_augroup, callback = vim.lsp.buf.document_highlight }
            )
            vim.api.nvim_create_autocmd(
              { "CursorMoved", "CursorMovedI" },
              { buffer = event.buf, group = highlight_augroup, callback = vim.lsp.buf.clear_references }
            )
            vim.api.nvim_create_autocmd("LspDetach", {
              group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
              end,
            })
          end
        end,
      })

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

      local servers = {
        eslint = {
          settings = { format = false },
          flags = {
            allow_incremental_sync = false,
            debounce_text_changes = 1000,
            exit_timeout = 1500,
          },
        },
        lua_ls = {
          settings = {
            Lua = {
              completion = { callSnippet = "Replace" },
            },
          },
        },
        svelte = {
          settings = {
            svelte = {
              plugin = {
                css = {
                  completions = {
                    emmet = false,
                  },
                },
              },
            },
            emmet = {
              showExpandedAbbreviation = "never",
            },
          },
          capabilities = {
            workspace = {
              didChangeWatchedFiles = false,
            },
          },
        },
      }

      require("mason").setup()
      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, { "tailwindcss-language-server", "stylua" })
      require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

      require("mason-lspconfig").setup({
        ensure_installed = {},
        automatic_installation = {},
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
            require("lspconfig")[server_name].setup(server)
          end,
        },
      })
    end,
  },
}
