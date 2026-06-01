local M = {}

local DEBOUNCE_MS = 300

local QUERY_STRING = [[
(call_expression
  function: [
    (identifier) @_fn (#eq? @_fn "formatMessage")
    (member_expression
      property: (property_identifier) @_fn (#eq? @_fn "formatMessage"))
  ]
  arguments: (arguments
    (object
      (pair
        key: (property_identifier) @_key (#eq? @_key "id")
        value: (string (string_fragment) @translation_id)))))
]]

local _compiled_queries = {}

M.state = {
  enabled = false,
  translations = {},
  active_locale = "en-US",
  locales = {},
  ns = nil,
  watcher = nil,
  debounce_timers = {},
  autocmd_group = nil,
}

local function get_query(lang)
  if _compiled_queries[lang] then return _compiled_queries[lang] end
  local ok, q = pcall(vim.treesitter.query.parse, lang, QUERY_STRING)
  if ok then
    _compiled_queries[lang] = q
    return q
  end
  return nil
end

function M.is_target_ft(bufnr)
  local ft = vim.bo[bufnr].filetype
  return ft == "typescript" or ft == "typescriptreact"
end

function M.discover_locales()
  local dir = vim.fn.getcwd() .. "/app/locales"
  local handle = vim.uv.fs_scandir(dir)
  if not handle then return {} end
  local locales = {}
  while true do
    local name, t = vim.uv.fs_scandir_next(handle)
    if not name then break end
    if t == "file" and name:match("%.json$") then
      table.insert(locales, (name:gsub("%.json$", "")))
    end
  end
  table.sort(locales)
  return locales
end

function M.find_locale_path(locale_name)
  locale_name = locale_name or M.state.active_locale
  local candidate = vim.fn.getcwd() .. "/app/locales/" .. locale_name .. ".json"
  return vim.uv.fs_stat(candidate) and candidate or nil
end

function M.load_locale(locale_name)
  local path = M.find_locale_path(locale_name)
  if not path then
    M.state.translations = {}
    return
  end
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then return end
  local decoded_ok, data = pcall(vim.json.decode, table.concat(lines, "\n"))
  if decoded_ok then M.state.translations = data end
end

function M.watch_locale()
  if M.state.watcher then
    M.state.watcher:stop()
    M.state.watcher:close()
    M.state.watcher = nil
  end
  local path = M.find_locale_path()
  if not path then return end
  local w = vim.uv.new_fs_event()
  w:start(path, {}, vim.schedule_wrap(function(err)
    if err then return end
    M.load_locale()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) and M.is_target_ft(buf) then
        M.debounced_render(buf)
      end
    end
    -- Restart watcher: atomic saves (nvim :w) replace the inode,
    -- so the old handle stops tracking after the first event.
    M.watch_locale()
  end))
  M.state.watcher = w
end

function M.render(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, M.state.ns, 0, -1)
  if not M.state.enabled or not M.is_target_ft(bufnr) then return end

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok then return end
  parser:parse()

  parser:for_each_tree(function(tree, ltree)
    local lang = ltree:lang()
    if lang ~= "typescript" and lang ~= "tsx" then return end
    local query = get_query(lang)
    if not query then return end

    for cap_id, node in query:iter_captures(tree:root(), bufnr, 0, -1) do
      if query.captures[cap_id] == "translation_id" then
        local key = vim.treesitter.get_node_text(node, bufnr)
        local val = M.state.translations[key]
        local display
        if val then
          local truncated = val:len() > 60 and val:sub(1, 57) .. "..." or val
          display = '→ "' .. truncated .. '"'
        else
          display = "→ ??"
        end

        local call_node = node
        while call_node and call_node:type() ~= "call_expression" do
          call_node = call_node:parent()
        end
        if not call_node then goto next_cap end

        local _row, _col, end_row, _end_col = call_node:range()

        pcall(vim.api.nvim_buf_set_extmark, bufnr, M.state.ns, end_row, 0, {
          virt_text = { { display, "IntlLensValue" } },
          virt_text_pos = "eol",
          hl_mode = "combine",
        })

        ::next_cap::
      end
    end
  end)
end

function M.debounced_render(bufnr)
  local t = M.state.debounce_timers[bufnr]
  if t then
    t:stop()
    t:close()
  end
  t = vim.uv.new_timer()
  t:start(DEBOUNCE_MS, 0, vim.schedule_wrap(function()
    t:stop()
    t:close()
    M.state.debounce_timers[bufnr] = nil
    M.render(bufnr)
  end))
  M.state.debounce_timers[bufnr] = t
end

-- Shared helper: find the translation key under the cursor via treesitter
function M.get_key_at_cursor()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_row = cursor[1] - 1  -- 0-indexed
  local cursor_col = cursor[2]

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok then return nil end
  parser:parse()

  local result = nil
  parser:for_each_tree(function(tree, ltree)
    if result then return end
    local lang = ltree:lang()
    if lang ~= "typescript" and lang ~= "tsx" then return end
    local query = get_query(lang)
    if not query then return end

    for cap_id, node in query:iter_captures(tree:root(), bufnr, 0, -1) do
      if query.captures[cap_id] == "translation_id" then
        local call_node = node
        while call_node and call_node:type() ~= "call_expression" do
          call_node = call_node:parent()
        end
        if not call_node then goto next_cap end

        local row, col, end_row, end_col = call_node:range()
        local in_range = (cursor_row > row or (cursor_row == row and cursor_col >= col))
          and (cursor_row < end_row or (cursor_row == end_row and cursor_col <= end_col))

        if in_range then
          local key = vim.treesitter.get_node_text(node, bufnr)
          result = { key = key, row = row, col = col }
          return
        end

        ::next_cap::
      end
    end
  end)

  return result
end

function M.jump_to_source()
  local info = M.get_key_at_cursor()
  if not info then
    vim.notify("Intl Lens: no translation key under cursor", vim.log.levels.WARN)
    return
  end
  local path = M.find_locale_path()
  if not path then
    vim.notify("Intl Lens: locale file not found", vim.log.levels.WARN)
    return
  end

  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    vim.notify("Intl Lens: could not read locale file", vim.log.levels.ERROR)
    return
  end

  local key_encoded = vim.fn.json_encode(info.key)
  local target_lnum = nil
  for i, line in ipairs(lines) do
    if line:find(key_encoded, 1, true) then
      target_lnum = i
      break
    end
  end

  vim.cmd.edit(path)
  if target_lnum then
    vim.api.nvim_win_set_cursor(0, { target_lnum, 0 })
    vim.cmd("normal! zz")
  end
end

-- Serialize a flat {string→string} table as alphabetically-sorted JSON.
-- Produces 2-space indented output matching standard locale file style.
local function write_sorted_locale(path, data)
  local keys = vim.tbl_keys(data)
  table.sort(keys)
  local out = { "{" }
  for i, key in ipairs(keys) do
    local comma = i < #keys and "," or ""
    table.insert(out, "    " .. vim.fn.json_encode(key) .. ": " .. vim.fn.json_encode(data[key]) .. comma)
  end
  table.insert(out, "}")
  table.insert(out, "")  -- trailing newline (writefile joins with \n)
  return pcall(vim.fn.writefile, out, path)
end

function M.edit_translation()
  local info = M.get_key_at_cursor()
  if not info then
    vim.notify("Intl Lens: no translation key under cursor", vim.log.levels.WARN)
    return
  end
  local path = M.find_locale_path()
  if not path then
    vim.notify("Intl Lens: locale file not found", vim.log.levels.WARN)
    return
  end

  local current_val = M.state.translations[info.key] or ""

  vim.ui.input(
    { prompt = "Edit [" .. info.key .. "]: ", default = current_val },
    function(new_val)
      if new_val == nil then return end  -- cancelled

      local ok, lines = pcall(vim.fn.readfile, path)
      if not ok then
        vim.notify("Intl Lens: could not read locale file", vim.log.levels.ERROR)
        return
      end

      local decoded_ok, data = pcall(vim.json.decode, table.concat(lines, "\n"))
      if not decoded_ok then
        vim.notify("Intl Lens: could not parse locale file", vim.log.levels.ERROR)
        return
      end

      data[info.key] = new_val

      local write_ok = write_sorted_locale(path, data)
      if not write_ok then
        vim.notify("Intl Lens: could not write locale file", vim.log.levels.ERROR)
        return
      end

      M.load_locale()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) and M.is_target_ft(buf) then
          M.debounced_render(buf)
        end
      end
    end
  )
end

function M.pick_translations()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local bufnr = vim.api.nvim_get_current_buf()
  if not M.is_target_ft(bufnr) then
    vim.notify("Intl Lens: not a TypeScript buffer", vim.log.levels.WARN)
    return
  end

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok then return end
  parser:parse()

  local entries = {}
  parser:for_each_tree(function(tree, ltree)
    local lang = ltree:lang()
    if lang ~= "typescript" and lang ~= "tsx" then return end
    local query = get_query(lang)
    if not query then return end

    for cap_id, node in query:iter_captures(tree:root(), bufnr, 0, -1) do
      if query.captures[cap_id] == "translation_id" then
        local key = vim.treesitter.get_node_text(node, bufnr)
        local val = M.state.translations[key] or "??"
        local node_row, node_col = node:range()
        local call_node = node
        while call_node and call_node:type() ~= "call_expression" do
          call_node = call_node:parent()
        end
        local lnum = call_node and select(1, call_node:range()) or node_row
        table.insert(entries, { key = key, value = val, lnum = lnum, col = node_col })
      end
    end
  end)

  if #entries == 0 then
    vim.notify("Intl Lens: no translations found in buffer", vim.log.levels.WARN)
    return
  end

  pickers.new({}, {
    prompt_title = "Intl Lens — " .. M.state.active_locale,
    finder = finders.new_table({
      results = entries,
      entry_maker = function(entry)
        return {
          value = entry,
          display = string.format("%-45s  %s", entry.key, entry.value),
          ordinal = entry.key .. entry.value,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          vim.api.nvim_win_set_cursor(0, { selection.value.lnum + 1, selection.value.col })
          vim.cmd("normal! zz")
        end
      end)

      -- <C-g>: jump to JSON source
      map("i", "<C-g>", function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if not selection then return end
        local path = M.find_locale_path()
        if not path then
          vim.notify("Intl Lens: locale file not found", vim.log.levels.WARN)
          return
        end
        local read_ok, lines = pcall(vim.fn.readfile, path)
        if not read_ok then return end
        local key_encoded = vim.fn.json_encode(selection.value.key)
        local target_lnum = nil
        for i, line in ipairs(lines) do
          if line:find(key_encoded, 1, true) then
            target_lnum = i
            break
          end
        end
        vim.cmd.edit(path)
        if target_lnum then
          vim.api.nvim_win_set_cursor(0, { target_lnum, 0 })
          vim.cmd("normal! zz")
        end
      end)

      -- <C-e>: close picker and edit translation
      map("i", "<C-e>", function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if not selection then return end
        vim.api.nvim_win_set_cursor(0, { selection.value.lnum + 1, selection.value.col })
        M.edit_translation()
      end)

      return true
    end,
  }):find()
end

-- Run ripgrep for key and populate quickfix, then open it.
local function open_usages_qf(key)
  -- Escape regex metacharacters in key (dots are common in intl ids)
  local escaped = key:gsub("[%.%(%)%[%]%*%+%?%^%$%{%}%|%\\]", "\\%1")
  -- Match key wrapped in any quote style: "key" 'key' `key`
  local pattern = vim.fn.shellescape('["\'`]' .. escaped .. '["\'`]')
  local results = vim.fn.systemlist(
    "rg --vimgrep " .. pattern .. " " .. vim.fn.shellescape(vim.fn.getcwd() .. "/app")
  )
  if #results == 0 then
    vim.notify("Intl Lens: no usages found for \"" .. key .. "\"", vim.log.levels.INFO)
    return
  end
  local json_items = {}
  local other_items = {}
  for _, line in ipairs(results) do
    local file, lnum, col, text = line:match("^(.+):(%d+):(%d+):(.*)$")
    if file then
      local item = { filename = file, lnum = tonumber(lnum), col = tonumber(col), text = text }
      if file:match("%.json$") then
        table.insert(json_items, item)
      else
        table.insert(other_items, item)
      end
    end
  end
  if #json_items == 0 and #other_items == 0 then
    vim.notify("Intl Lens: no usages found for \"" .. key .. "\"", vim.log.levels.INFO)
    return
  end
  -- JSON source always first, then TSX/TS usages
  local qflist = {}
  vim.list_extend(qflist, json_items)
  vim.list_extend(qflist, other_items)
  vim.fn.setqflist({}, "r", { title = "Intl: " .. key, items = qflist })
  vim.cmd("copen")
end

function M.copy_key()
  local info = M.get_key_at_cursor()
  if not info then
    vim.notify("Intl Lens: no translation key under cursor", vim.log.levels.WARN)
    return
  end
  vim.fn.setreg("+", info.key)
  vim.notify('Intl Lens: copied "' .. info.key .. '"')
end

function M.rename_key()
  local info = M.get_key_at_cursor()
  if not info then
    vim.notify("Intl Lens: no translation key under cursor", vim.log.levels.WARN)
    return
  end

  vim.ui.input({ prompt = "Rename [" .. info.key .. "] to: ", default = info.key }, function(new_key)
    if not new_key or new_key == "" or new_key == info.key then return end

    -- 1. Rename in every locale JSON file
    local locales_dir = vim.fn.getcwd() .. "/app/locales"
    local handle = vim.uv.fs_scandir(locales_dir)
    local locale_files_changed = 0
    if handle then
      while true do
        local name, t = vim.uv.fs_scandir_next(handle)
        if not name then break end
        if t == "file" and name:match("%.json$") then
          local path = locales_dir .. "/" .. name
          local ok, lines = pcall(vim.fn.readfile, path)
          if ok then
            local dok, data = pcall(vim.json.decode, table.concat(lines, "\n"))
            if dok and data[info.key] ~= nil then
              data[new_key] = data[info.key]
              data[info.key] = nil
              write_sorted_locale(path, data)
              locale_files_changed = locale_files_changed + 1
            end
          end
        end
      end
    end

    -- 2. Find and rewrite all TS/TSX files containing the old key
    local escaped_rg = info.key:gsub("[%.%(%)%[%]%*%+%?%^%$%{%}%|%\\]", "\\%1")
    local rg_pattern = vim.fn.shellescape('["\'`]' .. escaped_rg .. '["\'`]')
    local src_files = vim.fn.systemlist(
      "rg --files-with-matches " .. rg_pattern .. " " .. vim.fn.shellescape(vim.fn.getcwd() .. "/app")
    )

    local src_files_changed = 0
    for _, filepath in ipairs(src_files) do
      if not filepath:match("%.json$") then
        local ok, lines = pcall(vim.fn.readfile, filepath)
        if ok then
          local changed = false
          local escaped_lua = vim.pesc(info.key)
          for i, line in ipairs(lines) do
            local new_line = line
            for _, q in ipairs({ '"', "'", "`" }) do
              new_line = new_line:gsub(q .. escaped_lua .. q,
                function() return q .. new_key .. q end)
            end
            if new_line ~= line then lines[i] = new_line; changed = true end
          end
          if changed then
            pcall(vim.fn.writefile, lines, filepath)
            src_files_changed = src_files_changed + 1
          end
        end
      end
    end

    -- 3. Reload any open buffers that were modified on disk
    vim.cmd("checktime")

    -- 4. Reload locale and re-render
    M.load_locale()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) and M.is_target_ft(buf) then
        M.debounced_render(buf)
      end
    end

    vim.notify(string.format(
      'Intl Lens: "%s" → "%s" — %d locale file(s), %d source file(s)',
      info.key, new_key, locale_files_changed, src_files_changed
    ))
  end)
end

function M.find_usages()
  local info = M.get_key_at_cursor()
  if not info then
    vim.notify("Intl Lens: no translation key under cursor", vim.log.levels.WARN)
    return
  end
  open_usages_qf(info.key)
end

function M.pick_all_translations()
  local pickers      = require("telescope.pickers")
  local finders      = require("telescope.finders")
  local conf         = require("telescope.config").values
  local actions      = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  if vim.tbl_isempty(M.state.translations) then
    M.load_locale()
  end
  if vim.tbl_isempty(M.state.translations) then
    vim.notify("Intl Lens: locale file not found at " .. vim.fn.getcwd() .. "/app/locales/", vim.log.levels.WARN)
    return
  end

  local entries = {}
  for k, v in pairs(M.state.translations) do
    table.insert(entries, { key = k, value = v })
  end
  table.sort(entries, function(a, b) return a.key < b.key end)

  pickers.new({}, {
    prompt_title = "All Translations — " .. M.state.active_locale,
    finder = finders.new_table({
      results = entries,
      entry_maker = function(entry)
        return {
          value   = entry,
          display = string.format("%-45s  %s", entry.key, entry.value),
          ordinal = entry.key .. " " .. entry.value,  -- searchable by id OR message text
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selection then open_usages_qf(selection.value.key) end
      end)
      return true
    end,
  }):find()
end

function M.cycle_locale()
  local locales = M.state.locales
  if #locales == 0 then
    vim.notify("Intl Lens: no locales discovered", vim.log.levels.WARN)
    return
  end

  local idx = 1
  for i, l in ipairs(locales) do
    if l == M.state.active_locale then
      idx = i
      break
    end
  end

  idx = (idx % #locales) + 1
  M.state.active_locale = locales[idx]

  M.load_locale()
  M.watch_locale()

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and M.is_target_ft(buf) then
      M.render(buf)
    end
  end

  vim.notify("Intl Lens: " .. M.state.active_locale, vim.log.levels.INFO)
end

function M.enable()
  M.state.enabled = true
  M.state.locales = M.discover_locales()
  M.load_locale()
  M.watch_locale()
  M.state.autocmd_group = vim.api.nvim_create_augroup("IntlLens", { clear = true })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = M.state.autocmd_group,
    callback = function(a)
      if M.is_target_ft(a.buf) then M.debounced_render(a.buf) end
    end,
  })

  vim.api.nvim_create_autocmd({ "BufEnter", "BufReadPost" }, {
    group = M.state.autocmd_group,
    callback = function(a)
      if M.is_target_ft(a.buf) then M.render(a.buf) end
    end,
  })

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and M.is_target_ft(buf) then
      M.render(buf)
    end
  end

  vim.notify("Intl Lens enabled", vim.log.levels.INFO)
end

function M.disable()
  M.state.enabled = false
  if M.state.watcher then
    M.state.watcher:stop()
    M.state.watcher:close()
    M.state.watcher = nil
  end
  for _, t in pairs(M.state.debounce_timers) do
    t:stop()
    t:close()
  end
  M.state.debounce_timers = {}
  if M.state.autocmd_group then
    vim.api.nvim_del_augroup_by_id(M.state.autocmd_group)
    M.state.autocmd_group = nil
  end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      vim.api.nvim_buf_clear_namespace(buf, M.state.ns, 0, -1)
    end
  end
  vim.notify("Intl Lens disabled", vim.log.levels.INFO)
end

function M.toggle()
  if M.state.enabled then
    M.disable()
  else
    M.enable()
  end
end

-- Given a template_string treesitter node, return the ICU message string and
-- a vars table of {name, expr} pairs for each ${...} substitution.
local function extract_template_interpolation(node, bufnr)
  local msg_parts = {}
  local vars = {}
  local seen_names = {}

  for child in node:iter_children() do
    local t = child:type()
    if t == "string_fragment" then
      table.insert(msg_parts, vim.treesitter.get_node_text(child, bufnr))
    elseif t == "template_substitution" then
      -- Text is like "${elementType.toLowerCase()}" — strip the ${ }
      local sub_text = vim.treesitter.get_node_text(child, bufnr)
      local expr = sub_text:match("^%${(.+)}$") or sub_text

      -- Derive a clean identifier: use the first identifier in the expression.
      -- "${elementType.toLowerCase()}" → "elementType"
      -- "${someObj.prop}"              → "someObj"  (caller may override)
      -- "${count + 1}"                 → "count"
      local var_name = expr:match("^([%w_$]+)") or "value"

      -- Ensure uniqueness across multiple substitutions
      local base_name = var_name
      local i = 2
      while seen_names[var_name] do
        var_name = base_name .. i
        i = i + 1
      end
      seen_names[var_name] = true

      table.insert(msg_parts, "{" .. var_name .. "}")
      table.insert(vars, { name = var_name, expr = expr })
    end
    -- backtick delimiters (type "``") and "${", "}" punctuation are skipped
  end

  return table.concat(msg_parts), vars
end

-- Shared implementation: replace a text range with a formatMessage call.
-- jsx_wrap=true wraps the call in {…} for JSX expression contexts.
-- vars is an optional list of {name, expr} for interpolated values.
local function do_wrap(bufnr, start_row, start_col, end_row, end_col, default_msg, jsx_wrap, vars)
  -- Ensure translations are loaded even if the lens display is not toggled on
  if vim.tbl_isempty(M.state.translations) then
    M.load_locale()
  end

  -- Look up existing key by value
  local existing_id = ""
  for k, v in pairs(M.state.translations) do
    if v == default_msg then existing_id = k; break end
  end

  local values_str = ""
  if vars and #vars > 0 then
    local parts = {}
    for _, v in ipairs(vars) do
      if v.name == v.expr then
        table.insert(parts, v.name)          -- JS shorthand: { elementType }
      else
        table.insert(parts, v.name .. ": " .. v.expr)
      end
    end
    values_str = ", { " .. table.concat(parts, ", ") .. " }"
  end

  local inner = 'formatMessage({ id: "' .. existing_id .. '", defaultMessage: "' .. default_msg .. '" }' .. values_str .. ')'
  local replacement = jsx_wrap and ("{" .. inner .. "}") or inner

  -- Pre-compute: find innermost enclosing function body
  local body_insert_row = nil
  local needs_hook      = false

  local ts_ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if ts_ok then
    parser:parse()
    local node_ok, node = pcall(vim.treesitter.get_node, {
      bufnr = bufnr,
      pos   = { start_row, start_col },
    })
    if node_ok and node then
      while node do
        if node:type() == "statement_block" then
          local parent = node:parent()
          if parent then
            local pt = parent:type()
            if pt == "function_declaration" or pt == "function_expression"
               or pt == "arrow_function"    or pt == "method_definition" then
              local bsr, _, ber, _ = node:range()
              local body_lines = vim.api.nvim_buf_get_lines(bufnr, bsr, ber, false)
              local has_hook = false
              for _, line in ipairs(body_lines) do
                if line:find("useSafeIntl", 1, true) then has_hook = true; break end
              end
              if not has_hook then
                needs_hook      = true
                body_insert_row = bsr + 1
              end
              break
            end
          end
        end
        node = node:parent()
      end
    end
  end

  -- Pre-compute: import needed?
  local all_lines       = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local has_import      = false
  local last_import_row = 0
  for i, line in ipairs(all_lines) do
    if line:match("^import ") then last_import_row = i - 1 end
    if line:find("useSafeIntl", 1, true) then has_import = true end
  end
  local needs_import = needs_hook and not has_import

  -- Make edits: replacement first (no row shift), then insertions top-down
  vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, { replacement })

  local final_start_row = start_row

  if needs_import then
    local insert_at = last_import_row + 1
    vim.api.nvim_buf_set_lines(bufnr, insert_at, insert_at, false,
      { 'import { useSafeIntl } from "@/hooks/use-safe-intl";' })
    if body_insert_row and insert_at <= body_insert_row then body_insert_row = body_insert_row + 1 end
    if insert_at <= final_start_row then final_start_row = final_start_row + 1 end
  end

  if needs_hook and body_insert_row then
    vim.api.nvim_buf_set_lines(bufnr, body_insert_row, body_insert_row, false,
      { "  const { formatMessage } = useSafeIntl();" })
    if body_insert_row <= final_start_row then final_start_row = final_start_row + 1 end
  end

  -- Place cursor at end of id string content and enter insert mode
  local id_prefix = (jsx_wrap and '{' or '') .. 'formatMessage({ id: "'
  local final_col = start_col + #(id_prefix .. existing_id)
  vim.api.nvim_win_set_cursor(0, { final_start_row + 1, final_col })
  vim.cmd("startinsert")
end

function M.wrap_selection()
  local bufnr = vim.api.nvim_get_current_buf()
  if not M.is_target_ft(bufnr) then
    vim.notify("Intl Lens: not a TypeScript buffer", vim.log.levels.WARN)
    return
  end

  local start_pos = vim.fn.getpos("'<")
  local end_pos   = vim.fn.getpos("'>")
  local start_row = start_pos[2] - 1
  local start_col = start_pos[3] - 1
  local end_row   = end_pos[2] - 1
  local end_col   = end_pos[3]  -- 1-indexed inclusive = 0-indexed exclusive

  local end_line_text = vim.api.nvim_buf_get_lines(bufnr, end_row, end_row + 1, false)[1] or ""
  end_col = math.min(end_col, #end_line_text)

  local selected_text = table.concat(
    vim.api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col, {}), " ")

  local default_msg = selected_text:match('^"(.*)"$')
    or selected_text:match("^'(.*)'$")
    or selected_text:match("^`(.*)`$")
    or selected_text

  -- For template strings, convert ${expr} to {varName} and collect vars
  local interp_vars
  if selected_text:match("^`") and default_msg:find("${", 1, true) then
    local vars = {}
    local seen_names = {}
    default_msg = default_msg:gsub("%${([^}]+)}", function(expr)
      local var_name = expr:match("^([%w_$]+)") or "value"
      local base_name = var_name
      local i = 2
      while seen_names[var_name] do
        var_name = base_name .. i
        i = i + 1
      end
      seen_names[var_name] = true
      table.insert(vars, { name = var_name, expr = expr })
      return "{" .. var_name .. "}"
    end)
    interp_vars = vars
  end

  do_wrap(bufnr, start_row, start_col, end_row, end_col, default_msg, false, interp_vars)
end

-- Normal-mode entry: find string literal or JSX text node under cursor and wrap it.
function M.wrap_at_cursor()
  local bufnr = vim.api.nvim_get_current_buf()
  if not M.is_target_ft(bufnr) then
    vim.notify("Intl Lens: not a TypeScript buffer", vim.log.levels.WARN)
    return
  end

  local cursor    = vim.api.nvim_win_get_cursor(0)
  local crow, ccol = cursor[1] - 1, cursor[2]

  local ts_ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ts_ok then return end
  parser:parse()

  local node_ok, node = pcall(vim.treesitter.get_node, { bufnr = bufnr, pos = { crow, ccol } })
  if not node_ok or not node then
    vim.notify("Intl Lens: no treesitter node at cursor", vim.log.levels.WARN)
    return
  end

  -- Walk up to find a wrappable node
  local target_node, default_msg, jsx_wrap, interp_vars
  local n = node
  while n do
    local t = n:type()
    if t == "string" then
      -- Full string literal including quotes → strip them for defaultMessage
      local raw = vim.treesitter.get_node_text(n, bufnr)
      default_msg = raw:match('^"(.*)"$') or raw:match("^'(.*)'$") or raw
      target_node = n
      -- Wrap in {} when the string is a bare JSX attribute value: label="Close"
      -- but NOT when already inside a jsx_expression: label={"Close"}
      local parent_type = n:parent() and n:parent():type() or ""
      jsx_wrap = (parent_type == "jsx_attribute")
      break
    elseif t == "template_string" then
      -- Extract ICU placeholders and their expressions via treesitter
      local msg, vars = extract_template_interpolation(n, bufnr)
      default_msg  = msg
      interp_vars  = vars
      target_node  = n
      -- Same JSX attribute check for template literals
      local parent_type = n:parent() and n:parent():type() or ""
      jsx_wrap = (parent_type == "jsx_attribute")
      break
    elseif t == "jsx_text" then
      -- JSX body text — trim whitespace, wrap in {…}
      local raw = vim.treesitter.get_node_text(n, bufnr)
      default_msg = raw:match("^%s*(.-)%s*$")
      if default_msg and default_msg ~= "" then
        target_node = n
        jsx_wrap    = true
      end
      break
    end
    n = n:parent()
  end

  if not target_node or not default_msg or default_msg == "" then
    vim.notify("Intl Lens: cursor not inside a string or JSX text node", vim.log.levels.WARN)
    return
  end

  local sr, sc, er, ec = target_node:range()
  do_wrap(bufnr, sr, sc, er, ec, default_msg, jsx_wrap, interp_vars)
end

function M.setup()
  M.state.ns = vim.api.nvim_create_namespace("intl_lens")
  vim.api.nvim_set_hl(0, "IntlLensValue", { link = "Comment", default = true })
  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
      vim.api.nvim_set_hl(0, "IntlLensValue", { link = "Comment", default = true })
    end,
  })
  -- Register which-key group (safe: no-ops if which-key isn't loaded yet)
  vim.schedule(function()
    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({
        { "<leader>l",  group = "Int[l] Lens" },
        { "<leader>lw", group = "[W]rap",       mode = { "n", "v" } },
      })
    end
  end)

  vim.keymap.set("n", "<leader>li", M.toggle,            { desc = "Toggle Int[l] Lens",          silent = true })
  vim.keymap.set("n", "<leader>lj", M.jump_to_source,    { desc = "Intl Lens [J]ump to source",  silent = true })
  vim.keymap.set("n", "<leader>le", M.edit_translation,  { desc = "Intl Lens [E]dit translation",  silent = true })
  vim.keymap.set("n", "<leader>lE", function()
    vim.cmd("botright 15split | terminal pnpm intl:extract")
    local term_buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_create_autocmd("TermClose", {
      buffer = term_buf,
      once = true,
      callback = function()
        M.load_locale()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(buf) and M.is_target_ft(buf) then
            M.debounced_render(buf)
          end
        end
        vim.notify("Intl Lens: translations reloaded", vim.log.levels.INFO)
      end,
    })
  end, { desc = "Intl Lens [E]xtract (run script)", silent = true })
  vim.keymap.set("n", "<leader>lp", M.pick_translations,     { desc = "Intl Lens [P]ick keys (buffer)",   silent = true })
  vim.keymap.set("n", "<leader>lP", M.pick_all_translations, { desc = "Intl Lens [P]ick all translations", silent = true })
  vim.keymap.set("n", "<leader>lu", M.find_usages,  { desc = "Intl Lens [U]sages of key",   silent = true })
  vim.keymap.set("n", "<leader>lk", M.copy_key,    { desc = "Intl Lens [K]opy key",        silent = true })
  vim.keymap.set("n", "<leader>lr", M.rename_key,  { desc = "Intl Lens [R]ename key",      silent = true })
  vim.keymap.set("n", "<leader>ln", M.cycle_locale,      { desc = "Intl Lens [N]ext locale",     silent = true })
  vim.keymap.set("n", "<leader>lw", M.wrap_at_cursor,    { desc = "Intl Lens [W]rap at cursor",  silent = true })
  vim.keymap.set("v", "<leader>lw", function()
    -- Exit visual mode first so '< and '> marks are committed before we read them
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
    M.wrap_selection()
  end, { desc = "Intl Lens [W]rap selection", silent = true })

  vim.api.nvim_create_user_command("IntlLensToggle",  M.toggle,           {})
  vim.api.nvim_create_user_command("IntlLensJump",    M.jump_to_source,   {})
  vim.api.nvim_create_user_command("IntlLensEdit",    M.edit_translation, {})
  vim.api.nvim_create_user_command("IntlLensPick",     M.pick_translations,    {})
  vim.api.nvim_create_user_command("IntlLensPickAll", M.pick_all_translations,{})
  vim.api.nvim_create_user_command("IntlLensUsages",  M.find_usages,  {})
  vim.api.nvim_create_user_command("IntlLensCopyKey", M.copy_key,     {})
  vim.api.nvim_create_user_command("IntlLensRename",  M.rename_key,   {})
  vim.api.nvim_create_user_command("IntlLensLocale",  M.cycle_locale,         {})
  vim.api.nvim_create_user_command("IntlLensWrap",    M.wrap_at_cursor,   {})
end

M.setup()
return M
