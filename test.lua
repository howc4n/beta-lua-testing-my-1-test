-- Testing1Beta.lua - Roblox Cheat System
-- Focus: Teleport, Debug Console, Player Adjustments
-- Version: 1.0 Beta

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- ===== CONFIGURATION ===== --
local Config = {
    -- UI Settings
    UIScale = 1,
    Theme = {
        Background = Color3.fromRGB(36, 36, 37),
        Primary = Color3.fromRGB(46, 46, 47),
        Secondary = Color3.fromRGB(78, 78, 79),
        Accent = Color3.fromRGB(125, 85, 255),
        Text = Color3.fromRGB(255, 255, 255),
        Success = Color3.fromRGB(0, 255, 0),
        Warning = Color3.fromRGB(255, 255, 0),
        Error = Color3.fromRGB(255, 0, 0)
    },
    
    -- Teleport Settings
    TeleportSpeed = 1, -- Animation speed (0 = instant)
    SafeTeleport = true, -- Check for obstacles
    
    -- Player Settings
    DefaultWalkSpeed = 16,
    DefaultJumpPower = 50,
    MaxWalkSpeed = 500,
    MaxJumpPower = 500,
    
    -- Debug Settings
    ShowDebugInfo = true,
    LogInteractions = true,
    ScanRadius = 50
}

-- ===== GLOBAL VARIABLES ===== --
local CheatSystem = {
    GUI = nil,
    IsVisible = false,
    CurrentSpeed = Config.DefaultWalkSpeed,
    CurrentJump = Config.DefaultJumpPower,
    Waypoints = {},
    DebugMode = false,
    ClickTeleportEnabled = false,
    ScannedObjects = {},
    InteractionLog = {},
    
    -- Mobile UI Elements
    MainFrame = nil,
    CoordinateDisplay = nil,
    ToggleButtons = {},
    CoordinateEnabled = false,
    CoordinateConnection = nil
}

-- ===== UTILITY FUNCTIONS ===== --
local function Log(message, type)
    local prefix = "[CHEAT]"
    local color = Config.Theme.Text
    
    if type == "success" then
        prefix = "[SUCCESS]"
        color = Config.Theme.Success
    elseif type == "warning" then
        prefix = "[WARNING]"
        color = Config.Theme.Warning
    elseif type == "error" then
        prefix = "[ERROR]"
        color = Config.Theme.Error
    elseif type == "debug" then
        prefix = "[DEBUG]"
        color = Config.Theme.Accent
    end
    
    print(prefix .. " " .. message)
    
    -- Log to interaction log for debug console
    if Config.LogInteractions then
        table.insert(CheatSystem.InteractionLog, {
            timestamp = tick(),
            message = message,
            type = type or "info"
        })
        
        -- Keep only last 100 logs
        if #CheatSystem.InteractionLog > 100 then
            table.remove(CheatSystem.InteractionLog, 1)
        end
    end
end

local function GetDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

local function IsValidPosition(position)
    if not position then return false end
    
    -- Check if position is not NaN or infinite
    local x, y, z = position.X, position.Y, position.Z
    if x ~= x or y ~= y or z ~= z then return false end
    if math.abs(x) == math.huge or math.abs(y) == math.huge or math.abs(z) == math.huge then return false end
    
    return true
end

-- ===== TELEPORT SYSTEM ===== --
local TeleportSystem = {}

