local M = {}
M.opts = require("omarchy-theme-loader.default-themes")

local omarchy_current_path = vim.env.HOME .. "/.config/omarchy/current"

--- Configuration for a single theme.
---@class Theme
---@field colorscheme string The colorscheme name.

--- Options for configuing Omarchy themes.
---@class Opts
---@field themes table<string, Theme> A map of Omarchy theme names to their corresponding Neovim configurations.

---Get name of currently active Omarchy theme.
---@return string
M.current_omarchy_theme_name = function()
	-- Path to current/theme symlink
	local symlink = omarchy_current_path .. "/theme"

	-- Resolve the symlink (= return the path the symlink points at).
	local resolved = vim.fn.resolve(symlink)

	-- From that path, parse the theme name.
	local theme = vim.fn.fnamemodify(resolved, ":t")

	return theme
end

---Sync Neovim theme to the current Omarchy theme.
M.sync_theme = function()
	local current_omarchy_theme_name = M.current_omarchy_theme_name()

	local theme = M.opts.themes[current_omarchy_theme_name]
	if theme then
		-- Reset background option to its default.
		vim.o.background = "dark"

		-- Enable the actual theme.
		vim.cmd.colorscheme(theme.colorscheme)

		-- Set background to be transparent.
		require("omarchy-theme-loader.transparency").set_transparent_background()
	else
		vim.notify(
			string.format(
				"Did not find Neovim theme for Omarchy theme '%s'. Check your omarchy-theme-loader configuration.",
				current_omarchy_theme_name
			),
			vim.log.levels.ERROR
		)
	end
end

---@param opts Opts|nil
M.setup = function(opts)
	-- Combine user config with defaults.
	M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})
end

M.start = function()
	-- Sync the theme at startup.
	M.sync_theme()

	local handle, err = vim.uv.new_fs_event()
	if err or not handle then
		vim.notify(string.format("Could not start listening for Omarchy theme changes: %s", err), vim.log.levels.ERROR)
		return
	end

	-- Start listening for theme changes in ~/.config/omarchy/current folder.
	vim.uv.fs_event_start(handle, omarchy_current_path, {}, function(_, filename, _)
		-- We are not interested in other changes in current/ such as background changes.
		-- Filter out theme changes.
		if filename ~= "theme" then
			return
		end

		-- vim.cmd.* commands must not be called in fast event context, so defer it to be invoked soon by the main event loop.
		vim.schedule(function()
			M.sync_theme()
		end)
	end)
end

return M
