-- =====================================================
-- VÕ LÂM ANH HUB - BLOX FRUITS FULL PACK v6.1
-- Tác giả: palofsc
-- Client Name: Võ Lâm Anh Hub
-- Update: Thêm Auto Click (ClickDetector + ProximityPrompt + Button)
-- Chức năng: Auto Boss, Anti AFK, Fast Attack, Kill Aura,
--            Auto Farm, ESP, Fly, Noclip, Speed, Auto Click
-- =====================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ==== CONFIG ====
local Config = {
    AutoFarm = false,
    AutoQuest = false,
    AutoMastery = false,
    AutoCollect = false,
    AutoBoss = false,
    BossHop = false,
    AntiAFK = true,
    FastAttack = false,
    KillAura = false,
    AutoClick = false,
    AutoClickAll = false,
    ESP = false,
    Speed = false,
    Fly = false,
    Noclip = false,
    AttackSpeed = 0.01,
    AttackRange = 50,
    KillAuraRange = 35,
    CollectRange = 80,
    ClickRange = 50,
    ClickDelay = 0.1,
    SpeedValue = 100,
    FlySpeed = 150,
    SelectedBoss = "All",
    SelectedMastery = "Melee",
    FarmMethod = "Normal",
}

-- ==== BOSS LIST ====
local BossList = {
    "Greybeard", "Darkbeard", "Rip Indra", "Dough King", "Cursed Captain",
    "Order", "Longma", "Stone", "Bobby", "Yeti", "Snow Lurker",
    "Smoke Admiral", "Ice Admiral", "Vice Admiral", "Captain Elephant",
    "Saber Expert", "Wysper", "Thunder God", "Cake Queen", "Cake Prince",
    "Dough King Awakened"
}

-- ==== BIẾN ====
local flyConn, noclipConn, autoStatConn, afkConn
local ESPData = {}

-- ==== HELPERS ====
local function getChar() return LocalPlayer.Character end
local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- ==== GUI ====
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VoLamAnhHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
pcall(function() ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui", 10) end)
if not ScreenGui.Parent then ScreenGui.Parent = game:GetService("CoreGui") end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 400, 0, 580)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -290)
MainFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(255, 200, 0)
UIStroke.Thickness = 1.5
UIStroke.Transparency = 0.3
UIStroke.Parent = MainFrame

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 42)
TitleBar.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -110, 1, 0)
Title.Position = UDim2.new(0, 14, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚔ VÕ LÂM ANH HUB ⚔"
Title.TextColor3 = Color3.fromRGB(255, 200, 0)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.Parent = TitleBar

local VersionLbl = Instance.new("TextLabel")
VersionLbl.Size = UDim2.new(0, 60, 0, 14)
VersionLbl.Position = UDim2.new(0, 14, 0, 26)
VersionLbl.BackgroundTransparency = 1
VersionLbl.Text = "v6.1 | Blox Fruits"
VersionLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
VersionLbl.TextXAlignment = Enum.TextXAlignment.Left
VersionLbl.Font = Enum.Font.Gotham
VersionLbl.TextSize = 9
VersionLbl.Parent = TitleBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 32, 0, 32)
MinBtn.Position = UDim2.new(1, -74, 0, 5)
MinBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 18
MinBtn.BorderSizePixel = 0
MinBtn.Parent = TitleBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinBtn

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -38, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

local StatusLbl = Instance.new("TextLabel")
StatusLbl.Size = UDim2.new(1, -20, 0, 26)
StatusLbl.Position = UDim2.new(0, 10, 0, 48)
StatusLbl.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
StatusLbl.Text = "STATUS: IDLE | ANTI AFK: ON"
StatusLbl.TextColor3 = Color3.fromRGB(0, 255, 180)
StatusLbl.Font = Enum.Font.GothamSemibold
StatusLbl.TextSize = 11
StatusLbl.BorderSizePixel = 0
StatusLbl.Parent = MainFrame

local StatCorner = Instance.new("UICorner")
StatCorner.CornerRadius = UDim.new(0, 5)
StatCorner.Parent = StatusLbl

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -20, 1, -126)
ScrollFrame.Position = UDim2.new(0, 10, 0, 80)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 2400)
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.Parent = MainFrame

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 5)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = ScrollFrame

