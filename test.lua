-- ============================================================
-- VÕ LÂM ANH HUB - BLOX FRUITS UPDATE 31
-- Tác giả: palofsc
-- Phiên bản: 31.4 Full Client
-- Tính năng: Auto Farm, One Hit, Fast Attack, Boss, Raid,
--            Sự kiện mới nhất, Fishing, Race, GUI đầy đủ
-- Môi trường: Roblox Executor (Synapse X, Krnl, Fluxus, Delta)
-- ============================================================

-- ============================================================
-- DỊCH VỤ
-- ============================================================
local Players             = game:GetService("Players")
local RunService          =game:GetService("RunService")
local VirtualUser         = game:GetService("VirtualUser")
local HttpService         = game:GetService("HttpService")
local TweenService        = game:GetService("TweenService")
local UserInputService    = game:GetService("UserInputService")
local StarterGui          = game:GetService("StarterGui")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService     = game:GetService("TeleportService")

local player   = Players.LocalPlayer
local char     = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local root     = char:WaitForChild("HumanoidRootPart")

-- ============================================================
-- CẤU HÌNH MẶC ĐỊNH
-- ============================================================
local Config = {
    -- Farm
    AutoFarm        = false,
    AutoQuest       = false,
    AutoFarmLevel   = false,
    AutoFarmMastery = false,
    FarmRange       = 150,
    AttackDelay     = 0.1,
    SelectedMob     = "Nearest",
    SelectedQuest   = "Auto",

    -- One Hit / Fast Attack
    OneHit          = false,
    OneHitDamage    = 999999,
    FastAttack      = false,
    FastAttackSpeed = 0.02,
    MultiHit        = false,
    MultiHitCount   = 5,
    AutoClick       = false,
    AutoClickDelay  = 0.01,

    -- Chiến đấu
    AutoHaki        = true,
    AutoObservation = false,
    AutoFruit       = true,
    AutoSword       = false,
    AutoGun         = false,
    AutoMelee       = true,
    AutoHeal        = true,
    HealThreshold   = 40,
    AutoSkillZ      = false,
    AutoSkillX      = false,
    AutoSkillC      = false,
    AutoSkillV      = false,
    AutoSkillF      = false,

    -- Thu thập
    AutoCollect     = true,
    AutoChest       = false,
    AutoBerry       = false,
    AutoBone        = false,
    AutoMaterial    = false,

    -- Boss & Raid
    AutoBoss        = false,
    AutoRaid        = false,
    AutoDungeon     = false,
    AutoFactory     = false,
    AutoPirateRaid  = false,
    AutoKitsuneRaid = false,
    AutoLeviathan   = false,

    -- Sự kiện Update 31
    AutoDragonRework    = false,
    AutoKitsuneFestival = false,
    AutoKitsuneIsland   = false,
    AutoKitsuneShrine   = false,
    AutoKitsuneTrial    = false,
    AutoBlueMoonEvent   = false,
    AutoPortalEvent     = false,
    AutoHauntedShip     = false,
    AutoCursedShip      = false,
    AutoMirageIsland    = false,
    AutoTrialOfGod      = false,

    -- Fishing
    AutoFishing     = false,
    AutoBuyBait     = false,
    AutoSellFish    = false,

    -- Race
    AutoRace        = false,
    AutoRaceV4      = false,
    AutoRaceAwaken  = false,
    AutoFullyAwaken = false,

    -- Di chuyển
    HopLowHealth    = false,
    HopThreshold    = 20,
    AutoServerHop   = false,
    HopDelay        = 30,

    -- Anti
    AntiAFK         = true,
    AntiStun        = false,
    AntiBan         = true,

    -- UI
    Theme           = "VoLam",
    WebhookURL      = "",
    DebugLog        = false,
}

-- ============================================================
-- BIẾN TOÀN CỤC
-- ============================================================
local mainLoop    = nil
local fastLoop    = nil
local clickLoop   = nil
local gui         = nil
local skillCd     = {Z=0, X=0, C=0, V=0, F=0}

