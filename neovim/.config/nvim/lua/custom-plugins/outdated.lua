-- Add this directly to your init.lua or wherever you have your pnpm_commands function
local function pnpm_outdated()
  local package_json_path = vim.fn.getcwd() .. "/package.json"

  -- Check if package.json exists
  if vim.fn.filereadable(package_json_path) == 0 then
    vim.notify("No package.json found in current directory", vim.log.levels.ERROR)
    return
  end

  -- Read package.json for line matching
  local package_json_lines = vim.fn.readfile(package_json_path)

  -- Helper function to find package line in package.json
  local function find_package_line(package_name, lines)
    local in_deps = false
    local in_dev_deps = false
    local brace_count = 0

    for i, line in ipairs(lines) do
      -- Check if we're entering dependencies section
      if line:match('"dependencies"') then
        in_deps = true
        in_dev_deps = false
        brace_count = 0
      elseif line:match('"devDependencies"') then
        in_dev_deps = true
        in_deps = false
        brace_count = 0
      elseif line:match('"peerDependencies"') or line:match('"optionalDependencies"') then
        in_deps = false
        in_dev_deps = false
      end

      -- Track braces to know when we exit a section
      if in_deps or in_dev_deps then
        for c in line:gmatch("[{}]") do
          if c == "{" then
            brace_count = brace_count + 1
          else
            brace_count = brace_count - 1
            if brace_count <= 0 then
              in_deps = false
              in_dev_deps = false
            end
          end
        end
      end

      -- Look for the package in the current line
      if (in_deps or in_dev_deps) and line:match('"' .. vim.fn.escape(package_name, "^$.*[]~\\") .. '"') then return i end
    end

    return nil
  end

  local qf_items = {}
  local stdout_data = {}

  -- Check if pnpm is available
  if vim.fn.executable("pnpm") == 0 then
    vim.notify("pnpm is not installed or not in PATH", vim.log.levels.ERROR)
    return
  end

  vim.notify("Checking for outdated packages...", vim.log.levels.INFO)

  -- Run pnpm outdated with JSON format
  local job_id = vim.fn.jobstart({ "pnpm", "outdated", "--format", "json" }, {
    on_stdout = function(job_id, data, event)
      if data then vim.list_extend(stdout_data, data) end
    end,
    on_exit = function(job_id, exit_code, event)
      -- if exit_code ~= 0 then
      --   local err_msg = "pnpm outdated failed with exit code: " .. exit_code .. "\nOutput: " .. table.concat(stdout_data, "\n")
      --   vim.notify(err_msg, vim.log.levels.ERROR)
      --   return
      -- end
      --

      -- Join all stdout data
      local json_str = table.concat(stdout_data, "")

      -- Check first line for warnings and remove
      json_str = json_str:gsub("^Warning.*\n", "")

      -- Remove any empty strings
      json_str = json_str:gsub("^%s*", ""):gsub("%s*$", "")

      if json_str == "" then
        vim.notify("No outdated packages found!", vim.log.levels.INFO)
        return
      end

      -- Parse JSON
      local ok, outdated = pcall(vim.json.decode, json_str)
      if not ok then
        vim.notify("Failed to parse pnpm outdated JSON output: " .. tostring(outdated), vim.log.levels.ERROR)
        return
      end

      -- Create quickfix entries
      for package_name, info in pairs(outdated) do
        local line_num = find_package_line(package_name, package_json_lines)

        if line_num then
          local dep_type = ""
          if info.dependencyType == "devDependencies" then
            dep_type = " (dev)"
          elseif info.dependencyType == "peerDependencies" then
            dep_type = " (peer)"
          elseif info.dependencyType == "optionalDependencies" then
            dep_type = " (optional)"
          end

          local text = string.format(
            "%s%s: %s → %s (latest: %s)",
            package_name,
            dep_type,
            info.current or "?",
            info.wanted or info.current or "?",
            info.latest or "?"
          )

          if info.isDeprecated then text = text .. " [DEPRECATED]" end

          table.insert(qf_items, {
            filename = package_json_path,
            lnum = line_num,
            col = 1,
            text = text,
            type = info.isDeprecated and "W" or "I",
          })
        else
          -- Package not found in package.json (might be indirect dependency)
          local text = string.format(
            "%s: %s → %s (latest: %s) [indirect]",
            package_name,
            info.current or "?",
            info.wanted or info.current or "?",
            info.latest or "?"
          )

          table.insert(qf_items, {
            filename = package_json_path,
            lnum = 1,
            col = 1,
            text = text,
            type = "I",
          })
        end
      end

      if #qf_items > 0 then
        -- Sort items by line number
        table.sort(qf_items, function(a, b) return a.lnum < b.lnum end)

        -- Set quickfix list
        vim.fn.setqflist({}, " ", {
          title = "pnpm outdated packages",
          items = qf_items,
        })

        -- Open quickfix window
        vim.cmd("copen")

        -- Print summary
        local deprecated_count = 0
        local update_count = 0
        for _, item in ipairs(qf_items) do
          if item.type == "W" then
            deprecated_count = deprecated_count + 1
          else
            update_count = update_count + 1
          end
        end

        local msg = string.format("Found %d outdated package(s)", #qf_items)
        if deprecated_count > 0 then msg = msg .. string.format(" (%d deprecated)", deprecated_count) end
        vim.notify(msg, vim.log.levels.INFO)
      else
        vim.notify("No outdated packages found!", vim.log.levels.INFO)
      end
    end,
    stdout_buffered = true,
    cwd = vim.fn.getcwd(),
  })

  if job_id <= 0 then vim.notify("Failed to start pnpm outdated", vim.log.levels.ERROR) end
end

-- Create the command
vim.api.nvim_create_user_command("PnpmOutdated", pnpm_outdated, {
  desc = "Check for outdated pnpm packages and populate quickfix",
})

-- Create the keybinding
vim.keymap.set("n", "<leader>cU", pnpm_outdated, {
  desc = "Check pnpm outdated packages",
  silent = true,
})
