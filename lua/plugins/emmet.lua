return {
  "olrtg/nvim-emmet",
  config = function()
    vim.keymap.set({ "n", "v" }, '<leader>qe', require('nvim-emmet').wrap_with_abbreviation, { desc = "Emmet" })
  end,
}
