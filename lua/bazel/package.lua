local settings = require("bazel.settings")

local bazel_package = {
  -- Cache for Bazel packages
  _cache = {
    packages = {},
    timestamp = 0,
    ttl = 30, -- Cache TTL in seconds
  },
}
function bazel_package.get()
  local current_time = os.time()

  -- Return cached results if they're still valid
  if current_time - bazel_package._cache.timestamp < bazel_package._cache.ttl then
    return bazel_package._cache.packages
  end

  -- Update cache
  local handle = io.popen("bazel query //... --output package")
  if not handle then
    return bazel_package._cache.packages
  end

  local result = handle:read("*a")
  handle:close()

  local packages = {}

  for pkg in result:gmatch("[^\r\n]+") do
    table.insert(packages, pkg)
  end

  bazel_package._cache.packages = packages
  bazel_package._cache.timestamp = current_time

  return packages
end

function bazel_package.set()
  local packages = bazel_package.get()
  vim.ui.select(packages, {
    prompt = "Select Bazel package:",
    format_item = function(item)
      return item
    end,
  }, function(selected_package)
    if selected_package then
      vim.g.current_bazel_package = selected_package
      settings.save()
      vim.notify("Bazel package set to: " .. selected_package)
    end
  end)
end

function bazel_package.refresh()
  bazel_package._cache.timestamp = 0 -- Force cache refresh

  local packages = bazel_package.get()
  vim.notify("Refreshed Bazel Package cache. Found " .. #packages .. " packages.")
  return packages
end

function bazel_package.setup()
  vim.api.nvim_create_user_command("BazelSetPackage", bazel_package.set, { desc = "Set the current Bazel package" })

  vim.api.nvim_create_user_command(
    "BazelRefreshPackages",
    bazel_package.refresh,
    { desc = "Refresh the Bazel package cache" }
  )
end

return bazel_package