local BOSS_LIST = {
    "rip_indra","cyborg","darkbeard","greybeard","ice_admiral",
    "smoke_admiral","sword_dealer","magma_admiral","cursed_captain",
    "katakuri","king","queen","jack","kaido","big_mom","shanks",
    "dragon","kitsune","leviathan","soul_reaper","cursed_skull"
}

-- ============================================================
-- TIỆN ÍCH
-- ============================================================
local function notify(t, x, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = t, Text = x, Duration = dur or 3
        })
    end)
end

local function log(msg)
    if Config.DebugLog then warn("[VoLamAnhHub] "..msg) end
end

local function getEquippedTool()
    for _, t in ipairs(char:GetChildren()) do
        if t:IsA("Tool") then return t end
    end
    return nil
end

local function getMobList()
    local list = {}
    if workspace:FindFirstChild("Enemies") then
        for _, mob in ipairs(workspace.Enemies:GetChildren()) do
            if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0
               and mob:FindFirstChild("HumanoidRootPart") then
                table.insert(list, mob)
            end
        end
    end
    return list
end

local function findNearestEnemy()
    local closest, dist = nil, Config.FarmRange
    for _, mob in ipairs(getMobList()) do
        local d = (mob.HumanoidRootPart.Position - root.Position).Magnitude
        if d < dist then closest, dist = mob, d end
    end
    return closest
end

local function findEnemyByName(name)
    for _, mob in ipairs(getMobList()) do
        if mob.Name:lower():find(name:lower()) then return mob end
    end
    return nil
end

local function findBoss()
    for _, mob in ipairs(getMobList()) do
        for _, b in ipairs(BOSS_LIST) do
            if mob.Name:lower():find(b:lower()) then return mob end
        end
    end
    return nil
end

local function teleportTo(target)
    if target and target:FindFirstChild("HumanoidRootPart") then
        root.CFrame = target.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
    end
end

-- ============================================================
-- TẤN CÔNG
-- ============================================================
local function attackOnce()
    local tool = getEquippedTool()
    if tool then
        pcall(function() tool:Activate() end)
    end
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, "F", false, game)
        task.wait(0.01)
        VirtualInputManager:SendKeyEvent(false, "F", false, game)
    end)
end

local function useSkill(key, hold, cd)
    local now = tick()
    if now < skillCd[key] then return end
    VirtualInputManager:SendKeyEvent(true, key, false, game)
    task.wait(hold)
    VirtualInputManager:SendKeyEvent(false, key, false, game)
    skillCd[key] = now + cd
end

local function spamSkills()
    if Config.AutoSkillZ then useSkill("Z", 0.05, 0.6) end
    if Config.AutoSkillX then useSkill("X", 0.05, 0.6) end
    if Config.AutoSkillC then useSkill("C", 0.05, 0.6) end
    if Config.AutoSkillV then useSkill("V", 0.05, 0.6) end
    if Config.AutoSkillF then useSkill("F", 0.05, 0.6) end
end

local function applyOneHit(target)
    if not target or not target:FindFirstChild("Humanoid") then return end
    pcall(function() target.Humanoid.Health = 0 end)
    pcall(function() target.Humanoid.MaxHealth = 1 end)
    pcall(function()
        local r = ReplicatedStorage:FindFirstChild("Remotes")
        if r and r:FindFirstChild("CommF_") then
            r.CommF_:InvokeServer("Damage", target, Config.OneHitDamage)
        end
    end)
end

local function startFastAttack()
    if fastLoop then fastLoop:Disconnect() end
    fastLoop = RunService.Heartbeat:Connect(function()
        if not Config.FastAttack then return end
        if not humanoid or humanoid.Health <= 0 then return end
        local n = Config.MultiHit and Config.MultiHitCount or 1
        for i = 1, n do attackOnce() end
        task.wait(Config.FastAttackSpeed)
    end)
end

local function startAutoClick()
    if clickLoop then clickLoop:Disconnect() end
    clickLoop = RunService.Heartbeat:Connect(function()
        if not Config.AutoClick then return end
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(Vector2.new())
        end)
        task.wait(Config.AutoClickDelay)
    end)
