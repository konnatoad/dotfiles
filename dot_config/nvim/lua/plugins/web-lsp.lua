-- ~/.config/nvim/lua/plugins/web-lsp.lua
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ts_ls = {}, -- TypeScript / JavaScript (uses typescript-language-server)
        html = {}, -- HTML (uses html-lsp)
        cssls = {}, -- CSS (uses css-lsp)
      },
    },
  },
}
