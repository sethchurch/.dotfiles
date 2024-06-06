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
