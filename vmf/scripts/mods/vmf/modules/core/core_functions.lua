--@TODO: return right after output function call if it's not used in chat and in log
--@TODO: move logging options to developer mode in options menu
local vmf = get_mod("VMF")

local _UNSENT_CHAT_MESSAGES = {}
local _LOGGING_SETTINGS

-- ####################################################################################################################
-- ##### Local functions ##############################################################################################
-- ####################################################################################################################

local function safe_format(mod, str, ...)

  -- the game still crash with unknown error if there is non-standard character after '%' @TODO: any solutions?
  local success, message = pcall(string.format, str, ...)

  if success then
    return message
  else
    mod:error("string.format: " .. tostring(message)) --@TODO: good description
  end
end

local function pack_pcall(status, ...)

  return status, {...}
end

local function send_to_chat(message)

  if Managers.chat and Managers.chat:has_channel(1) then
    Managers.chat:add_local_system_message(1, message, true)
  else
    table.insert(_UNSENT_CHAT_MESSAGES, message)
  end
end

local function send_to_log(message)

  print("[MOD]" .. message)
end

-- ####################################################################################################################
-- ##### VMFMod #######################################################################################################
-- ####################################################################################################################

VMFMod.echo = function (self, message, ...)

  message = tostring(message)

  message = safe_format(self, message, ...)

  if message then
    if _LOGGING_SETTINGS.echo.send_to_chat then
      send_to_chat(message)
    end

    message = "[" .. self:get_name() .. "][ECHO] " .. message

    if _LOGGING_SETTINGS.echo.send_to_log then
      send_to_log(message)
    end
  end
end


VMFMod.error = function (self, message, ...)

  message = tostring(message)

  message = safe_format(self, message, ...)

  if message then
    message = "[" .. self:get_name() .. "][ERROR] " .. message

    if _LOGGING_SETTINGS.error.send_to_chat then
      send_to_chat(message)
    end

    if _LOGGING_SETTINGS.error.send_to_log then
      send_to_log(message)
    end
  end
end


VMFMod.warning = function (self, message, ...)

  message = tostring(message)

  message = safe_format(self, message, ...)

  if message then
    message = "[" .. self:get_name() .. "][WARNING] " .. message

    if _LOGGING_SETTINGS.warning.send_to_chat then
      send_to_chat(message)
    end

    if _LOGGING_SETTINGS.warning.send_to_log then
      send_to_log(message)
    end
  end
end


VMFMod.info = function (self, message, ...)

  message = tostring(message)

  message = safe_format(self, message, ...)

  if message then
    message = "[" .. self:get_name() .. "][INFO] " .. message

    if _LOGGING_SETTINGS.info.send_to_chat then
      send_to_chat(message)
    end

    if _LOGGING_SETTINGS.info.send_to_log then
      send_to_log(message)
    end
  end
end


VMFMod.debug = function (self, message, ...)

  message = tostring(message)

  message = safe_format(self, message, ...)

  if message then
    message = "[" .. self:get_name() .. "][DEBUG] " .. message

    if _LOGGING_SETTINGS.debug.send_to_chat then
      send_to_chat(message)
    end

    if _LOGGING_SETTINGS.debug.send_to_log then
      send_to_log(message)
    end
  end
end


VMFMod.pcall = function (self, ...)
  local status, values = pack_pcall(pcall(...))

  if not status then
    self:error("(pcall): %s", tostring(values[1]))
  end

  return status, unpack(values)
end


VMFMod.dofile = function (self, script_path)

  local success, values = pack_pcall(pcall(dofile, script_path))

  if not success then

    if values[1].error then
      self:error("(dofile): %s", values[1].error)
      print("\nTRACEBACK:\n\n" .. values[1].traceback .. "\nLOCALS:\n\n" .. values[1].locals)
    else
      self:error("(dofile): %s", tostring(values[1]))
    end
  end

  return unpack(values)
end

-- ####################################################################################################################
-- ##### VMF internal functions and variables #########################################################################
-- ####################################################################################################################
-- @TODO: maybe it doesn't belong in here
vmf.check_wrong_argument_type = function(mod, vmf_function_name, argument_name, argument, ...)

  local allowed_types = {...}
  local argument_type = type(argument)

  for _, allowed_type in ipairs(allowed_types) do
    if allowed_type == argument_type then
      return false
    end
  end

  mod:error("(%s): argument '%s' should have the '%s' type, not '%s'", vmf_function_name, argument_name, table.concat(allowed_types, "/"), argument_type)

  return true
end

vmf.unsent_chat_messages = _UNSENT_CHAT_MESSAGES

vmf.load_logging_settings = function ()

  _LOGGING_SETTINGS = {
    echo    = vmf:get("logging_mode") == "custom" and vmf:get("output_mode_echo"),--    or 3, @TODO: clean up?
    error   = vmf:get("logging_mode") == "custom" and vmf:get("output_mode_error"),--   or 3,
    warning = vmf:get("logging_mode") == "custom" and vmf:get("output_mode_warning"),-- or 3,
    info    = vmf:get("logging_mode") == "custom" and vmf:get("output_mode_info"),--    or 1,
    debug   = vmf:get("logging_mode") == "custom" and vmf:get("output_mode_debug"),--   or 0,
  }

  for method_name, logging_mode in pairs(_LOGGING_SETTINGS) do
    _LOGGING_SETTINGS[method_name] = {
      send_to_chat = logging_mode and logging_mode >= 2,
      send_to_log  = logging_mode and logging_mode % 2 == 1
    }
  end
end

-- ####################################################################################################################
-- ##### Script #######################################################################################################
-- ####################################################################################################################

vmf.load_logging_settings()