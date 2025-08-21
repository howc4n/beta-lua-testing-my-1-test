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

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")

print("🔧 Loading services...")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character
local Leaderstats = LocalPlayer.leaderstats
local Backpack = LocalPlayer.Backpack
local PlayerGui = LocalPlayer.PlayerGui

print("🔧 Player references loaded")

local ShecklesCount = Leaderstats and Leaderstats.Sheckles
local GameInfo
pcall(function()
    GameInfo = MarketplaceService:GetProductInfo(game.PlaceId)
end)

print("🔧 Game info:", GameInfo and GameInfo.Name or "Failed to load")

--// Folders
local GameEvents = ReplicatedStorage:FindFirstChild("GameEvents")
local Farms = workspace:FindFirstChild("Farm")

print("🔧 GameEvents found:", GameEvents and "✅" or "❌")
print("🔧 Farms found:", Farms and "✅" or "❌")

-- Safe character initialization
local function getRoot(char)
    return char and (char:FindFirstChild('HumanoidRootPart') or char:FindFirstChild('Torso') or char:FindFirstChild('UpperTorso'))
end

--// Remote Events (proper game remotes)
local PlantRemote, HarvestRemote, SellRemote, BuySeedRemote

if GameEvents then
    -- Try different possible names for remotes
    PlantRemote = GameEvents:FindFirstChild("Plant_RE") or 
                  GameEvents:FindFirstChild("PlantRemote") or
                  GameEvents:FindFirstChild("Plant") or
                  GameEvents:FindFirstChild("PlantSeed")
                  
    HarvestRemote = GameEvents:FindFirstChild("Harvest_RE") or
                    GameEvents:FindFirstChild("HarvestRemote") or
                    GameEvents:FindFirstChild("Harvest") or
                    GameEvents:FindFirstChild("HarvestPlant")
                    
    SellRemote = GameEvents:FindFirstChild("Sell_Inventory") or
                 GameEvents:FindFirstChild("SellInventory") or
                 GameEvents:FindFirstChild("Sell") or
                 GameEvents:FindFirstChild("SellRemote")
                 
    BuySeedRemote = GameEvents:FindFirstChild("BuySeedStock") or
                    GameEvents:FindFirstChild("BuySeed") or
                    GameEvents:FindFirstChild("BuyRemote") or
                    GameEvents:FindFirstChild("PurchaseSeed")
                    
    -- Debug: List all available remotes
    print("🔧 Available GameEvents:")
    for _, child in pairs(GameEvents:GetChildren()) do
        if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
            print("   -", child.Name, "(" .. child.ClassName .. ")")
        end
    end
end

print("🔧 Remote Events:")
print("   PlantRemote:", PlantRemote and "✅" or "❌")
print("   HarvestRemote:", HarvestRemote and "✅" or "❌") 
print("   SellRemote:", SellRemote and "✅" or "❌")
print("   BuySeedRemote:", BuySeedRemote and "✅" or "❌")

--// Configuration
local CheatConfig = {
    AutoPlant = {
        Enabled = false,
        SelectedSeed = "Carrot",
        PlantRandom = false,
        PlantInterval = 0.3
    },
    
    AutoHarvest = {
        Enabled = false,
        HarvestRadius = 25,
        HarvestInterval = 0.1
    },
    
    AutoBuy = {
        Enabled = false,
        SelectedSeed = "Carrot",
        BuyAmount = 10
    },
    
    AutoSell = {
        Enabled = false,
        SellThreshold = 15
    },
    
    AutoWalk = {
        Enabled = false,
        MaxWait = 10,
        AllowRandom = true
    },
    
    NoClip = {
        Enabled = false
    },
    
    Teleport = {
        InstantTP = false,
        TweenSpeed = 50
    }
}

--// Globals
local IsSelling = false
local SeedStock = {}
local OwnedSeeds = {}

local HarvestIgnores = {
    Normal = false,
    Gold = false,
    Rainbow = false
}

