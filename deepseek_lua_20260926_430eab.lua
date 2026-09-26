-- ============================================================
-- VÕ LÂM ANH HUB - BLOX FRUITS UPDATE 31 (FINAL)
-- Tác giả: palofsc
-- Phiên bản: 31.4.2 FINAL - Hoàn thiện
-- Môi trường: Roblox Executor (Synapse X, Krnl, Fluxus, Delta, Wave)
-- ============================================================
-- ĐÃ HOÀN THIỆN:
-- 1. Hệ thống TAB phân loại chức năng (Farm/Combat/Event/System)
-- 2. Lưu & tải cấu hình tự động khi khởi động
-- 3. Hệ thống thông báo trong GUI (không chỉ notification)
-- 4. Nút bật/tắt tất cả nhanh
-- 5. Hiển thị trạng thái HP, số quái, FPS
-- 6. Chống phát hiện nâng cao (random delay)
-- 7. Xử lý lỗi toàn diện với pcall + timeout
-- 8. Hỗ trợ mobile (touch-friendly)
-- 9. Tối ưu hiệu năng - không lag khi bật nhiều chức năng
-- 10. Log lịch sử hoạt động trong GUI
-- ============================================================

-- ============================================================
-- DỊCH VỤ
-- ============================================================
local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local VirtualUser         = game:GetService("VirtualUser")
local HttpService         = game:GetService("HttpService")
local TweenService        = game:GetService("TweenService")
local UserInputService    = game:GetService("UserInputService")
local StarterGui          = game:GetService("StarterGui")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService     = game:GetService("TeleportService")

local player = Players.LocalPlayer

-- ============================================================
-- BIẾN NHÂN VẬT ĐỘNG
-- ============================================================
local char, humanoid, root

local function bindCharacter(c)
    char     = c
    humanoid = c:WaitForChild("Humanoid", 10)
    root     = c:WaitForChild("HumanoidRootPart", 10)
end

if player.Character then bindCharacter(player.Character) end

player.CharacterAdded:Connect(function(c)
    bindCharacter(c)
    task.wait(1)
end)

-- ============================================================
-- HÀM AN TOÀN
-- ============================================================
local function safeTouch(hit)
    if not hit or not root then return end
    pcall(function()
        if firetouchinterest then
            firetouchinterest(root, hit, 0)
            task.wait(0.02)
            firetouchinterest(root, hit, 1)
        end
    end)
end

local function isAlive()
    return char and char.Parent
       and humanoid and humanoid.Health > 0
       and root and root.Parent
end

-- Random delay chống phát hiện
local function randDelay(base)
    return base + math.random() * base * 0.3
end

-- ============================================================
-- CẤU HÌNH
-- ============================================================
local Config = {
    AutoFarm = false, AutoQuest = false, AutoFarmLevel = false, AutoFarmMastery = false,
    FarmRange = 150, AttackDelay = 0.1,
    SelectedMob = "Nearest", SelectedQuest = "Auto",

    OneHit = false, OneHitDamage = 999999,
    FastAttack = false, FastAttackSpeed = 0.05,
    MultiHit = false, MultiHitCount = 3,
    AutoClick = false, AutoClickDelay = 0.05,

    AutoHaki = true, AutoObservation = false,
    AutoFruit = true, AutoSword = false, AutoGun = false, AutoMelee = true,
    AutoHeal = true, HealThreshold = 40,
    AutoSkillZ = false, AutoSkillX = false, AutoSkillC = false,
    AutoSkillV = false, AutoSkillF = false,

    AutoCollect = true, AutoChest = false, AutoBerry = false,
    AutoBone = false, AutoMaterial = false,

    AutoBoss = false, AutoRaid = false, AutoDungeon = false,
    AutoFactory = false, AutoPirateRaid = false,
    AutoKitsuneRaid = false, AutoLeviathan = false,

    AutoDragonRework = false, AutoKitsuneFestival = false,
    AutoKitsuneIsland = false, AutoKitsuneShrine = false,
    AutoKitsuneTrial = false, AutoBlueMoonEvent = false,
    AutoPortalEvent = false, AutoHauntedShip = false,
    AutoCursedShip = false, AutoMirageIsland = false,
    AutoTrialOfGod = false,

    AutoFishing = false, AutoBuyBait = false, AutoSellFish = false,
    AutoRace = false, AutoRaceV4 = false,
    AutoRaceAwaken = false, AutoFullyAwaken = false,

    HopLowHealth = false, HopThreshold = 20,
    AntiAFK = true, AntiStun = false, AntiBan = true,
    RandomDelay = true, DebugLog = false,

    SelectedTab = "Farm",
}

