return {
  'saghen/blink.cmp',
  version = '1.*',
  dependencies = {
    'L3MON4D3/LuaSnip',
  },
  opts = {
    keymap = {
      preset = 'none',
      ['<C-b>'] = { 'scroll_documentation_up' },
      ['<C-f>'] = { 'scroll_documentation_down' },
      ['<C-e>'] = { 'cancel' },
      ['<CR>'] = { 'accept', 'fallback' },
      ['<Tab>'] = { 'select_next', 'snippet_forward', 'fallback' },
      ['<S-Tab>'] = { 'select_prev', 'snippet_backward', 'fallback' },
    },
    snippets = { preset = 'luasnip' },
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
    },
    completion = {
      menu = { border = "single" },
      documentation = { auto_show = true, window = { border = "single" } },
      ghost_text = { enabled = true },
    },
    signature = { enabled = true, window = { border = "single" } },
  },
}