end

-- ============================================================
-- HỖ TRỢ
-- ============================================================
local function enableHaki()
    if not Config.AutoHaki then return end
    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
    end)
end

local function enableKen()
    if not Config.AutoObservation then return end
    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("Ken")
    end)
end

local function heal()
    if not Config.AutoHeal then return end
    if humanoid.Health / humanoid.MaxHealth * 100 < Config.HealThreshold then
        pcall(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("Heal")
        end)
    end
end

local function useFruit()
    if not Config.AutoFruit then return end
    for _, v in ipairs(player.Backpack:GetChildren()) do
        if v:IsA("Tool") and v.Name:lower():find("fruit") then
            v.Parent = char
            task.wait(0.03)
            pcall(function() v:Activate() end)
        end
    end
end

local function collectDrops()
    if not Config.AutoCollect then return end
    for _, item in ipairs(workspace:GetChildren()) do
        if item:IsA("Tool") and item:FindFirstChild("Handle") then
            pcall(function()
                firetouchinterest(root, item.Handle, 0)
                task.wait(0.02)
                firetouchinterest(root, item.Handle, 1)
            end)
        end
    end
end

local function collectChests()
    if not Config.AutoChest then return end
    for _, c in ipairs(workspace:GetChildren()) do
        if c.Name == "Chest" and c:FindFirstChild("Handle") then
            pcall(function()
                root.CFrame = c.Handle.CFrame
                task.wait(0.08)
                firetouchinterest(root, c.Handle, 0)
                task.wait(0.03)
                firetouchinterest(root, c.Handle, 1)
            end)
        end
    end
end

local function collectBerries()
    if not Config.AutoBerry then return end
    for _, b in ipairs(workspace:GetChildren()) do
        if b.Name:lower():find("berry") and b:FindFirstChild("Handle") then
            pcall(function()
                root.CFrame = b.Handle.CFrame
                task.wait(0.05)
                firetouchinterest(root, b.Handle, 0)
                task.wait(0.03)
                firetouchinterest(root, b.Handle, 1)
            end)
        end
    end
end

local function acceptQuest()
    if not Config.AutoQuest then return end
    pcall(function()
        local a = Config.SelectedQuest == "Auto" and {"Auto"} or {Config.SelectedQuest}
        ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", unpack(a))
    end)
end

-- ============================================================
-- SỰ KIỆN UPDATE 31
-- ============================================================
local function handleEvent(enabled, keyword, hpFlag)
    if not enabled then return end
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name:lower():find(keyword) then
            if obj:FindFirstChild("Humanoid") and obj.Humanoid.Health > 0 then
                teleportTo(obj)
                attackOnce()
            elseif obj:FindFirstChild("Handle") then
                pcall(function()
                    root.CFrame = obj.Handle.CFrame
                    task.wait(0.1)
                    firetouchinterest(root, obj.Handle, 0)
                    task.wait(0.05)
                    firetouchinterest(root, obj.Handle, 1)
                end)
            end
        end
    end
end

local function invokeRemote(name)
    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer(name)
    end)
end

-- ============================================================
-- FISHING
-- ============================================================
local function doFishing()
    if not Config.AutoFishing then return end
    pcall(function()
        local rod = player.Backpack:FindFirstChild("Fishing Rod")
                    or char:FindFirstChild("Fishing Rod")
        if rod then
            rod.Parent = char
            task.wait(0.1)
            rod:Activate()
        end
    end)
end

-- ============================================================
-- RACE
-- ============================================================
local function autoRace()
    if Config.AutoRace then invokeRemote("RaceV4") end
    if Config.AutoRaceAwaken then invokeRemote("AwakenRace") end
end

-- ============================================================
-- ANTI-AFK
-- ============================================================
if Config.AntiAFK then
    player.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

-- ============================================================
-- HỒI SINH
-- ============================================================
player.CharacterAdded:Connect(function(c)
    char     = c
    humanoid = c:WaitForChild("Humanoid")
    root     = c:WaitForChild("HumanoidRootPart")
    task.wait(1)
    log("Nhân vật hồi sinh")
end)

