--[[
  VOID Hybrid Remote+Console Logger v1.0
  Run this FIRST in your executor, then run target scripts.
]]

if _G.__VOID_HYBRID_LOGGER then
    warn("[VOID] Logger already active")
    return
end
_G.__VOID_HYBRID_LOGGER = true

local HS = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local buffer = {}
local maxBufferLines = 2000

-- Safe short-dump for args (no deep recursion)
local function safeValue(v)
    local t = typeof(v)
    if t == "Instance" then
        local ok, s = pcall(function() return v:GetFullName() end)
        return ok and ("<Instance>:"..s) or ("<Instance>:"..tostring(v.Name))
    elseif t == "table" then
        local out = {}
        local i = 0
        for k, val in pairs(v) do
            i = i + 1
            if i > 10 then break end
            local ks = tostring(k)
            local vs = typeof(val) == "table" and ("<table:"..tostring(#val)..">") or tostring(val)
            table.insert(out, ks.."="..vs)
        end
        return "<table>{"..table.concat(out, ", ")..(i>10 and ",..." or "").."}"
    elseif t == "Vector3" or t == "CFrame" or t == "Color3" then
        return tostring(v)
    else
        return tostring(v)
    end
end

local function packArgs(...)
    local n = select("#", ...)
    local arr = {}
    for i=1,n do
        arr[i] = safeValue(select(i, ...))
    end
    return arr
end

-- Logging utilities
local function pushLine(line)
    if #buffer >= maxBufferLines then
        table.remove(buffer, 1)
    end
    table.insert(buffer, line)
end

-- Multi-backend flush: try setclipboard -> writefile -> rconsoleprint -> notification
local function doOutput(full)
    -- prefer clipboard on PC/executor offering it
    if type(setclipboard) == "function" then
        pcall(function() setclipboard(full) end)
        return true, "clipboard"
    end
    -- try writefile (mobile or executors that support file)
    if type(writefile) == "function" then
        pcall(function() writefile("VOID_remote_logs.txt", full) end)
        return true, "file"
    end
    -- try rconsoleprint (some executors)
    if type(rconsoleprint) == "function" then
        pcall(function() rconsoleprint(full .. "\n") end)
        return true, "rconsole"
    end
    -- last resort: small notification (only shows short)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "VOID Logger",
            Text = ("Logged %d lines (no clipboard/writefile)"):format(#buffer),
            Duration = 4
        })
    end)
    return false, "none"
end

local function flush()
    if #buffer == 0 then return end
    local out = table.concat(buffer, "\n")
    local ok, mode = pcall(doOutput, out)
    if ok then
        -- keep UX: print preview locally
        pcall(function() 
            if mode == "clipboard" then
                -- visible confirmation in console
                print("[VOID] Flushed "..tostring(#buffer).." lines -> clipboard")
            elseif mode == "file" then
                print("[VOID] Flushed "..tostring(#buffer).." lines -> VOID_remote_logs.txt")
            elseif mode == "rconsole" then
                print("[VOID] Flushed "..tostring(#buffer).." lines -> rconsole")
            else
                print("[VOID] Flushed "..tostring(#buffer).." lines -> notification")
            end
        end)
    else
        pcall(function() print("[VOID] Flush failed: "..tostring(mode)) end)
    end
    buffer = {}
end

-- Override console builtins (collect logs)
local oldPrint, oldWarn, oldError = print, warn, error
print = function(...)
    local msg = table.concat({...}, " ")
    oldPrint(msg)
    pushLine("[PRINT] " .. msg)
    -- small delay to avoid sync issues on some executors; still trigger flush for obsidian-like behavior
    pcall(flush)
end
warn = function(...)
    local msg = table.concat({...}, " ")
    oldWarn(msg)
    pushLine("[WARN] " .. msg)
    pcall(flush)
end
error = function(msg, lvl)
    local str = tostring(msg)
    oldError(str, lvl)
    pushLine("[ERROR] " .. str)
    pcall(flush)
end

-- Hotkey manual flush: Ctrl+Shift+C
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.C and UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
        flush()
    end
end)

-- Periodic flush fallback (every 3s if something exists)
task.spawn(function()
    while task.wait(3) do
        if #buffer > 0 then
            pcall(flush)
        end
    end
end)

-- Safe namecall hook: prefer hookmetamethod, else raw metatable with setreadonly change
local hooked = false
local function try_hook()
    -- prefer hookmetamethod (safer on many exploit runtimes)
    if type(hookmetamethod) == "function" and type(getnamecallmethod) == "function" then
        local old = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" or method == "InvokeServer" then
                local ok, path = pcall(function() return self:GetFullName() end)
                local args = packArgs(...)
                local line = ("[%s] %s %s"):format(method, ok and path or tostring(self), HS:JSONEncode(args))
                pushLine(line)
                pcall(flush)
            end
            return old(self, ...)
        end)
        return true
    end

    -- fallback: mutate raw metatable if available
    local getrm = (type(getrawmetatable) == "function") and getrawmetatable or (debug and debug.getmetatable)
    if not getrm then return false end
    local mt = getrm(game)
    if not mt or not mt.__namecall then return false end

    local old = mt.__namecall
    -- try to make writable
    local setro = (type(setreadonly) == "function" and setreadonly) or (type(make_writeable) == "function" and make_writeable)
    if setro then pcall(setro, mt, false) end

    mt.__namecall = function(self, ...)
        local method = getnamecallmethod and getnamecallmethod() or ""
        if method == "FireServer" or method == "InvokeServer" then
            local ok, path = pcall(function() return self:GetFullName() end)
            local args = packArgs(...)
            local line = ("[%s] %s %s"):format(method, ok and path or tostring(self), HS:JSONEncode(args))
            pushLine(line)
            pcall(flush)
        end
        return old(self, ...)
    end

    if setro then pcall(setro, mt, true) end
    return true
end

local okHook, hookErr = pcall(try_hook)
hooked = okHook and hookErr ~= false

-- final status prints
oldPrint(("✅ VOID Hybrid Logger loaded. Hooked=%s (Ctrl+Shift+C to force flush)"):format(tostring(hooked)))
oldPrint("If clipboard not available, logs will be written to file or rconsole if supported.")
