-- ========================================================================== --
--                    NEOVIM KEYBINDS & MOTIONS MANUAL                        --
-- ========================================================================== --

local M = {}

local ns = vim.api.nvim_create_namespace("nvim_manual_popup")

local function setup_highlights()
  local ok, palettes = pcall(require, "catppuccin.palettes")
  local p = ok and palettes.get_palette() or {}

  local base = p.base or "#1e1e2e"
  local surface0 = p.surface0 or "#313244"
  local surface2 = p.surface2 or "#585b70"
  local overlay0 = p.overlay0 or "#6c7086"
  local subtext0 = p.subtext0 or "#a6adc8"
  local subtext1 = p.subtext1 or "#bac2de"
  local text = p.text or "#cdd6f4"
  local mauve = p.mauve or "#cba6f7"
  local pink = p.pink or "#f5c2e7"
  local blue = p.blue or "#89b4fa"
  local teal = p.teal or "#94e2d5"
  local yellow = p.yellow or "#f9e2af"

  vim.api.nvim_set_hl(0, "ManualNormal", { bg = "NONE", fg = text })
  vim.api.nvim_set_hl(0, "ManualBorder", { bg = "NONE", fg = surface2 })
  vim.api.nvim_set_hl(0, "ManualTitle", { bg = "NONE", fg = mauve, bold = true })
  vim.api.nvim_set_hl(0, "ManualSubtitle", { bg = "NONE", fg = subtext0, italic = true })
  vim.api.nvim_set_hl(0, "ManualSection", { bg = "NONE", fg = pink, bold = true })
  vim.api.nvim_set_hl(0, "ManualSectionLine", { bg = "NONE", fg = surface0 })
  vim.api.nvim_set_hl(0, "ManualKey", { bg = "NONE", fg = blue, bold = true })
  vim.api.nvim_set_hl(0, "ManualKeyBadge", { bg = surface0, fg = mauve, bold = true })
  vim.api.nvim_set_hl(0, "ManualKeyBadgeActive", { bg = mauve, fg = base, bold = true })
  vim.api.nvim_set_hl(0, "ManualPointer", { bg = "NONE", fg = pink, bold = true })
  vim.api.nvim_set_hl(0, "ManualTopicActive", { bg = "NONE", fg = text, bold = true })
  vim.api.nvim_set_hl(0, "ManualTopicNormal", { bg = "NONE", fg = subtext1 })
  vim.api.nvim_set_hl(0, "ManualDesc", { bg = "NONE", fg = subtext1 })
  vim.api.nvim_set_hl(0, "ManualDescMuted", { bg = "NONE", fg = subtext0 })
  vim.api.nvim_set_hl(0, "ManualIcon", { bg = "NONE", fg = teal })
  vim.api.nvim_set_hl(0, "ManualNote", { bg = "NONE", fg = yellow, italic = true })
  vim.api.nvim_set_hl(0, "ManualMuted", { bg = "NONE", fg = overlay0 })
  vim.api.nvim_set_hl(0, "ManualFooter", { bg = "NONE", fg = overlay0, italic = true })
  vim.api.nvim_set_hl(0, "ManualCursorLine", { bg = surface0 })
end

-- ========================================================================== --
--                             MANUAL PAGES DATA                              --
-- ========================================================================== --

