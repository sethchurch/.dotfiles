-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

config.max_fps = 144

config.color_scheme = "Tokyo Night"

config.font_size = 16
config.font = wezterm.font("FiraMono Nerd Font")

config.automatically_reload_config = true

config.keys = {
	{
		key = "n",
		mods = "SHIFT|CTRL",
		action = wezterm.action.ToggleFullScreen,
	},
}

return config
