-- GDScript / Godot shader support: filetypes, indentation, comment style
vim.filetype.add({
  extension = {
    gd = 'gdscript',
    gdshader = 'gdshader',
    gdshaderinc = 'gdshaderinc',
  },
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "gdscript", "gdshader", "gdshaderinc" },
  callback = function(ev)
    vim.bo[ev.buf].commentstring = (vim.bo[ev.buf].filetype == "gdscript") and "# %s" or "// %s"
    -- Godot's default style is tabs
    vim.bo[ev.buf].expandtab = false
    vim.bo[ev.buf].tabstop = 4
    vim.bo[ev.buf].shiftwidth = 4
  end,
})

return {}
