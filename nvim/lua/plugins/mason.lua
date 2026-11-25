return {
    {
        "mason-org/mason.nvim",
        opts = { ui = { border = "single" } },
    },
    {
        "mason-org/mason-lspconfig.nvim",
        dependencies = { "mason-org/mason.nvim" },
        config = function()
            require("lsp")
            require("mason-lspconfig").setup({
                ensure_installed = _G.lsps,
                automatic_installation = true,
            })
        end,
    },
}