-- ============================================================
-- VÒNG LẶP CHÍNH
-- ============================================================
local function startMainLoop()
    if mainLoop then mainLoop:Disconnect() end
    mainLoop = RunService.Heartbeat:Connect(function()
        if not humanoid or humanoid.Health <= 0 then return end
        pcall(function()
            enableHaki()
            enableKen()
            heal()
            collectDrops()
            collectChests()
            collectBerries()
            acceptQuest()
            doFishing()
            autoRace()

            -- Sự kiện Update 31
            handleEvent(Config.AutoDragonRework,    "dragon")
            handleEvent(Config.AutoKitsuneFestival, "kitsune")
            handleEvent(Config.AutoKitsuneIsland,   "kitsune")
            handleEvent(Config.AutoKitsuneShrine,   "shrine")
            handleEvent(Config.AutoKitsuneTrial,    "trial")
            handleEvent(Config.AutoBlueMoonEvent,   "blue")
            handleEvent(Config.AutoPortalEvent,     "portal")
            handleEvent(Config.AutoHauntedShip,     "haunted")
            handleEvent(Config.AutoCursedShip,      "cursed")
            handleEvent(Config.AutoMirageIsland,    "mirage")
            handleEvent(Config.AutoTrialOfGod,      "god")
            handleEvent(Config.AutoLeviathan,       "leviathan")
            handleEvent(Config.AutoKitsuneRaid,     "kitsune")

            if Config.AutoTrialOfGod then invokeRemote("TrialOfGod") end
            if Config.AutoKitsuneShrine then invokeRemote("KitsuneShrine") end
            if Config.AutoKitsuneTrial then invokeRemote("KitsuneTrial") end
            if Config.AutoRaid then invokeRemote("Raid") end
            if Config.AutoDungeon then invokeRemote("Dungeon") end
            if Config.AutoFactory then invokeRemote("Factory") end
            if Config.AutoPirateRaid then invokeRemote("PirateRaid") end
            if Config.AutoBuyBait then invokeRemote("BuyBait") end
            if Config.AutoSellFish then invokeRemote("SellFish") end
            if Config.AutoFullyAwaken then invokeRemote("FullyAwaken") end

            -- Farm
            if Config.AutoFarm then
                local enemy
                if Config.SelectedMob == "Nearest" then
                    enemy = findNearestEnemy()
                elseif Config.SelectedMob == "Boss" then
                    enemy = findBoss() or findNearestEnemy()
                else
                    enemy = findEnemyByName(Config.SelectedMob) or findNearestEnemy()
                end

                if enemy then
                    teleportTo(enemy)
                    useFruit()
                    spamSkills()
                    if Config.OneHit then applyOneHit(enemy) end
                    if not Config.FastAttack then attackOnce() end
                    task.wait(Config.AttackDelay)
                else
                    root.CFrame = root.CFrame * CFrame.new(
                        math.random(-8, 8), 0, math.random(-8, 8)
                    )
                    task.wait(0.3)
                end
            end

            if Config.HopLowHealth
               and humanoid.Health / humanoid.MaxHealth * 100 < Config.HopThreshold then
                notify("Võ Lâm Anh Hub", "Máu thấp - chuyển server")
                TeleportService:Teleport(game.PlaceId, player)
            end
        end)
    end)
end