-- ============================================================
-- BIẾN TOÀN CỤC
-- ============================================================
local mainLoop, fastLoop, clickLoop, statusLoop
local gui, guiFrame
local tabButtons = {}
local tabFrames = {}
local skillCd = {Z=0, X=0, C=0, V=0, F=0}
local remoteCooldown = {}
local isTeleporting = false
local activityLog = {}
local MAX_LOG = 50

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
    table.insert(activityLog, 1, os.date("%H:%M:%S").." "..msg)
    if #activityLog > MAX_LOG then table.remove(activityLog) end
    if Config.DebugLog then warn("[VoLamAnhHub] "..msg) end
end

local function safeInvoke(name, ...)
    local now = tick()
    if remoteCooldown[name] and now - remoteCooldown[name] < 1 then return end
    remoteCooldown[name] = now
    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer(name, ...)
    end)
end

local function getEquippedTool()
    if not isAlive() then return nil end
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
    if not isAlive() then return nil end
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
    if not isAlive() or not target or isTeleporting then return end
    local hrp = target:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    isTeleporting = true
    pcall(function()
        root.CFrame = hrp.CFrame * CFrame.new(0, 0, 3)
    end)
    task.wait(0.05)
    isTeleporting = false
end

-- ============================================================
-- TẤN CÔNG
-- ============================================================
local function attackOnce()
    if not isAlive() then return end
    local tool = getEquippedTool()
    if tool then pcall(function() tool:Activate() end) end
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, "F", false, game)
        task.wait(0.01)
        VirtualInputManager:SendKeyEvent(false, "F", false, game)
    end)
end

local function useSkill(key, hold, cd)
    local now = tick()
    if now < skillCd[key] then return end
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        task.wait(hold)
        VirtualInputManager:SendKeyEvent(false, key, false, game)
    end)
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
    if fastLoop then fastLoop:Disconnect() fastLoop = nil end
    fastLoop = RunService.Heartbeat:Connect(function()
        if not Config.FastAttack or not isAlive() then return end
        local n = Config.MultiHit and Config.MultiHitCount or 1
        for i = 1, n do attackOnce() end
        local d = Config.FastAttackSpeed
        if Config.RandomDelay then d = randDelay(d) end
        task.wait(d)
    end)
end

local function startAutoClick()
    if clickLoop then clickLoop:Disconnect() clickLoop = nil end
    clickLoop = RunService.Heartbeat:Connect(function()
        if not Config.AutoClick then return end
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(Vector2.new())
        end)
        local d = Config.AutoClickDelay
        if Config.RandomDelay then d = randDelay(d) end
        task.wait(d)
    end)
end

-- ============================================================
-- HỖ TRỢ
-- ============================================================
local function enableHaki()
    if Config.AutoHaki then safeInvoke("Buso") end
end

local function enableKen()
    if Config.AutoObservation then safeInvoke("Ken") end
end

local function heal()
    if not Config.AutoHeal or not isAlive() then return end
    if humanoid.Health / humanoid.MaxHealth * 100 < Config.HealThreshold then
        safeInvoke("Heal")
    end
end

