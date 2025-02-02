local GLOBALS = require("kulala.globals")
local FS = require("kulala.utils.fs")
local FORMATTER = require("kulala.formatter")
local EXT_PROCESSING = require("kulala.external_processing")
local INT_PROCESSING = require("kulala.internal_processing")

local M = {}

-- runs the cmd and maybe formats the result
M.run = function(result, callback)
  vim.fn.jobstart(result.cmd, {
    on_stderr = function(_, datalist)
      if callback then
        if #datalist > 0 and #datalist[1] > 0 then
          vim.notify(vim.inspect(datalist), vim.log.levels.ERROR)
        end
      end
    end,
    on_exit = function(_, code)
      local success = code == 0
      if success then
        local body = FS.read_file(GLOBALS.BODY_FILE)
        if result.ft ~= "text" then
          FS.write_file(GLOBALS.BODY_FILE, FORMATTER.format(result.ft, body))
        end
        for _, metadata in ipairs(result.metadata) do
          if metadata then
            if metadata.name == "env-json-key" then
              INT_PROCESSING.env_json_key(metadata.value, body)
            elseif metadata.name == "env-header-key" then
              INT_PROCESSING.env_header_key(metadata.value)
            elseif metadata.name == "stdin-cmd" then
              EXT_PROCESSING.stdin_cmd(metadata.value, body)
            elseif metadata.name == "env-stdin-cmd" then
              EXT_PROCESSING.env_stdin_cmd(metadata.value, body)
            end
          end
        end
      end
      if callback then
        callback(success)
      end
    end,
  })
end

return M
