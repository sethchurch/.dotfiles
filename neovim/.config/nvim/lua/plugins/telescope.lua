return {
  { -- Fuzzy Finder (files, lsp, etc)
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
          return vim.fn.executable('make') == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      require('telescope').setup({
        defaults = {
          sorting_strategy = 'descending',
          path_display = function(_, path)
            local tail = require('telescope.utils').path_tail(path)
            return string.format('%s (%s)', tail, path)
          end,
        },
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
        },
      })

      -- Enable Telescope extensions if they are installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      -- See `:help telescope.builtin`
      local builtin = require('telescope.builtin')
      local map = vim.keymap.set

      map('n', '<leader>sh', builtin.help_tags, { desc = 'Search Help' })
      map('n', '<leader>sk', builtin.keymaps, { desc = 'Search Keymaps' })
      map('n', '<leader>ss', builtin.builtin, { desc = 'Search Select Telescope' })
      map('n', '<leader>sw', builtin.grep_string, { desc = 'Search current Word' })
      map('n', '<leader>sg', builtin.live_grep, { desc = 'Search by Grep' })
      map('n', '<leader>sd', builtin.diagnostics, { desc = 'Search Diagnostics' })
      map('n', '<leader>sr', builtin.resume, { desc = 'Search Resume' })
      map('n', '<leader>s.', builtin.oldfiles, { desc = 'Search Recent Files ("." for repeat)' })
      map('n', '<leader>sb', builtin.buffers, { desc = 'Search existing buffers' })

      -- Slightly advanced example of overriding default behavior and theme
      map('n', '<leader>/', function()
        -- You can pass additional configuration to Telescope to change the theme, layout, etc.
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown({ winblend = 10, previewer = false }))
      end, { desc = '/ Fuzzily search in current buffer' })

      local searchHiddenFiles = function()
        builtin.find_files({ hidden = true, follow = true })
      end

      map('n', '<leader><leader>', searchHiddenFiles, { desc = 'Search Files' })
      map('n', '<leader>sf', searchHiddenFiles, { desc = 'Search Files' })

      map('n', '<leader>s/', function()
        builtin.live_grep({ grep_open_files = true, prompt_title = 'Live Grep in Open Files' })
      end, { desc = 'Search Open Files' })

      map('n', '<leader>sn', function()
        builtin.find_files({ cwd = vim.fn.stdpath('config') })
      end, { desc = 'Search Neovim files' })
    end,
    keys = {
      { '<leader>s"', '<cmd>Telescope registers<cr>', desc = 'Search Registers' },
      { '<leader>sa', '<cmd>Telescope autocommands<cr>', desc = 'Search Auto Commands' },
      { '<leader>sM', '<cmd>Telescope man_pages<cr>', desc = 'Search Man Pages' },
      { '<leader>sm', '<cmd>Telescope marks<cr>', desc = 'Jump to Mark' },
      { '<leader>so', '<cmd>Telescope vim_options<cr>', desc = 'Options' },
    },
  },
  {
    'piersolenski/telescope-import.nvim',
    dependencies = 'nvim-telescope/telescope.nvim',
    config = function()
      require('telescope').load_extension('import')
    end,
  },
}
