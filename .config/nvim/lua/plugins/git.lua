return {
  {
    "NeogitOrg/neogit",
    cmd = "Neogit",
    dependencies = { "nvim-lua/plenary.nvim", "dlyongemallo/diffview-plus.nvim" },
    opts = { integrations = { diffview = true } },
    keys = {
      { "<leader>gn", "<cmd>Neogit<cr>", desc = "Neogit status" },
    },
  },
  {
    "dlyongemallo/diffview-plus.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    keys = {
      { "<leader>gv", "<cmd>DiffviewOpen<cr>", desc = "Diffview: changes / merge" },
      { "<leader>gV", "<cmd>DiffviewClose<cr>", desc = "Diffview: close" },
      { "<leader>gH", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview: file history" },
    },
  },
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>gk",
        function()
          Snacks.terminal("hunk diff --watch", { win = { position = "right", width = 0.5 } })
        end,
        desc = "Hunk: live review",
      },
    },
  },
}