M.pages = {
  {
    id = "motions",
    icon = "󰌌 ",
    title = "Vim Motions & Editing",
    summary = "Move around, edit words/lines, copy & paste, select text & multi-cursor",
    sections = {
      {
        heading = "Basic Movement & Jumping",
        items = {
          { key = "h / j / k / l", desc = "Move Left / Down / Up / Right (prefix a count like 10j to jump 10 lines)" },
          { key = "w / b / e", desc = "Jump to start of next word (w), previous word (b), or end of word (e)" },
          { key = "0 / ^ / $", desc = "Jump to start of line (0), first non-blank char (^), or end of line ($)" },
          { key = "f{c} / t{c}", desc = "Jump onto next char {c} (f) or right before it (t); press ; to repeat" },
          { key = "%", desc = "Jump between matching brackets ( ), { }, [ ]" },
          { key = "gg / G", desc = "Jump to top of file (gg) or bottom of file (G), or {line}G" },
          { key = "{ / }", desc = "Jump up/down between blank lines / code blocks" },
          { key = "<C-u> / <C-d>", desc = "Smoothly scroll half a screen Up (Ctrl+u) or Down (Ctrl+d)" },
          { key = "zz / zt / zb", desc = "Smoothly center cursor line (zz), or align to top (zt) / bottom (zb)" },
          { key = "<C-o> / <C-i>", desc = "Jump Back (Ctrl+o) and Forward (Ctrl+i) in your jump history" },
        },
      },
      {
        heading = "Actions, Smart Targets & Multi-Cursor",
        items = {
          { key = "d / c / y + motion", desc = "Delete (d), Change (c), or Yank/Copy (y) — e.g. dw, cw, yy, dd" },
          { key = "ciw / ci\" / ci(", desc = "Change inside current word (ciw), quotes (ci\"), or parens (ci()" },
          { key = "u / <C-r>", desc = "Undo (u) / Redo (<C-r>) with flash highlight & persistent disk history" },
          { key = ".", desc = "Repeat the last edit command" },
          { key = "<C-n>  (visual-multi)", desc = "Select word under cursor & add next occurrence as a multi-cursor" },
          { key = "<A-e>  (autopairs)", desc = "Fast-wrap expression in Insert mode using nvim-autopairs" },
          { key = "/{text}  /  *", desc = "Search forward (/text) or word under cursor (*); <Esc> clears highlight" },
        },
      },
    },
  },

  {
    id = "core",
    icon = "󰒓 ",
    title = "Core Config, Files & Search",
    summary = "Leader shortcuts, Telescope fuzzy search, Neo-tree sidebar & UndoTree",
    sections = {
      {
        heading = "General Shortcuts (init.lua & vim-options.lua)",
        items = {
          { key = "<Space>", desc = "Leader key (2-space indent, mouse enabled, system clipboard, auto-save)" },
          { key = "<Esc>", desc = "Clear search highlights (:noh)" },
          { key = "<Space>;  /  :Dashboard", desc = "Open your animated ASCII-Sharks Startup Dashboard" },
          { key = "<Space>m  /  :Manual", desc = "Open this Keybinds & Motions Manual (e.g. :Manual git)" },
          { key = "<Space>u", desc = "Toggle UndoTree panel (persistent undo saved in data/undo)" },
          { key = "<F5> / <F6>", desc = "Compile & run current C++ file with g++ (F6 opens a split terminal)" },
        },
      },
      {
        heading = "Telescope Search (plugins/editor/telescope.lua)",
        items = {
          { key = "<C-p>", desc = "Find Files in the directory Neovim was launched from" },
          { key = "<Space>fg", desc = "Live Grep — search text across files in your workspace" },
          { key = "<C-v> / <C-x>", desc = "Inside Telescope: open in vertical split (Ctrl+v) or horizontal (Ctrl+x)" },
        },
      },
      {
        heading = "Neo-tree File Explorer (plugins/ui/neo-tree.lua)",
        items = {
          { key = "<C-l>", desc = "Reveal & focus Neo-tree file explorer on the Left" },
          { key = "<C-r>", desc = "Reveal & focus Neo-tree file explorer on the Right" },
          { key = "a / d / r  (in tree)", desc = "Add file/folder (a), Delete (d), or Rename (r) inside Neo-tree" },
        },
      },
    },
  },

  {
    id = "lsp",
    icon = "󰅩 ",
    title = "LSP, Diagnostics & Debugging",
    summary = "Go to definition, code actions, formatting, Trouble panels, TODOs & DAP",
    sections = {
      {
        heading = "LSP & Formatting (lsp-config.lua & none-ls.lua)",
        items = {
          { key = "k", desc = "Show hover documentation for symbol under cursor" },
          { key = "gd  or  <C-Click>", desc = "Jump to definition (works with Ctrl+LeftMouse in Normal & Insert mode)" },
          { key = "<Space>ca", desc = "Open LSP code actions / quick fixes" },
          { key = "<Space>gf", desc = "Format buffer via LSP / none-ls (stylua, prettier, black, clang-format, gofumpt)" },
        },
      },
      {
        heading = "Trouble & TODO Comments (trouble.lua & todo-comments.lua)",
        items = {
          { key = "<Space>xx / <Space>xX", desc = "Toggle Trouble diagnostics for project (xx) or current buffer (xX)" },
          { key = "<Space>xs / <Space>xl", desc = "Toggle Trouble document symbols (xs) or LSP definitions/refs (xl)" },
          { key = "<Space>xL / <Space>xQ", desc = "Toggle Trouble location list (xL) or quickfix list (xQ)" },
          { key = "]t / [t", desc = "Jump to next / previous TODO, FIX, NOTE, or WARN comment" },
          { key = "<Space>xt / <Space>xT", desc = "Open TODO list in Trouble (xt) or filtered TODO/FIX/FIXME (xT)" },
          { key = "<Space>st", desc = "Search all TODO comments with Telescope (:TodoTelescope)" },
        },
      },
      {
        heading = "Debugging (nvim-dap / debugging.lua)",
        items = {
          { key = "<Space>dt", desc = "Toggle breakpoint on current line" },
          { key = "<Space>dc", desc = "Start or continue debugging session" },
        },
      },
    },
  },

  {
    id = "git",
    icon = "󰊢 ",
    title = "Git (Gitsigns, Diffview, LazyGit & Flog)",
    summary = "Hunk navigation, staging/resetting, blame, diffs, LazyGit, Neogit & commit graph",
    sections = {
      {
        heading = "Hunk Navigation & Actions (gitsigns.lua)",
        items = {
          { key = "]h / [h", desc = "Jump to next (]h) or previous ([h) Git hunk" },
          { key = "<Space>hs / <Space>hr", desc = "Stage (hs) or Reset (hr) hunk (also works in Visual mode)" },
          { key = "<Space>hS / <Space>hR", desc = "Stage (hS) or Reset (hR) entire buffer" },
          { key = "<Space>hu / <Space>hp", desc = "Undo last staged hunk (hu) or Preview hunk popup (hp)" },
          { key = "<Space>td", desc = "Toggle inline deleted lines" },
        },
      },
      {
        heading = "Blame, Diffs & Git UIs (diffview, lazygit, neogit, fugitive, flog)",
        items = {
          { key = "<Space>lg", desc = "Open LazyGit floating terminal" },
          { key = "<Space>ng", desc = "Open Neogit status UI" },
          { key = "<Space>gs / <Space>gw", desc = "Fugitive Git status (gs) or stage current file (gw)" },
          { key = "<Space>gb / <Space>gB", desc = "Git blame line (Gitsigns/Fugitive) or open in browser (GBrowse)" },
          { key = "<Space>gd / <Space>gD", desc = "Open Diffview (gd) / Close Diffview (gD)" },
          { key = "<Space>gh", desc = "Open Diffview file history for current file" },
          { key = "<Space>gl / <Space>gls", desc = "Open Flog Git log graph (gl) or split log graph (gls)" },
        },
      },
    },
  },

  {
    id = "visuals",
    icon = "󰉦 ",
    title = "Dashboard & Animations",
    summary = "ASCII-Sharks startup screen, cursor/scroll animations, sparkles & break-time fun",
    sections = {
      {
        heading = "ASCII-Sharks Dashboard (plugins/ui/dashboard.lua)",
        items = {
          { key = "f / r / g / e", desc = "Find File (f), Recent Files (r), Live Grep (g), File Explorer (e)" },
          { key = "n / v / c / l / q", desc = "New Buffer (n), Git Status (v), Config (c), Lazy (l), Quit (q)" },
          { key = "1 .. 4  /  j / k / <CR>", desc = "Open recent file 1-4, or navigate actions with j/k and Enter" },
          { key = "s", desc = "Cycle between the 3 ASCII shark species rosters on the dashboard" },
        },
      },
      {
        heading = "Editor Animations (plugins/ui/animations.lua)",
        items = {
          { key = "Smear & Beacon", desc = "Cursor comet trail + Catppuccin pulse on >=8-line jumps or window switch" },
          { key = "Smooth Scroll & Scope", desc = "Quadratic scrolling (<C-d>/<C-u>) & animated Mauve indent scope" },
          { key = "Yank / Undo Flash", desc = "Flashes yanked text, undo (u), and redo (<C-r>)" },
          { key = "<Space>fml / fmg / fms", desc = "Cellular Automaton: falling sand (fml), Game of Life (fmg), scramble (fms)" },
          { key = ":ToggleTypingSparkles", desc = "Toggle Insert-mode pastel sparkle particles on or off" },
        },
      },
    },
  },
}