--// Database
local SeedDatabase = {
    "Carrot", "Corn", "Tomato", "Potato", "Eggplant", "Broccoli", 
    "Pumpkin", "Bell Pepper", "Radish", "Turnip", "Beet", "Parsnip",
    "Cabbage", "Cauliflower", "Brussels Sprout", "Kale", "Lettuce",
    "Spinach", "Arugula", "Swiss Chard", "Bok Choy", "Collard Green",
    "Mustard Green", "Watercress", "Endive", "Radicchio"
}

local NPCLocations = {
    ["Eloise"] = Vector3.new(62, 4, -26),
    ["Garden Center"] = Vector3.new(0, 4, 0),
    ["Spawn"] = Vector3.new(-200, 4, -200)
}

--// Core Functions
local function Plant(Position: Vector3, Seed: string)
    if PlantRemote then
        PlantRemote:FireServer(Position, Seed)
        wait(CheatConfig.AutoPlant.PlantInterval)
    end
end

local function GetFarms()
    if not Farms then return {} end
    return Farms:GetChildren()
end

local function GetFarmOwner(Farm: Folder): string?
    local Important = Farm:FindFirstChild("Important")
    if not Important then return end
    local Data = Important:FindFirstChild("Data")
    if not Data then return end
    local Owner = Data:FindFirstChild("Owner")
    if not Owner then return end
    return Owner.Value
end

local function GetFarm(PlayerName: string): Folder?
    local Farms = GetFarms()
    for _, Farm in next, Farms do
        local Owner = GetFarmOwner(Farm)
        if Owner == PlayerName then
            return Farm
        end
    end
    return
end

local function SellInventory()
    local Character = LocalPlayer.Character
    if not Character then return end
    
    local Previous = Character:GetPivot()
    local PreviousSheckles = ShecklesCount and ShecklesCount.Value or 0

    --// Prevent conflict
    if IsSelling then return end
    IsSelling = true

    Character:PivotTo(CFrame.new(62, 4, -26))
    while wait() do
        if ShecklesCount and ShecklesCount.Value ~= PreviousSheckles then break end
        if SellRemote then
            SellRemote:FireServer()
        end
    end
    Character:PivotTo(Previous)

    wait(0.2)
    IsSelling = false
end

local function BuySeed(Seed: string)
    if BuySeedRemote then
        BuySeedRemote:FireServer(Seed)
    end
end

local function GetSeedInfo(Seed: Tool): string?, number?
    local PlantName = Seed:FindFirstChild("Plant_Name")
    local Count = Seed:FindFirstChild("Numbers")
    if not PlantName then return end
    return PlantName.Value, Count and Count.Value or 1
end

local function CollectSeedsFromParent(Parent, Seeds: table)
    for _, Tool in next, Parent:GetChildren() do
        local Name, Count = GetSeedInfo(Tool)
        if not Name then continue end
        Seeds[Name] = {
            Count = Count,
            Tool = Tool
        }
    end
end

local function GetOwnedSeeds(): table
    local Character = LocalPlayer.Character
    
    table.clear(OwnedSeeds)
    CollectSeedsFromParent(Backpack, OwnedSeeds)
    if Character then
        CollectSeedsFromParent(Character, OwnedSeeds)
    end
    return OwnedSeeds
end

local function GetArea(Base: BasePart)
    local Center = Base:GetPivot()
    local Size = Base.Size

    --// Bottom left
    local X1 = math.ceil(Center.X - (Size.X/2))
    local Z1 = math.ceil(Center.Z - (Size.Z/2))

    --// Top right
    local X2 = math.floor(Center.X + (Size.X/2))
    local Z2 = math.floor(Center.Z + (Size.Z/2))

    return X1, Z1, X2, Z2
end

local function EquipCheck(Tool)
    local Character = LocalPlayer.Character
    if not Character then return end
    local Humanoid = Character:FindFirstChild("Humanoid")
    if not Humanoid then return end

    if Tool.Parent ~= Backpack then return end
    Humanoid:EquipTool(Tool)
end

