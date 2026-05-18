return {
    {
        "yonatanperel/lake-dweller.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("lake-dweller").setup({
                transparent = false,
                italics = false,
                float_background = false,
                variant = "nay-dweller",
            })
            vim.cmd.colorscheme("lake-dweller")
        end,
    },
    {
        "rebelot/kanagawa.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            --vim.cmd.colorscheme("kanagawa")
        end,
    },
    {
        "morhetz/gruvbox",
        lazy = false,
        priority = 1000,
        config = function()
            --vim.cmd.colorscheme("gruvbox")
        end,
    },
    {
        "neanias/everforest-nvim",
        version = false,
        lazy = false,
        priority = 1000, -- make sure to load this before all the other start plugins
        -- Optional; default configuration will be used if setup isn't called.
        config = function()
            require("everforest").setup({

            })
            --vim.cmd([[colorscheme everforest]])
        end,
    },
    {
        'RostislavArts/naysayer.nvim',
        priority = 1000,
        lazy = false,
        config = function()
            --vim.cmd.colorscheme('naysayer')
        end,
    }

}
