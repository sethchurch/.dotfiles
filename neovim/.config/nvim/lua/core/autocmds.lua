-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

local autocmd = vim.api.nvim_create_autocmd

local runSaveActions = function()
  pcall(vim.cmd, 'TSToolsAddMissingImports sync')
  pcall(require('conform').format, { async = false, lsp_fallback = true })
end

autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

autocmd('FileType', {
  pattern = 'help',
  callback = function()
    vim.cmd('wincmd H')
  end,
})

-- Before Save Events
autocmd({ 'BufWritePre' }, {
  callback = function()
    runSaveActions()
  end,
})

-- Save and Format on enter and exit
autocmd({ 'BufEnter', 'FocusLost' }, {
  callback = function()
    runSaveActions()
    vim.cmd('silent update')
  end,
})
