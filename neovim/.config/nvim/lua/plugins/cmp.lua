local function getModuleSpecifier(completion_source)
  -- Check if `data` exists and has an `entryNames` table
  if completion_source.data and type(completion_source.data.entryNames) == "table" then
    -- Iterate through the entryNames table
    for _, entry in ipairs(completion_source.data.entryNames) do
      -- Ensure the entry is a table with a `data` field
      if type(entry) == "table" and entry.data and entry.data.moduleSpecifier then return entry.data.moduleSpecifier end
    end
  end
  if type(completion_source.data.entryNames[1]) == "string" then return completion_source.data.entryNames[1] end
  -- Return nil if no valid moduleSpecifier is found
  return nil
end

--- Get completion context, i.e., auto-import/target module location.
local function get_lsp_completion_context(completion, source)
  local ok, source_name = pcall(function() return source.source.client.config.name end)
  if not ok then return nil end
  if source_name == "typescript-tools" then
    return getModuleSpecifier(completion)
  elseif source_name == "tsserver" then
    return completion.detail
  elseif source_name == "pyright" or source_name == "vtsls" then
    if completion.labelDetails ~= nil then return completion.labelDetails.description end
  elseif source_name == "gopls" then
    -- And this, for the record, is how I inspect payloads
    -- require("config.shared").logger("completion source: ", completion) -- Lazy-serialization of heavy payloads
    return completion.detail
  end
end

return {
  { -- Autocompletion
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      -- Snippet Engine & its associated nvim-cmp source
      {
        "L3MON4D3/LuaSnip",
        build = (function()
          if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then return end
          return "make install_jsregexp"
        end)(),
        dependencies = {
          { "rafamadriz/friendly-snippets", config = function() require("luasnip.loaders.from_vscode").lazy_load() end },
        },
      },
      "saadparwaiz1/cmp_luasnip",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-path",
      "onsails/lspkind.nvim",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      luasnip.config.setup({})

      cmp.setup({
        snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
        completion = { completeopt = "menu,menuone,noinsert" },
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping.select_next_item(),
          ["<S-Tab>"] = cmp.mapping.select_prev_item(),
          ["<C-Space>"] = cmp.mapping.complete({}),
          ["<C-l>"] = cmp.mapping(function()
            if luasnip.expand_or_locally_jumpable() then luasnip.expand_or_jump() end
          end, { "i", "s" }),
          ["<C-h>"] = cmp.mapping(function()
            if luasnip.locally_jumpable(-1) then luasnip.jump(-1) end
          end, { "i", "s" }),
        }),
        sources = { { name = "lazydev", group_index = 0 }, { name = "nvim_lsp" }, { name = "luasnip" }, { name = "path" } },
        formatting = {
          fields = { "kind", "abbr", "menu" },
          expandable_indicator = true,
          format = function(entry, vim_item)
            local item = require("lspkind").cmp_format({ mode = "symbol", maxwidth = 50 })(entry, vim_item)

            item.menu = ""
            local completion_context = get_lsp_completion_context(entry.completion_item, entry.source)
            if completion_context ~= nil and completion_context ~= "" then
              local truncated_context = string.sub(completion_context, 1, 30)
              if truncated_context ~= completion_context then truncated_context = truncated_context .. "..." end
              item.menu = item.menu .. " " .. truncated_context
            end

            return item
          end,
        },
      })
    end,
  },
}