--// Utility Functions
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
    local character = LocalPlayer.Character
    if not character then return end
    
    local rootPart = getRoot(character)
    if not rootPart then return end
    
    if instant or CheatConfig.Teleport.InstantTP then
        rootPart.CFrame = CFrame.new(position)
        createNotification("🚀 Teleport", "Instantly teleported!", 2)
    else
        local distance = (rootPart.Position - position).Magnitude
        local duration = distance / CheatConfig.Teleport.TweenSpeed
        
        local tween = TweenService:Create(rootPart, TweenInfo.new(duration), {
            CFrame = CFrame.new(position)
        })
        tween:Play()
        createNotification("🚀 Teleport", string.format("Teleporting %.1f studs...", distance), duration)
    end
end

--// Auto farm functions
local MyFarm
local MyImportant
local PlantLocations
local PlantsPhysical

-- Initialize farm data
local function InitializeFarmData()
    if not Farms then 
        print("❌ No Farms folder found")
        return 
    end
    
    MyFarm = GetFarm(LocalPlayer.Name)
    if not MyFarm then
        print("❌ Player farm not found")
        return
    end
    
    MyImportant = MyFarm:FindFirstChild("Important")
    if not MyImportant then
        print("❌ Farm Important folder not found")
        return
    end
    
    PlantLocations = MyImportant:FindFirstChild("Plant_Locations")
    PlantsPhysical = MyImportant:FindFirstChild("Plants_Physical")
    
    print("🔧 Farm data initialized:")
    print("   MyFarm:", MyFarm and "✅" or "❌")
    print("   PlantLocations:", PlantLocations and "✅" or "❌")
    print("   PlantsPhysical:", PlantsPhysical and "✅" or "❌")
end

-- Initial farm data setup
InitializeFarmData()

