return {
  cmd = { 'gopls' },
  filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
  root_markers = { 'go.work', 'go.mod', '.git' },
  capabilities = require('lsp-utils').get_capabilities(),
  settings = {
    gopls = {
      analyses = {
        unusedparams = true,
      },
      staticcheck = true,
      gofumpt = true,
    },
  },
  on_attach = function(client, bufnr)
    client.server_capabilities.semanticTokensProvider = nil
    vim.keymap.set("n", "<leader>i", function()
      vim.lsp.buf.format()
      vim.cmd("write")
      local filepath = vim.fn.expand("%:p")
      vim.fn.system({ "golangci-lint", "run", "--fix", filepath })
      vim.cmd("edit")
    end, { buffer = bufnr, desc = "Format and lint fix (Go)" })
  end,
}
