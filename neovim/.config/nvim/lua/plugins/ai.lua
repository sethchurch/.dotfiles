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
    -- Claude Code: MCP server for real-time context/diffs; claude itself runs in a tmux pane
    "coder/claudecode.nvim",
    lazy = false,
    dependencies = { "folke/snacks.nvim" },
    opts = {
      auto_start = true,
      terminal = { provider = "none" },
    },
    keys = {
      {
        "<leader>aa",
        function()
          if not vim.env.TMUX then
            vim.notify("Claude: not inside a tmux session ($TMUX not set)", vim.log.levels.WARN)
            return
          end
          -- If any other pane exists in this window, assume it's claude — hide it
          local current_pane = vim.fn.system("tmux display-message -p '#{pane_id}'"):gsub("%s+", "")
          local panes_output = vim.fn.system("tmux list-panes -F '#{pane_id}'")
          for pane_id in panes_output:gmatch("(%%%d+)") do
            if pane_id ~= current_pane then
              vim.fn.system("tmux break-pane -d -s " .. pane_id .. " -n __claude__")
              return
            end
          end
          -- No extra pane — check for hidden claude window to restore
          local windows = vim.fn.system("tmux list-windows -F '#{window_name}'")
          if windows:match("__claude__") then
            vim.fn.system("tmux join-pane -h -s __claude__")
            return
          end
          -- Open a fresh claude pane
          local ok, cc = pcall(require, "claudecode")
          local port = ok and cc.state and cc.state.port
          local result = vim.fn.system(
            "tmux split-window -h"
              .. " -e ENABLE_IDE_INTEGRATION=true"
              .. " -e FORCE_CODE_TERMINAL=true"
              .. (port and (" -e CLAUDE_CODE_SSE_PORT=" .. port) or "")
              .. " claude"
          )
          if vim.v.shell_error ~= 0 then vim.notify("Claude: tmux error: " .. result, vim.log.levels.ERROR) end
        end,
        desc = "Toggle Claude tmux pane",
      },
      {
        "<leader>ax",
        function()
          local panes = vim.fn.system("tmux list-panes -s -F '#{pane_id} #{pane_current_command}'")
          local claude_pane = panes:match("(%%%d+)%s+claude")
          if claude_pane then vim.fn.system("tmux kill-pane -t " .. claude_pane) end
          local windows = vim.fn.system("tmux list-windows -F '#{window_name}'")
          if windows:match("__claude__") then vim.fn.system("tmux kill-window -t __claude__") end
        end,
        desc = "Claude Code: Kill tmux pane",
      },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Claude Code: Send selection" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Claude Code: Accept diff" },
      { "<leader>aD", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Claude Code: Reject diff" },
    },
  },
  {
    -- Avante: inline editing only (<leader>ae on a visual selection)
    "yetone/avante.nvim",
    event = "VeryLazy",
    lazy = false,
    version = "*",

    opts = {
      provider = "openai",
      auto_suggestions_provider = "openai",
      providers = {
        copilot = {
          endpoint = "https://api.openai.com/v1",
          api_key = "OPENAI_API_KEY",
          model = "gpt-5.4-mini",
          proxy = nil,
          allow_insecure = false,
          timeout = 30000,
        },
      },
      file_selector = {
        provider = "telescope",
      },
      hints = {
        enabled = true,
      },
      -- Disable avante's chat panel bindings — use claude-code for chat.
      -- Only keep <leader>ae for inline edit.
      mappings = {
        ask = "<leader>aA", -- hidden away; use Claude Code instead
        edit = "<leader>ae",
        refresh = "<leader>aR",
        focus = "<leader>aF",
        toggle = {
          default = "<leader>aT",
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
    keys = {},
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