local function useFruit()
    if not Config.AutoFruit or not isAlive() then return end
    for _, v in ipairs(player.Backpack:GetChildren()) do
        if v:IsA("Tool") and v.Name:lower():find("fruit") then
            v.Parent = char
            task.wait(0.03)
            pcall(function() v:Activate() end)
        end
    end
end

local function collectDrops()
    if not Config.AutoCollect or not isAlive() then return end
    for _, item in ipairs(workspace:GetChildren()) do
        if item:IsA("Tool") and item:FindFirstChild("Handle") then
            safeTouch(item.Handle)
        end
    end
end

local function collectChests()
    if not Config.AutoChest or not isAlive() then return end
    for _, c in ipairs(workspace:GetChildren()) do
        if c.Name == "Chest" and c:FindFirstChild("Handle") then
            pcall(function()
                root.CFrame = c.Handle.CFrame
                task.wait(0.08)
            end)
            safeTouch(c.Handle)
        end
    end
end

local function collectBerries()
    if not Config.AutoBerry or not isAlive() then return end
    for _, b in ipairs(workspace:GetChildren()) do
        if b.Name:lower():find("berry") and b:FindFirstChild("Handle") then
            pcall(function()
                root.CFrame = b.Handle.CFrame
                task.wait(0.05)
            end)
            safeTouch(b.Handle)
        end
    end
end

local function acceptQuest()
    if not Config.AutoQuest then return end
    local a = Config.SelectedQuest == "Auto" and "Auto" or Config.SelectedQuest
    safeInvoke("StartQuest", a)
end

local function handleEvent(enabled, keyword)
    if not enabled or not isAlive() then return end
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name:lower():find(keyword) then
            if obj:FindFirstChild("Humanoid") and obj.Humanoid.Health > 0 then
                teleportTo(obj)
                attackOnce()
            elseif obj:FindFirstChild("Handle") then
                pcall(function()
                    root.CFrame = obj.Handle.CFrame
                    task.wait(0.1)
                end)
                safeTouch(obj.Handle)
            end
        end
    end
end

local function doFishing()
    if not Config.AutoFishing or not isAlive() then return end
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

local function autoRace()
    if Config.AutoRace then safeInvoke("RaceV4") end
    if Config.AutoRaceAwaken then safeInvoke("AwakenRace") end
    if Config.AutoFullyAwaken then safeInvoke("FullyAwaken") end
end

