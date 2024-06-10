return {
  {
    "nvimdev/dashboard-nvim",
    lazy = false,
    opts = {
      config = {
        header = {
          [[                                                    ]],
          [[                                                    ]],
          [[                                                    ]],
          [[ ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ]],
          [[ ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ]],
          [[ ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ]],
          [[ ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ]],
          [[ ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ]],
          [[ ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ]],
          [[                                                    ]],
          [[                                                    ]],
          [[                                                    ]],
        },
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        component_separators = "",
        section_separators = "",

        -- component_separators = "",
        -- section_separators = { left = "", right = "" },

        -- component_separators = { left = "", right = "" },
        -- section_separators = { left = "", right = "" },

        -- component_separators = "",
        -- section_separators = { left = "", right = "" },
      },
      sections = {
        lualine_y = {
          { "progress", separator = " ", padding = { left = 1, right = 0 } },
          { "location", padding = { left = 0, right = 1 } },
        },
        lualine_z = { "filetype" },
      },
    },
  },
}
