--[[
    Refactored Grow a Garden Auto-Farm v2.1
    Simplified single-phase bootstrap + robust dependency waiting + protected main body
    Features preserved from previous v2.0 implementation.
]]

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

local function safewait(t)
    if task and task.wait then return task.wait(t) end
    if coroutine and coroutine.yield then
        local ts = os.clock() + (t or 0)
        repeat until os.clock() >= ts
        return t
    end
    return t
end

-- Dependency wait helpers
local function waitForGameLoaded(timeout)
    local deadline = os.clock() + (timeout or 30)
    while not game:IsLoaded() do
        if os.clock() > deadline then return false, 'Game never loaded' end
        safewait(0.1)
    end
    return true
end

local function waitForPlayer(timeout)
    local Players = game:GetService('Players')
    local deadline = os.clock() + (timeout or 30)
    while os.clock() < deadline do
        local lp = Players.LocalPlayer
        if lp and lp.Character and lp.Character:FindFirstChild('HumanoidRootPart') then
            return true, lp
        end
        log('INFO','Waiting for player/character...')
        safewait(1)
    end
    return false, 'Player/Character timeout'
end

local function loadUILibrary()
    local sources = {
        {name='Obsidian-main', url='https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua'},
        {name='Obsidian-alt',  url='https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua'},
        {name='Rayfield',      url='https://raw.githubusercontent.com/shlexware/Rayfield/main/source'},
    }
    for _, src in ipairs(sources) do
        local ok, lib = pcall(function()
            return loadstring(game:HttpGet(src.url, true))()
        end)
        if ok and lib then
            _G.__AF2_LibName = src.name
            log('INFO','Loaded UI library: '..src.name)
            return lib
        else
            log('WARN','Failed load '..src.name..': '..tostring(lib))
        end
    end
    error('All UI libraries failed to load')
end

-- Begin bootstrap
local okGame, gameErr = waitForGameLoaded(60)
if not okGame then
    warn('[AFv2] '..gameErr)
    return
end

local playerOk, LocalPlayerOrErr = waitForPlayer(60)
if not playerOk then
    warn('[AFv2] '..LocalPlayerOrErr)
    return
end
local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer

local Library
local libOk, libErr = pcall(function()
    Library = loadUILibrary()
end)
if not libOk or not Library then
    warn('[AFv2] UI Library load failed: '..tostring(libErr))
    return
end

-- Temporary boot window
local BootWindow, BootLogBox
local function bootlog(msg, level)
    level = level or 'INFO'
    log(level, msg)
    if BootLogBox then BootLogBox:AddLabel(msg) end
end

local function createBootWindow()
    local ok, win = pcall(function()
        return Library:CreateWindow({
            Title = 'AFv2 Boot ('..(_G.__AF2_LibName or '?')..')',
            Size = UDim2.fromOffset(380,260),
            Center = true,
            AutoShow = true,
            Resizable = false,
            Footer = 'Initializing...'
        })
    end)
    if ok and win then
        BootWindow = win
        local tab = win:AddTab({Name='Boot', Icon='info'})
        local box = tab:AddLeftGroupbox('Progress')
        BootLogBox = box
        box:AddLabel('UI Lib: '..(_G.__AF2_LibName or '?'))
        box:AddLabel('PlaceId: '..tostring(game.PlaceId))
        box:AddLabel('Player: '..LocalPlayer.Name)
    else
        log('WARN','Failed to create boot window UI')
    end
end
createBootWindow()

-- Validate core services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local MarketplaceService = game:GetService('MarketplaceService')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')

-- Wait for GameEvents with retry
local function waitForChild(parent, childName, timeout)
    local deadline = os.clock() + (timeout or 30)
    local child = parent:FindFirstChild(childName)
    while not child and os.clock() < deadline do
        safewait(0.5)
        child = parent:FindFirstChild(childName)
    end
    return child
end

bootlog('Waiting for GameEvents...')
local GameEventsFolder = waitForChild(ReplicatedStorage,'GameEvents',40)
if not GameEventsFolder then
    bootlog('GameEvents not found. Aborting.', 'ERROR')
    return
end
bootlog('GameEvents OK')

-- Mark boot complete (before main build to allow other scripts hooking)
_G.__AF2_BOOT_COMPLETE = true

