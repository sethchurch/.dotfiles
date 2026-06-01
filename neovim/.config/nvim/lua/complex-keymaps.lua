local map = vim.keymap.set

-- [[ Flash.nvim ]]

map(
  "n",
  "<leader>fl",
  function()
    require("flash").jump({
      search = { mode = "search", max_length = 0 },
      label = { after = { 0, 0 } },
      pattern = "^",
    })
  end,
  { desc = "Flash: Jump to line start" }
)

map("n", "<leader>fw", function()
  require("flash").jump({
    search = { mode = function(str) return "\\<" .. str end },
  })
end, { desc = "Flash: Jump to word boundaries" })

map(
  "n",
  "<leader>fW",
  function()
    require("flash").jump({
      search = { multi_window = true },
      labels = "ASDFGHJKL",
    })
  end,
  { desc = "Flash: Multi-window jump" }
)

map("n", "<leader>*", function()
  local word = vim.fn.expand("<cword>")
  require("flash").jump({
    pattern = "\\<" .. word .. "\\>",
    search = { multi_window = false },
  })
end, { desc = "Flash: Jump to word under cursor" })

map("n", "<leader>fz", function() require("flash").jump({ search = { mode = "fuzzy" } }) end, { desc = "Flash: Fuzzy search jump" })

map("n", "<leader>fd", function()
  require("flash").jump({
    matcher = function(win)
      return vim.tbl_map(
        function(diag)
          return {
            pos = { diag.lnum + 1, diag.col },
            end_pos = { diag.end_lnum + 1, diag.end_col - 1 },
          }
        end,
        vim.diagnostic.get(vim.api.nvim_win_get_buf(win))
      )
    end,
    action = function(match, state)
      vim.api.nvim_win_call(match.win, function()
        vim.api.nvim_win_set_cursor(match.win, match.pos)
        vim.diagnostic.open_float()
      end)
      state:restore()
    end,
  })
end, { desc = "Flash: Jump to diagnostics" })

map(
  "n",
  "<leader>fi",
  function()
    require("flash").jump({
      search = { incremental = true },
      label = { after = false, before = true },
    })
  end,
  { desc = "Flash: Incremental search" }
)

map(
  "x",
  "<leader>fs",
  function()
    require("flash").jump({
      search = { mode = "search" },
      jump = { pos = "range" },
    })
  end,
  { desc = "Flash: Visual selection jump" }
)

map("n", "<leader>fc", function()
  local filetype = vim.bo.filetype
  if vim.tbl_contains({ "lua", "python", "javascript", "typescript", "rust", "go" }, filetype) then
    require("flash").treesitter()
    return
  end
  local config = { search = { mode = "exact" } }
  if vim.tbl_contains({ "markdown", "text", "org" }, filetype) then config.search.mode = "fuzzy" end
  require("flash").jump(config)
end, { desc = "Flash: Context-aware jump" })

local flash_bookmarks = {}

