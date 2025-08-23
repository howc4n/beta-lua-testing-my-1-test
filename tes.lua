--══════════════════════════════════════════════════════
-- Remote Logger Auto-Copy (Obsidian2 Style) ⚔️
--══════════════════════════════════════════════════════
local HS = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local buffer = {}

-- fungsi dump aman
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

-- flush ke clipboard
local function flush()
    if #buffer == 0 then return end
    local full = table.concat(buffer, "\n")
    if setclipboard then
        setclipboard(full)
        print("📋 Copied "..tostring(#buffer).." log(s) to clipboard")
    end
    buffer = {}
end

-- Hook RemoteEvent & RemoteFunction
for _, obj in ipairs(RS:GetDescendants()) do
    if obj:IsA("RemoteEvent") then
        local old = obj.FireServer
        obj.FireServer = function(self, ...)
            local line = "[RemoteEvent] " .. self:GetFullName() .. " " .. HS:JSONEncode(safeDump({...}))
            table.insert(buffer, line)
            print(line) -- trigger flush lewat print
            return old(self, ...)
        end
    elseif obj:IsA("RemoteFunction") then
        local old = obj.InvokeServer
        obj.InvokeServer = function(self, ...)
            local line = "[RemoteFunction] " .. self:GetFullName() .. " " .. HS:JSONEncode(safeDump({...}))
            table.insert(buffer, line)
            print(line) -- trigger flush lewat print
            return old(self, ...)
        end
    end
end

-- override print biar flush otomatis kayak obsidian2
local oldPrint = print
print = function(...)
    oldPrint(...)
    flush()
end

print("✅ Remote Logger aktif (Obsidian2 style)")
