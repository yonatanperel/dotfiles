return {
  "folke/snacks.nvim",
  lazy = false,
  keys = {
    { "<leader>ff", function() Snacks.picker.files() end, desc = "Find files" },
    { "<leader>fg", function() Snacks.picker.grep() end, desc = "Live grep" },
    { "<leader>fs", function() Snacks.picker.lsp_symbols() end, desc = "Workspace symbols" },
    { "gr", function() Snacks.picker.lsp_references() end, desc = "References" },
    { "<leader>gl", function() Snacks.picker.git_log() end, desc = "Git log" },
    { "<leader>gL", function() Snacks.picker.git_log_file() end, desc = "Git log (current file)" },
    { "<leader>gg", function() Snacks.terminal.toggle("lazygit") end, desc = "Lazygit" },
  },
  opts = {
    picker = {
      enabled = true,
      sources = {
        files = { hidden = true },
        grep = { hidden = true },
      },
      win = {
        input = {
          keys = {
            ["<c-q>"] = { "qflist", mode = { "i", "n" } },
          },
        },
      },
    },
  },
}