-- ==== UI BUILDERS ====
local function CreateSection(text)
    local L = Instance.new("TextLabel")
    L.Size = UDim2.new(1, 0, 0, 24)
    L.BackgroundTransparency = 1
    L.Text = "◆ " .. text .. " ◆"
    L.TextColor3 = Color3.fromRGB(255, 200, 0)
    L.Font = Enum.Font.GothamBold
    L.TextSize = 12
    L.Parent = ScrollFrame
end

local function CreateToggle(name, default, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 32)
    Btn.BackgroundColor3 = default and Color3.fromRGB(180, 120, 0) or Color3.fromRGB(28, 28, 38)
    Btn.Text = name .. ": " .. (default and "ON" or "OFF")
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.GothamSemibold
    Btn.TextSize = 12
    Btn.BorderSizePixel = 0
    Btn.Parent = ScrollFrame

    local C = Instance.new("UICorner")
    C.CornerRadius = UDim.new(0, 6)
    C.Parent = Btn

    local state = default
    Btn.MouseButton1Click:Connect(function()
        state = not state
        Btn.BackgroundColor3 = state and Color3.fromRGB(180, 120, 0) or Color3.fromRGB(28, 28, 38)
        Btn.Text = name .. ": " .. (state and "ON" or "OFF")
        pcall(callback, state)
    end)
end

local function CreateSlider(name, min, max, default, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 48)
    Frame.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    Frame.BorderSizePixel = 0
    Frame.Parent = ScrollFrame

    local C = Instance.new("UICorner")
    C.CornerRadius = UDim.new(0, 6)
    C.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -10, 0, 18)
    Label.Position = UDim2.new(0, 10, 0, 3)
    Label.BackgroundTransparency = 1
    Label.Text = name .. ": " .. default
    Label.TextColor3 = Color3.fromRGB(220, 220, 220)
    Label.Font = Enum.Font.GothamSemibold
    Label.TextSize = 11
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Bar = Instance.new("Frame")
    Bar.Size = UDim2.new(1, -20, 0, 10)
    Bar.Position = UDim2.new(0, 10, 0, 28)
    Bar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    Bar.BorderSizePixel = 0
    Bar.Parent = Frame

    local BarC = Instance.new("UICorner")
    BarC.CornerRadius = UDim.new(0, 5)
    BarC.Parent = Bar

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
    Fill.BorderSizePixel = 0
    Fill.Parent = Bar

    local FillC = Instance.new("UICorner")
    FillC.CornerRadius = UDim.new(0, 5)
    FillC.Parent = Fill

    local dragging = false
    Bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    Bar.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local relX = math.clamp((i.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + (max - min) * relX)
            Fill.Size = UDim2.new(relX, 0, 1, 0)
            Label.Text = name .. ": " .. val
            pcall(callback, val)
        end
    end)
end

local function CreateDropdown(name, options, default, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 32)
    Btn.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    Btn.Text = name .. ": " .. default
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.GothamSemibold
    Btn.TextSize = 12
    Btn.BorderSizePixel = 0
    Btn.Parent = ScrollFrame

    local C = Instance.new("UICorner")
    C.CornerRadius = UDim.new(0, 6)
    C.Parent = Btn

    local idx = 1
    for i, v in ipairs(options) do if v == default then idx = i end end

    Btn.MouseButton1Click:Connect(function()
        idx = idx + 1
        if idx > #options then idx = 1 end
        Btn.Text = name .. ": " .. options[idx]
        pcall(callback, options[idx])
    end)
end

