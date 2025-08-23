--══════════════════════════════════════════════════════
-- Remote Sniffer + Auto Clipboard Logger ⚔️ VOID Version
--══════════════════════════════════════════════════════
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

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
        elseif t == "userdata" then
            dumped[i] = "[UserData]"
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
            copyToClip(line) -- auto copy 1-line
            return old(self, ...)
        end
    elseif obj:IsA("RemoteFunction") then
        local old = obj.InvokeServer
        obj.InvokeServer = function(self, ...)
            local args = {...}
            local dumped = safeDump(args)
            local line = "[RemoteFunction] " .. self:GetFullName() .. " " .. HttpService:JSONEncode(dumped)
            print(line)
            copyToClip(line) -- auto copy 1-line
            return old(self, ...)
        end
    end
end

print("✅ VOID Logger aktif: semua Remote call dicopy otomatis ke clipboard")
