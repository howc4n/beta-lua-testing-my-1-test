-- VOID Mobile/PC Adaptive Logger ⚔️
if _G.__VOID_LOGGER then return end
_G.__VOID_LOGGER = true

local HS = game:GetService("HttpService")
local buffer = {}

local function push(line)
    table.insert(buffer, line)
end

local function flush()
    if #buffer == 0 then return end
    local text = table.concat(buffer, "\n")

    if setclipboard then
        setclipboard(text)
        print("[VOID] Logs copied to clipboard ✅")
    elseif writefile then
        writefile("VOID_logs.txt", text)
        print("[VOID] Logs written to workspace/VOID_logs.txt 📁")
    elseif rconsoleprint then
        rconsoleprint(text.."\n")
        print("[VOID] Logs dumped to rconsole 📜")
    else
        warn("[VOID] No clipboard/file/rconsole support. Showing logs inline ↓↓↓")
        warn(text)
    end

    buffer = {}
end

-- override console
local oldPrint, oldWarn, oldError = print, warn, error
print = function(...)
    local msg = table.concat({...}, " ")
    oldPrint(msg)
    push("[PRINT] "..msg)
    flush()
end
warn = function(...)
    local msg = table.concat({...}, " ")
    oldWarn(msg)
    push("[WARN] "..msg)
    flush()
end
error = function(msg, lvl)
    local str = tostring(msg)
    oldError(str, lvl)
    push("[ERROR] "..str)
    flush()
end

-- hook remotes
local mt = getrawmetatable(game)
local old = mt.__namecall
setreadonly(mt, false)
mt.__namecall = function(self, ...)
    local m = getnamecallmethod()
    if m == "FireServer" or m == "InvokeServer" then
        local ok, path = pcall(function() return self:GetFullName() end)
        push("["..m.."] "..(ok and path or tostring(self)).." "..HS:JSONEncode({...}))
        flush()
    end
    return old(self, ...)
end
setreadonly(mt, true)

print("✅ VOID Logger active. Logs will auto-dump (Clipboard if PC / File if HP).")
