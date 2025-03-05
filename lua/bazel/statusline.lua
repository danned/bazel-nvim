local package_module = require("bazel.package")
local platform = require("bazel.platform")
local statusline = {}

function statusline.setup()
  -- Check if lualine is available
  local has_lualine, lualine = pcall(require, "lualine")
  if not has_lualine then
    return
  end

  -- Get current lualine config
  local config = lualine.get_config()

  -- Add our component
  table.insert(config.sections.lualine_c, 1, {
    function()
      local current_package = vim.g.current_bazel_package or "No package"
      return "Bazel: " .. current_package
    end,
    on_click = function()
      package_module.set()
    end,

    icon = vim.g.current_bazel_platform_icon or "",
  })

  -- Apply the updated config
  lualine.setup(config)
end

return statusline
