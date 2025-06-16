local M = {}

-- Function to load all plugins from the custom-plugins directory
function M.load_all()
  local custom_plugins_path = vim.fn.stdpath("config") .. "/lua/custom-plugins"
  local plugins_dir = vim.loop.fs_scandir(custom_plugins_path)

  if not plugins_dir then
    vim.notify("Custom plugins directory not found: " .. custom_plugins_path, vim.log.levels.WARN)
    return
  end

  local loaded_count = 0

  while true do
    local name, type = vim.loop.fs_scandir_next(plugins_dir)
    if not name then break end

    -- Skip init.lua (this file) and non-lua files
    if type == "file" and name:match("%.lua$") and name ~= "init.lua" then
      local module_name = name:gsub("%.lua$", "")
      local success, err = pcall(require, "custom-plugins." .. module_name)

      if success then
        loaded_count = loaded_count + 1
      else
        vim.notify("❌ Failed to load custom plugin " .. module_name .. ": " .. err, vim.log.levels.ERROR)
      end
    end
  end
end

-- Auto-load all plugins when this module is required
M.load_all()

return M
