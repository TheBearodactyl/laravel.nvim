local Layout = require("nui.layout")
local Popup = require("nui.popup")
local Input = require("nui.input")
local app = require("laravel").app
local event = require("nui.utils.autocmd").event
local preview = require("laravel.pickers.common.preview")

local function scroll_fn(popup, direction)
  return function()
    local scroll = vim.api.nvim_get_option_value("scroll", { win = popup.winid })
    vim.api.nvim_win_call(popup.winid, function()
      vim.cmd("normal! " .. scroll .. direction)
    end)
  end
end

return function(command)
  local entry_popup = Input({
    focusable = true,
    border = {
      style = "rounded",
      text = {
        top = "Artisan",
        top_align = "center",
      },
    },
    win_options = {
      winhighlight = "Normal:LaravelPrompt",
    },
  }, {
    prompt = "$ artisan " .. command.name .. " ",
    on_submit = function(input)
      local args = vim.fn.split(input, " ", false)
      table.insert(args, 1, command.name)

      app("runner"):run("artisan", args)
    end,
  })

  local help_popup = Popup({
    border = {
      style = "rounded",
      text = {
        top = "Help (<c-c> to cancel)",
        top_align = "center",
      },
    },
    win_options = {
      winhighlight = "Normal:LaravelHelp",
    },
  })

  local command_preview = preview.command(command)

  vim.api.nvim_buf_set_lines(help_popup.bufnr, 0, -1, false, command_preview.lines)

  local hl = vim.api.nvim_create_namespace("laravel")
  for _, value in pairs(command_preview.highlights) do
    vim.api.nvim_buf_add_highlight(help_popup.bufnr, hl, value[1], value[2], value[3], value[4])
  end

  entry_popup:map("i", "<c-d>", scroll_fn(help_popup, "j"))
  entry_popup:map("n", "<c-d>", scroll_fn(help_popup, "j"))
  entry_popup:map("i", "<c-u>", scroll_fn(help_popup, "k"))
  entry_popup:map("n", "<c-u>", scroll_fn(help_popup, "k"))

  local boxes = {
    Layout.Box(entry_popup, { size = 3 }), -- 3 because of borders to be 1 row
    Layout.Box(help_popup, { grow = 1 }),
  }

  local layout = Layout({
    position = "50%",
    size = {
      width = "80%",
      height = "90%",
    },
    relative = "editor",
  }, Layout.Box(boxes, { dir = "col" }))

  entry_popup:map("i", "<c-c>", function()
    layout:unmount()
  end)

  entry_popup:map("n", "<c-c>", function()
    layout:unmount()
  end)

  entry_popup:map("n", "<Esc>", function()
    layout:unmount()
  end)

  entry_popup:map("i", "<Esc>", function()
    layout:unmount()
  end)

  entry_popup:on(event.BufLeave, function()
    layout:unmount()
  end)

  layout:mount()

  -- hack for starting in insert mode
  vim.defer_fn(function()
    vim.api.nvim_command("startinsert!")
  end, 20)
end
