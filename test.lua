--[[
    @author depso (depthso)
    @description Grow a Garden auto-farm script with Obsidian UI
    https://www.roblox.com/games/126884695634066
]]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Leaderstats = LocalPlayer.leaderstats
local Backpack = LocalPlayer.Backpack
local PlayerGui = LocalPlayer.PlayerGui

local ShecklesCount = Leaderstats.Sheckles
local GameInfo = MarketplaceService:GetProductInfo(game.PlaceId)

--// Obsidian UI Library
local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua'))()

--// Folders
local GameEvents = ReplicatedStorage.GameEvents
local Farms = workspace.Farm

local Accent = {
    DarkGreen = Color3.fromRGB(45, 95, 25),
    Green = Color3.fromRGB(69, 142, 40),
    Brown = Color3.fromRGB(26, 20, 8),
}

--// Dicts
local SeedStock = {}
local OwnedSeeds = {}
local HarvestIgnores = {
	Normal = false,
	Gold = false,
	Rainbow = false
}

--// Globals
local SelectedSeed, AutoPlantRandom, AutoPlant, AutoHarvest, AutoBuy, SellThreshold, NoClip, AutoWalkAllowRandom
local AutoSell, AutoWalk, AutoWalkMaxWait, AutoWalkStatus
local SelectedSeedStock, OnlyShowStock

--// Interface functions
local function Plant(Position: Vector3, Seed: string)
	GameEvents.Plant_RE:FireServer(Position, Seed)
	wait(.3)
end

local function GetFarms()
	return Farms:GetChildren()
end

local function GetFarmOwner(Farm: Folder): string
	local Important = Farm.Important
	local Data = Important.Data
	local Owner = Data.Owner

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

local IsSelling = false
local function SellInventory()
	local Character = LocalPlayer.Character
	local Previous = Character:GetPivot()
	local PreviousSheckles = ShecklesCount.Value

	--// Prevent conflict
	if IsSelling then return end
	IsSelling = true

	Character:PivotTo(CFrame.new(62, 4, -26))
	while wait() do
		if ShecklesCount.Value ~= PreviousSheckles then break end
		GameEvents.Sell_Inventory:FireServer()
	end
	Character:PivotTo(Previous)

	wait(0.2)
	IsSelling = false
end

local function BuySeed(Seed: string)
	GameEvents.BuySeedStock:FireServer(Seed)
end

local function BuyAllSelectedSeeds()
    local Seed = SelectedSeedStock.Value
    local Stock = SeedStock[Seed]

	if not Stock or Stock <= 0 then return end

    for i = 1, Stock do
        BuySeed(Seed)
    end
end

local function GetSeedInfo(Seed: Tool): number?
	local PlantName = Seed:FindFirstChild("Plant_Name")
	local Count = Seed:FindFirstChild("Numbers")
	if not PlantName then return end

	return PlantName.Value, Count.Value
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

local function CollectCropsFromParent(Parent, Crops: table)
	for _, Tool in next, Parent:GetChildren() do
		local Name = Tool:FindFirstChild("Item_String")
		if not Name then continue end

		table.insert(Crops, Tool)
	end
end

local function GetOwnedSeeds(): table
	local Character = LocalPlayer.Character
	
	CollectSeedsFromParent(Backpack, OwnedSeeds)
	CollectSeedsFromParent(Character, OwnedSeeds)

	return OwnedSeeds
end

local function GetInvCrops(): table
	local Character = LocalPlayer.Character
	
	local Crops = {}
	CollectCropsFromParent(Backpack, Crops)
	CollectCropsFromParent(Character, Crops)

	return Crops
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
    local Humanoid = Character.Humanoid

    if Tool.Parent ~= Backpack then return end
    Humanoid:EquipTool(Tool)
end

--// Auto farm functions
local MyFarm = GetFarm(LocalPlayer.Name)
local MyImportant = MyFarm.Important
local PlantLocations = MyImportant.Plant_Locations
local PlantsPhysical = MyImportant.Plants_Physical

