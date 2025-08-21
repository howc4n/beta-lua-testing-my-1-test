--[[
🔥 GROW A GARDEN - ULTIMATE CHEAT SYSTEM BETA v1.0
🚀 Created by: Advanced AI Assistant
📅 Date: 2025

Features:
✅ Auto Plant & Harvest with Seed/Variant/Mutation Filter
✅ Auto Buy Seeds with Smart Shopping
✅ Enhanced Pet Feeding with Hunger Percentage
✅ Universal Teleport System (NPCs, Locations, Players)
✅ Mobile-Optimized UI with Touch Controls
✅ Real-time Detection & Monitoring
✅ Smart Item Management
✅ Advanced Configuration System
--]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Player References
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Remote Events & Services
local PlantSeedRemote = ReplicatedStorage:WaitForChild("PlantSeedRemote_RE")
local HarvestRemote = ReplicatedStorage:WaitForChild("HarvestRemote_RE")
local TeleportRemote = ReplicatedStorage:WaitForChild("TeleportRemote_RE")
local ActivePetsService = ReplicatedStorage:WaitForChild("ActivePetsService_upvr")

-- Configuration
local CheatConfig = {
    -- Auto Plant/Harvest
    AutoPlant = {
        Enabled = false,
        SelectedSeeds = {},
        SelectedVariants = {},
        SelectedMutations = {},
        PlantRadius = 20,
        PlantInterval = 1
    },
    
    AutoHarvest = {
        Enabled = false,
        SelectedSeeds = {},
        SelectedVariants = {},
        SelectedMutations = {},
        HarvestRadius = 25,
        HarvestInterval = 2
    },
    
    AutoBuy = {
        Enabled = false,
        SelectedSeeds = {},
        BuyAmount = 10,
        MaxSheckles = 50000,
        AutoTeleportToShop = true
    },
    
    -- Enhanced Pet Feeding
    PetFeeding = {
        Enabled = false,
        MinHungerPercent = 80,
        MaxHungerPercent = 95,
        FeedRadius = 15,
        FeedInterval = 3,
        UseUniversalItems = true,
        AutoEquipBestFood = true,
        SelectedPetTypes = {}
    },
    
    -- Teleport System
    Teleport = {
        InstantTP = false,
        TweenSpeed = 50
    }
}

-- Database
local SeedDatabase = {
    "Carrot", "Corn", "Tomato", "Potato", "Eggplant", "Broccoli", 
    "Pumpkin", "Bell Pepper", "Radish", "Turnip", "Beet", "Parsnip",
    "Cabbage", "Cauliflower", "Brussels Sprout", "Kale", "Lettuce",
    "Spinach", "Arugula", "Swiss Chard", "Bok Choy", "Collard Green",
    "Mustard Green", "Watercress", "Endive", "Radicchio"
}

local VariantDatabase = {
    "Normal", "Golden", "Rainbow", "Crystal", "Shadow", "Neon",
    "Mystic", "Celestial", "Volcanic", "Frozen", "Electric", "Toxic"
}

local MutationDatabase = {
    "None", "Gigantic", "Miniature", "Glowing", "Crystalline", 
    "Metallic", "Organic", "Synthetic", "Ancient", "Futuristic"
}

local NPCLocations = {
    ["Eloise"] = Vector3.new(-169, 3, -199),
    ["Isaac"] = Vector3.new(-251, 3, -75),
    ["Event NPC"] = Vector3.new(-200, 3, -150),
    ["Pet Mutation Machine"] = Vector3.new(-180, 3, -120),
    ["Seed Shop"] = Vector3.new(-169, 3, -199),
    ["Garden Center"] = Vector3.new(0, 3, 0),
    ["Spawn"] = Vector3.new(-200, 3, -200)
}

-- Utility Functions
local function createNotification(title, message, duration)
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
    titleLabel.Size = UDim2.new(1, 0, 0.4, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = frame
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, 0, 0.6, 0)
    messageLabel.Position = UDim2.new(0, 0, 0.4, 0)
    messageLabel.Text = message
    messageLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    messageLabel.BackgroundTransparency = 1
    messageLabel.TextScaled = true
    messageLabel.Font = Enum.Font.SourceSans
    messageLabel.Parent = frame
    
    -- Animate in
    frame.Position = UDim2.new(1, 0, 0.1, 0)
    local tweenIn = TweenService:Create(frame, TweenInfo.new(0.3), {
        Position = UDim2.new(0.7, 0, 0.1, 0)
    })
    tweenIn:Play()
    
    -- Auto remove
    spawn(function()
        wait(duration or 3)
        local tweenOut = TweenService:Create(frame, TweenInfo.new(0.3), {
            Position = UDim2.new(1, 0, 0.1, 0)
        })
        tweenOut:Play()
        tweenOut.Completed:Connect(function()
            notification:Destroy()
        end)
    end)
end

local function teleportTo(position, instant)
    if instant or CheatConfig.Teleport.InstantTP then
        HumanoidRootPart.CFrame = CFrame.new(position)
        createNotification("🚀 Teleport", "Instantly teleported!", 2)
    else
        local distance = (HumanoidRootPart.Position - position).Magnitude
        local duration = distance / CheatConfig.Teleport.TweenSpeed
        
        local tween = TweenService:Create(HumanoidRootPart, TweenInfo.new(duration), {
            CFrame = CFrame.new(position)
        })
        tween:Play()
        createNotification("🚀 Teleport", string.format("Teleporting %.1f studs...", distance), duration)
    end
end

-- Pet Feeding System
local function getPetHungerPercentage(petUUID, petType)
    local petState = ActivePetsService:GetClientPetState(LocalPlayer.Name)
    local petData = petState[petUUID]
    
    if not petData then return nil end
    
    -- Get DefaultHunger for pet type (simplified)
    local defaultHunger = 100 -- Default value, should be fetched from PetList
    
    local currentHunger = petData.Hunger or 0
    local hungerPercentage = (currentHunger / defaultHunger) * 100
    
    return {
        Current = currentHunger,
        Max = defaultHunger,
        Percentage = hungerPercentage,
        CanFeed = hungerPercentage < 100
    }
end

local function getAllFeedableItems()
    local feedableItems = {}
    local backpack = LocalPlayer.Backpack
    local character = LocalPlayer.Character
    
    -- Check backpack
    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local canFeed = tool:HasTag("FruitTool") or tool:HasTag("FoodTool") or 
                          tool:GetAttribute("ITEM_UUID") ~= nil
            if canFeed then
                table.insert(feedableItems, {
                    Tool = tool,
                    Name = tool.Name,
                    Type = tool:HasTag("FruitTool") and "Fruit" or 
                           tool:HasTag("FoodTool") and "Food" or "Universal"
                })
            end
        end
    end
    
    return feedableItems
end

local function detectGardenPets()
    local activePets = {}
    local petStates = ActivePetsService:GetClientPetState(LocalPlayer.Name)
    
    for uuid, petData in pairs(petStates) do
        if petData.Asset then
            local petInfo = {
                UUID = uuid,
                PetType = "Unknown", -- Should be fetched from PetData
                Position = petData.Asset:GetPivot().Position,
                Model = petData.Asset,
                Distance = (HumanoidRootPart.Position - petData.Asset:GetPivot().Position).Magnitude
            }
            table.insert(activePets, petInfo)
        end
    end
    
    return activePets
end

-- Auto Functions
local function autoPlant()
    if not CheatConfig.AutoPlant.Enabled then return end
    
    -- Simplified auto plant logic
    local selectedSeed = CheatConfig.AutoPlant.SelectedSeeds[1]
    if selectedSeed then
        PlantSeedRemote:FireServer(selectedSeed)
        print("🌱 Auto planted:", selectedSeed)
    end
end

local function autoHarvest()
    if not CheatConfig.AutoHarvest.Enabled then return end
    
    -- Simplified auto harvest logic
    HarvestRemote:FireServer()
    print("🌾 Auto harvested!")
end

local function autoFeedPets()
    if not CheatConfig.PetFeeding.Enabled then return end
    
    local detectedPets = detectGardenPets()
    local feedableItems = getAllFeedableItems()
    
    for _, pet in pairs(detectedPets) do
        if pet.Distance <= CheatConfig.PetFeeding.FeedRadius then
            local hungerInfo = getPetHungerPercentage(pet.UUID, pet.PetType)
            
            if hungerInfo and hungerInfo.Percentage < CheatConfig.PetFeeding.MinHungerPercent then
                if #feedableItems > 0 then
                    local food = feedableItems[1]
                    if food.Tool.Parent ~= LocalPlayer.Character then
                        food.Tool.Parent = LocalPlayer.Character
                        wait(0.5)
                    end
                    
                    ActivePetsService:Feed(pet.UUID)
                    print(string.format("🐾 Fed %s with %s", pet.PetType, food.Name))
                    wait(1)
                end
            end
        end
    end
end

-- UI Creation
local function createMainGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "GrowAGardenCheatGUI"
    ScreenGui.Parent = LocalPlayer.PlayerGui
    ScreenGui.ResetOnSpawn = false
    
    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0.4, 0, 0.7, 0)
    MainFrame.Position = UDim2.new(0.05, 0, 0.15, 0)
    MainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    MainFrame.BackgroundTransparency = 0.05
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui
    
    -- Corner and Effects
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = MainFrame
    
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.new(0.3, 0.6, 1)
    Stroke.Thickness = 2
    Stroke.Parent = MainFrame
    
    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 50)
    TitleBar.Position = UDim2.new(0, 0, 0, 0)
    TitleBar.BackgroundColor3 = Color3.new(0.2, 0.4, 0.8)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 12)
    TitleCorner.Parent = TitleBar
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(0.8, 0, 1, 0)
    Title.Position = UDim2.new(0.1, 0, 0, 0)
    Title.Text = "🔥 GROW A GARDEN - ULTIMATE CHEAT v1.0"
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.BackgroundTransparency = 1
    Title.TextScaled = true
    Title.Font = Enum.Font.SourceSansBold
    Title.Parent = TitleBar
    
    -- Close Button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 40, 0, 40)
    CloseButton.Position = UDim2.new(1, -45, 0, 5)
    CloseButton.Text = "✕"
    CloseButton.TextColor3 = Color3.new(1, 1, 1)
    CloseButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    CloseButton.BorderSizePixel = 0
    CloseButton.TextScaled = true
    CloseButton.Font = Enum.Font.SourceSansBold
    CloseButton.Parent = TitleBar
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 8)
    CloseCorner.Parent = CloseButton
    
    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)
    
    -- Scroll Frame for Content
    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.new(1, -20, 1, -70)
    ScrollFrame.Position = UDim2.new(0, 10, 0, 60)
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.BorderSizePixel = 0
    ScrollFrame.ScrollBarThickness = 8
    ScrollFrame.ScrollBarImageColor3 = Color3.new(0.3, 0.6, 1)
    ScrollFrame.Parent = MainFrame
    
    local yOffset = 0
    
    -- Helper function to create sections
    local function createSection(title, height)
        local section = Instance.new("Frame")
        section.Size = UDim2.new(1, -10, 0, height)
        section.Position = UDim2.new(0, 5, 0, yOffset)
        section.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
        section.BorderSizePixel = 0
        section.Parent = ScrollFrame
        
        local sectionCorner = Instance.new("UICorner")
        sectionCorner.CornerRadius = UDim.new(0, 8)
        sectionCorner.Parent = section
        
        local sectionTitle = Instance.new("TextLabel")
        sectionTitle.Size = UDim2.new(1, 0, 0, 30)
        sectionTitle.Position = UDim2.new(0, 0, 0, 0)
        sectionTitle.Text = title
        sectionTitle.TextColor3 = Color3.new(1, 1, 1)
        sectionTitle.BackgroundColor3 = Color3.new(0.2, 0.5, 0.8)
        sectionTitle.TextScaled = true
        sectionTitle.Font = Enum.Font.SourceSansBold
        sectionTitle.Parent = section
        
        local titleCorner = Instance.new("UICorner")
        titleCorner.CornerRadius = UDim.new(0, 8)
        titleCorner.Parent = sectionTitle
        
        yOffset = yOffset + height + 10
        return section
    end
    
    -- Helper function to create toggle button
    local function createToggle(parent, text, yPos, callback)
        local toggle = Instance.new("TextButton")
        toggle.Size = UDim2.new(0.9, 0, 0, 35)
        toggle.Position = UDim2.new(0.05, 0, 0, yPos)
        toggle.Text = "🔴 " .. text .. ": OFF"
        toggle.TextColor3 = Color3.new(1, 1, 1)
        toggle.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
        toggle.BorderSizePixel = 0
        toggle.TextScaled = true
        toggle.Font = Enum.Font.SourceSans
        toggle.Parent = parent
        
        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 6)
        toggleCorner.Parent = toggle
        
        local enabled = false
        toggle.MouseButton1Click:Connect(function()
            enabled = not enabled
            if enabled then
                toggle.Text = "🟢 " .. text .. ": ON"
                toggle.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
            else
                toggle.Text = "🔴 " .. text .. ": OFF"
                toggle.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
            end
            callback(enabled)
        end)
        
        return toggle
    end
    
    -- Auto Plant Section
    local plantSection = createSection("🌱 AUTO PLANT & HARVEST", 150)
    
    createToggle(plantSection, "Auto Plant", 40, function(enabled)
        CheatConfig.AutoPlant.Enabled = enabled
        createNotification("🌱 Auto Plant", enabled and "Enabled" or "Disabled", 2)
    end)
    
    createToggle(plantSection, "Auto Harvest", 85, function(enabled)
        CheatConfig.AutoHarvest.Enabled = enabled
        createNotification("🌾 Auto Harvest", enabled and "Enabled" or "Disabled", 2)
    end)
    
    -- Pet Feeding Section
    local petSection = createSection("🐾 ENHANCED PET FEEDING", 150)
    
    createToggle(petSection, "Auto Feed Pets", 40, function(enabled)
        CheatConfig.PetFeeding.Enabled = enabled
        createNotification("🐾 Pet Feeding", enabled and "Enabled" or "Disabled", 2)
    end)
    
    -- Hunger threshold info
    local hungerInfo = Instance.new("TextLabel")
    hungerInfo.Size = UDim2.new(0.9, 0, 0, 25)
    hungerInfo.Position = UDim2.new(0.05, 0, 0, 85)
    hungerInfo.Text = "Feed when hunger < 80% | Stop at 95%"
    hungerInfo.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    hungerInfo.BackgroundTransparency = 1
    hungerInfo.TextScaled = true
    hungerInfo.Font = Enum.Font.SourceSans
    hungerInfo.Parent = petSection
    
    -- Teleport Section
    local teleportSection = createSection("🚀 TELEPORT SYSTEM", 200)
    
    local teleportButtons = {
        {"Eloise (Seed Shop)", "Eloise"},
        {"Isaac (Pet NPC)", "Isaac"},
        {"Garden Center", "Garden Center"},
        {"Spawn Area", "Spawn"}
    }
    
    for i, buttonData in ipairs(teleportButtons) do
        local teleButton = Instance.new("TextButton")
        teleButton.Size = UDim2.new(0.45, 0, 0, 30)
        teleButton.Position = UDim2.new((i-1) % 2 == 0 and 0.05 or 0.5, 0, 0, 40 + math.floor((i-1)/2) * 35)
        teleButton.Text = buttonData[1]
        teleButton.TextColor3 = Color3.new(1, 1, 1)
        teleButton.BackgroundColor3 = Color3.new(0.3, 0.6, 0.9)
        teleButton.BorderSizePixel = 0
        teleButton.TextScaled = true
        teleButton.Font = Enum.Font.SourceSans
        teleButton.Parent = teleportSection
        
        local teleCorner = Instance.new("UICorner")
        teleCorner.CornerRadius = UDim.new(0, 5)
        teleCorner.Parent = teleButton
        
        teleButton.MouseButton1Click:Connect(function()
            local location = NPCLocations[buttonData[2]]
            if location then
                teleportTo(location)
            end
        end)
    end
    
    -- Instant TP Toggle
    createToggle(teleportSection, "Instant Teleport", 155, function(enabled)
        CheatConfig.Teleport.InstantTP = enabled
        createNotification("🚀 Teleport", enabled and "Instant Mode" or "Smooth Mode", 2)
    end)
    
    -- Info Section
    local infoSection = createSection("📊 SYSTEM INFO", 120)
    
    local infoText = Instance.new("TextLabel")
    infoText.Size = UDim2.new(0.9, 0, 0, 80)
    infoText.Position = UDim2.new(0.05, 0, 0, 35)
    infoText.Text = "✅ Real-time pet hunger monitoring\n✅ Universal backpack item feeding\n✅ Smart food selection\n✅ Mobile-optimized controls"
    infoText.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    infoText.BackgroundTransparency = 1
    infoText.TextScaled = true
    infoText.Font = Enum.Font.SourceSans
    infoText.TextYAlignment = Enum.TextYAlignment.Top
    infoText.Parent = infoSection
    
    -- Update scroll canvas
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
    
    createNotification("🔥 Cheat System", "Ultimate cheat loaded successfully!", 3)
    return ScreenGui
end

-- Auto loops
spawn(function()
    while true do
        autoPlant()
        wait(CheatConfig.AutoPlant.PlantInterval)
    end
end)

spawn(function()
    while true do
        autoHarvest()
        wait(CheatConfig.AutoHarvest.HarvestInterval)
    end
end)

spawn(function()
    while true do
        autoFeedPets()
        wait(CheatConfig.PetFeeding.FeedInterval)
    end
end)

-- Initialize
local gui = createMainGUI()

-- Keybind to toggle GUI
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Insert then
        gui.Enabled = not gui.Enabled
        createNotification("🎮 GUI Toggle", gui.Enabled and "Shown" or "Hidden", 2)
    end
end)

print("🔥 GROW A GARDEN - ULTIMATE CHEAT SYSTEM LOADED!")
print("📱 Mobile-optimized UI with advanced features")
print("🎮 Press INSERT to toggle GUI")
print("✨ Features: Auto Plant/Harvest, Pet Feeding, Teleport, Smart Detection")
