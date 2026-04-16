return {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
        presets = {
            lsp_doc_border = false,
        },
    },
    dependencies = {
        "MunifTanjim/nui.nvim",
        "rcarriga/nvim-notify",
    }
}
