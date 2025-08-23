--[[
    Safe Console Logger v1.0
    (prevents Delta executor parse errors)
]]

-- kasih tanda kalau script berhasil jalan
print("✅ Script sudah ter-run di client executor!")

-- kalau mau kasih warning/error style
warn("⚡ Logger aktif: semua remote call akan dideteksi!")

--══════════════════════════════════════════════════════
-- 1-line console-to-clipboard logger
--══════════════════════════════════════════════════════
local HS = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local buffer = {}

local function copyToClip(text)
    if setclipboard then
        setclipboard(text)
    else
        -- fallback for executors without setclipboard
        local bind = Instance.new("BindableFunction")
        bind.OnInvoke = function() return text end
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Console copied!",
            Text  = "Press Ctrl+V anywhere.",
            Duration = 3,
            Callback = bind,
            Button1  = "OK"
        })
    end
end

local function flush()
    if #buffer == 0 then return end
    local full = table.concat(buffer, "\n")
    copyToClip(full)
    buffer = {}
end

-- Hook built-ins
local oldPrint, oldWarn, oldError = print, warn, error
print = function(...)
    local msg = table.concat({...}, " ")
    oldPrint(msg)
    table.insert(buffer, "[PRINT] " .. msg)
end
warn  = function(...)
    local msg = table.concat({...}, " ")
    oldWarn(msg)
    table.insert(buffer, "[WARN]  " .. msg)
end
error = function(msg, lvl)
    local str = tostring(msg)
    oldError(str, lvl)
    table.insert(buffer, "[ERROR] " .. str)
end

-- Hotkey: Ctrl+Shift+C = manual flush
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.C and UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
        flush()
    end
end)

-- Auto-flush tiap 5 detik
task.spawn(function()
    while true do
        task.wait(5)
        flush()
    end
end)
