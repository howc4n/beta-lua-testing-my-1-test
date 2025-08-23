--══════════════════════════════════════════════════════
-- RemoteEvent/Function Logger + Auto Clipboard
--══════════════════════════════════════════════════════
local HS = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local buffer = {}

local function copyToClip(text)
    if setclipboard then
        setclipboard(text)
        print("📋 Copied to clipboard!")
    else
        warn("⚠️ setclipboard not supported by this executor.")
    end
end

local function flush()
    if #buffer == 0 then return end
    local full = table.concat(buffer, "\n")
    copyToClip(full)
    buffer = {}
end

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
            dumped[i] = tostring(v)
        end
    end
    return dumped
end

-- Hook all RemoteEvent / RemoteFunction
for _, obj in ipairs(RS:GetDescendants()) do
    if obj:IsA("RemoteEvent") then
        local old = obj.FireServer
        obj.FireServer = function(self, ...)
            local dumped = safeDump({...})
            local line = "[RemoteEvent] " .. self:GetFullName() .. " " .. HS:JSONEncode(dumped)
            print(line)
            table.insert(buffer, line)
            flush()
            return old(self, ...)
        end
    elseif obj:IsA("RemoteFunction") then
        local old = obj.InvokeServer
        obj.InvokeServer = function(self, ...)
            local dumped = safeDump({...})
            local line = "[RemoteFunction] " .. self:GetFullName() .. " " .. HS:JSONEncode(dumped)
            print(line)
            table.insert(buffer, line)
            flush()
            return old(self, ...)
        end
    end
end

print("✅ Remote logger aktif: semua call langsung dicopy ke clipboard.")
