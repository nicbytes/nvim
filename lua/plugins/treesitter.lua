-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE
-- Customize Treesitter

local script_path = debug.getinfo(1, "S").source:sub(2)
local script_dir = vim.fn.fnamemodify(script_path, ":h")

-- Put this in your config (e.g. in the same lazy spec)
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*.rules" },
  callback = function() vim.bo.filetype = "firebase_security_rules" end,
})

-- Stronger override - runs after all other filetype detection
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function()
    if vim.fn.expand "%:e" == "rules" and vim.bo.filetype ~= "firebase_security_rules" then
      vim.bo.filetype = "firebase_security_rules"
    end
  end,
})

return {
  {
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
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- 1) Register the parser from your local grammar
      local parser_config = require("nvim-treesitter.parsers").get_parser_configs()

      parser_config.firebase_security_rules = {
        install_info = {
          -- Path to your tree-sitter project (must contain src/parser.c)
          url = script_dir .. "../../../../code/tree-sitter-firebase-security-rules",
          files = { "src/parser.c" },
          -- generate_requires_npm = false,
          -- requires_generate_from_grammar = false,
        },
        filetype = "firebase_security_rules", -- 2) filetype -> parser
        -- used_by = { "rules" }, -- optional: only needed if you *don’t* set filetype via autocmd
      }

      -- 3) Ensure Treesitter installs/loads the parser and highlighting
      opts.ensure_installed = opts.ensure_installed or {}
      if not vim.tbl_contains(opts.ensure_installed, "firebase_security_rules") then
        table.insert(opts.ensure_installed, "firebase_security_rules")
      end

      opts.highlight = opts.highlight or {}
      opts.highlight.enable = true
      opts.highlight.additional_vim_regex_highlighting = false
    end,
  },
}
