local opts = require("omarchy-theme-loader.default-opts")
local omarchy_current_path = vim.fs.joinpath(vim.env.HOME, ".config", "omarchy", "current")

---@type userdata|nil
local handle

--- Configuration for a single theme.
---@class Theme
---@field colorscheme string The colorscheme name.

--- Options for configuing Omarchy themes.
---@class Opts
---@field themes table<string, Theme> A map of Omarchy theme names to their corresponding Neovim configurations.

---Get name of currently active Omarchy theme.
---@return string
local function current_omarchy_theme_name()
	-- Path to theme.name file
	local theme_name_file = omarchy_current_path .. "/theme.name"

	-- Read theme name from file
	local file = io.open(theme_name_file, "r")
	if file then
		local theme = file:read("*l")
		file:close()
		if theme then
			return theme
		end
	end

	-- Fallback: try resolving symlink (legacy behavior)
	local symlink = omarchy_current_path .. "/theme"
	local resolved = vim.fn.resolve(symlink)
	return vim.fn.fnamemodify(resolved, ":t")
end

local function is_omarchy()
	return vim.uv.fs_stat(omarchy_current_path) ~= nil
end

---Sync Neovim theme to the current Omarchy theme.
local function sync_theme()
	local omarchy_theme = current_omarchy_theme_name()

	local theme = opts.themes[omarchy_theme]
	if not theme then
		vim.notify(
			string.format(
				"Did not find Neovim theme for Omarchy theme '%s'. You can specify it via your omarchy-theme-loader configuration.",
				omarchy_theme
			),
			vim.log.levels.ERROR
		)
		return
	end

	-- Reset background option to its default.
	vim.o.background = "dark"

	-- Enable the actual theme.
	local ok = pcall(vim.cmd.colorscheme, theme.colorscheme)
	if not ok then
		vim.notify(
			string.format(
				"Did not find colorscheme %s. You might need to install a Neovim plugin that specifies the colorscheme.",
				theme.colorscheme
			)
		)
		return
	end

	-- Set background to be transparent.
	require("omarchy-theme-loader.transparency").set_transparent_background()
end

local M = {}

---@param user_opts Opts|nil
M.setup = function(user_opts)
	-- Combine user config with defaults.
	opts = vim.tbl_deep_extend("force", opts, user_opts or {})
end

---Sync the Neovim theme to current Omarchy theme, and start watching for Omarchy theme changes.
---
---Do not call this directly from your Neovim config; Neovim will call it automatically on startup via
---`after/plugin/omarchy-theme-loader.lua`.
M.start = function()
	if not is_omarchy() then
		return
	end

	-- Sync the theme at startup.
	sync_theme()

	if handle then
		return
	end

	local err
	handle, err = vim.uv.new_fs_event()
	if err or not handle then
		vim.notify(string.format("Could not start listening for Omarchy theme changes: %s", err), vim.log.levels.ERROR)
		return
	end

	-- Start listening for theme changes in ~/.config/omarchy/current folder.
	vim.uv.fs_event_start(handle, omarchy_current_path, {}, function(_, filename, _)
		-- We are not interested in other changes in current/ such as background changes.
		-- Filter out theme changes (theme.name file or theme directory for legacy).
		if filename ~= "theme.name" and filename ~= "theme" then
			return
		end

		-- vim.cmd.* commands must not be called in fast event context, so defer it to be invoked soon by the main event loop.
		vim.schedule(function()
			sync_theme()
		end)
	end)
end

return M
