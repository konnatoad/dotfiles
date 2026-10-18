-- minimal start screen: greeting, recent files, one line of key hints.
-- every row is custom text so none of the stock snacks/lazyvim layout shows through
-- highlight groups: blue keys, plain names, dim everything else
local KEY, TEXT, DIM = "Function", "Normal", "SnacksDashboardDir"
local W = 62

local function greeting()
  local h = tonumber(os.date("%H"))
  local part = h < 5 and "night" or h < 12 and "morning" or h < 18 and "afternoon" or "evening"
  return {
    text = {
      { part .. ", ", hl = DIM },
      { "konna", hl = KEY },
      { os.date("%a %d %b"):lower(), hl = DIM, width = W - #part - 7, align = "right" },
    },
  }
end

local function rule()
  return { text = { { ("─"):rep(W), hl = DIM } }, padding = 1 }
end

local function recent()
  local items = { { text = { { "recent", hl = DIM } }, padding = 1 } }
  local n = 0
  for file in Snacks.dashboard.oldfiles() do
    n = n + 1
    local name = vim.fn.fnamemodify(file, ":t")
    local dir = vim.fn.fnamemodify(file, ":~:h")
    if #dir > 30 then
      dir = "…/" .. dir:match("([^/]+/[^/]+)$")
    end
    items[#items + 1] = {
      key = tostring(n),
      action = ":e " .. vim.fn.fnameescape(file),
      text = {
        { tostring(n), hl = KEY, width = 4 },
        { name, hl = TEXT, width = W - 4 - 30 },
        { dir, hl = DIM, width = 30, align = "right" },
      },
    }
    if n >= 6 then
      break
    end
  end
  items[#items].padding = 1
  return items
end

-- key, label, action; shown as one hint row, bound via hidden items
-- stylua: ignore
local actions = {
  { "f", "find",    ":lua Snacks.dashboard.pick('files')" },
  { "g", "grep",    ":lua Snacks.dashboard.pick('live_grep')" },
  { "n", "new",     ":ene | startinsert" },
  { "p", "projects", ":lua Snacks.picker.projects()" },
  { "s", "server",  ":lua Snacks.picker.files({ cwd = '/mnt/server' })" },
  { "c", "config",  ":lua Snacks.dashboard.pick('files', { cwd = vim.fn.stdpath('config') })" },
  { "q", "quit",    ":qa" },
}

local function hints()
  local text = {}
  local items = {}
  for i, a in ipairs(actions) do
    text[#text + 1] = { a[1], hl = KEY }
    text[#text + 1] = { " " .. a[2] .. (i < #actions and "  " or ""), hl = DIM }
    items[#items + 1] = { key = a[1], action = a[3], hidden = true }
  end
  -- session restore and lazy stay reachable, just not advertised
  items[#items + 1] = { key = "S", section = "session", hidden = true }
  items[#items + 1] = { key = "l", action = ":Lazy", hidden = true }
  table.insert(items, 1, { text = text, align = "center" })
  return items
end

return {
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        width = W,
        sections = { greeting, rule, recent, hints },
      },
    },
  },
}
