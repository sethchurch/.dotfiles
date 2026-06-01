-- intl-unused.lua
-- Find keys in en-US locale that are not referenced anywhere in app/.
--
-- Commands:
--   :IntlUnused    Scan for unused en-US keys and populate quickfix.
--
-- Keymaps:
--   <leader>lx   Find unused en-US keys

local LOCALE_NAME = "en-US"

local function run_unused()
    local cwd = vim.fn.getcwd()
    local locale_path = cwd .. "/app/locales/" .. LOCALE_NAME .. ".json"

    if not vim.uv.fs_stat(locale_path) then
        vim.notify("Intl Unused: locale file not found: app/locales/" .. LOCALE_NAME .. ".json", vim.log.levels.WARN)
        return
    end

    local read_ok, file_lines = pcall(vim.fn.readfile, locale_path)
    if not read_ok then
        vim.notify("Intl Unused: could not read locale file", vim.log.levels.ERROR)
        return
    end

    local decode_ok, locale_data = pcall(vim.json.decode, table.concat(file_lines, "\n"))
    if not decode_ok or not locale_data then
        vim.notify("Intl Unused: could not parse locale file", vim.log.levels.ERROR)
        return
    end

    local all_keys = {}
    for k in pairs(locale_data) do
        table.insert(all_keys, k)
    end
    table.sort(all_keys)

    if #all_keys == 0 then
        vim.notify("Intl Unused: locale file is empty", vim.log.levels.INFO)
        return
    end

    vim.notify(string.format("Intl Unused: checking %d keys...", #all_keys), vim.log.levels.INFO)

    -- Write every key as three patterns ("key", 'key', `key`) to a temp file so
    -- rg can do a single fixed-string pass over all source files.  This catches
    -- every usage pattern: id: "key", id="key", <FormattedMessage id="key" />, etc.
    local tmpfile = vim.fn.tempname()
    local patterns = {}
    for _, key in ipairs(all_keys) do
        table.insert(patterns, '"' .. key .. '"')
        table.insert(patterns, "'" .. key .. "'")
        table.insert(patterns, "`" .. key .. "`")
    end
    vim.fn.writefile(patterns, tmpfile)

    local stdout_lines = {}

    vim.fn.jobstart(
        { "rg", "--no-filename", "-o", "-F",
          "-f", tmpfile,
          cwd .. "/app",
          "--glob", "!**/locales/*.json" },
        {
            stdout_buffered = true,
            cwd = cwd,

            on_stdout = function(_, data)
                if data then vim.list_extend(stdout_lines, data) end
            end,

            on_exit = function(_, _)
                vim.fn.delete(tmpfile)
                vim.schedule(function()
                    -- Each matched line is exactly one of our patterns: "key", 'key', or `key`.
                    -- Strip the surrounding quote character to recover the key.
                    local used = {}
                    for _, line in ipairs(stdout_lines) do
                        local key = line:match('^["\x27`](.+)["\x27`]$')
                        if key and key ~= "" then
                            used[key] = true
                        end
                    end

                    -- Build quickfix items for every key not found in source
                    local items = {}
                    for _, key in ipairs(all_keys) do
                        if not used[key] then
                            -- Locate the key in the JSON file for jump-to support
                            local lnum = 1
                            local encoded = vim.fn.json_encode(key)
                            for i, l in ipairs(file_lines) do
                                if l:find(encoded, 1, true) then
                                    lnum = i
                                    break
                                end
                            end
                            local val = locale_data[key] or ""
                            local truncated = #val > 60 and val:sub(1, 57) .. "..." or val
                            table.insert(items, {
                                filename = locale_path,
                                lnum     = lnum,
                                col      = 1,
                                text     = key .. '  →  "' .. truncated .. '"',
                                type     = "W",
                            })
                        end
                    end

                    if #items == 0 then
                        vim.notify("Intl Unused: no unused keys ✓", vim.log.levels.INFO)
                        return
                    end

                    vim.fn.setqflist({}, "r", {
                        title = string.format("Intl Unused (%s): %d unused", LOCALE_NAME, #items),
                        items = items,
                    })
                    vim.cmd("copen")
                    vim.notify(
                        string.format("Intl Unused: %d unused key(s) in %s", #items, LOCALE_NAME),
                        vim.log.levels.WARN
                    )
                end)
            end,
        }
    )
end

local function write_sorted_locale(path, data)
    local sorted_keys = vim.tbl_keys(data)
    table.sort(sorted_keys)
    local out = { "{" }
    for i, key in ipairs(sorted_keys) do
        local comma = i < #sorted_keys and "," or ""
        table.insert(out, "    " .. vim.fn.json_encode(key) .. ": " .. vim.fn.json_encode(data[key]) .. comma)
    end
    table.insert(out, "}")
    table.insert(out, "")
    return pcall(vim.fn.writefile, out, path)
end

local function purge_unused()
    local qflist = vim.fn.getqflist()
    if #qflist == 0 then
        vim.notify("Intl Unused: quickfix list is empty — run :IntlUnused first", vim.log.levels.WARN)
        return
    end

    -- Extract keys from quickfix items produced by run_unused().
    -- item.text looks like: "some.key  →  \"the value\""
    -- The arrow is the unicode character →, not ASCII ->
    local keys_to_remove = {}
    for _, item in ipairs(qflist) do
        local key = item.text:match("^(.-)  →  ")
        if key and key ~= "" then
            table.insert(keys_to_remove, key)
        end
    end

    if #keys_to_remove == 0 then
        vim.notify("Intl Unused: no removable keys found in quickfix list", vim.log.levels.WARN)
        return
    end

    -- Remove from every locale JSON file in app/locales/
    local locales_dir = vim.fn.getcwd() .. "/app/locales"
    local handle = vim.uv.fs_scandir(locales_dir)
    if not handle then
        vim.notify("Intl Unused: could not open " .. locales_dir, vim.log.levels.ERROR)
        return
    end

    local files_changed = 0
    while true do
        local name, t = vim.uv.fs_scandir_next(handle)
        if not name then break end
        if t == "file" and name:match("%.json$") then
            local path = locales_dir .. "/" .. name
            local read_ok, lines = pcall(vim.fn.readfile, path)
            if read_ok then
                local decode_ok, data = pcall(vim.json.decode, table.concat(lines, "\n"))
                if decode_ok and data then
                    local changed = false
                    for _, key in ipairs(keys_to_remove) do
                        if data[key] ~= nil then
                            data[key] = nil
                            changed = true
                        end
                    end
                    if changed then
                        write_sorted_locale(path, data)
                        files_changed = files_changed + 1
                    end
                end
            end
        end
    end

    vim.fn.setqflist({}, "r", { title = "Intl Unused: cleared", items = {} })
    vim.notify(string.format("Intl Unused: removed %d key(s) from %d locale file(s)", #keys_to_remove, files_changed), vim.log.levels.INFO)
end

vim.api.nvim_create_user_command("IntlUnused", function()
    run_unused()
end, {
    desc = "Find unused keys in " .. LOCALE_NAME .. " locale",
})

vim.api.nvim_create_user_command("IntlUnusedPurge", function()
    purge_unused()
end, {
    desc = "Remove all keys in the current quickfix list from the locale file",
})

vim.keymap.set("n", "<leader>lx",  run_unused,   { desc = "Intl Unused: find unused [x] keys",   silent = true })
vim.keymap.set("n", "<leader>lX",  purge_unused, { desc = "Intl Unused: purge unused keys",       silent = true })
