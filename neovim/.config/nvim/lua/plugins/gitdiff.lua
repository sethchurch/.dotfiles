return {
  'sindrets/diffview.nvim',
  config = function()
    require('diffview').setup()
    vim.keymap.set('n', '<leader>ndd', '<cmd>:DiffviewFileHistory %<CR>', { desc = 'Open [D]iff View' })
    vim.keymap.set('n', '<leader>ndc', '<cmd>:DiffviewClose<CR>', { desc = 'Close [D]iff View' })
  end,
}
