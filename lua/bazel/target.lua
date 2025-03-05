local settings = require("bazel.settings")
local target_module = {
  -- Cache for Bazel targets within packages
  cache = {
    targets = {},
    timestamp = 0,
    ttl = 30, -- Cache TTL in seconds
  },
}
-- Function to get all targets in a package
function target_module.get_all_in_package(package)
  local current_time = os.time()
  local cache_key = package or ""

  -- Return cached results if they're still valid
  if
    target_module.cache.targets[cache_key] and current_time - target_module.cache.timestamp < target_module.cache.ttl
  then
    return target_module.cache.targets[cache_key]
  end

  -- Update cache
  local handle = io.popen("bazel query '" .. package .. ":*' --output label")
  if not handle then
    return {}
  end

  local result = handle:read("*a")
  handle:close()

  local target_list = {}
  for target in result:gmatch("[^\r\n]+") do
    table.insert(target_list, target)
  end

  target_module.cache.targets[cache_key] = target_list
  target_module.cache.timestamp = current_time

  return target_list
end
function target_module.set()
  if not vim.g.current_bazel_package then
    vim.notify("No Bazel package set. Use :BazelSetPackage first.", vim.log.levels.ERROR)
    return
  end

  local available_targets = target_module.get_all_in_package(vim.g.current_bazel_package)
  if #available_targets == 0 then
    vim.notify("No targets found in package: " .. vim.g.current_bazel_package, vim.log.levels.WARN)
    return
  end

  vim.ui.select(available_targets, {
    prompt = "Select Bazel target:",
    format_item = function(item)
      return item
    end,
  }, function(selected_target)
    if selected_target then
      vim.g.current_bazel_target = selected_target
      settings.save()
      vim.notify("Bazel target set to: " .. selected_target)
    end
  end)
end

function target_module.refresh()
  if not vim.g.current_bazel_package then
    vim.notify("No Bazel package set. Use :BazelSetPackage first.", vim.log.levels.ERROR)
    return
  end
  target_module.cache.timestamp = 0 -- Force cache refresh
  local targets = target_module.get_all_in_package(vim.g.current_bazel_package)
  vim.notify("Refreshed Bazel targets cache. Found " .. #targets .. " targets in package.")
end

function target_module.setup()
  vim.api.nvim_create_user_command("BazelSetTarget", target_module.set, { desc = "Set the current Bazel target" })

  vim.api.nvim_create_user_command(
    "BazelRefreshTargets",
    target_module.refresh,
    { desc = "Refresh the Bazel targets cache" }
  )
end

return target_module
