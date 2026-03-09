return {
  {
    "folke/todo-comments.nvim",
    opts = function(_, opts)
      opts.keywords = vim.tbl_deep_extend("force", opts.keywords or {}, {
        COURT = { icon = "⚖ ", color = "error" },
        TRIBUNAL = { icon = "󰙣 ", color = "warning" },
        ASTRONOMER = { icon = " ", color = "info" },
        OBSERVATORY = { icon = " ", color = "hint" },
        VOID = { icon = " ", color = "default" },
      })
    end,
  },
}
