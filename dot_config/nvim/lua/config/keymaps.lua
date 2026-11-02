-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode", silent = true })
vim.keymap.set("i", "kj", "<ESC>", { desc = "Exit insert mode", silent = true })

-- Temporarily use the top letter row to enter a Normal-mode count.
local number_keys = "qwertyuiop"
local number_buffer
local saved_number_maps = {}

local function leave_number_mode()
  if not number_buffer then
    return
  end
  local buffer = number_buffer
  number_buffer = nil
  if vim.api.nvim_buf_is_valid(buffer) then
    vim.api.nvim_buf_call(buffer, function()
      for key in number_keys:gmatch(".") do
        vim.keymap.del("n", key, { buffer = buffer })
        if saved_number_maps[key] then
          vim.fn.mapset("n", false, saved_number_maps[key])
        end
      end
    end)
  end
  saved_number_maps = {}
  vim.api.nvim_echo({ { "", "Normal" } }, false, {})
end

vim.keymap.set("n", ",", function()
  if number_buffer then
    leave_number_mode()
    return "<Esc>"
  end
  number_buffer = vim.api.nvim_get_current_buf()
  for index = 1, #number_keys do
    local key = number_keys:sub(index, index)
    local mapping = vim.fn.maparg(key, "n", false, true)
    if mapping.buffer == 1 then
      saved_number_maps[key] = mapping
    end
    vim.keymap.set("n", key, tostring(index % 10), { buffer = number_buffer, nowait = true })
  end
  vim.api.nvim_echo({ { "Number mode", "ModeMsg" } }, false, {})
  return ""
end, { expr = true, desc = "Toggle number mode" })

-- Keep collecting digits until the next command, then restore normal keys.
vim.on_key(function(key)
  if number_buffer and not key:match("^%d$") then
    leave_number_mode()
  end
end, vim.api.nvim_create_namespace("number_mode"))

vim.api.nvim_create_autocmd({ "BufLeave", "InsertEnter", "CmdlineEnter" }, {
  group = vim.api.nvim_create_augroup("number_mode", { clear = true }),
  callback = leave_number_mode,
})
