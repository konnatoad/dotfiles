-- catppuccin mocha with the UI greys matched to the desktop (noctalia/ghostty monochrome);
-- syntax colors stay vivid
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false, -- nvim 0.12 ships its own "catppuccin" colorscheme that would win otherwise
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = true, -- let the ghostty blur show through
      float = { transparent = true, solid = false },
      term_colors = true,
      styles = {
        comments = { "italic" },
        keywords = { "italic" },
      },
      -- only the background/text greys are overridden so the UI matches noctalia/ghostty;
      -- syntax keeps catppuccin's full-strength accent colors so code pops
      color_overrides = {
        mocha = {
          text = "#e2e2e2",
          subtext1 = "#c6c6c6",
          subtext0 = "#ababab",
          overlay2 = "#919191",
          overlay1 = "#7a7a7a",
          overlay0 = "#5e5e5e",
          surface2 = "#474747",
          surface1 = "#383838",
          surface0 = "#262626",
          base = "#131313",
          mantle = "#0e0e0e",
          crust = "#0a0a0a",
        },
      },
      custom_highlights = function(c)
        return {
          CursorLineNr = { fg = c.blue, style = { "bold" } },
          FloatBorder = { fg = c.overlay0 },
          FloatTitle = { fg = c.blue },
          WinSeparator = { fg = c.surface1 },
        }
      end,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "catppuccin-mocha" },
  },
}
