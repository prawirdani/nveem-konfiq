return {
  "olrtg/nvim-emmet",
  keys = { { '<leader>qe', mode = { "n", "v" }, desc = "Emmet" } },
  config = function()
    vim.keymap.set({ "n", "v" }, '<leader>qe', require('nvim-emmet').wrap_with_abbreviation, { desc = "Emmet" })
  end,
}
