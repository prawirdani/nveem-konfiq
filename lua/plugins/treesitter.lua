-- Highlight, edit, and navigate code
return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  main = 'nvim-treesitter.configs', -- Sets main module to use for opts
  -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
  opts = {
    ensure_installed = { 'bash', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc', 'go', 'css', 'typescript', 'javascript', 'tsx', 'python', 'c', 'cpp', 'yaml', 'json', 'dockerfile', 'jsdoc' },
    -- Autoinstall languages that are not installed
    auto_install = true,
    highlight = {
      enable = true,
      -- Treesitter stalls on huge buffers; regex fallback is fine there.
      disable = function(_, buf)
        local name = vim.api.nvim_buf_get_name(buf)
        local stats = name ~= '' and vim.uv.fs_stat(name)
        if stats and stats.size > 1024 * 1024 then
          return true
        end
        return vim.api.nvim_buf_line_count(buf) > 20000
      end,
    },
  },
}
