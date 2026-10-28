-- Run with Lua 5.3+ from the repository root. No running Hammerspoon required.
local tests = {}

local function test(name, fn)
    tests[#tests + 1] = { name, fn }
end

local function equal(actual, expected)
    assert(actual == expected, string.format("expected %s, got %s", tostring(expected), tostring(actual)))
end

local function fixture(options)
    options = options or {}
    local state = { tasks = {}, nativeCalls = {}, sleeps = {}, logs = {}, detections = 0, taps = {} }
    local keycodes = { cmd = 55, rightcmd = 54, shift = 56, rightshift = 60 }
    local types = { keyDown = 1, keyUp = 2, flagsChanged = 3 }
    local logger = {}
    for _, level in ipairs({ "i", "df", "wf", "ef" }) do
        logger[level] = function(format, ...)
            state.logs[#state.logs + 1] = { level, string.format(format, ...) }
        end
    end

    local function event(code, kind, flags)
        return {
            getKeyCode = function() return code end,
            getType = function() return kind end,
            getFlags = function() return flags or {} end,
        }
    end

    local mock = {
        logger = { new = function() return logger end },
        fs = { attributes = function(path) return (options.files or {})[path] end },
        execute = function(command, userEnvironment)
            equal(command, "command -v macism")
            equal(userEnvironment, true)
            state.detections = state.detections + 1
            if options.shellError then error("login shell unavailable") end
            return options.output or "", options.found
        end,
        keycodes = {
            map = keycodes,
            currentSourceID = function(sourceID)
                state.nativeCalls[#state.nativeCalls + 1] = sourceID
                if options.nativeResults then return options.nativeResults[#state.nativeCalls] end
                return true
            end,
        },
        timer = { usleep = function(delay) state.sleeps[#state.sleeps + 1] = delay end },
        eventtap = {
            event = {
                types = types,
                newKeyEvent = function(code, down)
                    return event(code, down and types.keyDown or types.keyUp)
                end,
            },
            new = function(_, callback)
                local tap = { callback = callback }
                function tap:start() self.active = true end
                function tap:stop() self.active = false end
                state.taps[#state.taps + 1] = tap
                return tap
            end,
        },
        task = { new = function(path, callback, arguments)
            if options.failCreate then return nil end
            local task = { path = path, arguments = arguments }
            function task:start()
                if options.failStart then return false end
                self.active = true
                return self
            end
            function task:terminate()
                self.terminated = true
                self.active = false
                return self
            end
            function task:complete(exitCode, stderr)
                self.active = false
                callback(exitCode or 0, "", stderr or "")
            end
            state.tasks[#state.tasks + 1] = task
            return task
        end },
    }
    local env = setmetatable({ hs = mock }, { __index = _G })
    local spoon = assert(loadfile("init.lua", "t", env))()
    spoon.override = true
    spoon.userMapping = {
        rightshift = "com.apple.inputmethod.SCIM.WBX",
        cmd = "com.apple.keylayout.ABC",
        kana = "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese",
    }
    function state.send(code, kind, flags)
        return state.taps[#state.taps].callback(event(code, kind, flags))
    end
    function state.tap(key)
        local modifier = key == "cmd" and "cmd" or "shift"
        state.send(keycodes[key], types.flagsChanged, { [modifier] = true })
        state.send(keycodes[key], types.flagsChanged, {})
    end
    function state.hasLog(level, text)
        for _, entry in ipairs(state.logs) do
            if entry[1] == level and entry[2]:find(text, 1, true) then return true end
        end
        return false
    end
    state.types = types
    return spoon, state, options
end

local function executable()
    return { mode = "file", permissions = "rwxr-xr-x" }
end

local function withMacism()
    return fixture({ files = { ["/opt/homebrew/bin/macism"] = executable() } })
end

test("missing macism keeps native switching and detects only at startup", function()
    local spoon, state = fixture()
    spoon:start()
    state.tap("rightshift")
    state.tap("cmd")
    equal(#state.tasks, 0)
    equal(state.nativeCalls[1], "com.apple.inputmethod.SCIM.WBX")
    equal(state.nativeCalls[2], "com.apple.keylayout.ABC")
    equal(state.detections, 1)
    assert(state.hasLog("i", "macism not found"))
end)

test("native backend preserves retries and stops after success", function()
    local spoon, state = fixture({ nativeResults = { false, true } })
    spoon:start()
    state.tap("rightshift")
    equal(#state.nativeCalls, 2)
    equal(#state.sleeps, 1)
    equal(state.sleeps[1], 100000)
end)

test("shell lookup errors do not prevent native startup", function()
    local spoon, state = fixture({ shellError = true })
    spoon:start()
    state.tap("rightshift")
    equal(#state.nativeCalls, 1)
    assert(state.hasLog("wf", "login shell unavailable"))
end)

test("native backend stops after three failed attempts", function()
    local spoon, state = fixture({ nativeResults = { false, false, false } })
    spoon:start()
    state.tap("rightshift")
    equal(#state.nativeCalls, 3)
    equal(#state.sleeps, 2)
    assert(state.hasLog("ef", "after 3 retries"))
end)

test("Apple Silicon Homebrew macism switches asynchronously without native calls", function()
    local spoon, state = withMacism()
    spoon:start()
    state.tap("rightshift")
    equal(state.tasks[1].path, "/opt/homebrew/bin/macism")
    equal(state.tasks[1].arguments[1], "com.apple.inputmethod.SCIM.WBX")
    equal(#state.tasks[1].arguments, 1)
    equal(state.tasks[1].active, true)
    equal(#state.nativeCalls, 0)
    equal(#state.sleeps, 0)
    equal(state.detections, 0)
    assert(state.hasLog("i", "Using macism"))
    state.tasks[1]:complete()
    assert(state.hasLog("df", "macism completed"))
end)

test("Intel Homebrew macism is detected", function()
    local spoon, state = fixture({ files = { ["/usr/local/bin/macism"] = executable() } })
    spoon:start()
    state.tap("cmd")
    equal(state.tasks[1].path, "/usr/local/bin/macism")
    equal(state.tasks[1].arguments[1], "com.apple.keylayout.ABC")
end)

test("custom login PATH handles shell banners and spaces", function()
    local path = "/Users/test/Tools with spaces/macism"
    local spoon, state = fixture({
        files = { [path] = executable() },
        found = true,
        output = "Welcome to the shell!\n" .. path .. "\n",
    })
    spoon:start()
    state.tap("rightshift")
    equal(state.tasks[1].path, path)
    equal(state.detections, 1)
end)

test("non-executable files, directories and shell aliases are not installations", function()
    local spoon, state = fixture({
        files = {
            ["/opt/homebrew/bin/macism"] = { mode = "file", permissions = "rw-r--r--" },
            ["/usr/local/bin/macism"] = { mode = "directory", permissions = "rwxr-xr-x" },
        },
        found = true,
        output = "macism is an alias for something\n",
    })
    spoon:start()
    state.tap("rightshift")
    equal(#state.tasks, 0)
    equal(#state.nativeCalls, 1)
end)

test("source ID is passed literally as one process argument", function()
    local spoon, state = withMacism()
    local sourceID = "id with spaces;$(touch ignored)'\""
    spoon.userMapping.rightshift = sourceID
    spoon:start()
    state.tap("rightshift")
    equal(state.tasks[1].arguments[1], sourceID)
    equal(#state.tasks[1].arguments, 1)
end)

test("rapid switches serialize and keep the most recent pending source", function()
    local spoon, state = withMacism()
    spoon:start()
    state.tap("rightshift")
    state.tap("rightshift")
    state.tap("cmd")
    equal(#state.tasks, 1)
    state.tasks[1]:complete()
    equal(#state.tasks, 2)
    equal(state.tasks[2].arguments[1], "com.apple.keylayout.ABC")
    state.tasks[2]:complete()
    equal(#state.tasks, 2)
    -- Selecting the same source again must still reach macism for recovery.
    state.tap("cmd")
    equal(#state.tasks, 3)
end)

test("macism failure is logged and the pending switch still runs", function()
    local spoon, state = withMacism()
    spoon:start()
    state.tap("rightshift")
    state.tap("cmd")
    state.tasks[1]:complete(2, "source unavailable")
    assert(state.hasLog("ef", "exit 2"))
    assert(state.hasLog("ef", "source unavailable"))
    equal(#state.tasks, 2)
    equal(#state.nativeCalls, 0)
end)

for _, failure in ipairs({ "failCreate", "failStart" }) do
    test(failure .. " is logged without native fallback and allows another request", function()
        local spoon, state, options = withMacism()
        options[failure] = true
        spoon:start()
        state.tap("rightshift")
        assert(state.hasLog("ef", "Could not start macism"))
        equal(#state.nativeCalls, 0)
        options[failure] = false
        state.tap("cmd")
        equal(state.tasks[#state.tasks].active, true)
        equal(state.tasks[#state.tasks].arguments[1], "com.apple.keylayout.ABC")
    end)
end

test("stop terminates macism, discards pending work and ignores late callbacks", function()
    local spoon, state = withMacism()
    spoon:start()
    state.tap("rightshift")
    state.tap("cmd")
    spoon:stop()
    equal(state.tasks[1].terminated, true)
    equal(state.taps[1].active, false)
    state.tasks[1]:complete()
    equal(#state.tasks, 1)
    spoon:stop() -- idempotent
end)

test("restart detects installations and removals", function()
    local spoon, state, options = fixture()
    spoon:start()
    state.tap("rightshift")
    equal(#state.nativeCalls, 1)
    options.files = { ["/opt/homebrew/bin/macism"] = executable() }
    spoon:start()
    state.tap("rightshift")
    equal(#state.tasks, 1)
    options.files = {}
    spoon:start()
    equal(state.tasks[1].terminated, true)
    state.tasks[1]:complete()
    state.tap("rightshift")
    equal(#state.nativeCalls, 2)
    equal(#state.tasks, 1)
    equal(state.taps[1].active, false)
    equal(state.taps[2].active, false)
    equal(state.taps[3].active, true)
end)

test("callback from an earlier start cannot interfere with the new task", function()
    local spoon, state = withMacism()
    spoon:start()
    state.tap("rightshift")
    spoon:start()
    state.tap("cmd")
    state.tasks[1]:complete()
    state.tap("rightshift")
    equal(#state.tasks, 2)
    state.tasks[2]:complete()
    equal(#state.tasks, 3)
    equal(state.tasks[3].arguments[1], "com.apple.inputmethod.SCIM.WBX")
end)

test("right Shift combinations do not switch input sources", function()
    local spoon, state = withMacism()
    spoon:start()
    state.send(60, state.types.flagsChanged, { shift = true })
    state.send(0, state.types.keyDown, { shift = true })
    state.send(60, state.types.flagsChanged, {})
    equal(#state.tasks, 0)
    state.tap("rightshift")
    equal(#state.tasks, 1)
end)

test("configured Kana consumes down and up but switches only once", function()
    local spoon, state = withMacism()
    spoon:start()
    equal(state.send(104, state.types.keyDown), true)
    equal(state.send(104, state.types.keyUp), true)
    equal(#state.tasks, 1)
    equal(state.tasks[1].arguments[1], "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese")
end)

test("default mappings are retained when override is false", function()
    local spoon, state = withMacism()
    spoon.override = false
    spoon.userMapping = {}
    spoon:start()
    state.send(54, state.types.flagsChanged, { cmd = true })
    state.send(54, state.types.flagsChanged, {})
    equal(state.tasks[1].arguments[1], "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese")
end)

local failed = 0
for _, entry in ipairs(tests) do
    local ok, err = pcall(entry[2])
    if ok then
        print("PASS " .. entry[1])
    else
        failed = failed + 1
        io.stderr:write("FAIL " .. entry[1] .. ": " .. tostring(err) .. "\n")
    end
end
print(string.format("%d tests, %d failures", #tests, failed))
if failed > 0 then os.exit(1) end
