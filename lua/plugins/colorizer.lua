return {
  "NvChad/nvim-colorizer.lua",
  event = "BufReadPre",
  opts = {
    filetypes = { "*", "!lazy" },
    user_default_options = {
      RGB = true,
      RGBA = true,
      names = true,
      RRGGBB = true,
      RRGGBBAA = true,
      AARRGGBB = true,
      rgb_fn = true,
      hsl_fn = true,
      css = true,
      css_fn = true,
      mode = "background", -- Set high contrast color backgrounds
      tailwind = true,     -- Support tailwind color highlights
    },
  },
}
