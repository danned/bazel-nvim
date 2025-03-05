local executor = {}
-- Function to parse error line into quickfix entry
function executor.parse_error_line(line)
  -- Skip empty lines
  if line == "" then
    return nil
  end

  -- Handle "In file included from..." lines
  local included_file = line:match("In file included from ([^:]+):%d+")
  if included_file then
    return { text = line }
  end

  -- Handle lines starting with spaces or pipes (continuation of previous error)
  if line:match("^%s*|+%s*") then
    return { text = line }
  end

  -- Match standard error patterns like "path/to/file:line:col: error: message"
  local file, lnum, col, msg = line:match("([^:]+):(%d+):(%d+):%s*(.*)")
  if file and lnum then
    return {
      filename = file,
      lnum = tonumber(lnum),
      col = tonumber(col) or 1,
      text = msg or line,
    }
  end

  -- Try matching without column number
  file, lnum, msg = line:match("([^:]+):(%d+):%s*(.*)")
  if file and lnum then
    return {
      filename = file,
      lnum = tonumber(lnum),
      col = 1,
      text = msg or line,
    }
  end

  -- If no match, return just the text
  return { text = line }
end

-- Function to execute bazel command and show output in quickfix
function executor.bazel_command(cmd)
  -- Clear and open quickfix window
  vim.fn.setqflist({}, "r")
  vim.cmd("copen")

  -- Store all output lines
  local qf_entries = {}

  -- Start job
  local job_id = vim.fn.jobstart(cmd, {
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            local entry = executor.parse_error_line(line)
            table.insert(qf_entries, entry)
            vim.fn.setqflist({}, "a", { items = { entry } })
            vim.cmd("cbottom")
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            local entry = executor.parse_error_line(line)
            table.insert(qf_entries, entry)
            vim.fn.setqflist({}, "a", { items = { entry } })
            vim.cmd("cbottom")
          end
        end
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        vim.notify("Command completed successfully", vim.log.levels.INFO)
      else
        vim.notify("Command failed with exit code: " .. exit_code, vim.log.levels.ERROR)
      end
    end,
    stdout_buffered = false,
    stderr_buffered = false,
  })

  if job_id == 0 then
    vim.notify("Failed to start job", vim.log.levels.ERROR)
  elseif job_id == -1 then
    vim.notify("Invalid command", vim.log.levels.ERROR)
  end
end
function executor.build()
  if not vim.g.current_bazel_target then
    vim.notify("No Bazel target set. Use :BazelSetTarget first.", vim.log.levels.ERROR)
    return
  end

  local cmd = "bazel build --platforms=@sparc//platforms:"
    .. vim.g.current_bazel_platform
    .. " "
    .. vim.g.current_bazel_target
  executor.bazel_command(cmd)
end

function executor.setup()
  -- Command to build the current target
  vim.api.nvim_create_user_command("BazelBuild", executor.build, { desc = "Build the current Bazel target" })
end

return executor
