return {
  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    opts = {},

    config = function()
      local char = '│'
      require('ibl').setup {
        indent = { char = char },
        scope = { enabled = false },
      }
    end,
  },
}
