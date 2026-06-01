-- intl-audit.lua
-- Runs tools/intl-audit.ts and populates quickfix with hardcoded UI strings.
--
-- Commands:
--   :IntlAudit [dir]    Audit a directory (default: app). Dir is relative to cwd.
--   :IntlAuditFile      Audit the current file.
--
-- Keymaps:
--   <leader>la   Audit app/ (or prompt for dir)
--   <leader>lA   Audit current file

local SCRIPT = "tools/intl-audit.ts"

--- Parse a single qf-format line: file:lnum:col:text
--- Returns a qf item table or nil.
local function parse_line(line)
    -- Find first three colons to split file / lnum / col / text.
    -- Linux paths never contain colons so this is unambiguous.
    local i1 = line:find(":", 1, true)
    if not i1 then return nil end
    local i2 = line:find(":", i1 + 1, true)
    if not i2 then return nil end
    local i3 = line:find(":", i2 + 1, true)
    if not i3 then return nil end

    local file = line:sub(1, i1 - 1)
    local lnum = tonumber(line:sub(i1 + 1, i2 - 1))
    local col  = tonumber(line:sub(i2 + 1, i3 - 1))
    local text = line:sub(i3 + 1)

    if not (lnum and col and file ~= "") then return nil end

    -- W = warning (NO MATCH, needs a new key), I = info (already mapped)
    local qtype = text:find("NO MATCH", 1, true) and "W" or "I"

    return { filename = file, lnum = lnum, col = col, text = text, type = qtype }
end

--- Run the audit script asynchronously, populate quickfix, open it.
local function run_audit(args, title)
    local cmd = vim.list_extend({ "npx", "tsx", SCRIPT, "--format", "qf" }, args)

    vim.notify("Intl Audit: scanning...", vim.log.levels.INFO)

    local stdout_lines = {}

    vim.fn.jobstart(cmd, {
        stdout_buffered = true,
        cwd = vim.fn.getcwd(),

        on_stdout = function(_, data)
            if data then vim.list_extend(stdout_lines, data) end
        end,

        on_exit = function(_, _)
            vim.schedule(function()
                local items = {}
                for _, line in ipairs(stdout_lines) do
                    if line ~= "" then
                        local item = parse_line(line)
                        if item then table.insert(items, item) end
                    end
                end

                if #items == 0 then
                    vim.notify("Intl Audit: no hardcoded strings found ✓", vim.log.levels.INFO)
                    return
                end

                -- Count by type
                local unmatched, matched = 0, 0
                for _, item in ipairs(items) do
                    if item.type == "W" then unmatched = unmatched + 1 else matched = matched + 1 end
                end

                vim.fn.setqflist({}, "r", { title = "Intl Audit: " .. title, items = items })
                vim.cmd("copen")

                local msg = string.format(
                    "Intl Audit: %d string(s) found — %d need new keys, %d already mapped",
                    #items, unmatched, matched
                )
                local level = unmatched > 0 and vim.log.levels.WARN or vim.log.levels.INFO
                vim.notify(msg, level)
            end)
        end,
    })
end

-- :IntlAudit [dir]
vim.api.nvim_create_user_command("IntlAudit", function(opts)
    local dir = opts.args ~= "" and opts.args or "app"
    run_audit({ "--dir", dir }, dir)
end, {
    nargs = "?",
    complete = "dir",
    desc = "Intl audit: scan a directory for hardcoded UI strings",
})

-- :IntlAuditFile  (current file, path relative to cwd)
vim.api.nvim_create_user_command("IntlAuditFile", function()
    local file = vim.fn.expand("%:p")
    if file == "" then
        vim.notify("Intl Audit: no file open", vim.log.levels.WARN)
        return
    end
    run_audit({ "--file", file }, vim.fn.expand("%:t"))
end, {
    desc = "Intl audit: scan the current file for hardcoded UI strings",
})

-- <leader>la  — audit, prompting for directory (defaults to "app")
vim.keymap.set("n", "<leader>la", function()
    vim.ui.input({ prompt = "Intl Audit dir (relative, default: app): " }, function(input)
        if input == nil then return end -- cancelled
        local dir = (input == "" and "app" or input)
        run_audit({ "--dir", dir }, dir)
    end)
end, { desc = "Intl [A]udit directory", silent = true })

-- <leader>lA  — audit the current file directly
vim.keymap.set("n", "<leader>lA", function()
    local file = vim.fn.expand("%:p")
    if file == "" then
        vim.notify("Intl Audit: no file open", vim.log.levels.WARN)
        return
    end
    run_audit({ "--file", file }, vim.fn.expand("%:t"))
end, { desc = "Intl [A]udit current file", silent = true })
