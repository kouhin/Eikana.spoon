--- === Eikana ===
---
--- A cmd-eikana like Hammerspoon spoon plugin.

local obj = {}
obj.index = obj

-- Metadata
obj.name = "Eikana"
obj.version = "1.0.0"
obj.author = "Bin Hou"
obj.license = "MIT"
obj.homepage = "https://github.com/kouhin/Eikana.spoon"

obj._defaultMapping = {
   cmd = 'Romaji',
   rightcmd = 'Hiragana'
}
obj.userMapping = {}
obj.mapping = {}

for k, v in pairs(obj._defaultMapping) do obj.mapping[k] = v end
for k, v in pairs(obj.userMapping) do obj.mapping[k] = v end

function obj:handleEvent(ev)
   local key = hs.keycodes.map[ev:getKeyCode()]
   local method = self.mapping[key]

   if method == nil then return end

   if method == 'Romaji' then
      hs.eventtap.keyStroke({}, 102)
   elseif method == 'Hiragana' then
      hs.eventtap.keyStroke({}, 104)
   else
      hs.keycodes.setMethod(method)
   end
end

function obj:start()
   if self.eventtap == nil then
      self.eventtap = self:bindKeyMethodMapping()
   end
   self.eventtap:start()
end

function obj:stop()
   if self.eventtap == nil then return end
   self.eventtap:stop()
   self.eventtap = nil
end

function obj:bindKeyMethodMapping()
   for k, v in pairs(self.userMapping) do obj.mapping[k] = v end

   local keys = {}
   for k in pairs(self.mapping) do table.insert(keys, k) end

   local function handleEvent(ev)
      local key = hs.keycodes.map[ev:getKeyCode()]
      local method = self.mapping[key]

      if method == nil then return end

      if method == 'Romaji' then
         hs.eventtap.keyStroke({}, 102)
      elseif method == 'Hiragana' then
         hs.eventtap.keyStroke({}, 104)
      else
         hs.keycodes.setMethod(method)
      end
   end

   return addSingleModKeyPressEventListener(keys, handleEvent)
end

return obj
