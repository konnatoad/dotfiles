-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt

opt.scrolloff = 8 -- keep context above/below the cursor
opt.sidescrolloff = 8
opt.wrap = false
opt.cursorline = true
opt.relativenumber = true

opt.winborder = "rounded" -- rounded borders on every floating window
opt.pumblend = 0 -- no blend so the transparent background stays clean
opt.fillchars:append({ eob = " " }) -- hide the ~ on empty lines
