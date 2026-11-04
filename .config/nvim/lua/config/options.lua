-- lua/config/options.lua
-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
-- Undercurl
vim.cmd([[let &t_Cs = "\e[4:3m"]])
vim.cmd([[let &t_Ce = "\e[4:0m"]])

-- Autowarpping
vim.opt.wrap = true

-- Disable Noice
vim.opt.showmode = false

-- Clipboard over OSC 52 when no local clipboard tool exists (devcontainer/devpod/ssh).
-- Copy goes through the terminal (Ghostty) to the host clipboard; paste falls back to
-- nvim's own registers so Ghostty doesn't prompt for clipboard-read on every `p`.
local has_local_clip = (vim.env.WAYLAND_DISPLAY and vim.fn.executable("wl-copy") == 1)
  or (vim.env.DISPLAY and (vim.fn.executable("xclip") == 1 or vim.fn.executable("xsel") == 1))
if not has_local_clip then
  local osc52 = require("vim.ui.clipboard.osc52")
  local function paste()
    return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
  end
  vim.g.clipboard = {
    name = "OSC 52",
    copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
    paste = { ["+"] = paste, ["*"] = paste },
  }
end
