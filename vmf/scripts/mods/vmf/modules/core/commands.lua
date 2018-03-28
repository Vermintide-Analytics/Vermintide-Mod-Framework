local vmf = get_mod("VMF")
--[[
  * letters' case doesn't matter
  * ctrl+c & ctrl+v
  * very flexible chat history without any glitches that occured in the past
  * commands are not shown if the mod is disabled

  not sure about UI scaling
]]
local _COMMANDS = {}

-- ####################################################################################################################
-- ##### VMFMod #######################################################################################################
-- ####################################################################################################################

VMFMod.command = function (self, command_name, command_description, command_function)

  if vmf.check_wrong_argument_type(self, "command", "command_name", command_name, "string") or
     vmf.check_wrong_argument_type(self, "command", "command_description", command_description, "string", "nil") or
     vmf.check_wrong_argument_type(self, "command", "command_function", command_function, "function") then

    return
  end

  if string.find(command_name, " ") then

    self:error("(command): command name can't contain spaces: [%s]", command_name)
    return
  end

  command_name = command_name:lower()

  if _COMMANDS[command_name] and _COMMANDS[command_name].mod ~= self then
    self:error("(command): command name '%s' is already used by another mod '%s'", command_name, _COMMANDS[command_name].mod:get_name())
    return
  end

  _COMMANDS[command_name] = {
    mod = self,
    exec_function = command_function,
    description = command_description,
    is_enabled = true
  }
end


VMFMod.command_remove = function (self, command_name)

  if vmf.check_wrong_argument_type(self, "command_remove", "command_name", command_name, "string") then
    return
  end

  _COMMANDS[command_name] = nil
end


VMFMod.command_disable = function (self, command_name)

  if vmf.check_wrong_argument_type(self, "command_disable", "command_name", command_name, "string") then
    return
  end

  if _COMMANDS[command_name] then
    _COMMANDS[command_name].is_enabled = false
  end
end


VMFMod.command_enable = function (self, command_name)

  if vmf.check_wrong_argument_type(self, "command_enable", "command_name", command_name, "string") then
    return
  end

  if _COMMANDS[command_name] then
    _COMMANDS[command_name].is_enabled = true
  end
end


VMFMod.remove_all_commands = function (self)

  for command_name, command_entry in pairs(_COMMANDS) do
    if command_entry.mod == self then
      _COMMANDS[command_name] = nil
    end
  end
end


VMFMod.disable_all_commands = function (self)
  for _, command_entry in pairs(_COMMANDS) do
    if command_entry.mod == self then
      command_entry.is_enabled = false
    end
  end
end


VMFMod.enable_all_commands = function (self)
  for _, command_entry in pairs(_COMMANDS) do
    if command_entry.mod == self then
      command_entry.is_enabled = true
    end
  end
end

-- ####################################################################################################################
-- ##### VMF internal functions and variables #########################################################################
-- ####################################################################################################################

vmf.get_commands_list = function(name_contains, exact_match)

  name_contains = name_contains:lower()

  local commands_list = {}

  for command_name, command_entry in pairs(_COMMANDS) do

    if exact_match then
      if command_name == name_contains and command_entry.is_enabled then
        table.insert(commands_list, {name = command_name, description = command_entry.description})
        break
      end
    else
      if string.sub(command_name, 1, string.len(name_contains)) == name_contains and command_entry.is_enabled and command_entry.mod:is_enabled() then
        table.insert(commands_list, {name = command_name, description = command_entry.description})
      end
    end
  end

  table.sort(commands_list, function(a, b) return a.name < b.name end)

  return commands_list
end


vmf.run_command = function(command_name, ...)

  local command_entry = _COMMANDS[command_name]
  if command_entry then
    local success, error_message = pcall(command_entry.exec_function, ...)
    if not success then
      command_entry.mod:error("(commands) in command '%s': %s", command_name, tostring(error_message))
    end
  else
    vmf:error("(commands): command '%s' wasn't found.", command_name) -- should never see this
  end
end