-- ==== AUTO CLICK CORE ====
local function AutoClickTick()
    local myHrp = getHRP()
    if not myHrp then return end

    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local ok, d = pcall(function() return (obj.Position - myHrp.Position).Magnitude end)
            if ok and d and d <= Config.ClickRange then
                -- ClickDetector
                local cd = obj:FindFirstChildOfClass("ClickDetector")
                if cd then
                    pcall(function() fireclickdetector(cd) end)
                end
                -- ProximityPrompt
                local pp = obj:FindFirstChildOfClass("ProximityPrompt")
                if pp then
                    pcall(function() fireproximityprompt(pp) end)
                end
                -- Touch
                pcall(function()
                    for _, c in pairs(obj:GetChildren()) do
                        if c:IsA("TouchTransmitter") then
                            firetouchinterest(myHrp, obj, 0)
                            firetouchinterest(myHrp, obj, 1)
                        end
                    end
                end)
            end
        end
    end

    -- Auto click toàn bộ ClickDetector trong Workspace (không giới hạn khoảng cách)
    if Config.AutoClickAll then
        for _, obj in pairs(Workspace:GetDescendants()) do
            local cd = obj:FindFirstChildOfClass("ClickDetector")
            if cd then pcall(function() fireclickdetector(cd) end) end
            local pp = obj:FindFirstChildOfClass("ProximityPrompt")
            if pp then pcall(function() fireproximityprompt(pp) end) end
        end
    end
end

-- ==== CORE ====
local function FindBoss(bossName)
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj:IsA("Model") then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                if obj.Name:lower():match(bossName:lower()) then
                    return obj
                end
            end
        end
    end
    return nil
end

local function GetNearestEnemy(maxDist)
    maxDist = maxDist or 150
    local nearest, dist = nil, maxDist
    local myHrp = getHRP()
    if not myHrp then return nil end
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj ~= getChar() and obj:IsA("Model") then
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local d = (hrp.Position - myHrp.Position).Magnitude
                if d < dist then nearest, dist = obj, d end
            end
        end
    end
    return nearest
end

local function GetEquippedTool()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Tool")
end

local function EquipBestTool()
    local c = getChar()
    if not c then return nil end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if not bp then return nil end
    local priority = {"Fruit", "Sword", "Gun", "Melee"}
    for _, p in ipairs(priority) do
        for _, t in pairs(bp:GetChildren()) do
            if t:IsA("Tool") then
                local tip = string.lower(t.ToolTip or "")
                local nm = string.lower(t.Name)
                if tip:match(string.lower(p)) or nm:match(string.lower(p)) then
                    t.Parent = c
                    return t
                end
            end
        end
    end
    for _, t in pairs(bp:GetChildren()) do
        if t:IsA("Tool") then t.Parent = c return t end
    end
    return nil
end

local function AttackTarget(target)
    if not target then return end
    local hrp = target:FindFirstChild("HumanoidRootPart")
    local hum = target:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    local myHrp = getHRP()
    if not myHrp then return end

    pcall(function()
        if (hrp.Position - myHrp.Position).Magnitude > 8 then
            myHrp.CFrame = hrp.CFrame * CFrame.new(0, 0, 3)
        end
    end)

    local tool = GetEquippedTool() or EquipBestTool()
    if tool then pcall(function() tool:Activate() end) end

    pcall(function()
        hum:TakeDamage(50)
        if hum.Health <= 0 then hum.Health = 0 end
    end)

    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            for _, r in pairs(remotes:GetChildren()) do
                if r:IsA("RemoteEvent") and (r.Name:match("Attack") or r.Name:match("Hit") or r.Name:match("Damage")) then
                    r:FireServer(target)
                end
            end
        end
    end)
end

local function AutoBossTick()
    local targetBoss = nil
    if Config.SelectedBoss == "All" then
        for _, boss in ipairs(BossList) do
            local b = FindBoss(boss)
            if b then targetBoss = b break end
        end
    else
        targetBoss = FindBoss(Config.SelectedBoss)
    end

    if targetBoss then
        AttackTarget(targetBoss)
        local hum = targetBoss:FindFirstChildOfClass("Humanoid")
        StatusLbl.Text = "STATUS: BOSS | " .. targetBoss.Name .. " | HP: " .. math.floor(hum and hum.Health or 0)
    else
        StatusLbl.Text = "STATUS: BOSS | Đang tìm boss..."
    end
end

local function AutoFarmTick()
    local target = GetNearestEnemy(Config.AttackRange)
    if target then AttackTarget(target) end
end