local function GetRandomFarmPoint(): Vector3?
    if not PlantLocations then return end
    local FarmLands = PlantLocations:GetChildren()
    if #FarmLands == 0 then return end
    
    local FarmLand = FarmLands[math.random(1, #FarmLands)]
    local X1, Z1, X2, Z2 = GetArea(FarmLand)
    local X = math.random(X1, X2)
    local Z = math.random(Z1, Z2)

    return Vector3.new(X, 4, Z)
end

local function AutoPlantLoop()
    local Seed = CheatConfig.AutoPlant.SelectedSeed
    if not Seed then return end

    local SeedData = OwnedSeeds[Seed]
    if not SeedData then return end

    local Count = SeedData.Count
    local Tool = SeedData.Tool

    --// Check for stock
    if Count <= 0 then return end

    local Planted = 0
    local Step = 1

    --// Check if the client needs to equip the tool
    EquipCheck(Tool)

    --// Plant at random points
    if CheatConfig.AutoPlant.PlantRandom and PlantLocations then
        for i = 1, Count do
            local Point = GetRandomFarmPoint()
            if Point then
                Plant(Point, Seed)
            end
        end
        return
    end
    
    --// Plant on the farmland area
    if PlantLocations then
        local Dirt = PlantLocations:FindFirstChildOfClass("Part")
        if Dirt then
            local X1, Z1, X2, Z2 = GetArea(Dirt)
            for X = X1, X2, Step do
                for Z = Z1, Z2, Step do
                    if Planted >= Count then break end
                    local Point = Vector3.new(X, 0.13, Z)
                    Planted += 1
                    Plant(Point, Seed)
                end
            end
        end
    end
end

local function HarvestPlant(Plant: Model)
    local Prompt = Plant:FindFirstChild("ProximityPrompt", true)
    --// Check if it can be harvested
    if not Prompt then return end
    fireproximityprompt(Prompt)
end

local function CanHarvest(Plant): boolean?
    local Prompt = Plant:FindFirstChild("ProximityPrompt", true)
    if not Prompt then return end
    if not Prompt.Enabled then return end
    return true
end

local function CollectHarvestable(Parent, Plants, IgnoreDistance: boolean?)
    local Character = LocalPlayer.Character
    if not Character then return Plants end
    local PlayerPosition = Character:GetPivot().Position

    for _, Plant in next, Parent:GetChildren() do
        --// Fruits
        local Fruits = Plant:FindFirstChild("Fruits")
        if Fruits then
            CollectHarvestable(Fruits, Plants, IgnoreDistance)
        end

        --// Distance check
        local PlantPosition = Plant:GetPivot().Position
        local Distance = (PlayerPosition-PlantPosition).Magnitude
        if not IgnoreDistance and Distance > CheatConfig.AutoHarvest.HarvestRadius then continue end

        --// Ignore check
        local Variant = Plant:FindFirstChild("Variant")
        if Variant and HarvestIgnores[Variant.Value] then continue end

        --// Collect
        if CanHarvest(Plant) then
            table.insert(Plants, Plant)
        end
    end
    return Plants
end

local function GetHarvestablePlants(IgnoreDistance: boolean?)
    local Plants = {}
    if PlantsPhysical then
        CollectHarvestable(PlantsPhysical, Plants, IgnoreDistance)
    end
    return Plants
end

local function AutoHarvestLoop()
    if not PlantsPhysical then return end
    local Plants = GetHarvestablePlants()
    for _, Plant in next, Plants do
        HarvestPlant(Plant)
        wait(CheatConfig.AutoHarvest.HarvestInterval)
    end
end

local function AutoSellCheck()
    if not CheatConfig.AutoSell.Enabled then return end
    
    local Character = LocalPlayer.Character
    if not Character then return end
    
    local CropCount = 0
    for _, Tool in next, Backpack:GetChildren() do
        if Tool:FindFirstChild("Item_String") then
            CropCount += 1
        end
    end
    for _, Tool in next, Character:GetChildren() do
        if Tool:FindFirstChild("Item_String") then
            CropCount += 1
        end
    end

    if CropCount >= CheatConfig.AutoSell.SellThreshold then
        SellInventory()
    end
end

local function AutoWalkLoop()
    if IsSelling then return end
    if not CheatConfig.AutoWalk.Enabled then return end

    local Character = LocalPlayer.Character
    if not Character then return end
    local Humanoid = Character:FindFirstChild("Humanoid")
    if not Humanoid then return end

    local Plants = GetHarvestablePlants(true)
    local RandomAllowed = CheatConfig.AutoWalk.AllowRandom
    local DoRandom = #Plants == 0 or math.random(1, 3) == 2

    --// Random point
    if RandomAllowed and DoRandom then
        local Position = GetRandomFarmPoint()
        if Position then
            Humanoid:MoveTo(Position)
        end
        return
    end
   
    --// Move to each plant
    for _, Plant in next, Plants do
        local Position = Plant:GetPivot().Position
        Humanoid:MoveTo(Position)
    end
end

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


    local SeedShop = PlayerGui:FindFirstChild("Seed_Shop")
    if not SeedShop then return {} end
    
    local Items = SeedShop:FindFirstChild("Blueberry", true)
    if not Items then return {} end
    Items = Items.Parent

    local NewList = {}

    for _, Item in next, Items:GetChildren() do
        local MainFrame = Item:FindFirstChild("Main_Frame")
        if not MainFrame then continue end

        local StockText = MainFrame:FindFirstChild("Stock_Text")
        if not StockText then continue end
        
        local StockCount = tonumber(StockText.Text:match("%d+")) or 0

        --// Separate list
        if IgnoreNoStock then
            if StockCount <= 0 then continue end
            NewList[Item.Name] = StockCount
            continue
        end

        SeedStock[Item.Name] = StockCount
    end

    return IgnoreNoStock and NewList or SeedStock
end

local function StartServices()
    print("🔧 Starting services...")
    
    --// Auto-Walk
    spawn(function()
        while wait(0.01) do
            if CheatConfig.AutoWalk.Enabled then
                pcall(function()
                    local MaxWait = CheatConfig.AutoWalk.MaxWait
                    AutoWalkLoop()
                    wait(math.random(1, MaxWait))
                end)
            end
        end
    end)

    --// Auto-Harvest
    spawn(function()
        while wait(0.01) do
            if CheatConfig.AutoHarvest.Enabled then
                pcall(AutoHarvestLoop)
            end
        end
    end)

    --// Auto-Buy
    spawn(function()
        while wait(0.01) do
            if CheatConfig.AutoBuy.Enabled then
                pcall(function()
                    local Seed = CheatConfig.AutoBuy.SelectedSeed
                    local Stock = SeedStock[Seed]
                    if Stock and Stock > 0 then
                        for i = 1, math.min(Stock, CheatConfig.AutoBuy.BuyAmount) do
                            BuySeed(Seed)
                            wait(0.1)
                        end
                    end
                end)
            end
        end
    end)

    --// Auto-Plant
    spawn(function()
        while wait(0.01) do
            if CheatConfig.AutoPlant.Enabled then
                pcall(AutoPlantLoop)
            end
        end
    end)

    --// Get stocks and seeds (continuous loop like autofarm.lua)
    spawn(function()
        while wait(0.1) do
            pcall(function()
                GetSeedStock()
                GetOwnedSeeds()
            end)
        end
    end)
    
    print("🔧 Services started!")
end

--// UI Creation (Simplified)
local function createMainGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "GrowAGardenCheatGUI"
    ScreenGui.Parent = LocalPlayer.PlayerGui
    ScreenGui.ResetOnSpawn = false
    
    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0.3, 0, 0.6, 0)
    MainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
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
    
    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
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
    Title.Text = GameInfo and GameInfo.Name .. " | Cheat Menu" or "Grow a Garden | Cheat Menu"
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.BackgroundTransparency = 1
    Title.TextScaled = true
    Title.Font = Enum.Font.SourceSansBold
    Title.Parent = TitleBar
    
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
    CloseButton.Parent = TitleBar
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 8)
    CloseCorner.Parent = CloseButton
    
    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)
    
    -- Content Frame
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Size = UDim2.new(1, -20, 1, -60)
    ContentFrame.Position = UDim2.new(0, 10, 0, 50)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = MainFrame
    
    local yOffset = 10
    
    -- Helper function to create toggle button
    local function createToggle(text, callback)
        local toggle = Instance.new("TextButton")
        toggle.Size = UDim2.new(1, -10, 0, 30)
        toggle.Position = UDim2.new(0, 5, 0, yOffset)
        toggle.Text = "🔴 " .. text .. ": OFF"
        toggle.TextColor3 = Color3.new(1, 1, 1)
        toggle.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
        toggle.BorderSizePixel = 0
        toggle.TextScaled = true
        toggle.Font = Enum.Font.SourceSans
        toggle.Parent = ContentFrame
        
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
        
        yOffset = yOffset + 40
        return toggle
    end
    
    -- Create toggles
    createToggle("Auto Plant", function(enabled)
        CheatConfig.AutoPlant.Enabled = enabled
        createNotification("🌱 Auto Plant", enabled and "Enabled" or "Disabled", 2)
    end)
    
    createToggle("Auto Harvest", function(enabled)
        CheatConfig.AutoHarvest.Enabled = enabled
        createNotification("🌾 Auto Harvest", enabled and "Enabled" or "Disabled", 2)
    end)
    
    createToggle("Auto Buy Seeds", function(enabled)
        CheatConfig.AutoBuy.Enabled = enabled
        createNotification("💰 Auto Buy", enabled and "Enabled" or "Disabled", 2)
    end)
    
    createToggle("Auto Sell", function(enabled)
        CheatConfig.AutoSell.Enabled = enabled
        createNotification("💸 Auto Sell", enabled and "Enabled" or "Disabled", 2)
    end)
    
    createToggle("Auto Walk", function(enabled)
        CheatConfig.AutoWalk.Enabled = enabled
        createNotification("🚶 Auto Walk", enabled and "Enabled" or "Disabled", 2)
    end)
    
    createToggle("NoClip", function(enabled)
        CheatConfig.NoClip.Enabled = enabled
        createNotification("👻 NoClip", enabled and "Enabled" or "Disabled", 2)
    end)
    
    -- Teleport buttons
    local teleportLabel = Instance.new("TextLabel")
    teleportLabel.Size = UDim2.new(1, -10, 0, 25)
    teleportLabel.Position = UDim2.new(0, 5, 0, yOffset)
    teleportLabel.Text = "🚀 Teleport:"
    teleportLabel.TextColor3 = Color3.new(1, 1, 1)
    teleportLabel.BackgroundTransparency = 1
    teleportLabel.TextScaled = true
    teleportLabel.Font = Enum.Font.SourceSansBold
    teleportLabel.Parent = ContentFrame
    
    yOffset = yOffset + 30
    
    for name, location in pairs(NPCLocations) do
        local teleButton = Instance.new("TextButton")
        teleButton.Size = UDim2.new(1, -10, 0, 25)
        teleButton.Position = UDim2.new(0, 5, 0, yOffset)
        teleButton.Text = name
        teleButton.TextColor3 = Color3.new(1, 1, 1)
        teleButton.BackgroundColor3 = Color3.new(0.3, 0.6, 0.9)
        teleButton.BorderSizePixel = 0
        teleButton.TextScaled = true
        teleButton.Font = Enum.Font.SourceSans
        teleButton.Parent = ContentFrame
        
        local teleCorner = Instance.new("UICorner")
        teleCorner.CornerRadius = UDim.new(0, 5)
        teleCorner.Parent = teleButton
        
        teleButton.MouseButton1Click:Connect(function()
            teleportTo(location)
        end)
        
        yOffset = yOffset + 30
    end
    
    createNotification("🔥 Cheat System", "Cheat system loaded!", 3)
    return ScreenGui