function TeleportSystem.SafeTeleport(targetPosition, speed)
    if not Character or not RootPart then
        Log("Character not found!", "error")
        return false
    end
    
    if not IsValidPosition(targetPosition) then
        Log("Invalid teleport position!", "error")
        return false
    end
    
    speed = speed or Config.TeleportSpeed
    
    if speed <= 0 then
        -- Instant teleport
        RootPart.CFrame = CFrame.new(targetPosition)
        Log("Teleported instantly to: " .. tostring(targetPosition), "success")
    else
        -- Smooth teleport with tween
        local tweenInfo = TweenInfo.new(speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(RootPart, tweenInfo, {CFrame = CFrame.new(targetPosition)})
        
        tween:Play()
        Log("Teleporting smoothly to: " .. tostring(targetPosition), "success")
        
        tween.Completed:Connect(function()
            Log("Teleport completed!", "success")
        end)
    end
    
    return true
end

function TeleportSystem.TeleportToPlayer(playerName)
    local targetPlayer = Players:FindFirstChild(playerName)
    if not targetPlayer then
        Log("Player '" .. playerName .. "' not found!", "error")
        return false
    end
    
    if not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        Log("Player '" .. playerName .. "' has no valid character!", "error")
        return false
    end
    
    local targetPosition = targetPlayer.Character.HumanoidRootPart.Position
    return TeleportSystem.SafeTeleport(targetPosition)
end

function TeleportSystem.EnableClickTeleport()
    CheatSystem.ClickTeleportEnabled = true
    Log("Click Teleport enabled! Click anywhere to teleport.", "success")
    
    Mouse.Button1Down:Connect(function()
        if CheatSystem.ClickTeleportEnabled then
            local targetPosition = Mouse.Hit.Position
            TeleportSystem.SafeTeleport(targetPosition + Vector3.new(0, 5, 0)) -- Add slight Y offset
        end
    end)
end

function TeleportSystem.DisableClickTeleport()
    CheatSystem.ClickTeleportEnabled = false
    Log("Click Teleport disabled.", "warning")
end

function TeleportSystem.AddWaypoint(name, position)
    position = position or RootPart.Position
    CheatSystem.Waypoints[name] = position
    Log("Waypoint '" .. name .. "' saved at: " .. tostring(position), "success")
end

function TeleportSystem.TeleportToWaypoint(name)
    local waypoint = CheatSystem.Waypoints[name]
    if not waypoint then
        Log("Waypoint '" .. name .. "' not found!", "error")
        return false
    end
    
    return TeleportSystem.SafeTeleport(waypoint)
end

function TeleportSystem.ListWaypoints()
    Log("=== SAVED WAYPOINTS ===", "debug")
    for name, position in pairs(CheatSystem.Waypoints) do
        Log(name .. ": " .. tostring(position), "debug")
    end
    Log("======================", "debug")
end

-- ===== PLAYER ADJUSTMENT SYSTEM ===== --
local PlayerSystem = {}

function PlayerSystem.SetWalkSpeed(speed)
    if not Humanoid then
        Log("Humanoid not found!", "error")
        return false
    end
    
    speed = math.clamp(speed, 0, Config.MaxWalkSpeed)
    Humanoid.WalkSpeed = speed
    CheatSystem.CurrentSpeed = speed
    Log("Walk speed set to: " .. speed, "success")
    return true
end

function PlayerSystem.SetJumpPower(power)
    if not Humanoid then
        Log("Humanoid not found!", "error")
        return false
    end
    
    power = math.clamp(power, 0, Config.MaxJumpPower)
    
    -- Handle both JumpPower and JumpHeight (newer Roblox versions)
    if Humanoid:FindFirstChild("JumpHeight") then
        Humanoid.JumpHeight = power
    else
        Humanoid.JumpPower = power
    end
    
    CheatSystem.CurrentJump = power
    Log("Jump power set to: " .. power, "success")
    return true
end

function PlayerSystem.ResetPlayer()
    PlayerSystem.SetWalkSpeed(Config.DefaultWalkSpeed)
    PlayerSystem.SetJumpPower(Config.DefaultJumpPower)
    Log("Player stats reset to default.", "success")
end

function PlayerSystem.GetPlayerStats()
    Log("=== PLAYER STATS ===", "debug")
    Log("Walk Speed: " .. (Humanoid.WalkSpeed or "N/A"), "debug")
    Log("Jump Power: " .. (Humanoid.JumpPower or Humanoid.JumpHeight or "N/A"), "debug")
    Log("Health: " .. Humanoid.Health .. "/" .. Humanoid.MaxHealth, "debug")
    Log("Position: " .. tostring(RootPart.Position), "debug")
    Log("===================", "debug")
end

-- ===== OBJECT SCANNER & DEBUG SYSTEM ===== --
local DebugSystem = {}

function DebugSystem.ScanNearbyObjects()
    if not RootPart then
        Log("Character not found for scanning!", "error")
        return
    end
    
    local playerPosition = RootPart.Position
    local foundObjects = {}
    
    Log("=== SCANNING NEARBY OBJECTS ===", "debug")
    Log("Scan radius: " .. Config.ScanRadius .. " studs", "debug")
    
    -- Scan workspace for objects
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Part") or obj:IsA("Model") or obj:IsA("ClickDetector") then
            local objPosition = nil
            
            if obj:IsA("Part") then
                objPosition = obj.Position
            elseif obj:IsA("Model") and obj.PrimaryPart then
                objPosition = obj.PrimaryPart.Position
            elseif obj:IsA("ClickDetector") and obj.Parent:IsA("Part") then
                objPosition = obj.Parent.Position
            end
            
            if objPosition and GetDistance(playerPosition, objPosition) <= Config.ScanRadius then
                local objectInfo = {
                    name = obj.Name,
                    className = obj.ClassName,
                    position = objPosition,
                    distance = GetDistance(playerPosition, objPosition),
                    hasClickDetector = obj:FindFirstChild("ClickDetector") ~= nil,
                    hasPrompt = obj:FindFirstChild("ProximityPrompt") ~= nil,
                    canInteract = false
                }
                
                -- Check for interaction capabilities
                if obj:IsA("ClickDetector") or obj:FindFirstChild("ClickDetector") then
                    objectInfo.canInteract = true
                    objectInfo.interactionType = "Click"
                elseif obj:FindFirstChild("ProximityPrompt") then
                    objectInfo.canInteract = true
                    objectInfo.interactionType = "Proximity"
                end
                
                -- Detect common farming game objects
                local lowerName = obj.Name:lower()
                if string.find(lowerName, "sell") then
                    objectInfo.gameFunction = "Sell"
                elseif string.find(lowerName, "buy") or string.find(lowerName, "shop") then
                    objectInfo.gameFunction = "Buy"
                elseif string.find(lowerName, "collect") or string.find(lowerName, "harvest") then
                    objectInfo.gameFunction = "Collect"
                elseif string.find(lowerName, "plant") or string.find(lowerName, "place") then
                    objectInfo.gameFunction = "Place"
                elseif string.find(lowerName, "seed") then
                    objectInfo.gameFunction = "Seed"
                elseif string.find(lowerName, "plot") or string.find(lowerName, "farm") then
                    objectInfo.gameFunction = "Farm Plot"
                end
                
                table.insert(foundObjects, objectInfo)
            end
        end
    end
    
    -- Sort by distance
    table.sort(foundObjects, function(a, b) return a.distance < b.distance end)
    
    -- Display results
    Log("Found " .. #foundObjects .. " objects:", "debug")
    for i, obj in ipairs(foundObjects) do
        if i <= 10 then -- Show only first 10 objects
            local infoString = string.format(
                "[%d] %s (%s) - Distance: %.1f - Function: %s - Interactive: %s",
                i,
                obj.name,
                obj.className,
                obj.distance,
                obj.gameFunction or "Unknown",
                obj.canInteract and obj.interactionType or "No"
            )
            Log(infoString, "debug")
        end
    end
    
    CheatSystem.ScannedObjects = foundObjects
    Log("===============================", "debug")
    
    return foundObjects
end

function DebugSystem.InteractWithObject(objectIndex)
    if not CheatSystem.ScannedObjects or #CheatSystem.ScannedObjects == 0 then
        Log("No scanned objects available! Run scan first.", "error")
        return false
    end
    
    local obj = CheatSystem.ScannedObjects[objectIndex]
    if not obj then
        Log("Object index " .. objectIndex .. " not found!", "error")
        return false
    end
    
    Log("Attempting to interact with: " .. obj.name, "debug")
    
    -- Find the actual object in workspace
    for _, workspaceObj in pairs(Workspace:GetDescendants()) do
        if workspaceObj.Name == obj.name and workspaceObj.ClassName == obj.className then
            if GetDistance(workspaceObj.Position or workspaceObj.Parent.Position, obj.position) < 5 then
                -- Found the object, try to interact
                if workspaceObj:IsA("ClickDetector") then
                    fireclickdetector(workspaceObj)
                    Log("Clicked object: " .. obj.name, "success")
                    return true
                elseif workspaceObj:FindFirstChild("ClickDetector") then
                    fireclickdetector(workspaceObj.ClickDetector)
                    Log("Clicked object: " .. obj.name, "success")
                    return true
                elseif workspaceObj:FindFirstChild("ProximityPrompt") then
                    fireproximityprompt(workspaceObj.ProximityPrompt)
                    Log("Activated proximity prompt: " .. obj.name, "success")
                    return true
                end
            end
        end
    end
    
    Log("Could not interact with object: " .. obj.name, "error")
    return false
end

function DebugSystem.TeleportToObject(objectIndex)
    if not CheatSystem.ScannedObjects or #CheatSystem.ScannedObjects == 0 then
        Log("No scanned objects available! Run scan first.", "error")
        return false
    end
    
    local obj = CheatSystem.ScannedObjects[objectIndex]
    if not obj then
        Log("Object index " .. objectIndex .. " not found!", "error")
        return false
    end
    
    Log("Teleporting to object: " .. obj.name, "debug")
    return TeleportSystem.SafeTeleport(obj.position + Vector3.new(0, 5, 0))
end

function DebugSystem.ShowInteractionLog()
    Log("=== INTERACTION LOG ===", "debug")
    local recentLogs = {}
    
    -- Get last 20 logs
    local startIndex = math.max(1, #CheatSystem.InteractionLog - 19)
    for i = startIndex, #CheatSystem.InteractionLog do
        table.insert(recentLogs, CheatSystem.InteractionLog[i])
    end
    
    for _, logEntry in ipairs(recentLogs) do
        local timeStr = string.format("%.2f", logEntry.timestamp % 1000)
        Log("[" .. timeStr .. "] " .. logEntry.message, logEntry.type)
    end
    Log("======================", "debug")
end

-- ===== MOBILE UI SYSTEM ===== --
local MobileUI = {}

function MobileUI.CreateMainGUI()
    if CheatSystem.GUI then
        CheatSystem.GUI:Destroy()
    end
    
    -- Main ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CheatSystemGUI"
    screenGui.Parent = CoreGui
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    CheatSystem.GUI = screenGui
    
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Parent = screenGui
    mainFrame.BackgroundColor3 = Config.Theme.Background
    mainFrame.BorderSizePixel = 2
    mainFrame.BorderColor3 = Config.Theme.Accent
    mainFrame.Position = UDim2.new(0, 10, 0, 10)
    mainFrame.Size = UDim2.new(0, 300, 0, 400)
    mainFrame.Active = true
    mainFrame.Draggable = true
    CheatSystem.MainFrame = mainFrame
    
    -- Corner for modern look
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    -- Header
    local header = Instance.new("TextLabel")
    header.Name = "Header"
    header.Parent = mainFrame
    header.BackgroundColor3 = Config.Theme.Accent
    header.Size = UDim2.new(1, 0, 0, 40)
    header.Font = Enum.Font.SourceSansBold
    header.Text = "🎮 CHEAT SYSTEM v1.0"
    header.TextColor3 = Config.Theme.Text
    header.TextSize = 18
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 10)
    headerCorner.Parent = header
    
    -- Hide/Show Button
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Parent = mainFrame
    toggleButton.BackgroundColor3 = Config.Theme.Error
    toggleButton.Position = UDim2.new(1, -35, 0, 5)
    toggleButton.Size = UDim2.new(0, 30, 0, 30)
    toggleButton.Font = Enum.Font.SourceSansBold
    toggleButton.Text = "X"
    toggleButton.TextColor3 = Config.Theme.Text
    toggleButton.TextSize = 16
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 15)
    toggleCorner.Parent = toggleButton
    
    -- Coordinate Display
    local coordFrame = Instance.new("Frame")
    coordFrame.Name = "CoordinateFrame"
    coordFrame.Parent = mainFrame
    coordFrame.BackgroundColor3 = Config.Theme.Primary
    coordFrame.Position = UDim2.new(0, 10, 0, 50)
    coordFrame.Size = UDim2.new(1, -20, 0, 80)
    
    local coordCorner = Instance.new("UICorner")
    coordCorner.CornerRadius = UDim.new(0, 8)
    coordCorner.Parent = coordFrame
    
    local coordLabel = Instance.new("TextLabel")
    coordLabel.Name = "CoordinateLabel"
    coordLabel.Parent = coordFrame
    coordLabel.BackgroundTransparency = 1
    coordLabel.Size = UDim2.new(1, -10, 1, -30)
    coordLabel.Position = UDim2.new(0, 5, 0, 25)
    coordLabel.Font = Enum.Font.Code
    coordLabel.Text = "X: 0.0\nY: 0.0\nZ: 0.0"
    coordLabel.TextColor3 = Config.Theme.Success
    coordLabel.TextSize = 16
    coordLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local coordTitle = Instance.new("TextLabel")
    coordTitle.Name = "CoordinateTitle"
    coordTitle.Parent = coordFrame
    coordTitle.BackgroundTransparency = 1
    coordTitle.Size = UDim2.new(1, 0, 0, 25)
    coordTitle.Font = Enum.Font.SourceSansBold
    coordTitle.Text = "📍 COORDINATES"
    coordTitle.TextColor3 = Config.Theme.Text
    coordTitle.TextSize = 14
    
    CheatSystem.CoordinateDisplay = coordLabel
    
    return mainFrame, screenGui
end

function MobileUI.CreateToggleButton(text, position, callback, defaultState)
    local button = Instance.new("TextButton")
    button.Name = text .. "Toggle"
    button.Parent = CheatSystem.MainFrame
    button.BackgroundColor3 = defaultState and Config.Theme.Success or Config.Theme.Secondary
    button.Position = position
    button.Size = UDim2.new(0, 130, 0, 35)
    button.Font = Enum.Font.SourceSans
    button.Text = text .. (defaultState and " ON" or " OFF")
    button.TextColor3 = Config.Theme.Text
    button.TextSize = 14
    button.AutoButtonColor = false
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    local isToggled = defaultState
    
    button.MouseButton1Click:Connect(function()
        isToggled = not isToggled
        button.BackgroundColor3 = isToggled and Config.Theme.Success or Config.Theme.Secondary
        button.Text = text .. (isToggled and " ON" or " OFF")
        
        if callback then
            callback(isToggled)
        end
        
        -- Visual feedback
        local tween = TweenService:Create(button, TweenInfo.new(0.1), {
            Size = UDim2.new(0, 135, 0, 38)
        })
        tween:Play()
        tween.Completed:Connect(function()
            local tween2 = TweenService:Create(button, TweenInfo.new(0.1), {
                Size = UDim2.new(0, 130, 0, 35)
            })
            tween2:Play()
        end)
    end)
    
    CheatSystem.ToggleButtons[text] = {
        button = button,
        isToggled = isToggled,
        callback = callback
    }
    
    return button
end

function MobileUI.UpdateCoordinates()
    if not CheatSystem.CoordinateEnabled or not CheatSystem.CoordinateDisplay or not RootPart then
        return
    end
    
    local pos = RootPart.Position
    local coordText = string.format(
        "X: %.1f\nY: %.1f\nZ: %.1f",
        pos.X, pos.Y, pos.Z
    )
    CheatSystem.CoordinateDisplay.Text = coordText
end

function MobileUI.ToggleCoordinateDisplay(enabled)
    CheatSystem.CoordinateEnabled = enabled
    
    if enabled then
        -- Start coordinate updates
        if CheatSystem.CoordinateConnection then
            CheatSystem.CoordinateConnection:Disconnect()
        end
        
        CheatSystem.CoordinateConnection = RunService.Heartbeat:Connect(function()
            MobileUI.UpdateCoordinates()
        end)
        
        Log("Coordinate display enabled! 📍", "success")
    else
        -- Stop coordinate updates
        if CheatSystem.CoordinateConnection then
            CheatSystem.CoordinateConnection:Disconnect()
            CheatSystem.CoordinateConnection = nil
        end
        
        if CheatSystem.CoordinateDisplay then
            CheatSystem.CoordinateDisplay.Text = "Coordinates\nDisabled"
        end
        
        Log("Coordinate display disabled.", "warning")
    end
end

function MobileUI.SetupToggleButtons()
    if not CheatSystem.MainFrame then return end
    
    -- Coordinate Toggle
    MobileUI.CreateToggleButton("📍 Coordinates", UDim2.new(0, 10, 0, 140), function(enabled)
        MobileUI.ToggleCoordinateDisplay(enabled)
    end, false)
    
    -- Click Teleport Toggle
    MobileUI.CreateToggleButton("🎯 Click TP", UDim2.new(0, 150, 0, 140), function(enabled)
        if enabled then
            TeleportSystem.EnableClickTeleport()
        else
            TeleportSystem.DisableClickTeleport()
        end
    end, false)
    
    -- Speed Boost Toggle
    MobileUI.CreateToggleButton("⚡ Speed", UDim2.new(0, 10, 0, 185), function(enabled)
        if enabled then
            PlayerSystem.SetWalkSpeed(100)
        else
            PlayerSystem.SetWalkSpeed(Config.DefaultWalkSpeed)
        end
    end, false)
    
    -- Jump Boost Toggle
    MobileUI.CreateToggleButton("🚀 Jump", UDim2.new(0, 150, 0, 185), function(enabled)
        if enabled then
            PlayerSystem.SetJumpPower(150)
        else
            PlayerSystem.SetJumpPower(Config.DefaultJumpPower)
        end
    end, false)
    
    -- Object Scanner Toggle
    MobileUI.CreateToggleButton("🔍 Scanner", UDim2.new(0, 10, 0, 230), function(enabled)
        if enabled then
            DebugSystem.ScanNearbyObjects()
            -- Auto scan every 5 seconds
            CheatSystem.AutoScanConnection = RunService.Heartbeat:Connect(function()
                wait(5)
                if CheatSystem.ToggleButtons["🔍 Scanner"].isToggled then
                    DebugSystem.ScanNearbyObjects()
                end
            end)
        else
            if CheatSystem.AutoScanConnection then
                CheatSystem.AutoScanConnection:Disconnect()
                CheatSystem.AutoScanConnection = nil
            end
        end
    end, false)
    
    -- Player Stats Toggle
    MobileUI.CreateToggleButton("📊 Stats", UDim2.new(0, 150, 0, 230), function(enabled)
        if enabled then
            PlayerSystem.GetPlayerStats()
            -- Show stats every 3 seconds
            CheatSystem.StatsConnection = RunService.Heartbeat:Connect(function()
                wait(3)
                if CheatSystem.ToggleButtons["📊 Stats"].isToggled then
                    PlayerSystem.GetPlayerStats()
                end
            end)
        else
            if CheatSystem.StatsConnection then
                CheatSystem.StatsConnection:Disconnect()
                CheatSystem.StatsConnection = nil
            end
        end
    end, false)
    
    -- Create action buttons
    local scanButton = Instance.new("TextButton")
    scanButton.Name = "ScanButton"
    scanButton.Parent = CheatSystem.MainFrame
    scanButton.BackgroundColor3 = Config.Theme.Accent
    scanButton.Position = UDim2.new(0, 10, 0, 275)
    scanButton.Size = UDim2.new(0, 130, 0, 30)
    scanButton.Font = Enum.Font.SourceSans
    scanButton.Text = "🔍 SCAN NOW"
    scanButton.TextColor3 = Config.Theme.Text
    scanButton.TextSize = 14
    
    local scanCorner = Instance.new("UICorner")
    scanCorner.CornerRadius = UDim.new(0, 6)
    scanCorner.Parent = scanButton
    
    scanButton.MouseButton1Click:Connect(function()
        DebugSystem.ScanNearbyObjects()
    end)
    
    local waypointButton = Instance.new("TextButton")
    waypointButton.Name = "WaypointButton"
    waypointButton.Parent = CheatSystem.MainFrame
    waypointButton.BackgroundColor3 = Config.Theme.Accent
    waypointButton.Position = UDim2.new(0, 150, 0, 275)
    waypointButton.Size = UDim2.new(0, 130, 0, 30)
    waypointButton.Font = Enum.Font.SourceSans
    waypointButton.Text = "📍 SAVE POS"
    waypointButton.TextColor3 = Config.Theme.Text
    waypointButton.TextSize = 14
    
    local waypointCorner = Instance.new("UICorner")
    waypointCorner.CornerRadius = UDim.new(0, 6)
    waypointCorner.Parent = waypointButton
    
    waypointButton.MouseButton1Click:Connect(function()
        local waypointName = "pos_" .. math.floor(tick() % 10000)
        TeleportSystem.AddWaypoint(waypointName)
    end)
    
    -- Reset button
    local resetButton = Instance.new("TextButton")
    resetButton.Name = "ResetButton"
    resetButton.Parent = CheatSystem.MainFrame
    resetButton.BackgroundColor3 = Config.Theme.Warning
    resetButton.Position = UDim2.new(0, 10, 0, 315)
    resetButton.Size = UDim2.new(1, -20, 0, 30)
    resetButton.Font = Enum.Font.SourceSansBold
    resetButton.Text = "🔄 RESET ALL"
    resetButton.TextColor3 = Config.Theme.Text
    resetButton.TextSize = 14
    
    local resetCorner = Instance.new("UICorner")
    resetCorner.CornerRadius = UDim.new(0, 6)
    resetCorner.Parent = resetButton
    
    resetButton.MouseButton1Click:Connect(function()
        PlayerSystem.ResetPlayer()
        -- Reset all toggles
        for name, toggle in pairs(CheatSystem.ToggleButtons) do
            if toggle.isToggled then
                toggle.button.Text = name .. " OFF"
                toggle.button.BackgroundColor3 = Config.Theme.Secondary
                toggle.isToggled = false
                if toggle.callback then
                    toggle.callback(false)
                end
            end
        end
        Log("All systems reset! 🔄", "success")
    end)
end

function MobileUI.ToggleGUI()
    if not CheatSystem.GUI then
        MobileUI.CreateMainGUI()
        MobileUI.SetupToggleButtons()
        CheatSystem.IsVisible = true
        Log("Mobile GUI created! 📱", "success")
    else
        CheatSystem.MainFrame.Visible = not CheatSystem.MainFrame.Visible
        CheatSystem.IsVisible = CheatSystem.MainFrame.Visible
        Log("GUI " .. (CheatSystem.IsVisible and "shown" or "hidden"), "success")
    end
end

-- ===== COMMAND SYSTEM ===== --
local CommandSystem = {}

local Commands = {
    ["tp"] = function(args)
        if #args >= 3 then
            local x, y, z = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
            if x and y and z then
                TeleportSystem.SafeTeleport(Vector3.new(x, y, z))
            else
                Log("Invalid coordinates! Usage: tp <x> <y> <z>", "error")
            end
        elseif #args == 1 then
            TeleportSystem.TeleportToPlayer(args[1])
        else
            Log("Usage: tp <player> OR tp <x> <y> <z>", "error")
        end
    end,
    
    ["clicktp"] = function(args)
        if args[1] == "on" then
            TeleportSystem.EnableClickTeleport()
        elseif args[1] == "off" then
            TeleportSystem.DisableClickTeleport()
        else
            Log("Usage: clicktp <on/off>", "error")
        end
    end,
    
    ["speed"] = function(args)
        local speed = tonumber(args[1])
        if speed then
            PlayerSystem.SetWalkSpeed(speed)
        else
            Log("Current speed: " .. CheatSystem.CurrentSpeed, "debug")
        end
    end,
    
    ["jump"] = function(args)
        local jump = tonumber(args[1])
        if jump then
            PlayerSystem.SetJumpPower(jump)
        else
            Log("Current jump: " .. CheatSystem.CurrentJump, "debug")
        end
    end,
    
    ["waypoint"] = function(args)
        if args[1] == "add" and args[2] then
            TeleportSystem.AddWaypoint(args[2])
        elseif args[1] == "tp" and args[2] then
            TeleportSystem.TeleportToWaypoint(args[2])
        elseif args[1] == "list" then
            TeleportSystem.ListWaypoints()
        else
            Log("Usage: waypoint <add/tp/list> [name]", "error")
        end
    end,
    
    ["scan"] = function(args)
        DebugSystem.ScanNearbyObjects()
    end,
    
    ["interact"] = function(args)
        local index = tonumber(args[1])
        if index then
            DebugSystem.InteractWithObject(index)
        else
            Log("Usage: interact <object_index>", "error")
        end
    end,
    
    ["tpobj"] = function(args)
        local index = tonumber(args[1])
        if index then
            DebugSystem.TeleportToObject(index)
        else
            Log("Usage: tpobj <object_index>", "error")
        end
    end,
    
    ["stats"] = function(args)
        PlayerSystem.GetPlayerStats()
    end,
    
    ["reset"] = function(args)
        PlayerSystem.ResetPlayer()
    end,
    
    ["log"] = function(args)
        DebugSystem.ShowInteractionLog()
    end,
    
    ["help"] = function(args)
        Log("=== AVAILABLE COMMANDS ===", "debug")
        Log("tp <player> OR tp <x> <y> <z> - Teleport", "debug")
        Log("clicktp <on/off> - Toggle click teleport", "debug")
        Log("speed <value> - Set walk speed", "debug")
        Log("jump <value> - Set jump power", "debug")
        Log("waypoint <add/tp/list> [name] - Waypoint system", "debug")
        Log("scan - Scan nearby objects", "debug")
        Log("interact <index> - Interact with scanned object", "debug")
        Log("tpobj <index> - Teleport to scanned object", "debug")
        Log("stats - Show player stats", "debug")
        Log("reset - Reset player stats", "debug")
        Log("log - Show interaction log", "debug")
        Log("help - Show this help", "debug")
        Log("==========================", "debug")
    end
}

function CommandSystem.ExecuteCommand(commandString)
    if not commandString or commandString == "" then return end
    
    local args = {}
    for word in commandString:gmatch("%S+") do
        table.insert(args, word)
    end
    
    if #args == 0 then return end
    
    local command = args[1]:lower()
    table.remove(args, 1) -- Remove command from args
    
    local commandFunc = Commands[command]
    if commandFunc then
        Log("Executing command: " .. command, "debug")
        commandFunc(args)
    else
        Log("Unknown command: " .. command .. ". Type 'help' for available commands.", "error")
    end
end

-- ===== AUTO-UPDATE CHARACTER REFERENCES ===== --
local function UpdateCharacterReferences()
    Character = LocalPlayer.Character
    if Character then
        Humanoid = Character:WaitForChild("Humanoid")
        RootPart = Character:WaitForChild("HumanoidRootPart")
        Log("Character references updated.", "debug")
    end
end

LocalPlayer.CharacterAdded:Connect(UpdateCharacterReferences)

-- ===== INITIALIZATION ===== --
local function Initialize()
    Log("Testing1Beta.lua initialized!", "success")
    Log("Type 'help' for available commands.", "success")
    
    -- Set up some default waypoints
    TeleportSystem.AddWaypoint("spawn", RootPart.Position)
    
    -- Create Mobile GUI
    MobileUI.CreateMainGUI()
    MobileUI.SetupToggleButtons()
    
    -- Initial scan
    task.wait(2) -- Wait for game to load
    DebugSystem.ScanNearbyObjects()
end

-- ===== KEYBIND SETUP ===== --
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- F1 - Toggle click teleport
    if input.KeyCode == Enum.KeyCode.F1 then
        if CheatSystem.ClickTeleportEnabled then
            TeleportSystem.DisableClickTeleport()
        else
            TeleportSystem.EnableClickTeleport()
        end
    end
    
    -- F2 - Scan objects
    if input.KeyCode == Enum.KeyCode.F2 then
        DebugSystem.ScanNearbyObjects()
    end
    
    -- F3 - Show player stats
    if input.KeyCode == Enum.KeyCode.F3 then
        PlayerSystem.GetPlayerStats()
    end
    
    -- F4 - Reset player
    if input.KeyCode == Enum.KeyCode.F4 then
        PlayerSystem.ResetPlayer()
    end
    
    -- F5 - Emergency teleport to spawn
    if input.KeyCode == Enum.KeyCode.F5 then
        TeleportSystem.TeleportToWaypoint("spawn")
    end
    
    -- F6 - Toggle Mobile GUI
    if input.KeyCode == Enum.KeyCode.F6 then
        MobileUI.ToggleGUI()
    end
    
    -- G - Toggle Coordinate Display (quick toggle)
    if input.KeyCode == Enum.KeyCode.G then
        local coordToggle = CheatSystem.ToggleButtons["📍 Coordinates"]
        if coordToggle then
            local newState = not coordToggle.isToggled
            coordToggle.isToggled = newState
            coordToggle.button.BackgroundColor3 = newState and Config.Theme.Success or Config.Theme.Secondary
            coordToggle.button.Text = "📍 Coordinates" .. (newState and " ON" or " OFF")
            if coordToggle.callback then
                coordToggle.callback(newState)
            end
        end
    end
end)