local function KillAuraTick()
    local myHrp = getHRP()
    if not myHrp then return end
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj ~= getChar() and obj:IsA("Model") then
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                if (hrp.Position - myHrp.Position).Magnitude <= Config.KillAuraRange then
                    pcall(function() hum:TakeDamage(100) hum.Health = 0 end)
                    local tool = GetEquippedTool()
                    if tool then pcall(function() tool:Activate() end) end
                end
            end
        end
    end
end

local function AutoQuestTick()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end
    for _, g in pairs(pg:GetDescendants()) do
        if g:IsA("TextButton") and g.Visible then
            local t = string.lower(g.Text or "")
            if t:match("nhận") or t:match("quest") or t:match("start") or t:match("begin") then
                pcall(function() g:Activate() end)
            end
        end
    end
end

local function StartAntiAFK()
    pcall(function()
        LocalPlayer.Idled:Connect(function()
            VirtualUser:Button2Down(Vector2.new(0, 0), Camera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0, 0), Camera.CFrame)
        end)
    end)
    afkConn = task.spawn(function()
        while task.wait(60) do
            if Config.AntiAFK then
                pcall(function()
                    local hum = getHum()
                    if hum then hum.Jump = true task.wait(0.1) end
                end)
            end
        end
    end)
end

local function StartNoclip()
    noclipConn = RunService.Stepped:Connect(function()
        local c = getChar()
        if c then
            for _, p in pairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end)
end
local function StopNoclip()
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
end

local function StartFly()
    local c = getChar()
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp
    flyConn = RunService.RenderStepped:Connect(function()
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0, 1, 0) end
        bv.Velocity = dir * Config.FlySpeed
    end)
end
local function StopFly()
    if flyConn then flyConn:Disconnect() flyConn = nil end
    local hrp = getHRP()
    if hrp then
        local bv = hrp:FindFirstChildOfClass("BodyVelocity")
        if bv then bv:Destroy() end
    end
end

local function CreateESP(player)
    if player == LocalPlayer or ESPData[player] then return end
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    if not hrp then return end
    local H = Instance.new("Highlight")
    H.Adornee = char
    H.FillColor = Color3.fromRGB(255, 200, 0)
    H.OutlineColor = Color3.fromRGB(255, 255, 255)
    H.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    H.Parent = char
    local BB = Instance.new("BillboardGui")
    BB.Adornee = head or hrp
    BB.Size = UDim2.new(0, 180, 0, 36)
    BB.StudsOffset = Vector3.new(0, 3, 0)
    BB.AlwaysOnTop = true
    BB.Parent = char
    local NL = Instance.new("TextLabel")
    NL.Size = UDim2.new(1, 0, 1, 0)
    NL.BackgroundTransparency = 1
    NL.Text = player.Name
    NL.TextColor3 = Color3.fromRGB(255, 200, 0)
    NL.TextStrokeTransparency = 0
    NL.Font = Enum.Font.GothamBold
    NL.TextSize = 12
    NL.Parent = BB
    ESPData[player] = {H, BB}
end
local function RemoveESP(player)
    if ESPData[player] then
        for _, o in pairs(ESPData[player]) do
            if o and o.Parent then o:Destroy() end
        end
        ESPData[player] = nil
    end
end

-- ==== MENU ====
CreateSection("AUTO CLICK")

CreateToggle("Auto Click", false, function(v) Config.AutoClick = v end)
CreateToggle("Auto Click ALL (toàn map)", false, function(v) Config.AutoClickAll = v end)
CreateSlider("Click Range", 5, 200, 50, function(v) Config.ClickRange = v end)
CreateSlider("Click Delay (ms)", 10, 1000, 100, function(v) Config.ClickDelay = v / 1000 end)

CreateSection("BOSS HUNT")

CreateToggle("Auto Boss", false, function(v) Config.AutoBoss = v end)
CreateToggle("Boss Hop", false, function(v) Config.BossHop = v end)
CreateDropdown("Select Boss", {"All", "Greybeard", "Darkbeard", "Rip Indra", "Dough King",
    "Cursed Captain", "Longma", "Stone", "Yeti", "Snow Lurker", "Smoke Admiral",
    "Ice Admiral", "Vice Admiral", "Wysper", "Thunder God", "Cake Queen", "Cake Prince"}, "All",
    function(v) Config.SelectedBoss = v end)