-- ========================================================================== --
--                        FLOATING WINDOW MANAGEMENT                          --
-- ========================================================================== --

local state = {
  win = nil,
  buf = nil,
  mode = nil,
  page_idx = 1,
}

local function close_active()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    pcall(vim.api.nvim_win_close, state.win, true)
  end
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    pcall(vim.api.nvim_buf_delete, state.buf, { force = true })
  end
  state.win = nil
  state.buf = nil
  state.mode = nil
end

local function create_float(width, height, title, footer)
  close_active()
  setup_highlights()

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].buflisted = false
  vim.bo[buf].filetype = "manual"

  local ui = vim.api.nvim_list_uis()[1]
  local cols = ui and ui.width or vim.o.columns
  local rows = ui and ui.height or vim.o.lines

  local w = math.min(width, math.max(44, cols - 4))
  local h = math.min(height, math.max(12, rows - 4))
  local row = math.max(0, math.floor((rows - h) / 2) - 1)
  local col = math.max(0, math.floor((cols - w) / 2))

  local win_opts = {
    relative = "editor",
    width = w,
    height = h,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = { { " " .. title .. " ", "ManualTitle" } },
    title_pos = "center",
  }

  if footer and vim.fn.has("nvim-0.10") == 1 then
    win_opts.footer = { { " " .. footer .. " ", "ManualFooter" } }
    win_opts.footer_pos = "center"
  end

  local win = vim.api.nvim_open_win(buf, true, win_opts)
  vim.wo[win].winhl = "Normal:ManualNormal,FloatBorder:ManualBorder,CursorLine:ManualCursorLine"
  vim.wo[win].wrap = false

  state.win = win
  state.buf = buf

  vim.api.nvim_create_autocmd("ColorScheme", {
    buffer = buf,
    callback = setup_highlights,
  })

  return buf, win, w, h
