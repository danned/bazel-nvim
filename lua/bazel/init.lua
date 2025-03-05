local compile_commands = require("bazel.compile_commands")
local executor = require("bazel.executor")
local package_module = require("bazel.package")
local platform = require("bazel.platform")
local settings = require("bazel.settings")
local target = require("bazel.target")
local statusline = require("bazel.statusline")

local M = {}

function M.setup(opts)
  local config = settings.load()
  vim.g.bazel_platform_prefix = opts.bazel_platform_prefix or ""
  vim.g.current_bazel_package = config.current_package
  vim.g.current_bazel_target = config.current_target
  vim.g.current_bazel_platform = config.current_platform

  platform.set_helper(vim.g.current_bazel_platform)

  compile_commands.setup()
  executor.setup()
  platform.setup()
  target.setup()
  package_module.setup()
  statusline.setup()
end

return M
