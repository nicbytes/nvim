-- You can also add or configure plugins by creating files in this `plugins/` folder
-- Here are some examples:

-- Enable bidirectional clipboard.
vim.opt.clipboard = "unnamedplus"

---@type LazySpec
return {

  {
    "folke/zen-mode.nvim",
    keys = {
      { "<leader>z", function() require("zen-mode").toggle() end, mode = "n", desc = "󱅻 Zen Mode" },
    },
    opts = {
      plugins = {
        alacritty = {
          enabled = true,
        },
      },
      float = {
        padding = 4,
        max_height = 32,
      },
    },
  },

  -- == Examples of Overriding Plugins ==

  -- customize alpha options
  {
    "goolord/alpha-nvim",
    opts = function(_, opts)
      -- customize the dashboard header
      opts.section.header.val = {
        " █████  ███████ ████████ ██████   ██████",
        "██   ██ ██         ██    ██   ██ ██    ██",
        "███████ ███████    ██    ██████  ██    ██",
        "██   ██      ██    ██    ██   ██ ██    ██",
        "██   ██ ███████    ██    ██   ██  ██████",
        " ",
        "    ███    ██ ██    ██ ██ ███    ███",
        "    ████   ██ ██    ██ ██ ████  ████",
        "    ██ ██  ██ ██    ██ ██ ██ ████ ██",
        "    ██  ██ ██  ██  ██  ██ ██  ██  ██",
        "    ██   ████   ████   ██ ██      ██",
      }
      return opts
    end,
  },
}
