return {
  -- 1. Smooth comet/trail cursor animation on jumps
  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    opts = {
      stiffness = 0.8,
      trailing_stiffness = 0.55,
      distance_stop_animating = 0.5,
      smear_between_buffers = true,
      smear_between_neighbor_lines = true,
      smear_insert_mode = false,
      filetypes_disabled = { "dashboard", "manual" },
    },
  },

  -- 2. Smooth scrolling for <C-d>, <C-u>, <C-f>, <C-b>, zz, etc.
  {
    "karb94/neoscroll.nvim",
    event = "VeryLazy",
    opts = {
      mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "<C-y>", "<C-e>", "zt", "zz", "zb" },
      hide_cursor = true,
      stop_eof = true,
      respect_scrolloff = false,
      cursor_scrolls_alone = true,
      easing = "quadratic",
      duration_multiplier = 0.8,
    },
  },

  -- 3. Animated active indent scope guide
  {
    "echasnovski/mini.indentscope",
    version = false,
    event = { "BufReadPre", "BufNewFile" },
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = {
          "help",
          "dashboard",
          "neo-tree",
          "Trouble",
          "trouble",
          "lazy",
          "mason",
          "notify",
          "toggleterm",
          "qf",
        },
        callback = function()
          vim.b.miniindentscope_disable = true
        end,
      })
    end,
    config = function()
      local indentscope = require("mini.indentscope")
      indentscope.setup({
        symbol = "│",
        options = { try_as_border = true },
        draw = {
          delay = 50,
          animation = indentscope.gen_animation.quadratic({ easing = "out", duration = 120, unit = "total" }),
        },
      })
      vim.api.nvim_set_hl(0, "MiniIndentscopeSymbol", { fg = "#cba6f7" })
    end,
  },

  -- 4. Window resize, open, and close transitions (scroll & cursor disabled to avoid conflicts)
  {
    "echasnovski/mini.animate",
    version = false,
    event = "VeryLazy",
    config = function()
      local animate = require("mini.animate")
      animate.setup({
        cursor = { enable = false },
        scroll = { enable = false },
        resize = {
          enable = true,
          timing = animate.gen_timing.linear({ duration = 100, unit = "total" }),
        },
        open = {
          enable = true,
          timing = animate.gen_timing.linear({ duration = 120, unit = "total" }),
        },
        close = {
          enable = true,
          timing = animate.gen_timing.linear({ duration = 120, unit = "total" }),
        },
      })
    end,
  },

  -- 5. Undo / Redo & Paste flash
  {
    "tzachar/highlight-undo.nvim",
    event = "VeryLazy",
    opts = {
      duration = 250,
      undo = {
        hlgroup = "HighlightUndo",
        mode = "n",
        lhs = "u",
        map = "undo",
      },
      redo = {
        hlgroup = "HighlightRedo",
        mode = "n",
        lhs = "<C-r>",
        map = "redo",
      },
      highlight_for_count = true,
    },
    config = function(_, opts)
      vim.api.nvim_set_hl(0, "HighlightUndo", { bg = "#45475a", fg = "#f38ba8", bold = true })
      vim.api.nvim_set_hl(0, "HighlightRedo", { bg = "#45475a", fg = "#a6e3a1", bold = true })
      require("highlight-undo").setup(opts)
    end,
  },

  -- 6. Cellular Automaton break-time animations (<leader>fml / fmg / fms)
  {
    "Eandrju/cellular-automaton.nvim",
    cmd = "CellularAutomaton",
    keys = (function()
      local function run_ca(anim)
        return function()
          local ok = pcall(vim.treesitter.get_parser, 0)
          if not ok then
            vim.notify("Open a code file first — CellularAutomaton needs a Treesitter parser.", vim.log.levels.INFO)
            return
          end
          vim.cmd("CellularAutomaton " .. anim)
        end
      end
      return {
        { "<leader>fml", run_ca("make_it_rain"), desc = "Make it rain (falling sand)" },
        { "<leader>fmg", run_ca("game_of_life"), desc = "Conway's Game of Life" },
        { "<leader>fms", run_ca("scramble"), desc = "Scramble buffer" },
      }
    end)(),
  },

  -- 7. Native Lua: Yank flash + Cursor Beacon Pulse + Typing Sparkles
  {
    "catppuccin/nvim",
    optional = true,
    init = function()
      local uv = vim.uv or vim.loop
      local api = vim.api

      local disabled_fts = {
        dashboard = true,
        manual = true,
        ["neo-tree"] = true,
        TelescopePrompt = true,
        lazy = true,
        mason = true,
        Trouble = true,
        trouble = true,
        qf = true,
        help = true,
      }

      local function set_fx_highlights()
        api.nvim_set_hl(0, "AnimYankFlash", { bg = "#585b70", fg = "#f5c2e7", bold = true })
        api.nvim_set_hl(0, "AnimBeacon1", { bg = "#cba6f7", fg = "#1e1e2e", bold = true })
        api.nvim_set_hl(0, "AnimBeacon2", { bg = "#89b4fa", fg = "#1e1e2e", bold = true })
        api.nvim_set_hl(0, "AnimBeacon3", { bg = "#45475a", fg = "#cdd6f4" })
        api.nvim_set_hl(0, "AnimSparkle1", { fg = "#f5c2e7", bold = true })
        api.nvim_set_hl(0, "AnimSparkle2", { fg = "#cba6f7", bold = true })
        api.nvim_set_hl(0, "AnimSparkle3", { fg = "#89b4fa" })
        api.nvim_set_hl(0, "AnimSparkle4", { fg = "#94e2d5" })
        api.nvim_set_hl(0, "AnimSparkle5", { fg = "#f9e2af" })
      end
      set_fx_highlights()
      api.nvim_create_autocmd("ColorScheme", { callback = set_fx_highlights })

      -- A. Yank Flash
      api.nvim_create_autocmd("TextYankPost", {
        group = api.nvim_create_augroup("AnimYankGroup", { clear = true }),
        callback = function()
          (vim.hl or vim.highlight).on_yank({ higroup = "AnimYankFlash", timeout = 180 })
        end,
      })

      -- B. Cursor Beacon / Pulse on big jumps (>= 8 lines) or window switches
      local beacon_ns = api.nvim_create_namespace("AnimCursorBeacon")
      local beacon_hls = { "AnimBeacon1", "AnimBeacon2", "AnimBeacon3" }
      local last_win_pos = {}

      local function pulse_cursor(buf, row, col)
        if not api.nvim_buf_is_valid(buf) or disabled_fts[vim.bo[buf].filetype] then
          return
        end
        local line = api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
        local end_col = math.min(#line, col + 1)
        if col >= #line then
          return
        end

        local step = 1
        local timer = uv.new_timer()
        local id
        timer:start(
          0,
          55,
          vim.schedule_wrap(function()
            if not api.nvim_buf_is_valid(buf) then
              if not timer:is_closing() then
                timer:stop()
                timer:close()
              end
              return
            end
            if id then
              pcall(api.nvim_buf_del_extmark, buf, beacon_ns, id)
              id = nil
            end
            if step > #beacon_hls then
              if not timer:is_closing() then
                timer:stop()
                timer:close()
              end
              return
            end
            local cur_line = api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
            if cur_line and col < #cur_line then
              id = api.nvim_buf_set_extmark(buf, beacon_ns, row, col, {
                end_col = math.min(#cur_line, end_col),
                hl_group = beacon_hls[step],
                priority = 200,
              })
            end
            step = step + 1
          end)
        )
      end

      local beacon_group = api.nvim_create_augroup("AnimCursorBeaconGroup", { clear = true })
      api.nvim_create_autocmd("CursorMoved", {
        group = beacon_group,
        callback = function()
          local win = api.nvim_get_current_win()
          local buf = api.nvim_get_current_buf()
          if disabled_fts[vim.bo[buf].filetype] then
            return
          end
          local pos = api.nvim_win_get_cursor(win)
          local prev = last_win_pos[win]
          last_win_pos[win] = { buf = buf, row = pos[1] - 1, col = pos[2] }
          if prev and prev.buf == buf and math.abs((pos[1] - 1) - prev.row) >= 8 then
            pulse_cursor(buf, pos[1] - 1, pos[2])
          end
        end,
      })
      api.nvim_create_autocmd("WinEnter", {
        group = beacon_group,
        callback = function()
          local win = api.nvim_get_current_win()
          local buf = api.nvim_get_current_buf()
          local pos = api.nvim_win_get_cursor(win)
          last_win_pos[win] = { buf = buf, row = pos[1] - 1, col = pos[2] }
          vim.schedule(function()
            if api.nvim_win_is_valid(win) and api.nvim_get_current_win() == win then
              local p = api.nvim_win_get_cursor(win)
              pulse_cursor(api.nvim_get_current_buf(), p[1] - 1, p[2])
            end
          end)
        end,
      })

      -- C. Typing Particle / Sparkle Effects in Insert Mode
      local sparkles_enabled = true
      local sparkle_ns = api.nvim_create_namespace("AnimTypingSparkles")
      local sparkle_glyphs = { "✦", "✧", "·", "˚" }
      local sparkle_hls = { "AnimSparkle1", "AnimSparkle2", "AnimSparkle3", "AnimSparkle4", "AnimSparkle5" }

      api.nvim_create_user_command("ToggleTypingSparkles", function()
        sparkles_enabled = not sparkles_enabled
      end, { desc = "Toggle typing sparkle particles" })

      api.nvim_create_autocmd("TextChangedI", {
        group = api.nvim_create_augroup("AnimTypingSparklesGroup", { clear = true }),
        callback = function()
          if not sparkles_enabled then
            return
          end
          local buf = api.nvim_get_current_buf()
          if disabled_fts[vim.bo[buf].filetype] then
            return
          end
          local win = api.nvim_get_current_win()
          local pos = api.nvim_win_get_cursor(win)
          local row = pos[1] - 1
          local line_count = api.nvim_buf_line_count(buf)

          local ids = {}
          for i = 1, 2 do
            local target_row = row + (i == 2 and row + 1 < line_count and 1 or 0)
            local glyph = sparkle_glyphs[math.random(#sparkle_glyphs)]
            local hl = sparkle_hls[math.random(#sparkle_hls)]
            local pad = string.rep(" ", math.random(0, 3))
            local ok, eid = pcall(api.nvim_buf_set_extmark, buf, sparkle_ns, target_row, 0, {
              virt_text = { { pad .. glyph, hl } },
              virt_text_pos = "eol",
              priority = 50,
            })
            if ok and eid then
              table.insert(ids, eid)
            end
          end

          vim.defer_fn(function()
            if api.nvim_buf_is_valid(buf) then
              for _, eid in ipairs(ids) do
                pcall(api.nvim_buf_del_extmark, buf, sparkle_ns, eid)
              end
            end
          end, 220)
        end,
      })
    end,
  },
}
