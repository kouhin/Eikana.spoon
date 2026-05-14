---@meta

---@class hs.eventtap
local Eventtap = {}

function Eventtap:start() end

function Eventtap:stop() end

---@class hs.eventtap.event
local EventtapEvent = {}

---@return integer
function EventtapEvent:getKeyCode() end

---@return table
function EventtapEvent:getFlags() end

---@return integer
function EventtapEvent:getType() end

---@class hs.logger
local Logger = {}

---@param message string
function Logger.i(message) end

---@param format string
---@param ... any
function Logger.df(format, ...) end

---@param format string
---@param ... any
function Logger.wf(format, ...) end

---@param format string
---@param ... any
function Logger.ef(format, ...) end

---@class hs.keycodes
---@field map table

---@class hs.eventtap.event.module
---@field types hs.eventtap.event.types

---@class hs.eventtap.module
---@field event hs.eventtap.event.module

---@class hs.eventtap.event.types
---@field keyDown integer
---@field keyUp integer
---@field flagsChanged integer

---@class hs.timer

---@class hs
---@field keycodes hs.keycodes
---@field eventtap hs.eventtap.module
---@field timer hs.timer
---@field logger table
hs = {}
hs.keycodes = {}
hs.eventtap = {}
hs.eventtap.event = {}
hs.eventtap.event.types = {}
hs.timer = {}
hs.logger = {}

---@param name string
---@param level string
---@return hs.logger
function hs.logger.new(name, level) end

---@overload fun(): string
---@param sourceID string
---@return boolean
function hs.keycodes.currentSourceID(sourceID) end

---@param sourceIDs? boolean
---@return table
function hs.keycodes.methods(sourceIDs) end

---@param sourceIDs? boolean
---@return table
function hs.keycodes.layouts(sourceIDs) end

---@param modifiers table
---@param key string|integer
function hs.eventtap.keyStroke(modifiers, key) end

---@param events table
---@param callback function
---@return hs.eventtap
function hs.eventtap.new(events, callback) end

---@param key string|integer
---@param isDown boolean
---@return hs.eventtap.event
function hs.eventtap.event.newKeyEvent(key, isDown) end

---@param seconds number
---@param callback function
function hs.timer.doAfter(seconds, callback) end

---@param microseconds integer
function hs.timer.usleep(microseconds) end
