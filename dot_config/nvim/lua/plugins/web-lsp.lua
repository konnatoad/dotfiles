-- ~/.config/nvim/lua/plugins/web-lsp.lua
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        html = {}, -- HTML (uses html-lsp)
        cssls = {}, -- CSS (uses css-lsp)
        -- TypeScript/JavaScript is handled by vtsls from the typescript extra.
        -- tsgo is installed in mason too and would otherwise auto-start next to it,
        -- giving duplicate diagnostics and "Command setContext not found" errors
        tsgo = { enabled = false },
        -- same story for python: pyright (python extra) already covers it
        pylsp = { enabled = false },
      },
    },
  },
}
