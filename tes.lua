-- Remote logger (client-side, run di executor dulu sebelum cheat)
-- VOID Version ⚔️

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- fungsi aman buat print argumen
local function safeDump(args)
    local dumped = {}
    for i, v in ipairs(args) do
        local t = typeof(v)
        if t == "Instance" then
            dumped[i] = v:GetFullName()
        elseif t == "Vector3" then
            dumped[i] = tostring(v)
        elseif t == "CFrame" then
            dumped[i] = tostring(v)
        else
            dumped[i] = v
        end
    end
    return dumped
end

-- hook RemoteEvent
for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
    if obj:IsA("RemoteEvent") then
        local old = obj.FireServer
        obj.FireServer = function(self, ...)
            local args = {...}
            local dumped = safeDump(args)
            print("[RemoteEvent]", self:GetFullName(), HttpService:JSONEncode(dumped))
            return old(self, ...)
        end
    elseif obj:IsA("RemoteFunction") then
        local old = obj.InvokeServer
        obj.InvokeServer = function(self, ...)
            local args = {...}
            local dumped = safeDump(args)
            print("[RemoteFunction]", self:GetFullName(), HttpService:JSONEncode(dumped))
            return old(self, ...)
        end
    end
end

print("✅ Remote logger aktif, semua call akan dicatat sebelum dieksekusi")
