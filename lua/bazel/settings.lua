local settings = {}

-- Function to load settings from JSON file
function settings.load()
  local config_path = vim.fn.stdpath("data") .. "/bazel_settings.json"
  local file = io.open(config_path, "r")
  if file then
    local content = file:read("*all")
    file:close()
    local ok, config_data = pcall(vim.json.decode, content)
    if ok and config_data then
      return config_data
    end
  end
  return {}
end

-- Function to save settings to JSON file
function settings.save()
  local config_path = vim.fn.stdpath("data") .. "/bazel_settings.json"
  local config_data = {
    current_package = vim.g.current_bazel_package,
    current_target = vim.g.current_bazel_target,
    current_platform = vim.g.current_bazel_platform,
  }
  local file = io.open(config_path, "w")
  if file then
    file:write(vim.json.encode(config_data))
    file:close()
  end
end

return settings