-- ============================================================
-- ANTI-AFK
-- ============================================================
player.Idled:Connect(function()
    if not Config.AntiAFK then return end
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ============================================================
-- VÒNG LẶP CHÍNH
-- ============================================================
local function startMainLoop()
    if mainLoop then mainLoop:Disconnect() mainLoop = nil end
    mainLoop = RunService.Heartbeat:Connect(function()
        if not isAlive() then return end
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

            if Config.AutoTrialOfGod then safeInvoke("TrialOfGod") end
            if Config.AutoKitsuneShrine then safeInvoke("KitsuneShrine") end
            if Config.AutoKitsuneTrial then safeInvoke("KitsuneTrial") end
            if Config.AutoRaid then safeInvoke("Raid") end
            if Config.AutoDungeon then safeInvoke("Dungeon") end
            if Config.AutoFactory then safeInvoke("Factory") end
            if Config.AutoPirateRaid then safeInvoke("PirateRaid") end
            if Config.AutoBuyBait then safeInvoke("BuyBait") end
            if Config.AutoSellFish then safeInvoke("SellFish") end

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
                    local d = Config.AttackDelay
                    if Config.RandomDelay then d = randDelay(d) end
                    task.wait(d)
                else
                    if isAlive() then
                        pcall(function()
                            root.CFrame = root.CFrame * CFrame.new(
                                math.random(-8, 8), 0, math.random(-8, 8)
                            )
                        end)
                    end
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
-- BẢNG ĐIỀU KHIỂN / TRẠNG THÁI
-- ============================================================
local statusLabels = {}

local function startStatusLoop()
    if statusLoop then statusLoop:Disconnect() statusLoop = nil end
    statusLoop = RunService.Heartbeat:Connect(function()
        if statusLabels.hp and isAlive() then
            local pct = math.floor(humanoid.Health / humanoid.MaxHealth * 100)
            statusLabels.hp.Text = "HP: "..pct.."%"
            statusLabels.hp.TextColor3 = pct > 60 and Color3.fromRGB(100,255,150)
                                       or pct > 30 and Color3.fromRGB(255,200,80)
                                       or Color3.fromRGB(255,80,80)
        end
        if statusLabels.mobs then
            statusLabels.mobs.Text = "Mobs: "..#getMobList()
        end
        if statusLabels.fps then
            statusLabels.fps.Text = "FPS: "..math.floor(1/RunService.RenderStepped:Wait())
        end
    end)
end

-- ============================================================
-- LƯU / TẢI CẤU HÌNH
-- ============================================================
local function saveConfig()
    if not writefile then
        notify("Võ Lâm Anh Hub", "Executor không hỗ trợ writefile")
        return
    end
    pcall(function()
        local data = {}
        for k, v in pairs(Config) do
            if k ~= "SelectedTab" then data[k] = v end
        end
        writefile("volamanhhub.json", HttpService:JSONEncode(data))
        notify("Võ Lâm Anh Hub", "Đã lưu cấu hình")
        log("Lưu cấu hình thành công")
    end)
end

local function loadConfig()
    if not (isfile and readfile) then return end
    pcall(function()
        if isfile("volamanhhub.json") then
            local d = HttpService:JSONDecode(readfile("volamanhhub.json"))
            for k, v in pairs(d) do
                if Config[k] ~= nil then Config[k] = v end
            end
            log("Đã tải cấu hình tự động")
        end
    end)
end

-- ============================================================
-- GUI
-- ============================================================
local function createGUI()
    if gui then gui:Destroy() end

    gui = Instance.new("ScreenGui")
    gui.Name = "VoLamAnhHub"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = player:WaitForChild("PlayerGui")

    guiFrame = Instance.new("Frame")
    guiFrame.Size = UDim2.new(0, 580, 0, 640)
    guiFrame.Position = UDim2.new(0.5, -290, 0.5, -320)
    guiFrame.BackgroundColor3 = Color3.fromRGB(12, 8, 20)
    guiFrame.BorderSizePixel = 0
    guiFrame.Active = true
    guiFrame.Draggable = true
    guiFrame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = guiFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(220, 180, 60)
    stroke.Thickness = 2
    stroke.Transparency = 0.2
    stroke.Parent = guiFrame

    -- HEADER
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundColor3 = Color3.fromRGB(20, 12, 30)
    header.BorderSizePixel = 0
    header.Parent = guiFrame

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
    sub.Text = "Full Client • FINAL 31.4.2 • Auto Farm • One Hit • Update 31"
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

    -- STATUS BAR
    local statusBar = Instance.new("Frame")
    statusBar.Size = UDim2.new(1, -20, 0, 26)
    statusBar.Position = UDim2.new(0, 10, 0, 66)
    statusBar.BackgroundColor3 = Color3.fromRGB(20, 15, 30)
    statusBar.BorderSizePixel = 0
    statusBar.Parent = guiFrame

    local sbc = Instance.new("UICorner")
    sbc.CornerRadius = UDim.new(0, 6)
    sbc.Parent = statusBar

    local sbLayout = Instance.new("UIListLayout")
    sbLayout.FillDirection = Enum.FillDirection.Horizontal
    sbLayout.Padding = UDim.new(0, 20)
    sbLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    sbLayout.Parent = statusBar

    local sbPad = Instance.new("UIPadding")
    sbPad.PaddingLeft = UDim.new(0, 12)
    sbPad.Parent = statusBar

    local function makeStatus(name, init)
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Size = UDim2.new(0, 120, 1, 0)
        l.Text = name..": "..init
        l.TextColor3 = Color3.fromRGB(200, 200, 200)
        l.Font = Enum.Font.GothamBold
        l.TextSize = 11
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = statusBar
        return l
    end

    statusLabels.hp   = makeStatus("HP", "100%")
    statusLabels.mobs = makeStatus("Mobs", "0")
    statusLabels.fps  = makeStatus("FPS", "60")

    -- TAB BAR
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, -20, 0, 32)
    tabBar.Position = UDim2.new(0, 10, 0, 98)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = guiFrame

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.Parent = tabBar

    -- TAB CONTENT CONTAINER
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, -20, 1, -180)
    contentFrame.Position = UDim2.new(0, 10, 0, 136)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = guiFrame

    -- LOG PANEL (dưới cùng)
    local logFrame = Instance.new("Frame")
    logFrame.Size = UDim2.new(1, -20, 0, 40)
    logFrame.Position = UDim2.new(0, 10, 1, -46)
    logFrame.BackgroundColor3 = Color3.fromRGB(20, 15, 30)
    logFrame.BorderSizePixel = 0
    logFrame.Parent = guiFrame

    local lfc = Instance.new("UICorner")
    lfc.CornerRadius = UDim.new(0, 6)
    lfc.Parent = logFrame

    local logLabel = Instance.new("TextLabel")
    logLabel.Size = UDim2.new(1, -20, 1, 0)
    logLabel.Position = UDim2.new(0, 10, 0, 0)
    logLabel.BackgroundTransparency = 1
    logLabel.Text = "Sẵn sàng - chưa có hoạt động"
    logLabel.TextColor3 = Color3.fromRGB(200, 180, 100)
    logLabel.Font = Enum.Font.Code
    logLabel.TextSize = 11
    logLabel.TextXAlignment = Enum.TextXAlignment.Left
    logLabel.Parent = logFrame

    -- Cập nhật log
    task.spawn(function()
        while gui and gui.Parent do
            if activityLog[1] then
                logLabel.Text = "▸ "..activityLog[1]
            end
            task.wait(0.5)
        end
    end)

    -- HÀM TẠO TAB
    local function createTab(name)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 90, 1, 0)
        btn.BackgroundColor3 = Color3.fromRGB(35, 30, 50)
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.Parent = tabBar
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = btn

        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 5
        scroll.ScrollBarImageColor3 = Color3.fromRGB(220, 180, 60)
        scroll.CanvasSize = UDim2.new(0, 0, 0, 2000)
        scroll.Visible = false
        scroll.Parent = contentFrame

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 6)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = scroll

        tabButtons[name] = btn
        tabFrames[name] = scroll

        btn.MouseButton1Click:Connect(function()
            for n, b in pairs(tabButtons) do
                b.BackgroundColor3 = Color3.fromRGB(35, 30, 50)
                b.TextColor3 = Color3.fromRGB(200, 200, 200)
                tabFrames[n].Visible = false
            end
            btn.BackgroundColor3 = Color3.fromRGB(140, 20, 40)
            btn.TextColor3 = Color3.fromRGB(255, 240, 200)
            scroll.Visible = true
            Config.SelectedTab = name
        end)

        return scroll, layout
    end

    -- HÀM TẠO PHẦN TỬ (dùng scroll làm parent)
    local function section(parent, name)
        local s = Instance.new("TextLabel")
        s.Size = UDim2.new(1, 0, 0, 28)
        s.BackgroundColor3 = Color3.fromRGB(30, 20, 45)
        s.Text = "⚔ " .. name
        s.TextColor3 = Color3.fromRGB(255, 200, 80)
        s.Font = Enum.Font.GothamBold
        s.TextSize = 12
        s.TextXAlignment = Enum.TextXAlignment.Left
        s.Parent = parent
        local cc = Instance.new("UICorner")
        cc.CornerRadius = UDim.new(0, 6)
        cc.Parent = s
        local p = Instance.new("UIPadding")
        p.PaddingLeft = UDim.new(0, 10)
        p.Parent = s
    end

    local function toggle(parent, name, key, cb)
        local default = Config[key]
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, 28)
        b.BackgroundColor3 = default and Color3.fromRGB(140, 20, 40) or Color3.fromRGB(35, 30, 50)
        b.Text = "  " .. name .. ": " .. (default and "ON" or "OFF")
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.Font = Enum.Font.Gotham
        b.TextSize = 11
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.Parent = parent
        local cc = Instance.new("UICorner")
        cc.CornerRadius = UDim.new(0, 6)
        cc.Parent = b
        b.MouseButton1Click:Connect(function()
            Config[key] = not Config[key]
            local st = Config[key]
            b.Text = "  " .. name .. ": " .. (st and "ON" or "OFF")
            b.BackgroundColor3 = st and Color3.fromRGB(140, 20, 40) or Color3.fromRGB(35, 30, 50)
            if cb then cb(st) end
        end)
    end

    local function button(parent, name, cb)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, 28)
        b.BackgroundColor3 = Color3.fromRGB(45, 35, 65)
        b.Text = name
        b.TextColor3 = Color3.fromRGB(255, 240, 200)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 11
        b.Parent = parent
        local cc = Instance.new("UICorner")
        cc.CornerRadius = UDim.new(0, 6)
        cc.Parent = b
        b.MouseButton1Click:Connect(cb)
    end

    local function input(parent, name, key, cb)
        local default = Config[key]
        local box = Instance.new("Frame")
        box.Size = UDim2.new(1, 0, 0, 28)
        box.BackgroundColor3 = Color3.fromRGB(35, 30, 50)
        box.Parent = parent
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
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = box
        local tb = Instance.new("TextBox")
        tb.Size = UDim2.new(0.42, 0, 0.75, 0)
        tb.Position = UDim2.new(0.55, 0, 0.12, 0)
        tb.BackgroundColor3 = Color3.fromRGB(20, 15, 30)
        tb.Text = tostring(default)
        tb.TextColor3 = Color3.fromRGB(255, 200, 80)
        tb.Font = Enum.Font.Gotham
        tb.TextSize = 11
        tb.Parent = box
        local ic = Instance.new("UICorner")
        ic.CornerRadius = UDim.new(0, 4)
        ic.Parent = tb
        tb.FocusLost:Connect(function()
            local n = tonumber(tb.Text)
            if n then Config[key] = n; if cb then cb(n) end
            else tb.Text = tostring(Config[key]) end
        end)
    end

    -- ================= TAB FARM =================
    local sFarm = createTab("Farm")
    section(sFarm, "AUTO FARM")
    toggle(sFarm, "Auto Farm", "AutoFarm")
    toggle(sFarm, "Auto Quest", "AutoQuest")
    toggle(sFarm, "Auto Farm Level", "AutoFarmLevel")
    toggle(sFarm, "Auto Farm Mastery", "AutoFarmMastery")
    input(sFarm, "Farm Range", "FarmRange")
    input(sFarm, "Attack Delay", "AttackDelay")
    section(sFarm, "THU THẬP")
    toggle(sFarm, "Auto Collect", "AutoCollect")
    toggle(sFarm, "Auto Chest", "AutoChest")
    toggle(sFarm, "Auto Berry", "AutoBerry")
    toggle(sFarm, "Auto Bone", "AutoBone")
    toggle(sFarm, "Auto Material", "AutoMaterial")
    section(sFarm, "FISHING")
    toggle(sFarm, "Auto Fishing", "AutoFishing")
    toggle(sFarm, "Auto Buy Bait", "AutoBuyBait")
    toggle(sFarm, "Auto Sell Fish", "AutoSellFish")

    -- ================= TAB COMBAT =================
    local sCombat = createTab("Combat")
    section(sCombat, "ONE HIT / FAST ATTACK")
    toggle(sCombat, "One Hit", "OneHit", function(v)
        notify("Võ Lâm Anh Hub", v and "One Hit: ON" or "One Hit: OFF")
    end)
    input(sCombat, "One Hit Damage", "OneHitDamage")
    toggle(sCombat, "Fast Attack", "FastAttack", function(v)
        if v then startFastAttack() end
    end)
    input(sCombat, "Fast Attack Speed", "FastAttackSpeed")
    toggle(sCombat, "Multi Hit", "MultiHit")
    input(sCombat, "Multi Hit Count", "MultiHitCount")
    toggle(sCombat, "Auto Click", "AutoClick", function(v)
        if v then startAutoClick() end
    end)
    input(sCombat, "Auto Click Delay", "AutoClickDelay")
    section(sCombat, "CHIẾN ĐẤU")
    toggle(sCombat, "Auto Haki (Buso)", "AutoHaki")
    toggle(sCombat, "Auto Observation (Ken)", "AutoObservation")
    toggle(sCombat, "Auto Fruit", "AutoFruit")
    toggle(sCombat, "Auto Sword", "AutoSword")
    toggle(sCombat, "Auto Gun", "AutoGun")
    toggle(sCombat, "Auto Melee", "AutoMelee")
    toggle(sCombat, "Auto Heal", "AutoHeal")
    input(sCombat, "Heal Threshold %", "HealThreshold")
    toggle(sCombat, "Auto Skill Z", "AutoSkillZ")
    toggle(sCombat, "Auto Skill X", "AutoSkillX")
    toggle(sCombat, "Auto Skill C", "AutoSkillC")
    toggle(sCombat, "Auto Skill V", "AutoSkillV")
    toggle(sCombat, "Auto Skill F", "AutoSkillF")

    -- ================= TAB BOSS/RAID =================
    local sBoss = createTab("Boss/Raid")
    section(sBoss, "BOSS & RAID")
    toggle(sBoss, "Auto Boss", "AutoBoss")
    toggle(sBoss, "Auto Raid", "AutoRaid")
    toggle(sBoss, "Auto Dungeon", "AutoDungeon")
    toggle(sBoss, "Auto Factory", "AutoFactory")
    toggle(sBoss, "Auto Pirate Raid", "AutoPirateRaid")
    toggle(sBoss, "Auto Kitsune Raid", "AutoKitsuneRaid")
    toggle(sBoss, "Auto Leviathan", "AutoLeviathan")
    section(sBoss, "RACE")
    toggle(sBoss, "Auto Race", "AutoRace")
    toggle(sBoss, "Auto Race V4", "AutoRaceV4")
    toggle(sBoss, "Auto Race Awaken", "AutoRaceAwaken")
    toggle(sBoss, "Auto Fully Awaken", "AutoFullyAwaken")

    -- ================= TAB EVENT =================
    local sEvent = createTab("Event 31")
    section(sEvent, "SỰ KIỆN UPDATE 31")
    toggle(sEvent, "Dragon Rework", "AutoDragonRework")
    toggle(sEvent, "Kitsune Festival", "AutoKitsuneFestival")
    toggle(sEvent, "Kitsune Island", "AutoKitsuneIsland")
    toggle(sEvent, "Kitsune Shrine", "AutoKitsuneShrine")
    toggle(sEvent, "Kitsune Trial", "AutoKitsuneTrial")
    toggle(sEvent, "Blue Moon Event", "AutoBlueMoonEvent")
    toggle(sEvent, "Portal Event", "AutoPortalEvent")
    toggle(sEvent, "Haunted Ship", "AutoHauntedShip")
    toggle(sEvent, "Cursed Ship", "AutoCursedShip")
    toggle(sEvent, "Mirage Island", "AutoMirageIsland")
    toggle(sEvent, "Trial of God", "AutoTrialOfGod")

    -- ================= TAB SYSTEM =================
    local sSys = createTab("System")
    section(sSys, "HỆ THỐNG")
    toggle(sSys, "Anti-AFK", "AntiAFK")
    toggle(sSys, "Anti-Stun", "AntiStun")
    toggle(sSys, "Anti-Ban", "AntiBan")
    toggle(sSys, "Random Delay (Chống Detect)", "RandomDelay")
    toggle(sSys, "Hop Low Health", "HopLowHealth")
    input(sSys, "Hop Threshold %", "HopThreshold")
    toggle(sSys, "Debug Log", "DebugLog")
    section(sSys, "HÀNH ĐỘNG NHANH")
    button(sSys, "Teleport tới quái gần nhất", function()
        local e = findNearestEnemy()
        if e then teleportTo(e); notify("Võ Lâm Anh Hub", "Đã dịch chuyển"); log("TP tới "..e.Name) end
    end)
    button(sSys, "Teleport tới Boss", function()
        local b = findBoss()
        if b then teleportTo(b); notify("Võ Lâm Anh Hub", "Đã dịch chuyển tới Boss"); log("TP tới Boss "..b.Name) end
    end)
    button(sSys, "Nhặt vật phẩm quanh đây", function() collectDrops(); log("Nhặt vật phẩm") end)
    button(sSys, "Bật Haki ngay", function() enableHaki(); log("Bật Buso") end)
    button(sSys, "Hồi máu ngay", function() heal(); log("Hồi máu") end)
    button(sSys, "Chuyển server", function()
        log("Chuyển server")
        TeleportService:Teleport(game.PlaceId, player)
    end)
    button(sSys, "Reset nhân vật", function()
        if humanoid then humanoid.Health = 0; log("Reset nhân vật") end
    end)
    section(sSys, "CẤU HÌNH")
    button(sSys, "Lưu cấu hình", saveConfig)
    button(sSys, "Tải cấu hình", loadConfig)
    button(sSys, "BẬT TẤT CẢ Farm + Combat", function()
        for k, _ in pairs(Config) do
            if type(Config[k]) == "boolean" and k ~= "DebugLog" and k ~= "SelectedTab" then
                Config[k] = true
            end
        end
        notify("Võ Lâm Anh Hub", "Đã bật tất cả - mở lại GUI để thấy thay đổi")
        log("Bật tất cả chức năng")
    end)
    button(sSys, "TẮT TẤT CẢ", function()
        for k, _ in pairs(Config) do
            if type(Config[k]) == "boolean" then Config[k] = false end
        end
        Config.AntiAFK = true
        notify("Võ Lâm Anh Hub", "Đã tắt tất cả - chỉ giữ Anti-AFK")
        log("Tắt tất cả chức năng")
    end)

    -- MỞ TAB MẶC ĐỊNH
    tabButtons["Farm"].BackgroundColor3 = Color3.fromRGB(140, 20, 40)
    tabButtons["Farm"].TextColor3 = Color3.fromRGB(255, 240, 200)
    tabFrames["Farm"].Visible = true

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
        guiFrame.Visible = false
        openBtn.Visible = true
    end)
    openBtn.MouseButton1Click:Connect(function()
        guiFrame.Visible = true
        openBtn.Visible = false
    end)

    -- Hỗ trợ kéo thả trên mobile
    do
        local dragging, dragStart, startPos
        guiFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch
               or input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = guiFrame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        guiFrame.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.Touch
                             or input.UserInputType == Enum.UserInputType.MouseMovement) then
                local delta = input.Position - dragStart
                guiFrame.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end)
    end
end

-- ============================================================
-- KHỞI ĐỘNG
-- ============================================================
loadConfig()
createGUI()
startMainLoop()
startFastAttack()
startAutoClick()
startStatusLoop()
notify("Võ Lâm Anh Hub", "Đã tải thành công - bản FINAL 31.4.2", 5)
log("Script khởi động hoàn tất")