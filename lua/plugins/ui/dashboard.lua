return {
  dir = vim.fn.stdpath("config"),
  name = "neovim-modern-dashboard",
  lazy = false,
  priority = 900,
  config = function()
    local uv = vim.uv or vim.loop
    local api = vim.api
    local fn = vim.fn

    -- Capture initial working directory before BufEnter `lcd %:p:h` changes it
    local launch_dir = fn.getcwd()

    local ns = api.nvim_create_namespace("ModernDashboard")
    local state = {
      buf = nil,
      win = nil,
      timer = nil,
      tick = 0,
      phase = "intro", -- "intro" -> "ambient"
      selected_idx = 1,
      interactive_lines = {},
      line_to_item = {},
      layout = nil,
      git_branch = nil,
    }

    -- Catppuccin Mocha gradient palette for the logo & section headers
    local gradient_stops = {
      { 203, 166, 247 }, -- Mauve     #cba6f7
      { 180, 190, 254 }, -- Lavender  #b4befe
      { 137, 180, 250 }, -- Blue      #89b4fa
      { 116, 199, 236 }, -- Sapphire  #74c7ec
      { 148, 226, 213 }, -- Teal      #94e2d5
      { 245, 194, 231 }, -- Pink      #f5c2e7
    }

    local NUM_GRADIENT_STEPS = 24
    local gradient_hls = {}

    local function rgb_to_hex(r, g, b)
      return string.format("#%02x%02x%02x", math.floor(r + 0.5), math.floor(g + 0.5), math.floor(b + 0.5))
    end

    local function interpolate_palette(t)
      t = t % 1.0
      local scaled = t * #gradient_stops
      local idx1 = math.floor(scaled) + 1
      local idx2 = (idx1 % #gradient_stops) + 1
      local frac = scaled - math.floor(scaled)
      frac = frac * frac * (3 - 2 * frac)
      local c1 = gradient_stops[idx1]
      local c2 = gradient_stops[idx2]
      return rgb_to_hex(
        c1[1] + (c2[1] - c1[1]) * frac,
        c1[2] + (c2[2] - c1[2]) * frac,
        c1[3] + (c2[3] - c1[3]) * frac
      )
    end

    local function setup_highlights()
      for i = 1, NUM_GRADIENT_STEPS do
        local hex = interpolate_palette((i - 1) / NUM_GRADIENT_STEPS)
        local hl_name = "DashboardGrad" .. i
        api.nvim_set_hl(0, hl_name, { fg = hex, bold = true })
        gradient_hls[i] = hl_name
      end

      -- UI Accent Highlights (Catppuccin Mocha palette)
      api.nvim_set_hl(0, "DashboardStarDim", { fg = "#45475a" })
      api.nvim_set_hl(0, "DashboardStarMid", { fg = "#7f849c" })
      api.nvim_set_hl(0, "DashboardStarBright", { fg = "#f9e2af", bold = true })
      api.nvim_set_hl(0, "DashboardSubtitle", { fg = "#a6adc8", italic = true })
      api.nvim_set_hl(0, "DashboardPillBorder", { fg = "#45475a" })
      api.nvim_set_hl(0, "DashboardPillProject", { fg = "#89b4fa", bold = true })
      api.nvim_set_hl(0, "DashboardPillGit", { fg = "#a6e3a1", bold = true })
      api.nvim_set_hl(0, "DashboardPillClock", { fg = "#f9e2af", bold = true })

      api.nvim_set_hl(0, "DashboardBoxBorder", { fg = "#313244" })
      api.nvim_set_hl(0, "DashboardBoxBorderActive", { fg = "#585b70" })
      api.nvim_set_hl(0, "DashboardSectionTitle", { fg = "#cba6f7", bold = true })

      api.nvim_set_hl(0, "DashboardItemNormal", { fg = "#bac2de" })
      api.nvim_set_hl(0, "DashboardItemActive", { fg = "#cdd6f4", bold = true })
      api.nvim_set_hl(0, "DashboardPointer", { fg = "#f5c2e7", bold = true })
      api.nvim_set_hl(0, "DashboardKeyBadge", { fg = "#cba6f7", bold = true })
      api.nvim_set_hl(0, "DashboardKeyBadgeActive", { fg = "#1e1e2e", bg = "#cba6f7", bold = true })
      api.nvim_set_hl(0, "DashboardKeyBracket", { fg = "#585b70" })
      api.nvim_set_hl(0, "DashboardRecentPath", { fg = "#6c7086" })
      api.nvim_set_hl(0, "DashboardRecentPathActive", { fg = "#a6adc8" })

      -- Action icon colors
      api.nvim_set_hl(0, "DashboardIconFind", { fg = "#89b4fa" })
      api.nvim_set_hl(0, "DashboardIconRecent", { fg = "#f9e2af" })
      api.nvim_set_hl(0, "DashboardIconGrep", { fg = "#94e2d5" })
      api.nvim_set_hl(0, "DashboardIconTree", { fg = "#a6e3a1" })
      api.nvim_set_hl(0, "DashboardIconNew", { fg = "#b4befe" })
      api.nvim_set_hl(0, "DashboardIconGit", { fg = "#fab387" })
      api.nvim_set_hl(0, "DashboardIconConfig", { fg = "#cba6f7" })
      api.nvim_set_hl(0, "DashboardIconLazy", { fg = "#f5c2e7" })
      api.nvim_set_hl(0, "DashboardIconQuit", { fg = "#f38ba8" })
    end

    local function detect_git_branch()
      local out = fn.systemlist({ "git", "-C", launch_dir, "branch", "--show-current" })
      if vim.v.shell_error == 0 and out and out[1] and out[1] ~= "" then
        state.git_branch = out[1]
      else
        state.git_branch = nil
      end
    end

    -- Geometric NEOVIM banner with orbital starfield frame
    local logo_final = {
      "    ·  ✦       ███╗   ██╗ ███████╗  ██████╗  ██╗   ██╗ ██╗ ███╗   ███╗       ✦  ·    ",
      "  ✦       ·    ████╗  ██║ ██╔════╝ ██╔═══██╗ ██║   ██║ ██║ ████╗ ████║    ·       ✦  ",
      "     ·         ██╔██╗ ██║ █████╗   ██║   ██║ ██║   ██║ ██║ ██╔████╔██║         ·     ",
      "  ·     ✦      ██║╚██╗██║ ██╔══╝   ██║   ██║ ╚██╗ ██╔╝ ██║ ██║╚██╔╝██║      ✦     ·  ",
      "    ✦       ·  ██║ ╚████║ ███████╗ ╚██████╔╝  ╚████╔╝  ██║ ██║ ╚═╝ ██║  ·       ✦    ",
      "       ·       ╚═╝  ╚═══╝ ╚══════╝  ╚═════╝    ╚═══╝   ╚═╝ ╚═╝     ╚═╝       ·       ",
    }

    local scramble_glyphs = { "░", "▒", "▓", "◈", "◇", "◆", "∙", "·" }

    local function split_utf8_cells(str)
      local cells = {}
      local n = fn.strchars(str)
      local byte_pos = 0
      for i = 0, n - 1 do
        local ch = fn.strcharpart(str, i, 1)
        local blen = #ch
        local width = fn.strdisplaywidth(ch)
        table.insert(cells, {
          char = ch,
          col_idx = i,
          byte_start = byte_pos,
          byte_end = byte_pos + blen,
          width = width,
        })
        byte_pos = byte_pos + blen
      end
      return cells
    end

    local logo_cells = {}
    for idx, line in ipairs(logo_final) do
      logo_cells[idx] = split_utf8_cells(line)
    end

    local function get_recent_files(max_count)
      local results = {}
      local seen = {}
      local oldfiles = vim.v.oldfiles or {}
      local devicons_ok, devicons = pcall(require, "nvim-web-devicons")

      for _, file in ipairs(oldfiles) do
        if #results >= max_count then
          break
        end
        local abs = fn.fnamemodify(file, ":p")
        if
          abs ~= ""
          and not seen[abs]
          and not abs:match("COMMIT_EDITMSG")
          and not abs:match("/%.git/")
          and fn.filereadable(abs) == 1
        then
          seen[abs] = true
          local filename = fn.fnamemodify(abs, ":t")
          local ext = fn.fnamemodify(abs, ":e")
          local icon, icon_hl = "󰈔", "DashboardItemNormal"
          if devicons_ok then
            local ic, hl = devicons.get_icon(filename, ext, { default = true })
            if ic then
              icon = ic
            end
            if hl then
              icon_hl = hl
            end
          end

          local dir_path = fn.fnamemodify(abs, ":h")
          local short_dir = fn.fnamemodify(dir_path, ":~")
          if dir_path == launch_dir then
            short_dir = "./"
          elseif dir_path:sub(1, #launch_dir + 1) == launch_dir .. "/" then
            short_dir = "./" .. dir_path:sub(#launch_dir + 2)
          end
          if fn.strdisplaywidth(short_dir) > 23 then
            short_dir = "…" .. fn.strcharpart(short_dir, fn.strchars(short_dir) - 22)
          end

          local disp_name = filename
          if fn.strdisplaywidth(disp_name) > 20 then
            disp_name = fn.strcharpart(disp_name, 0, 19) .. "…"
          end

          table.insert(results, {
            abs = abs,
            filename = disp_name,
            short_path = short_dir,
            icon = icon,
            icon_hl = icon_hl,
            key = tostring(#results + 1),
          })
        end
      end
      return results
    end

    local function get_actions()
      return {
        {
          key = "f",
          icon = "󰈞",
          icon_hl = "DashboardIconFind",
          label = "Find File",
          desc = "Search project files",
          action = function()
            require("telescope.builtin").find_files({ cwd = launch_dir })
          end,
        },
        {
          key = "r",
          icon = "󰄉",
          icon_hl = "DashboardIconRecent",
          label = "Recent Files",
          desc = "Browse file history",
          action = function()
            require("telescope.builtin").oldfiles()
          end,
        },
        {
          key = "g",
          icon = "󰊄",
          icon_hl = "DashboardIconGrep",
          label = "Live Grep",
          desc = "Search text in workspace",
          action = function()
            require("telescope.builtin").live_grep({ cwd = launch_dir })
          end,
        },
        {
          key = "e",
          icon = "󰙅",
          icon_hl = "DashboardIconTree",
          label = "File Explorer",
          desc = "Toggle Neo-tree sidebar",
          action = function()
            vim.cmd("Neotree filesystem reveal left")
          end,
        },
        {
          key = "n",
          icon = "󰈔",
          icon_hl = "DashboardIconNew",
          label = "New Buffer",
          desc = "Create untitled file",
          action = function()
            vim.cmd("enew | startinsert")
          end,
        },
        {
          key = "v",
          icon = "󰊢",
          icon_hl = "DashboardIconGit",
          label = "Git Status",
          desc = "Open LazyGit / Neogit",
          action = function()
            if fn.executable("lazygit") == 1 then
              vim.cmd("LazyGit")
            else
              vim.cmd("Neogit")
            end
          end,
        },
        {
          key = "c",
          icon = "󰒓",
          icon_hl = "DashboardIconConfig",
          label = "Neovim Config",
          desc = "Edit ~/.config/nvim",
          action = function()
            require("telescope.builtin").find_files({ cwd = fn.stdpath("config") })
          end,
        },
        {
          key = "l",
          icon = "󰒲",
          icon_hl = "DashboardIconLazy",
          label = "Lazy Manager",
          desc = "Manage plugins & updates",
          action = function()
            vim.cmd("Lazy")
          end,
        },
        {
          key = "q",
          icon = "󰅚",
          icon_hl = "DashboardIconQuit",
          label = "Quit Neovim",
          desc = "Exit editor session",
          action = function()
            vim.cmd("qa")
          end,
        },
      }
    end

    local function pad_right(str, width)
      local w = fn.strdisplaywidth(str)
      if w >= width then
        return str
      end
      return str .. string.rep(" ", width - w)
    end

    local function center_line(str, win_width)
      local w = fn.strdisplaywidth(str)
      local pad = math.max(0, math.floor((win_width - w) / 2))
      return string.rep(" ", pad) .. str, pad, w
    end

    -- Build centered dashboard layout without background waves or footer lines
    local function build_layout()
      if not state.win or not api.nvim_win_is_valid(state.win) then
        return
      end
      local win_width = api.nvim_win_get_width(state.win)
      local win_height = api.nvim_win_get_height(state.win)

      local card_width = 64
      local card_pad = math.max(0, math.floor((win_width - card_width) / 2))
      local card_indent = string.rep(" ", card_pad)

      local actions = get_actions()
      local recents = get_recent_files(4)

      local lines = {}
      local meta = {
        win_width = win_width,
        win_height = win_height,
        card_width = card_width,
        card_pad = card_pad,
        logo_rows = {},
        logo_pad = 0,
        pill_row = nil,
        box_rows = {},
        section_rows = {},
        action_rows = {},
        recent_rows = {},
      }

      state.interactive_lines = {}
      state.line_to_item = {}

      -- Center the entire logo + pill + controls box vertically in the screen
      local card_rows_count = 3 + #actions + (#recents > 0 and (#recents + 3) or 0) + 1
      local est_height = #logo_final + 1 + 1 + 1 + card_rows_count
      local top_pad = math.max(1, math.floor((win_height - est_height) / 2))
      for _ = 1, top_pad do
        table.insert(lines, "")
      end

      -- 1. Logo Rows
      for i, raw in ipairs(logo_final) do
        local centered, pad = center_line(raw, win_width)
        table.insert(lines, centered)
        local r_idx = #lines - 1
        meta.logo_rows[i] = r_idx
        meta.logo_pad = pad
      end

      table.insert(lines, "")

      -- 2. Context Pill Row (Project + Git Branch + Clock)
      local proj_name = fn.fnamemodify(launch_dir, ":t")
      if proj_name == "" then
        proj_name = "~"
      end
      local clock_str = os.date("%H:%M")
      local pill_segments = {
        { text = "╭─ ", hl = "DashboardPillBorder" },
        { text = "󰉋  " .. proj_name, hl = "DashboardPillProject" },
      }
      if state.git_branch then
        table.insert(pill_segments, { text = "   │   ", hl = "DashboardPillBorder" })
        table.insert(pill_segments, { text = " " .. state.git_branch, hl = "DashboardPillGit" })
      end
      table.insert(pill_segments, { text = "   │   ", hl = "DashboardPillBorder" })
      table.insert(pill_segments, { text = "󰥔  " .. clock_str, hl = "DashboardPillClock" })
      table.insert(pill_segments, { text = " ─╮", hl = "DashboardPillBorder" })

      local pill_plain = ""
      for _, seg in ipairs(pill_segments) do
        pill_plain = pill_plain .. seg.text
      end
      local pill_centered, pill_pad = center_line(pill_plain, win_width)
      table.insert(lines, pill_centered)
      local pill_r = #lines - 1
      meta.pill_row = {
        row = pill_r,
        pad = pill_pad,
        segments = pill_segments,
      }

      table.insert(lines, "")

      -- 3. Framed Card Top Border
      local top_title = " ✦  QUICK ACTIONS  ✦ "
      local side_len = math.floor((card_width - 2 - fn.strdisplaywidth(top_title)) / 2)
      local right_len = card_width - 2 - fn.strdisplaywidth(top_title) - side_len
      local top_border = card_indent
        .. "╭"
        .. string.rep("─", side_len)
        .. top_title
        .. string.rep("─", right_len)
        .. "╮"
      table.insert(lines, top_border)
      table.insert(meta.section_rows, {
        row = #lines - 1,
        pad = card_pad,
        left_bytes = #("╭" .. string.rep("─", side_len)),
        title_bytes = #top_title,
        total_bytes = #top_border - card_pad,
      })

      local empty_card_row = card_indent .. "│" .. string.rep(" ", card_width - 2) .. "│"
      table.insert(lines, empty_card_row)
      table.insert(meta.box_rows, #lines - 1)

      -- 4. Action Rows (Single-column classic layout)
      for idx, act in ipairs(actions) do
        local row_idx = #lines
        table.insert(lines, empty_card_row)
        local item_entry = {
          index = #state.interactive_lines + 1,
          row = row_idx,
          kind = "action",
          data = act,
          reveal_step = idx,
        }
        table.insert(state.interactive_lines, item_entry)
        state.line_to_item[row_idx] = item_entry
        table.insert(meta.action_rows, item_entry)
      end

      table.insert(lines, empty_card_row)
      table.insert(meta.box_rows, #lines - 1)

      -- 5. Recent Workspace Files Section
      if #recents > 0 then
        local rec_title = " 󰋚  RECENT WORKSPACE FILES "
        local r_side = math.floor((card_width - 2 - fn.strdisplaywidth(rec_title)) / 2)
        local r_right = card_width - 2 - fn.strdisplaywidth(rec_title) - r_side
        local mid_border = card_indent
          .. "├"
          .. string.rep("─", r_side)
          .. rec_title
          .. string.rep("─", r_right)
          .. "┤"
        table.insert(lines, mid_border)
        table.insert(meta.section_rows, {
          row = #lines - 1,
          pad = card_pad,
          left_bytes = #("├" .. string.rep("─", r_side)),
          title_bytes = #rec_title,
          total_bytes = #mid_border - card_pad,
        })

        table.insert(lines, empty_card_row)
        table.insert(meta.box_rows, #lines - 1)

        for idx, rec in ipairs(recents) do
          local row_idx = #lines
          table.insert(lines, empty_card_row)
          local item_entry = {
            index = #state.interactive_lines + 1,
            row = row_idx,
            kind = "recent",
            data = rec,
            reveal_step = #actions + idx,
            action = function()
              vim.cmd("edit " .. fn.fnameescape(rec.abs))
            end,
          }
          table.insert(state.interactive_lines, item_entry)
          state.line_to_item[row_idx] = item_entry
          table.insert(meta.recent_rows, item_entry)
        end

        table.insert(lines, empty_card_row)
        table.insert(meta.box_rows, #lines - 1)
      end

      -- 6. Card Bottom Border
      local bot_border = card_indent .. "╰" .. string.rep("─", card_width - 2) .. "╯"
      table.insert(lines, bot_border)
      table.insert(meta.box_rows, #lines - 1)

      -- Fill remaining rows down to win_height for a clean canvas
      while #lines < win_height do
        table.insert(lines, "")
      end

      meta.base_lines = lines
      state.layout = meta

      if state.selected_idx > #state.interactive_lines then
        state.selected_idx = 1
      end
    end

    local function format_interactive_item(item, is_selected, reveal_progress)
      local meta = state.layout
      local card_width = meta.card_width
      local card_pad = meta.card_pad
      local card_indent = string.rep(" ", card_pad)
      local inner_width = card_width - 2

      local pointer = is_selected and "  ❯  " or "     "
      local icon_str, label_str, sub_str, key_str, icon_hl

      if item.kind == "action" then
        local act = item.data
        icon_str = pad_right(act.icon, 3)
        icon_hl = act.icon_hl
        label_str = pad_right(act.label, 16)
        sub_str = pad_right(act.desc, 31)
        key_str = is_selected and (" " .. act.key .. " ") or ("[" .. act.key .. "]")
      else
        local rec = item.data
        icon_str = pad_right(rec.icon, 3)
        icon_hl = rec.icon_hl
        label_str = pad_right(rec.filename, 22)
        sub_str = pad_right(rec.short_path, 25)
        key_str = is_selected and (" " .. rec.key .. " ") or ("[" .. rec.key .. "]")
      end

      if reveal_progress < 1.0 then
        local visible_chars = math.floor(fn.strchars(label_str) * reveal_progress)
        local revealed = fn.strcharpart(label_str, 0, visible_chars)
        local rem = fn.strchars(label_str) - visible_chars
        local scrambled = ""
        for i = 1, rem do
          local ch = fn.strcharpart(label_str, visible_chars + i - 1, 1)
          if ch == " " then
            scrambled = scrambled .. " "
          else
            scrambled = scrambled .. scramble_glyphs[((state.tick + i) % #scramble_glyphs) + 1]
          end
        end
        label_str = revealed .. scrambled
      end

      local content = pointer .. icon_str .. label_str .. sub_str .. key_str
      content = pad_right(content, inner_width)
      local full_line = card_indent .. "│" .. content .. "│"

      local b_left_border = card_pad
      local b_pointer = b_left_border + #"│"
      local b_icon = b_pointer + #pointer
      local b_label = b_icon + #icon_str
      local b_sub = b_label + #label_str
      local b_key = b_sub + #sub_str
      local b_key_end = b_key + #key_str
      local b_right_border = #full_line - #"│"

      local hls = {
        { b_left_border, b_pointer, is_selected and "DashboardBoxBorderActive" or "DashboardBoxBorder" },
        { b_pointer, b_icon, "DashboardPointer" },
        { b_icon, b_label, icon_hl },
        { b_label, b_sub, is_selected and "DashboardItemActive" or "DashboardItemNormal" },
        { b_sub, b_key, is_selected and "DashboardRecentPathActive" or "DashboardRecentPath" },
        {
          b_key,
          b_key_end,
          is_selected and "DashboardKeyBadgeActive" or "DashboardKeyBadge",
        },
        { b_right_border, #full_line, is_selected and "DashboardBoxBorderActive" or "DashboardBoxBorder" },
      }

      return full_line, hls
    end

    local function render_frame()
      if not state.buf or not api.nvim_buf_is_valid(state.buf) then
        return false
      end
      if not state.win or not api.nvim_win_is_valid(state.win) then
        return false
      end
      if api.nvim_win_get_buf(state.win) ~= state.buf then
        return false
      end

      if not state.layout then
        build_layout()
      end
      local meta = state.layout
      if not meta then
        return false
      end

      local lines = vim.deepcopy(meta.base_lines)
      local item_highlights = {}

      local intro_ticks = 18
      local is_intro = state.phase == "intro" and state.tick <= intro_ticks

      -- 1. Build Logo Lines
      for r_idx, cells in ipairs(logo_cells) do
        local buf_row = meta.logo_rows[r_idx]
        if is_intro then
          local progress = (state.tick - (r_idx - 1) * 1.4) / 10.0
          local row_chars = {}
          for c_idx, cell in ipairs(cells) do
            local col_prog = progress - (c_idx / #cells) * 0.45
            if cell.char == " " then
              table.insert(row_chars, " ")
            elseif col_prog <= 0 then
              table.insert(row_chars, " ")
            elseif col_prog < 0.65 then
              local g = scramble_glyphs[((state.tick + r_idx + c_idx) % #scramble_glyphs) + 1]
              table.insert(row_chars, g)
            else
              table.insert(row_chars, cell.char)
            end
          end
          lines[buf_row + 1] = string.rep(" ", meta.logo_pad) .. table.concat(row_chars)
        end
      end

      -- 2. Build Interactive Action & Recent Rows
      for idx, item in ipairs(state.interactive_lines) do
        local is_sel = (idx == state.selected_idx)
        local rev_prog = 1.0
        if is_intro then
          rev_prog = math.max(0.0, math.min(1.0, (state.tick - item.reveal_step * 0.9) / 8.0))
        end
        local line_str, hls = format_interactive_item(item, is_sel, rev_prog)
        lines[item.row + 1] = line_str
        item_highlights[item.row] = hls
      end

      local current_lines = api.nvim_buf_get_lines(state.buf, 0, -1, false)
      local needs_text_update = (#current_lines ~= #lines)
      if not needs_text_update then
        for i = 1, #lines do
          if current_lines[i] ~= lines[i] then
            needs_text_update = true
            break
          end
        end
      end

      if needs_text_update then
        vim.bo[state.buf].modifiable = true
        api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
        vim.bo[state.buf].modifiable = false
      end

      api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)

      -- Highlight Logo with Diagonal Flowing Aurora Wave + Twinkling Stars
      local wave_phase = state.tick * 0.038
      for r_idx, _ in ipairs(logo_final) do
        local buf_row = meta.logo_rows[r_idx]
        local line_str = lines[buf_row + 1]
        local row_cells = split_utf8_cells(line_str)
        for _, cell in ipairs(row_cells) do
          if cell.char ~= " " then
            if cell.char == "✦" or cell.char == "·" then
              local star_phase = math.sin(state.tick * 0.14 + r_idx * 1.7 + cell.col_idx * 0.5)
              local star_hl = "DashboardStarMid"
              if star_phase > 0.55 then
                star_hl = "DashboardStarBright"
              elseif star_phase < -0.25 then
                star_hl = "DashboardStarDim"
              end
              api.nvim_buf_set_extmark(state.buf, ns, buf_row, cell.byte_start, {
                end_col = cell.byte_end,
                hl_group = star_hl,
              })
            else
              local t = (cell.col_idx * 0.015 + r_idx * 0.065 - wave_phase) % 1.0
              local g_idx = math.floor(t * NUM_GRADIENT_STEPS) + 1
              g_idx = math.max(1, math.min(NUM_GRADIENT_STEPS, g_idx))
              api.nvim_buf_set_extmark(state.buf, ns, buf_row, cell.byte_start, {
                end_col = cell.byte_end,
                hl_group = gradient_hls[g_idx],
              })
            end
          end
        end
      end

      -- Highlight Context Pill Row
      if meta.pill_row then
        local pr = meta.pill_row
        local col_offset = pr.pad
        for _, seg in ipairs(pr.segments) do
          local blen = #seg.text
          api.nvim_buf_set_extmark(state.buf, ns, pr.row, col_offset, {
            end_col = col_offset + blen,
            hl_group = seg.hl,
          })
          col_offset = col_offset + blen
        end
      end

      -- Highlight Section Headers
      for _, sec in ipairs(meta.section_rows) do
        local s_start = sec.pad
        local t_start = s_start + sec.left_bytes
        local t_end = t_start + sec.title_bytes
        local s_end = s_start + sec.total_bytes
        api.nvim_buf_set_extmark(state.buf, ns, sec.row, s_start, {
          end_col = t_start,
          hl_group = "DashboardBoxBorder",
        })
        local pulse_idx = (math.floor(state.tick * 0.5) % NUM_GRADIENT_STEPS) + 1
        api.nvim_buf_set_extmark(state.buf, ns, sec.row, t_start, {
          end_col = t_end,
          hl_group = gradient_hls[pulse_idx],
        })
        api.nvim_buf_set_extmark(state.buf, ns, sec.row, t_end, {
          end_col = s_end,
          hl_group = "DashboardBoxBorder",
        })
      end

      -- Highlight Box Spacer & Bottom Borders
      for _, brow in ipairs(meta.box_rows) do
        local bline = lines[brow + 1] or ""
        if #bline > meta.card_pad then
          api.nvim_buf_set_extmark(state.buf, ns, brow, meta.card_pad, {
            end_col = #bline,
            hl_group = "DashboardBoxBorder",
          })
        end
      end

      -- Highlight Interactive Rows
      for row_idx, hls in pairs(item_highlights) do
        for _, h in ipairs(hls) do
          api.nvim_buf_set_extmark(state.buf, ns, row_idx, h[1], {
            end_col = h[2],
            hl_group = h[3],
          })
        end
      end

      -- Position cursor on active item
      local active_item = state.interactive_lines[state.selected_idx]
      if active_item and api.nvim_get_current_win() == state.win then
        local target_row = active_item.row + 1
        local target_col = meta.card_pad + #"│  ❯  "
        local cur = api.nvim_win_get_cursor(state.win)
        if cur[1] ~= target_row or cur[2] ~= target_col then
          pcall(api.nvim_win_set_cursor, state.win, { target_row, target_col })
        end
      end

      return true
    end

    local function stop_animation()
      if state.timer then
        if not state.timer:is_closing() then
          state.timer:stop()
          state.timer:close()
        end
        state.timer = nil
      end
    end

    local function start_animation(with_intro)
      stop_animation()
      if with_intro then
        state.tick = 0
        state.phase = "intro"
      else
        state.phase = "ambient"
      end

      local timer = uv.new_timer()
      state.timer = timer

      local interval = with_intro and 22 or 45
      timer:start(
        0,
        interval,
        vim.schedule_wrap(function()
          if not state.timer then
            return
          end
          state.tick = state.tick + 1

          if state.phase == "intro" and state.tick > 18 then
            state.phase = "ambient"
            if state.timer and not state.timer:is_closing() then
              state.timer:stop()
              state.timer:start(
                45,
                45,
                vim.schedule_wrap(function()
                  if not state.timer then
                    return
                  end
                  state.tick = state.tick + 1
                  if not render_frame() then
                    stop_animation()
                  end
                end)
              )
            end
          end

          if not render_frame() then
            stop_animation()
          end
        end)
      )
    end

    local function move_selection(delta)
      local count = #state.interactive_lines
      if count == 0 then
        return
      end
      state.selected_idx = ((state.selected_idx - 1 + delta) % count) + 1
      render_frame()
    end

    local function trigger_selected()
      local item = state.interactive_lines[state.selected_idx]
      if not item then
        return
      end
      stop_animation()
      if item.kind == "action" and item.data and item.data.action then
        item.data.action()
      elseif item.action then
        item.action()
      end
    end

    local function open_dashboard()
      setup_highlights()
      detect_git_branch()

      local win = api.nvim_get_current_win()
      local buf = state.buf
      if not buf or not api.nvim_buf_is_valid(buf) then
        buf = api.nvim_create_buf(false, true)
        state.buf = buf
      end

      state.win = win
      api.nvim_win_set_buf(win, buf)

      vim.bo[buf].buftype = "nofile"
      vim.bo[buf].bufhidden = "wipe"
      vim.bo[buf].swapfile = false
      vim.bo[buf].filetype = "dashboard"
      vim.bo[buf].modifiable = false
      vim.bo[buf].buflisted = false

      vim.wo[win].number = false
      vim.wo[win].relativenumber = false
      vim.wo[win].cursorline = false
      vim.wo[win].cursorcolumn = false
      vim.wo[win].signcolumn = "no"
      vim.wo[win].foldcolumn = "0"
      vim.wo[win].spell = false
      vim.wo[win].list = false
      vim.wo[win].wrap = false
      vim.wo[win].fillchars = "eob: "

      state.selected_idx = 1
      build_layout()

      local kopts = { buffer = buf, noremap = true, silent = true, nowait = true }
      vim.keymap.set("n", "j", function()
        move_selection(1)
      end, kopts)
      vim.keymap.set("n", "<Down>", function()
        move_selection(1)
      end, kopts)
      vim.keymap.set("n", "<Tab>", function()
        move_selection(1)
      end, kopts)
      vim.keymap.set("n", "k", function()
        move_selection(-1)
      end, kopts)
      vim.keymap.set("n", "<Up>", function()
        move_selection(-1)
      end, kopts)
      vim.keymap.set("n", "<S-Tab>", function()
        move_selection(-1)
      end, kopts)
      vim.keymap.set("n", "<CR>", trigger_selected, kopts)
      vim.keymap.set("n", "<2-LeftMouse>", trigger_selected, kopts)

      for idx, item in ipairs(state.interactive_lines) do
        local key = item.data and item.data.key
        if key then
          vim.keymap.set("n", key, function()
            state.selected_idx = idx
            render_frame()
            trigger_selected()
          end, kopts)
        end
      end

      local group = api.nvim_create_augroup("ModernDashboardLifecycle", { clear = true })
      api.nvim_create_autocmd("CursorMoved", {
        group = group,
        buffer = buf,
        callback = function()
          if not state.win or not api.nvim_win_is_valid(state.win) then
            return
          end
          local cur_row = api.nvim_win_get_cursor(state.win)[1] - 1
          local matched = state.line_to_item[cur_row]
          if matched and matched.index ~= state.selected_idx then
            state.selected_idx = matched.index
            render_frame()
          end
        end,
      })

      api.nvim_create_autocmd("VimResized", {
        group = group,
        buffer = buf,
        callback = function()
          build_layout()
          render_frame()
        end,
      })

      api.nvim_create_autocmd({ "BufLeave", "BufWipeout", "BufUnload", "VimLeavePre" }, {
        group = group,
        buffer = buf,
        callback = function()
          stop_animation()
        end,
      })

      api.nvim_create_autocmd("BufEnter", {
        group = group,
        buffer = buf,
        callback = function()
          state.win = api.nvim_get_current_win()
          if not state.timer then
            start_animation(false)
          end
        end,
      })

      start_animation(true)
    end

    api.nvim_create_autocmd("ColorScheme", {
      callback = setup_highlights,
    })

    api.nvim_create_user_command("Dashboard", open_dashboard, { desc = "Open Modern Animated Dashboard" })
    vim.keymap.set("n", "<leader>;", open_dashboard, { desc = "Open Dashboard" })

    if fn.argc() == 0 then
      api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = function()
          if fn.argc() == 0 and api.nvim_buf_get_name(0) == "" and vim.bo.filetype == "" then
            open_dashboard()
          end
        end,
      })
    end
  end,
}
