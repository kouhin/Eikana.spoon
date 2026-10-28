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

---@param property integer
---@return number
function EventtapEvent:getProperty(property) end

---@param property integer
---@param value number
---@return hs.eventtap.event
function EventtapEvent:setProperty(property, value) end

---@return hs.eventtap.event
function EventtapEvent:post() end

---@class hs.logger
local Logger = {}

---@param message string
function Logger.i(message) end

---@param format string
---@param ... any
function Logger.f(format, ...) end

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

---@class hs.task
local Task = {}

---@return hs.task|boolean
function Task:start() end

---@return hs.task
function Task:terminate() end

---@class hs.timer
local Timer = {}

---@return hs.timer
function Timer:stop() end

---@class hs.eventtap.event.module
---@field types hs.eventtap.event.types
---@field properties hs.eventtap.event.properties

---@class hs.eventtap.module
---@field event hs.eventtap.event.module

---@class hs.eventtap.event.types
---@field keyDown integer
---@field keyUp integer
---@field flagsChanged integer

---@class hs.eventtap.event.properties
---@field eventSourceUserData integer

---@class hs
---@field keycodes hs.keycodes
---@field eventtap hs.eventtap.module
---@field task table
---@field timer table
---@field fs table
---@field logger table
hs = {}
hs.keycodes = {}
hs.eventtap = {}
hs.eventtap.event = {}
hs.eventtap.event.types = {}
hs.eventtap.event.properties = {}
hs.task = {}
hs.timer = {}
hs.fs = {}
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

---@overload fun(key: string|integer, isDown: boolean): hs.eventtap.event
---@param modifiers table
---@param key string|integer
---@param isDown boolean
---@return hs.eventtap.event
function hs.eventtap.event.newKeyEvent(modifiers, key, isDown) end

---@param launchPath string
---@param callback fun(exitCode: integer, stdOut: string, stdErr: string)|nil
---@param arguments string[]
---@return hs.task
function hs.task.new(launchPath, callback, arguments) end

---@param seconds number
---@param callback function
---@return hs.timer
function hs.timer.doAfter(seconds, callback) end

---@param path string
---@param attribute? string
---@return any
function hs.fs.attributes(path, attribute) end
