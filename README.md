# Omarchy Theme Loader

A drop-in plugin for changing Neovim theme automatically when Omarchy theme changes.

## Usage

To use 
1. Install the themes itself.
2. Install the `EskelinenAntti/omarchy-theme-loader.nvim` plugin.

<details>
<summary>lazy.nvim setup</summary>

<br/>
Add this to your plugins folder and you are good to go.

```lua
return {
    -- 1. Install the theme plugins for the various Omarchy themes.
	{
		"ribru17/bamboo.nvim",
		priority = 1000,
		lazy = true,
	},
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		lazy = true,
	},
	{
		"neanias/everforest-nvim",
		priority = 1000,
		lazy = true,
	},
	{
		"kepano/flexoki-neovim",
		priority = 1000,
		lazy = true,
	},
	{
		"ellisonleao/gruvbox.nvim",
		priority = 1000,
		lazy = true,
	},
	{
		"rebelot/kanagawa.nvim",
		priority = 1000,
		lazy = true,
	},
	{
		"tahayvr/matteblack.nvim",
		priority = 1000,
		lazy = true,
	},
	{
		"loctvl842/monokai-pro.nvim",
		priority = 1000,
		lazy = true,
		config = function()
			require("monokai-pro").setup({
				filter = "ristretto",
				override = function()
					return {
						NonText = { fg = "#948a8b" },
						MiniIconsGrey = { fg = "#948a8b" },
						MiniIconsRed = { fg = "#fd6883" },
						MiniIconsBlue = { fg = "#85dacc" },
						MiniIconsGreen = { fg = "#adda78" },
						MiniIconsYellow = { fg = "#f9cc6c" },
						MiniIconsOrange = { fg = "#f38d70" },
						MiniIconsPurple = { fg = "#a8a9eb" },
						MiniIconsAzure = { fg = "#a8a9eb" },
						MiniIconsCyan = { fg = "#85dacc" },
					}
				end,
			})
		end,
	},
	{
		"shaunsingh/nord.nvim",
		priority = 1000,
		lazy = true,
	},
	{
		"rose-pine/neovim",
		name = "rose-pine",
		priority = 1000,
		lazy = true,
	},
	{
		"folke/tokyonight.nvim",
		priority = 1000,
		lazy = true,
	},
	{
		"EdenEast/nightfox.nvim",
		priority = 1000,
		lazy = true,
	},
    -- 2. Install the omarchy-theme-loader plugin.
	{
		"EskelinenAntti/omarchy-theme-loader.nvim"
	},
}
```
</details>

## Custom Omarchy themes

If you use a custom Omarchy theme
1. Install the Neovim plugin for that theme.
2. Configure the mapping between Omarchy theme name and Neovim colorscheme.

<details>
<summary>lazy.nvim example</summary>

The example below shows how to configure `omarchy-theme-loader` to work with the <a href="https://github.com/bjarneo/omarchy-ash-theme">Omarchy Ash Theme</a>.

```lua
return {
    -- ... other themes
    
    -- 1. Install the theme plugin.
    {
        "bjarneo/ash.nvim"
        priority=1000,
        lazy=true,
    },

    -- 2. Configure required mapping between Omarchy theme name and Neovim colorscheme.
	{
		"EskelinenAntti/omarchy-theme-loader.nvim",
        opts = {
            themes = {
                -- Name of the Omarchy theme.
                ["ash"] = {
                    -- Name of the corresponding Neovim colorscheme.
                    colorscheme = "ash"
                }
            }
        }

	},
```

</details>

Don't know where to look for the plugin and the colorscheme? You can find those from the custom Omarchy theme's repository, from `neovim.lua` file.

For example, see the [neovim.lua](https://github.com/bjarneo/omarchy-ash-theme/blob/main/neovim.lua) for the Omarchy Ash Theme: the Neovim plugin is `bjarneo/ash.nvim` and the colorscheme is `ash`.

