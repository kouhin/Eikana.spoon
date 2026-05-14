--- === Eikana ===
---
--- A Hammerspoon spoon plugin that mimics the functionality of cmd-eikana for macOS.
--- It allows users to switch between different input methods using modifier keys.
---
--- Features:
---   - Switch between Romaji and Hiragana input methods
---   - Customizable key mappings
---   - Support for both default and user-defined mappings
---
--- Usage:
---   local eikana = hs.loadSpoon("Eikana")
---   eikana:start()
---
--- @author Bin Hou
--- @version 1.1.0
--- @license MIT
--- @homepage https://github.com/kouhin/Eikana.spoon

-- Module definition
local obj = {}
obj.__index = obj

-- Metadata
obj.name = "Eikana"
obj.version = "1.1.0"
obj.author = "Bin Hou"
obj.license = "MIT"
obj.homepage = "https://github.com/kouhin/Eikana.spoon"

-- Default configuration
obj._defaultMapping = {
    cmd = 'Romaji',
    rightcmd = 'Hiragana'
}

-- User configuration
obj.userMapping = {}
obj.override = false

-- Initialize logger
obj.logger = hs.logger.new('Eikana', 'info')

--[[
   Utility Functions
]]

--- Get the size of a table
--- @param t table The table to count
--- @return number The number of elements in the table
local function getTableSize(t)
    local count = 0
    for _, __ in pairs(t) do
        count = count + 1
    end
    return count
end

--[[
   Input Method Management
]]

--- Switch to the specified input method
--- @param method string The name of the input method to switch to
local function switchInputMethod(method)
    if method == 'Romaji' then
        hs.eventtap.keyStroke({}, 102)
        return
    elseif method == 'Hiragana' then
        hs.eventtap.keyStroke({}, 104)
        return
    end

    local maxRetries = 3
    local retryCount = 0
    local success = false

    while not success and retryCount < maxRetries do
        success = hs.keycodes.setMethod(method)
        if not success then
            retryCount = retryCount + 1
            if retryCount < maxRetries then
                hs.timer.usleep(100000) -- 100ms
            end
        end
    end

    if success then
        obj.logger.df("Successfully switched to input method: %s", method)
    else
        obj.logger.ef("Failed to switch to input method: %s after %d retries", method, maxRetries)
    end
end

--[[
   Event Handling
]]

--- Create an event handler for input method switching
--- @param mapping table The key-to-method mapping
--- @return function The event handler function
local function createEventHandler(mapping)
    return function(ev)
        local key = hs.keycodes.map[ev:getKeyCode()]
        local method = mapping[key]

        if method == nil then return end

        obj.logger.df("Switching input method to: %s", method)
        local success, err = pcall(switchInputMethod, method)
        if not success then
            obj.logger.ef("Failed to switch input method: %s", err)
        end
    end
end

--- Handle a single modifier key press event
--- @param keys table The keys to monitor
--- @param handler function The handler function
--- @return hs.eventtap The event tap object
local function addSingleModKeyPressEventListener(keys, handler)
    local targetKeyCodes = {}
    for _, v in pairs(keys) do
        targetKeyCodes[v] = true
    end

    local lastKeyCode = 0
    local lastFlagCount = 0

    local function resetState()
        if lastKeyCode ~= 0 then
            lastKeyCode = 0
        end
    end

    local function eventhandler(event)
        local code = event:getKeyCode()
        local flag = event:getFlags()

        if event:getType() == hs.eventtap.event.types.keyDown then
            return resetState()
        end

        if event:getType() == hs.eventtap.event.types.flagsChanged then
            local currentFlagCount = getTableSize(flag)
            if currentFlagCount == 0 then
                if lastFlagCount == 1 and code == lastKeyCode then
                    if not targetKeyCodes[hs.keycodes.map[code]] then
                        resetState()
                    else
                        handler(hs.eventtap.event.newKeyEvent(code, false))
                    end
                else
                    resetState()
                end
            elseif currentFlagCount == 1 then
                if lastFlagCount == 0 then
                    lastKeyCode = code
                else
                    resetState()
                end
            else
                resetState()
            end
            lastFlagCount = currentFlagCount
        end
    end

    return hs.eventtap.new(
        { hs.eventtap.event.types.keyDown, hs.eventtap.event.types.flagsChanged },
        eventhandler
    )
end

--[[
   Public Methods
]]

--- Handle an input event
--- @param ev hs.eventtap.event The event to handle
function obj:handleEvent(ev)
    local handler = createEventHandler(self.mapping)
    handler(ev)
end

--- Start the Eikana spoon
function obj:start()
    if self.eventtap ~= nil then
        self.eventtap:stop()
        self.eventtap = nil
    end

    self.mapping = {}
    if not self.override then
        for k, v in pairs(self._defaultMapping) do
            self.mapping[k] = v
        end
    end
    for k, v in pairs(self.userMapping) do
        self.mapping[k] = v
    end

    self.eventtap = self:bindKeyMethodMapping()
    self.eventtap:start()
    obj.logger.i("Eikana started successfully")
end

--- Stop the Eikana spoon
function obj:stop()
    if self.eventtap == nil then return end
    self.eventtap:stop()
    self.eventtap = nil
    obj.logger.i("Eikana stopped")
end

--- Bind key method mapping to event tap
--- @return hs.eventtap The event tap object
function obj:bindKeyMethodMapping()
    local keys = {}
    for k in pairs(self.mapping) do
        table.insert(keys, k)
    end

    return addSingleModKeyPressEventListener(keys, createEventHandler(self.mapping))
end

return obj
