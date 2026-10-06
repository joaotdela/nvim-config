return {
  -- Render Markdown inside Neovim with nice formatting
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    ft = { "markdown" },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {
      heading = {
        icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
        border = true,
      },
      code = {
        style = "full",
        sign = true,
      },
      checkbox = {
        unchecked = { icon = "󰄱 " },
        checked = { icon = "󰱒 " },
      },
      bullet = {
        icons = { "●", "○", "◆", "◇" },
      },
    },
    keys = {
      {
        "mr",
        function()
          local rm = require("render-markdown")
          rm.toggle()
        end,
        ft = "markdown",
        desc = "[M]arkdown [R]ender toggle",
      },
    },
  },
  -- Live preview in the browser with hot-reload
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = "cd app && npm install",
    init = function()
      vim.g.mkdp_auto_close = 1
      vim.g.mkdp_theme = "dark"
      vim.g.mkdp_preview_options = {
        maid = {},
        disable_sync_scroll = 0,
        sync_scroll_type = "middle",
      }
    end,
    keys = {
      {
        "mp",
        "<cmd>MarkdownPreviewToggle<cr>",
        ft = "markdown",
        desc = "[M]arkdown [P]review in browser",
      },
    },
  },
}
