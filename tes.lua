local HS = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local buffer = {}

local function safeDump(args)
    local dumped = {}
    for i,v in ipairs(args) do
        local t = typeof(v)
        if t == "Instance" then
            dumped[i] = v:GetFullName()
        else
            dumped[i] = tostring(v)
        end
    end
    return dumped
end

local function copyToClip(text)
    if setclipboard then
        setclipboard(text)
        print("Copied to clipboard: "..string.sub(text,1,100)) -- preview
    end
end

local function flush()
    if #buffer == 0 then return end
    local full = table.concat(buffer, "\n")
    copyToClip(full)
    buffer = {}
end

for _,obj in ipairs(RS:GetDescendants()) do
    if obj:IsA("RemoteEvent") then
        local old = obj.FireServer
        obj.FireServer = function(self,...)
            local line = "[RemoteEvent] "..self:GetFullName().." "..HS:JSONEncode(safeDump({...}))
            table.insert(buffer,line)
            flush()
            return old(self,...)
        end
    elseif obj:IsA("RemoteFunction") then
        local old = obj.InvokeServer
        obj.InvokeServer = function(self,...)
            local line = "[RemoteFunction] "..self:GetFullName().." "..HS:JSONEncode(safeDump({...}))
            table.insert(buffer,line)
            flush()
            return old(self,...)
        end
    end
end

print("Logger aktif")
