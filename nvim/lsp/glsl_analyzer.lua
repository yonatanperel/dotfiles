return {
  cmd = { 'glsl_analyzer' },
  filetypes = { 'glsl', 'vert', 'frag', 'geom', 'comp', 'tesc', 'tese' },
  root_markers = { '.git' },
  capabilities = require('lsp-utils').get_capabilities(),
}
