-- Run with Lua 5.3+ from the repository root: make test
-- Hammerspoon APIs are mocked; nothing is launched and no input source changes.

local ABC = 'com.apple.keylayout.ABC'
local JAPANESE = 'com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese'
local WUBI = 'com.apple.inputmethod.SCIM.WBX'
local MACISM = '/opt/homebrew/bin/macism'
local MARKER = 0x45696B61

local M -- State of the current test

local function event(code, kind, flags)
    local properties = {}
    return {
        flags = flags or {},
        getKeyCode = function() return code end,
        getType = function() return kind end,
        getFlags = function(self) return self.flags end,
        getProperty = function(_, property) return properties[property] or 0 end,
        setProperty = function(self, property, value) properties[property] = value; return self end,
        post = function(self) M.posted[#M.posted + 1] = self; return self end,
    }
end

hs = {
    logger = {
        new = function()
            local logger = {}
            for _, level in ipairs({ 'i', 'f', 'df', 'wf', 'ef' }) do
                logger[level] = function(format, ...)
                    M.logs[#M.logs + 1] = string.format(format, ...)
                end
            end
            return logger
        end,
    },
    keycodes = {
        map = { cmd = 55, rightcmd = 54, shift = 56, rightshift = 60, a = 0 },
        currentSourceID = function(sourceID)
            M.tis[#M.tis + 1] = sourceID
            return M.enabled[sourceID] == true
        end,
    },
    eventtap = {
        new = function(_, handler)
            return {
                start = function() M.tap = handler end,
                stop = function() end,
            }
        end,
        event = {
            types = { keyDown = 10, keyUp = 11, flagsChanged = 12 },
            properties = { eventSourceUserData = 42 },
            newKeyEvent = function(mods, code, isDown)
                if type(mods) ~= 'table' then mods, code, isDown = nil, mods, code end
                return event(code, isDown and 10 or 11, {})
            end,
        },
    },
    timer = {
        doAfter = function(delay, fn)
            local timer = { delay = delay, fn = fn }
            function timer:stop() self.stopped = true end
            M.timers[#M.timers + 1] = timer
            return timer
        end,
    },
    task = {
        new = function(path, callback, arguments)
            local task = { path = path, arguments = arguments }
            function task:start()
                if M.failStart then return false end
                self.running = true
                return self
            end
            function task:finish(exitCode, stdOut)
                self.running = false
                callback(exitCode, stdOut or '', '')
            end
            function task:terminate()
                self.terminated = true
                self:finish(15)
            end
            M.tasks[#M.tasks + 1] = task
            return task
        end,
    },
    fs = {
        attributes = function(path)
            local permissions = M.files[path]
            return permissions and { mode = 'file', permissions = permissions } or nil
        end,
    },
}

local function setup(options)
    options = options or {}
    M = {
        logs = {}, posted = {}, tis = {}, tasks = {}, timers = {},
        enabled = { [ABC] = true, [JAPANESE] = true, [WUBI] = true, ['com.apple.keylayout.US'] = true },
        files = options.files or {},
        failStart = options.failStart,
    }
    local eikana = dofile('init.lua')
    for key, value in pairs(options.config or {}) do eikana[key] = value end
    eikana:start()
    return eikana
end

local function tap(key)
    local code = hs.keycodes.map[key]
    M.tap(event(code, 12, { [key:gsub('^right', '')] = true }))
    M.tap(event(code, 12, {}))
end

local function fireTimers()
    for _, timer in ipairs(M.timers) do
        if not timer.stopped and not timer.fired then
            timer.fired = true
            timer.fn()
        end
    end
end

local function logged(text)
    for _, line in ipairs(M.logs) do
        if line:find(text, 1, true) then return true end
    end
    return false
end

local function equal(actual, expected, message)
    if actual ~= expected then
        error(string.format('%s: expected %s, got %s', message, tostring(expected), tostring(actual)), 2)
    end
end

local withMacism = { files = { [MACISM] = 'rwxr-xr-x' }, config = { userMapping = { rightshift = WUBI } } }

local tests = {
    { 'default mapping posts Kana for Japanese and selects ABC directly', function()
        setup()
        tap('rightcmd')
        equal(#M.posted, 2, 'Kana down and up')
        equal(M.posted[1]:getKeyCode(), 104, 'Kana keycode')
        equal(M.posted[1]:getProperty(42), MARKER, 'marker')
        equal(next(M.posted[1].flags), nil, 'no modifier flags')
        tap('cmd')
        equal(M.tis[1], ABC, 'ABC via TIS')
        equal(#M.tis, 1, 'no TIS for Japanese')
        equal(logged('macism'), false, 'no macism warning for layouts and Japanese')
    end },

    { 'posted keys pass through even when Kana is mapped', function()
        setup({ config = { userMapping = { kana = WUBI } } })
        tap('rightcmd')
        equal(M.tap(M.posted[1]), false, 'posted keyDown passes')
        equal(M.tap(M.posted[2]), false, 'posted keyUp passes')
        equal(#M.tis, 0, 'posted Kana does not trigger the Kana mapping')
        equal(M.tap(event(104, 10)), true, 'physical Kana is consumed')
        equal(M.tis[1], WUBI, 'physical Kana switches')
    end },

    { 'modifier combinations do not switch', function()
        setup()
        M.tap(event(54, 12, { cmd = true }))
        M.tap(event(0, 10, { cmd = true }))
        M.tap(event(54, 12, {}))
        equal(#M.posted + #M.tis, 0, 'no switch')
    end },

    { 'only input methods other than Japanese use macism', function()
        setup({ files = withMacism.files, config = { override = true, userMapping = {
            cmd = 'com.apple.keylayout.US',
            shift = 'com.apple.inputmethod.Kotoeri.KanaTyping.Japanese',
            rightshift = WUBI,
        } } })
        tap('cmd')
        tap('shift')
        equal(#M.tasks, 0, 'layout and Japanese do not use macism')
        tap('rightshift')
        equal(M.tasks[1].path, MACISM, 'macism path')
        equal(M.tasks[1].arguments[1], WUBI, 'source ID as one argument')
        M.tasks[1]:finish(0)
        equal(M.tis[2], nil, 'no TIS after macism succeeds')
        equal(M.timers[1].stopped, true, 'watchdog stopped')
    end },

    { 'requests during macism wait and only the latest runs', function()
        setup(withMacism)
        tap('rightshift')
        tap('rightcmd')
        tap('cmd')
        equal(#M.posted + #M.tis, 0, 'nothing runs while macism runs')
        M.tasks[1]:finish(0)
        equal(#M.posted, 0, 'superseded Japanese request dropped')
        equal(M.tis[1], ABC, 'latest request runs')
    end },

    { 'macism errors fall back to TIS', function()
        setup(withMacism)
        tap('rightshift')
        M.tasks[1]:finish(0, 'Input source ' .. WUBI .. ' does not exist!\n')
        equal(logged('macism failed (exit code 0): Input source'), true, 'stdout error logged')
        equal(M.tis[1], WUBI, 'fallback after stdout error')
        tap('rightshift')
        M.tasks[2]:finish(1)
        equal(M.tis[2], WUBI, 'fallback after nonzero exit')
    end },

    { 'a hung macism is terminated and the queue continues', function()
        setup(withMacism)
        tap('rightshift')
        tap('cmd')
        fireTimers()
        equal(M.tasks[1].terminated, true, 'terminated')
        equal(M.tis[1], WUBI, 'fallback')
        equal(M.tis[2], ABC, 'pending request runs')
    end },

    { 'macism launch failure falls back to TIS', function()
        setup({ files = withMacism.files, config = withMacism.config, failStart = true })
        tap('rightshift')
        equal(M.tis[1], WUBI, 'fallback')
        tap('cmd')
        equal(M.tis[2], ABC, 'later requests are not blocked')
    end },

    { 'stop cancels macism, drops the pending request and ignores late callbacks', function()
        local eikana = setup(withMacism)
        tap('rightshift')
        tap('cmd')
        eikana:stop()
        equal(M.tasks[1].terminated, true, 'terminated')
        equal(M.timers[1].stopped, true, 'watchdog stopped')
        M.tasks[1]:finish(0, 'late output')
        equal(#M.tis, 0, 'no fallback or pending request after stop')
        eikana:start()
        tap('rightshift')
        equal(#M.tasks, 2, 'switching works after restart')
    end },

    { 'macism detection', function()
        setup({ files = { [MACISM] = 'rw-r--r--' }, config = withMacism.config })
        equal(logged('macism not found, switching to ' .. WUBI), true, 'non-executable file ignored')
        tap('rightshift')
        equal(M.tis[1], WUBI, 'TIS without macism')

        setup({ files = { [MACISM] = 'rwxr-xr-x', ['/opt/bin/macism'] = 'rwxr-xr-x' },
            config = { macismPath = '/opt/bin/macism', userMapping = { rightshift = WUBI } } })
        tap('rightshift')
        equal(M.tasks[1].path, '/opt/bin/macism', 'configured path')

        setup({ files = withMacism.files, config = { macismPath = '/missing/macism' } })
        equal(logged('macism not found: /missing/macism'), true, 'missing configured path reported')

        setup({ files = withMacism.files, config = { macismPath = false, userMapping = { rightshift = WUBI } } })
        tap('rightshift')
        equal(#M.tasks, 0, 'false disables macism')
        equal(logged('macism'), false, 'no warning when disabled')
    end },
}

local failed = 0
for _, test in ipairs(tests) do
    local ok, err = pcall(test[2])
    print((ok and 'PASS ' or 'FAIL ') .. test[1] .. (ok and '' or '\n     ' .. tostring(err)))
    if not ok then failed = failed + 1 end
end
print(string.format('%d tests, %d failures', #tests, failed))
if failed > 0 then os.exit(1) end
