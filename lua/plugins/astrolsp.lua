---@type LazySpec
return {
  "AstroNvim/astrolsp",
  ---@type AstroLSPOpts
  opts = {
    autocmds = {
      -- Prevent double formatting
      -- Ref: https://discord.com/channels/939594913560031363/1224731564261507072/1367373738617868289
      -- Ref: https://github.com/AstroNvim/astrocommunity/blob/ced2b71ebe41d43e2268129caffcf96433e43f8f/lua/astrocommunity/pack/typescript/init.lua#L92-L101
      eslint_fix_on_save = {
        cond = function(client) return client.name == "eslint" and vim.fn.exists ":EslintFixAll" > 0 end,
        {
          event = "BufWritePost",
          desc = "Fix all eslint errors",
          callback = function(args)
            if vim.F.if_nil(vim.b[args.buf].autoformat, vim.g.autoformat, true) then vim.cmd.EslintFixAll() end
          end,
        },
      },
    },
    servers = {
      "rust_analyzer",
    },
  },
}