-- ============================================================
-- GUI VÕ LÂM ANH HUB
-- ============================================================
local function createGUI()
    if gui then gui:Destroy() end

    gui = Instance.new("ScreenGui")
    gui.Name = "VoLamAnhHub"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = player:WaitForChild("PlayerGui")

    -- Khung chính
    local frame = Instance.new("Frame")
    frame.Name = "Main"
    frame.Size = UDim2.new(0, 540, 0, 620)
    frame.Position = UDim2.new(0.5, -270, 0.5, -310)
    frame.BackgroundColor3 = Color3.fromRGB(12, 8, 20)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(220, 180, 60)
    stroke.Thickness = 2
    stroke.Transparency = 0.2
    stroke.Parent = frame

    -- HEADER
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundColor3 = Color3.fromRGB(20, 12, 30)
    header.BorderSizePixel = 0
    header.Parent = frame

    local hc = Instance.new("UICorner")
    hc.CornerRadius = UDim.new(0, 14)
    hc.Parent = header

    local hgrad = Instance.new("UIGradient")
    hgrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 20, 40)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(220, 180, 60)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 40, 140))
    })
    hgrad.Rotation = 30
    hgrad.Parent = header

    local logo = Instance.new("TextLabel")
    logo.Size = UDim2.new(0, 44, 0, 44)
    logo.Position = UDim2.new(0, 10, 0, 8)
    logo.BackgroundTransparency = 1
    logo.Text = "⚔️"
    logo.TextSize = 30
    logo.Font = Enum.Font.GothamBold
    logo.Parent = header

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -60, 0, 26)
    title.Position = UDim2.new(0, 60, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = "VÕ LÂM ANH HUB - BLOX FRUITS 31"
    title.TextColor3 = Color3.fromRGB(255, 240, 200)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -60, 0, 18)
    sub.Position = UDim2.new(0, 60, 0, 34)
    sub.BackgroundTransparency = 1
    sub.Text = "Auto Farm • One Hit • Boss • Raid • Sự kiện Update 31"
    sub.TextColor3 = Color3.fromRGB(255, 220, 120)
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 10
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Parent = header

    local hide = Instance.new("TextButton")
    hide.Size = UDim2.new(0, 34, 0, 34)
    hide.Position = UDim2.new(1, -44, 0, 12)
    hide.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    hide.Text = "X"
    hide.TextColor3 = Color3.fromRGB(255, 255, 255)
    hide.Font = Enum.Font.GothamBold
    hide.TextSize = 14
    hide.Parent = header

    local hcc = Instance.new("UICorner")
    hcc.CornerRadius = UDim.new(0, 8)
    hcc.Parent = hide

    -- TAB BAR
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, -20, 0, 34)
    tabBar.Position = UDim2.new(0, 10, 0, 66)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = frame

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.Parent = tabBar

    -- SCROLL
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -110)
    scroll.Position = UDim2.new(0, 10, 0, 106)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 5
    scroll.ScrollBarImageColor3 = Color3.fromRGB(220, 180, 60)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 2400)
    scroll.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    -- HÀM TẠO PHẦN TỬ
    local function section(name)
        local s = Instance.new("TextLabel")
        s.Size = UDim2.new(1, 0, 0, 30)
        s.BackgroundColor3 = Color3.fromRGB(30, 20, 45)
        s.Text = "⚔ " .. name
        s.TextColor3 = Color3.fromRGB(255, 200, 80)
        s.Font = Enum.Font.GothamBold
        s.TextSize = 12
        s.TextXAlignment = Enum.TextXAlignment.Left
        s.Parent = scroll
        local cc = Instance.new("UICorner")
        cc.CornerRadius = UDim.new(0, 6)
        cc.Parent = s
        local p = Instance.new("UIPadding")
        p.PaddingLeft = UDim.new(0, 10)
        p.Parent = s
    end

    local function toggle(name, default, cb)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, 30)
        b.BackgroundColor3 = default and Color3.fromRGB(140, 20, 40) or Color3.fromRGB(35, 30, 50)
        b.Text = "  " .. name .. ": " .. (default and "ON" or "OFF")
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.Font = Enum.Font.Gotham
        b.TextSize = 12
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.Parent = scroll
        local cc = Instance.new("UICorner")
        cc.CornerRadius = UDim.new(0, 6)
        cc.Parent = b
        local st = default
        b.MouseButton1Click:Connect(function()
            st = not st
            b.Text = "  " .. name .. ": " .. (st and "ON" or "OFF")
            b.BackgroundColor3 = st and Color3.fromRGB(140, 20, 40) or Color3.fromRGB(35, 30, 50)
            cb(st)
        end)
    end

    local function button(name, cb)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, 30)
        b.BackgroundColor3 = Color3.fromRGB(45, 35, 65)
        b.Text = name
        b.TextColor3 = Color3.fromRGB(255, 240, 200)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 12
        b.Parent = scroll
        local cc = Instance.new("UICorner")
        cc.CornerRadius = UDim.new(0, 6)
        cc.Parent = b
        b.MouseButton1Click:Connect(cb)
    end

    local function input(name, default, cb)
        local box = Instance.new("Frame")
        box.Size = UDim2.new(1, 0, 0, 30)
        box.BackgroundColor3 = Color3.fromRGB(35, 30, 50)
        box.Parent = scroll
        local cc = Instance.new("UICorner")
        cc.CornerRadius = UDim.new(0, 6)
        cc.Parent = box
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.5, 0, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = box
        local tb = Instance.new("TextBox")
        tb.Size = UDim2.new(0.42, 0, 0.75, 0)
        tb.Position = UDim2.new(0.55, 0, 0.12, 0)
        tb.BackgroundColor3 = Color3.fromRGB(20, 15, 30)
        tb.Text = tostring(default)
        tb.TextColor3 = Color3.fromRGB(255, 200, 80)
        tb.Font = Enum.Font.Gotham
        tb.TextSize = 12
        tb.Parent = box
        local ic = Instance.new("UICorner")
        ic.CornerRadius = UDim.new(0, 4)
        ic.Parent = tb
        tb.FocusLost:Connect(function()
            local n = tonumber(tb.Text)
            if n then cb(n) else tb.Text = tostring(default) end
        end)
    end

    -- ============ FARM ============
    section("AUTO FARM")
    toggle("Auto Farm", Config.AutoFarm, function(v) Config.AutoFarm = v end)
    toggle("Auto Quest", Config.AutoQuest, function(v) Config.AutoQuest = v end)
    toggle("Auto Farm Level", Config.AutoFarmLevel, function(v) Config.AutoFarmLevel = v end)
    toggle("Auto Farm Mastery", Config.AutoFarmMastery, function(v) Config.AutoFarmMastery = v end)
    input("Farm Range", Config.FarmRange, function(v) Config.FarmRange = v end)
    input("Attack Delay", Config.AttackDelay, function(v) Config.AttackDelay = v end)

    -- ============ ONE HIT ============
    section("ONE HIT / FAST ATTACK")
    toggle("One Hit", Config.OneHit, function(v)
        Config.OneHit = v
        notify("Võ Lâm Anh Hub", v and "One Hit: ON" or "One Hit: OFF")
    end)
    input("One Hit Damage", Config.OneHitDamage, function(v) Config.OneHitDamage = v end)
    toggle("Fast Attack", Config.FastAttack, function(v)
        Config.FastAttack = v
        if v then startFastAttack() end
    end)
    input("Fast Attack Speed", Config.FastAttackSpeed, function(v) Config.FastAttackSpeed = v end)
    toggle("Multi Hit", Config.MultiHit, function(v) Config.MultiHit = v end)
    input("Multi Hit Count", Config.MultiHitCount, function(v) Config.MultiHitCount = v end)
    toggle("Auto Click", Config.AutoClick, function(v)
        Config.AutoClick = v
        if v then startAutoClick() end
    end)
    input("Auto Click Delay", Config.AutoClickDelay, function(v) Config.AutoClickDelay = v end)

    -- ============ CHIẾN ĐẤU ============
    section("CHIẾN ĐẤU")
    toggle("Auto Haki (Buso)", Config.AutoHaki, function(v) Config.AutoHaki = v end)
    toggle("Auto Observation (Ken)", Config.AutoObservation, function(v) Config.AutoObservation = v end)
    toggle("Auto Fruit", Config.AutoFruit, function(v) Config.AutoFruit = v end)
    toggle("Auto Sword", Config.AutoSword, function(v) Config.AutoSword = v end)
    toggle("Auto Gun", Config.AutoGun, function(v) Config.AutoGun = v end)
    toggle("Auto Melee", Config.AutoMelee, function(v) Config.AutoMelee = v end)
    toggle("Auto Heal", Config.AutoHeal, function(v) Config.AutoHeal = v end)
    input("Heal Threshold %", Config.HealThreshold, function(v) Config.HealThreshold = v end)
    toggle("Auto Skill Z", Config.AutoSkillZ, function(v) Config.AutoSkillZ = v end)
    toggle("Auto Skill X", Config.AutoSkillX, function(v) Config.AutoSkillX = v end)
    toggle("Auto Skill C", Config.AutoSkillC, function(v) Config.AutoSkillC = v end)
    toggle("Auto Skill V", Config.AutoSkillV, function(v) Config.AutoSkillV = v end)
    toggle("Auto Skill F", Config.AutoSkillF, function(v) Config.AutoSkillF = v end)

    -- ============ THU THẬP ============
    section("THU THẬP")
    toggle("Auto Collect", Config.AutoCollect, function(v) Config.AutoCollect = v end)
    toggle("Auto Chest", Config.AutoChest, function(v) Config.AutoChest = v end)
    toggle("Auto Berry", Config.AutoBerry, function(v) Config.AutoBerry = v end)
    toggle("Auto Bone", Config.AutoBone, function(v) Config.AutoBone = v end)
    toggle("Auto Material", Config.AutoMaterial, function(v) Config.AutoMaterial = v end)

    -- ============ BOSS & RAID ============
    section("BOSS & RAID")
    toggle("Auto Boss", Config.AutoBoss, function(v) Config.AutoBoss = v end)
    toggle("Auto Raid", Config.AutoRaid, function(v) Config.AutoRaid = v end)
    toggle("Auto Dungeon", Config.AutoDungeon, function(v) Config.AutoDungeon = v end)
    toggle("Auto Factory", Config.AutoFactory, function(v) Config.AutoFactory = v end)
    toggle("Auto Pirate Raid", Config.AutoPirateRaid, function(v) Config.AutoPirateRaid = v end)
    toggle("Auto Kitsune Raid", Config.AutoKitsuneRaid, function(v) Config.AutoKitsuneRaid = v end)
    toggle("Auto Leviathan", Config.AutoLeviathan, function(v) Config.AutoLeviathan = v end)

    -- ============ SỰ KIỆN UPDATE 31 ============
    section("SỰ KIỆN UPDATE 31")
    toggle("Dragon Rework", Config.AutoDragonRework, function(v) Config.AutoDragonRework = v end)
    toggle("Kitsune Festival", Config.AutoKitsuneFestival, function(v) Config.AutoKitsuneFestival = v end)
    toggle("Kitsune Island", Config.AutoKitsuneIsland, function(v) Config.AutoKitsuneIsland = v end)
    toggle("Kitsune Shrine", Config.AutoKitsuneShrine, function(v) Config.AutoKitsuneShrine = v end)
    toggle("Kitsune Trial", Config.AutoKitsuneTrial, function(v) Config.AutoKitsuneTrial = v end)
    toggle("Blue Moon Event", Config.AutoBlueMoonEvent, function(v) Config.AutoBlueMoonEvent = v end)
    toggle("Portal Event", Config.AutoPortalEvent, function(v) Config.AutoPortalEvent = v end)
    toggle("Haunted Ship", Config.AutoHauntedShip, function(v) Config.AutoHauntedShip = v end)
    toggle("Cursed Ship", Config.AutoCursedShip, function(v) Config.AutoCursedShip = v end)
    toggle("Mirage Island", Config.AutoMirageIsland, function(v) Config.AutoMirageIsland = v end)
    toggle("Trial of God", Config.AutoTrialOfGod, function(v) Config.AutoTrialOfGod = v end)

    -- ============ FISHING ============
    section("FISHING")
    toggle("Auto Fishing", Config.AutoFishing, function(v) Config.AutoFishing = v end)
    toggle("Auto Buy Bait", Config.AutoBuyBait, function(v) Config.AutoBuyBait = v end)
    toggle("Auto Sell Fish", Config.AutoSellFish, function(v) Config.AutoSellFish = v end)

    -- ============ RACE ============
    section("RACE")
    toggle("Auto Race", Config.AutoRace, function(v) Config.AutoRace = v end)
    toggle("Auto Race V4", Config.AutoRaceV4, function(v) Config.AutoRaceV4 = v end)
    toggle("Auto Race Awaken", Config.AutoRaceAwaken, function(v) Config.AutoRaceAwaken = v end)
    toggle("Auto Fully Awaken", Config.AutoFullyAwaken, function(v) Config.AutoFullyAwaken = v end)

    -- ============ HỆ THỐNG ============
    section("HỆ THỐNG")
    toggle("Anti-AFK", Config.AntiAFK, function(v) Config.AntiAFK = v end)
    toggle("Anti-Stun", Config.AntiStun, function(v) Config.AntiStun = v end)
    toggle("Anti-Ban", Config.AntiBan, function(v) Config.AntiBan = v end)
    toggle("Hop Low Health", Config.HopLowHealth, function(v) Config.HopLowHealth = v end)
    input("Hop Threshold %", Config.HopThreshold, function(v) Config.HopThreshold = v end)
    toggle("Debug Log", Config.DebugLog, function(v) Config.DebugLog = v end)

    -- ============ HÀNH ĐỘNG NHANH ============
    section("HÀNH ĐỘNG NHANH")
    button("Teleport tới quái gần nhất", function()
        local e = findNearestEnemy()
        if e then teleportTo(e) notify("Võ Lâm Anh Hub", "Đã dịch chuyển") end
    end)
    button("Teleport tới Boss", function()
        local b = findBoss()
        if b then teleportTo(b) notify("Võ Lâm Anh Hub", "Đã dịch chuyển tới Boss") end
    end)
    button("Nhặt vật phẩm quanh đây", function() collectDrops() end)
    button("Bật Haki ngay", function() enableHaki() end)
    button("Hồi máu ngay", function() heal() end)
    button("Chuyển server", function()
        TeleportService:Teleport(game.PlaceId, player)
    end)
    button("Reset nhân vật", function() humanoid.Health = 0 end)
    button("Lưu cấu hình", function()
        pcall(function()
            writefile("volamanhhub.json", HttpService:JSONEncode(Config))
            notify("Võ Lâm Anh Hub", "Đã lưu cấu hình")
        end)
    end)
    button("Tải cấu hình", function()
        pcall(function()
            if isfile and isfile("volamanhhub.json") then
                local d = HttpService:JSONDecode(readfile("volamanhhub.json"))
                for k, v in pairs(d) do Config[k] = v end
                notify("Võ Lâm Anh Hub", "Đã tải cấu hình")
            end
        end)
    end)

    -- NÚT MỞ LẠI
    local openBtn = Instance.new("TextButton")
    openBtn.Size = UDim2.new(0, 64, 0, 64)
    openBtn.Position = UDim2.new(0, 20, 0.5, -32)
    openBtn.BackgroundColor3 = Color3.fromRGB(180, 20, 40)
    openBtn.Text = "⚔️"
    openBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    openBtn.Font = Enum.Font.GothamBold
    openBtn.TextSize = 26
    openBtn.Visible = false
    openBtn.Parent = gui

    local obc = Instance.new("UICorner")
    obc.CornerRadius = UDim.new(1, 0)
    obc.Parent = openBtn

    local obs = Instance.new("UIStroke")
    obs.Color = Color3.fromRGB(220, 180, 60)
    obs.Thickness = 2
    obs.Parent = openBtn

    hide.MouseButton1Click:Connect(function()
        frame.Visible = false
        openBtn.Visible = true
    end)
    openBtn.MouseButton1Click:Connect(function()
        frame.Visible = true
        openBtn.Visible = false
    end)
end

-- ============================================================
-- KHỞI ĐỘNG
-- ============================================================
createGUI()
startMainLoop()
startFastAttack()
startAutoClick()
notify("Võ Lâm Anh Hub", "Đã tải thành công - Update 31 Full Client", 5)
log("Script khởi động hoàn tất")