return {
  {
    "piersolenski/wtf.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    opts = {
      popup_type = "vertical",
      openai_model_id = "gpt-4o",
    },
    keys = {
      {
        "gw",
        mode = { "n", "x" },
        function() require("wtf").ai() end,
        desc = "Debug diagnostic with AI",
      },
      {
        mode = { "n" },
        "gW",
        function() require("wtf").search() end,
        desc = "Search diagnostic with Google",
      },
    },
  },
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function() require("copilot").setup({}) end,
  },
  {
    "greggh/claude-code.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim", -- Required for git operations
    },
    config = function() require("claude-code").setup() end,
  },
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    lazy = false,
    version = "*", -- Set this to "*" to always pull the latest release version, or set it to false to update to the latest code changes.

    -- opts = {
    --   provider = "openai",
    --   auto_suggestions_provider = "copilot",
    --   providers = {
    --     copilot = {
    --       endpoint = "https://api.githubcopilot.com",
    --       model = "claude-3.5-sonnet",
    --       proxy = nil, -- [protocol://]host[:port] Use this proxy
    --       allow_insecure = false, -- Allow insecure server connections
    --       timeout = 30000, -- Timeout in milliseconds
    --       reasoning_effort = "high",
    --     },
    --   },
    --   file_selector = {
    --     provider = "telescope",
    --   },
    --   hints = {
    --     enabled = true,
    --   },
    --   mappings = {
    --     toggle = {
    --       hint = "<leader>ta",
    --     },
    --   },
    -- },

    opts = {
      -- add any opts here
      provider = "copilot",
      auto_suggestions_provider = "copilot",
      providers = {
        copilot = {
          endpoint = "https://api.githubcopilot.com",
          model = "claude-3.5-sonnet",
          proxy = nil, -- [protocol://]host[:port] Use this proxy
          allow_insecure = false, -- Allow insecure server connections
          timeout = 30000, -- Timeout in milliseconds
          reasoning_effort = "high",
        },
      },
      file_selector = {
        provider = "telescope",
      },
      hints = {
        enabled = true,
      },
      mappings = {
        toggle = {
          hint = "<leader>ta",
        },
      },
    },
    -- if you want to build from source then do `make build_from_source=true`
    build = "make",
    -- build = "powershell -executionpolicy bypass -file build.ps1 -buildfromsource false" -- for windows
    dependencies = {
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "muniftanjim/nui.nvim",
      "echasnovski/mini.pick", -- for file_selector provider mini.pick
      "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
      "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
      "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
      "zbirenbaum/copilot.lua", -- for providers='copilot'
      {
        -- support for image pasting
        "hakonharnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          -- recommended settings
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            -- required for windows users
            use_absolute_path = true,
          },
        },
      },
      {
        -- make sure to set this up properly if you have lazy=true
        "meanderingprogrammer/render-markdown.nvim",
        opts = {
          file_types = { "markdown", "avante" },
        },
        ft = { "markdown", "avante" },
      },
    },
    keys = {
      { "<leader>ax", "<cmd>avanteclear<cr>", desc = "avante: clear chat" },
    },
  },
  -- {
  --   "zbirenbaum/copilot.lua",
  --   build = ":Copilot auth",
  -- },
  -- {
  --   "olimorris/codecompanion.nvim",
  --   dependencies = {
  --     "nvim-lua/plenary.nvim",
  --     "nvim-treesitter/nvim-treesitter",
  --   },
  --   config = true,
  -- },
}
