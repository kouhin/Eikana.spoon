--- === Eikana ===
---
--- A Hammerspoon spoon plugin that mimics the functionality of cmd-eikana for macOS.
--- It allows users to switch between different input methods using modifier keys.
---
--- Features:
---   - Switch between input sources by source ID
---   - Switch to Japanese with the native Kana key, like a JIS keyboard
---   - Switch to other input methods with macism when it is installed
---   - Customizable key mappings
---   - Support for both default and user-defined mappings
---
--- Usage:
---   local eikana = hs.loadSpoon("Eikana")
---   eikana:start()
---
--- @author Bin Hou
--- @version 2.0.0
--- @license MIT
--- @homepage https://github.com/kouhin/Eikana.spoon

-- Module definition
local obj = {}
obj.__index = obj

-- Metadata
obj.name = "Eikana"
obj.version = "2.0.0"
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
-- Path to macism (https://github.com/laishulu/macism), used to switch to input methods.
-- nil searches the Homebrew prefixes; false always uses TISSelectInputSource.
obj.macismPath = nil

-- Initialize logger
obj.logger = hs.logger.new('Eikana', 'info')

local specialKeyCodes = {
    eisuu = 102,
    kana = 104
}

local macismSearchPaths = {
    '/opt/homebrew/bin/macism',
    '/usr/local/bin/macism'
}

-- Seconds to wait for macism before giving up on it
local macismTimeout = 1

-- Tags the key events Eikana posts so its own event tap lets them through
local syntheticEventMarker = 0x45696B61 -- "Eika"

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

   When a background app such as Hammerspoon calls TISSelectInputSource to select a
   CJKV input method, the switch often does not take effect: the menu bar shows the new
   input method, but the focused app keeps typing with the old one. It still reports
   success, so retrying does not help. Eikana therefore avoids it for input methods:
     - Japanese (Kotoeri) is selected by posting the Kana key, as a JIS keyboard does.
     - Other input methods are selected by macism, which asks the focused app to switch.
     - Keyboard layouts are not affected and use TISSelectInputSource directly.
]]

-- While macism runs, later requests wait here so they cannot be overtaken by it.
-- Only the latest one is kept.
local pendingSourceID = nil
-- Hammerspoon stops tasks and timers once they are garbage collected, so keep references
---@type hs.task|nil
local macismTask = nil
---@type hs.timer
local macismWatchdog

--- Find the macism executable
--- @param path string|false|nil The configured macism path
--- @return string|nil The macism path, or nil when macism is not used
local function findMacism(path)
    if path == false then return nil end

    for _, candidate in ipairs(path and { path } or macismSearchPaths) do
        local attributes = hs.fs.attributes(candidate)
        if attributes ~= nil and attributes.mode == 'file' and attributes.permissions:find('x', 1, true) then
            return candidate
        end
    end

    if path then
        obj.logger.wf("macism not found: %s", path)
    end
    return nil
end

--- Decide how to switch to an input source
--- @param sourceID string The input source ID
--- @return string "kana", "layout" or "inputMethod"
local function getSwitchStrategy(sourceID)
    if sourceID:match('^com%.apple%.inputmethod%.Kotoeri%.%w+%.Japanese$') then
        return 'kana'
    elseif sourceID:find('.keylayout.', 1, true) then
        return 'layout'
    end
    return 'inputMethod'
end

--- Post a key press that Eikana's event tap lets through
--- @param keyCode integer The keycode to press
local function postKeyPress(keyCode)
    for _, isDown in ipairs({ true, false }) do
        hs.eventtap.event.newKeyEvent({}, keyCode, isDown)
            :setProperty(hs.eventtap.event.properties.eventSourceUserData, syntheticEventMarker)
            :post()
    end
end

--- Select an input source with TISSelectInputSource
--- @param sourceID string The input source ID
local function selectWithTIS(sourceID)
    if hs.keycodes.currentSourceID(sourceID) then
        obj.logger.df("Switched to input source: %s", sourceID)
    else
        obj.logger.ef("Failed to switch to input source: %s (is it enabled?)", sourceID)
    end
end

local switchInputSource

--- Select an input source with macism, falling back to TISSelectInputSource
--- @param sourceID string The input source ID
local function selectWithMacism(sourceID)
    local task
    task = hs.task.new(obj._macismPath, function(exitCode, stdOut, stdErr)
        if task ~= macismTask then return end -- Cancelled by stop()
        macismTask = nil
        macismWatchdog:stop()

        -- macism prints nothing on success; errors such as an unknown ID still exit with 0
        local output = ((stdOut or '') .. (stdErr or '')):gsub('%s+$', '')
        if exitCode == 0 and output == '' then
            obj.logger.df("Switched to input source with macism: %s", sourceID)
        else
            obj.logger.wf("macism failed (exit code %d): %s", exitCode, output)
            selectWithTIS(sourceID)
        end

        local nextSourceID = pendingSourceID
        pendingSourceID = nil
        if nextSourceID ~= nil then switchInputSource(nextSourceID) end
    end, { sourceID })

    if not task:start() then
        obj.logger.wf("Could not start macism: %s", obj._macismPath)
        selectWithTIS(sourceID)
        return
    end

    macismTask = task
    macismWatchdog = hs.timer.doAfter(macismTimeout, function()
        obj.logger.wf("macism timed out switching to: %s", sourceID)
        task:terminate()
    end)
end

--- Cancel the running macism switch and drop the pending one
local function cancelSwitch()
    pendingSourceID = nil
    if macismTask == nil then return end

    local task = macismTask
    macismTask = nil
    macismWatchdog:stop()
    task:terminate()
end

--- Switch to the specified input source ID
--- @param sourceID string The input source ID to switch to
function switchInputSource(sourceID)
    if macismTask ~= nil then
        pendingSourceID = sourceID
        return
    end

    local strategy = getSwitchStrategy(sourceID)
    if strategy == 'kana' then
        postKeyPress(specialKeyCodes.kana)
        obj.logger.df("Posted the Kana key to switch to: %s", sourceID)
    elseif strategy == 'inputMethod' and obj._macismPath ~= nil then
        selectWithMacism(sourceID)
    else
        selectWithTIS(sourceID)
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
        if event:getProperty(hs.eventtap.event.properties.eventSourceUserData) == syntheticEventMarker then
            return false
        end

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
    self:stop()

    self.mapping = {}
    if not self.override then
        for k, v in pairs(self._defaultMapping) do
            self.mapping[k] = v
        end
    end
    for k, v in pairs(self.userMapping) do
        self.mapping[k] = v
    end

    self._macismPath = findMacism(self.macismPath)
    if self._macismPath ~= nil then
        obj.logger.f("Switching input methods with macism: %s", self._macismPath)
    elseif self.macismPath ~= false then
        for _, sourceID in pairs(self.mapping) do
            if getSwitchStrategy(sourceID) == 'inputMethod' then
                obj.logger.wf("macism not found, switching to %s may not take effect", sourceID)
            end
        end
    end

    self.eventtap = self:bindKeyMethodMapping()
    self.eventtap:start()
    obj.logger.i("Eikana started successfully")
end

--- Stop the Eikana spoon
function obj:stop()
    cancelSwitch()
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