-- ===== COMMAND LINE INTERFACE ===== --
-- Simple command input via console
_G.CheatSystem = CheatSystem
_G.cmd = CommandSystem.ExecuteCommand
_G.tp = function(x, y, z) CommandSystem.ExecuteCommand("tp " .. x .. " " .. y .. " " .. z) end
_G.speed = function(s) CommandSystem.ExecuteCommand("speed " .. s) end
_G.jump = function(j) CommandSystem.ExecuteCommand("jump " .. j) end
_G.scan = function() CommandSystem.ExecuteCommand("scan") end
_G.gui = function() MobileUI.ToggleGUI() end
_G.coords = function() 
    local coordToggle = CheatSystem.ToggleButtons["📍 Coordinates"]
    if coordToggle then
        local newState = not coordToggle.isToggled
        coordToggle.isToggled = newState
        coordToggle.button.BackgroundColor3 = newState and Config.Theme.Success or Config.Theme.Secondary
        coordToggle.button.Text = "📍 Coordinates" .. (newState and " ON" or " OFF")
        if coordToggle.callback then
            coordToggle.callback(newState)
        end
    end
end

-- Initialize the system
Initialize()

Log("=== MOBILE CHEAT SYSTEM ===", "success")
Log("📱 Mobile UI Controls:", "success")
Log("F6 - Toggle Mobile GUI", "success")
Log("G - Quick coordinate toggle", "success")
Log("", "success")
Log("🎮 Keybind Controls:", "success")
Log("F1 - Toggle click teleport", "success")
Log("F2 - Scan nearby objects", "success")
Log("F3 - Show player stats", "success")
Log("F4 - Reset player stats", "success")
Log("F5 - Teleport to spawn", "success")
Log("", "success")
Log("💻 Console shortcuts:", "success")
Log("gui() - Toggle mobile GUI", "success")
Log("coords() - Toggle coordinates", "success")
Log("cmd('help') - Show all commands", "success")
Log("tp(x, y, z) - Quick teleport", "success")
Log("speed(value) - Quick speed change", "success")
Log("jump(value) - Quick jump change", "success")
Log("scan() - Quick object scan", "success")
Log("==========================", "success")
