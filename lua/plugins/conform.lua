return {
  -- Autoformat
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<leader>cf',
      function()
        require('conform').format { async = true, lsp_format = 'fallback' }
      end,
      mode = '',
      desc = '[C]ode [F]ormat',
    },
  },
  opts = {
    notify_on_error = true,
    format_on_save = function(bufnr)
      -- Disable "format_on_save lsp_fallback" for languages that don't
      -- have a well standardized coding style. You can add additional
      -- languages here or re-enable it for the disabled ones.
      local disable_filetypes = { c = true, cpp = true }
      local lsp_format_opt
      if disable_filetypes[vim.bo[bufnr].filetype] then
        lsp_format_opt = 'never'
      else
        lsp_format_opt = 'fallback'
      end
      return {
        timeout_ms = 1000,
        async = true,
        lsp_format = lsp_format_opt,
      }
    end,
    formatters_by_ft = {
      lua = { 'stylua' },
      go = { 'gofumpt', 'golines' },
      c = { 'clang_format' },
      cpp = { 'clang_format' },
      ['javascript'] = { 'biome-check' },
      ['javascriptreact'] = { 'biome-check' },
      ['typescript'] = { 'biome-check' },
      ['typescriptreact'] = { 'biome-check' },
      ['json'] = { 'biome-check' },
      ['css'] = { 'prettier' },
      ['html'] = { 'prettier' },
      yaml = { 'prettier' },
      yml = { 'prettier' },
      sql = { 'sql_formatter' },
      nginx = { 'nginxfmt' },
    },
    formatters = {
      golines = {
        command = 'golines',
        args = {
          '-m',
          '120',
          '--shorten-comments',
        },
      },
    },
  },
}
