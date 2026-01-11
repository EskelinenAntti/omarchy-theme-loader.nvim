local opts = require("omarchy-theme-loader.default-opts")
local omarchy_current_path = vim.fs.joinpath(vim.env.HOME, ".config", "omarchy", "current")
local omarchy_current_theme_name_path = vim.fs.joinpath(omarchy_current_path, "theme.name")

local is_omarchy = nil
local is_legacy_omarchy = nil

---@type userdata|nil
local handle

local function check_is_omarchy()
	if is_omarchy == nil then
		is_omarchy = vim.uv.fs_stat(omarchy_current_path) ~= nil
	end

	return is_omarchy
end

---Check if running in Omarchy version prior 3.3., as 3.3. introduced a breaking change for the underlying theme mechanism.
---@return boolean
local function check_is_legacy_omarchy()
	if is_legacy_omarchy == nil then
		is_legacy_omarchy = vim.uv.fs_stat(omarchy_current_theme_name_path) == nil
	end

	return check_is_omarchy() and is_legacy_omarchy
end

--- Configuration for a single theme.
---@class Theme
---@field colorscheme string The colorscheme name.

--- Options for configuing Omarchy themes.
---@class Opts
---@field themes table<string, Theme> A map of Omarchy theme names to their corresponding Neovim configurations.

---Get name of currently active Omarchy theme.
---@return string
local function current_omarchy_theme_name()
	if check_is_legacy_omarchy() then
		local symlink = omarchy_current_path .. "/theme"
		local resolved = vim.fn.resolve(symlink)
		return vim.fn.fnamemodify(resolved, ":t")
	end

	-- Read theme name from 'theme.name' file
	local file = io.open(omarchy_current_theme_name_path, "r")
	if not file then
		error(string.format("Could not read current theme from '%s'", omarchy_current_theme_name_path))
	end

	local theme = file:read()
	file:close()
	return theme
end

---Sync Neovim theme to the current Omarchy theme.
local function sync_theme()
	local ok, omarchy_theme_result = pcall(current_omarchy_theme_name)
	if not ok then
		vim.notify(omarchy_theme_result, vim.log.levels.ERROR)
		return
	end

	local theme = opts.themes[omarchy_theme_result]
	if not theme then
		vim.notify(
			string.format(
				"Did not find Neovim theme for Omarchy theme '%s'. You can specify it via your omarchy-theme-loader configuration.",
				omarchy_theme_result
			),
			vim.log.levels.ERROR
		)
		return
	end

	-- Reset background option to its default.
	vim.o.background = "dark"

	-- Enable the actual theme.
	if not pcall(vim.cmd.colorscheme, theme.colorscheme) then
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
	if not check_is_omarchy() then
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

	if check_is_legacy_omarchy() then
		vim.uv.fs_event_start(handle, omarchy_current_path, {}, function(_, filename, _)
			-- In older Omarchy versions we needed to listen for theme changes by watching the .config/omarchy/current folder,
			-- and only react to updates in the 'theme' symlink within the folder.
			if filename ~= "theme" then
				return
			end

			-- vim.cmd.* commands must not be called in fast event context, so defer it to be invoked soon by the main event loop.
			vim.schedule(function()
				sync_theme()
			end)
		end)
	else
		-- Watch 'theme.name' file and sync Neovim whenever there is an update.
		vim.uv.fs_event_start(handle, omarchy_current_theme_name_path, {}, function(_, _, _)
			-- vim.cmd.* commands must not be called in fast event context, so defer it to be invoked soon by the main event loop.
			vim.schedule(function()
				sync_theme()
			end)
		end)
	end
end

return M
