-- Project-wide TypeScript diagnostics for the `tsc` (typescript-go) server.
--
-- tsc advertises `workspaceDiagnostics = false`, so Neovim only ever sees
-- diagnostics for files open in a buffer. It does answer `textDocument/diagnostic`
-- for any file in the program, including files that were never opened, so we pull
-- per file and store the result on an unloaded buffer. Tree plugins read that.
--
-- shortcut: no incremental refresh, every save re-pulls the whole project.
-- Upgrade to a file watcher if a project gets too large for that.

local M = {}

local ns = vim.api.nvim_create_namespace 'ts-project-diagnostics'
local augroup = vim.api.nvim_create_augroup('ts-project-diagnostics', { clear = true })
local MAX_FILES = 1000
local DEBOUNCE_MS = 600

local EXTS = {
  ts = true,
  tsx = true,
  mts = true,
  cts = true,
  js = true,
  jsx = true,
  mjs = true,
  cjs = true,
}

local state = {
  client = nil,
  root = nil,
  queue = {},
  bufs = {},
  gen = 0,
  busy = false,
  timer = nil,
  warned = false,
}

local function list_files(root)
  local files = {}
  local ok, out = pcall(vim.fn.systemlist, { 'git', '-C', root, 'ls-files', '--cached', '--others', '--exclude-standard' })
  if not ok or vim.v.shell_error ~= 0 then
    return files
  end
  local base = root:gsub('/+$', '')
  for _, rel in ipairs(out) do
    if EXTS[vim.fn.fnamemodify(rel, ':e')] then
      files[#files + 1] = base .. '/' .. rel
    end
  end
  return files
end

-- LSP character offsets -> byte columns. Lines are only read for files that
-- actually have diagnostics, so a clean project stays off disk.
local function to_vim(client, path, items)
  local encoding = client.offset_encoding or 'utf-16'
  local lines
  local function byte_col(lnum, character)
    lines = lines or vim.fn.readfile(path)
    local line = lines[lnum + 1] or ''
    local ok, col = pcall(vim.str_byteindex, line, encoding, character, false)
    return ok and col or character
  end
  local out = {}
  for _, d in ipairs(items) do
    local start, finish = d.range.start, d.range['end']
    out[#out + 1] = {
      lnum = start.line,
      col = byte_col(start.line, start.character),
      end_lnum = finish.line,
      end_col = byte_col(finish.line, finish.character),
      severity = d.severity,
      message = d.message,
      source = d.source,
      code = d.code,
    }
  end
  return out
end

local function apply(client, path, items)
  if #items == 0 and vim.fn.bufnr(path) == -1 then
    return
  end
  local bufnr = vim.fn.bufadd(path)
  state.bufs[bufnr] = true
  vim.diagnostic.set(ns, bufnr, to_vim(client, path, items))
end

local function step()
  if state.busy then
    return
  end
  local item = table.remove(state.queue, 1)
  if not item then
    return
  end
  local client = state.client
  if not client or client:is_stopped() then
    return
  end
  state.busy = true
  client:request('textDocument/diagnostic', { textDocument = { uri = vim.uri_from_fname(item.path) } }, function(err, result)
    state.busy = false
    if item.gen == state.gen and not err and result and result.items then
      apply(client, item.path, result.items)
    end
    vim.schedule(step)
  end)
end

function M.clear()
  for bufnr in pairs(state.bufs) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.diagnostic.set(ns, bufnr, {})
    end
  end
  state.bufs = {}
  state.queue = {}
  state.gen = state.gen + 1
end

function M.refresh()
  local client = state.client
  if not client or client:is_stopped() then
    return
  end
  state.gen = state.gen + 1
  local gen = state.gen
  state.queue = {}

  local files = list_files(state.root)
  if #files > MAX_FILES then
    if not state.warned then
      state.warned = true
      vim.notify(('[ts-project-diagnostics] %d files, over the %d limit; skipped'):format(#files, MAX_FILES), vim.log.levels.WARN)
    end
    M.clear()
    return
  end

  local seen = {}
  for _, path in ipairs(files) do
    local bufnr = vim.fn.bufnr(path)
    if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
      -- Open buffers get their own pull from the LSP client.
      seen[bufnr] = true
      state.bufs[bufnr] = nil
      vim.diagnostic.set(ns, bufnr, {})
    else
      if bufnr ~= -1 then
        seen[bufnr] = true
      end
      state.queue[#state.queue + 1] = { path = path, gen = gen }
    end
  end

  -- Drop diagnostics for files that left the project (deleted or ignored).
  for bufnr in pairs(state.bufs) do
    if not seen[bufnr] and vim.api.nvim_buf_is_valid(bufnr) then
      vim.diagnostic.set(ns, bufnr, {})
    end
    state.bufs[bufnr] = nil
  end

  step()
end

local function schedule_refresh()
  if not state.client or state.client:is_stopped() then
    return
  end
  if not state.timer or state.timer:is_closing() then
    state.timer = vim.uv.new_timer()
  end
  state.timer:stop()
  state.timer:start(DEBOUNCE_MS, 0, vim.schedule_wrap(M.refresh))
end

function M.setup(client)
  if client.name ~= 'tsc' or not client:supports_method 'textDocument/diagnostic' then
    return
  end
  if state.client and state.client.id == client.id then
    return
  end
  local root = client.config.root_dir or client.root_dir
  if not root or root == '' then
    return
  end

  state.client, state.root = client, root
  state.warned = false

  vim.defer_fn(M.refresh, 300)

  vim.api.nvim_create_autocmd('BufWritePost', {
    group = augroup,
    pattern = { '*.ts', '*.tsx', '*.js', '*.jsx', '*.mts', '*.cts', '*.mjs', '*.cjs' },
    callback = schedule_refresh,
  })
  vim.api.nvim_create_autocmd('LspDetach', {
    group = augroup,
    callback = function(event)
      if event.data and event.data.client_id == client.id then
        M.clear()
        state.client = nil
      end
    end,
  })
  vim.api.nvim_create_user_command('TsProjectDiagnostics', M.refresh, { desc = 'Refresh project-wide TypeScript diagnostics' })
  vim.api.nvim_create_user_command('TsProjectDiagnosticsClear', M.clear, { desc = 'Clear project-wide TypeScript diagnostics' })
end

return M
