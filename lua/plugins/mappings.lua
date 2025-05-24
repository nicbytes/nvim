---@type LazySpec
return {
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      mappings = {
        n = {
          -- override the existing gd
          ["gd"] = {
            function()
              vim.lsp.buf.definition()
              vim.cmd "normal! zz"
            end,
            desc = "Show the definition of current symbol & center",
            -- cond = "textDocument/definition",
          },
        },
      },
    },
  },
}
