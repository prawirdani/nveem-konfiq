return {
  -- Main LSP Configuration (Modern approach for Neovim 0.11+ with mason v2)
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'williamboman/mason.nvim', config = true },
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
    },
    config = function()
      -- Setup capabilities
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities.textDocument.completion.completionItem.snippetSupport = true
      -- blink.cmp does not inject its own capabilities; merge them so LSP
      -- completions get resolve/snippet-edit support.
      local ok, blink = pcall(require, 'blink.cmp')
      if ok then
        capabilities = blink.get_lsp_capabilities(capabilities, true)
      end

      -- Configure LSP servers using vim.lsp.config (Neovim 0.11+ native API)
      -- This is the modern way to configure LSP servers

      -- Apply capabilities to all servers
      vim.lsp.config('*', {
        capabilities = capabilities,
      })

      local servers = {
        -- TypeScript 7 native language server (`tsc --lsp --stdio`).
        -- Requires the `tsc` mason package (npm typescript >= 7); nvim-lspconfig
        -- supplies cmd/root_dir/filetypes defaults.
        -- NOTE: reads settings from the `js/ts` section only. `vtsls.*` and
        -- `typescript.tsserver.*` options are v6-only and ignored here.
        -- No tsserver plugins (Volar/Svelte/Astro) support TS7 yet.
        tsc = {
          settings = {
            ['js/ts'] = {
              preferences = {
                includeCompletionsForModuleExports = true,
                includeCompletionsForImportStatements = true,
                importModuleSpecifier = 'non-relative',
              },
              -- Auto-update imports when moving files
              updateImportsOnFileMove = { enabled = 'always' },
              suggest = {
                completeFunctionCalls = true,
              },
              inlayHints = {
                parameterNames = { enabled = 'all' },
                parameterTypes = { enabled = true },
                variableTypes = { enabled = false },
                propertyDeclarationTypes = { enabled = false },
                functionLikeReturnTypes = { enabled = false },
                enumMemberValues = { enabled = false },
              },
            },
          },
        },
        -- Manual start only, see `automatic_enable` below: `:LspStart vtsls`.
        -- Use for projects with tsserver plugins (Volar/Svelte/Astro): TS7 `tsc`
        -- has no plugin support. Do not run together with `tsc` on the same buffer.
        vtsls = {
          settings = {
            vtsls = {
              enableMoveToFileCodeAction = true,
              autoUseWorkspaceTsdk = true,
              experimental = {
                completion = {
                  -- PERFORMANCE: Fuzzy Match
                  enableServerSideFuzzyMatch = true,
                  -- PERFORMANCE: Limit completion entries
                  entriesLimit = 15,
                },
                -- PERFORMANCE: Limit inlay hint length to prevent lag
                maxInlayHintLength = 20,
              },
            },
            typescript = {
              tsserver = {
                -- PERFORMANCE: Increase memory limit for large monorepos (default: 3072)
                maxTsServerMemory = 10240,
              },
            },
          },
        },
        tailwindcss = {
          -- Manual start only, see `automatic_enable` below: `:LspStart tailwindcss`
          settings = {
            tailwindCSS = {
              experimental = {
                classRegex = {
                  'class:?\\s*["\']([^"\']*)["\']',
                  'className:?\\s*["\']([^"\']*)["\']',
                },
              },
              -- Only validate and suggest for current file
              validate = true,
              -- Disable some features for performance
              lint = {
                cssConflict = 'warning',
                invalidApply = 'error',
              },
            },
          },
        },

        gopls = {
          root_markers = {
            'go.work',
            'go.mod',
          },
          settings = {
            gopls = {
              gofumpt = true,
              codelenses = {
                gc_details = false,
                generate = true,
                regenerate_cgo = true,
                run_govulncheck = true,
                test = true,
                tidy = true,
                upgrade_dependency = true,
                vendor = true,
              },
              hints = {
                compositeLiteralFields = true,
                compositeLiteralTypes = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
              },
              analyses = {
                nilness = true,
                unusedparams = true,
                unusedwrite = true,
                useany = true,
              },
              -- usePlaceholders = true,
              completeUnimported = true,
              staticcheck = true,
              directoryFilters = {
                '-.git',
                '-.vscode',
                '-.idea',
                '-.vscode-test',
                '-node_modules',
              },
              semanticTokens = true,
            },
          },
        },

        lua_ls = {
          settings = {
            Lua = {
              completion = { callSnippet = 'Replace' },
              diagnostics = { globals = { 'vim' } },
            },
          },
        },

        -- postgres_lsp = {},
        pyright = {},
        ruff = {},
        biome = {},
        dockerls = {},
        docker_language_server = {},
        docker_compose_language_service = {},
        emmet_language_server = {},
        bashls = {},
        clangd = {},
      }

      for name, config in pairs(servers) do
        vim.lsp.config(name, config)
      end

      -- Setup Mason
      require('mason').setup()

      -- Derive ensure_installed list automatically from the keys
      local lsp_servers = vim.tbl_keys(servers)

      local formatters = {
        'stylua',
        'gofumpt',
        'golines',
        'clang-format',
        'biome',
        'prettier',
        'sql-formatter',
        'nginx-config-formatter',
      }

      -- Install both LSP servers and formatters via mason-tool-installer
      require('mason-tool-installer').setup {
        ensure_installed = vim.list_extend(vim.list_extend({}, lsp_servers), formatters),
        auto_update = false,
        run_on_start = true,
      }

      -- Setup mason-lspconfig v2 (only LSP servers, no formatters!)
      require('mason-lspconfig').setup {
        ensure_installed = lsp_servers, -- Only LSP servers here
        automatic_enable = {
          -- Manual start only: `:LspStart <server>` (or `:LspInfo` to inspect)
          exclude = {
            'vtsls',
            'tailwindcss',
          },
        },
      }

      -- LSP Attach Handler
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          local telescope = require 'telescope.builtin'

          -- Navigation
          map('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
          map('gr', telescope.lsp_references, '[G]oto [R]eferences')
          map('gI', telescope.lsp_implementations, '[G]oto [I]mplementation')
          map('<leader>D', telescope.lsp_type_definitions, 'Type [D]efinition')

          -- Symbols
          map('<leader>ds', telescope.lsp_document_symbols, '[D]ocument [S]ymbols')
          map('<leader>ws', telescope.lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

          -- Code Actions
          map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })
          map('<leader>cd', vim.diagnostic.open_float, '[C]ode [D]iagnostic')
          map('<leader>ch', vim.lsp.buf.hover, '[C]ode [H]over')
          map('<leader>ce', function()
            vim.diagnostic.jump { forward = true, float = true, count = 1 }
          end, '[C]ode [E]rror')

          -- Diagnostic Config: see init.lua

          -- Helper function for version compatibility
          ---@param client vim.lsp.Client
          ---@param method vim.lsp.protocol.Method
          ---@param bufnr? integer
          ---@return boolean
          local function client_supports_method(client, method, bufnr)
            if vim.fn.has 'nvim-0.11' == 1 then
              return client:supports_method(method, bufnr)
            else
              return client.supports_method(method, { bufnr = bufnr })
            end
          end

          local client = vim.lsp.get_client_by_id(event.data.client_id)

          -- tsc cannot publish diagnostics for unopened files; pull them so the
          -- file tree can show project errors. See lua/ts-project-diagnostics.lua
          if client and client.name == 'tsc' then
            require('ts-project-diagnostics').setup(client)
          end

          -- Inlay hints
          if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle Inlay [H]ints')
          end

          -- Document highlight
          if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
            local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })
            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'lsp-highlight', buffer = event2.buf }
              end,
            })
          end
        end,
      })
    end,
  },

  -- Lua development for Neovim
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = 'luvit-meta/library', words = { 'vim%.uv' } },
      },
    },
  },
  { 'Bilal2453/luvit-meta', lazy = true },
}
