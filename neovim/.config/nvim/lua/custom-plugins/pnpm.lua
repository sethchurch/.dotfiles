-- Add this to your Neovim config (init.lua or a separate file)

local function pnpm_commands()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  -- Read package.json
  local package_json_path = vim.fn.getcwd() .. "/package.json"
  local file = io.open(package_json_path, "r")

  if not file then
    vim.notify("No package.json found in current directory", vim.log.levels.ERROR)
    return
  end

  local content = file:read("*all")
  file:close()

  -- Parse JSON (simple parsing for scripts section)
  local scripts = {}
  local json_ok, json = pcall(vim.fn.json_decode, content)

  if json_ok and json.scripts then
    for script_name, script_cmd in pairs(json.scripts) do
      table.insert(scripts, {
        name = script_name,
        command = script_cmd,
        display = script_name .. " → " .. script_cmd,
      })
    end
  else
    vim.notify("Could not parse package.json or no scripts found", vim.log.levels.ERROR)
    return
  end

  if #scripts == 0 then
    vim.notify("No scripts found in package.json", vim.log.levels.WARN)
    return
  end

  -- Create telescope picker
  pickers
    .new({}, {
      prompt_title = "PNPM Scripts",
      finder = finders.new_table({
        results = scripts,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.display,
            ordinal = entry.name,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()

          -- Run the selected pnpm command
          local cmd = "pnpm run " .. selection.value.name
          vim.notify("Running: " .. cmd)

          -- Option 1: Run in terminal (opens terminal window)
          -- vim.cmd("terminal " .. cmd)

          -- Option 2: Run in background (uncomment to use instead)
          -- vim.fn.system(cmd)
          -- vim.notify("Command completed: " .. cmd)

          -- Option 3: Run with async job (uncomment to use instead)
          vim.fn.jobstart(cmd, {
            on_exit = function(_, exit_code)
              if exit_code == 0 then
                vim.notify("✅ " .. cmd .. " completed successfully")
              else
                vim.notify("❌ " .. cmd .. " failed with exit code " .. exit_code, vim.log.levels.ERROR)
              end
            end,
          })
        end)

        return true
      end,
    })
    :find()
end

-- Create the command
vim.api.nvim_create_user_command("PnpmCommands", pnpm_commands, {})

-- Optional: Create a keybinding
vim.keymap.set("n", "<leader>sp", pnpm_commands, { desc = "[P]NPM" })