local Dirt = PlantLocations:FindFirstChildOfClass("Part")
local X1, Z1, X2, Z2 = GetArea(Dirt)

local function GetRandomFarmPoint(): Vector3
    local FarmLands = PlantLocations:GetChildren()
    local FarmLand = FarmLands[math.random(1, #FarmLands)]

    local X1, Z1, X2, Z2 = GetArea(FarmLand)
    local X = math.random(X1, X2)
    local Z = math.random(Z1, Z2)

    return Vector3.new(X, 4, Z)
end

local function AutoPlantLoop()
	local Seed = SelectedSeed.Value

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
	if AutoPlantRandom.Value then
		for i = 1, Count do
			local Point = GetRandomFarmPoint()
			Plant(Point, Seed)
		end
	end
	
	--// Plant on the farmland area
	for X = X1, X2, Step do
		for Z = Z1, Z2, Step do
			if Planted > Count then break end
			local Point = Vector3.new(X, 0.13, Z)

			Planted += 1
			Plant(Point, Seed)
		end
	end
end

local function HarvestPlant(Plant: Model)
	local Prompt = Plant:FindFirstChild("ProximityPrompt", true)

	--// Check if it can be harvested
	if not Prompt then return end
	fireproximityprompt(Prompt)
end

local function GetSeedStock(IgnoreNoStock: boolean?): table
	local SeedShop = PlayerGui.Seed_Shop
	local Items = SeedShop:FindFirstChild("Blueberry", true).Parent

	local NewList = {}

	for _, Item in next, Items:GetChildren() do
		local MainFrame = Item:FindFirstChild("Main_Frame")
		if not MainFrame then continue end

		local StockText = MainFrame.Stock_Text.Text
		local StockCount = tonumber(StockText:match("%d+"))

		--// Seperate list
		if IgnoreNoStock then
			if StockCount <= 0 then continue end
			NewList[Item.Name] = StockCount
			continue
		end

		SeedStock[Item.Name] = StockCount
	end

	return IgnoreNoStock and NewList or SeedStock
end

local function CanHarvest(Plant): boolean?
    local Prompt = Plant:FindFirstChild("ProximityPrompt", true)
	if not Prompt then return end
    if not Prompt.Enabled then return end

    return true
end

local function CollectHarvestable(Parent, Plants, IgnoreDistance: boolean?)
	local Character = LocalPlayer.Character
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
		if not IgnoreDistance and Distance > 15 then continue end

		--// Ignore check
		local Variant = Plant:FindFirstChild("Variant")
		if HarvestIgnores[Variant.Value] then continue end

        --// Collect
        if CanHarvest(Plant) then
            table.insert(Plants, Plant)
        end
	end
    return Plants
end

local function GetHarvestablePlants(IgnoreDistance: boolean?)
    local Plants = {}
    CollectHarvestable(PlantsPhysical, Plants, IgnoreDistance)
    return Plants
end

local function HarvestPlants(Parent: Model)
	local Plants = GetHarvestablePlants()
    for _, Plant in next, Plants do
        HarvestPlant(Plant)
    end
end

local function AutoSellCheck()
    local CropCount = #GetInvCrops()

    if not AutoSell.Value then return end
    if CropCount < SellThreshold.Value then return end

    SellInventory()
end

local function AutoWalkLoop()
	if IsSelling then return end

    local Character = LocalPlayer.Character
    local Humanoid = Character.Humanoid

    local Plants = GetHarvestablePlants(true)
	local RandomAllowed = AutoWalkAllowRandom.Value
	local DoRandom = #Plants == 0 or math.random(1, 3) == 2

    --// Random point
    if RandomAllowed and DoRandom then
        local Position = GetRandomFarmPoint()
        Humanoid:MoveTo(Position)
		AutoWalkStatus:SetText("Random point")
        return
    end
   
    --// Move to each plant
    for _, Plant in next, Plants do
        local Position = Plant:GetPivot().Position
        Humanoid:MoveTo(Position)
		AutoWalkStatus:SetText(Plant.Name)
    end
end

local function NoclipLoop()
    local Character = LocalPlayer.Character
    if not NoClip.Value then return end
    if not Character then return end

    for _, Part in Character:GetDescendants() do
        if Part:IsA("BasePart") then
            Part.CanCollide = false
        end
    end
end

local function MakeLoop(Toggle, Func)
	coroutine.wrap(function()
		while wait(.01) do
			if not Toggle.Value then continue end
			Func()
		end
	end)()
end

local function StartServices()
	--// Auto-Walk
	MakeLoop(AutoWalk, function()
		local MaxWait = AutoWalkMaxWait.Value
		AutoWalkLoop()
		wait(math.random(1, MaxWait))
	end)

	--// Auto-Harvest
	MakeLoop(AutoHarvest, function()
		HarvestPlants(PlantsPhysical)
	end)

	--// Auto-Buy
	MakeLoop(AutoBuy, BuyAllSelectedSeeds)

	--// Auto-Plant
	MakeLoop(AutoPlant, AutoPlantLoop)

	--// Get stocks
	while wait(.1) do
		GetSeedStock()
		GetOwnedSeeds()
	end
end

--// Custom theme setup for garden look
Library.Scheme.BackgroundColor = Accent.Brown
Library.Scheme.MainColor = Accent.DarkGreen
Library.Scheme.AccentColor = Accent.Green

--// Create Window using Obsidian
local Window = Library:CreateWindow({
    Title = `{GameInfo.Name} | Depso`,
    Footer = "Auto-Farm Script with Obsidian UI",
    Size = UDim2.fromOffset(480, 600),
    Icon = "leaf",
    AutoShow = true,
    Center = true,
    Resizable = true,
})

--// Create main tab
local MainTab = Window:AddTab({
    Name = "Auto Farm",
    Icon = "tractor",
    Description = "Main farming automation features"
})

--// Auto-Plant Section
local PlantGroupbox = MainTab:AddLeftGroupbox("Auto-Plant 🥕", "sprout")

SelectedSeed = PlantGroupbox:AddDropdown("SelectedSeed", {
    Text = "Select Seed",
    Values = {},
    Multi = false,
    Default = "",
    Callback = function(Value)
        -- Callback for when seed is selected
    end
})

-- Function to update seed dropdown
local function UpdateSeedDropdown()
    local seeds = {}
    for seedName, _ in pairs(GetSeedStock()) do
        table.insert(seeds, seedName)
    end
    SelectedSeed:SetValues(seeds)
end

AutoPlant = PlantGroupbox:AddToggle("AutoPlant", {
    Text = "Auto Plant",
    Default = false,
    Callback = function(Value)
        -- Auto plant toggled
    end
})

AutoPlantRandom = PlantGroupbox:AddToggle("AutoPlantRandom", {
    Text = "Plant at random points",
    Default = false,
    Callback = function(Value)
        -- Random planting toggled
    end
})

PlantGroupbox:AddButton({
    Text = "Plant All",
    Func = AutoPlantLoop,
    Tooltip = "Plant all seeds of selected type"
})

--// Auto-Harvest Section
local HarvestGroupbox = MainTab:AddRightGroupbox("Auto-Harvest 🚜", "wheat")

AutoHarvest = HarvestGroupbox:AddToggle("AutoHarvest", {
    Text = "Auto Harvest",
    Default = false,
    Callback = function(Value)
        -- Auto harvest toggled
    end
})

HarvestGroupbox:AddDivider()
HarvestGroupbox:AddLabel("Ignore Types:")

for ignoreType, value in pairs(HarvestIgnores) do
    local toggle = HarvestGroupbox:AddToggle("Ignore" .. ignoreType, {
        Text = "Ignore " .. ignoreType,
        Default = value,
        Callback = function(Value)
            HarvestIgnores[ignoreType] = Value
        end
    })
end

--// Auto-Buy Section  
local BuyGroupbox = MainTab:AddLeftGroupbox("Auto-Buy 🥕", "shopping-cart")

SelectedSeedStock = BuyGroupbox:AddDropdown("SelectedSeedStock", {
    Text = "Select Seed to Buy",
    Values = {},
    Multi = false,
    Default = "",
    Callback = function(Value)
        -- Callback for when seed stock is selected
    end
})

-- Function to update stock dropdown
local function UpdateStockDropdown()
    local onlyStock = OnlyShowStock and OnlyShowStock.Value or false
    local stockList = GetSeedStock(onlyStock)
    local values = {}
    for seedName, _ in pairs(stockList) do
        table.insert(values, seedName)
    end
    SelectedSeedStock:SetValues(values)
end

AutoBuy = BuyGroupbox:AddToggle("AutoBuy", {
    Text = "Auto Buy",
    Default = false,
    Callback = function(Value)
        -- Auto buy toggled
    end
})

OnlyShowStock = BuyGroupbox:AddToggle("OnlyShowStock", {
    Text = "Only show in stock",
    Default = false,
    Callback = function(Value)
        UpdateStockDropdown()
    end
})

BuyGroupbox:AddButton({
    Text = "Buy All",
    Func = BuyAllSelectedSeeds,
    Tooltip = "Buy all available stock of selected seed"
})

--// Auto-Sell Section
local SellGroupbox = MainTab:AddRightGroupbox("Auto-Sell 💰", "coins")

SellGroupbox:AddButton({
    Text = "Sell Inventory",
    Func = SellInventory,
    Tooltip = "Manually sell all crops in inventory"
})

AutoSell = SellGroupbox:AddToggle("AutoSell", {
    Text = "Auto Sell",
    Default = false,
    Callback = function(Value)
        -- Auto sell toggled
    end
})

SellThreshold = SellGroupbox:AddSlider("SellThreshold", {
    Text = "Crops threshold",
    Default = 15,
    Min = 1,
    Max = 199,
    Rounding = 0,
    Callback = function(Value)
        -- Threshold changed
    end
})

--// Auto-Walk Section
local WalkTab = Window:AddTab({
    Name = "Auto Walk",
    Icon = "footprints",
    Description = "Automatic movement and navigation"
})

local WalkGroupbox = WalkTab:AddLeftGroupbox("Auto-Walk 🚶", "navigation")

AutoWalkStatus = WalkGroupbox:AddLabel("Status: None")

AutoWalk = WalkGroupbox:AddToggle("AutoWalk", {
    Text = "Auto Walk",
    Default = false,
    Callback = function(Value)
        -- Auto walk toggled
    end
})

AutoWalkAllowRandom = WalkGroupbox:AddToggle("AutoWalkAllowRandom", {
    Text = "Allow random points",
    Default = true,
    Callback = function(Value)
        -- Random walk toggled
    end
})

NoClip = WalkGroupbox:AddToggle("NoClip", {
    Text = "No Clip",
    Default = false,
    Callback = function(Value)
        -- NoClip toggled
    end
})

AutoWalkMaxWait = WalkGroupbox:AddSlider("AutoWalkMaxWait", {
    Text = "Max delay (seconds)",
    Default = 10,
    Min = 1,
    Max = 120,
    Rounding = 0,
    Callback = function(Value)
        -- Max wait time changed
    end
})

--// Connections
RunService.Stepped:Connect(NoclipLoop)
Backpack.ChildAdded:Connect(AutoSellCheck)

--// Start update loops
coroutine.wrap(function()
    while wait(1) do
        UpdateSeedDropdown()
        UpdateStockDropdown()
    end
end)()

--// Services
StartServices()

--// Show notification
Library:Notify({
    Title = "Auto Farm Loaded",
    Description = "Garden automation script is ready!",
    Time = 3
})
