local compile_commands = {}

function compile_commands.refresh(opts)
  if not vim.g.current_bazel_package then
    vim.notify("No Bazel platform set. Use :BazelSetPackage first.", vim.log.levels.ERROR)
    return
  end
  local target_suffix = opts.args ~= "" and opts.args or "linux"
  -- Using hedron_compile_commands to generate compile_commands.json
  vim.cmd("terminal bazel run " .. vim.g.current_bazel_package .. ":compile_commands_" .. target_suffix)
end

function compile_commands.setup()
  -- Command to refresh compile commands
  vim.api.nvim_create_user_command("BazelRefreshCompileCommands", compile_commands.refresh, {
    desc = "Refresh compile_commands.json for the current target",
    nargs = "?",
    complete = function()
      return { "linux", "test" }
    end,
  })
end

return compile_commands
