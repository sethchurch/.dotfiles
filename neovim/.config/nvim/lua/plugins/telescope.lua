return {
  {
    "piersolenski/telescope-import.nvim",
    iependencies = "nvim-telescope/telescope.nvim",
    config = function() require("telescope").load_extension("import") end,
    keys = {
      { "<leader>si", "<cmd>Telescope import<cr>", desc = "[I]mports" },
    },
  },
  {
    "nvim-telescope/telescope.nvim",
    event = "VimEnter",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function() return vim.fn.executable("make") == 1 end,
      },
      { "nvim-telescope/telescope-ui-select.nvim" },

      { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
    },
    config = function()
      require("telescope").setup({
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown(),
          },
        },
        pickers = {
          colorscheme = {
            enable_preview = true,
            layout_config = {
              height = 0.4,
              width = 0.2,
            },
          },
        },
        defaults = {
          layout_strategy = "vertical",
          layout_config = {
            prompt_position = "bottom",
          },
        },
      })

      -- Enable Telescope extensions if they are installed
      pcall(require("telescope").load_extension, "fzf")
      pcall(require("telescope").load_extension, "ui-select")

      -- See `:help telescope.builtin`
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader><leader>", builtin.find_files, { desc = "[F]iles" })
      vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[H]elp" })
      vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[K]eymaps" })
      vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "[F]iles" })
      vim.keymap.set("n", "<leader>ss", builtin.builtin, { desc = "[S]elect Telescope" })
      vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "[W]ord" })
      vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "[G]rep" })
      vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[D]iagnostics" })
      vim.keymap.set("n", "<leader>sR", builtin.resume, { desc = "[R]esume" })
      vim.keymap.set("n", "<leader>sr", builtin.oldfiles, { desc = '[R]ecent ("." for repeat)' })
      vim.keymap.set("n", "<leader>sc", builtin.colorscheme, { desc = "[C]olorscheme" })

      vim.keymap.set(
        "n",
        "<leader>/",
        function()
          builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
            winblend = 10,
            previewer = false,
          }))
        end,
        { desc = "[/] Fuzzily search in current buffer" }
      )

      vim.keymap.set(
        "n",
        "<leader>s/",
        function()
          builtin.live_grep({
            grep_open_files = true,
            prompt_title = "Live Grep in Open Files",
          })
        end,
        { desc = "[/] in Open Files" }
      )

      vim.keymap.set("n", "<leader>sn", function() builtin.find_files({ cwd = vim.fn.stdpath("config") }) end, { desc = "[N]eovim files" })
    end,
  },
}
