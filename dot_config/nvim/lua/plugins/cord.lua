-- ~/.config/nvim/lua/plugins/cord.lua
return {
  {
    "vyfor/cord.nvim",
    build = ":Cord update",
    event = "VeryLazy",

    opts = function()
      -- cache git info
      local git_branch = nil
      local repo_name = nil

      local function update_git_info()
        -- branch
        local ok_b, out_b = pcall(vim.fn.systemlist, { "git", "branch", "--show-current" })
        if ok_b and type(out_b) == "table" then
          local b = (out_b[1] or ""):gsub("%s+$", "")
          git_branch = (b ~= "") and b or nil
        else
          git_branch = nil
        end

        -- repo name from remote.origin.url
        local ok_r, out_r = pcall(vim.fn.systemlist, { "git", "config", "--get", "remote.origin.url" })
        if ok_r and type(out_r) == "table" then
          local url = (out_r[1] or ""):gsub("%s+$", "")
          if url ~= "" then
            local name = url:match("([^/]+)%.git$") or url:match("([^/]+)$")
            repo_name = name or nil
          else
            repo_name = nil
          end
        else
          repo_name = nil
        end
      end

      -- turn Neovim filetype into a short tag
      local function language_tag()
        local ft = vim.bo.filetype or ""
        if ft == "" then
          return ""
        end

        local map = {
          typescript = "TS",
          typescriptreact = "TSX",
          javascript = "JS",
          javascriptreact = "JSX",
          lua = "Lua",
          rust = "Rust",
          html = "HTML",
          css = "CSS",
          scss = "SCSS",
          json = "JSON",
          markdown = "MD",
        }

        return map[ft] or ft
      end

      -- count diagnostics in current buffer (WARN+)
      local function get_diag_count()
        if not vim.diagnostic or not vim.diagnostic.get then
          return 0
        end

        local ok, diags = pcall(vim.diagnostic.get, 0, {
          severity = { min = vim.diagnostic.severity.WARN },
        })

        if not ok or type(diags) ~= "table" then
          return 0
        end

        return #diags
      end

      -- pretty suffix like " · ⚠2"
      local function diag_suffix()
        local count = get_diag_count()
        if count <= 0 then
          return ""
        end
        return string.format(" · ⚠%d", count)
      end

      -- run once at startup
      update_git_info()

      local v = vim.version()
      local nvim_version = string.format("%d.%d.%d", v.major, v.minor, v.patch)

      return {
        editor = {
          client = "neovim",
          tooltip = "Neovim " .. nvim_version,
        },

        display = {
          theme = "default",
          flavor = "dark",
          view = "full",
          swap_fields = false,
          swap_icons = false,
        },

        idle = {
          enabled = true,
          timeout = 5 * 60 * 1000, -- 5 minutes
          show_status = true,
          ignore_focus = true,
          unidle_on_focus = true,
          smart_idle = true,
          details = "Idling",
        },

        text = {
          -- 2nd line: just repo + branch (no duplication of problems)
          workspace = function(opts)
            local ws = repo_name or opts.workspace or "No project"
            local branch = git_branch and (" (" .. git_branch .. ")") or ""
            return ws .. branch
          end,

          -- 1st line: LANG · file · Lx:Cy · ⚠N
          editing = function(opts)
            local filename = opts.filename or "untitled"
            local line = opts.cursor_line or 0
            local col = opts.cursor_char or 0
            local lang = language_tag()
            local parts = {}

            if lang ~= "" then
              table.insert(parts, lang)
            end
            table.insert(parts, filename)
            table.insert(parts, string.format("L%d:%d", line, col))

            local base = table.concat(parts, " · ")
            return base .. diag_suffix()
          end,

          viewing = function(opts)
            local filename = opts.filename or "buffer"
            local lang = language_tag()
            local parts = {}

            if lang ~= "" then
              table.insert(parts, lang)
            end
            table.insert(parts, filename)

            local base = table.concat(parts, " · ")
            return base .. diag_suffix()
          end,
        },

        hooks = {
          workspace_change = function()
            update_git_info()
          end,
        },

        buttons = {
          {
            label = function(opts)
              if opts.repo_url then
                return "View Repository"
              end
              return "konnatoad on GitHub"
            end,
            url = function(opts)
              return opts.repo_url or "https://github.com/konnatoad"
            end,
          },
        },

        -- no extra cord plugins; we use vim.diagnostic directly
        plugins = {},
      }
    end,
  },
}
