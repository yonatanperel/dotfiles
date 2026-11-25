vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = true
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.o.winborder = "single"

-- Some colorschemes (e.g. poimandres) give FloatBorder the same colour as
-- NormalFloat's background, which makes the border invisible. Keep it visible.
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    local function hl(name) return vim.api.nvim_get_hl(0, { name = name, link = false }) end
    local float, border, comment = hl("NormalFloat"), hl("FloatBorder"), hl("Comment")
    if border.fg == float.bg or border.fg == nil then
      vim.api.nvim_set_hl(0, "FloatBorder", { fg = comment.fg or hl("Normal").fg, bg = float.bg })
    end
  end,
})

-- Fixed RPC socket so the Godot editor can open scripts in this nvim
-- (see scripts/godot-open.sh). First nvim to start owns it.
do
  local sock = "/tmp/godot-nvim.pipe"
  if not pcall(vim.fn.serverstart, sock) then
    -- stale socket from a crashed nvim? remove it and retry
    local ok, chan = pcall(vim.fn.sockconnect, "pipe", sock, { rpc = true })
    if ok and chan ~= 0 then
      vim.fn.chanclose(chan)
    else
      vim.uv.fs_unlink(sock)
      pcall(vim.fn.serverstart, sock)
    end
  end
end
