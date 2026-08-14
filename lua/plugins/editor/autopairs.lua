return {
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  config = function()
    local autopairs = require("nvim-autopairs")
    local Rule = require("nvim-autopairs.rule")
    local cond = require("nvim-autopairs.conds")

    autopairs.setup({
      check_ts = true,           -- use treesitter for smarter pairing
      ts_config = {
        lua  = { "string" },     -- don't add pairs inside lua strings
        javascript = { "template_string" },
        typescript = { "template_string" },
      },
      disable_filetype = { "TelescopePrompt", "spectre_panel" },
      fast_wrap = {
        map = "<M-e>",           -- Alt+e: wrap the next word in brackets
        chars = { "{", "[", "(", '"', "'" },
        end_key = "$",
        keys = "qwertyuiopzxcvbnmasdfghjkl",
        check_comma = true,
        highlight = "Search",
      },
    })

    -- Integrate with nvim-cmp: only add closing pair when cmp is not active
    local cmp_autopairs = require("nvim-autopairs.completion.cmp")
    local ok, cmp = pcall(require, "cmp")
    if ok then
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end

    -- Extra rule: add space inside {  } for JS/TS objects
    autopairs.add_rules({
      Rule("{ ", " }", { "javascript", "typescript", "javascriptreact", "typescriptreact" }),
    })
  end,
}
