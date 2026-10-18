-- animated cursor: leaves a short smear/trail when jumping around.
-- disabled: ghostty's cursor_liquid.glsl shader does a smoother, pixel-level version
return {
  {
    "sphamba/smear-cursor.nvim",
    enabled = false,
    event = "VeryLazy",
    cond = vim.g.neovide == nil,
    opts = {
      cursor_color = "#89b4fa", -- same blue as the window borders
      smear_between_buffers = true,
      smear_between_neighbor_lines = true,
      smear_insert_mode = true,
      scroll_buffer_space = true,
      hide_target_hack = true,
      -- ghostty draws the finer "legacy computing" block glyphs itself, so the smear
      -- can use diagonal/sub-cell shapes instead of chunky full blocks
      legacy_computing_symbols_support = true,
      legacy_computing_symbols_support_vertical_bars = true,
      use_diagonal_blocks = true,
      time_interval = 7, -- ~144 fps instead of the default ~60
      -- slightly slower than the defaults: lower = slower, longer trail
      stiffness = 0.5,
      trailing_stiffness = 0.35,
      damping = 0.85,
      distance_stop_animating = 0.5,
    },
  },
}
