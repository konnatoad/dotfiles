local map = vim.keymap.set
local builtin = require("telescope.builtin")

map("n", "<leader>ms", function()
  builtin.find_files({ cwd = "/mnt/server" })
end, { desc = "Find files in /mnt/server" })
