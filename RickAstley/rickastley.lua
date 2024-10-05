_addon.name = "RickAstley"
_addon.author = "mug0n"
_addon.version = "1.0.0"
_addon.commands = {"rickastley","rick"}

require("chat")
require("lists")
require("tables")
local config = require("config")
local packets = require("packets")
local res = require('resources')

defaults = T{
    buff_ids = L{},
    quiet_mode = false,
}

settings = config.load(defaults)
config.save(settings)


local prevent_messages = {
    "Never Gonna Give You Up: %s.",
    "Hold Me In Your Arms: %s.",
    "Don't Say Goodbye: %s.",
    "I Just Wanna Be With You : %s.",
}


function addon_message(text)
    windower.add_to_chat(7, "[" .. _addon.name:color(338) .. "] " .. text)
end


math.randomseed(os.time())

windower.register_event("outgoing chunk", function(id, original, modified, injected, blocked)
    if id == 0x0F1 then
        local packet = packets.parse("outgoing", original)
        local buff_id = packet["Buff"]

        if settings.buff_ids:contains(tostring(buff_id)) then
            -- find buff name by id
            local buff_name = res.buffs[buff_id].en or "Unknown"
            addon_message(string.format(prevent_messages[math.random(1, #prevent_messages)], buff_name))
            return true
        end
    end
    return false
end)


windower.register_event('addon command', function(command, ...)
    command = command and command:lower() or "help"
    local args = list.concat(L{...}, string.char(32)):lower()

    if command == "help" then
        addon_message("Usage: /rick <command> [argument]")
        addon_message("  add <buff name> - adds buff to the protection list")
        addon_message("  remove <buff name> - removes buff from the protection list")
        addon_message("  quiet - toggles quiet mode (prevent removal messages)")

    elseif table.contains(T{"add", "remove"}, command) then
        -- look for buff by name
        local buff_id
        local buff_name

        for k, v in ipairs(res.buffs) do
            if args == v.en:lower() then
                buff_id = k
                buff_name = v.en
                break
            end
        end

        if not buff_id then
            addon_message(string.format("Buff '%s' not found", args))
            return
        end

        if command == "add" then
            if not settings.buff_ids:contains(buff_id) then
                settings.buff_ids:append(buff_id)
                addon_message(string.format("Adding buff: %s.", buff_name))
            else
                addon_message(string.format("%s is already protected!", buff_name))
                return
            end
        elseif command == "remove" then
            if settings.buff_ids:contains(buff_id) then
                settings.buff_ids:remove(buff_id)
                addon_message(string.format("Removing buff: %s", buff_name))
            else
                addon_message(string.format("%s is not being protected!", buff_name))
                return
            end
        end

        -- update config
        config.save(settings)
    elseif command == "quiet" then
        -- toggle quiet mode
        settings.quiet_mode = not settings.quiet_mode
        addon_message(string.format("Quiet mode: %s.", settings.quiet_mode and "ON" or "OFF"))

        -- update config
        config.save(settings)
    else
        addon_message(string.format("Unknown command: %s, see //rick help for more information.", command))
    end
end)
