print("🔥 GROW A GARDEN - CHEAT SYSTEM LOADING...")

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")

print("🔧 Services loaded")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character
local Leaderstats = LocalPlayer.leaderstats
local Backpack = LocalPlayer.Backpack
local PlayerGui = LocalPlayer.PlayerGui

print("🔧 Player:", LocalPlayer.Name)

-- Test notification first
local function createNotification(title, message, duration)
    print("�", title, "-", message)
    
    local notification = Instance.new("ScreenGui")
    notification.Name = "CheatNotification"
    notification.Parent = LocalPlayer.PlayerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.3, 0, 0.1, 0)
    frame.Position = UDim2.new(0.7, 0, 0.1, 0)
    frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    frame.BorderSizePixel = 0
    frame.Parent = notification
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 1, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.Text = title .. ": " .. message
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = frame
    
    -- Auto remove
    spawn(function()
        wait(duration or 3)
        notification:Destroy()
    end)
end

-- Test notification
createNotification("🔥 Test", "Script is running!")

print("🔧 Notification test complete")

-- Configuration
local CheatConfig = {
    AutoPlant = { Enabled = false },
    AutoHarvest = { Enabled = false },
    AutoSell = { Enabled = false },
    NoClip = { Enabled = false }
}

-- Simple GUI Test
local function createSimpleGUI()
    print("🔧 Creating simple GUI...")
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "TestCheatGUI"
    ScreenGui.Parent = LocalPlayer.PlayerGui
    ScreenGui.ResetOnSpawn = false
    
    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 300, 0, 400)
    MainFrame.Position = UDim2.new(0, 50, 0, 50)
    MainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    MainFrame.BorderSizePixel = 2
    MainFrame.BorderColor3 = Color3.new(1, 1, 1)
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.Position = UDim2.new(0, 0, 0, 0)
    Title.Text = "🔥 CHEAT MENU - TESTING"
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.BackgroundColor3 = Color3.new(0.2, 0.2, 0.8)
    Title.BorderSizePixel = 0
    Title.TextScaled = true
    Title.Font = Enum.Font.SourceSansBold
    Title.Parent = MainFrame
    
    -- Close Button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 30, 0, 30)
    CloseButton.Position = UDim2.new(1, -35, 0, 5)
    CloseButton.Text = "X"
    CloseButton.TextColor3 = Color3.new(1, 1, 1)
    CloseButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    CloseButton.BorderSizePixel = 0
    CloseButton.TextScaled = true
    CloseButton.Font = Enum.Font.SourceSansBold
    CloseButton.Parent = MainFrame
    
    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        createNotification("❌ GUI", "Closed")
    end)
    
    local yPos = 60
    
    -- Test buttons
    local function createButton(text, callback)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 280, 0, 40)
        button.Position = UDim2.new(0, 10, 0, yPos)
        button.Text = text
        button.TextColor3 = Color3.new(1, 1, 1)
        button.BackgroundColor3 = Color3.new(0.3, 0.3, 0.6)
        button.BorderSizePixel = 1
        button.BorderColor3 = Color3.new(1, 1, 1)
        button.TextScaled = true
        button.Font = Enum.Font.SourceSans
        button.Parent = MainFrame
        
        button.MouseButton1Click:Connect(callback)
        
        yPos = yPos + 50
        return button
    end
    
    -- Test buttons
    createButton("🔔 Test Notification", function()
        createNotification("🔔 Test", "Button clicked!")
    end)
    
    createButton("🚀 Test Teleport", function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = CFrame.new(0, 10, 0)
            createNotification("🚀 Teleport", "Moved to 0,10,0")
        else
            createNotification("❌ Error", "No character found")
        end
    end)
    
    createButton("👻 Toggle NoClip", function()
        CheatConfig.NoClip.Enabled = not CheatConfig.NoClip.Enabled
        createNotification("👻 NoClip", CheatConfig.NoClip.Enabled and "ON" or "OFF")
    end)
    
    createButton("📊 Show Status", function()
        createNotification("📊 Status", string.format("Character: %s | NoClip: %s", 
            LocalPlayer.Character and "✅" or "❌",
            CheatConfig.NoClip.Enabled and "ON" or "OFF"
        ))
    end)
    
    print("✅ GUI created successfully!")
    createNotification("✅ GUI", "Created successfully!")
    return ScreenGui
end

-- NoClip function
local function NoclipLoop()
    if not CheatConfig.NoClip.Enabled then return end
    
    local Character = LocalPlayer.Character
    if not Character then return end

    for _, Part in Character:GetDescendants() do
        if Part:IsA("BasePart") then
            Part.CanCollide = false
        end
    end
end

print("🔧 Setting up basic services...")

-- Basic connections
RunService.Stepped:Connect(NoclipLoop)

-- Create GUI immediately
local gui = createSimpleGUI()

-- Keybind to toggle GUI
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Insert then
        if gui and gui.Parent then
            gui.Enabled = not gui.Enabled
            createNotification("🎮 GUI", gui.Enabled and "Shown" or "Hidden")
            print("🎮 GUI toggled:", gui.Enabled and "Shown" or "Hidden")
        else
            print("❌ GUI not found, recreating...")
            gui = createSimpleGUI()
        end
    end
end)

print("🔥 SIMPLE CHEAT SYSTEM LOADED!")
print("🎮 Press INSERT to toggle GUI")
print("📢 Check if you can see the notification and GUI!")
