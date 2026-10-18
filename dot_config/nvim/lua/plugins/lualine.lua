-- slimmer statusline: rounded ends, no separators in between, no clock (noctalia's bar has one)
return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options.section_separators = { left = "", right = "" }
      opts.options.component_separators = { left = "", right = "" }

      opts.sections.lualine_a = { { "mode", separator = { left = "\u{e0b6}", right = "\u{e0b4}" } } }
      opts.sections.lualine_y = { { "progress" } }
      opts.sections.lualine_z = { { "location", separator = { left = "\u{e0b6}", right = "\u{e0b4}" } } }
    end,
  },
}
