return {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    config = function()
        require("lsp")
        require('nvim-treesitter.configs').setup({
            ensure_installed = _G.languages,
            highlight = { enable = true },
            indent = { enable = true },
        }
        )
    end
}
