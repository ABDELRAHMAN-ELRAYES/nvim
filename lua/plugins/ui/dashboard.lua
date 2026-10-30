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
      sim = nil,
      preset_idx = 1,
    }

    ---------------------------------------------------------------------------
    -- ASCII-SHARKS MATH, SPECIES & GEOMETRY (from stackedlol/ascii-sharks)
    ---------------------------------------------------------------------------
    local TAU = math.pi * 2
    local SHARK_NODES = 20

    local function clamp(v, lo, hi)
      if v < lo then
        return lo
      end
      if v > hi then
        return hi
      end
      return v
    end

    local function rand(lo, hi)
      return lo + math.random() * (hi - lo)
    end

    local function randInt(lo, hi)
      return lo + math.floor(math.random() * (hi - lo + 1))
    end

    local function smoothstep(e0, e1, x)
      local t = clamp((x - e0) / (e1 - e0), 0, 1)
      return t * t * (3 - 2 * t)
    end

    local function angleDiff(a, b)
      local d = (b - a) % TAU
      if d > math.pi then
        d = d - TAU
      end
      if d < -math.pi then
        d = d + TAU
      end
      return d
    end

    local bit = bit or require("bit")
    local bxor, band, rshift, lshift = bit.bxor, bit.band, bit.rshift, bit.lshift

    local function imul32(a, b)
      local ah = band(rshift(a, 16), 0xffff)
      local al = band(a, 0xffff)
      local bh = band(rshift(b, 16), 0xffff)
      local bl = band(b, 0xffff)
      return bit.tobit(al * bl + lshift(band(ah * bl + al * bh, 0xffff), 16))
    end

    local function hash3(x, y, z)
      local h = bxor(
        imul32(math.floor(x), 374761393),
        bxor(imul32(math.floor(y), 668265263), imul32(math.floor(z), 1442695041))
      )
      h = imul32(bxor(h, rshift(h, 13)), 1274126177)
      h = bxor(h, rshift(h, 16))
      if h < 0 then
        h = h + 4294967296
      end
      return h / 4294967296
    end

    -- Divergence-free ocean current field from ascii-sharks/src/math.ts
    local function ocean_current(x, y, t)
      local s = 0.0028
      local vx = math.sin(y * s + t * 0.22) * 10 + math.cos((x + y) * s * 0.7 - t * 0.14) * 6
      local vy = -math.cos(x * s - t * 0.18) * 6 + math.sin((x - y) * s * 0.7 + t * 0.16) * 4
      return vx, vy
    end

    local function inTriangle(px, py, ax, ay, bx, by, cx, cy)
      local d1 = (px - bx) * (ay - by) - (ax - bx) * (py - by)
      local d2 = (px - cx) * (by - cy) - (bx - cx) * (py - cy)
      local d3 = (px - ax) * (cy - ay) - (cx - ax) * (py - ay)
      local neg = d1 < 0 or d2 < 0 or d3 < 0
      local pos = d1 > 0 or d2 > 0 or d3 > 0
      return not (neg and pos)
    end

    -- Fish species behavioral presets from ascii-sharks/src/species.ts
    local SPECIES = {
      {
        name = "sardine",
        speed = { 30, 44 },
        schoolSize = { 16, 26 },
        spacing = 12,
        align = 1.6,
        cohesion = 1.25,
        jitter = 14,
        mill = 0.55,
        verticalDrag = 0.9,
      },
      {
        name = "anchovy",
        speed = { 34, 52 },
        schoolSize = { 18, 28 },
        spacing = 10,
        align = 1.75,
        cohesion = 1.4,
        jitter = 22,
        mill = 0.85,
        verticalDrag = 0.75,
      },
      {
        name = "silverside",
        speed = { 28, 42 },
        schoolSize = { 12, 20 },
        spacing = 14,
        align = 1.5,
        cohesion = 0.95,
        jitter = 16,
        mill = 0.25,
        verticalDrag = 1.15,
      },
      {
        name = "mackerel",
        speed = { 42, 60 },
        schoolSize = { 8, 15 },
        spacing = 18,
        align = 1.9,
        cohesion = 0.85,
        jitter = 12,
        mill = 0.2,
        verticalDrag = 0.85,
      },
      {
        name = "goby",
        speed = { 18, 28 },
        schoolSize = { 6, 12 },
        spacing = 16,
        align = 0.7,
        cohesion = 0.55,
        jitter = 26,
        mill = 0,
        verticalDrag = 1.2,
      },
    }

    local function classicHalfWidth(s)
      if s < 0.13 then
        return 0.09 * (math.sin(((s / 0.13) * math.pi) / 2) ^ 0.95)
      end
      if s < 0.3 then
        return 0.09 + 0.016 * smoothstep(0.13, 0.3, s)
      end
      if s < 0.84 then
        return 0.019 + 0.087 * ((1 - (s - 0.3) / 0.54) ^ 1.25)
      end
      local k = (s - 0.84) / 0.16
      return 0.019 * (1 - k) + 0.012 * math.sin(k * math.pi)
    end

    -- All 8 shark species from ascii-sharks/src/renderer.ts
    local SHAPES = {
      classic = {
        halfWidth = classicHalfWidth,
        pectoral = { 0.15, 0.43, 0.55, 0.26 },
        falcate = true,
        pelvic = { 0.57, 0.65, 0.69, 0.085 },
        caudal = 0.085,
        dorsal = { 0.33, 0.47 },
        secondDorsal = { 0.71, 0.76 },
        eye = { 0.1, 0.14 },
        gills = { 0.19, 0.29 },
        tint = "slate",
      },
      hammerhead = {
        halfWidth = function(s)
          if s < 0.06 then
            return 0.045
          end
          if s < 0.3 then
            return 0.045 + 0.061 * smoothstep(0.06, 0.3, s)
          end
          return classicHalfWidth(s) * 0.92
        end,
        head = { span = 0.17, sweep = 0.035, depth = 0.09, notch = 0 },
        pectoral = { 0.17, 0.4, 0.5, 0.22 },
        falcate = true,
        pelvic = { 0.56, 0.63, 0.67, 0.075 },
        caudal = 0.11,
        dorsal = { 0.28, 0.44 },
        secondDorsal = { 0.7, 0.74 },
        eye = nil,
        gills = { 0.16, 0.26 },
        tint = "slate",
      },
      greathammer = {
        halfWidth = function(s)
          if s < 0.05 then
            return 0.04
          end
          if s < 0.3 then
            return 0.04 + 0.07 * smoothstep(0.05, 0.3, s)
          end
          return classicHalfWidth(s) * 0.95
        end,
        head = { span = 0.21, sweep = 0.006, depth = 0.085, notch = 0.014 },
        pectoral = { 0.16, 0.38, 0.49, 0.24 },
        falcate = true,
        pelvic = { 0.55, 0.62, 0.67, 0.085 },
        caudal = 0.13,
        dorsal = { 0.24, 0.45 },
        secondDorsal = { 0.68, 0.74 },
        eye = nil,
        gills = { 0.15, 0.25 },
        tint = "slate",
      },
      zebra = {
        halfWidth = function(s)
          if s < 0.1 then
            return 0.075 * (math.sin(((s / 0.1) * math.pi) / 2) ^ 0.7)
          end
          if s < 0.28 then
            return 0.075 + 0.025 * smoothstep(0.1, 0.28, s)
          end
          if s < 0.55 then
            return 0.022 + 0.078 * ((1 - (s - 0.28) / 0.27) ^ 1.1)
          end
          local k = (s - 0.55) / 0.45
          return 0.022 * (1 - k * k) + 0.012 * math.sin(k * math.pi)
        end,
        pectoral = { 0.12, 0.3, 0.36, 0.19 },
        falcate = false,
        pelvic = { 0.42, 0.48, 0.51, 0.065 },
        caudal = 0,
        dorsal = { 0.36, 0.44 },
        secondDorsal = { 0.49, 0.53 },
        eye = { 0.06, 0.09 },
        gills = { 0.13, 0.2 },
        tint = "warm",
      },
      tiger = {
        halfWidth = function(s)
          if s < 0.13 then
            return 0.1 * (math.sin(((s / 0.13) * math.pi) / 2) ^ 0.45)
          end
          if s < 0.3 then
            return 0.1 + 0.014 * smoothstep(0.13, 0.3, s)
          end
          if s < 0.84 then
            return 0.019 + 0.095 * ((1 - (s - 0.3) / 0.54) ^ 1.2)
          end
          local k = (s - 0.84) / 0.16
          return 0.019 * (1 - k) + 0.012 * math.sin(k * math.pi)
        end,
        pectoral = { 0.15, 0.42, 0.53, 0.25 },
        falcate = true,
        pelvic = { 0.57, 0.65, 0.69, 0.085 },
        caudal = 0.095,
        dorsal = { 0.33, 0.46 },
        secondDorsal = { 0.71, 0.75 },
        eye = { 0.08, 0.12 },
        gills = { 0.19, 0.28 },
        tint = "warm",
      },
      mako = {
        halfWidth = function(s)
          if s < 0.16 then
            return 0.078 * (math.sin(((s / 0.16) * math.pi) / 2) ^ 1.45)
          end
          if s < 0.32 then
            return 0.078 + 0.014 * smoothstep(0.16, 0.32, s)
          end
          if s < 0.84 then
            return 0.014 + 0.078 * ((1 - (s - 0.32) / 0.52) ^ 1.35)
          end
          local k = (s - 0.84) / 0.16
          return 0.014 * (1 - k) + 0.014 * math.sin(k * math.pi)
        end,
        pectoral = { 0.18, 0.36, 0.44, 0.21 },
        falcate = true,
        pelvic = { 0.58, 0.64, 0.68, 0.065 },
        caudal = 0.12,
        dorsal = { 0.34, 0.46 },
        secondDorsal = { 0.74, 0.77 },
        eye = { 0.11, 0.15 },
        gills = { 0.2, 0.29 },
        tint = "indigo",
      },
      thresher = {
        halfWidth = function(s)
          if s < 0.09 then
            return 0.076 * (math.sin(((s / 0.09) * math.pi) / 2) ^ 1.1)
          end
          if s < 0.24 then
            return 0.076 + 0.018 * smoothstep(0.09, 0.24, s)
          end
          if s < 0.52 then
            return 0.02 + 0.074 * ((1 - (s - 0.24) / 0.28) ^ 1.2)
          end
          local k = (s - 0.52) / 0.48
          return 0.02 * ((1 - k) ^ 1.5) + 0.006 * math.sin(k * math.pi)
        end,
        pectoral = { 0.11, 0.28, 0.39, 0.25 },
        falcate = true,
        pelvic = { 0.37, 0.43, 0.46, 0.07 },
        caudal = 0,
        dorsal = { 0.24, 0.33 },
        secondDorsal = { 0.46, 0.49 },
        eye = { 0.055, 0.085 },
        gills = { 0.12, 0.19 },
        tint = "violet",
      },
      nurse = {
        halfWidth = function(s)
          if s < 0.1 then
            return 0.095 * (math.sin(((s / 0.1) * math.pi) / 2) ^ 0.5)
          end
          if s < 0.28 then
            return 0.095 + 0.012 * smoothstep(0.1, 0.28, s)
          end
          if s < 0.72 then
            return 0.024 + 0.083 * ((1 - (s - 0.28) / 0.44) ^ 1.1)
          end
          local k = (s - 0.72) / 0.28
          return 0.024 * (1 - k * 0.85) + 0.008 * math.sin(k * math.pi)
        end,
        head = { span = 0.055, sweep = -0.025, depth = 0.018, notch = 0.02 },
        pectoral = { 0.13, 0.33, 0.38, 0.2 },
        falcate = false,
        pelvic = { 0.46, 0.54, 0.57, 0.085 },
        caudal = 0,
        dorsal = { 0.44, 0.54 },
        secondDorsal = { 0.62, 0.69 },
        eye = { 0.06, 0.085 },
        gills = { 0.14, 0.22 },
        tint = "bronze",
      },
    }

    local SKIN_RAMP = { ":", ";", "t", "%", "S", "X", "8", "#", "@" }
    local FIN_GLYPHS = { "%", ";", "t", "S", ":" }
    local RIDGE_GLYPHS = { "@", "8", "%" }
    local MARK_GLYPHS = { "#", "%", "@" }
    local EDGE_HEAVY = { ":", ";" }
    local EDGE_LIGHT = { ".", "'", ",", "`" }
    local SUBSAMPLES = { 0.25, 0.3, 0.75, 0.3, 0.25, 0.72, 0.75, 0.72 }

    local FLAG_BODY = 1
    local FLAG_EDGE = 2
    local FLAG_FIN = 3
    local FLAG_RIDGE = 4
    local FLAG_EYE = 5
    local FLAG_MARK = 6

    -- Default shark roster from ascii-sharks/src/world.ts + alternate presets (press `s` to cycle)
    local PRESETS = {
      {
        { kind = "greathammer", size = 1.0 },
        { kind = "zebra", size = 0.78 },
        { kind = "hammerhead", size = 0.86 },
        { kind = "classic", size = 0.74 },
      },
      {
        { kind = "tiger", size = 1.0 },
        { kind = "mako", size = 0.85 },
        { kind = "thresher", size = 0.92 },
        { kind = "nurse", size = 0.78 },
      },
      {
        { kind = "classic", size = 1.0 },
        { kind = "greathammer", size = 0.90 },
        { kind = "tiger", size = 0.84 },
        { kind = "zebra", size = 0.76 },
      },
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

    local function int_to_rgb(c, fallback)
      if not c or c < 0 then
        return fallback[1], fallback[2], fallback[3]
      end
      return band(rshift(c, 16), 0xff), band(rshift(c, 8), 0xff), band(c, 0xff)
    end

    local function rgb_to_hex(r, g, b)
      return string.format(
        "#%02x%02x%02x",
        clamp(math.floor(r + 0.5), 0, 255),
        clamp(math.floor(g + 0.5), 0, 255),
        clamp(math.floor(b + 0.5), 0, 255)
      )
    end

    local function mix_rgb(c1, c2, t)
      return {
        c1[1] + (c2[1] - c1[1]) * t,
        c1[2] + (c2[2] - c1[2]) * t,
        c1[3] + (c2[3] - c1[3]) * t,
      }
    end

    local function get_hl_rgb(name, attr, fallback)
      local ok, hl = pcall(api.nvim_get_hl, 0, { name = name, link = false })
      if ok and hl and hl[attr] then
        return { int_to_rgb(hl[attr], fallback) }
      end
      return fallback
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

      -- UI Accent Highlights (Catppuccin Mocha palette - kept 100% intact)
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

      -- Sharks Background Animation Highlights (matching ascii-sharks renderer.ts)
      local bg_rgb = get_hl_rgb("Normal", "bg", { 30, 30, 46 })
      local fg_rgb = get_hl_rgb("Normal", "fg", { 205, 214, 244 })
      local comment_rgb = get_hl_rgb("Comment", "fg", { 108, 112, 134 })
      local special_rgb = get_hl_rgb("Special", "fg", { 245, 194, 231 })
      local func_rgb = get_hl_rgb("Function", "fg", { 137, 180, 250 })
      local const_rgb = get_hl_rgb("Constant", "fg", { 250, 179, 135 })
      local type_rgb = get_hl_rgb("Type", "fg", { 249, 226, 175 })
      local str_rgb = get_hl_rgb("String", "fg", { 166, 227, 161 })
      local diag_info = get_hl_rgb("DiagnosticInfo", "fg", { 137, 220, 235 })
      local diag_warn = get_hl_rgb("DiagnosticWarn", "fg", { 249, 226, 175 })
      local diag_err = get_hl_rgb("DiagnosticError", "fg", { 243, 139, 168 })

      local bg_hex = rgb_to_hex(bg_rgb[1], bg_rgb[2], bg_rgb[3])
      local fg_hex = rgb_to_hex(fg_rgb[1], fg_rgb[2], fg_rgb[3])

      api.nvim_set_hl(0, "SharkWakeDim", { fg = rgb_to_hex(unpack(mix_rgb(bg_rgb, diag_info, 0.38))) })
      api.nvim_set_hl(0, "SharkWakeBright", { fg = rgb_to_hex(unpack(mix_rgb(bg_rgb, diag_info, 0.75))), bold = true })

      api.nvim_set_hl(0, "SharkHeatDim", { fg = rgb_to_hex(unpack(mix_rgb(bg_rgb, const_rgb, 0.75))) })
      api.nvim_set_hl(0, "SharkHeatBright", { fg = rgb_to_hex(unpack(diag_err)), bold = true })

      api.nvim_set_hl(0, "SharkFishDim", { fg = rgb_to_hex(unpack(mix_rgb(bg_rgb, comment_rgb, 0.65))) })
      api.nvim_set_hl(0, "SharkFishMid", { fg = rgb_to_hex(unpack(comment_rgb)) })
      api.nvim_set_hl(0, "SharkFishBright", { fg = fg_hex, bold = true })

      api.nvim_set_hl(0, "SharkEdgeDim", { fg = rgb_to_hex(unpack(mix_rgb(bg_rgb, comment_rgb, 0.55))) })
      api.nvim_set_hl(0, "SharkEdgeBright", { fg = rgb_to_hex(unpack(mix_rgb(comment_rgb, fg_rgb, 0.38))) })

      local tints = {
        slate = mix_rgb(fg_rgb, diag_info, 0.35),
        warm = mix_rgb(fg_rgb, type_rgb, 0.38),
        indigo = mix_rgb(fg_rgb, func_rgb, 0.42),
        violet = mix_rgb(fg_rgb, special_rgb, 0.38),
        bronze = mix_rgb(fg_rgb, const_rgb, 0.38),
      }
      for name, target_rgb in pairs(tints) do
        for lvl = 1, 8 do
          local t = 0.14 + ((lvl - 1) / 7) * 0.64
          local cell_bg = mix_rgb(bg_rgb, target_rgb, t)
          local cell_fg = lvl > 4 and bg_rgb or mix_rgb(bg_rgb, fg_rgb, 0.12)
          api.nvim_set_hl(0, "SharkSkin_" .. name .. "_" .. lvl, {
            bg = rgb_to_hex(cell_bg[1], cell_bg[2], cell_bg[3]),
            fg = rgb_to_hex(cell_fg[1], cell_fg[2], cell_fg[3]),
            bold = true,
          })
        end
      end

      local ridge_bg = mix_rgb(bg_rgb, fg_rgb, 0.85)
      local mark_bg = mix_rgb(bg_rgb, comment_rgb, 0.22)
      local mark_fg = mix_rgb(bg_rgb, comment_rgb, 0.65)
      api.nvim_set_hl(0, "SharkRidge", { bg = rgb_to_hex(unpack(ridge_bg)), fg = bg_hex, bold = true })
      api.nvim_set_hl(0, "SharkEye", { bg = bg_hex, fg = fg_hex, bold = true })
      api.nvim_set_hl(
        0,
        "SharkMark",
        { bg = rgb_to_hex(unpack(mark_bg)), fg = rgb_to_hex(unpack(mark_fg)), bold = true }
      )

      local theme_accents = {
        special_rgb,
        diag_err,
        const_rgb,
        diag_info,
        func_rgb,
        str_rgb,
        diag_warn,
        fg_rgb,
      }
      local mid_skin_bg = rgb_to_hex(unpack(mix_rgb(bg_rgb, fg_rgb, 0.32)))
      for i, col_rgb in ipairs(theme_accents) do
        api.nvim_set_hl(0, "SharkAccent_" .. i, {
          bg = mid_skin_bg,
          fg = rgb_to_hex(col_rgb[1], col_rgb[2], col_rgb[3]),
          bold = true,
        })
      end
    end

    ---------------------------------------------------------------------------
    -- FULL ASCII-SHARKS WORLD & RENDERER PORT (stackedlol/ascii-sharks)
    ---------------------------------------------------------------------------
    local BUCKET_SIZE = 70

    local function spawn_school(sim, from_edge)
      local species_idx = randInt(1, #SPECIES)
      local sp = SPECIES[species_idx]
      local count = randInt(sp.schoolSize[1], sp.schoolSize[2])
      local go_right = math.random() < 0.5
      local W, H = sim.W, sim.H
      local cx, cy
      if from_edge then
        cx = go_right and -20 or (W + 20)
        cy = rand(H * 0.08, H * 0.92)
      else
        -- Prefer spawning in the open left/right flanks or top/bottom waters
        local zone = math.random()
        if zone < 0.38 then
          cx = rand(W * 0.05, W * 0.28)
          cy = rand(H * 0.08, H * 0.92)
        elseif zone < 0.76 then
          cx = rand(W * 0.72, W * 0.95)
          cy = rand(H * 0.08, H * 0.92)
        else
          cx = rand(W * 0.15, W * 0.85)
          cy = math.random() < 0.5 and rand(H * 0.06, H * 0.22) or rand(H * 0.78, H * 0.94)
        end
      end
      local base_dir = (go_right and 0 or math.pi) + rand(-0.22, 0.22)
      local school_depth = rand(0.55, 1.0)
      local spread = math.sqrt(count) * sp.spacing * 0.7

      for _ = 1, count do
        local a = rand(0, TAU)
        local r = math.sqrt(math.random()) * spread
        local speed = rand(sp.speed[1], sp.speed[2])
        local dir = base_dir + rand(-0.15, 0.15)
        table.insert(sim.fish, {
          x = cx + math.cos(a) * r * 1.5,
          y = clamp(cy + math.sin(a) * r * 0.65, 16, H - 16),
          vx = math.cos(dir) * speed,
          vy = math.sin(dir) * speed,
          baseSpeed = speed,
          species = species_idx,
          seed = rand(0, TAU),
          alarm = 0,
          depth = clamp(school_depth + rand(-0.08, 0.08), 0.45, 1.0),
        })
      end
    end

    local function create_sim(cols, rows, preset_idx)
      local cw, ch = 10, 15
      local W = cols * cw
      local H = rows * ch
      local minSide = math.min(W, H)
      -- Scale sharks generously so their cephalofoil, fins, gills, and skin patterns are large and crisp
      local baseLength = clamp(math.max(minSide * 0.74, W * 0.30), 290, 500)
      local specs = PRESETS[preset_idx or 1]

      local sim = {
        cols = cols,
        rows = rows,
        cw = cw,
        ch = ch,
        W = W,
        H = H,
        time = 0,
        sharks = {},
        fish = {},
        events = {},
        energy = {},
        scratch = {},
        heat = {},
        heatScratch = {},
      }

      -- Spawn sharks around the outer perimeter (left flank, right flank, top, bottom)
      for i, spec in ipairs(specs) do
        local length = baseLength * spec.size
        local orbitRx = W * rand(0.35, 0.44)
        local orbitRy = H * rand(0.35, 0.44)
        local a = ((i - 1) / #specs) * TAU + rand(-0.2, 0.2)
        local orbitDir = (i % 2 == 1) and 1 or -1
        local x = W * 0.5 + math.cos(a) * orbitRx
        local y = H * 0.5 + math.sin(a) * orbitRy
        local tx = -math.sin(a) * orbitRx * orbitDir
        local ty = math.cos(a) * orbitRy * orbitDir
        local heading = math.atan2(ty, tx) + rand(-0.18, 0.18)

        local nodes = {}
        local seg = length / (SHARK_NODES - 1)
        for n = 0, SHARK_NODES - 1 do
          nodes[n * 2 + 1] = x - math.cos(heading) * seg * n
          nodes[n * 2 + 2] = y - math.sin(heading) * seg * n
        end

        table.insert(sim.sharks, {
          id = i,
          kind = spec.kind,
          length = length,
          nodes = nodes,
          heading = heading,
          speed = 38,
          phase = rand(0, TAU),
          turn = 0,
          wander = 0,
          orbitDir = orbitDir,
          orbitRx = orbitRx,
          orbitRy = orbitRy,
          hunger = rand(0.25, 0.75),
          depth = spec.size,
        })
      end

      -- Sort smaller/deeper sharks first so larger lead sharks render on top
      table.sort(sim.sharks, function(a, b)
        return a.length < b.length
      end)

      local num_schools = clamp(math.floor((W * H) / 140000), 5, 9)
      for _ = 1, num_schools do
        spawn_school(sim, false)
      end

      return sim
    end

    -- Shark forward-cone prey selection from ascii-sharks/src/world.ts
    local function find_prey(sim, sh)
      if #sim.fish == 0 then
        return nil, 1
      end
      local hx, hy = sh.nodes[1], sh.nodes[2]
      local fx = math.cos(sh.heading)
      local fy = math.sin(sh.heading)
      local maxRange = sh.length * 1.45
      local best = nil
      local bestScore = 1e9

      for _, f in ipairs(sim.fish) do
        local dx = f.x - hx
        local dy = f.y - hy
        local d = math.sqrt(dx * dx + dy * dy)
        if d <= maxRange and d >= 1 then
          local dot = (dx * fx + dy * fy) / d
          if dot >= -0.25 then
            local cone = 1.35 - dot * 0.55
            local score = d * cone
            if score < bestScore then
              bestScore = score
              best = f
            end
          end
        end
      end

      if not best then
        return nil, 1
      end

      local neighbors = 0
      local r2 = 34 * 34
      for _, o in ipairs(sim.fish) do
        local dx = o.x - best.x
        local dy = o.y - best.y
        if dx * dx + dy * dy < r2 then
          neighbors = neighbors + 1
        end
      end
      local confusion = 1 / (1 + math.max(0, neighbors - 4) * 0.08)
      return best, confusion
    end

    local function step_fish(sim, dt)
      local fish = sim.fish
      local W, H = sim.W, sim.H
      local bCols = math.max(1, math.ceil(W / BUCKET_SIZE))
      local bRows = math.max(1, math.ceil(H / BUCKET_SIZE))
      local buckets = {}

      for idx, f in ipairs(fish) do
        local c = clamp(math.floor(f.x / BUCKET_SIZE), 0, bCols - 1)
        local r = clamp(math.floor(f.y / BUCKET_SIZE), 0, bRows - 1)
        local key = r * bCols + c
        local b = buckets[key]
        if not b then
          b = {}
          buckets[key] = b
        end
        b[#b + 1] = idx
      end

      local neighborR2 = 64 * 64

      for i, f in ipairs(fish) do
        local sp = SPECIES[f.species]
        local sepR = sp.spacing
        local sepR2 = sepR * sepR
        local spd = math.sqrt(f.vx * f.vx + f.vy * f.vy)
        if spd < 1e-4 then
          spd = 1
        end
        local hfx = f.vx / spd
        local hfy = f.vy / spd

        local sepX, sepY = 0, 0
        local aliX, aliY = 0, 0
        local cohX, cohY = 0, 0
        local count = 0
        local maxNeighborAlarm = 0

        local c0 = clamp(math.floor(f.x / BUCKET_SIZE), 0, bCols - 1)
        local r0 = clamp(math.floor(f.y / BUCKET_SIZE), 0, bRows - 1)

        for dr = -1, 1 do
          local rr = r0 + dr
          if rr >= 0 and rr < bRows then
            for dc = -1, 1 do
              local cc = c0 + dc
              if cc >= 0 and cc < bCols then
                local cell = buckets[rr * bCols + cc]
                if cell then
                  for _, j in ipairs(cell) do
                    if j ~= i then
                      local o = fish[j]
                      local dx = o.x - f.x
                      local dy = o.y - f.y
                      local d2 = dx * dx + dy * dy
                      if d2 <= neighborR2 and d2 >= 1e-4 then
                        local d = math.sqrt(d2)
                        if d2 < sepR2 then
                          local w = (sepR - d) / sepR
                          sepX = sepX - (dx / d) * w
                          sepY = sepY - (dy / d) * w
                        end
                        if o.species == f.species then
                          local cos = (dx * hfx + dy * hfy) / d
                          if cos >= -0.75 then
                            aliX = aliX + o.vx
                            aliY = aliY + o.vy
                            cohX = cohX + o.x
                            cohY = cohY + o.y
                            count = count + 1
                            if o.alarm > maxNeighborAlarm then
                              maxNeighborAlarm = o.alarm
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end

        local ax = sepX * 95
        local ay = sepY * 95

        if count > 0 then
          aliX = aliX / count
          aliY = aliY / count
          local aliLen = math.sqrt(aliX * aliX + aliY * aliY)
          if aliLen > 1e-3 then
            ax = ax + ((aliX / aliLen) * f.baseSpeed - f.vx) * sp.align
            ay = ay + ((aliY / aliLen) * f.baseSpeed - f.vy) * sp.align
          end

          local toCx = cohX / count - f.x
          local toCy = cohY / count - f.y
          local cd = math.sqrt(toCx * toCx + toCy * toCy)
          local cohBoost = 1 + f.alarm * 1.4
          ax = ax + toCx * sp.cohesion * cohBoost
          ay = ay + toCy * sp.cohesion * cohBoost

          if sp.mill > 0 and cd > 6 and count >= 5 then
            local tx = -toCy / cd
            local ty = toCx / cd
            local sign = tx * f.vx + ty * f.vy >= 0 and 1 or -1
            local millStrength = sp.mill * (1 + f.alarm * 2.2) * 26
            ax = ax + tx * sign * millStrength
            ay = ay + ty * sign * millStrength
          end
        end

        -- Predator evasion (fountain effect around approaching shark head)
        local directFear = 0
        for _, sh in ipairs(sim.sharks) do
          local sdx = math.cos(sh.heading)
          local sdy = math.sin(sh.heading)
          for k = 0, SHARK_NODES - 1, 2 do
            local nx = sh.nodes[k * 2 + 1]
            local ny = sh.nodes[k * 2 + 2]
            local dx = f.x - nx
            local dy = f.y - ny
            local d = math.sqrt(dx * dx + dy * dy)
            local fearR = (k == 0 and sh.length * 0.52 or sh.length * 0.28) + 46
            if d < fearR and d > 1e-3 then
              local w = (1 - d / fearR) ^ 2
              if k == 0 then
                local side = sdx * dy - sdy * dx >= 0 and 1 or -1
                local lx = -sdy * side
                local ly = sdx * side
                ax = ax + (dx / d * 0.55 + lx * 0.75) * 920 * w
                ay = ay + (dy / d * 0.55 + ly * 0.75) * 920 * w
              else
                ax = ax + (dx / d) * 760 * w
                ay = ay + (dy / d) * 760 * w
              end
              if w > directFear then
                directFear = w
              end
            end
          end
        end

        local propagated = maxNeighborAlarm * 0.88
        f.alarm = math.max(f.alarm * math.exp(-dt * 2.2), directFear, propagated)

        local curX, curY = ocean_current(f.x, f.y, sim.time)
        ax = ax + (curX - f.vx * 0.15) * 0.6
        ay = ay + (curY - f.vy * 0.15) * 0.6
        ay = ay - f.vy * sp.verticalDrag * (1 - 0.6 * f.alarm)

        local m = 42
        if f.x < m then
          ax = ax + (m - f.x) * 4.5
        elseif f.x > W - m then
          ax = ax - (f.x - (W - m)) * 4.5
        end
        if f.y < m then
          ay = ay + (m - f.y) * 5.5
        elseif f.y > H - m then
          ay = ay - (f.y - (H - m)) * 5.5
        end

        f.vx = f.vx + (ax + math.cos(sim.time * 1.9 + f.seed) * sp.jitter) * dt
        f.vy = f.vy + (ay + math.sin(sim.time * 2.5 + f.seed) * sp.jitter * 0.6) * dt

        local newSpd = math.sqrt(f.vx * f.vx + f.vy * f.vy)
        local maxSpd = f.baseSpeed * (1.2 + 1.65 * f.alarm)
        local minSpd = f.baseSpeed * 0.55
        if newSpd > maxSpd then
          f.vx = (f.vx / newSpd) * maxSpd
          f.vy = (f.vy / newSpd) * maxSpd
        elseif newSpd < minSpd and newSpd > 1e-3 then
          f.vx = (f.vx / newSpd) * minSpd
          f.vy = (f.vy / newSpd) * minSpd
        end

        f.x = f.x + f.vx * dt
        f.y = f.y + f.vy * dt
        if f.x < -30 then
          f.x = W + 25
        elseif f.x > W + 30 then
          f.x = -25
        end
        f.y = clamp(f.y, 8, H - 8)
      end
    end

    local function step_sim(sim, dt)
      sim.time = sim.time + dt
      sim.events = {}
      local W, H = sim.W, sim.H
      local cxW, cyW = W * 0.5, H * 0.5

      step_fish(sim, dt)

      local minFish = clamp(math.floor((W * H) / 11500), 65, 160)
      if #sim.fish < minFish then
        spawn_school(sim, true)
      end

      -- Step sharks (full ascii-sharks AI: hunting pursuit, flank patrol orbit, card avoidance, follow-the-leader spine)
      for _, sh in ipairs(sim.sharks) do
        local L = sh.length
        local nodes = sh.nodes
        local hx, hy = nodes[1], nodes[2]

        sh.hunger = clamp(sh.hunger + dt * 0.038, 0, 1)

        local dx = math.cos(sh.heading)
        local dy = math.sin(sh.heading)

        sh.wander = clamp(sh.wander + (math.random() - 0.5) * dt * 2.8, -1.1, 1.1)
        dx = dx + math.cos(sh.heading + sh.wander) * 0.42
        dy = dy + math.sin(sh.heading + sh.wander) * 0.42

        local prey, confusion = nil, 1
        if sh.hunger > 0.28 then
          prey, confusion = find_prey(sim, sh)
        end

        local closing = 0
        if prey then
          local px = prey.x + prey.vx * 0.28 - hx
          local py = prey.y + prey.vy * 0.28 - hy
          local pd = math.sqrt(px * px + py * py)
          if pd > 1e-3 then
            local focus = sh.hunger * (0.55 + 0.45 * confusion)
            local pull = (1.5 + 1.9 * focus) * clamp(1 - pd / (L * 1.65), 0.25, 1)
            dx = dx + (px / pd) * pull
            dy = dy + (py / pd) * pull
            closing = clamp(1 - pd / (L * 0.95), 0, 1) * focus
          end
        else
          -- Wide screen-filling elliptical patrol through the left/right flanks and top/bottom waters
          local breath = 1 + 0.12 * math.sin(sim.time * 0.14 + sh.id * 1.7)
          local rx = (hx - cxW) / math.max(1, sh.orbitRx * breath)
          local ry = (hy - cyW) / math.max(1, sh.orbitRy * breath)
          local r = math.sqrt(rx * rx + ry * ry)
          if r < 1e-3 then
            r = 1e-3
          end
          local radial = clamp(1 - r, -1, 1)
          local tx = -ry / r * sh.orbitDir
          local ty = rx / r * sh.orbitDir
          dx = dx + (tx + (rx / r) * radial * 0.85) * 0.72
          dy = dy + (ty + (ry / r) * radial * 0.85) * 0.72
        end

        -- Soft no-swim repulsion zone shaped to the centered UI card so sharks swim around the controls box
        local cardHalfW = math.max(W * 0.24, 33 * sim.cw)
        local cardHalfH = H * 0.34
        local ex = (hx - cxW) / cardHalfW
        local ey = (hy - cyW) / cardHalfH
        local e2 = ex * ex + ey * ey
        if e2 < 1 and e2 > 1e-5 then
          local e = math.sqrt(e2)
          local w = (1 - e) * (prey and 1.25 or 2.45)
          -- Push horizontally toward the wide left/right flanks as well as radially
          dx = dx + (ex / e) * w * 1.25
          dy = dy + (ey / e) * w * 0.9
        end

        -- Soft boundary return near screen edges
        local padX = W * 0.04
        local padY = H * 0.05
        local over = math.max(padX - hx, hx - (W - padX), padY - hy, hy - (H - padY))
        if over > 0 then
          local w = clamp(over / (L * 0.32), 0, 1) * 3.6
          local toX = cxW - hx
          local toY = cyW - hy
          local d = math.sqrt(toX * toX + toY * toY)
          if d > 1e-3 then
            dx = dx + (toX / d) * w
            dy = dy + (toY / d) * w
          end
        end

        -- Multi-node separation between sharks
        for _, other in ipairs(sim.sharks) do
          if other ~= sh then
            for k = 0, SHARK_NODES - 1, 4 do
              local ox = hx - other.nodes[k * 2 + 1]
              local oy = hy - other.nodes[k * 2 + 2]
              local d = math.sqrt(ox * ox + oy * oy)
              local range = (L + other.length) * (k == 0 and 0.42 or 0.25)
              if d < range and d > 1e-3 then
                local w = (1 - d / range) * 2.4
                dx = dx + (ox / d) * w
                dy = dy + (oy / d) * w
              end
            end
          end
        end

        local curX, curY = ocean_current(hx, hy, sim.time)
        dx = dx + curX * 0.012
        dy = dy + curY * 0.012

        local desired = math.atan2(dy, dx)
        local maxTurn = (1.05 + closing * 1.55) * dt
        local turned = clamp(angleDiff(sh.heading, desired), -maxTurn, maxTurn)
        sh.heading = sh.heading + turned
        sh.turn = sh.turn + (turned / math.max(1e-4, dt) - sh.turn) * math.min(1, dt * 3)

        local cruise = 34 + L * 0.045
        local targetSpeed = cruise * (1 + closing * 1.45)
        sh.speed = sh.speed + (targetSpeed - sh.speed) * math.min(1, dt * 2.2)
        sh.phase = sh.phase + dt * (2.2 + sh.speed / 22)

        nodes[1] = nodes[1] + math.cos(sh.heading) * sh.speed * dt
        nodes[2] = nodes[2] + math.sin(sh.heading) * sh.speed * dt

        -- Eat fish within mouth reach
        local mouthX = nodes[1] + math.cos(sh.heading) * L * 0.03
        local mouthY = nodes[2] + math.sin(sh.heading) * L * 0.03
        local eatR2 = (L * 0.055) ^ 2
        for fi = #sim.fish, 1, -1 do
          local f = sim.fish[fi]
          local fdx = f.x - mouthX
          local fdy = f.y - mouthY
          if fdx * fdx + fdy * fdy < eatR2 then
            table.insert(sim.events, { x = f.x, y = f.y })
            table.remove(sim.fish, fi)
            sh.hunger = math.max(0, sh.hunger - 0.14)
            break
          end
        end

        -- Follow-the-leader spine solver with maximum inter-segment curvature
        local seg = L / (SHARK_NODES - 1)
        local maxBend = 0.16
        local prevAngle = sh.heading + math.pi
        for k = 1, SHARK_NODES - 1 do
          local px = nodes[(k - 1) * 2 + 1]
          local py = nodes[(k - 1) * 2 + 2]
          local angle = math.atan2(nodes[k * 2 + 2] - py, nodes[k * 2 + 1] - px)
          angle = prevAngle + clamp(angleDiff(prevAngle, angle), -maxBend, maxBend)
          nodes[k * 2 + 1] = px + math.cos(angle) * seg
          nodes[k * 2 + 2] = py + math.sin(angle) * seg
          prevAngle = angle
        end
      end
    end

    -- Markings for tiger shark wavy bars & zebra shark spots (from ascii-sharks/src/renderer.ts)
    local function marked(shape, s, v, L, across, sharkId)
      if shape == SHAPES.tiger then
        if s < 0.16 or s > 0.85 or across < 0.22 or across > 0.92 then
          return false
        end
        local wobble = (hash3(math.floor(s * 28), math.floor(across * 6), sharkId) - 0.5) * 1.1
        local bar = math.sin(s * math.pi * 2 * 9 + wobble)
        return bar > 0.42
      end
      if shape == SHAPES.zebra and s > 0.07 then
        local gu = (s * L) / (L * 0.06)
        local gv = v / (L * 0.045)
        local cu = math.floor(gu)
        local cv = math.floor(gv)
        local jx = hash3(cu, cv, sharkId) * 0.5 + 0.25
        local jy = hash3(cu, cv, sharkId + 11) * 0.5 + 0.25
        local dx = gu - (cu + jx)
        local dy = gv - (cv + jy)
        return dx * dx + dy * dy < 0.08
      end
      return false
    end

    local function sample_shark(px, py, L, spine, arc, arcTotal, shape, finTipLeft, finTipRight, sharkId)
      local best = 1e12
      local bestS = 0
      local bestSign = 1
      local bestNx = 0
      local bestNy = 0

      for k = 0, SHARK_NODES - 2 do
        local ax = spine[k * 2 + 1]
        local ay = spine[k * 2 + 2]
        local sx = spine[(k + 1) * 2 + 1] - ax
        local sy = spine[(k + 1) * 2 + 2] - ay
        local len2 = sx * sx + sy * sy
        if len2 < 1e-6 then
          len2 = 1
        end
        local u = clamp(((px - ax) * sx + (py - ay) * sy) / len2, 0, 1)
        local qx = ax + sx * u
        local qy = ay + sy * u
        local dx = px - qx
        local dy = py - qy
        local d2 = dx * dx + dy * dy
        if d2 < best then
          best = d2
          local len = math.sqrt(len2)
          bestS = (arc[k + 1] + u * len) / arcTotal
          bestSign = (sx * (py - ay) - sy * (px - ax) >= 0) and 1 or -1
          bestNx = (-sy / len) * bestSign
          bestNy = (sx / len) * bestSign
        end
      end

      local a = math.sqrt(best)
      local s = bestS
      local u = s * L
      local w = shape.halfWidth(s) * L

      local head = shape.head
      if head and u < L * (head.sweep + head.depth + head.notch) then
        local span = L * head.span
        local r = a / span
        local front = L * head.sweep * r * r + L * head.notch * math.max(0, 1 - r / 0.14)
        local depth = L * head.depth * (1 - 0.2 * (r ^ 4))
        if r <= 1 and u >= front and u <= front + depth then
          local flag = r > 0.84 and FLAG_EYE or FLAG_BODY
          local shade = r > 0.84 and 0 or (0.62 - 0.2 * r + (u < front + L * 0.012 and 0.1 or 0))
          return true, flag, shade, s, a * bestSign, a
        end
      end

      if a <= w then
        local across = a / math.max(1e-3, w)
        local facing = (bestNx * -0.6 + bestNy * -0.8) * across
        local shade = 0.58 - across * across * 0.42 + facing * 0.26
        local flag = FLAG_BODY
        if s > shape.dorsal[1] and s < shape.dorsal[2] and across < 0.3 then
          flag = FLAG_RIDGE
          shade = 1
        elseif s > shape.secondDorsal[1] and s < shape.secondDorsal[2] and across < 0.4 then
          shade = math.max(shade, 0.82)
        elseif shape.eye and s > shape.eye[1] and s < shape.eye[2] and across > 0.6 then
          flag = FLAG_EYE
          shade = 0
        elseif s > shape.gills[1] and s < shape.gills[2] and across > 0.58 then
          if math.floor(((s - shape.gills[1]) / (shape.gills[2] - shape.gills[1])) * 5) % 2 == 0 then
            shade = shade * 0.45
          end
        elseif s < 0.05 then
          shade = math.max(shade, 0.7)
        elseif
          shape == SHAPES.zebra
          and s > 0.14
          and s < 0.55
          and (
            math.abs(across - 0.18) < 0.045
            or math.abs(across - 0.48) < 0.04
            or math.abs(across - 0.76) < 0.035
          )
        then
          shade = math.max(shade, 0.88)
        elseif marked(shape, s, a * bestSign, L, across, sharkId) then
          flag = FLAG_MARK
        end
        return true, flag, shade, s, a * bestSign, a
      end

      local tip = bestSign > 0 and finTipRight or finTipLeft
      local p0, p1, p2 = shape.pectoral[1], shape.pectoral[2], shape.pectoral[3]
      if
        inTriangle(u, a, L * p0, 0, L * p1, 0, L * p2, tip)
        and not (shape.falcate and inTriangle(u, a, L * p1, 0, L * (p1 + (p2 - p1) * 0.33), tip * 0.55, L * p2, tip))
      then
        local flag = marked(shape, s, a * bestSign, L, 0, sharkId) and FLAG_MARK or FLAG_FIN
        return true, flag, 0.38 + 0.22 * (1 - clamp(a / math.max(1, tip), 0, 1)), s, a * bestSign, a
      end

      local v0, v1, v2, vr = shape.pelvic[1], shape.pelvic[2], shape.pelvic[3], shape.pelvic[4]
      if
        inTriangle(u, a, L * v0, 0, L * v1, 0, L * v2, L * vr)
        or (shape.caudal > 0 and inTriangle(u, a, L * 0.86, 0, L * 0.95, 0, L, L * shape.caudal))
      then
        return true, FLAG_FIN, 0.36, s, a * bestSign, a
      end

      return false, 0, 0, s, a * bestSign, a
    end

    local function diffuse_field(field, scratch, cols, rows, decay)
      local n = cols * rows
      for i = 0, n - 1 do
        local c = i % cols
        local r = (i - c) / cols
        local center = field[i] or 0
        local l = c > 0 and (field[i - 1] or 0) or center
        local rt = c < cols - 1 and (field[i + 1] or 0) or center
        local u = r > 0 and (field[i - cols] or 0) or center
        local d = r < rows - 1 and (field[i + cols] or 0) or center
        local val = (center * 4 + l + rt + u + d) * 0.125 * decay
        scratch[i] = val > 0.015 and val or nil
      end
      for i = 0, n - 1 do
        field[i] = scratch[i]
      end
    end

    local function compute_shark_grid(sim)
      local cols, rows, cw, ch = sim.cols, sim.rows, sim.cw, sim.ch
      local grid_char = {}
      local grid_hl = {}

      -- 1. Deposit wake from fish & shark tails, plus eat heat splashes, then diffuse
      for _, f in ipairs(sim.fish) do
        local c = math.floor(f.x / cw)
        local r = math.floor(f.y / ch)
        if c >= 0 and c < cols and r >= 0 and r < rows then
          local idx = r * cols + c
          sim.energy[idx] = math.min(1.0, (sim.energy[idx] or 0) + (0.08 + f.alarm * 0.25) * f.depth)
        end
      end
      for _, sh in ipairs(sim.sharks) do
        for k = SHARK_NODES - 6, SHARK_NODES - 1 do
          local c = math.floor(sh.nodes[k * 2 + 1] / cw)
          local r = math.floor(sh.nodes[k * 2 + 2] / ch)
          if c >= 0 and c < cols and r >= 0 and r < rows then
            local idx = r * cols + c
            sim.energy[idx] = math.min(1.0, (sim.energy[idx] or 0) + 0.42 * sh.depth)
          end
        end
      end
      for _, ev in ipairs(sim.events) do
        local c = math.floor(ev.x / cw)
        local r = math.floor(ev.y / ch)
        for dr = -1, 1 do
          for dc = -1, 1 do
            local cc, rr = c + dc, r + dr
            if cc >= 0 and cc < cols and rr >= 0 and rr < rows then
              local w = (dc == 0 and dr == 0) and 1.0 or 0.6
              local idx = rr * cols + cc
              sim.heat[idx] = math.min(1.0, (sim.heat[idx] or 0) + w)
            end
          end
        end
      end

      diffuse_field(sim.energy, sim.scratch, cols, rows, 0.90)
      diffuse_field(sim.heat, sim.heatScratch, cols, rows, 0.84)

      -- 2. Render wake & feeding heat splashes
      for idx, e in pairs(sim.energy) do
        if e >= 0.08 then
          grid_char[idx] = e > 0.55 and ":" or "·"
          grid_hl[idx] = e > 0.35 and "SharkWakeBright" or "SharkWakeDim"
        end
      end
      for idx, h in pairs(sim.heat) do
        if h >= 0.08 then
          grid_char[idx] = h > 0.45 and "*" or "·"
          grid_hl[idx] = h > 0.45 and "SharkHeatBright" or "SharkHeatDim"
        end
      end

      -- 3. Render schooling fish
      for _, f in ipairs(sim.fish) do
        local c = math.floor(f.x / cw)
        local r = math.floor(f.y / ch)
        if c >= 0 and c < cols and r >= 0 and r < rows then
          local idx = r * cols + c
          grid_char[idx] = "-"
          grid_hl[idx] = f.alarm > 0.35 and "SharkFishBright" or (f.depth > 0.78 and "SharkFishMid" or "SharkFishDim")
        end
      end

      -- 4. Render sharks with full 5-point sub-cell supersampling (center + 4 SUBSAMPLES)
      local spine = {}
      local arc = {}
      for _, sh in ipairs(sim.sharks) do
        local L = sh.length
        local n = sh.nodes
        local swim = clamp(sh.speed / 60, 0.4, 1.4)
        local shape = SHAPES[sh.kind]

        for k = 0, SHARK_NODES - 1 do
          local s = k / (SHARK_NODES - 1)
          local a = math.max(0, k - 1)
          local b = math.min(SHARK_NODES - 1, k + 1)
          local tx = n[a * 2 + 1] - n[b * 2 + 1]
          local ty = n[a * 2 + 2] - n[b * 2 + 2]
          local tl = math.sqrt(tx * tx + ty * ty)
          if tl < 1e-6 then
            tl = 1
          end
          tx, ty = tx / tl, ty / tl
          local amp = L * 0.05 * (0.1 + 0.9 * (s ^ 1.8)) * swim
          local off = amp * math.sin(sh.phase - s * 5.2)
          spine[k * 2 + 1] = n[k * 2 + 1] - ty * off
          spine[k * 2 + 2] = n[k * 2 + 2] + tx * off
        end

        arc[1] = 0
        for k = 1, SHARK_NODES - 1 do
          local dx = spine[k * 2 + 1] - spine[(k - 1) * 2 + 1]
          local dy = spine[k * 2 + 2] - spine[(k - 1) * 2 + 2]
          arc[k + 1] = arc[k] + math.sqrt(dx * dx + dy * dy)
        end
        local arcTotal = math.max(1, arc[SHARK_NODES])

        local bank = clamp(sh.turn * 0.45, -0.35, 0.35)
        local flex = 1 + 0.06 * math.sin(sh.phase * 0.5)
        local reachFin = shape.pectoral[4]
        local finTipRight = L * reachFin * flex * (1 - bank)
        local finTipLeft = L * reachFin * flex * (1 + bank)

        local minX, minY, maxX, maxY = 1e9, 1e9, -1e9, -1e9
        for k = 0, SHARK_NODES - 1 do
          local sx, sy = spine[k * 2 + 1], spine[k * 2 + 2]
          if sx < minX then
            minX = sx
          end
          if sx > maxX then
            maxX = sx
          end
          if sy < minY then
            minY = sy
          end
          if sy > maxY then
            maxY = sy
          end
        end

        local reach = L * 0.36
        local c0 = math.max(0, math.floor((minX - reach) / cw))
        local c1 = math.min(cols - 1, math.floor((maxX + reach) / cw))
        local r0 = math.max(0, math.floor((minY - reach) / ch))
        local r1 = math.min(rows - 1, math.floor((maxY + reach) / ch))
        local skipBeyond = reach + 20

        for r = r0, r1 do
          for c = c0, c1 do
            local x = c * cw + cw * 0.5
            local y = r * ch + ch * 0.5
            local centerHit, flag, shade, s, v, dist =
              sample_shark(x, y, L, spine, arc, arcTotal, shape, finTipLeft, finTipRight, sh.id)

            if centerHit or dist <= skipBeyond then
              local hits = centerHit and 1 or 0
              for si = 1, #SUBSAMPLES, 2 do
                local sx = c * cw + SUBSAMPLES[si] * cw
                local sy = r * ch + SUBSAMPLES[si + 1] * ch
                local shHit, sFlag, sShade, sS, sV =
                  sample_shark(sx, sy, L, spine, arc, arcTotal, shape, finTipLeft, finTipRight, sh.id)
                if shHit then
                  if not centerHit and hits == 0 then
                    flag, shade, s, v = sFlag, sShade, sS, sV
                  end
                  hits = hits + 1
                end
              end

              if hits > 0 then
                local coverage = hits / 5
                local finalFlag = (centerHit and coverage >= 0.6) and flag or FLAG_EDGE
                local finalShade = finalFlag == FLAG_EDGE and coverage or clamp(shade, 0, 1)

                local idx = r * cols + c
                local su = math.floor(s * 52)
                local sv = math.floor(v / (cw * 0.9))
                local key = math.floor(hash3(su, sv, sh.id) * 100000)
                local tick = math.floor(sim.time * 2.4 + (key % 97) / 19)
                local roll = hash3(key, tick, 7)

                local glyph, hl
                if finalFlag == FLAG_EDGE then
                  local set = finalShade >= 0.5 and EDGE_HEAVY or EDGE_LIGHT
                  glyph = set[(key % #set) + 1]
                  if roll < 0.04 then
                    hl = "SharkAccent_" .. ((key % 8) + 1)
                  else
                    hl = finalShade >= 0.5 and "SharkEdgeBright" or "SharkEdgeDim"
                  end
                elseif finalFlag == FLAG_RIDGE then
                  glyph = RIDGE_GLYPHS[(key % #RIDGE_GLYPHS) + 1]
                  hl = "SharkRidge"
                elseif finalFlag == FLAG_EYE then
                  glyph = "o"
                  hl = "SharkEye"
                elseif finalFlag == FLAG_MARK then
                  glyph = MARK_GLYPHS[(key % #MARK_GLYPHS) + 1]
                  hl = "SharkMark"
                elseif finalFlag == FLAG_FIN then
                  glyph = FIN_GLYPHS[(key % #FIN_GLYPHS) + 1]
                  if roll < 0.05 then
                    hl = "SharkAccent_" .. ((key % 8) + 1)
                  else
                    local lvl = clamp(math.floor((0.25 + finalShade * 0.65) * 8) + 1, 1, 8)
                    hl = "SharkSkin_" .. shape.tint .. "_" .. lvl
                  end
                else
                  local jitter = (hash3(key, 3, 19) - 0.5) * 0.9
                  local ramp_idx = clamp(math.floor((1 - finalShade) * (#SKIN_RAMP - 0.01) + jitter) + 1, 1, #SKIN_RAMP)
                  glyph = SKIN_RAMP[ramp_idx]
                  if roll < 0.095 then
                    hl = "SharkAccent_" .. ((key % 8) + 1)
                  else
                    local lvl = clamp(math.floor(finalShade * 7.99) + 1, 1, 8)
                    hl = "SharkSkin_" .. shape.tint .. "_" .. lvl
                  end
                end

                grid_char[idx] = glyph
                grid_hl[idx] = hl
              end
            end
          end
        end
      end

      return grid_char, grid_hl
    end

    local function build_shark_virt_text(grid_char, grid_hl, row, start_col, end_col, cols)
      if end_col <= start_col then
        return nil
      end
      local row_offset = row * cols
      local last_active = -1
      for c = end_col - 1, start_col, -1 do
        if grid_char[row_offset + c] then
          last_active = c
          break
        end
      end
      if last_active < start_col then
        return nil
      end

      local chunks = {}
      local cur_chars = {}
      local cur_hl = nil

      for c = start_col, last_active do
        local idx = row_offset + c
        local ch = grid_char[idx] or " "
        local hl = grid_hl[idx]
        if hl ~= cur_hl and #cur_chars > 0 then
          table.insert(chunks, { table.concat(cur_chars), cur_hl })
          cur_chars = {}
        end
        cur_hl = hl
        table.insert(cur_chars, ch)
      end
      if #cur_chars > 0 then
        table.insert(chunks, { table.concat(cur_chars), cur_hl })
      end
      return chunks
    end

    local function detect_git_branch()
      local out = fn.systemlist({ "git", "-C", launch_dir, "branch", "--show-current" })
      if vim.v.shell_error == 0 and out and out[1] and out[1] ~= "" then
        state.git_branch = out[1]
      else
        state.git_branch = nil
      end
    end

    -- Geometric NEOVIM banner
    local logo_final = {
      "███╗   ██╗ ███████╗  ██████╗  ██╗   ██╗ ██╗ ███╗   ███╗",
      "████╗  ██║ ██╔════╝ ██╔═══██╗ ██║   ██║ ██║ ████╗ ████║",
      "██╔██╗ ██║ █████╗   ██║   ██║ ██║   ██║ ██║ ██╔████╔██║",
      "██║╚██╗██║ ██╔══╝   ██║   ██║ ╚██╗ ██╔╝ ██║ ██║╚██╔╝██║",
      "██║ ╚████║ ███████╗ ╚██████╔╝  ╚████╔╝  ██║ ██║ ╚═╝ ██║",
      "╚═╝  ╚═══╝ ╚══════╝  ╚═════╝    ╚═══╝   ╚═╝ ╚═╝     ╚═╝",
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

    -- Build centered dashboard layout with foreground bounds for sharks background animation
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
        fg_bounds = {},
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
        local centered, pad, w = center_line(raw, win_width)
        table.insert(lines, centered)
        local r_idx = #lines - 1
        meta.logo_rows[i] = r_idx
        meta.logo_pad = pad
        meta.fg_bounds[r_idx] = {
          left = math.max(0, pad - 1),
          right = math.min(win_width, pad + w + 1),
        }
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
      local pill_centered, pill_pad, pill_w = center_line(pill_plain, win_width)
      table.insert(lines, pill_centered)
      local pill_r = #lines - 1
      meta.pill_row = {
        row = pill_r,
        pad = pill_pad,
        segments = pill_segments,
      }
      meta.fg_bounds[pill_r] = {
        left = math.max(0, pill_pad - 2),
        right = math.min(win_width, pill_pad + pill_w + 2),
      }

      local function mark_card_bounds(r)
        meta.fg_bounds[r] = {
          left = math.max(0, card_pad - 1),
          right = math.min(win_width, card_pad + card_width + 1),
        }
      end

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
      mark_card_bounds(#lines - 1)
      table.insert(meta.section_rows, {
        row = #lines - 1,
        pad = card_pad,
        left_bytes = #("╭" .. string.rep("─", side_len)),
        title_bytes = #top_title,
        total_bytes = #top_border - card_pad,
      })

      local empty_card_row = card_indent .. "│" .. string.rep(" ", card_width - 2) .. "│"
      table.insert(lines, empty_card_row)
      mark_card_bounds(#lines - 1)
      table.insert(meta.box_rows, #lines - 1)

      -- 4. Action Rows (Single-column classic layout)
      for idx, act in ipairs(actions) do
        local row_idx = #lines
        table.insert(lines, empty_card_row)
        mark_card_bounds(row_idx)
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
      mark_card_bounds(#lines - 1)
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
        mark_card_bounds(#lines - 1)
        table.insert(meta.section_rows, {
          row = #lines - 1,
          pad = card_pad,
          left_bytes = #("├" .. string.rep("─", r_side)),
          title_bytes = #rec_title,
          total_bytes = #mid_border - card_pad,
        })

        table.insert(lines, empty_card_row)
        mark_card_bounds(#lines - 1)
        table.insert(meta.box_rows, #lines - 1)

        for idx, rec in ipairs(recents) do
          local row_idx = #lines
          table.insert(lines, empty_card_row)
          mark_card_bounds(row_idx)
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
        mark_card_bounds(#lines - 1)
        table.insert(meta.box_rows, #lines - 1)
      end

      -- 6. Card Bottom Border
      local bot_border = card_indent .. "╰" .. string.rep("─", card_width - 2) .. "╯"
      table.insert(lines, bot_border)
      mark_card_bounds(#lines - 1)
      table.insert(meta.box_rows, #lines - 1)

      -- Fill remaining rows down to win_height for a clean canvas
      while #lines < win_height do
        table.insert(lines, "")
      end

      meta.base_lines = lines
      state.layout = meta

      local sim_cols = math.max(40, win_width)
      local sim_rows = math.max(15, #lines)
      if not state.sim then
        state.sim = create_sim(sim_cols, sim_rows, state.preset_idx)
      elseif state.sim.cols ~= sim_cols or state.sim.rows ~= sim_rows then
        state.sim = create_sim(sim_cols, sim_rows, state.preset_idx)
      end

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

      -- 0. Render ASCII-Sharks Background Animation Around Foreground UI
      if state.sim then
        local grid_char, grid_hl = compute_shark_grid(state.sim)
        local total_rows = #lines
        local sim_cols = state.sim.cols
        for r = 0, total_rows - 1 do
          local bounds = meta.fg_bounds[r]
          if not bounds then
            local vt = build_shark_virt_text(grid_char, grid_hl, r, 0, meta.win_width, sim_cols)
            if vt then
              api.nvim_buf_set_extmark(state.buf, ns, r, 0, {
                virt_text = vt,
                virt_text_win_col = 0,
                hl_mode = "combine",
                priority = 10,
              })
            end
          else
            if bounds.left > 0 then
              local vt_left = build_shark_virt_text(grid_char, grid_hl, r, 0, bounds.left, sim_cols)
              if vt_left then
                api.nvim_buf_set_extmark(state.buf, ns, r, 0, {
                  virt_text = vt_left,
                  virt_text_win_col = 0,
                  hl_mode = "combine",
                  priority = 10,
                })
              end
            end
            if bounds.right < meta.win_width then
              local vt_right = build_shark_virt_text(grid_char, grid_hl, r, bounds.right, meta.win_width, sim_cols)
              if vt_right then
                api.nvim_buf_set_extmark(state.buf, ns, r, 0, {
                  virt_text = vt_right,
                  virt_text_win_col = bounds.right,
                  hl_mode = "combine",
                  priority = 10,
                })
              end
            end
          end
        end
      end

      -- Highlight Logo with Diagonal Flowing Aurora Wave
      local wave_phase = state.tick * 0.038
      for r_idx, _ in ipairs(logo_final) do
        local buf_row = meta.logo_rows[r_idx]
        local line_str = lines[buf_row + 1]
        local row_cells = split_utf8_cells(line_str)
        for _, cell in ipairs(row_cells) do
          if cell.char ~= " " then
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

      -- Flush redraw immediately even when typing in Command mode (:)
      if fn.mode():match("^[cr]") and api.nvim__redraw then
        pcall(api.nvim__redraw, { buf = state.buf, valid = true })
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
          if state.sim then
            step_sim(state.sim, state.phase == "intro" and 0.022 or 0.045)
          end

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
                  if state.sim then
                    step_sim(state.sim, 0.045)
                  end
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
      state.sim = nil
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
      vim.keymap.set("n", "s", function()
        state.preset_idx = (state.preset_idx % #PRESETS) + 1
        if state.sim then
          state.sim = create_sim(state.sim.cols, state.sim.rows, state.preset_idx)
          render_frame()
        end
      end, kopts)

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
