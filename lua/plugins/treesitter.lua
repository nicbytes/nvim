if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE
-- Customize Treesitter

---@type LazySpec
return {
  "nvim-treesitter/nvim-treesitter",
  opts = function(_, opts)
    -- add more things to the ensure_installed table protecting against community packs modifying it
    opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, {
      "lua",
      -- add more arguments for adding more treesitter parsers
    })

    opts.highlight = { enable = true }

    local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
    parser_config.kdi = {
      install_info = {
        -- if your parser is hosted on a git repo, specify the URL.
        -- Otherwise, if you built it locally, set the 'parser_install_dir' accordingly.
        url = "~/code/tree-sitter-kdi", -- update with your repo URL
        files = { "src/parser.c", "src/scanner.c" },
        -- branch = "main",                -- adjust if your default branch is different
      },
      filetype = "kdi",
    }
  end,
}
