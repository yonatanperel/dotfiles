-- Godot's built-in language server; requires the Godot editor to be running
-- with the project open (default port 6005, override with GDScript_Port).
local port = tonumber(os.getenv('GDScript_Port')) or 6005

-- Under WSL2 NAT mode (not mirrored) the Windows host isn't on 127.0.0.1; use the default
-- gateway instead. Override with GDScript_Host.
local function get_host()
  local env = os.getenv('GDScript_Host')
  if env and env ~= '' then return env end
  local mode = vim.fn.has('wsl') == 1 and vim.trim(vim.fn.system('wslinfo --networking-mode 2>/dev/null')) or ''
  if mode == 'nat' then
    local route = vim.fn.system("ip route show default 2>/dev/null")
    local gw = route:match('default via ([%d%.]+)')
    if gw then return gw end
  end
  return '127.0.0.1'
end

return {
  -- Proxy translates /mnt/c/... <-> C:/... URIs so goto-definition etc. land on the right file
  cmd = { 'python3', vim.fn.stdpath('config') .. '/scripts/godot-lsp-proxy.py', get_host(), tostring(port) },
  filetypes = { 'gdscript' },
  root_markers = { 'project.godot', '.git' },
  capabilities = require('lsp-utils').get_capabilities(),
}
