return {
  -- Auto-close and auto-rename JSX/HTML tags
  "windwp/nvim-ts-autotag",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    opts = {
      enable_close = true,          -- auto close tags
      enable_rename = true,         -- auto rename paired tags
      enable_close_on_slash = true, -- close on </
    },
    per_filetype = {
      ["html"] = { enable_close = true },
      ["jsx"]  = { enable_close = true },
      ["tsx"]  = { enable_close = true },
    },
  },
}
