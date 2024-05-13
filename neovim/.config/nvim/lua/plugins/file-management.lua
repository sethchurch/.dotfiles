-- Various plugins focused on managing and navigating files

return {
  {
    'otavioschwanck/arrow.nvim',
    opts = {
      show_icons = true,
      leader_key = '<C-e>',
      buffer_leader_key = 'm',
    },
  },
  {
    'simonmclean/triptych.nvim',
    event = 'VeryLazy',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
    },
    keys = {
      { '\\', ':Triptych<CR>', { desc = 'Open Triptych' } },
    },
    config = function()
      require('triptych').setup()
    end,
  },
  {
    'stevearc/oil.nvim',
    opts = {},
    -- Optional dependencies
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('oil').setup()
      vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })
    end,
  },
}
