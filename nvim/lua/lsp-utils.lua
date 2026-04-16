local M = {}

function M.get_capabilities()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  local has_blink, blink = pcall(require, 'blink.cmp')
  if has_blink then
    capabilities = blink.get_lsp_capabilities(capabilities)
  end
  return capabilities
end

return M