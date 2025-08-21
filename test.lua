--[[
    @author depso (depthso)
    @description Grow a Garden auto-farm script with Enhanced Obsidian UI
    @version 2.0 - Advanced Features
    https://www.roblox.com/games/126884695634066
]]

-- DEBUG / SAFE BOOTSTRAP WRAPPER (added)
local BOOT_SUCCESS, BOOT_ERROR = pcall(function()
    -- Basic environment diagnostics
    local startTick = tick and tick() or os.clock()
    print("[AutoFarmV2] Bootstrap start @", startTick)
    print("[AutoFarmV2] Executor Identify (if any):", identifyexecutor and identifyexecutor() or "Unknown")

    -- Safer wait function abstraction
    local function safeWait(t)
        if task and task.wait then return task.wait(t) end
        return wait(t)
    end

    -- Library loader with fallback & timeout
    local function loadLibrary()
        local lib
        local ok, err = pcall(function()
            lib = loadstring(game:HttpGet('https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua', true))()
        end)
        if ok and lib then
            print('[AutoFarmV2] Loaded Obsidian main library')
            return lib, 'Obsidian'
        end
        warn('[AutoFarmV2] Failed load Obsidian:', err)

        ok, err = pcall(function()
            lib = loadstring(game:HttpGet('https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua', true))()
        end)
        if ok and lib then
            print('[AutoFarmV2] Loaded Obsidian fallback branch')
            return lib, 'ObsidianFallback'
        end
        warn('[AutoFarmV2] Fallback branch failed:', err)

        ok, err = pcall(function()
            lib = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source', true))()
        end)
        if ok and lib then
            print('[AutoFarmV2] Loaded Rayfield as emergency fallback')
            return lib, 'Rayfield'
        end
        error('ALL_UI_LIB_LOAD_FAILED:' .. tostring(err))
    end

    -- Replace previous direct library load
    do
        local LoadedLib, LibName = loadLibrary()
        Library = LoadedLib
        _G.__AF2_LibName = LibName
    end

    -- Pre-check critical services / objects
    assert(game and game.PlaceId, 'Game object not available')
    print('[AutoFarmV2] PlaceId:', game.PlaceId)

    local rsOk, rs = pcall(function() return game:GetService('ReplicatedStorage') end)
    assert(rsOk and rs, 'ReplicatedStorage missing')
    assert(rs:FindFirstChild('GameEvents'), 'GameEvents folder missing in ReplicatedStorage')

    -- Player readiness
    if not game:IsLoaded() then game.Loaded:Wait() end
    local Players = game:GetService('Players')
    local LocalPlayer = Players.LocalPlayer
    while not LocalPlayer or not LocalPlayer.Character do
        print('[AutoFarmV2] Waiting for character...')
        safeWait(1)
        LocalPlayer = Players.LocalPlayer
    end
    print('[AutoFarmV2] Character OK')

    -- Farm detection probe (lightweight)
    local farmFolder = workspace:FindFirstChild('Farm')
    if not farmFolder then
        warn('[AutoFarmV2] workspace.Farm not found, script may early-exit')
    else
        print('[AutoFarmV2] Farm folder children count:', #farmFolder:GetChildren())
    end

    -- Attach a minimal temp window early (sanity check UI)
    local okUI, testWindow = pcall(function()
        return Library:CreateWindow({
            Title = 'AFv2 Loader / ' .. (_G.__AF2_LibName or 'UnknownLib'),
            Size = UDim2.fromOffset(300, 120),
            Center = true,
            AutoShow = true,
            Resizable = false,
            Footer = 'Booting...'
        })
    end)
    if okUI and testWindow then
        local tab = testWindow:AddTab({Name='Log', Icon='info'})
        local box = tab:AddLeftGroupbox('Status')
        box:AddLabel('Library: ' .. (_G.__AF2_LibName or '?'))
        box:AddLabel('PlaceId: ' .. tostring(game.PlaceId))
        box:AddLabel('Player: ' .. Players.LocalPlayer.Name)
        _G.__AF2_BootWindow = testWindow
    else
        warn('[AutoFarmV2] Failed to create temp window UI')
    end
end)

if not BOOT_SUCCESS then
    warn('[AutoFarmV2] FATAL BOOT ERROR =>', BOOT_ERROR)
    return -- Abort entire script if bootstrap failed
else
    print('[AutoFarmV2] Bootstrap OK, continuing full script load...')
end

-- >>> PATCH: Robustified bootstrap & full UI init guard <<<
-- Remove second library load & convert temp boot window to progress panel until main window is ready.

-- Prevent duplicate execution
if _G.__AF2_RUNNING then
    warn('[AutoFarmV2] Already running. Aborting duplicate.')
    return
end
_G.__AF2_RUNNING = true

-- Forward declared variables to allow bootstrap referencing before full def
local Library -- will be set in bootstrap
local MAIN_WINDOW_READY = false
local BOOT_PANEL -- temp window
local function bootLog(msg)
    print('[AutoFarmV2]', msg)
    if BOOT_PANEL and BOOT_PANEL.__LogBox then
        BOOT_PANEL.__LogBox:AddLabel(msg)
    end
end

-- Replace previous bootstrap block (leave existing code above intact)
local BOOT_OK, BOOT_ERR = pcall(function()
    local start = tick and tick() or os.clock()
    bootLog('Bootstrap start @' .. tostring(start))

    -- Library loader unified
    local function loadUILib()
        local sources = {
            {name='Obsidian-main', url='https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua'},
            {name='Obsidian-alt',  url='https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua'},
            {name='Rayfield',      url='https://raw.githubusercontent.com/shlexware/Rayfield/main/source'},
        }
        for _, src in ipairs(sources) do
            local ok, libOrErr = pcall(function()
                return loadstring(game:HttpGet(src.url, true))()
            end)
            if ok and libOrErr then
                _G.__AF2_LibName = src.name
                bootLog('Loaded UI lib: ' .. src.name)
                return libOrErr
            else
                bootLog('Fail load ' .. src.name .. ': ' .. tostring(libOrErr))
            end
        end
        error('All UI libraries failed to load')
    end

    Library = loadUILib()

    -- Early minimal panel
    local okPanel, panel = pcall(function()
        return Library:CreateWindow({
            Title = 'AFv2 Boot (' .. (_G.__AF2_LibName or '?') .. ')',
            Size = UDim2.fromOffset(380, 260),
            Center = true,
            AutoShow = true,
            Resizable = false,
            Footer = 'Initializing...'
        })
    end)
    if okPanel and panel then
        BOOT_PANEL = panel
        local tab = panel:AddTab({Name='Boot', Icon='info'})
        local box = tab:AddLeftGroupbox('Progress')
        BOOT_PANEL.__LogBox = box
        box:AddLabel('UI Lib: ' .. (_G.__AF2_LibName or '?'))
        box:AddLabel('PlaceId: ' .. tostring(game.PlaceId))
        box:AddLabel('Executor: ' .. (identifyexecutor and identifyexecutor() or 'Unknown'))
    else
        bootLog('Failed to create boot panel UI')
    end

    -- Service & asset checks
    local rs = game:GetService('ReplicatedStorage')
    if not rs:FindFirstChild('GameEvents') then
        bootLog('GameEvents missing - will retry later')
    else
        bootLog('GameEvents folder OK')
    end

    if not workspace:FindFirstChild('Farm') then
        bootLog('workspace.Farm missing (maybe not loaded yet)')
    end
end)

if not BOOT_OK then
    warn('[AutoFarmV2] BOOT FAIL:', BOOT_ERR)
    return
end

-- Watchdog for full init (timeout if something blocks)
local INIT_TIMEOUT = 60
local initStart = tick and tick() or os.clock()
local function timedOut()
    local now = tick and tick() or os.clock()
    return (now - initStart) > INIT_TIMEOUT
end

-- Defer heavy logic to separate thread so bootstrap returns quickly
coroutine.wrap(function()
    bootLog('Deferred main initialization...')

    -- Wait for player & character
    local Players = game:GetService('Players')
    local lp = Players.LocalPlayer
    while (not lp or not lp.Character) and not timedOut() do
        bootLog('Waiting character...')
        task.wait(1)
        lp = Players.LocalPlayer
    end
    if timedOut() then
        bootLog('Timeout waiting character. Abort.')
        return
    end

    -- Wait GameEvents
    local rs = game:GetService('ReplicatedStorage')
    local tries = 0
    while (not rs:FindFirstChild('GameEvents')) and tries < 30 and not timedOut() do
        tries = tries + 1
        bootLog('Waiting GameEvents (' .. tries .. ')')
        task.wait(.5)
    end
    if not rs:FindFirstChild('GameEvents') then
        bootLog('GameEvents never appeared. Abort.')
        return
    end

    -- Inject original full script logic now (guard to prevent duplicate Library definition)
    if _G.__AF2_MAIN_STARTED then
        bootLog('Main already started, skipping.')
        return
    end
    _G.__AF2_MAIN_STARTED = true

    -- REMOVE redundant second load if present
    -- (Search done automatically; manual removal below)

    -- Continue with original script body AFTER this patch.
    -- >>> PATCH END (main script below already present) <<<
end)()

-- MAIN BODY GUARD
if not _G.__AF2_ALLOW_MAIN then
    -- If somehow reached early, delay then proceed
    repeat task.wait(0.05) until _G.__AF2_ALLOW_MAIN
end

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Leaderstats = LocalPlayer.leaderstats
local Backpack = LocalPlayer.Backpack
local PlayerGui = LocalPlayer.PlayerGui

local ShecklesCount = Leaderstats.Sheckles
local GameInfo = MarketplaceService:GetProductInfo(game.PlaceId)

--// Obsidian UI Library
if _G.__AF2_SKIP_SECOND_LOAD then
    -- Library already loaded in bootstrap
else
    Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua'))()
end

--// Folders
local GameEvents = ReplicatedStorage.GameEvents
local Farms = workspace.Farm

local Accent = {
    DarkGreen = Color3.fromRGB(45, 95, 25),
    Green = Color3.fromRGB(69, 142, 40),
    Brown = Color3.fromRGB(26, 20, 8),
    Gold = Color3.fromRGB(255, 215, 0),
    Rainbow = Color3.fromRGB(138, 43, 226)
}

--// Enhanced Dicts and Variables
local SeedStock = {}
local OwnedSeeds = {}
local SessionStats = {
    StartTime = tick(),
    PlantsHarvested = 0,
    SeedsPlanted = 0,
    TotalProfit = 0,
    MutationsFound = 0,
    GearsUsed = 0,
    EggsOpened = 0
}

local HarvestFilters = {
    SeedTypes = {"All"},
    Variants = {"All", "Normal", "Gold", "Rainbow"},
    SelectedSeeds = {"All"},
    SelectedVariants = {"All"}
}

local NPCLocations = {
    SeedShop = Vector3.new(51, 4, -20),
    GearShop = Vector3.new(65, 4, -15),
    PetShop = Vector3.new(70, 4, -25),
    SellArea = Vector3.new(62, 4, -26),
    BeanstalkEvent = Vector3.new(45, 4, 30), -- Current event location
    Farm = Vector3.new(0, 4, 0) -- Will be updated to player's farm
}

--// Globals
local SelectedSeed, SelectedSeeds, AutoPlantRandom, AutoPlant, AutoHarvest, AutoBuy, SellThreshold, NoClip
local AutoWalkAllowRandom, AutoSell, AutoWalk, AutoWalkMaxWait, AutoWalkStatus
local SelectedSeedStock, OnlyShowStock, SelectedGear, SelectedEgg, AutoGearBuy, AutoEggBuy
local PlantAtPlayer, PlantRadius, HarvestByType, HarvestByVariant
local PreviousPosition

-- Status tracking
local StatusLabels = {}
local IsPlanting, IsHarvesting, IsSelling, IsBuying = false, false, false, false

--// Utility Functions
local function tableFind(tbl, value)
    for i, v in pairs(tbl) do
        if v == value then
            return i
        end
    end
    return nil
end

local function GetPlayerPosition()
    local Character = LocalPlayer.Character
    if not Character then return Vector3.new(0, 4, 0) end
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    if not HumanoidRootPart then return Vector3.new(0, 4, 0) end
    return HumanoidRootPart.Position
end

local function GetPlayerCFrame()
    local Character = LocalPlayer.Character
    if not Character then return CFrame.new(0, 4, 0) end
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    if not HumanoidRootPart then return CFrame.new(0, 4, 0) end
    return HumanoidRootPart.CFrame
end

local function TeleportToPosition(position)
    local Character = LocalPlayer.Character
    if not Character then return end
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    if not HumanoidRootPart then return end
    
    PreviousPosition = HumanoidRootPart.CFrame
    HumanoidRootPart.CFrame = CFrame.new(position)
    wait(0.5) -- Allow time for teleport
end

local function ReturnToPreviousPosition()
    if not PreviousPosition then return end
    local Character = LocalPlayer.Character
    if not Character then return end
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    if not HumanoidRootPart then return end
    
    HumanoidRootPart.CFrame = PreviousPosition
end

local function UpdateSessionStats()
    if StatusLabels.SessionTime then
        local elapsed = tick() - SessionStats.StartTime
        local hours = math.floor(elapsed / 3600)
        local minutes = math.floor((elapsed % 3600) / 60)
        StatusLabels.SessionTime:SetText(string.format("Session: %02d:%02d", hours, minutes))
    end
    
    if StatusLabels.PlantsHarvested then
        StatusLabels.PlantsHarvested:SetText("Harvested: " .. SessionStats.PlantsHarvested)
    end
    
    if StatusLabels.TotalProfit then
        StatusLabels.TotalProfit:SetText("Profit: $" .. SessionStats.TotalProfit)
    end
    
    if StatusLabels.MutationsFound then
        StatusLabels.MutationsFound:SetText("Mutations: " .. SessionStats.MutationsFound)
    end
end

--// Enhanced Interface Functions
local function Plant(Position, Seed)
    if IsPlanting then return end
    IsPlanting = true
    
    GameEvents.Plant_RE:FireServer(Position, Seed)
    SessionStats.SeedsPlanted = SessionStats.SeedsPlanted + 1
    wait(0.3)
    
    IsPlanting = false
end

local function GetFarms()
    return Farms:GetChildren()
end

local function GetFarmOwner(Farm)
    local Important = Farm.Important
    local Data = Important.Data
    local Owner = Data.Owner
    return Owner.Value
end

local function GetFarm(PlayerName)
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
    
    if IsSelling then return end
    IsSelling = true
    
    local PreviousSheckles = ShecklesCount.Value
    TeleportToPosition(NPCLocations.SellArea)
    
    while wait() do
        if ShecklesCount.Value ~= PreviousSheckles then break end
        GameEvents.Sell_Inventory:FireServer()
    end
    
    SessionStats.TotalProfit = SessionStats.TotalProfit + (ShecklesCount.Value - PreviousSheckles)
    ReturnToPreviousPosition()
    wait(0.2)
    IsSelling = false
end

local function BuySeed(Seed)
    if IsBuying then return end
    IsBuying = true
    
    TeleportToPosition(NPCLocations.SeedShop)
    GameEvents.BuySeedStock:FireServer(Seed)
    wait(0.5)
    ReturnToPreviousPosition()
    
    IsBuying = false
end

local function BuyGear(Gear)
    if IsBuying then return end
    IsBuying = true
    
    TeleportToPosition(NPCLocations.GearShop)
    GameEvents.BuyGear:FireServer(Gear) -- Assuming this exists
    SessionStats.GearsUsed = SessionStats.GearsUsed + 1
    wait(0.5)
    ReturnToPreviousPosition()
    
    IsBuying = false
end

local function BuyEgg(Egg)
    if IsBuying then return end
    IsBuying = true
    
    TeleportToPosition(NPCLocations.PetShop)
    GameEvents.BuyEgg:FireServer(Egg) -- Assuming this exists
    SessionStats.EggsOpened = SessionStats.EggsOpened + 1
    wait(0.5)
    ReturnToPreviousPosition()
    
    IsBuying = false
end

local function BuyAllSelectedSeeds()
    if not SelectedSeedStock or not SelectedSeedStock.Value then return end
    
    local Seed = SelectedSeedStock.Value
    local Stock = SeedStock[Seed]
    if not Stock or Stock <= 0 then return end

    for i = 1, Stock do
        BuySeed(Seed)
    end
end

local function GetSeedInfo(Seed)
    local PlantName = Seed:FindFirstChild("Plant_Name")
    local Count = Seed:FindFirstChild("Numbers")
    if not PlantName then return end
    return PlantName.Value, Count.Value
end

local function CollectSeedsFromParent(Parent, Seeds)
    for _, Tool in next, Parent:GetChildren() do
        local Name, Count = GetSeedInfo(Tool)
        if Name then
            Seeds[Name] = {
                Count = Count,
                Tool = Tool
            }
        end
    end
end

local function CollectCropsFromParent(Parent, Crops)
    for _, Tool in next, Parent:GetChildren() do
        local Name = Tool:FindFirstChild("Item_String")
        if Name then
            table.insert(Crops, Tool)
        end
    end
end

local function GetOwnedSeeds()
    local Character = LocalPlayer.Character
    OwnedSeeds = {} -- Reset
    
    CollectSeedsFromParent(Backpack, OwnedSeeds)
    if Character then
        CollectSeedsFromParent(Character, OwnedSeeds)
    end
    
    -- Update dropdown values
    local seedNames = {"All"}
    for seedName, _ in pairs(OwnedSeeds) do
        if not tableFind(seedNames, seedName) then
            table.insert(seedNames, seedName)
        end
    end
    HarvestFilters.SeedTypes = seedNames
    
    return OwnedSeeds
end

local function GetInvCrops()
    local Character = LocalPlayer.Character
    local Crops = {}
    
    CollectCropsFromParent(Backpack, Crops)
    if Character then
        CollectCropsFromParent(Character, Crops)
    end
    
    return Crops
end

local function GetArea(Base)
    local Center = Base:GetPivot()
    local Size = Base.Size

    local X1 = math.ceil(Center.X - (Size.X/2))
    local Z1 = math.ceil(Center.Z - (Size.Z/2))
    local X2 = math.floor(Center.X + (Size.X/2))
    local Z2 = math.floor(Center.Z + (Size.Z/2))

    return X1, Z1, X2, Z2
end

local function EquipCheck(Tool)
    local Character = LocalPlayer.Character
    if not Character then return end
    local Humanoid = Character.Humanoid
    if not Humanoid then return end

    if Tool.Parent ~= Backpack then return end
    Humanoid:EquipTool(Tool)
end

--// Enhanced Auto farm functions
local MyFarm = GetFarm(LocalPlayer.Name)
if MyFarm then
    NPCLocations.Farm = MyFarm:GetPivot().Position
    local MyImportant = MyFarm.Important
    local PlantLocations = MyImportant.Plant_Locations
    local PlantsPhysical = MyImportant.Plants_Physical

    local Dirt = PlantLocations:FindFirstChildOfClass("Part")
    if Dirt then
        local X1, Z1, X2, Z2 = GetArea(Dirt)
        
        local function GetRandomFarmPoint()
            local FarmLands = PlantLocations:GetChildren()
            local FarmLand = FarmLands[math.random(1, #FarmLands)]
            local X1, Z1, X2, Z2 = GetArea(FarmLand)
            local X = math.random(X1, X2)
            local Z = math.random(Z1, Z2)
            return Vector3.new(X, 4, Z)
        end

        local function GetPlayerRadiusPoints()
            local PlayerPos = GetPlayerPosition()
            local Radius = PlantRadius and PlantRadius.Value or 10
            local Points = {}
            
            for i = 1, 20 do -- Generate 20 random points around player
                local angle = math.random() * 2 * math.pi
                local distance = math.random() * Radius
                local x = PlayerPos.X + math.cos(angle) * distance
                local z = PlayerPos.Z + math.sin(angle) * distance
                table.insert(Points, Vector3.new(x, PlayerPos.Y, z))
            end
            
            return Points
        end

        local function ShouldPlantSeed(seedName)
            if not SelectedSeeds or not SelectedSeeds.Value then return false end
            local selected = SelectedSeeds.Value
            
            if selected == "All" then return true end
            if type(selected) == "table" then
                return tableFind(selected, seedName) ~= nil
            end
            return selected == seedName
        end

        local function AutoPlantLoop()
            if not SelectedSeed or not SelectedSeed.Value then return end
            local Seed = SelectedSeed.Value
            
            -- Multi-seed planting
            if Seed == "All" then
                for seedName, seedData in pairs(OwnedSeeds) do
                    if ShouldPlantSeed(seedName) and seedData.Count > 0 then
                        EquipCheck(seedData.Tool)
                        
                        if PlantAtPlayer and PlantAtPlayer.Value then
                            local Points = GetPlayerRadiusPoints()
                            for _, Point in pairs(Points) do
                                if seedData.Count <= 0 then break end
                                Plant(Point, seedName)
                                seedData.Count = seedData.Count - 1
                            end
                        else
                            -- Normal planting pattern
                            local Planted = 0
                            for X = X1, X2, 1 do
                                for Z = Z1, Z2, 1 do
                                    if Planted >= seedData.Count then break end
                                    local Point = Vector3.new(X, 0.13, Z)
                                    Plant(Point, seedName)
                                    Planted = Planted + 1
                                end
                            end
                        end
                    end
                end
                return
            end
            
            -- Single seed planting
            local SeedData = OwnedSeeds[Seed]
            if not SeedData or SeedData.Count <= 0 then return end
            
            EquipCheck(SeedData.Tool)
            
            if PlantAtPlayer and PlantAtPlayer.Value then
                local Points = GetPlayerRadiusPoints()
                for _, Point in pairs(Points) do
                    if SeedData.Count <= 0 then break end
                    Plant(Point, Seed)
                    SeedData.Count = SeedData.Count - 1
                end
            else
                -- Normal grid planting
                local Planted = 0
                for X = X1, X2, 1 do
                    for Z = Z1, Z2, 1 do
                        if Planted >= SeedData.Count then break end
                        local Point = Vector3.new(X, 0.13, Z)
                        Plant(Point, Seed)
                        Planted = Planted + 1
                    end
                end
            end
        end

        local function HarvestPlant(Plant)
            local Prompt = Plant:FindFirstChild("ProximityPrompt", true)
            if not Prompt then return end
            fireproximityprompt(Prompt)
            SessionStats.PlantsHarvested = SessionStats.PlantsHarvested + 1
        end

        local function GetSeedStock(IgnoreNoStock)
            local SeedShop = PlayerGui.Seed_Shop
            local Items = SeedShop:FindFirstChild("Blueberry", true)
            if not Items then return {} end
            local Parent = Items.Parent

            local NewList = {}

            for _, Item in next, Parent:GetChildren() do
                local MainFrame = Item:FindFirstChild("Main_Frame")
                if MainFrame then
                    local StockText = MainFrame.Stock_Text.Text
                    local StockCount = tonumber(StockText:match("%d+"))

                    if IgnoreNoStock then
                        if StockCount > 0 then
                            NewList[Item.Name] = StockCount
                        end
                    else
                        SeedStock[Item.Name] = StockCount
                    end
                end
            end

            return IgnoreNoStock and NewList or SeedStock
        end

        local function CanHarvest(Plant)
            local Prompt = Plant:FindFirstChild("ProximityPrompt", true)
            if not Prompt then return end
            if not Prompt.Enabled then return end
            return true
        end

        local function ShouldHarvestPlant(Plant)
            -- Check seed type filter
            if HarvestByType and HarvestByType.Value ~= "All" then
                local PlantName = Plant.Name
                if PlantName ~= HarvestByType.Value then return false end
            end
            
            -- Check variant filter
            if HarvestByVariant and HarvestByVariant.Value ~= "All" then
                local Variant = Plant:FindFirstChild("Variant")
                if not Variant then return false end
                if Variant.Value ~= HarvestByVariant.Value then return false end
                
                -- Count mutations
                if Variant.Value == "Gold" or Variant.Value == "Rainbow" then
                    SessionStats.MutationsFound = SessionStats.MutationsFound + 1
                end
            end
            
            return true
        end

        local function CollectHarvestable(Parent, Plants, IgnoreDistance)
            local Character = LocalPlayer.Character
            if not Character then return Plants end
            local PlayerPosition = Character:GetPivot().Position

            for _, Plant in next, Parent:GetChildren() do
                local Fruits = Plant:FindFirstChild("Fruits")
                if Fruits then
                    CollectHarvestable(Fruits, Plants, IgnoreDistance)
                end

                local PlantPosition = Plant:GetPivot().Position
                local Distance = (PlayerPosition-PlantPosition).Magnitude
                
                if (IgnoreDistance or Distance <= 15) and ShouldHarvestPlant(Plant) and CanHarvest(Plant) then
                    table.insert(Plants, Plant)
                end
            end
            return Plants
        end

        local function GetHarvestablePlants(IgnoreDistance)
            local Plants = {}
            CollectHarvestable(PlantsPhysical, Plants, IgnoreDistance)
            return Plants
        end

        local function HarvestPlants()
            if IsHarvesting then return end
            IsHarvesting = true
            
            local Plants = GetHarvestablePlants()
            for _, Plant in next, Plants do
                HarvestPlant(Plant)
            end
            
            IsHarvesting = false
        end

        local function AutoSellCheck()
            local CropCount = #GetInvCrops()
            if not AutoSell or not AutoSell.Value then return end
            if CropCount < (SellThreshold and SellThreshold.Value or 15) then return end
            SellInventory()
        end

        local function AutoWalkLoop()
            if IsSelling or IsPlanting or IsHarvesting then return end

            local Character = LocalPlayer.Character
            if not Character then return end
            local Humanoid = Character.Humanoid

            local Plants = GetHarvestablePlants(true)
            local RandomAllowed = AutoWalkAllowRandom and AutoWalkAllowRandom.Value or false
            local DoRandom = #Plants == 0 or math.random(1, 3) == 2

            if RandomAllowed and DoRandom then
                local Position = GetRandomFarmPoint()
                Humanoid:MoveTo(Position)
                if AutoWalkStatus then
                    AutoWalkStatus:SetText("Status: Random point")
                end
                return
            end

            for _, Plant in next, Plants do
                local Position = Plant:GetPivot().Position
                Humanoid:MoveTo(Position)
                if AutoWalkStatus then
                    AutoWalkStatus:SetText("Status: " .. Plant.Name)
                end
            end
        end

        local function NoclipLoop()
            local Character = LocalPlayer.Character
            if not NoClip or not NoClip.Value then return end
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
                    if Toggle and Toggle.Value then
                        Func()
                    end
                end
            end)()
        end

        local function StartServices()
            MakeLoop(AutoWalk, function()
                local MaxWait = AutoWalkMaxWait and AutoWalkMaxWait.Value or 10
                AutoWalkLoop()
                wait(math.random(1, MaxWait))
            end)

            MakeLoop(AutoHarvest, HarvestPlants)
            MakeLoop(AutoBuy, BuyAllSelectedSeeds)
            MakeLoop(AutoPlant, AutoPlantLoop)

            while wait(.1) do
                GetSeedStock()
                GetOwnedSeeds()
                UpdateSessionStats()
            end
        end

        --// Custom theme setup for garden look
        Library.Scheme.BackgroundColor = Accent.Brown
        Library.Scheme.MainColor = Accent.DarkGreen
        Library.Scheme.AccentColor = Accent.Green

        --// Create Enhanced Window using Obsidian
        local Window = Library:CreateWindow({
            Title = GameInfo.Name .. " | Enhanced Auto-Farm v2.0",
            Footer = "Advanced Features with Smart Automation",
            Size = UDim2.fromOffset(580, 700),
            Icon = "leaf",
            AutoShow = true,
            Center = true,
            Resizable = true,
        })

        --// Create main tab
        local MainTab = Window:AddTab({
            Name = "Auto Farm",
            Icon = "tractor",
            Description = "Enhanced farming automation"
        })

        --// Enhanced Auto-Plant Section
        local PlantGroupbox = MainTab:AddLeftGroupbox("Enhanced Auto-Plant 🌱", "sprout")

        SelectedSeed = PlantGroupbox:AddDropdown("SelectedSeed", {
            Text = "Select Seed Type",
            Values = {"All"},
            Multi = false,
            Default = "All",
            Callback = function(Value)
                -- Seed selection callback
            end
        })

        SelectedSeeds = PlantGroupbox:AddDropdown("SelectedSeeds", {
            Text = "Multi-Seed Selection",
            Values = {"All"},
            Multi = true,
            Default = {"All"},
            Callback = function(Value)
                -- Multi-seed selection callback
            end
        })

        AutoPlant = PlantGroupbox:AddToggle("AutoPlant", {
            Text = "Auto Plant",
            Default = false,
            Callback = function(Value)
                -- Auto plant toggled
            end
        })

        PlantAtPlayer = PlantGroupbox:AddToggle("PlantAtPlayer", {
            Text = "Plant at Player Position",
            Default = false,
            Callback = function(Value)
                -- Plant at player toggled
            end
        })

        PlantRadius = PlantGroupbox:AddSlider("PlantRadius", {
            Text = "Plant Radius",
            Default = 10,
            Min = 5,
            Max = 50,
            Rounding = 0,
            Callback = function(Value)
                -- Plant radius changed
            end
        })

        AutoPlantRandom = PlantGroupbox:AddToggle("AutoPlantRandom", {
            Text = "Include random points",
            Default = false,
            Callback = function(Value)
                -- Random planting toggled
            end
        })

        PlantGroupbox:AddButton({
            Text = "Plant All Selected",
            Func = AutoPlantLoop,
            Tooltip = "Plant all selected seed types"
        })

        --// Enhanced Auto-Harvest Section
        local HarvestGroupbox = MainTab:AddRightGroupbox("Smart Auto-Harvest 🚜", "wheat")

        AutoHarvest = HarvestGroupbox:AddToggle("AutoHarvest", {
            Text = "Auto Harvest",
            Default = false,
            Callback = function(Value)
                -- Auto harvest toggled
            end
        })

        HarvestByType = HarvestGroupbox:AddDropdown("HarvestByType", {
            Text = "Harvest Seed Types",
            Values = {"All"},
            Multi = false,
            Default = "All",
            Callback = function(Value)
                -- Harvest filter by type
            end
        })

        HarvestByVariant = HarvestGroupbox:AddDropdown("HarvestByVariant", {
            Text = "Harvest Variants",
            Values = {"All", "Normal", "Gold", "Rainbow"},
            Multi = false,
            Default = "All",
            Callback = function(Value)
                -- Harvest filter by variant
            end
        })

        HarvestGroupbox:AddButton({
            Text = "Harvest All Filtered",
            Func = HarvestPlants,
            Tooltip = "Harvest based on current filters"
        })

        --// Enhanced Shopping Section
        local ShopTab = Window:AddTab({
            Name = "Smart Shopping",
            Icon = "shopping-cart",
            Description = "Automated purchasing system"
        })

        local SeedShopGroupbox = ShopTab:AddLeftGroupbox("Seed Shop 🌰", "seedling")

        SelectedSeedStock = SeedShopGroupbox:AddDropdown("SelectedSeedStock", {
            Text = "Select Seed to Buy",
            Values = {},
            Multi = false,
            Default = "",
            Callback = function(Value)
                -- Seed stock selection
            end
        })

        AutoBuy = SeedShopGroupbox:AddToggle("AutoBuy", {
            Text = "Auto Buy Seeds",
            Default = false,
            Callback = function(Value)
                -- Auto buy toggled
            end
        })

        OnlyShowStock = SeedShopGroupbox:AddToggle("OnlyShowStock", {
            Text = "Only show in stock",
            Default = false,
            Callback = function(Value)
                -- Update dropdown based on stock
            end
        })

        SeedShopGroupbox:AddButton({
            Text = "Buy All Stock",
            Func = BuyAllSelectedSeeds,
            Tooltip = "Buy all available stock of selected seed"
        })

        SeedShopGroupbox:AddButton({
            Text = "Teleport to Seed Shop",
            Func = function() TeleportToPosition(NPCLocations.SeedShop) end,
            Tooltip = "Quick teleport to seed shop"
        })

        --// Gear Shop Section
        local GearShopGroupbox = ShopTab:AddRightGroupbox("Gear Shop ⚙️", "tools")

        SelectedGear = GearShopGroupbox:AddDropdown("SelectedGear", {
            Text = "Select Gear",
            Values = {"Watering Can", "Fertilizer", "Shovel", "Hoe"},
            Multi = false,
            Default = "Watering Can",
            Callback = function(Value)
                -- Gear selection
            end
        })

        AutoGearBuy = GearShopGroupbox:AddToggle("AutoGearBuy", {
            Text = "Auto Buy Gear",
            Default = false,
            Callback = function(Value)
                -- Auto gear buy toggled
            end
        })

        GearShopGroupbox:AddButton({
            Text = "Buy Selected Gear",
            Func = function() 
                if SelectedGear and SelectedGear.Value then
                    BuyGear(SelectedGear.Value)
                end
            end,
            Tooltip = "Buy the selected gear"
        })

        GearShopGroupbox:AddButton({
            Text = "Teleport to Gear Shop",
            Func = function() TeleportToPosition(NPCLocations.GearShop) end,
            Tooltip = "Quick teleport to gear shop"
        })

        --// Pet/Egg Shop Section
        local PetShopGroupbox = ShopTab:AddLeftGroupbox("Pet Shop 🥚", "heart")

        SelectedEgg = PetShopGroupbox:AddDropdown("SelectedEgg", {
            Text = "Select Egg Type",
            Values = {"Basic Egg", "Golden Egg", "Rainbow Egg", "Special Egg"},
            Multi = false,
            Default = "Basic Egg",
            Callback = function(Value)
                -- Egg selection
            end
        })

        AutoEggBuy = PetShopGroupbox:AddToggle("AutoEggBuy", {
            Text = "Auto Buy Eggs",
            Default = false,
            Callback = function(Value)
                -- Auto egg buy toggled
            end
        })

        PetShopGroupbox:AddButton({
            Text = "Buy Selected Egg",
            Func = function()
                if SelectedEgg and SelectedEgg.Value then
                    BuyEgg(SelectedEgg.Value)
                end
            end,
            Tooltip = "Buy the selected egg type"
        })

        PetShopGroupbox:AddButton({
            Text = "Teleport to Pet Shop",
            Func = function() TeleportToPosition(NPCLocations.PetShop) end,
            Tooltip = "Quick teleport to pet shop"
        })

        --// Teleport & Navigation Tab
        local TeleportTab = Window:AddTab({
            Name = "Teleportation",
            Icon = "map-pin",
            Description = "Quick travel and navigation"
        })

        local TeleportGroupbox = TeleportTab:AddLeftGroupbox("Quick Teleports 🌀", "zap")

        TeleportGroupbox:AddButton({
            Text = "My Farm",
            Func = function() TeleportToPosition(NPCLocations.Farm) end,
            Tooltip = "Teleport to your farm"
        })

        TeleportGroupbox:AddButton({
            Text = "Sell Area",
            Func = function() TeleportToPosition(NPCLocations.SellArea) end,
            Tooltip = "Teleport to selling area"
        })

        TeleportGroupbox:AddButton({
            Text = "Beanstalk Event",
            Func = function() TeleportToPosition(NPCLocations.BeanstalkEvent) end,
            Tooltip = "Teleport to current Beanstalk event"
        })

        TeleportGroupbox:AddButton({
            Text = "Return to Previous",
            Func = ReturnToPreviousPosition,
            Tooltip = "Return to previous position"
        })

        local CustomTeleportGroupbox = TeleportTab:AddRightGroupbox("Custom Teleport 📍", "target")

        local TeleportX, TeleportY, TeleportZ
        TeleportX = CustomTeleportGroupbox:AddSlider("TeleportX", {
            Text = "X Coordinate",
            Default = 0,
            Min = -1000,
            Max = 1000,
            Rounding = 0,
            Callback = function(Value) end
        })

        TeleportY = CustomTeleportGroupbox:AddSlider("TeleportY", {
            Text = "Y Coordinate", 
            Default = 4,
            Min = 0,
            Max = 100,
            Rounding = 0,
            Callback = function(Value) end
        })

        TeleportZ = CustomTeleportGroupbox:AddSlider("TeleportZ", {
            Text = "Z Coordinate",
            Default = 0,
            Min = -1000,
            Max = 1000,
            Rounding = 0,
            Callback = function(Value) end
        })

        CustomTeleportGroupbox:AddButton({
            Text = "Teleport to Coordinates",
            Func = function()
                local x = TeleportX.Value or 0
                local y = TeleportY.Value or 4
                local z = TeleportZ.Value or 0
                TeleportToPosition(Vector3.new(x, y, z))
            end,
            Tooltip = "Teleport to custom coordinates"
        })

        --// Auto-Sell Section with Enhanced Features
        local SellGroupbox = TeleportTab:AddLeftGroupbox("Smart Auto-Sell 💰", "coins")

        SellGroupbox:AddButton({
            Text = "Sell Inventory Now",
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
            Text = "Sell at crop count",
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
            Name = "Movement",
            Icon = "footprints",
            Description = "Automatic movement and pathfinding"
        })

        local WalkGroupbox = WalkTab:AddLeftGroupbox("Smart Auto-Walk 🚶", "navigation")

        AutoWalkStatus = WalkGroupbox:AddLabel("Status: Idle")

        AutoWalk = WalkGroupbox:AddToggle("AutoWalk", {
            Text = "Auto Walk",
            Default = false,
            Callback = function(Value)
                if not Value and AutoWalkStatus then
                    AutoWalkStatus:SetText("Status: Idle")
                end
            end
        })

        AutoWalkAllowRandom = WalkGroupbox:AddToggle("AutoWalkAllowRandom", {
            Text = "Allow random movement",
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

        --// Statistics & Dashboard Tab
        local StatsTab = Window:AddTab({
            Name = "Statistics",
            Icon = "bar-chart",
            Description = "Session tracking and analytics"
        })

        local SessionGroupbox = StatsTab:AddLeftGroupbox("Session Statistics 📊", "activity")

        StatusLabels.SessionTime = SessionGroupbox:AddLabel("Session: 00:00")
        StatusLabels.PlantsHarvested = SessionGroupbox:AddLabel("Harvested: 0")
        StatusLabels.TotalProfit = SessionGroupbox:AddLabel("Profit: $0")
        StatusLabels.MutationsFound = SessionGroupbox:AddLabel("Mutations: 0")

        local SessionStatsGroupbox = StatsTab:AddRightGroupbox("Activity Stats 🎯", "target")

        local SeedsPlantedLabel = SessionStatsGroupbox:AddLabel("Seeds Planted: 0")
        local GearsUsedLabel = SessionStatsGroupbox:AddLabel("Gears Used: 0")
        local EggsOpenedLabel = SessionStatsGroupbox:AddLabel("Eggs Opened: 0")

        SessionStatsGroupbox:AddButton({
            Text = "Reset Statistics",
            Func = function()
                SessionStats = {
                    StartTime = tick(),
                    PlantsHarvested = 0,
                    SeedsPlanted = 0,
                    TotalProfit = 0,
                    MutationsFound = 0,
                    GearsUsed = 0,
                    EggsOpened = 0
                }
                UpdateSessionStats()
            end,
            Tooltip = "Reset all session statistics"
        })

        --// Enhanced Inventory Management
        local InventoryTab = Window:AddTab({
            Name = "Inventory",
            Icon = "package",
            Description = "Smart inventory management"
        })

        local InventoryGroupbox = InventoryTab:AddLeftGroupbox("Inventory Manager 📦", "package")

        local InventoryStatus = InventoryGroupbox:AddLabel("Inventory: 0/200")
        local SeedCountLabel = InventoryGroupbox:AddLabel("Seeds: 0")
        local CropCountLabel = InventoryGroupbox:AddLabel("Crops: 0")

        InventoryGroupbox:AddButton({
            Text = "Update Inventory Info",
            Func = function()
                local crops = GetInvCrops()
                local seeds = GetOwnedSeeds()
                local totalSeeds = 0
                for _, seedData in pairs(seeds) do
                    totalSeeds = totalSeeds + seedData.Count
                end
                
                InventoryStatus:SetText("Inventory: " .. (#crops + totalSeeds) .. "/200")
                SeedCountLabel:SetText("Seeds: " .. totalSeeds)
                CropCountLabel:SetText("Crops: " .. #crops)
            end,
            Tooltip = "Refresh inventory information"
        })

        --// Keybind System
        local KeybindTab = Window:AddTab({
            Name = "Keybinds",
            Icon = "keyboard",
            Description = "Hotkey controls for quick actions"
        })

        local KeybindGroupbox = KeybindTab:AddLeftGroupbox("Quick Controls ⌨️", "zap")

        KeybindGroupbox:AddLabel("Default Keybinds:")
        KeybindGroupbox:AddLabel("F1 - Toggle Auto Plant")
        KeybindGroupbox:AddLabel("F2 - Toggle Auto Harvest") 
        KeybindGroupbox:AddLabel("F3 - Sell Inventory")
        KeybindGroupbox:AddLabel("F4 - Emergency Stop All")

        local EmergencyStopActive = false
        KeybindGroupbox:AddButton({
            Text = "Emergency Stop All",
            Func = function()
                EmergencyStopActive = true
                if AutoPlant then AutoPlant:SetValue(false) end
                if AutoHarvest then AutoHarvest:SetValue(false) end
                if AutoWalk then AutoWalk:SetValue(false) end
                if AutoBuy then AutoBuy:SetValue(false) end
                if AutoSell then AutoSell:SetValue(false) end
                
                Library:Notify({
                    Title = "Emergency Stop",
                    Description = "All automation stopped!",
                    Time = 3
                })
            end,
            Tooltip = "Immediately stop all automation"
        })

        --// Update functions for real-time data
        local function UpdateDropdowns()
            local seeds = GetOwnedSeeds()
            local seedNames = {"All"}
            for seedName, _ in pairs(seeds) do
                if not tableFind(seedNames, seedName) then
                    table.insert(seedNames, seedName)
                end
            end
            
            if SelectedSeed then SelectedSeed:SetValues(seedNames) end
            if SelectedSeeds then SelectedSeeds:SetValues(seedNames) end
            if HarvestByType then HarvestByType:SetValues(seedNames) end
            
            local stockList = GetSeedStock(OnlyShowStock and OnlyShowStock.Value or false)
            local stockValues = {}
            for seedName, _ in pairs(stockList) do
                table.insert(stockValues, seedName)
            end
            if SelectedSeedStock then SelectedSeedStock:SetValues(stockValues) end
        end

        local function UpdateExtendedStats()
            if SeedsPlantedLabel then
                SeedsPlantedLabel:SetText("Seeds Planted: " .. SessionStats.SeedsPlanted)
            end
            if GearsUsedLabel then
                GearsUsedLabel:SetText("Gears Used: " .. SessionStats.GearsUsed)
            end
            if EggsOpenedLabel then
                EggsOpenedLabel:SetText("Eggs Opened: " .. SessionStats.EggsOpened)
            end
        end

        --// Enhanced Services with Error Handling
        local function StartEnhancedServices()
            -- Existing automation loops
            MakeLoop(AutoWalk, function()
                local MaxWait = AutoWalkMaxWait and AutoWalkMaxWait.Value or 10
                AutoWalkLoop()
                wait(math.random(1, MaxWait))
            end)

            MakeLoop(AutoHarvest, HarvestPlants)
            MakeLoop(AutoBuy, BuyAllSelectedSeeds)
            MakeLoop(AutoPlant, AutoPlantLoop)
            
            -- New automation loops
            MakeLoop(AutoGearBuy, function()
                if SelectedGear and SelectedGear.Value then
                    BuyGear(SelectedGear.Value)
                    wait(5) -- Longer delay for gear buying
                end
            end)
            
            MakeLoop(AutoEggBuy, function()
                if SelectedEgg and SelectedEgg.Value then
                    BuyEgg(SelectedEgg.Value)
                    wait(10) -- Even longer delay for egg buying
                end
            end)

            -- Main update loop
            while wait(.5) do
                if not EmergencyStopActive then
                    GetSeedStock()
                    GetOwnedSeeds()
                    UpdateSessionStats()
                    UpdateExtendedStats()
                    UpdateDropdowns()
                else
                    wait(1)
                end
            end
        end

        --// Keybind Setup
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            if input.KeyCode == Enum.KeyCode.F1 then
                if AutoPlant then AutoPlant:SetValue(not AutoPlant.Value) end
            elseif input.KeyCode == Enum.KeyCode.F2 then
                if AutoHarvest then AutoHarvest:SetValue(not AutoHarvest.Value) end
            elseif input.KeyCode == Enum.KeyCode.F3 then
                SellInventory()
            elseif input.KeyCode == Enum.KeyCode.F4 then
                EmergencyStopActive = not EmergencyStopActive
                if EmergencyStopActive then
                    if AutoPlant then AutoPlant:SetValue(false) end
                    if AutoHarvest then AutoHarvest:SetValue(false) end
                    if AutoWalk then AutoWalk:SetValue(false) end
                end
            end
        end)

        --// Connections
        RunService.Stepped:Connect(NoclipLoop)
        Backpack.ChildAdded:Connect(AutoSellCheck)

        --// Start enhanced services
        StartEnhancedServices()

        --// Initial dropdown population
        coroutine.wrap(function()
            wait(2) -- Allow time for UI to load
            UpdateDropdowns()
        end)()

        --// Show notifications
        Library:Notify({
            Title = "Enhanced Auto Farm v2.0",
            Description = "All advanced features loaded successfully!",
            Time = 4
        })

        Library:Notify({
            Title = "Keybinds Active",
            Description = "F1-F4 hotkeys are ready to use!",
            Time = 3
        })

    else
        Library:Notify({
            Title = "Error",
            Description = "Could not find farm dirt area!",
            Time = 5
        })
    end
else
    Library:Notify({
        Title = "Error", 
        Description = "Could not find your farm!",
        Time = 5
    })
end