end

-- ========================================================================== --
--                          CATEGORY PICKER POPUP                             --
-- ========================================================================== --

function M.open_picker()
  local lines = {}
  local highlights = {}
  local item_rows = {}

  local function add_line(text, spans)
    table.insert(lines, text)
    if spans then
      highlights[#lines] = spans
    end
  end

  add_line("")
  local header = "   ✦  Select a manual topic:"
  add_line(header, {
    { "ManualSection", 0, 5 },
    { "ManualSubtitle", 5, #header },
  })
  add_line("")

  local first_item_line = #lines + 1
  for idx, page in ipairs(M.pages) do
    local row_num = #lines + 1
    local badge = "[" .. idx .. "]"
    local prefix = "     "
    local icon_str = "  " .. page.icon .. " "
    local title_str = page.title .. "   "
    local full = prefix .. badge .. icon_str .. title_str

    local c1 = #prefix
    local c2 = c1 + #badge
    local c3 = c2 + #icon_str

    add_line(full, {
      { "ManualKeyBadge", c1, c2 },
      { "ManualIcon", c2, c3 },
      { "ManualTopicActive", c3, #full },
    })
    item_rows[row_num] = idx
  end
  local last_item_line = #lines

  add_line("")
  local tip = "   1-" .. #M.pages .. " / <Enter>: Open   •   q / <Esc>: Close"
  add_line(tip, { { "ManualMuted", 0, #tip } })
  add_line("")

  local max_w = 50
  for _, l in ipairs(lines) do
    max_w = math.max(max_w, vim.fn.strdisplaywidth(l) + 4)
  end

  local buf, win = create_float(
    max_w,
    #lines,
    "✦  NEOVIM MANUAL  ✦",
    "j/k: Move  •  Enter: Open  •  q: Close"
  )
  state.mode = "picker"
  vim.wo[win].cursorline = true

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  for row, spans in pairs(highlights) do
    for _, sp in ipairs(spans) do
      pcall(vim.api.nvim_buf_add_highlight, buf, ns, sp[1], row - 1, sp[2], sp[3])
    end
  end

  local pointer_ns = vim.api.nvim_create_namespace("nvim_manual_pointer")
  local function update_pointer(row_num)
    vim.api.nvim_buf_clear_namespace(buf, pointer_ns, 0, -1)
    vim.api.nvim_buf_set_extmark(buf, pointer_ns, row_num - 1, 0, {
      virt_text = { { "  ❯", "ManualPointer" } },
      virt_text_pos = "overlay",
      priority = 200,
    })
  end

  local initial_row = first_item_line + math.max(0, math.min(#M.pages - 1, (state.page_idx or 1) - 1))
  pcall(vim.api.nvim_win_set_cursor, win, { initial_row, 2 })
  update_pointer(initial_row)

  local clamping = false
  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = buf,
    callback = function()
      if clamping or not vim.api.nvim_win_is_valid(win) then
        return
      end
      local cur = vim.api.nvim_win_get_cursor(win)[1]
      local clamped = math.max(first_item_line, math.min(last_item_line, cur))
      if cur ~= clamped then
        clamping = true
        pcall(vim.api.nvim_win_set_cursor, win, { clamped, 2 })
        clamping = false
      end
      update_pointer(clamped)
    end,
  })

  local function select_current()
    local cur = vim.api.nvim_win_get_cursor(win)[1]
    local idx = item_rows[cur]
    if idx then
      M.open_page(idx)
    end
  end

  local map_opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "<CR>", select_current, map_opts)
  vim.keymap.set("n", "l", select_current, map_opts)
  vim.keymap.set("n", "<Space>", select_current, map_opts)
  vim.keymap.set("n", "q", close_active, map_opts)
  vim.keymap.set("n", "<Esc>", close_active, map_opts)

  for i = 1, #M.pages do
    vim.keymap.set("n", tostring(i), function()
      M.open_page(i)
    end, map_opts)
  end
end

-- ========================================================================== --
--                            MANUAL READER POPUP                             --
-- ========================================================================== --

function M.open_page(idx_or_id)
  local page_idx = 1
  if type(idx_or_id) == "number" then
    page_idx = ((idx_or_id - 1) % #M.pages) + 1
  elseif type(idx_or_id) == "string" then
    local query = idx_or_id:lower()
    for i, p in ipairs(M.pages) do
      if p.id == query or p.title:lower():find(query, 1, true) then
        page_idx = i
        break
      end
    end
  end

  state.page_idx = page_idx
  local page = M.pages[page_idx]

  local lines = {}
  local highlights = {}

  local function add_line(text, hl_spans)
    table.insert(lines, text)
    if hl_spans then
      highlights[#lines] = hl_spans
    end
  end

  add_line("")
  local banner = string.format("   %s %s  (%d/%d)", page.icon, page.title, page_idx, #M.pages)
  add_line(banner, { { "ManualTitle", 0, #banner } })
  local sub = "   " .. page.summary
  add_line(sub, { { "ManualSubtitle", 0, #sub } })
  add_line("")

  local key_col_width = 26
  for _, sec in ipairs(page.sections) do
    local prefix = "   ✦ " .. sec.heading .. " "
    local rule = string.rep("─", math.max(4, 96 - vim.fn.strdisplaywidth(prefix)))
    local sec_hdr = prefix .. rule
    add_line(sec_hdr, {
      { "ManualSection", 0, #prefix },
      { "ManualSectionLine", #prefix, #sec_hdr },
    })

    for _, item in ipairs(sec.items) do
      local pad_len = math.max(2, key_col_width - vim.fn.strdisplaywidth(item.key))
      local key_part = "     " .. item.key .. string.rep(" ", pad_len)
      local sep_part = "│ "
      local desc_part = item.desc
      local row_str = key_part .. sep_part .. desc_part

      local c1 = #key_part
      local c2 = c1 + #sep_part
      add_line(row_str, {
        { "ManualKey", 0, c1 },
        { "ManualSectionLine", c1, c2 },
        { "ManualDesc", c2, #row_str },
      })
    end
    add_line("")
  end

  local nav_hint = "   [<BS> / b] Back to Categories   •   [[ / ]] Prev/Next Page   •   [/] Search   •   [q / <Esc>] Close"
  add_line(nav_hint, { { "ManualNote", 0, #nav_hint } })
  add_line("")

  local ui = vim.api.nvim_list_uis()[1]
  local max_rows = ui and math.floor(ui.height * 0.84) or 34
  local win_h = math.min(#lines, math.max(18, max_rows))
  local win_w = 104
  for _, l in ipairs(lines) do
    win_w = math.max(win_w, vim.fn.strdisplaywidth(l) + 4)
  end

  local buf, win = create_float(
    win_w,
    win_h,
    string.format("✦  %s %s (%d/%d)  ✦", page.icon, page.title, page_idx, #M.pages),
    "<BS>/b: Categories  •  [ / ]: Prev/Next Topic  •  j/k/<C-d>/<C-u>: Scroll  •  q/Esc: Close"
  )
  state.mode = "page"
  vim.wo[win].cursorline = true

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  for row, spans in pairs(highlights) do
    for _, sp in ipairs(spans) do
      pcall(vim.api.nvim_buf_add_highlight, buf, ns, sp[1], row - 1, sp[2], sp[3])
    end
  end

  pcall(vim.api.nvim_win_set_cursor, win, { 2, 3 })

  local map_opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "<BS>", M.open_picker, map_opts)
  vim.keymap.set("n", "b", M.open_picker, map_opts)
  vim.keymap.set("n", "h", M.open_picker, map_opts)
  vim.keymap.set("n", "[", function()
    M.open_page(page_idx - 1)
  end, map_opts)
  vim.keymap.set("n", "]", function()
    M.open_page(page_idx + 1)
  end, map_opts)
  vim.keymap.set("n", "<Left>", function()
    M.open_page(page_idx - 1)
  end, map_opts)
  vim.keymap.set("n", "<Right>", function()
    M.open_page(page_idx + 1)
  end, map_opts)
  vim.keymap.set("n", "q", close_active, map_opts)
  vim.keymap.set("n", "<Esc>", close_active, map_opts)
end

function M.open(arg)
  if arg and arg ~= "" then
    M.open_page(arg)
  else
    M.open_picker()
  end
end

M.close = close_active
M._state = state

return M
