# Development and verification

## Switching implementation

Every `spoon.Eikana:start()` stops the previous listener and macism task, clears pending requests, and detects the switching backend again. Detection checks for an executable file in this order:

1. `/opt/homebrew/bin/macism` (Apple Silicon Homebrew)
2. `/usr/local/bin/macism` (Intel Homebrew)
3. The interactive login shell's `PATH`, using `hs.execute("command -v macism", true)`

The detected path is cached until the next `start()`. Shell startup output is filtered for executable absolute paths. A shell lookup error is logged and leaves the native backend available. Startup logs record the selected backend and any detected macism path.

When macism is available, `hs.task` runs it asynchronously with the source ID as a literal argument; the switch command does not go through a shell. Only one task runs at a time, and only the latest request received during that task is kept for the next switch. Launch failures and nonzero exit codes are logged without falling back to the native backend. `stop()` terminates the active task, drops the pending request, and ignores late callbacks.

When macism is unavailable, Eikana preserves the original `hs.keycodes.currentSourceID()` implementation: up to three attempts, with a 100 ms blocking wait between failed attempts. Both backends use the existing `userMapping` and `override` configuration.

## Automated tests

Run from the repository root with Lua 5.3 or newer:

```sh
make test
# Or select a specific Lua executable:
make test LUA=/path/to/lua
```

`tests/run.lua` mocks the Hammerspoon APIs. It does not launch macism, change the active input source, or require a running Hammerspoon instance. It verifies:

- Detection of both Homebrew locations and custom login-shell paths, including paths with spaces and shell startup output.
- Rejection of non-executable files, directories, and shell aliases, with native startup preserved if the shell lookup fails.
- The original native backend and its retry limit when macism is unavailable.
- Asynchronous execution with literal source-ID arguments and no native fallback after macism errors.
- Serialization of rapid requests, keeping only the latest pending source.
- Cancellation and backend detection on stop/restart, including late process callbacks.
- Modifier combinations, standalone modifier presses, and configured JIS keys.

These tests cover dispatch and lifecycle behavior. They cannot establish whether a macOS input method actually receives keystrokes.

## Manual verification on macOS

1. Load the updated Spoon in Hammerspoon and enable the target input sources in System Settings.
2. On a machine without macism, call `spoon.Eikana:start()` and confirm the Console reports `macism not found; using hs.keycodes`. Confirm existing key mappings still switch sources.
3. Install macism using the README instructions, call `spoon.Eikana:start()` again, and confirm the Console reports its absolute path. The existing mappings should now use macism without configuration changes.
4. In TextEdit and any previously affected application, switch to ABC and type English first. Press the configured key for Wubi or another CJK input method, then type a known character code. Check composition/candidate behavior and actual text, not only the menu bar icon. Repeat with immediate typing after the switch.
5. Verify that modifier combinations still work normally. If configured, verify JIS `Eisuu` and `Kana` keys.
6. Press different input-source keys rapidly and confirm the last requested source wins. Stop or restart Eikana while a switch is pending and confirm no queued request starts afterward.
7. Check the Console for process errors. A failed macism command remains a macism error; Eikana does not silently retry using the native backend. After changing the installation, call `start()` again to repeat detection.

## Build

```sh
make build
```

The build packages `init.lua` and `docs/docs.json` into `Spoons/Eikana.spoon.zip`. Keep the bundled documentation and the three README translations consistent when changing switching behavior.
