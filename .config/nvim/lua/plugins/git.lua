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
    "lewis6991/gitsigns.nvim",
    event = "LazyFile",
    opts = {
      current_line_blame = true,
      current_line_blame_opts = { delay = 500, virt_text_pos = "eol" },
      current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
      preview_config = { border = "rounded" },
    },
    keys = {
      { "<leader>gt", "<cmd>Gitsigns toggle_current_line_blame<cr>", desc = "Gitsigns: toggle line blame" },
      { "<leader>gw", "<cmd>Gitsigns toggle_word_diff<cr>", desc = "Gitsigns: toggle word diff" },
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
