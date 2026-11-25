-- GLSL shader support: filetype detection and comment style
vim.filetype.add({
  extension = {
    vert = 'glsl', frag = 'glsl', geom = 'glsl',
    comp = 'glsl', tesc = 'glsl', tese = 'glsl',
    vs = 'glsl', fs = 'glsl',
  },
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "glsl",
  callback = function(ev)
    vim.bo[ev.buf].commentstring = "// %s"
  end,
})

-- Diagnostics via glslangValidator (glsl_analyzer only reports a few syntax errors)
local ns = vim.api.nvim_create_namespace("glslang")
local stages = { vert = "vert", vs = "vert", frag = "frag", fs = "frag", geom = "geom",
  comp = "comp", tesc = "tesc", tese = "tese" }

local function lint(buf)
  if vim.fn.executable("glslangValidator") == 0 or not vim.api.nvim_buf_is_valid(buf) then return end
  local ext = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":e")
  local stage = stages[ext] or "frag"
  local text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n") .. "\n"
  vim.system({ "glslangValidator", "--stdin", "-S", stage }, { stdin = text }, function(res)
    local diags = {}
    for line in ((res.stdout or "") .. "\n"):gmatch("[^\n]+") do
      local sev, lnum, msg = line:match("^(%u+): [^:]*:(%d+): (.*)$")
      if sev == "ERROR" or sev == "WARNING" then
        diags[#diags + 1] = {
          lnum = math.max(tonumber(lnum) - 1, 0), col = 0,
          severity = sev == "ERROR" and vim.diagnostic.severity.ERROR or vim.diagnostic.severity.WARN,
          message = msg, source = "glslang",
        }
      end
    end
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(buf) then vim.diagnostic.set(ns, buf, diags) end
    end)
  end)
end

vim.api.nvim_create_autocmd({ "FileType", "BufWritePost", "InsertLeave" }, {
  callback = function(ev)
    if vim.bo[ev.buf].filetype == "glsl" then lint(ev.buf) end
  end,
})

return {}
