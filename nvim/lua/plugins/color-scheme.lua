return {
    {
        "nyoom-engineering/oxocarbon.nvim",
        build = false,
        lazy = false,
        priority = 1000,
        config = function()
            vim.opt.background = "dark"
            --vim.cmd.colorscheme("oxocarbon")
            for _, g in ipairs({ "Normal", "NormalNC", "SignColumn", "EndOfBuffer" }) do
                vim.api.nvim_set_hl(0, g, { bg = "none" })
            end
        end,
    },
    {
        "datsfilipe/vesper.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("vesper").setup({ transparent = true, italics = { comments = true } })
            --vim.cmd.colorscheme("vesper")
        end,
    },
    {
        "projekt0n/github-nvim-theme",
        name = "github-theme",
        lazy = false,
        priority = 1000,
        config = function()
            require("github-theme").setup({
                options = {
                    transparent = true,
                    terminal_colors = true,
                    styles = { comments = "NONE", keywords = "NONE" },
                },
            })
            --vim.cmd.colorscheme("github_dark_default")

            -- Set to true to flatten syntax colors (comments grey, strings blue, keywords red, rest plain).
            local minimal_syntax = false
            if minimal_syntax then
                -- Minimal syntax: comments grey, strings light blue, keywords red, rest plain fg.
                local fg = "#e6edf3"
                local plain = {
                    "Identifier", "Function", "Type", "Typedef", "Operator", "Special", "Delimiter",
                    "Constant", "Number", "Float", "Boolean", "Character", "PreProc", "Include",
                    "Define", "Macro", "Structure", "StorageClass", "Tag", "SpecialChar",
                    "@variable", "@variable.builtin", "@variable.member", "@variable.parameter",
                    "@property", "@field", "@parameter", "@function", "@function.call",
                    "@function.method", "@function.method.call", "@function.builtin", "@constructor",
                    "@type", "@type.builtin", "@type.definition", "@module", "@namespace",
                    "@constant", "@constant.builtin", "@number", "@number.float", "@boolean",
                    "@operator", "@punctuation", "@punctuation.bracket", "@punctuation.delimiter",
                    "@tag", "@tag.attribute", "@tag.delimiter", "@attribute", "@label",
                    "@lsp.type.function", "@lsp.type.method", "@lsp.type.class", "@lsp.type.type",
                    "@lsp.type.variable", "@lsp.type.parameter", "@lsp.type.property",
                    "@lsp.type.namespace", "@lsp.type.enum", "@lsp.type.enumMember",
                    "@lsp.type.interface", "@lsp.type.struct", "@lsp.type.macro",
                }
                for _, g in ipairs(plain) do
                    vim.api.nvim_set_hl(0, g, { fg = fg })
                end
                for _, g in ipairs({ "Keyword", "Statement", "Conditional", "Repeat", "Exception",
                    "@keyword", "@keyword.function", "@keyword.return", "@keyword.operator",
                    "@keyword.import", "@keyword.conditional", "@keyword.repeat", "@lsp.type.keyword" }) do
                    vim.api.nvim_set_hl(0, g, { fg = "#ff7b72" })
                end
                for _, g in ipairs({ "String", "@string", "@string.escape", "@string.special" }) do
                    vim.api.nvim_set_hl(0, g, { fg = "#a5d6ff" })
                end
                for _, g in ipairs({ "Comment", "@comment" }) do
                    vim.api.nvim_set_hl(0, g, { fg = "#6e7681" })
                end
            end
        end,
    },
    {
        "yonatanperel/lake-dweller.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("lake-dweller").setup({
                transparent = true,
                italics = false,
                float_background = false,
                variant = "lake-dweller",
            })
            --vim.cmd.colorscheme("lake-dweller")
        end,
    },
    {
        "scottmckendry/cyberdream.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("cyberdream").setup({
                variant = "muted",
                transparent = true,
                saturation = 0.85,
                italic_comments = false,
            })
            --vim.cmd.colorscheme("cyberdream")
        end,
    },
    {
        "olivercederborg/poimandres.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("poimandres").setup({
                disable_background = true,
                disable_float_background = false,
            })
            vim.cmd.colorscheme("poimandres")
        end,
    },
    {
        "rebelot/kanagawa.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            --require("kanagawa").setup({ transparent = true, theme = "dragon" })
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
