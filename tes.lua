--[[ 
  VOID Remote Logger (namecall hook, auto-clipboard)
  Run this FIRST in your executor, then run the obfuscated/target script.
]]

if _G.__VOID_LOGGER_ACTIVE then
    warn("[VOID] Logger already active")
    return
end
_G.__VOID_LOGGER_ACTIVE = true

local HS  = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")

-- ==== buffer & clipboard ====
local buffer = {}
local function copy(text)
    if setclipboard then
        setclipboard(text)
    else
        -- executor-mu tidak support setclipboard → no-op
    end
end

local function flush()
    if #buffer == 0 then return end
    local out = table.concat(buffer, "\n")
    copy(out)
    buffer = {}
end

-- stringify aman untuk argumen remote
local function s(v)
    local t = typeof(v)
    if t == "Instance" then
        local ok, path = pcall(function() return v:GetFullName() end)
        return "<"..v.ClassName..">:"..(ok and path or v.Name)
    elseif t == "table" then
        local ok, j = pcall(function() return HS:JSONEncode(v) end)
        return ok and j or "<table>"
    else
        return tostring(v)
    end
end
local function packArgs(...)
    local n = select("#", ...)
    local arr = table.create(n)
    for i=1,n do arr[i] = s(select(i, ...)) end
    return arr
end

-- ==== print/warn/error override → auto flush seperti obsidian2 ====
local _print, _warn, _error = print, warn, error
print = function(...)
    local msg = table.concat({...}, " ")
    _print(msg)
    table.insert(buffer, "[PRINT] "..msg)
    flush()
end
warn = function(...)
    local msg = table.concat({...}, " ")
    _warn(msg)
    table.insert(buffer, "[WARN]  "..msg)
    flush()
end
error = function(msg, lvl)
    local str = tostring(msg)
    table.insert(buffer, "[ERROR] "..str)
    flush()
    return _error(str, lvl)
end

-- ==== hook __namecall untuk RemoteEvent/RemoteFunction ====
local hooked = false

local function hook_by_metamethod()
    if hookmetamethod and getnamecallmethod then
        local old
        old = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" or method == "InvokeServer" then
                local ok, path = pcall(function() return self:GetFullName() end)
                local line = "["..method.."] "..(ok and path or tostring(self)).." "..HS:JSONEncode(packArgs(...))
                table.insert(buffer, line)
                flush()
            end
            return old(self, ...)
        end)
        return true
    end
    return false
end

local function hook_by_rawmt()
    local getrm = getrawmetatable or debug and debug.getmetatable
    local mt = getrm and getrm(game)
    if not mt or not mt.__namecall then return false end
    local setro = setreadonly or set_readonly or make_writeable
    if setro then pcall(setro, mt, false) end
    local old = mt.__namecall
    mt.__namecall = function(self, ...)
        local method = getnamecallmethod and getnamecallmethod() or ""
        if method == "FireServer" or method == "InvokeServer" then
            local ok, path = pcall(function() return self:GetFullName() end)
            local line = "["..method.."] "..(ok and path or tostring(self)).." "..HS:JSONEncode(packArgs(...))
            table.insert(buffer, line)
            flush()
        end
        return old(self, ...)
    end
    if setro then pcall(setro, mt, true) end
    return true
end

hooked = hook_by_metamethod() or hook_by_rawmt()

-- ==== hotkey manual: Ctrl+Shift+C → paksa copy sekarang ====
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.C and UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
        flush()
    end
end)

-- auto-flush tiap 3 detik (kalau ada isi)
task.spawn(function()
    while task.wait(3) do
        flush()
    end
end)

print("✅ Script sudah ter-run. Logger "..(hooked and "HOOKED" or "NOT HOOKED")..".")
warn("⚔️ Semua FireServer/InvokeServer akan dicopy ke clipboard otomatis.")
--[[ 
  VOID Remote Logger (namecall hook, auto-clipboard)
  Run this FIRST in your executor, then run the obfuscated/target script.
]]

if _G.__VOID_LOGGER_ACTIVE then
    warn("[VOID] Logger already active")
    return
end
_G.__VOID_LOGGER_ACTIVE = true

local HS  = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")

-- ==== buffer & clipboard ====
local buffer = {}
local function copy(text)
    if setclipboard then
        setclipboard(text)
    else
        -- executor-mu tidak support setclipboard → no-op
    end
end

local function flush()
    if #buffer == 0 then return end
    local out = table.concat(buffer, "\n")
    copy(out)
    buffer = {}
end

-- stringify aman untuk argumen remote
local function s(v)
    local t = typeof(v)
    if t == "Instance" then
        local ok, path = pcall(function() return v:GetFullName() end)
        return "<"..v.ClassName..">:"..(ok and path or v.Name)
    elseif t == "table" then
        local ok, j = pcall(function() return HS:JSONEncode(v) end)
        return ok and j or "<table>"
    else
        return tostring(v)
    end
end
local function packArgs(...)
    local n = select("#", ...)
    local arr = table.create(n)
    for i=1,n do arr[i] = s(select(i, ...)) end
    return arr
end

-- ==== print/warn/error override → auto flush seperti obsidian2 ====
local _print, _warn, _error = print, warn, error
print = function(...)
    local msg = table.concat({...}, " ")
    _print(msg)
    table.insert(buffer, "[PRINT] "..msg)
    flush()
end
warn = function(...)
    local msg = table.concat({...}, " ")
    _warn(msg)
    table.insert(buffer, "[WARN]  "..msg)
    flush()
end
error = function(msg, lvl)
    local str = tostring(msg)
    table.insert(buffer, "[ERROR] "..str)
    flush()
    return _error(str, lvl)
end

-- ==== hook __namecall untuk RemoteEvent/RemoteFunction ====
local hooked = false

local function hook_by_metamethod()
    if hookmetamethod and getnamecallmethod then
        local old
        old = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" or method == "InvokeServer" then
                local ok, path = pcall(function() return self:GetFullName() end)
                local line = "["..method.."] "..(ok and path or tostring(self)).." "..HS:JSONEncode(packArgs(...))
                table.insert(buffer, line)
                flush()
            end
            return old(self, ...)
        end)
        return true
    end
    return false
end

local function hook_by_rawmt()
    local getrm = getrawmetatable or debug and debug.getmetatable
    local mt = getrm and getrm(game)
    if not mt or not mt.__namecall then return false end
    local setro = setreadonly or set_readonly or make_writeable
    if setro then pcall(setro, mt, false) end
    local old = mt.__namecall
    mt.__namecall = function(self, ...)
        local method = getnamecallmethod and getnamecallmethod() or ""
        if method == "FireServer" or method == "InvokeServer" then
            local ok, path = pcall(function() return self:GetFullName() end)
            local line = "["..method.."] "..(ok and path or tostring(self)).." "..HS:JSONEncode(packArgs(...))
            table.insert(buffer, line)
            flush()
        end
        return old(self, ...)
    end
    if setro then pcall(setro, mt, true) end
    return true
end

hooked = hook_by_metamethod() or hook_by_rawmt()

-- ==== hotkey manual: Ctrl+Shift+C → paksa copy sekarang ====
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.C and UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
        flush()
    end
end)

-- auto-flush tiap 3 detik (kalau ada isi)
task.spawn(function()
    while task.wait(3) do
        flush()
    end
end)

print("✅ Script sudah ter-run. Logger "..(hooked and "HOOKED" or "NOT HOOKED")..".")
warn("⚔️ Semua FireServer/InvokeServer akan dicopy ke clipboard otomatis.")
