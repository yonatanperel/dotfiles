_G.lsps = { "gopls", "lua_ls", "pyright", "ts_ls", "bashls", "glsl_analyzer" }
-- LSPs not installable via mason (gdscript uses Godot's built-in server)
_G.extra_lsps = { "gdscript" }
_G.languages = { "go", "lua", "python", "sql", "bash", "yaml", "toml", "json", "markdown", "dockerfile", "cpp", "rust", "gdscript", "gdshader", "glsl" }
vim.lsp.enable(_G.lsps)
vim.lsp.enable(_G.extra_lsps)
