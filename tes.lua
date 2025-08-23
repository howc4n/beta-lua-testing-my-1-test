-- Tambahkan kode ini di bagian paling akhir file IY.lua
-- Sistem auto-copy console log untuk Android

do
    local old_print = print
    local old_warn = warn
    local old_error = error
    
    local log_buffer = {}
    local last_copy_time = 0
    local copy_interval = 5 -- Salin setiap 5 detik
    
    -- Override fungsi print
    print = function(...)
        local msg = table.concat({...}, " ")
        old_print(msg)
        table.insert(log_buffer, "[PRINT] " .. msg)
    end
    
    -- Override fungsi warn
    warn = function(...)
        local msg = table.concat({...}, " ")
        old_warn(msg)
        table.insert(log_buffer, "[WARN] " .. msg)
    end
    
    -- Override fungsi error
    error = function(msg, level)
        local str = tostring(msg)
        old_error(str, level)
        table.insert(log_buffer, "[ERROR] " .. str)
    end
    
    -- Fungsi untuk menyalin log ke clipboard
    local function copy_logs_to_clipboard()
        if #log_buffer == 0 then return end
        
        local full_text = table.concat(log_buffer, "\n")
        
        if everyClipboard then
            everyClipboard(full_text)
        elseif setclipboard then
            setclipboard(full_text)
        end
    end
    
    -- Buat tombol di UI untuk menyalin manual
    local CopyButton = Instance.new("TextButton")
    CopyButton.Name = "CopyLogsButton"
    CopyButton.Parent = ScaledHolder
    CopyButton.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
    CopyButton.BorderSizePixel = 0
    CopyButton.Position = UDim2.new(0, 10, 0, 10)
    CopyButton.Size = UDim2.new(0, 100, 0, 30)
    CopyButton.Font = Enum.Font.SourceSans
    CopyButton.Text = "Copy Logs"
    CopyButton.TextColor3 = Color3.new(1, 1, 1)
    CopyButton.TextSize = 14
    CopyButton.ZIndex = 100
    CopyButton.Visible = true
    
    -- Tambahkan ke arrays untuk styling
    table.insert(shade2, CopyButton)
    table.insert(text1, CopyButton)
    
    -- Fungsi untuk handle klik tombol
    CopyButton.MouseButton1Click:Connect(function()
        copy_logs_to_clipboard()
        notify("Logger", "Logs copied to clipboard!")
    end)
    
    -- Sistem auto-copy periodik
    task.spawn(function()
        while true do
            task.wait(copy_interval)
            
            -- Salin logs ke clipboard setiap interval
            copy_logs_to_clipboard()
            
            -- Kosongkan buffer setelah disalin
            log_buffer = {}
        end
    end)
end