-- Protected main body
local mainOk, mainErr = pcall(function()
    -----------------------------------------------------------------------------
    -- MAIN IMPLEMENTATION (refactored, original features preserved)
    -----------------------------------------------------------------------------
    -- shim for static analyzers (ignored at runtime in Roblox)
    local Vector3 = Vector3
    local CFrame = CFrame
    local tick = tick

    -- Additional services
    local InsertService = game:GetService('InsertService')
    local TweenService = game:GetService('TweenService')

    local Leaderstats = LocalPlayer:WaitForChild('leaderstats')
    local Backpack = LocalPlayer:WaitForChild('Backpack')
    local PlayerGui = LocalPlayer:WaitForChild('PlayerGui')

    local ShecklesCount = Leaderstats:WaitForChild('Sheckles')
    local GameInfo = MarketplaceService:GetProductInfo(game.PlaceId)

    -- Folders
    local Farms = workspace:FindFirstChild('Farm') or workspace:WaitForChild('Farm', 20)

    -- Accent colors
    local Accent = {
        DarkGreen = Color3.fromRGB(45, 95, 25),
        Green = Color3.fromRGB(69, 142, 40),
        Brown = Color3.fromRGB(26, 20, 8),
        Gold = Color3.fromRGB(255, 215, 0),
        Rainbow = Color3.fromRGB(138, 43, 226)
    }

    -- Data tables
    local SeedStock, OwnedSeeds = {}, {}
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
        SeedTypes = {'All'},
        Variants = {'All','Normal','Gold','Rainbow'},
        SelectedSeeds = {'All'},
        SelectedVariants = {'All'}
    }

    local NPCLocations = {
        SeedShop = Vector3.new(51, 4, -20),
        GearShop = Vector3.new(65, 4, -15),
        PetShop = Vector3.new(70, 4, -25),
        SellArea = Vector3.new(62, 4, -26),
        BeanstalkEvent = Vector3.new(45, 4, 30),
        Farm = Vector3.new(0, 4, 0) -- updated later
    }

    -- UI references / toggles
    local SelectedSeed, SelectedSeeds, AutoPlantRandom, AutoPlant, AutoHarvest, AutoBuy
    local SellThreshold, NoClip, AutoWalkAllowRandom, AutoSell, AutoWalk, AutoWalkMaxWait
    local SelectedSeedStock, OnlyShowStock, SelectedGear, SelectedEgg, AutoGearBuy, AutoEggBuy
    local PlantAtPlayer, PlantRadius, HarvestByType, HarvestByVariant

    local PreviousPosition
    local StatusLabels = {}
    local IsPlanting, IsHarvesting, IsSelling, IsBuying = false, false, false, false

    -- Utilities
    local function tableFind(tbl, value)
        for i,v in pairs(tbl) do if v == value then return i end end
        return nil
    end

    local function GetPlayerPosition()
        local c = LocalPlayer.Character; if not c then return Vector3.new(0,4,0) end
        local hrp = c:FindFirstChild('HumanoidRootPart'); if not hrp then return Vector3.new(0,4,0) end
        return hrp.Position
    end
    local function TeleportToPosition(pos)
        local c = LocalPlayer.Character; if not c then return end
        local hrp = c:FindFirstChild('HumanoidRootPart'); if not hrp then return end
        PreviousPosition = hrp.CFrame
        hrp.CFrame = CFrame.new(pos)
        safewait(0.35)
    end
    local function ReturnToPreviousPosition()
        if not PreviousPosition then return end
        local c = LocalPlayer.Character; if not c then return end
        local hrp = c:FindFirstChild('HumanoidRootPart'); if not hrp then return end
        hrp.CFrame = PreviousPosition
    end

    local function UpdateSessionStats()
        if StatusLabels.SessionTime then
            local elapsed = tick() - SessionStats.StartTime
            local h = math.floor(elapsed/3600)
            local m = math.floor((elapsed%3600)/60)
            StatusLabels.SessionTime:SetText(string.format('Session: %02d:%02d', h, m))
        end
        if StatusLabels.PlantsHarvested then
            StatusLabels.PlantsHarvested:SetText('Harvested: '..SessionStats.PlantsHarvested)
        end
        if StatusLabels.TotalProfit then
            StatusLabels.TotalProfit:SetText('Profit: $'..SessionStats.TotalProfit)
        end
        if StatusLabels.MutationsFound then
            StatusLabels.MutationsFound:SetText('Mutations: '..SessionStats.MutationsFound)
        end
    end

    -- GameEvents reference
    local GameEvents = ReplicatedStorage:WaitForChild('GameEvents')

    local function Plant(pos, seedName)
        if IsPlanting then return end
        IsPlanting = true
        pcall(function() GameEvents.Plant_RE:FireServer(pos, seedName) end)
        SessionStats.SeedsPlanted = SessionStats.SeedsPlanted + 1
        safewait(0.25)
        IsPlanting = false
    end

    local function GetFarms()
        return Farms and Farms:GetChildren() or {}
    end
    local function GetFarmOwner(farm)
        local ok, result = pcall(function()
            return farm.Important.Data.Owner.Value
        end)
        if ok then return result end
    end
    local function GetFarm(playerName)
        for _, farm in ipairs(GetFarms()) do
            if GetFarmOwner(farm) == playerName then return farm end
        end
    end

    -- Sell / buy helpers
    local function SellInventory()
        if IsSelling then return end
        IsSelling = true
        local prev = ShecklesCount.Value
        TeleportToPosition(NPCLocations.SellArea)
        local t0 = os.clock()
        while os.clock() - t0 < 8 do
            if ShecklesCount.Value ~= prev then break end
            pcall(function() GameEvents.Sell_Inventory:FireServer() end)
            safewait(0.2)
        end
        SessionStats.TotalProfit = SessionStats.TotalProfit + (ShecklesCount.Value - prev)
        ReturnToPreviousPosition()
        IsSelling = false
    end

    local function BuySeed(seed)
        if IsBuying then return end
        IsBuying = true
        TeleportToPosition(NPCLocations.SeedShop)
        pcall(function() GameEvents.BuySeedStock:FireServer(seed) end)
        safewait(0.4)
        ReturnToPreviousPosition()
        IsBuying = false
    end
    local function BuyGear(gear)
        if IsBuying then return end
        IsBuying = true
        TeleportToPosition(NPCLocations.GearShop)
        pcall(function() GameEvents.BuyGear:FireServer(gear) end)
        SessionStats.GearsUsed = SessionStats.GearsUsed + 1
        safewait(0.4)
        ReturnToPreviousPosition()
        IsBuying = false
    end
    local function BuyEgg(egg)
        if IsBuying then return end
        IsBuying = true
        TeleportToPosition(NPCLocations.PetShop)
        pcall(function() GameEvents.BuyEgg:FireServer(egg) end)
        SessionStats.EggsOpened = SessionStats.EggsOpened + 1
        safewait(0.5)
        ReturnToPreviousPosition()
        IsBuying = false
    end
    local function BuyAllSelectedSeeds()
        if not (SelectedSeedStock and SelectedSeedStock.Value) then return end
        local seed = SelectedSeedStock.Value
        local stock = SeedStock[seed]
        if not stock or stock <= 0 then return end
        for _=1, stock do BuySeed(seed) end
    end

    local function GetSeedInfo(tool)
        local pn = tool:FindFirstChild('Plant_Name')
        local count = tool:FindFirstChild('Numbers')
        if pn and count then return pn.Value, count.Value end
    end
    local function CollectSeedsFromParent(parent, seeds)
        for _,tool in ipairs(parent:GetChildren()) do
            local name,count = GetSeedInfo(tool)
            if name then
                seeds[name] = {Count = count, Tool = tool}
            end
        end
    end
    local function CollectCropsFromParent(parent, crops)
        for _,tool in ipairs(parent:GetChildren()) do
            local name = tool:FindFirstChild('Item_String')
            if name then table.insert(crops, tool) end
        end
    end
    local function GetOwnedSeeds()
        OwnedSeeds = {}
        CollectSeedsFromParent(Backpack, OwnedSeeds)
        local char = LocalPlayer.Character
        if char then CollectSeedsFromParent(char, OwnedSeeds) end
        local names = {'All'}
        for seedName,_ in pairs(OwnedSeeds) do table.insert(names, seedName) end
        HarvestFilters.SeedTypes = names
        return OwnedSeeds
    end
    local function GetInvCrops()
        local crops = {}
        CollectCropsFromParent(Backpack, crops)
        local char = LocalPlayer.Character
        if char then CollectCropsFromParent(char, crops) end
        return crops
    end
    local function GetArea(base)
        local pivot = base:GetPivot()
        local size = base.Size
        local X1 = math.ceil(pivot.X - size.X/2)
        local Z1 = math.ceil(pivot.Z - size.Z/2)
        local X2 = math.floor(pivot.X + size.X/2)
        local Z2 = math.floor(pivot.Z + size.Z/2)
        return X1,Z1,X2,Z2
    end
    local function EquipCheck(tool)
        local char = LocalPlayer.Character; if not char then return end
        local hum = char:FindFirstChildOfClass('Humanoid'); if not hum then return end
        if tool.Parent == Backpack then hum:EquipTool(tool) end
    end

    local MyFarm = GetFarm(LocalPlayer.Name)
    local PlantLocations, PlantsPhysical, X1,Z1,X2,Z2
    if MyFarm then
        NPCLocations.Farm = MyFarm:GetPivot().Position
        local important = MyFarm:FindFirstChild('Important')
        if important then
            PlantLocations = important:FindFirstChild('Plant_Locations')
            PlantsPhysical = important:FindFirstChild('Plants_Physical')
            if PlantLocations then
                local dirt = PlantLocations:FindFirstChildOfClass('Part')
                if dirt then
                    X1,Z1,X2,Z2 = GetArea(dirt)
                end
            end
        end
    end

    local function GetRandomFarmPoint()
        if not PlantLocations then return Vector3.new() end
        local farms = PlantLocations:GetChildren()
        if #farms == 0 then return Vector3.new() end
        local plot = farms[math.random(1,#farms)]
        local a,b,c,d = GetArea(plot)
        return Vector3.new(math.random(a,c), 4, math.random(b,d))
    end

    local function GetPlayerRadiusPoints()
        local origin = GetPlayerPosition()
        local radius = (PlantRadius and PlantRadius.Value) or 10
        local pts = {}
        for _=1, 20 do
            local ang = math.random()*math.pi*2
            local dist = math.random()*radius
            table.insert(pts, Vector3.new(origin.X + math.cos(ang)*dist, origin.Y, origin.Z + math.sin(ang)*dist))
        end
        return pts
    end

    local function ShouldPlantSeed(seedName)
        if not SelectedSeeds or not SelectedSeeds.Value then return false end
        local selected = SelectedSeeds.Value
        if selected == 'All' then return true end
        if type(selected) == 'table' then return tableFind(selected, seedName) ~= nil end
        return selected == seedName
    end

    local function AutoPlantLoop()
        if not SelectedSeed or not SelectedSeed.Value then return end
        local chosen = SelectedSeed.Value
        if chosen == 'All' then
            for sName, data in pairs(OwnedSeeds) do
                if ShouldPlantSeed(sName) and data.Count > 0 then
                    EquipCheck(data.Tool)
                    if PlantAtPlayer and PlantAtPlayer.Value then
                        for _,pt in ipairs(GetPlayerRadiusPoints()) do
                            if data.Count <= 0 then break end
                            Plant(pt, sName)
                            data.Count = data.Count - 1
                        end
                    else
                        local planted = 0
                        for x=X1,X2 do for z=Z1,Z2 do
                            if planted >= data.Count then break end
                            Plant(Vector3.new(x,0.13,z), sName)
                            planted = planted + 1
                        end end
                    end
                end
            end
            return
        end
        local data = OwnedSeeds[chosen]
        if not data or data.Count <= 0 then return end
        EquipCheck(data.Tool)
        if PlantAtPlayer and PlantAtPlayer.Value then
            for _,pt in ipairs(GetPlayerRadiusPoints()) do
                if data.Count <= 0 then break end
                Plant(pt, chosen)
                data.Count = data.Count - 1
            end
        else
            local planted = 0
            for x=X1,X2 do for z=Z1,Z2 do
                if planted >= data.Count then break end
                Plant(Vector3.new(x,0.13,z), chosen)
                planted = planted + 1
            end end
        end
    end

    local function HarvestPlant(plant)
        local prompt = plant:FindFirstChild('ProximityPrompt', true)
        if not prompt then return end
        pcall(function() fireproximityprompt(prompt) end)
        SessionStats.PlantsHarvested = SessionStats.PlantsHarvested + 1
    end

    local function GetSeedStock(ignoreNoStock)
        local shop = PlayerGui:FindFirstChild('Seed_Shop')
        if not shop then return {} end
        local marker = shop:FindFirstChild('Blueberry', true)
        if not marker then return {} end
        local parent = marker.Parent
        local newList = {}
        for _, item in ipairs(parent:GetChildren()) do
            local frame = item:FindFirstChild('Main_Frame')
            if frame and frame:FindFirstChild('Stock_Text') then
                local stockText = frame.Stock_Text.Text
                local count = tonumber(stockText:match('%d+')) or 0
                if ignoreNoStock then
                    if count > 0 then newList[item.Name] = count end
                else
                    SeedStock[item.Name] = count
                end
            end
        end
        return ignoreNoStock and newList or SeedStock
    end

    local function CanHarvest(plant)
        local prompt = plant:FindFirstChild('ProximityPrompt', true)
        if not prompt or not prompt.Enabled then return false end
        return true
    end

    local function ShouldHarvestPlant(plant)
        if HarvestByType and HarvestByType.Value and HarvestByType.Value ~= 'All' then
            if plant.Name ~= HarvestByType.Value then return false end
        end
        if HarvestByVariant and HarvestByVariant.Value and HarvestByVariant.Value ~= 'All' then
            local variant = plant:FindFirstChild('Variant')
            if not variant or variant.Value ~= HarvestByVariant.Value then return false end
            if variant.Value == 'Gold' or variant.Value == 'Rainbow' then
                SessionStats.MutationsFound = SessionStats.MutationsFound + 1
            end
        end
        return true
    end

    local function CollectHarvestable(parent, plants, ignoreDist)
        local c = LocalPlayer.Character; if not c then return plants end
        local pos = c:GetPivot().Position
        for _, child in ipairs(parent:GetChildren()) do
            local fruits = child:FindFirstChild('Fruits')
            if fruits then CollectHarvestable(fruits, plants, ignoreDist) end
            local ok, plantPos = pcall(function() return child:GetPivot().Position end)
            if ok and plantPos then
                local dist = (pos - plantPos).Magnitude
                if (ignoreDist or dist <= 15) and ShouldHarvestPlant(child) and CanHarvest(child) then
                    table.insert(plants, child)
                end
            end
        end
        return plants
    end

    local function GetHarvestablePlants(ignoreDist)
        local list = {}
        if PlantsPhysical then CollectHarvestable(PlantsPhysical, list, ignoreDist) end
        return list
    end

    local function HarvestPlants()
        if IsHarvesting then return end
        IsHarvesting = true
        for _, p in ipairs(GetHarvestablePlants()) do HarvestPlant(p) end
        IsHarvesting = false
    end

    local function AutoSellCheck()
        local cropCount = #GetInvCrops()
        if not (AutoSell and AutoSell.Value) then return end
        if cropCount < ((SellThreshold and SellThreshold.Value) or 15) then return end
        SellInventory()
    end

    local function AutoWalkLoop()
        if IsSelling or IsPlanting or IsHarvesting then return end
        local c = LocalPlayer.Character; if not c then return end
        local h = c:FindFirstChildOfClass('Humanoid'); if not h then return end
        local plants = GetHarvestablePlants(true)
        local randomAllowed = AutoWalkAllowRandom and AutoWalkAllowRandom.Value
        local doRandom = (#plants == 0) or math.random(1,3) == 2
        if randomAllowed and doRandom then
            h:MoveTo(GetRandomFarmPoint())
            return
        end
        for _, plant in ipairs(plants) do
            local ok, pos = pcall(function() return plant:GetPivot().Position end)
            if ok then h:MoveTo(pos) end
        end
    end

    local function NoclipLoop()
        if not (NoClip and NoClip.Value) then return end
        local c = LocalPlayer.Character; if not c then return end
        for _, part in ipairs(c:GetDescendants()) do
            if part:IsA('BasePart') then part.CanCollide = false end
        end
    end

    -- Loop helper
    local function MakeLoop(toggle, fn, baseInterval)
        task.spawn(function()
            while safewait(baseInterval or 0.05) do
                if toggle and toggle.Value then
                    local ok, err = pcall(fn)
                    if not ok then log('ERROR','Loop error: '..tostring(err)) end
                end
            end
        end)
    end

    -- Apply theme (Obsidian only; Rayfield may not have Scheme)
    pcall(function()
        if Library.Scheme then
            Library.Scheme.BackgroundColor = Accent.Brown
            Library.Scheme.MainColor = Accent.DarkGreen
            Library.Scheme.AccentColor = Accent.Green
        end
    end)

    -- Main window
    local Window = Library:CreateWindow({
        Title = GameInfo.Name .. ' | Enhanced Auto-Farm v2.1',
        Footer = 'Refactored stable bootstrap',
        Size = UDim2.fromOffset(580, 700),
        Icon = 'leaf',
        AutoShow = true,
        Center = true,
        Resizable = true,
    })

    if BootWindow then pcall(function() BootWindow:Destroy() end) BootWindow = nil BootLogBox = nil end

    -- TABS & UI (Reuse original structure) -------------------------------------------------
    local MainTab = Window:AddTab({Name='Auto Farm', Icon='tractor', Description='Enhanced farming automation'})
    local PlantGroupbox = MainTab:AddLeftGroupbox('Enhanced Auto-Plant 🌱','sprout')

    SelectedSeed = PlantGroupbox:AddDropdown('SelectedSeed',{Text='Select Seed Type', Values={'All'}, Multi=false, Default='All'})
    SelectedSeeds = PlantGroupbox:AddDropdown('SelectedSeeds',{Text='Multi-Seed Selection', Values={'All'}, Multi=true, Default={'All'}})
    AutoPlant = PlantGroupbox:AddToggle('AutoPlant',{Text='Auto Plant', Default=false})
    PlantAtPlayer = PlantGroupbox:AddToggle('PlantAtPlayer',{Text='Plant at Player Position', Default=false})
    PlantRadius = PlantGroupbox:AddSlider('PlantRadius',{Text='Plant Radius', Default=10, Min=5, Max=50, Rounding=0})
    AutoPlantRandom = PlantGroupbox:AddToggle('AutoPlantRandom',{Text='Include random points', Default=false})
    PlantGroupbox:AddButton({Text='Plant All Selected', Func=AutoPlantLoop, Tooltip='Plant all selected seed types'})

    local HarvestGroupbox = MainTab:AddRightGroupbox('Smart Auto-Harvest 🚜','wheat')
    AutoHarvest = HarvestGroupbox:AddToggle('AutoHarvest',{Text='Auto Harvest', Default=false})
    HarvestByType = HarvestGroupbox:AddDropdown('HarvestByType',{Text='Harvest Seed Types', Values={'All'}, Multi=false, Default='All'})
    HarvestByVariant = HarvestGroupbox:AddDropdown('HarvestByVariant',{Text='Harvest Variants', Values={'All','Normal','Gold','Rainbow'}, Multi=false, Default='All'})
    HarvestGroupbox:AddButton({Text='Harvest All Filtered', Func=HarvestPlants, Tooltip='Harvest based on current filters'})

    local ShopTab = Window:AddTab({Name='Smart Shopping', Icon='shopping-cart', Description='Automated purchasing system'})
    local SeedShopGroupbox = ShopTab:AddLeftGroupbox('Seed Shop 🌰','seedling')
    SelectedSeedStock = SeedShopGroupbox:AddDropdown('SelectedSeedStock',{Text='Select Seed to Buy', Values={}, Multi=false, Default=''})
    AutoBuy = SeedShopGroupbox:AddToggle('AutoBuy',{Text='Auto Buy Seeds', Default=false})
    OnlyShowStock = SeedShopGroupbox:AddToggle('OnlyShowStock',{Text='Only show in stock', Default=false})
    SeedShopGroupbox:AddButton({Text='Buy All Stock', Func=BuyAllSelectedSeeds})
    SeedShopGroupbox:AddButton({Text='Teleport to Seed Shop', Func=function() TeleportToPosition(NPCLocations.SeedShop) end})

    local GearShopGroupbox = ShopTab:AddRightGroupbox('Gear Shop ⚙️','tools')
    SelectedGear = GearShopGroupbox:AddDropdown('SelectedGear',{Text='Select Gear', Values={'Watering Can','Fertilizer','Shovel','Hoe'}, Multi=false, Default='Watering Can'})
    AutoGearBuy = GearShopGroupbox:AddToggle('AutoGearBuy',{Text='Auto Buy Gear', Default=false})
    GearShopGroupbox:AddButton({Text='Buy Selected Gear', Func=function() if SelectedGear and SelectedGear.Value then BuyGear(SelectedGear.Value) end end})
    GearShopGroupbox:AddButton({Text='Teleport to Gear Shop', Func=function() TeleportToPosition(NPCLocations.GearShop) end})

    local PetShopGroupbox = ShopTab:AddLeftGroupbox('Pet Shop 🥚','heart')
    SelectedEgg = PetShopGroupbox:AddDropdown('SelectedEgg',{Text='Select Egg Type', Values={'Basic Egg','Golden Egg','Rainbow Egg','Special Egg'}, Multi=false, Default='Basic Egg'})
    AutoEggBuy = PetShopGroupbox:AddToggle('AutoEggBuy',{Text='Auto Buy Eggs', Default=false})
    PetShopGroupbox:AddButton({Text='Buy Selected Egg', Func=function() if SelectedEgg and SelectedEgg.Value then BuyEgg(SelectedEgg.Value) end end})
    PetShopGroupbox:AddButton({Text='Teleport to Pet Shop', Func=function() TeleportToPosition(NPCLocations.PetShop) end})

    local TeleportTab = Window:AddTab({Name='Teleportation', Icon='map-pin', Description='Quick travel and navigation'})
    local TeleportGroupbox = TeleportTab:AddLeftGroupbox('Quick Teleports 🌀','zap')
    TeleportGroupbox:AddButton({Text='My Farm', Func=function() TeleportToPosition(NPCLocations.Farm) end})
    TeleportGroupbox:AddButton({Text='Sell Area', Func=function() TeleportToPosition(NPCLocations.SellArea) end})
    TeleportGroupbox:AddButton({Text='Beanstalk Event', Func=function() TeleportToPosition(NPCLocations.BeanstalkEvent) end})
    TeleportGroupbox:AddButton({Text='Return to Previous', Func=ReturnToPreviousPosition})

    local CustomTeleportGroupbox = TeleportTab:AddRightGroupbox('Custom Teleport 📍','target')
    local TeleportX = CustomTeleportGroupbox:AddSlider('TeleportX',{Text='X Coordinate', Default=0, Min=-1000, Max=1000})
    local TeleportY = CustomTeleportGroupbox:AddSlider('TeleportY',{Text='Y Coordinate', Default=4, Min=0, Max=100})
    local TeleportZ = CustomTeleportGroupbox:AddSlider('TeleportZ',{Text='Z Coordinate', Default=0, Min=-1000, Max=1000})
    CustomTeleportGroupbox:AddButton({Text='Teleport to Coordinates', Func=function()
        TeleportToPosition(Vector3.new(TeleportX.Value or 0, TeleportY.Value or 4, TeleportZ.Value or 0))
    end})

    local SellGroupbox = TeleportTab:AddLeftGroupbox('Smart Auto-Sell 💰','coins')
    SellGroupbox:AddButton({Text='Sell Inventory Now', Func=SellInventory})
    AutoSell = SellGroupbox:AddToggle('AutoSell',{Text='Auto Sell', Default=false})
    SellThreshold = SellGroupbox:AddSlider('SellThreshold',{Text='Sell at crop count', Default=15, Min=1, Max=199})

    local WalkTab = Window:AddTab({Name='Movement', Icon='footprints', Description='Automatic movement and pathfinding'})
    local WalkGroupbox = WalkTab:AddLeftGroupbox('Smart Auto-Walk 🚶','navigation')
    local AutoWalkStatus = WalkGroupbox:AddLabel('Status: Idle')
    AutoWalk = WalkGroupbox:AddToggle('AutoWalk',{Text='Auto Walk', Default=false, Callback=function(val) if not val then AutoWalkStatus:SetText('Status: Idle') end end})
    AutoWalkAllowRandom = WalkGroupbox:AddToggle('AutoWalkAllowRandom',{Text='Allow random movement', Default=true})
    NoClip = WalkGroupbox:AddToggle('NoClip',{Text='No Clip', Default=false})
    AutoWalkMaxWait = WalkGroupbox:AddSlider('AutoWalkMaxWait',{Text='Max delay (seconds)', Default=10, Min=1, Max=120})

    local StatsTab = Window:AddTab({Name='Statistics', Icon='bar-chart', Description='Session tracking and analytics'})
    local SessionGroupbox = StatsTab:AddLeftGroupbox('Session Statistics 📊','activity')
    StatusLabels.SessionTime = SessionGroupbox:AddLabel('Session: 00:00')
    StatusLabels.PlantsHarvested = SessionGroupbox:AddLabel('Harvested: 0')
    StatusLabels.TotalProfit = SessionGroupbox:AddLabel('Profit: $0')
    StatusLabels.MutationsFound = SessionGroupbox:AddLabel('Mutations: 0')

    local SessionStatsGroupbox = StatsTab:AddRightGroupbox('Activity Stats 🎯','target')
    local SeedsPlantedLabel = SessionStatsGroupbox:AddLabel('Seeds Planted: 0')
    local GearsUsedLabel = SessionStatsGroupbox:AddLabel('Gears Used: 0')
    local EggsOpenedLabel = SessionStatsGroupbox:AddLabel('Eggs Opened: 0')
    SessionStatsGroupbox:AddButton({Text='Reset Statistics', Func=function()
        SessionStats = {StartTime=tick(), PlantsHarvested=0, SeedsPlanted=0, TotalProfit=0, MutationsFound=0, GearsUsed=0, EggsOpened=0}
        UpdateSessionStats()
    end})

    local InventoryTab = Window:AddTab({Name='Inventory', Icon='package', Description='Smart inventory management'})
    local InventoryGroupbox = InventoryTab:AddLeftGroupbox('Inventory Manager 📦','package')
    local InventoryStatus = InventoryGroupbox:AddLabel('Inventory: 0/200')
    local SeedCountLabel = InventoryGroupbox:AddLabel('Seeds: 0')
    local CropCountLabel = InventoryGroupbox:AddLabel('Crops: 0')
    InventoryGroupbox:AddButton({Text='Update Inventory Info', Func=function()
        local crops = GetInvCrops()
        local seeds = GetOwnedSeeds()
        local totalSeeds = 0
        for _,data in pairs(seeds) do totalSeeds = totalSeeds + data.Count end
        InventoryStatus:SetText('Inventory: '..(#crops + totalSeeds)..'/200')
        SeedCountLabel:SetText('Seeds: '..totalSeeds)
        CropCountLabel:SetText('Crops: '..#crops)
    end})

    local KeybindTab = Window:AddTab({Name='Keybinds', Icon='keyboard', Description='Hotkey controls for quick actions'})
    local KeybindGroupbox = KeybindTab:AddLeftGroupbox('Quick Controls ⌨️','zap')
    KeybindGroupbox:AddLabel('F1 - Toggle Auto Plant')
    KeybindGroupbox:AddLabel('F2 - Toggle Auto Harvest')
    KeybindGroupbox:AddLabel('F3 - Sell Inventory')
    KeybindGroupbox:AddLabel('F4 - Emergency Stop All')
    local EmergencyStopActive = false
    KeybindGroupbox:AddButton({Text='Emergency Stop All', Func=function()
        EmergencyStopActive = true
        for _,tg in ipairs({AutoPlant,AutoHarvest,AutoWalk,AutoBuy,AutoSell,AutoGearBuy,AutoEggBuy}) do if tg then pcall(function() tg:SetValue(false) end) end end
        pcall(function() Library:Notify({Title='Emergency Stop', Description='All automation stopped!', Time=3}) end)
    end})

    -- Dropdown / stats update helpers
    local function UpdateDropdowns()
        local seeds = GetOwnedSeeds()
        local seedNames = {'All'}
        for sName,_ in pairs(seeds) do table.insert(seedNames, sName) end
        if SelectedSeed then SelectedSeed:SetValues(seedNames) end
        if SelectedSeeds then SelectedSeeds:SetValues(seedNames) end
        if HarvestByType then HarvestByType:SetValues(seedNames) end
        local stockList = GetSeedStock(OnlyShowStock and OnlyShowStock.Value or false)
        local stockValues = {}
        for s,_ in pairs(stockList) do table.insert(stockValues, s) end
        if SelectedSeedStock then SelectedSeedStock:SetValues(stockValues) end
    end
    local function UpdateExtendedStats()
        if SeedsPlantedLabel then SeedsPlantedLabel:SetText('Seeds Planted: '..SessionStats.SeedsPlanted) end
        if GearsUsedLabel then GearsUsedLabel:SetText('Gears Used: '..SessionStats.GearsUsed) end
        if EggsOpenedLabel then EggsOpenedLabel:SetText('Eggs Opened: '..SessionStats.EggsOpened) end
    end

    -- Automation loops
    MakeLoop(AutoWalk, function()
        AutoWalkLoop()
        safewait(math.random(1, (AutoWalkMaxWait and AutoWalkMaxWait.Value) or 10))
    end, 0.25)
    MakeLoop(AutoHarvest, HarvestPlants, 0.1)
    MakeLoop(AutoBuy, BuyAllSelectedSeeds, 1)
    MakeLoop(AutoPlant, AutoPlantLoop, 0.15)
    MakeLoop(AutoGearBuy, function() if SelectedGear and SelectedGear.Value then BuyGear(SelectedGear.Value); safewait(5) end end, 0.5)
    MakeLoop(AutoEggBuy, function() if SelectedEgg and SelectedEgg.Value then BuyEgg(SelectedEgg.Value); safewait(10) end end, 0.5)

    -- Passive update thread
    task.spawn(function()
        while safewait(0.5) do
            if EmergencyStopActive then safewait(1) else
                pcall(GetSeedStock)
                pcall(GetOwnedSeeds)
                UpdateSessionStats()
                UpdateExtendedStats()
                UpdateDropdowns()
            end
        end
    end)

    -- Keybinds
    UserInputService.InputBegan:Connect(function(input,gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.F1 and AutoPlant then AutoPlant:SetValue(not AutoPlant.Value) end
        if input.KeyCode == Enum.KeyCode.F2 and AutoHarvest then AutoHarvest:SetValue(not AutoHarvest.Value) end
        if input.KeyCode == Enum.KeyCode.F3 then SellInventory() end
        if input.KeyCode == Enum.KeyCode.F4 then
            EmergencyStopActive = not EmergencyStopActive
            if EmergencyStopActive then
                for _,tg in ipairs({AutoPlant,AutoHarvest,AutoWalk,AutoBuy,AutoSell}) do if tg then pcall(function() tg:SetValue(false) end) end end
            end
        end
    end)

    -- Connections
    RunService.Stepped:Connect(NoclipLoop)
    Backpack.ChildAdded:Connect(AutoSellCheck)

    -- Initial deferred updates
    task.spawn(function()
        safewait(2)
        UpdateDropdowns()
    end)

    -- Notifications
    pcall(function()
        Library:Notify({Title='Enhanced Auto Farm v2.1', Description='Stable refactored bootstrap loaded!', Time=4})
        Library:Notify({Title='Keybinds Active', Description='F1-F4 hotkeys ready.', Time=3})
    end)

    -- Health check (simple)
    task.spawn(function()
        while true do
            safewait(15)
            if not ReplicatedStorage:FindFirstChild('GameEvents') then
                log('WARN','HealthCheck: GameEvents missing (may have been reparented).')
            end
        end
    end) -- end health check task

end) -- end pcall main body

if not mainOk then
    bootlog('Main execution failed: '..tostring(mainErr), 'ERROR')
else
    bootlog('Initialization complete.')
end