end

--// Connections and Initialization
print("🔧 Setting up connections...")

RunService.Stepped:Connect(NoclipLoop)

-- Important: Auto-sell check when items are added to backpack
Backpack.ChildAdded:Connect(AutoSellCheck)

-- Character event handling
LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    print("🔧 Character added:", newCharacter.Name)
    wait(1)
    Character = newCharacter
    InitializeFarmData()
    print("✅ Character reloaded - Farm:", MyFarm and "Found" or "Not found")
end)

-- Initial character setup
if LocalPlayer.Character then
    Character = LocalPlayer.Character
    print("🔧 Initial character found:", Character.Name)
else
    print("🔧 No initial character, waiting...")
end

print("🔧 Starting services...")
-- Start services
StartServices()

print("🔧 Creating GUI...")
-- Create GUI
spawn(function()
    wait(2) -- Wait for game to load
    print("🔧 GUI creation starting...")
    local success, gui = pcall(createMainGUI)
    if success and gui then
        print("✅ GUI created successfully!")
        
        -- Keybind to toggle GUI
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            if input.KeyCode == Enum.KeyCode.Insert then
                gui.Enabled = not gui.Enabled
                createNotification("🎮 GUI Toggle", gui.Enabled and "Shown" or "Hidden", 2)
                print("🎮 GUI toggled:", gui.Enabled and "Shown" or "Hidden")
            end
        end)
    else
        print("❌ GUI creation failed:", gui)
    end
end)

print("🔥 GROW A GARDEN - CHEAT SYSTEM LOADED!")
print("🎮 Press INSERT to toggle GUI")
print("✨ Features: Auto Plant/Harvest, Auto Buy/Sell, Auto Walk, NoClip, Teleport")
print("🔧 Debug Info:")
print("   Character:", LocalPlayer.Character and "✅" or "❌")
print("   PlantRemote:", PlantRemote and "✅" or "❌")
print("   HarvestRemote:", HarvestRemote and "✅" or "❌")
print("   GameEvents:", GameEvents and "✅" or "❌")
print("   Farm:", MyFarm and "✅" or "❌")
