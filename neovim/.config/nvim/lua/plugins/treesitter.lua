return {
  { -- Highlight, edit, and navigate code
    "nvim-treesitter/nvim-treesitter",
    branch = "master", -- Pin to stable branch (the `main` rewrite drops the highlight/indent modules and breaks telescope 0.1.x previews)
    build = ":TSUpdate",
    main = "nvim-treesitter.configs", -- Sets main module to use for opts
    -- nvim 0.12 compat: core dropped the per-capture single-node `match` format and
    -- now always passes `match[id]` as a node *list* (TSNode[]). The master branch's
    -- custom predicates/directives (set-lang-from-info-string!, downcase!, nth?, etc.)
    -- still assume a single node, so they hand a list to get_node_text and crash with
    -- "attempt to call method 'range' (a nil value)" (e.g. via render-markdown's
    -- injection parsing of fenced code blocks). master is frozen and won't be fixed,
    -- so wrap the registration helpers to normalize each capture's list to its first
    -- node before nvim-treesitter installs its handlers. Runs in `init` (before the
    -- plugin's config requires query_predicates) and only affects later registrations,
    -- leaving core handlers untouched.
    init = function()
      local q = require("vim.treesitter.query")
      for _, name in ipairs({ "add_directive", "add_predicate" }) do
        local orig = q[name]
        q[name] = function(pred_name, handler, opts)
          local wrapped = function(match, ...)
            local normalized = {}
            for id, nodes in pairs(match) do
              normalized[id] = type(nodes) == "table" and nodes[1] or nodes
            end
            return handler(normalized, ...)
          end
          return orig(pred_name, wrapped, opts)
        end
      end
    end,
    -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
    opts = {
      ensure_installed = { "bash", "c", "diff", "html", "lua", "luadoc", "markdown", "markdown_inline", "query", "vim", "vimdoc" },
      -- Autoinstall languages that are not installed
      auto_install = true,
      highlight = {
        enable = true,
        -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
        --  If you are experiencing weird indenting issues, add the language to
        --  the list of additional_vim_regex_highlighting and disabled languages for indent.
        additional_vim_regex_highlighting = { "ruby" },
      },
      indent = { enable = true, disable = { "ruby" } },
    },
    -- There are additional nvim-treesitter modules that you can use to interact
    -- with nvim-treesitter. You should go explore a few and see what interests you:
    --
    --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
    --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
    --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    event = "VeryLazy",
  },
  {
    "windwp/nvim-ts-autotag",
    opts = {},
  },
}
