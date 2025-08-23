--[[
    Grow a Garden Auto-Farm v2.2 - Fixed Initialization
    Enhanced error handling and dependency checking
]]

--══════════════════════════════════════════════════════
-- Android Auto-Copy Console Logger
--══════════════════════════════════════════════════════
local buffer = {}
local autoCopyEnabled = true
local copyInterval = 5 -- Salin setiap 5 detik

-- Fungsi untuk menyalin teks ke clipboard
local function copyToClip(text)
    if setclipboard then
        setclipboard(text)
        return true
    elseif everyClipboard then
        everyClipboard(text)
        return true
    else
        return false
    end
end

-- Fungsi untuk menyimpan dan menyalin log
local function flush()
    if #buffer == 0 then return end
    local full = table.concat(buffer, "\n")
    local success = copyToClip(full)
    
    if success then
        -- Notifikasi sukses
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Console Logs",
            Text = "Logs copied to clipboard!",
            Duration = 3
        })
    else
        -- Notifikasi gagal
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Console Logs",
            Text = "Clipboard not available!",
            Duration = 3
        })
    end
    
    buffer = {}
end

-- Override fungsi print, warn, dan error
local oldPrint, oldWarn, oldError = print, warn, error

print = function(...)
    local msg = table.concat({...}, " ")
    oldPrint(msg)
    table.insert(buffer, "[PRINT] " .. msg)
end

warn = function(...)
    local msg = table.concat({...}, " ")
    oldWarn(msg)
    table.insert(buffer, "[WARN]  " .. msg)
end

error = function(msg, lvl)
    local str = tostring(msg)
    oldError(str, lvl)
    table.insert(buffer, "[ERROR] " .. str)
end

-- Buat tombol UI untuk menyalin manual
local function createCopyButton()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoCopyLogger"
    screenGui.Parent = game:GetService("CoreGui")
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local copyButton = Instance.new("TextButton")
    copyButton.Name = "CopyLogsButton"
    copyButton.Parent = screenGui
    copyButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    copyButton.BorderColor3 = Color3.fromRGB(60, 60, 60)
    copyButton.BorderSizePixel = 2
    copyButton.Position = UDim2.new(0, 10, 0, 10)
    copyButton.Size = UDim2.new(0, 120, 0, 40)
    copyButton.Font = Enum.Font.SourceSansBold
    copyButton.Text = "📋 Copy Logs"
    copyButton.TextColor3 = Color3.new(1, 1, 1)
    copyButton.TextSize = 14
    copyButton.ZIndex = 100

    -- Tambahkan efek hover
    copyButton.MouseEnter:Connect(function()
        copyButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    end)

    copyButton.MouseLeave:Connect(function()
        copyButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end)

    copyButton.MouseButton1Click:Connect(function()
        flush()
    end)

    return screenGui, copyButton
end

-- Buat tombol toggle untuk enable/disable auto copy
local function createToggleButton(parent)
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleAutoCopy"
    toggleButton.Parent = parent
    toggleButton.BackgroundColor3 = autoCopyEnabled and Color3.fromRGB(30, 100, 30) or Color3.fromRGB(100, 30, 30)
    toggleButton.BorderColor3 = Color3.fromRGB(60, 60, 60)
    toggleButton.BorderSizePixel = 2
    toggleButton.Position = UDim2.new(0, 140, 0, 0)
    toggleButton.Size = UDim2.new(0, 150, 0, 40)
    toggleButton.Font = Enum.Font.SourceSansBold
    toggleButton.Text = autoCopyEnabled and "🟢 Auto Copy ON" or "🔴 Auto Copy OFF"
    toggleButton.TextColor3 = Color3.new(1, 1, 1)
    toggleButton.TextSize = 14
    toggleButton.ZIndex = 100

    toggleButton.MouseButton1Click:Connect(function()
        autoCopyEnabled = not autoCopyEnabled
        toggleButton.BackgroundColor3 = autoCopyEnabled and Color3.fromRGB(30, 100, 30) or Color3.fromRGB(100, 30, 30)
        toggleButton.Text = autoCopyEnabled and "🟢 Auto Copy ON" or "🔴 Auto Copy OFF"
        
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Auto Copy",
            Text = autoCopyEnabled and "Auto copy enabled!" or "Auto copy disabled!",
            Duration = 2
        })
    end)

    return toggleButton
end

-- Jalankan sistem auto-copy
local screenGui, copyButton = createCopyButton()
local toggleButton = createToggleButton(screenGui)

-- Sistem auto-copy periodik
task.spawn(function()
    while true do
        task.wait(copyInterval)
        if autoCopyEnabled then
            flush()
        end
    end
end)

-- Notifikasi bahwa logger telah dimulai
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Console Logger",
    Text = "Auto-copy logger started! Logs will be copied every " .. copyInterval .. " seconds.",
    Duration = 5
})

--══════════════════════════════════════════════════════
-- Kode asli script di bawah ini...
--══════════════════════════════════════════════════════

-- Duplicate run guard
if _G.__AF2_RUNNING then
    warn('[AFv2] Script already running; aborting duplicate load.')
    return
end
_G.__AF2_RUNNING = true

local START_TIME = os.clock()
local function log(level, msg)
    print(string.format('[AFv2][%s][%05.2fs] %s', level, os.clock() - START_TIME, msg))
end

-- ... (sisa kode asli script tetap di bawah)
