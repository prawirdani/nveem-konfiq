return {
  'rebelot/kanagawa.nvim',
  priority = 1000,
  name = 'kanagawa',
  config = function()
    require('kanagawa').setup {
      transparent = true,
      terminalColors = true,
      keywordStyle = { italic = true, bold = false },
      commentStyle = { italic = true, bold = false },
      statementStyle = { italic = true, bold = false },
      functionStyle = { italic = false, bold = true },
      colors = {
        theme = {
          all = {
            ui = {
              bg_gutter = 'none',
            },
          },
        },
      },
      overrides = function(colors)
        local theme = colors.theme
        return {
          -- Apply your custom background to all floating windows
          -- NormalFloat = { bg = 'none' },
          -- FloatBorder = { bg = 'none' },
          -- FloatTitle = { bg = 'none' },
          --
          -- NormalFloat = { bg = '#49443C' },
          -- FloatBorder = { fg = '#c5c9c5', bg = '#393836' },
          -- FloatTitle = { bg = '#393836', fg = '#c5c9c5' },

          -- Specific plugin overrides
          -- LazyNormal = { bg = '#393836', fg = '#c5c9c5' },
          -- MasonNormal = { bg = '#393836', fg = '#c5c9c5' },

          -- Cursor line in floating windows
          CursorLine = { bg = '#282727' },
        }
      end,
    }

    -- Apply the colorscheme first
    vim.cmd.colorscheme 'kanagawa-wave'

    -- =========================
    -- Colors Palette
    -- =========================
    local colors = {
      bg = '#393836',
      bg_alt = '#282727',
      fg = '#c5c9c5',
      fg_dim = '#727169',
      red = '#c4746e',
      blue = '#8ba4b0',
      autumnGreen = '#76946A', -- Git Add
      autumnRed = '#C34043', -- Git Deleted
      autumnYellow = '#DCA561', -- Git Changed
      samuraiRed = '#E82424', -- Diagnostic Error
      roninYellow = '#FF9E3B', -- Diagnostic Warning, Modified
      waveAqua = '#6A9589', -- Diagnostic Info
      dragonBlue = '#658594', -- Diagnostic Hint
      oldWhite = '#C8C093', -- Text
      fujiWhite = '#DCD7BA',
      winterYellow = '#49443C',
    }

    -- =========================
    -- Barbar Highlight Overrides
    -- =========================
    vim.api.nvim_set_hl(0, 'BufferCurrent', { fg = colors.oldWhite, bg = colors.bg })
    vim.api.nvim_set_hl(0, 'BufferCurrentIndex', { fg = colors.oldWhite, bg = colors.bg })
    vim.api.nvim_set_hl(0, 'BufferCurrentMod', { fg = colors.roninYellow, bg = colors.bg })
    vim.api.nvim_set_hl(0, 'BufferCurrentSign', { fg = colors.blue, bg = colors.bg })
    vim.api.nvim_set_hl(0, 'BufferCurrentTarget', { fg = colors.red, bg = colors.bg })

    -- Inactive (dimmed background)
    vim.api.nvim_set_hl(0, 'BufferInactive', { fg = colors.fg_dim, bg = colors.bg_alt })
    vim.api.nvim_set_hl(0, 'BufferInactiveIndex', { fg = colors.fg_dim, bg = colors.bg_alt })
    vim.api.nvim_set_hl(0, 'BufferInactiveMod', { fg = colors.roninYellow, bg = colors.bg_alt })
    vim.api.nvim_set_hl(0, 'BufferInactiveSign', { fg = colors.fg_dim, bg = colors.bg_alt })
    vim.api.nvim_set_hl(0, 'BufferInactiveHINT', { fg = colors.dragonBlue, bg = colors.bg_alt })
    vim.api.nvim_set_hl(0, 'BufferInactiveERROR', { fg = colors.samuraiRed, bg = colors.bg_alt })
    vim.api.nvim_set_hl(0, 'BufferInactiveWARN', { fg = colors.roninYellow, bg = colors.bg_alt })
    vim.api.nvim_set_hl(0, 'BufferInactiveINFO', { fg = colors.waveAqua, bg = colors.bg_alt })
    vim.api.nvim_set_hl(0, 'BufferInactiveADDED', { fg = colors.autumnGreen, bg = colors.bg_alt })
    vim.api.nvim_set_hl(0, 'BufferInactiveCHANGED', { fg = colors.autumnYellow, bg = colors.bg_alt })
    vim.api.nvim_set_hl(0, 'BufferInactiveDELETED', { fg = colors.autumnRed, bg = colors.bg_alt })

    -- Tabline
    vim.api.nvim_set_hl(0, 'TabLineSel', { fg = colors.fg, bg = colors.bg })
    vim.api.nvim_set_hl(0, 'TabLine', { fg = colors.fg, bg = colors.bg })
    vim.api.nvim_set_hl(0, 'TabLineFill', { bg = colors.bg_alt })

    -- Statusline
    vim.api.nvim_set_hl(0, 'StatusLine', { fg = colors.oldWhite, bg = colors.bg_alt })
    vim.api.nvim_set_hl(0, 'StatusLineNC', { fg = colors.fg_dim, bg = colors.bg })

    -- Which-key
    vim.api.nvim_set_hl(0, 'WhichKeyNormal', { bg = colors.bg })
    vim.api.nvim_set_hl(0, 'WhichKeyBorder', { fg = colors.oldWhite })

    -- Telescope
    vim.api.nvim_set_hl(0, 'TelescopePromptBorder', { fg = colors.oldWhite })
    vim.api.nvim_set_hl(0, 'TelescopeResultsBorder', { fg = colors.oldWhite })
    vim.api.nvim_set_hl(0, 'TelescopePreviewBorder', { fg = colors.oldWhite })

    -- Completion Menu
    -- vim.api.nvim_set_hl(0, 'Pmenu', { bg = colors.oldWhite, fg = colors.bg })
    -- vim.api.nvim_set_hl(0, 'PmenuSbar', { bg = colors.fujiWhite })
    -- vim.api.nvim_set_hl(0, 'PmenuSel', { bg = colors.bg })
    -- Pmenu = { bg = '#393836', fg = '#c5c9c5' },
    -- PmenuSel = { bg = '#282727', fg = '#c5c9c5', bold = true },
    -- PmenuThumb = { bg = '#727169' },
  end,
}
