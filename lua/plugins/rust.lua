return {
  "AstroNvim/astrolsp",
  optional = true,
  ---@param opts AstroLSPOpts
  opts = {
    handlers = { rust_analyzer = false }, -- disable setup of `rust_analyzer`
    features = {
      inlay_hints = true,
    },
    ---@diagnostic disable: missing-fields
    config = {
      rust_analyzer = {
        settings = {
          ["rust-analyzer"] = {
            check = {
              command = "clippy",
              extraArgs = {
                "--no-deps",
              },
            },
            files = {
              excludeDirs = {
                "venv",
              },
            },
          },
        },
      },
    },
  },
}
