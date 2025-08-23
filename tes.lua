--══════════════════════════════════════════════════════
-- Remote Sniffer + Manual Copy Buffer ⚔️ VOID Version
--══════════════════════════════════════════════════════
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local buffer = {} -- simpan semua log

--══════════════════════════════════════════════════════
-- Helper: safe dump argumen biar JSON aman
--══════════════════════════════════════════════════════
local function safeDump(args)
    local dumped = {}
    for i, v in ipairs(args) do
        local t = typeof(v)
        if t == "Instance" then
            dumped[i] = "[Instance] " .. v:GetFullName()
        elseif t == "Vector3" or t == "CFrame" or t == "Color3" then
            dumped[i] = tostring(v)
        elseif t == "table" then
            dumped[i] = "[Table] size=" .. tostring(#v)
        else
            dumped[i] = v
        end
    end
    return dumped
end

--══════════════════════════════════════════════════════
-- Clipboard helper
--══════════════════════════════════════════════════════
local function copyToClip(text)
    if typeof(setclipboard) == "function" then
        setclipboard(text)
        print("📋 Copied to clipboard!")
    else
        warn("⚠️ setclipboard not supported by this executor.")
    end
end

--══════════════════════════════════════════════════════
-- Hook RemoteEvent & RemoteFunction
--══════════════════════════════════════════════════════
for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
    if obj:IsA("RemoteEvent") then
        local old = obj.FireServer
        obj.FireServer = function(self, ...)
            local args = {...}
            local dumped = safeDump(args)
            local line = "[RemoteEvent] " .. self:GetFullName() .. " " .. HttpService:JSONEncode(dumped)
            print(line)
            table.insert(buffer, line)
            return old(self, ...)
        end
    elseif obj:IsA("RemoteFunction") then
        local old = obj.InvokeServer
        obj.InvokeServer = function(self, ...)
            local args = {...}
            local dumped = safeDump(args)
            local line = "[RemoteFunction] " .. self:GetFullName() .. " " .. HttpService:JSONEncode(dumped)
            print(line)
            table.insert(buffer, line)
            return old(self, ...)
        end
    end
end

--══════════════════════════════════════════════════════
-- Fungsi manual buat copy semua log
--══════════════════════════════════════════════════════
_G.CopyLogs = function()
    local text = table.concat(buffer, "\n")
    copyToClip(text)
end

print("✅ VOID Logger aktif: semua log tersimpan ke buffer.")
print("ℹ️ Jalankan _G.CopyLogs() kapan saja untuk copy semua log ke clipboard!")
