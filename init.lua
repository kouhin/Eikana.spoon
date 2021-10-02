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

table.size = function(t)
   local count = 0
   for _, __ in pairs(t) do
      count = count + 1
   end
   return count
end

function addSingleModKeyPressEventListener(keys, handler)
   local targetKeyCodes = {}
   for _,v in pairs(keys) do targetKeyCodes[v]=true end

   local prevCode = 0
   local prevFlagSize = 0

   local function reset()
      if prevCode ~= 0 then prevCode = 0 end
   end

   local function eventhandler(event)
      local code = event:getKeyCode()
      local flag = event:getFlags()

      if event:getType() == hs.eventtap.event.types.keyDown then
         return reset()
      end

      if event:getType() == hs.eventtap.event.types.flagsChanged then
         local flagSize = table.size(flag)
         if flagSize == 0  then
            if prevFlagSize == 1 and code == prevCode then
               -- FlagSize 1 -> 0
               if not targetKeyCodes[hs.keycodes.map[code]] then
                  reset()
               else
                  handler(hs.eventtap.event.newKeyEvent(code, false))
               end
            else
               reset()
            end
         elseif flagSize == 1 then
            if prevFlagSize == 0 then
               -- FlagSize 0 -> 1
               prevCode = code
            else
               reset()
            end
         else
            reset()
         end
         prevFlagSize = flagSize
      end
   end
   return hs.eventtap.new({hs.eventtap.event.types.keyDown, hs.eventtap.event.types.flagsChanged}, eventhandler)
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
