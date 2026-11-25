return {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
        -- the lsp_doc_border preset hardcodes "rounded", so set the view directly
        views = {
            hover = {
                border = { style = "single" },
                position = { row = 2, col = 2 },
            },
        },
    },
    dependencies = {
        "MunifTanjim/nui.nvim",
        {
            "rcarriga/nvim-notify",
            -- transparent colorschemes leave Normal without a bg, so set it explicitly
            opts = { background_colour = "#000000" },
        },
    }
}