CreateSection("ANTI AFK")

CreateToggle("Anti AFK", true, function(v)
    Config.AntiAFK = v
    StatusLbl.Text = "STATUS: IDLE | ANTI AFK: " .. (v and "ON" or "OFF")
end)

CreateSection("FAST ATTACK")

CreateToggle("Fast Attack", false, function(v) Config.FastAttack = v end)
CreateSlider("Attack Delay (ms)", 1, 200, 10, function(v) Config.AttackSpeed = v / 1000 end)
CreateSlider("Attack Range", 10, 200, 50, function(v) Config.AttackRange = v end)

CreateSection("AUTO FARM")

CreateToggle("Auto Farm", false, function(v) Config.AutoFarm = v end)
CreateToggle("Auto Quest", false, function(v) Config.AutoQuest = v end)
CreateSlider("Collect Range", 20, 200, 80, function(v) Config.CollectRange = v end)

CreateSection("COMBAT")

CreateToggle("Kill Aura", false, function(v) Config.KillAura = v end)
CreateSlider("Kill Aura Range", 5, 150, 35, function(v) Config.KillAuraRange = v end)

CreateSection("MOVEMENT")

CreateToggle("Speed Hack", false, function(v)
    Config.Speed = v
    if not v then
        local hum = getHum()
        if hum then hum.WalkSpeed = 16 end
    end
end)
CreateSlider("Speed Value", 16, 400, 100, function(v) Config.SpeedValue = v end)

CreateToggle("Fly", false, function(v)
    Config.Fly = v
    if v then StartFly() else StopFly() end
end)
CreateSlider("Fly Speed", 20, 600, 150, function(v) Config.FlySpeed = v end)

CreateToggle("Noclip", false, function(v)
    Config.Noclip = v
    if v then StartNoclip() else StopNoclip() end
end)

CreateSection("VISUAL")

CreateToggle("ESP Player", false, function(v)
    Config.ESP = v
    if v then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then CreateESP(p) end
        end
    else
        for p, _ in pairs(ESPData) do RemoveESP(p) end
    end
end)

-- ==== SỰ KIỆN ====
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(1)
        if Config.ESP then CreateESP(p) end
    end)
end)
Players.PlayerRemoving:Connect(function(p) RemoveESP(p) end)

-- ==== KHỞI ĐỘNG ====
StartAntiAFK()

-- Auto Click Thread
task.spawn(function()
    while task.wait(Config.ClickDelay) do
        if Config.AutoClick then pcall(AutoClickTick) end
    end
end)

-- Fast Attack Thread
task.spawn(function()
    while task.wait(Config.AttackSpeed) do
        if Config.FastAttack then
            local target = GetNearestEnemy(Config.AttackRange)
            if target then AttackTarget(target) end
        end
    end
end)

-- Boss Thread
task.spawn(function()
    while task.wait(0.2) do
        if Config.AutoBoss then pcall(AutoBossTick) end
    end
end)

-- Main Heartbeat
RunService.Heartbeat:Connect(function()
    if not LocalPlayer.Character then return end
    local myHrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end

    if Config.AutoFarm and not Config.FastAttack then pcall(AutoFarmTick) end
    if Config.AutoQuest then pcall(AutoQuestTick) end
    if Config.KillAura then pcall(KillAuraTick) end

    if Config.Speed then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = Config.SpeedValue end
    end
end)

-- ==== ĐIỀU KHIỂN ====
MinBtn.MouseButton1Click:Connect(function()
    for _, c in pairs(MainFrame:GetChildren()) do
        if c ~= TitleBar then c.Visible = not c.Visible end
    end
    MainFrame.Size = MainFrame.Size.Y.Offset == 580 and UDim2.new(0, 400, 0, 42) or UDim2.new(0, 400, 0, 580)
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

print("[VÕ LÂM ANH HUB] v6.1 loaded. Auto Click: ON/OFF | Toggle: RightShift")