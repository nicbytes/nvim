return {
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      opts.sources.providers = opts.sources.providers or {}
      opts.sources.default = opts.sources.default or { "lsp", "buffer", "snippets", "path" }

      -- Register our custom Firebase rules provider
      opts.sources.providers.firebase_rules = {
        name = "Firebase Rules",
        module = "blink_sources.firebase_rules",
        opts = {}, -- you could pass additional options here
      }

      -- Enable it globally (first) so its items appear near the top
      table.insert(opts.sources.default, 1, "firebase_rules")

      -- -- Optionally restrict to your rules filetype
      -- opts.sources.per_filetype = opts.sources.per_filetype or {}
      -- opts.sources.per_filetype.firebase_security_rules = { "firebase_rules", "buffer", "path" }
      --
      -- -- Optional: disable snippet signatures for this filetype if you don't want them
      -- opts.signature = opts.signature or {}
      -- opts.signature.enabled = false
    end,
  },
}