map("n", "<leader>fm", function()
  require("flash").jump({
    action = function(match, state)
      local pos = { match.win, match.pos[1], match.pos[2] }
      table.insert(flash_bookmarks, pos)
      print("Bookmarked position " .. #flash_bookmarks)
      state:restore()
    end,
  })
end, { desc = "Flash: Bookmark position" })

map("n", "<leader>fb", function()
  if #flash_bookmarks == 0 then
    print("No bookmarks")
    return
  end
  require("flash").jump({
    matcher = function(win)
      local matches = {}
      for _, bookmark in ipairs(flash_bookmarks) do
        if bookmark[1] == win then
          table.insert(matches, {
            pos = { bookmark[2], bookmark[3] },
            end_pos = { bookmark[2], bookmark[3] + 1 },
          })
        end
      end
      return matches
    end,
    labeler = function(matches, state)
      local labels = {}
      for i, _ in ipairs(matches) do
        labels[i] = tostring(i)
      end
      return
    end,
  })
end, { desc = "Flash: Jump to bookmarks" })

-- [[ Project checks ]]

-- ESLint + TypeScript check (async, with fidget progress)
map("n", "<leader>cl", function()
  local results = {}
  local jobs_completed = 0
  local total_jobs = 2

  local progress = require("fidget.progress")
  local handle = progress.handle.create({
    title = "Validating",
    message = "Starting checks...",
    lsp_client = { name = "PR Checks" },
  })

  local function process_results()
    jobs_completed = jobs_completed + 1
    handle:report({
      message = string.format("Completed %d/%d checks", jobs_completed, total_jobs),
      percentage = (jobs_completed / total_jobs) * 100,
    })

    if jobs_completed == total_jobs then
      vim.fn.setqflist({}, "r", { title = "ESLint & TypeScript", lines = results })
      if #results > 0 then
        vim.cmd("copen")
        handle:finish("Found " .. #results .. " issues")
      else
        handle:finish("All checks passed!")
      end
    end
  end

  vim.fn.jobstart({ "npx", "eslint", "-f", "unix", "--cache", "--fix", "--fix-type", "problem,suggestion,layout", "app/**/*.{js,ts,jsx,tsx}" }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(results, line)
            handle:report({ message = "ESLint: found issues...", percentage = 25 })
          end
        end
      end
    end,
    on_exit = function()
      handle:report({ message = "ESLint complete", percentage = 50 })
      process_results()
    end,
  })

  local function parse_tsc_lines(data)
    if data then
      for _, line in ipairs(data) do
        if line ~= "" and line:match("^[^%s]") then
          local file, lnum, col, msg = line:match("^(.+)%((%d+),(%d+)%):%s*(.+)$")
          if file then
            table.insert(results, string.format("%s:%s:%s: %s", file, lnum, col, msg))
            handle:report({ message = "TypeScript: checking types...", percentage = 75 })
          end
        end
      end
    end
  end

  vim.fn.jobstart({ "npx", "tsc", "--noEmit", "--pretty", "false" }, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      parse_tsc_lines(data)
    end,
    on_stderr = function(_, data)
      parse_tsc_lines(data)
    end,
    on_exit = function()
      handle:report({ message = "TypeScript complete", percentage = 100 })
      process_results()
    end,
  })
end, { desc = "ESLint + TypeScript Check (async)" })

-- Dead code check (async, results in quickfix)
map("n", "<leader>cd", function()
  print("🧹 Running dead code check...")
  vim.system({ "pnpm", "test:dead-code", "--plain" }, { text = true }, function(obj)
    local output = vim.split(obj.stdout or "", "\n", { trimempty = true })
    local hadError = obj.code ~= 0
    vim.schedule(function()
      if hadError and #output > 0 then
        vim.fn.setqflist({}, "r", { title = "Dead Code", lines = output })
        vim.cmd("copen")
        print("🧹 Dead code results loaded into quickfix.")
      else
        print("✅ No dead code found.")
      end
    end)
  end)
end, { desc = "[C]heck [D]ead Code (Async)" })

-- [[ Terminals ]]

-- Test UI terminal (persistent, toggleable)
map("n", "<leader>ct", function()
  local Terminal = require("toggleterm.terminal").Terminal

  if not _G.test_ui_term then
    _G.test_ui_term = Terminal:new({
      cmd = "pnpm test:ui",
      direction = "vertical",
      on_open = function(term)
        vim.cmd("startinsert!")
        local opts = { buffer = term.bufnr, noremap = true }
        vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], opts)
        vim.keymap.set("t", "<C-[>", [[<C-\><C-n>]], opts)
        vim.keymap.set("t", "<C-h>", [[<C-\><C-n><C-w>h]], opts)
        vim.keymap.set("t", "<C-j>", [[<C-\><C-n><C-w>j]], opts)
        vim.keymap.set("t", "<C-k>", [[<C-\><C-n><C-w>k]], opts)
        vim.keymap.set("t", "<C-l>", [[<C-\><C-n><C-w>l]], opts)
        vim.keymap.set("t", "<C-t>", function() term:toggle() end, opts)
        vim.keymap.set("t", "<C-w><C-w>", [[<C-\><C-n><C-w>w]], opts)
        vim.keymap.set("t", "<C-w>p", [[<C-\><C-n><C-w>p]], opts)
      end,
      close_on_exit = false,
      auto_scroll = true,
    })
  end

  _G.test_ui_term:toggle()
end, { desc = "Toggle test:ui terminal" })

-- [[ External tools ]]

local function open_react_devtools() vim.fn.jobstart({ "cmd.exe", "/C", "start", '""', "/B", "react-devtools" }, { detach = true }) end

vim.api.nvim_create_user_command("ReactDevTools", open_react_devtools, { desc = "Launch Windows React DevTools (from WSL)" })
map("n", "<leader>od", open_react_devtools, { desc = "Open React DevTools (Windows standalone)" })
