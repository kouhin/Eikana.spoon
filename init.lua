--- === Eikana ===
---
--- A Hammerspoon spoon plugin that mimics the functionality of cmd-eikana for macOS.
--- It allows users to switch between different input methods using modifier keys.
---
--- Features:
---   - Switch between input sources by source ID
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
    cmd = 'com.apple.keylayout.ABC',
    rightcmd = 'com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese'
}

-- User configuration
obj.userMapping = {}
obj.override = false

-- Initialize logger
obj.logger = hs.logger.new('Eikana', 'info')

local specialKeyCodes = {
    eisuu = 102,
    kana = 104
}

local modifierKeys = {
    cmd = true,
    rightcmd = true,
    alt = true,
    rightalt = true,
    shift = true,
    rightshift = true,
    ctrl = true,
    rightctrl = true
}

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

--- Resolve a configured key name to a numeric keycode
--- @param key string The configured key name
--- @return number|nil The resolved keycode
local function resolveKeyCode(key)
    return specialKeyCodes[key] or hs.keycodes.map[key]
end

--- Build keycode-based mappings for event handling
--- @param mapping table The key-to-source-ID mapping
--- @return table, table, table Source ID mapping, modifier keycodes, regular keycodes
local function buildKeyCodeMapping(mapping)
    local keyCodeMapping = {}
    local modifierKeyCodes = {}
    local regularKeyCodes = {}

    for key, sourceID in pairs(mapping) do
        local code = resolveKeyCode(key)

        if code == nil then
            obj.logger.wf("Ignoring unknown key mapping: %s", key)
        elseif specialKeyCodes[key] ~= nil then
            keyCodeMapping[code] = sourceID
            regularKeyCodes[code] = true
        elseif modifierKeys[key] then
            keyCodeMapping[code] = sourceID
            modifierKeyCodes[code] = true
        else
            obj.logger.wf("Ignoring unsupported non-modifier key mapping: %s", key)
        end
    end

    return keyCodeMapping, modifierKeyCodes, regularKeyCodes
end

--[[
   Input Method Management
]]

--- Switch to the specified input source ID
--- @param sourceID string The input source ID to switch to
local function switchInputSource(sourceID)
    local maxRetries = 3
    local retryCount = 0
    local success = false

    while not success and retryCount < maxRetries do
        success = hs.keycodes.currentSourceID(sourceID) == true
        if not success then
            retryCount = retryCount + 1
            if retryCount < maxRetries then
                hs.timer.usleep(100000) -- 100ms
            end
        end
    end

    if success then
        obj.logger.df("Successfully switched to input source: %s", sourceID)
    else
        obj.logger.ef("Failed to switch to input source: %s after %d retries", sourceID, maxRetries)
    end
end

--[[
   Event Handling
]]

--- Create an event handler for input source switching
--- @param keyCodeMapping table The keycode-to-source-ID mapping
--- @return function The event handler function
local function createEventHandler(keyCodeMapping)
    return function(ev)
        local sourceID = keyCodeMapping[ev:getKeyCode()]

        if sourceID == nil then return end

        obj.logger.df("Switching input source to: %s", sourceID)
        local success, err = pcall(switchInputSource, sourceID)
        if not success then
            obj.logger.ef("Failed to switch input source: %s", err)
        end
    end
end

--- Handle a single modifier key press event
--- @param modifierKeyCodes table The modifier keycodes to monitor
--- @param regularKeyCodes table The regular keycodes to monitor
--- @param handler function The handler function
--- @return hs.eventtap The event tap object
local function addKeyPressEventListener(modifierKeyCodes, regularKeyCodes, handler)
    local lastKeyCode = 0
    local lastFlagCount = 0

    local function resetState()
        lastKeyCode = 0
    end

    local function eventhandler(event)
        local code = event:getKeyCode()
        local flag = event:getFlags()

        if event:getType() == hs.eventtap.event.types.keyDown then
            resetState()

            if regularKeyCodes[code] then
                handler(event)
                return true
            end

            return false
        end

        if event:getType() == hs.eventtap.event.types.keyUp then
            if regularKeyCodes[code] then
                return true
            end

            return false
        end

        if event:getType() == hs.eventtap.event.types.flagsChanged then
            local currentFlagCount = getTableSize(flag)

            if currentFlagCount == 0 then
                if lastFlagCount == 1 and code == lastKeyCode then
                    if not modifierKeyCodes[code] then
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

        return false
    end

    return hs.eventtap.new(
        {
            hs.eventtap.event.types.keyDown,
            hs.eventtap.event.types.keyUp,
            hs.eventtap.event.types.flagsChanged
        },
        eventhandler
    )
end

--[[
   Public Methods
]]

--- Handle an input event
--- @param ev hs.eventtap.event The event to handle
function obj:handleEvent(ev)
    local keyCodeMapping = buildKeyCodeMapping(self.mapping)
    local handler = createEventHandler(keyCodeMapping)
    handler(ev)
end

--- Print enabled input source names and IDs to the Hammerspoon Console
function obj:listInputSources()
    local methodNames = hs.keycodes.methods()
    local methodIDs = hs.keycodes.methods(true)
    local layoutNames = hs.keycodes.layouts()
    local layoutIDs = hs.keycodes.layouts(true)

    print("Input methods:")
    for i, sourceID in ipairs(methodIDs) do
        print(string.format("  %s -> %s", methodNames[i] or "(unknown)", sourceID))
    end

    print("Keyboard layouts:")
    for i, sourceID in ipairs(layoutIDs) do
        print(string.format("  %s -> %s", layoutNames[i] or "(unknown)", sourceID))
    end
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
    local keyCodeMapping, modifierKeyCodes, regularKeyCodes = buildKeyCodeMapping(self.mapping)

    return addKeyPressEventListener(modifierKeyCodes, regularKeyCodes, createEventHandler(keyCodeMapping))
end

return obj
