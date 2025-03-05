local settings = require("bazel.settings")
local platform = {
  -- Cache for platforms
  _cache = {
    platforms = {},
    timestamp = 0,
    ttl = 300, -- Cache TTL in seconds (5 minutes since platforms change less frequently)
  },
}
local function get_platforms()
  local current_time = os.time()

  -- Return cached results if they're still valid
  if current_time - platform._cache.timestamp < platform._cache.ttl then
    return platform._cache.platforms
  end
  -- Update cache
  local handle = io.popen("bazel query 'kind(platform, //platforms/...)'")
  if not handle then
    return platform._cache.platforms
  end

  local result = handle:read("*a")
  handle:close()

  local platforms = {}
  for platform_item in result:gmatch("[^\r\n]+") do
    print(platform_item)
    -- Extract platform name from @local_config_platform//:platform_name
    local name = platform_item:match("//platforms:([%w_-]+)")
    if name then
      table.insert(platforms, name)
    end
  end

  -- If no platforms found, fallback to default platforms
  if #platforms == 0 then
    platforms = {
      "target",
      "host",
    }
  end

  platform._cache.platforms = platforms
  platform._cache.timestamp = current_time

  return platforms
end

-- Function to set the platform icon based on platform name
function platform.set_helper(platform_name)
  if platform_name and platform_name:lower():match("linux") then
    vim.g.current_bazel_platform_icon = "" -- host icon
  else
    vim.g.current_bazel_platform_icon = "" -- target icon
  end
end

function platform.set()
  local available_platforms = get_platforms()
  vim.ui.select(available_platforms, {
    prompt = "Select platform:",
    format_item = function(item)
      return item .. (item == vim.g.current_bazel_platform and " (current)" or "")
    end,
  }, function(selected_platform)
    if selected_platform then
      -- Set the global variable for current platform
      vim.g.current_bazel_platform = selected_platform

      -- Set the platform icon
      platform.set_helper(selected_platform)

      -- Invalidate cache since targets might be different for different platforms
      platform._cache.timestamp = 0
      settings.save()
      vim.notify("Platform set to: " .. selected_platform)
    end
  end)
end

function platform.setup()
  vim.api.nvim_create_user_command("BazelSetPlatform", platform.set, { desc = "Set the current platform" })

  vim.api.nvim_create_user_command("BazelRefreshPlatforms", function()
    platform._cache.timestamp = 0 -- Force cache refresh
    local platforms = platform.get_platforms()
    vim.notify("Refreshed Bazel platforms cache. Found " .. #platforms .. " platforms.")
  end, { desc = "Refresh the Bazel platforms cache" })
end

return platform
