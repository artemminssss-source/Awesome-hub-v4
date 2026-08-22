local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({
	Title = "AWESOME HUB",
	Footer = "https://t.me/AWESOME_HUB",
	Icon = 95816097006870,
	NotifySide = "Right",
	ShowCustomCursor = true,
	Center = true,
	AutoShow = true,
	Resizable = true,
	TabPadding = 10,
	CornerRadius = 10,
	Animations = {
		ToggleWindow = true,
		TabSwitch = true,
		Groupbox = true,
		Dropdown = true,
		KeyPicker = true
	},
	TabTransitionTime = 0.22,
	TabSwipeOffset = 26,
	TabSwipeFrom = "bottom",
	EnableSidebarResize = true,
	MinSidebarWidth = 200,
	SidebarCompactWidth = 56,
})

-- ===================== SERVICES =====================
local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ContentProvider = game:GetService("ContentProvider")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")

print("✅ AWESOME HUB LOADED!")

-- ===================== DEFAULT SETTINGS =====================
local defaultLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    GlobalShadows = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Ambient = Lighting.Ambient,
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd,
    FogColor = Lighting.FogColor
}

local DefaultSky = Lighting:FindFirstChildOfClass("Sky")
local DefaultSkySettings = {}
if DefaultSky then
    DefaultSkySettings.SkyboxBk = DefaultSky.SkyboxBk
    DefaultSkySettings.SkyboxDn = DefaultSky.SkyboxDn
    DefaultSkySettings.SkyboxFt = DefaultSky.SkyboxFt
    DefaultSkySettings.SkyboxLf = DefaultSky.SkyboxLf
    DefaultSkySettings.SkyboxRt = DefaultSky.SkyboxRt
    DefaultSkySettings.SkyboxUp = DefaultSky.SkyboxUp
end

-- ===================== RAGE VARIABLES =====================
local RageVars = {
    spinBotEnabled = false,
    autoRespawnEnabled = false,
    nightLightingEnabled = false,
    weaponSkinEnabled = false,
    bulletTracersEnabled = false,
    BunnyHop = false,
    BhopDelay = 0.05,
    Radar = false,
    Rejoin = false,
    ServerHop = false,
    AntiAFK = false,
    FPSBoost = false,
    SpiderClimb = false,
    FOVEnabled = false,
    FOVValue = 90,
    weaponTransparency = 0.35,
    weaponReflectance = 0.2,
    viewmodelChanger = false,
    viewmodelColor = Color3.fromRGB(140, 140, 245),
    viewmodelMaterial = "Neon",
}

-- ===================== SALIENT AIM VARIABLES =====================
local SalientAimVariables = {
    enabled = false,
    fov = 120,
    showFOVCircle = true,
    showSnapline = true,
    wallCheck = true,
    fovColor = Color3.fromRGB(255, 255, 255),
    fovTransparency = 0.8,
    fovThickness = 1.5,
    lineColor = Color3.fromRGB(255, 0, 0),
    lineTransparency = 0.9,
    lineThickness = 1.5,
    fovCircle = nil,
    snapLine = nil,
    bulletHandler = nil,
    oldFire = nil,
}

-- ===================== AIM BOT VARIABLES =====================
local AimBotVariables = {
    enabled = false,
    rainbow = false,
    rainbowSpeed = 5,
    color = Color3.fromRGB(255, 0, 0),
    radius = 50,
    lineWidth = 2,
    targetPart = "Head",
    smoothness = 0.15,
    mode = "Classic",
    connection = nil,
    line = nil,
    target = nil,
}

-- ===================== SALIENT AIM FUNCTIONS =====================
local function SalientAim_CreateDrawings()
    if not SalientAimVariables.fovCircle then
        SalientAimVariables.fovCircle = Drawing.new("Circle")
        SalientAimVariables.fovCircle.Thickness = SalientAimVariables.fovThickness
        SalientAimVariables.fovCircle.Color = SalientAimVariables.fovColor
        SalientAimVariables.fovCircle.Transparency = SalientAimVariables.fovTransparency
        SalientAimVariables.fovCircle.Filled = false
        SalientAimVariables.fovCircle.NumSides = 64
        SalientAimVariables.fovCircle.Visible = false
    end

    if not SalientAimVariables.snapLine then
        SalientAimVariables.snapLine = Drawing.new("Line")
        SalientAimVariables.snapLine.Thickness = SalientAimVariables.lineThickness
        SalientAimVariables.snapLine.Color = SalientAimVariables.lineColor
        SalientAimVariables.snapLine.Transparency = SalientAimVariables.lineTransparency
        SalientAimVariables.snapLine.Visible = false
    end
end

local function SalientAim_IsVisible(targetHead)
    if not SalientAimVariables.wallCheck then return true end
    local origin = camera.CFrame.Position
    local direction = (targetHead.Position - origin)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {player.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true
    local result = Workspace:Raycast(origin, direction, raycastParams)
    return result == nil or result.Instance:IsDescendantOf(targetHead.Parent)
end

local function SalientAim_GetClosestTarget()
    local closestPart, closestDist = nil, SalientAimVariables.fov

    for _, p in Players:GetPlayers() do
        if p == player then continue end
        local character = p.Character
        if not character then continue end
        local humanoid = character:FindFirstChild("Humanoid")
        local head = character:FindFirstChild("Head")
        if not head or not humanoid or humanoid.Health <= 0 then continue end

        local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
        if not onScreen then continue end

        local screenCenter = camera.ViewportSize / 2
        local distance = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude

        if distance < closestDist and SalientAim_IsVisible(head) then
            closestPart = head
            closestDist = distance
        end
    end
    return closestPart
end

local function SalientAim_UpdateDrawings(target)
    local center = camera.ViewportSize / 2

    if SalientAimVariables.showFOVCircle then
        SalientAimVariables.fovCircle.Visible = true
        SalientAimVariables.fovCircle.Position = center
        SalientAimVariables.fovCircle.Radius = SalientAimVariables.fov
        SalientAimVariables.fovCircle.Color = SalientAimVariables.fovColor
        SalientAimVariables.fovCircle.Transparency = SalientAimVariables.fovTransparency
        SalientAimVariables.fovCircle.Thickness = SalientAimVariables.fovThickness
    else
        SalientAimVariables.fovCircle.Visible = false
    end

    if SalientAimVariables.showSnapline and target then
        local screenPos = camera:WorldToViewportPoint(target.Position)
        SalientAimVariables.snapLine.Visible = true
        SalientAimVariables.snapLine.From = center
        SalientAimVariables.snapLine.To = Vector2.new(screenPos.X, screenPos.Y)
        SalientAimVariables.snapLine.Color = SalientAimVariables.lineColor
        SalientAimVariables.snapLine.Transparency = SalientAimVariables.lineTransparency
        SalientAimVariables.snapLine.Thickness = SalientAimVariables.lineThickness
    else
        SalientAimVariables.snapLine.Visible = false
    end
end

local function SalientAim_HookBulletHandler()
    if SalientAimVariables.bulletHandler then
        SalientAimVariables.oldFire = SalientAimVariables.bulletHandler.Fire
    else
        pcall(function()
            SalientAimVariables.bulletHandler = require(game:GetService("ReplicatedStorage").ModuleScripts.GunModules.BulletHandler)
            SalientAimVariables.oldFire = SalientAimVariables.bulletHandler.Fire
        end)
    end

    if not SalientAimVariables.bulletHandler then return end

    SalientAimVariables.bulletHandler.Fire = function(p6)
        if not SalientAimVariables.enabled or not p6 or typeof(p6) ~= "table" or not p6.Origin then
            return SalientAimVariables.oldFire(p6)
        end

        local targetHead = SalientAim_GetClosestTarget()

        if targetHead then
            local direction = (targetHead.Position - p6.Origin).Unit
            p6.Direction = direction
            if p6.Force then
                p6.Force = p6.Force * 20.224489795918366
            end
            if p6.Gravity then
                p6.Gravity = p6.Gravity * 0.6
            end
        end

        return SalientAimVariables.oldFire(p6)
    end
end

local function SalientAim_UnhookBulletHandler()
    if SalientAimVariables.bulletHandler and SalientAimVariables.oldFire then
        SalientAimVariables.bulletHandler.Fire = SalientAimVariables.oldFire
    end
end

local SalientAim_RenderConnection = nil

local function SalientAim_Toggle(value)
    SalientAimVariables.enabled = value

    if value then
        SalientAim_CreateDrawings()
        SalientAim_HookBulletHandler()

        if SalientAim_RenderConnection then
            SalientAim_RenderConnection:Disconnect()
        end

        SalientAim_RenderConnection = RunService.RenderStepped:Connect(function()
            if not SalientAimVariables.enabled then
                if SalientAimVariables.fovCircle then SalientAimVariables.fovCircle.Visible = false end
                if SalientAimVariables.snapLine then SalientAimVariables.snapLine.Visible = false end
                return
            end
            local target = SalientAim_GetClosestTarget()
            SalientAim_UpdateDrawings(target)
        end)
        print("✅ Salient Aim ENABLED")
    else
        if SalientAim_RenderConnection then
            SalientAim_RenderConnection:Disconnect()
            SalientAim_RenderConnection = nil
        end
        if SalientAimVariables.fovCircle then SalientAimVariables.fovCircle.Visible = false end
        if SalientAimVariables.snapLine then SalientAimVariables.snapLine.Visible = false end
        SalientAim_UnhookBulletHandler()
        print("❌ Salient Aim DISABLED")
    end
end

-- ===================== RAGE: VIEWMODEL CHANGER =====================
local function applyViewmodel()
    if not RageVars.viewmodelChanger then return end

    local color = RageVars.viewmodelColor or Color3.fromRGB(140, 140, 245)
    local material = Enum.Material[RageVars.viewmodelMaterial or "Neon"]

    local viewmodel = Workspace:FindFirstChild("ViewModel")
    if not viewmodel then return end

    local rightArm = viewmodel:FindFirstChild("Right Arm")
    local leftArm = viewmodel:FindFirstChild("Left Arm")

    if rightArm and rightArm:IsA("BasePart") then
        rightArm.Material = material
        rightArm.Color = color
    end

    if leftArm and leftArm:IsA("BasePart") then
        leftArm.Material = material
        leftArm.Color = color
    end
end

RunService.RenderStepped:Connect(applyViewmodel)

-- ===================== RAGE: NIGHT LIGHTING =====================
local nightBloom = nil
local nightSky = nil
local nightConnection = nil

local function setupNightLighting()
    Lighting.ClockTime = 13
    Lighting.Brightness = 0

    if not nightBloom then
        nightBloom = Instance.new("BloomEffect")
        nightBloom.Name = "NightBloom"
        nightBloom.Size = 24
        nightBloom.Intensity = 1
        nightBloom.Threshold = 0.9
        nightBloom.Parent = Lighting
    end

    if not nightSky then
        nightSky = Instance.new("Sky")
        nightSky.Name = "CustomSky"
        nightSky.SkyboxLf = "rbxassetid://12173273102"
        nightSky.SkyboxUp = "rbxassetid://12173274627"
        nightSky.SkyboxDn = "rbxassetid://12173271252"
        nightSky.SkyboxBk = "rbxassetid://12173268397"
        nightSky.SkyboxRt = "rbxassetid://12173273903"
        nightSky.SkyboxFt = "rbxassetid://12173272214"
        nightSky.Parent = Lighting
    end

    if nightConnection then nightConnection:Disconnect() end
    nightConnection = RunService.RenderStepped:Connect(function()
        if not RageVars.nightLightingEnabled then return end
        if Lighting.ClockTime ~= 13 then Lighting.ClockTime = 13 end
        if not Lighting:FindFirstChild("NightBloom") and nightBloom then nightBloom:Clone().Parent = Lighting end
        if not Lighting:FindFirstChild("CustomSky") and nightSky then nightSky:Clone().Parent = Lighting end
    end)
end

local function removeNightLighting()
    if nightConnection then nightConnection:Disconnect() nightConnection = nil end
    if nightBloom then nightBloom:Destroy() nightBloom = nil end
    if nightSky then nightSky:Destroy() nightSky = nil end
    for _, v in ipairs(Lighting:GetChildren()) do
        if v.Name == "NightBloom" or v.Name == "CustomSky" then v:Destroy() end
    end
    Lighting.ClockTime = defaultLighting.ClockTime
    Lighting.Brightness = defaultLighting.Brightness
end

-- ===================== RAGE: WEAPON SKIN =====================
local function applyWeaponSkin(tool)
    if not tool or not tool:IsA("Tool") then return end
    for _, v in ipairs(tool:GetDescendants()) do
        if v:IsA("BasePart") or v:IsA("MeshPart") or v:IsA("UnionOperation") then
            if v.Transparency < 1 and v.Name ~= "Handle" then
                v.Material = Enum.Material.Neon
                v.Color = Color3.fromRGB(140, 140, 245)
                v.Transparency = RageVars.weaponTransparency
                v.Reflectance = RageVars.weaponReflectance
                if v:IsA("UnionOperation") then v.UsePartColor = true end
            end
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        end
    end
end

local function updateWeapons()
    local character = player.Character
    if not character then return end
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") then applyWeaponSkin(tool) end
    end
end

RunService.RenderStepped:Connect(function()
    if RageVars.weaponSkinEnabled and player.Character then
        updateWeapons()
    end
end)

-- ===================== RAGE: BULLET TRACERS =====================
local function createBulletTracer(muzzle)
    if not muzzle or not muzzle.Parent then return end
    local bullet = Instance.new("Part")
    bullet.Size = Vector3.new(0.9, 0.5, 1)
    bullet.Color = Color3.fromRGB(140, 140, 245)
    bullet.Material = Enum.Material.Neon
    bullet.Anchored = false
    bullet.CanCollide = false
    bullet.CFrame = muzzle.CFrame
    bullet.CastShadow = false
    bullet.Parent = Workspace

    local att0 = Instance.new("Attachment", bullet)
    local att1 = Instance.new("Attachment", bullet)
    att0.Position = Vector3.new(0, 0, -0.15)
    att1.Position = Vector3.new(0, 0, 0.15)

    local trail = Instance.new("Trail")
    trail.Attachment0 = att0
    trail.Attachment1 = att1
    trail.FaceCamera = true
    trail.Lifetime = 3
    trail.LightEmission = 1
    trail.LightInfluence = 0
    trail.Brightness = 8
    trail.Color = ColorSequence.new(Color3.fromRGB(140, 140, 245))
    trail.Transparency = NumberSequence.new(0)
    trail.WidthScale = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.219),
        NumberSequenceKeypoint.new(1, 0.219)
    })
    trail.Enabled = true
    trail.Parent = bullet

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(100000, 100000, 100000)
    bv.Velocity = camera.CFrame.LookVector * 600
    bv.Parent = bullet

    Debris:AddItem(bullet, 13)
end

-- ===================== RAGE: CHARACTER HOOKS =====================
local function hookCharacter(char)
    task.wait(0.5)

    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait(0.3)
            if RageVars.weaponSkinEnabled then
                applyWeaponSkin(child)
            end
            if RageVars.bulletTracersEnabled then
                for _, v in ipairs(child:GetDescendants()) do
                    if v:IsA("BasePart") and (v.Name:find("Muzzle") or v.Name:find("Muz")) then
                        pcall(function()
                            v.AncestryChanged:Connect(function()
                                if v.Parent and RageVars.bulletTracersEnabled then
                                    createBulletTracer(v)
                                end
                            end)
                        end)
                    end
                end
            end
        end
    end)
end

player.CharacterAdded:Connect(hookCharacter)
if player.Character then
    hookCharacter(player.Character)
    for _, tool in ipairs(player.Character:GetChildren()) do
        if tool:IsA("Tool") then
            if RageVars.weaponSkinEnabled then applyWeaponSkin(tool) end
            if RageVars.bulletTracersEnabled then
                for _, v in ipairs(tool:GetDescendants()) do
                    if v:IsA("BasePart") and (v.Name:find("Muzzle") or v.Name:find("Muz")) then
                        pcall(function()
                            v.AncestryChanged:Connect(function()
                                if v.Parent and RageVars.bulletTracersEnabled then
                                    createBulletTracer(v)
                                end
                            end)
                        end)
                    end
                end
            end
        end
    end
end

-- ===================== RAGE: SPIN BOT =====================
task.spawn(function()
    while true do
        if RageVars.spinBotEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local root = player.Character.HumanoidRootPart
            root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(50), 0)
        end
        task.wait(0.01)
    end
end)

-- ===================== RAGE: AUTO RESPAWN =====================
local function firePlay()
    pcall(function()
        game:GetService("ReplicatedStorage").Remotes.Command:FireServer("Play")
    end)
end

pcall(function()
    game:GetService("ReplicatedStorage").Remotes.Death.OnClientEvent:Connect(function(id)
        if id == player.UserId and RageVars.autoRespawnEnabled then
            task.wait(0.3)
            firePlay()
        end
    end)
end)

task.spawn(function()
    while true do
        task.wait(0.2)
        if RageVars.autoRespawnEnabled then
            local char = player.Character
            local hum = char and char:FindFirstChild("Humanoid")
            if not char or (hum and hum.Health <= 0) then
                firePlay()
                task.wait(1.5)
            end
        end
    end
end)

-- ===================== RAGE: BUNNY HOP =====================
local lastJump = 0

RunService.Heartbeat:Connect(function()
    if not RageVars.BunnyHop then return end

    local char = player.Character
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    local state = hum:GetState()
    if state == Enum.HumanoidStateType.Landed or state == Enum.HumanoidStateType.Running then
        local now = tick()
        local delay = RageVars.BhopDelay or 0.05
        if now - lastJump >= delay then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            lastJump = now
        end
    end
end)

-- ===================== RAGE: RADAR =====================
local RADAR_SIZE = 150
local RADAR_RANGE = 200
local DOT_SIZE = 6

local radarGui = Instance.new("ScreenGui")
radarGui.Name = "Radar"
radarGui.ResetOnSpawn = false
radarGui.IgnoreGuiInset = true
radarGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function()
    radarGui.Parent = game:GetService("CoreGui")
end)
if not radarGui.Parent then
    radarGui.Parent = player:WaitForChild("PlayerGui")
end

local radarFrame = Instance.new("Frame")
radarFrame.Name = "Radar"
radarFrame.Size = UDim2.fromOffset(RADAR_SIZE, RADAR_SIZE)
radarFrame.Position = UDim2.new(1, -RADAR_SIZE - 20, 0, 20)
radarFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
radarFrame.BackgroundTransparency = 0.3
radarFrame.BorderSizePixel = 0
radarFrame.Visible = false
radarFrame.Parent = radarGui

local radarCorner = Instance.new("UICorner")
radarCorner.CornerRadius = UDim.new(1, 0)
radarCorner.Parent = radarFrame

local radarStroke = Instance.new("UIStroke")
radarStroke.Thickness = 2
radarStroke.Color = Color3.fromRGB(170, 0, 255)
radarStroke.Parent = radarFrame

local function makeRadarLabel(text, pos)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromOffset(20, 16)
    label.AnchorPoint = Vector2.new(0.5, 0.5)
    label.Position = pos
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 210)
    label.TextSize = 12
    label.Font = Enum.Font.GothamBold
    label.Parent = radarFrame
end

makeRadarLabel("N", UDim2.new(0.5, 0, 0, 10))
makeRadarLabel("E", UDim2.new(1, -10, 0.5, 0))
makeRadarLabel("S", UDim2.new(0.5, 0, 1, -10))
makeRadarLabel("W", UDim2.new(0, 10, 0.5, 0))

local radarArrow = Instance.new("TextLabel")
radarArrow.Name = "Arrow"
radarArrow.Size = UDim2.fromOffset(20, 20)
radarArrow.AnchorPoint = Vector2.new(0.5, 0.5)
radarArrow.Position = UDim2.fromScale(0.5, 0.5)
radarArrow.BackgroundTransparency = 1
radarArrow.Text = "▲"
radarArrow.TextColor3 = Color3.fromRGB(100, 255, 100)
radarArrow.TextSize = 18
radarArrow.Font = Enum.Font.GothamBold
radarArrow.ZIndex = 5
radarArrow.Parent = radarFrame

local radarDots = {}

local function getRadarDot(plr)
    if radarDots[plr] then
        return radarDots[plr]
    end

    local dot = Instance.new("Frame")
    dot.Name = plr.Name
    dot.Size = UDim2.fromOffset(DOT_SIZE, DOT_SIZE)
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    dot.BorderSizePixel = 0
    dot.Visible = false
    dot.Parent = radarFrame

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = dot

    radarDots[plr] = dot
    return dot
end

local function clearRadarDot(plr)
    if radarDots[plr] then
        radarDots[plr]:Destroy()
        radarDots[plr] = nil
    end
end

Players.PlayerRemoving:Connect(clearRadarDot)

RunService.RenderStepped:Connect(function()
    if not RageVars.Radar then
        radarFrame.Visible = false
        return
    end

    radarFrame.Visible = true

    local char = player.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local cam = Workspace.CurrentCamera
    if not cam then return end

    local look = cam.CFrame.LookVector
    local yaw = math.deg(math.atan2(-look.X, -look.Z))
    radarArrow.Rotation = yaw

    local myPos = hrp.Position

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == player then continue end

        local pChar = plr.Character
        local pHrp = pChar and pChar:FindFirstChild("HumanoidRootPart")
        local hum = pChar and pChar:FindFirstChildOfClass("Humanoid")

        if not pHrp or not hum or hum.Health <= 0 then
            if radarDots[plr] then
                radarDots[plr].Visible = false
            end
            continue
        end

        local offset = pHrp.Position - myPos
        local dist = offset.Magnitude

        if dist > RADAR_RANGE then
            if radarDots[plr] then
                radarDots[plr].Visible = false
            end
            continue
        end

        local scale = (RADAR_SIZE / 2) / RADAR_RANGE
        local x = offset.X * scale
        local y = -offset.Z * scale

        local radius = RADAR_SIZE / 2 - DOT_SIZE
        local mag = math.sqrt(x * x + y * y)
        if mag > radius then
            x = x / mag * radius
            y = y / mag * radius
        end

        local dot = getRadarDot(plr)
        dot.Position = UDim2.new(0.5, x, 0.5, y)
        dot.Visible = true
    end
end)

-- ===================== RAGE: ANTI AFK =====================
task.spawn(function()
    while true do
        task.wait(30)
        if RageVars.AntiAFK then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end
end)

-- ===================== RAGE: FPS BOOST =====================
local function applyFPSBoost(enabled)
    if enabled then
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            UserSettings():GetService("UserGameSettings").SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
        end)
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                obj.Enabled = false
            end
        end
    end
end

-- ===================== RAGE: SERVER HOP / REJOIN =====================
local function serverHop()
    local placeId = game.PlaceId
    local servers = {}
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"))
    end)
    if success and result and result.data then
        for _, server in ipairs(result.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                table.insert(servers, server.id)
            end
        end
    end
    if #servers > 0 then
        TeleportService:TeleportToPlaceInstance(placeId, servers[math.random(1, #servers)], player)
    else
        TeleportService:Teleport(placeId, player)
    end
end

local function rejoin()
    TeleportService:Teleport(game.PlaceId, player)
end

task.spawn(function()
    local lastHop = RageVars.ServerHop
    local lastRejoin = RageVars.Rejoin
    local lastFPS = RageVars.FPSBoost

    while true do
        task.wait(0.2)

        if RageVars.FPSBoost ~= lastFPS then
            lastFPS = RageVars.FPSBoost
            applyFPSBoost(lastFPS)
        end

        if RageVars.ServerHop and not lastHop then
            serverHop()
        end
        lastHop = RageVars.ServerHop

        if RageVars.Rejoin and not lastRejoin then
            rejoin()
        end
        lastRejoin = RageVars.Rejoin
    end
end)

-- ===================== RAGE: FOV CHANGER =====================
RunService.RenderStepped:Connect(function()
    if RageVars.FOVEnabled then
        Workspace.CurrentCamera.FieldOfView = RageVars.FOVValue or 90
    end
end)

-- ===================== RAGE: SPIDER CLIMB =====================
RunService.Heartbeat:Connect(function()
    if not RageVars.SpiderClimb then return end

    local char = player.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {char}
    params.FilterType = Enum.RaycastFilterType.Exclude

    local dirs = {
        hrp.CFrame.LookVector,
        -hrp.CFrame.LookVector,
        hrp.CFrame.RightVector,
        -hrp.CFrame.RightVector
    }

    for _, dir in ipairs(dirs) do
        local result = Workspace:Raycast(hrp.Position, dir * 2, params)
        if result then
            hum:ChangeState(Enum.HumanoidStateType.Climbing)
            hrp.Velocity = Vector3.new(hrp.Velocity.X, 20, hrp.Velocity.Z)
            break
        end
    end
end)

-- ===================== AIM BOT FUNCTIONS =====================
local function AimBot_CanSeeTarget(origin, targetPos, targetPlayer)
    local direction = (targetPos - origin).Unit
    local distance = (targetPos - origin).Magnitude

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local ignoreList = {}
    for _, p in ipairs(game.Players:GetPlayers()) do
        if p.Character then
            table.insert(ignoreList, p.Character)
        end
    end
    raycastParams.FilterDescendantsInstances = ignoreList

    local result = workspace:Raycast(origin, direction * distance, raycastParams)

    if result then
        return false
    end
    return true
end

local function AimBot_GetTargets()
    local targets = {}
    local character = player.Character
    if not character then return targets end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return targets end

    local head = character:FindFirstChild("Head")
    local origin = head and head.Position or hrp.Position

    for _, otherPlayer in ipairs(game.Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local otherChar = otherPlayer.Character
            local otherHrp = otherChar:FindFirstChild("HumanoidRootPart")
            if otherHrp and otherChar:FindFirstChild("Humanoid") and otherChar.Humanoid.Health > 0 then
                local targetPart = otherChar:FindFirstChild(AimBotVariables.targetPart) or otherHrp
                local distance = (hrp.Position - otherHrp.Position).Magnitude

                if distance <= AimBotVariables.radius then
                    local canSee = AimBot_CanSeeTarget(origin, targetPart.Position, otherPlayer)
                    if canSee then
                        table.insert(targets, {
                            Player = otherPlayer,
                            Character = otherChar,
                            Part = targetPart,
                            Distance = distance
                        })
                    end
                end
            end
        end
    end

    table.sort(targets, function(a, b) return a.Distance < b.Distance end)
    return targets
end

local function AimBot_GetClosestToCrosshair()
    local targets = AimBot_GetTargets()
    if #targets == 0 then return nil end

    local bestTarget = nil
    local bestScore = math.huge

    for _, target in ipairs(targets) do
        local screenPos, onScreen = camera:WorldToViewportPoint(target.Part.Position)
        if onScreen then
            local centerX, centerY = camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2
            local distanceFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(centerX, centerY)).Magnitude
            local distanceWeight = target.Distance / AimBotVariables.radius
            local score = distanceFromCenter * 0.7 + distanceWeight * 0.3

            if score < bestScore then
                bestScore = score
                bestTarget = target
            end
        end
    end

    return bestTarget
end

local function AimBot_UpdateLine()
    if not AimBotVariables.line then
        AimBotVariables.line = Drawing.new("Line")
        AimBotVariables.line.ZIndex = 999
        AimBotVariables.line.Thickness = AimBotVariables.lineWidth
        AimBotVariables.line.Color = AimBotVariables.color
        AimBotVariables.line.Visible = false
        AimBotVariables.line.Transparency = 0.7
    end

    local line = AimBotVariables.line
    local target = AimBotVariables.target

    if not AimBotVariables.enabled or not target then
        line.Visible = false
        return
    end

    local character = player.Character
    if not character then
        line.Visible = false
        return
    end

    local head = character:FindFirstChild("Head")
    if not head then
        line.Visible = false
        return
    end

    local targetPart = target.Part
    if not targetPart or not targetPart.Parent then
        line.Visible = false
        return
    end

    local headScreen = camera:WorldToViewportPoint(head.Position)
    local targetScreen = camera:WorldToViewportPoint(targetPart.Position)

    if headScreen and targetScreen then
        line.From = Vector2.new(headScreen.X, headScreen.Y)
        line.To = Vector2.new(targetScreen.X, targetScreen.Y)

        if AimBotVariables.rainbow then
            line.Color = Color3.fromHSV(tick() % AimBotVariables.rainbowSpeed / AimBotVariables.rainbowSpeed, 1, 1)
        else
            line.Color = AimBotVariables.color
        end

        line.Thickness = AimBotVariables.lineWidth
        line.Visible = true
    else
        line.Visible = false
    end
end

local function AimBot_Aim()
    if not AimBotVariables.enabled then
        AimBotVariables.target = nil
        if AimBotVariables.line then AimBotVariables.line.Visible = false end
        return
    end

    local character = player.Character
    if not character then
        AimBotVariables.target = nil
        if AimBotVariables.line then AimBotVariables.line.Visible = false end
        return
    end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        AimBotVariables.target = nil
        if AimBotVariables.line then AimBotVariables.line.Visible = false end
        return
    end

    local currentTarget = AimBotVariables.target
    local targetStillValid = false

    if currentTarget then
        local head = character:FindFirstChild("Head")
        local origin = head and head.Position or hrp.Position

        if currentTarget.Part and currentTarget.Part.Parent then
            local canSee = AimBot_CanSeeTarget(origin, currentTarget.Part.Position, currentTarget.Player)
            local distance = (hrp.Position - currentTarget.Part.Position).Magnitude

            if canSee and distance <= AimBotVariables.radius and currentTarget.Character and currentTarget.Character:FindFirstChild("Humanoid") and currentTarget.Character.Humanoid.Health > 0 then
                targetStillValid = true
            end
        end
    end

    if not targetStillValid then
        AimBotVariables.target = AimBot_GetClosestToCrosshair()
    end

    local target = AimBotVariables.target

    if not target then
        if AimBotVariables.line then AimBotVariables.line.Visible = false end
        return
    end

    local targetPos = target.Part.Position
    local currentCFrame = camera.CFrame
    local lookAt = CFrame.lookAt(currentCFrame.Position, targetPos)

    if AimBotVariables.mode == "Smooth" then
        camera.CFrame = camera.CFrame:Lerp(lookAt, AimBotVariables.smoothness)
    else
        camera.CFrame = lookAt
    end
end

local function AimBot_Toggle(value)
    AimBotVariables.enabled = value

    if value then
        if AimBotVariables.connection then
            AimBotVariables.connection:Disconnect()
        end
        AimBotVariables.connection = RunService.Heartbeat:Connect(function()
            AimBot_Aim()
            AimBot_UpdateLine()
        end)
        print("✅ Aim Bot ENABLED")
    else
        if AimBotVariables.connection then
            AimBotVariables.connection:Disconnect()
            AimBotVariables.connection = nil
        end
        if AimBotVariables.line then
            AimBotVariables.line.Visible = false
        end
        AimBotVariables.target = nil
        print("❌ Aim Bot DISABLED")
    end
end

-- ===================== AURA MODELS =====================
local AuraModels = {
    'Godly',
    'Super Sayien',
    'North Star',
    'Blue Lord',
    'Pink Aura',
    'Angel Wing',
    'Sweet Heart',
    'Ethereal Aura',
}

local AuraModelIDs = {
    ['Godly'] = 'rbxassetid://16699750981',
    ['Super Sayien'] = 'rbxassetid://116109508364297',
    ['North Star'] = 'rbxassetid://83945069652732',
    ['Blue Lord'] = 'rbxassetid://10974316799',
    ['Pink Aura'] = 'rbxassetid://115980859615239',
    ['Angel Wing'] = 'rbxassetid://90022969696073',
    ['Sweet Heart'] = 'rbxassetid://91724768175470',
    ['Ethereal Aura'] = 'rbxassetid://97041568674250',
}

local activeClassicAuras = {}

-- ===================== PARTICLE AURA DATA =====================
local PARTICLE_AURA_DATA = {
    { "starlight", "rbxassetid://134645216613107" },
    { "heavenly", "rbxassetid://139300897520961" },
    { "ribbon", "rbxassetid://132069507632161" },
    { "sakura", "rbxassetid://81755778619404" },
    { "angel", "rbxassetid://97658130917593" },
    { "wind", "rbxassetid://80694081850877" },
    { "flow", "rbxassetid://119913533725648" },
    { "star", "rbxassetid://73754563740680" },
    { "neon", "rbxassetid://18498709246" },
}

local PARTICLE_AURA_NAMES = {}
local particleAuraIdByName = {}

for _, row in ipairs(PARTICLE_AURA_DATA) do
    table.insert(PARTICLE_AURA_NAMES, row[1])
    particleAuraIdByName[row[1]] = row[2]
end

local loadedParticleAuras = {}
local activeParticleAuras = {}

-- ===================== SKYBOX ASSETS =====================
local SkyboxAssets = {
    ["HD"] = {
        Bk = "http://www.roblox.com/asset/?id=16553658937", Dn = "http://www.roblox.com/asset/?id=16553660713",
        Ft = "http://www.roblox.com/asset/?id=16553662144", Lf = "http://www.roblox.com/asset/?id=16553664042",
        Rt = "http://www.roblox.com/asset/?id=16553665766", Up = "http://www.roblox.com/asset/?id=16553667750"
    },
    ["Space"] = {
        Bk = "http://www.roblox.com/asset/?id=166509999", Dn = "http://www.roblox.com/asset/?id=166510057",
        Ft = "http://www.roblox.com/asset/?id=166510116", Lf = "http://www.roblox.com/asset/?id=166510092",
        Rt = "http://www.roblox.com/asset/?id=166510131", Up = "http://www.roblox.com/asset/?id=166510114"
    },
    ["Sunset"] = {
        Bk = "rbxassetid://600830446", Dn = "rbxassetid://600831635",
        Ft = "rbxassetid://600832720", Lf = "rbxassetid://600886090",
        Rt = "rbxassetid://600833862", Up = "rbxassetid://600835177"
    },
    ["Pink"] = {
        Bk = "rbxassetid://12216109205", Dn = "rbxassetid://12216109875",
        Ft = "rbxassetid://12216109489", Lf = "rbxassetid://12216110170",
        Rt = "rbxassetid://12216110471", Up = "rbxassetid://12216108877"
    },
    ["Roblox Default"] = {
        Bk = "rbxasset://textures/sky/sky512_bk.tex", Dn = "rbxasset://textures/sky/sky512_dn.tex",
        Ft = "rbxasset://textures/sky/sky512_ft.tex", Lf = "rbxasset://textures/sky/sky512_lf.tex",
        Rt = "rbxasset://textures/sky/sky512_rt.tex", Up = "rbxasset://textures/sky/sky512_up.tex"
    },
}

-- ===================== HAT VARIABLES =====================
local HatVariables = {
    enabled = false,
    style = "Classic",
    transparency = 0.3,
    rainbow = false,
    rainbowSpeed = 5,
    color = Color3.fromRGB(0, 255, 255),
    radius = 2.4,
    height = 1.6,
    reflectance = 0,
    sides = 25,
    parts = {},
    connection = nil,
}

local tau = math.pi * 2
local drawings = {}

for i = 1, HatVariables.sides do
    drawings[i] = {Drawing.new('Line'), Drawing.new('Triangle')}
    drawings[i][1].ZIndex = 2
    drawings[i][1].Thickness = 2
    drawings[i][2].ZIndex = 1
    drawings[i][2].Filled = true
end

-- ===================== TRAIL VARIABLES =====================
local TrailVariables = {
    enabled = false,
    isGradient = false,
    lifetime = 0.5,
    transparencyStart = 0,
    rainbow = false,
    colorStatic = Color3.fromRGB(0, 255, 255),
    gradient1 = Color3.fromRGB(0, 86, 255),
    gradient2 = Color3.fromRGB(255, 0, 0),
    parts = {},
    connection = nil,
}

-- ===================== AURA TRAILER VARIABLES =====================
local AuraTrailerVariables = {
    enabled = false,
    color = Color3.fromRGB(255, 0, 0),
    lifetime = 0.5,
}

-- ===================== FORCE FIELD VARIABLES =====================
local ForceFieldVariables = {
    enabled = false,
    color = Color3.fromRGB(128, 128, 128),
    rainbow = false,
    originalColors = {},
    connection = nil,
}

-- ===================== WORLD VARIABLES =====================
local WorldVariables = {
    screenEnabled = false,
    screenIntensity = 0,
    screenConnection = nil,
    timeEnabled = false,
    timeValue = 12,
    fullBrightEnabled = false,
}

-- ===================== SKYBOX VARIABLES =====================
local SkyboxVariables = {
    current = "HD",
    customEnabled = false,
}

-- ===================== ANIME VARIABLES =====================
local AnimeVariables = {
    enabled = false,
    gui = nil,
}

-- ===================== FPS/PING VARIABLES =====================
local FPSVariables = {
    fpsPing1Enabled = false,
    fpsPing2Enabled = false,
}

-- ===================== HAT FUNCTIONS =====================
local function Hat_RemoveClassic()
    if HatVariables.parts[player.Character] then
        HatVariables.parts[player.Character]:Destroy()
        HatVariables.parts[player.Character] = nil
    end
end

local function Hat_AddClassic(char)
    task.wait(0.1)
    local head = char:WaitForChild("Head", 5)
    if not head then return end
    Hat_RemoveClassic()

    local hat = Instance.new("Part")
    hat.Name = "ChineseHat"
    hat.Transparency = HatVariables.transparency
    hat.Color = HatVariables.color
    hat.Material = Enum.Material.Neon
    hat.CanCollide = false
    hat.Reflectance = HatVariables.reflectance

    local mesh = Instance.new("SpecialMesh")
    mesh.MeshId = "rbxassetid://1033714"
    mesh.Scale = Vector3.new(HatVariables.radius, HatVariables.height, HatVariables.radius)
    mesh.Parent = hat

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = head
    weld.Part1 = hat
    weld.Parent = hat

    hat.CFrame = head.CFrame * CFrame.new(0, 1.1, 0)
    hat.Parent = char
    HatVariables.parts[char] = hat
end

local function Hat_UpdateClassic()
    for char, hat in pairs(HatVariables.parts) do
        if hat and hat.Parent and char == player.Character then
            hat.Transparency = HatVariables.transparency
            hat.Reflectance = HatVariables.reflectance

            if HatVariables.rainbow then
                hat.Color = Color3.fromHSV(tick() % HatVariables.rainbowSpeed / HatVariables.rainbowSpeed, 1, 1)
            else
                hat.Color = HatVariables.color
            end

            local mesh = hat:FindFirstChildOfClass("SpecialMesh")
            if mesh then
                mesh.Scale = Vector3.new(HatVariables.radius, HatVariables.height, HatVariables.radius)
            end
        end
    end
end

local function Hat_UpdateDrawing()
    local pass = HatVariables.enabled and player.Character and player.Character:FindFirstChild('Head') ~= nil and (camera.CFrame.p - camera.Focus.p).magnitude > 1 and player.Character.Humanoid.Health > 0

    for i = 1, #drawings do
        local line, triangle = drawings[i][1], drawings[i][2]
        if pass then
            local color
            if HatVariables.rainbow then
                color = Color3.fromHSV((tick() % HatVariables.rainbowSpeed / HatVariables.rainbowSpeed - (i / #drawings)) % 1, 0.5, 1)
            else
                color = HatVariables.color
            end

            local pos = player.Character.Head.Position + Vector3.new(0, 0.75, 0)
            local topWorld = pos + Vector3.new(0, 0.75, 0)

            local last, next = (i / HatVariables.sides) * tau, ((i + 1) / HatVariables.sides) * tau
            local lastWorld = pos + (Vector3.new(math.cos(last), 0, math.sin(last)) * HatVariables.radius)
            local nextWorld = pos + (Vector3.new(math.cos(next), 0, math.sin(next)) * HatVariables.radius)
            local lastScreen = camera:WorldToViewportPoint(lastWorld)
            local nextScreen = camera:WorldToViewportPoint(nextWorld)
            local topScreen = camera:WorldToViewportPoint(topWorld)

            line.From = Vector2.new(lastScreen.X, lastScreen.Y)
            line.To = Vector2.new(nextScreen.X, nextScreen.Y)
            line.Color = color
            line.Transparency = 1 - HatVariables.transparency
            line.Visible = true

            triangle.PointA = Vector2.new(topScreen.X, topScreen.Y)
            triangle.PointB = line.From
            triangle.PointC = line.To
            triangle.Color = color
            triangle.Transparency = 0.35
            triangle.Visible = true
        else
            line.Visible = false
            triangle.Visible = false
        end
    end
end

local function Hat_ToggleEnabled(value)
    HatVariables.enabled = value

    if value then
        if HatVariables.style == "Classic" and player.Character then
            Hat_AddClassic(player.Character)
        end

        if HatVariables.connection then HatVariables.connection:Disconnect() end
        HatVariables.connection = RunService.Heartbeat:Connect(function()
            if HatVariables.style == "Classic" then
                Hat_UpdateClassic()
            end
        end)
    else
        if player.Character then Hat_RemoveClassic() end
        for i = 1, #drawings do
            drawings[i][1].Visible = false
            drawings[i][2].Visible = false
        end

        if HatVariables.connection then
            HatVariables.connection:Disconnect()
            HatVariables.connection = nil
        end
    end
end

local function Hat_ChangeStyle(newStyle)
    local wasEnabled = HatVariables.enabled
    HatVariables.style = newStyle

    if wasEnabled then
        Hat_ToggleEnabled(false)
        task.wait(0.1)
        Hat_ToggleEnabled(true)
    end
end

local function Hat_UpdateSides(newSides)
    HatVariables.sides = newSides

    for i = 1, #drawings do
        drawings[i][1]:Remove()
        drawings[i][2]:Remove()
    end
    drawings = {}

    for i = 1, newSides do
        drawings[i] = {Drawing.new('Line'), Drawing.new('Triangle')}
        drawings[i][1].ZIndex = 2
        drawings[i][1].Thickness = 2
        drawings[i][2].ZIndex = 1
        drawings[i][2].Filled = true
    end
end

RunService.RenderStepped:Connect(function()
    if HatVariables.enabled and HatVariables.style == "Drawing" then
        Hat_UpdateDrawing()
    end
end)

-- ===================== TRAIL FUNCTIONS =====================
local function Trail_RemoveFromCharacter(char)
    if TrailVariables.parts[char] then
        TrailVariables.parts[char]:Destroy()
        TrailVariables.parts[char] = nil
    end
    if char and char:FindFirstChild("HumanoidRootPart") then
        local torso = char.HumanoidRootPart
        if torso:FindFirstChild("TrailAttach0") then torso.TrailAttach0:Destroy() end
        if torso:FindFirstChild("TrailAttach1") then torso.TrailAttach1:Destroy() end
    end
end

local function Trail_AddToCharacter(character)
    local torso = character:WaitForChild("HumanoidRootPart", 5)
    if not torso then return end
    Trail_RemoveFromCharacter(character)

    local a0 = Instance.new("Attachment")
    a0.Name = "TrailAttach0"
    a0.Position = Vector3.new(0, 2, 0)
    a0.Parent = torso

    local a1 = Instance.new("Attachment")
    a1.Name = "TrailAttach1"
    a1.Position = Vector3.new(0, -2, 0)
    a1.Parent = torso

    local trail = Instance.new("Trail")
    trail.Attachment0 = a0
    trail.Attachment1 = a1
    trail.Lifetime = TrailVariables.lifetime
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, TrailVariables.transparencyStart),
        NumberSequenceKeypoint.new(1, 1)
    })

    if TrailVariables.isGradient then
        trail.Color = ColorSequence.new(TrailVariables.gradient1, TrailVariables.gradient2)
    else
        trail.Color = ColorSequence.new(TrailVariables.colorStatic)
    end

    trail.LightEmission = 0.2
    trail.Enabled = true
    trail.Parent = character
    TrailVariables.parts[character] = trail
end

local function Trail_UpdateAll()
    for char, trail in pairs(TrailVariables.parts) do
        if trail and trail.Parent and char == player.Character then
            trail.Lifetime = TrailVariables.lifetime
            trail.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, TrailVariables.transparencyStart),
                NumberSequenceKeypoint.new(1, 1)
            })

            if TrailVariables.isGradient then
                trail.Color = ColorSequence.new(TrailVariables.gradient1, TrailVariables.gradient2)
            else
                if TrailVariables.rainbow then
                    trail.Color = ColorSequence.new(Color3.fromHSV(tick() % 5 / 5, 1, 1))
                else
                    trail.Color = ColorSequence.new(TrailVariables.colorStatic)
                end
            end
        end
    end
end

local function Trail_ToggleEnabled(value)
    TrailVariables.enabled = value
    if value and player.Character then
        Trail_AddToCharacter(player.Character)
        if TrailVariables.connection then TrailVariables.connection:Disconnect() end
        TrailVariables.connection = RunService.Heartbeat:Connect(Trail_UpdateAll)
    else
        if player.Character then Trail_RemoveFromCharacter(player.Character) end
        if TrailVariables.connection then
            TrailVariables.connection:Disconnect()
            TrailVariables.connection = nil
        end
    end
end

-- ===================== AURA TRAILER FUNCTIONS =====================
local function AuraTrailer_Toggle(enabled)
    local character = player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for _, v in pairs(character:GetChildren()) do
        if v:IsA("BasePart") and v ~= hrp then
            if enabled then
                if not v:FindFirstChild("AuraTrailer") then
                    local trail = Instance.new("Trail")
                    trail.Name = "AuraTrailer"
                    trail.Texture = "rbxassetid://1390780157"
                    trail.Parent = v

                    local p1 = Instance.new("Attachment", v)
                    p1.Name = "AuraPointer1"

                    local p2 = Instance.new("Attachment", hrp)
                    p2.Name = "AuraPointer2"

                    trail.Attachment0 = p1
                    trail.Attachment1 = p2
                    trail.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, AuraTrailerVariables.color),
                        ColorSequenceKeypoint.new(1, AuraTrailerVariables.color)
                    })
                    trail.Lifetime = AuraTrailerVariables.lifetime
                end
            else
                if v:FindFirstChild("AuraTrailer") then v.AuraTrailer:Destroy() end
                if v:FindFirstChild("AuraPointer1") then v.AuraPointer1:Destroy() end
            end
        end
    end

    if not enabled then
        for _, obj in pairs(hrp:GetChildren()) do
            if obj.Name == "AuraPointer2" then obj:Destroy() end
        end
    end
end

local function AuraTrailer_Update()
    local character = player.Character
    if not character then return end
    for _, v in pairs(character:GetDescendants()) do
        if v:IsA("Trail") and v.Name == "AuraTrailer" then
            v.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, AuraTrailerVariables.color),
                ColorSequenceKeypoint.new(1, AuraTrailerVariables.color)
            })
            v.Lifetime = AuraTrailerVariables.lifetime
        end
    end
end

-- ===================== FORCE FIELD FUNCTIONS =====================
local function ForceField_SaveOriginalColors(char)
    ForceFieldVariables.originalColors[char] = {}
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "ChineseHat" then
            ForceFieldVariables.originalColors[char][part] = {
                Color = part.Color,
                Material = part.Material
            }
        end
    end
end

local function ForceField_Apply(char)
    ForceField_SaveOriginalColors(char)
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "ChineseHat" then
            part.Color = ForceFieldVariables.color
            part.Material = Enum.Material.ForceField
        end
    end
end

local function ForceField_Update()
    if player.Character and ForceFieldVariables.enabled then
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "ChineseHat" and part.Material == Enum.Material.ForceField then
                if ForceFieldVariables.rainbow then
                    part.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1)
                else
                    part.Color = ForceFieldVariables.color
                end
            end
        end
    end
end

local function ForceField_Remove(char)
    if ForceFieldVariables.originalColors[char] then
        for part, data in pairs(ForceFieldVariables.originalColors[char]) do
            if part and part.Parent and part:IsA("BasePart") then
                part.Color = data.Color
                part.Material = data.Material
            end
        end
        ForceFieldVariables.originalColors[char] = {}
    end
end

local function ForceField_ToggleEnabled(value)
    ForceFieldVariables.enabled = value
    if player.Character then
        if value then
            ForceField_Apply(player.Character)
            if ForceFieldVariables.connection then ForceFieldVariables.connection:Disconnect() end
            ForceFieldVariables.connection = RunService.Heartbeat:Connect(ForceField_Update)
        else
            if ForceFieldVariables.connection then
                ForceFieldVariables.connection:Disconnect()
                ForceFieldVariables.connection = nil
            end
            ForceField_Remove(player.Character)
        end
    end
end

-- ===================== SKYBOX FUNCTIONS =====================
local function Skybox_Apply(name)
    local sb = SkyboxAssets[name]
    if not sb then return end

    local assets = {sb.Bk, sb.Dn, sb.Ft, sb.Lf, sb.Rt, sb.Up}
    task.spawn(function()
        ContentProvider:PreloadAsync(assets)
    end)

    local sky = Lighting:FindFirstChildOfClass("Sky")
    if not sky then
        sky = Instance.new("Sky")
        sky.Name = "Sky"
        sky.Parent = Lighting
    end

    sky.SkyboxBk = sb.Bk
    sky.SkyboxDn = sb.Dn
    sky.SkyboxFt = sb.Ft
    sky.SkyboxLf = sb.Lf
    sky.SkyboxRt = sb.Rt
    sky.SkyboxUp = sb.Up
end

local function Skybox_RestoreDefault()
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if sky and DefaultSkySettings.SkyboxBk then
        sky.SkyboxBk = DefaultSkySettings.SkyboxBk
        sky.SkyboxDn = DefaultSkySettings.SkyboxDn
        sky.SkyboxFt = DefaultSkySettings.SkyboxFt
        sky.SkyboxLf = DefaultSkySettings.SkyboxLf
        sky.SkyboxRt = DefaultSkySettings.SkyboxRt
        sky.SkyboxUp = DefaultSkySettings.SkyboxUp
    elseif sky then
        sky:Destroy()
    end
end

-- ===================== CLASSIC AURA FUNCTIONS =====================
local function ClassicAura_LoadModel(id)
    local success, result = pcall(function()
        return game:GetObjects(id)[1]
    end)
    if not success then
        warn("Failed to load aura model:", id)
        return nil
    end
    return result
end

local function ClassicAura_DisableOne(auraName)
    if activeClassicAuras[auraName] then
        for _, v in pairs(activeClassicAuras[auraName]) do
            if v and v.Parent then
                pcall(function() v:Destroy() end)
            end
        end
        activeClassicAuras[auraName] = nil
    end
end

local function ClassicAura_EnableOne(char, auraName)
    if not char or not char.Parent then return end

    ClassicAura_DisableOne(auraName)

    local id = AuraModelIDs[auraName]
    if not id then
        warn("No ID found for aura:", auraName)
        return
    end

    local model = ClassicAura_LoadModel(id)
    if not model then
        warn("Failed to load model for:", auraName)
        return
    end

    local effects = {}
    for _, obj in pairs(model:GetDescendants()) do
        if not obj:IsA('BasePart') then
            pcall(function()
                local clone = obj:Clone()
                local parentName = obj.Parent and obj.Parent.Name
                local target = char:FindFirstChild(parentName)
                if not target then
                    target = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA('BasePart')
                end
                if target then
                    clone.Parent = target
                    table.insert(effects, clone)
                end
            end)
        end
    end

    pcall(function() model:Destroy() end)

    if #effects > 0 then
        activeClassicAuras[auraName] = effects
        print("✅ Enabled Classic Aura:", auraName, "- Effects:", #effects)
    else
        warn("⚠️ No effects created for:", auraName)
    end
end

local function ClassicAura_RefreshAll()
    local char = player.Character
    if not char then return end

    if not Toggles.ClassicAuraEnabled or not Toggles.ClassicAuraEnabled.Value then
        for _, auraName in ipairs(AuraModels) do
            ClassicAura_DisableOne(auraName)
        end
        return
    end

    if not Options.ClassicAuraDropdown then return end
    local selectedAuras = Options.ClassicAuraDropdown.Value

    for _, auraName in ipairs(AuraModels) do
        ClassicAura_DisableOne(auraName)
    end

    if type(selectedAuras) == "table" then
        for auraName, isSelected in pairs(selectedAuras) do
            if isSelected then
                task.spawn(function()
                    ClassicAura_EnableOne(char, auraName)
                end)
            end
        end
    end
end

-- ===================== PARTICLE AURA FUNCTIONS =====================
local function mapCharacterParts(character)
    local parts = {}
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("BasePart") then
            parts[child.Name] = child
        end
    end
    return parts
end

local function getParticleAuraTemplate(name)
    local cached = loadedParticleAuras[name]
    if cached then return cached end
    local id = particleAuraIdByName[name]
    if not id then return nil end
    local ok, result = pcall(function()
        return game:GetObjects(id)[1]
    end)
    if ok and result then
        loadedParticleAuras[name] = result
        return result
    end
    return nil
end

local function tintParticleSubtree(root, color)
    if not color or not root then return end
    local seq = ColorSequence.new(color)
    local function tintOne(obj)
        pcall(function()
            if obj:IsA("ParticleEmitter") or obj:IsA("Beam") or obj:IsA("Trail") then
                obj.Color = seq
            elseif obj:IsA("PointLight") then
                obj.Color = color
            end
        end)
    end
    tintOne(root)
    for _, d in ipairs(root:GetDescendants()) do
        tintOne(d)
    end
end

local function setParticleEmittersEnabledInSubtree(root, enabled)
    if not root then return end
    pcall(function()
        if root:IsA("ParticleEmitter") then
            root.Enabled = enabled
        end
    end)
    for _, d in ipairs(root:GetDescendants()) do
        pcall(function()
            if d:IsA("ParticleEmitter") then
                d.Enabled = enabled
            end
        end)
    end
end

local function applyParticleAuraToCharacter(character, auraName, color)
    local auraObj = getParticleAuraTemplate(auraName)
    if not auraObj then
        warn("No template for particle aura:", auraName)
        return {}
    end

    local localParts = mapCharacterParts(character)
    local cloned = auraObj:Clone()
    local created = {}

    for _, part in ipairs(cloned:GetChildren()) do
        local targetPart = localParts[part.Name]
        if targetPart then
            for _, child in ipairs(part:GetChildren()) do
                pcall(function()
                    local inst = child:Clone()
                    inst.Name = "LarpticAuraParticle"
                    inst.Parent = targetPart
                    if color then
                        tintParticleSubtree(inst, color)
                    end
                    table.insert(created, inst)
                end)
            end
        end
    end

    pcall(function() cloned:Destroy() end)

    for _, p in ipairs(created) do
        setParticleEmittersEnabledInSubtree(p, true)
    end

    if #created > 0 then
        print("✅ Enabled Particle Aura:", auraName, "- Particles:", #created)
    end

    return created
end

local function ParticleAura_DisableOne(auraName)
    if activeParticleAuras[auraName] then
        for _, p in ipairs(activeParticleAuras[auraName]) do
            if p then
                pcall(function() p:Destroy() end)
            end
        end
        activeParticleAuras[auraName] = nil
    end
end

local function ParticleAura_RefreshAll()
    local char = player.Character
    if not char then return end

    if not Toggles.ParticleAuraEnabled or not Toggles.ParticleAuraEnabled.Value then
        for _, auraName in ipairs(PARTICLE_AURA_NAMES) do
            ParticleAura_DisableOne(auraName)
        end
        return
    end

    if not Options.ParticleAuraDropdown then return end
    local selectedAuras = Options.ParticleAuraDropdown.Value

    for _, auraName in ipairs(PARTICLE_AURA_NAMES) do
        ParticleAura_DisableOne(auraName)
    end

    local col = Options.ParticleAuraColor and Options.ParticleAuraColor.Value or Color3.fromRGB(133, 220, 255)
    if type(selectedAuras) == "table" then
        for auraName, isSelected in pairs(selectedAuras) do
            if isSelected then
                task.spawn(function()
                    local particles = applyParticleAuraToCharacter(char, auraName, col)
                    activeParticleAuras[auraName] = particles
                end)
            end
        end
    end
end

-- ===================== SCREEN FUNCTIONS =====================
local function Screen_Toggle(value)
    WorldVariables.screenEnabled = value
    if value then
        getgenv().gg_scripters = "Aori0001"
        WorldVariables.screenConnection = RunService.RenderStepped:Connect(function()
            camera.CFrame = camera.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, (0.65 + WorldVariables.screenIntensity), 0, 0, 0, 1)
        end)
    else
        if WorldVariables.screenConnection then
            WorldVariables.screenConnection:Disconnect()
            WorldVariables.screenConnection = nil
        end
        getgenv().gg_scripters = nil
    end
end

-- ===================== ANIME FUNCTIONS =====================
local function Anime_Toggle(value)
    AnimeVariables.enabled = value
    if value then
        AnimeVariables.gui = Instance.new("ScreenGui", player.PlayerGui)
        AnimeVariables.gui.Name = "AnimeImageGui"
        AnimeVariables.gui.ResetOnSpawn = false

        local imageLabel = Instance.new("ImageLabel", AnimeVariables.gui)
        imageLabel.Name = "AnimeImage"
        imageLabel.Image = "http://www.roblox.com/asset/?id=117783035423570"
        imageLabel.Size = UDim2.new(0, 350, 0, 400)
        imageLabel.Position = UDim2.new(1, -25, 0, 10)
        imageLabel.AnchorPoint = Vector2.new(1, 0)
        imageLabel.BackgroundTransparency = 1
    else
        if AnimeVariables.gui then
            AnimeVariables.gui:Destroy()
            AnimeVariables.gui = nil
        end
    end
end

-- ===================== CREATE TABS =====================
local MainTab = Window:AddTab("Main", "home")
local RageTab = Window:AddTab("Rage", "target")
local VisualTab = Window:AddTab("Visual", "palette")
local SettingsTab = Window:AddTab("Settings", "settings")

-- ===================== MAIN TAB =====================
local MainGroup = MainTab:AddLeftGroupbox("Information")
MainGroup:AddLabel("Awesome script in development")
MainGroup:AddLabel("Visuals only for now")
MainGroup:AddLabel("(More features coming soon)")

-- ===================== AIM BOT GROUPBOX =====================
local AimBotGroup = MainTab:AddLeftGroupbox("Aim Bot")

AimBotGroup:AddToggle("AimBotToggle", {
    Text = "Enable Aim Bot",
    Default = false,
    Callback = function(Value)
        AimBot_Toggle(Value)
    end,
})

AimBotGroup:AddToggle("AimBotRainbow", {
    Text = "Rainbow Line",
    Default = false,
    Callback = function(Value)
        AimBotVariables.rainbow = Value
    end,
})

AimBotGroup:AddSlider("AimBotRainbowSpeed", {
    Text = "Rainbow Speed",
    Default = 5,
    Min = 1,
    Max = 20,
    Rounding = 0,
    Callback = function(Value)
        AimBotVariables.rainbowSpeed = Value
    end,
})

AimBotGroup:AddSlider("AimBotRadius", {
    Text = "Search Radius",
    Default = 50,
    Min = 10,
    Max = 200,
    Rounding = 0,
    Callback = function(Value)
        AimBotVariables.radius = Value
    end,
})

AimBotGroup:AddSlider("AimBotLineWidth", {
    Text = "Line Width",
    Default = 2,
    Min = 1,
    Max = 5,
    Rounding = 0,
    Callback = function(Value)
        AimBotVariables.lineWidth = Value
        if AimBotVariables.line then
            AimBotVariables.line.Thickness = Value
        end
    end,
})

AimBotGroup:AddDropdown("AimBotTargetPart", {
    Values = {"Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso"},
    Default = "Head",
    Text = "Target Part",
    Callback = function(Value)
        AimBotVariables.targetPart = Value
    end,
})

AimBotGroup:AddDropdown("AimBotMode", {
    Values = {"Classic", "Smooth"},
    Default = "Classic",
    Text = "Aim Mode",
    Callback = function(Value)
        AimBotVariables.mode = Value
    end,
})

AimBotGroup:AddSlider("AimBotSmoothness", {
    Text = "Smoothness",
    Default = 0.15,
    Min = 0.01,
    Max = 0.5,
    Rounding = 2,
    Callback = function(Value)
        AimBotVariables.smoothness = Value
    end,
})

AimBotGroup:AddLabel("Line Color"):AddColorPicker("AimBotColor", {
    Default = Color3.fromRGB(255, 0, 0),
    Title = "Line Color",
    Callback = function(Value)
        AimBotVariables.color = Value
        if AimBotVariables.line then
            AimBotVariables.line.Color = Value
        end
    end,
})

-- ===================== RAGE TAB: SILENT AIM =====================
local SilentAimGroup = RageTab:AddLeftGroupbox("Silent Aim")

SilentAimGroup:AddToggle("SalientAimToggle", {
    Text = "Enable Silent Aim",
    Default = false,
    Callback = function(Value)
        SalientAim_Toggle(Value)
    end,
})

SilentAimGroup:AddDivider()

SilentAimGroup:AddSlider("SalientAimFOV", {
    Text = "FOV Radius",
    Default = 120,
    Min = 10,
    Max = 500,
    Rounding = 0,
    Callback = function(Value)
        SalientAimVariables.fov = Value
    end,
})

SilentAimGroup:AddToggle("SalientAimShowFOV", {
    Text = "Show FOV Circle",
    Default = true,
    Callback = function(Value)
        SalientAimVariables.showFOVCircle = Value
    end,
})

SilentAimGroup:AddToggle("SalientAimShowSnapline", {
    Text = "Show Snapline",
    Default = true,
    Callback = function(Value)
        SalientAimVariables.showSnapline = Value
    end,
})

SilentAimGroup:AddToggle("SalientAimWallCheck", {
    Text = "Wall Check",
    Default = true,
    Callback = function(Value)
        SalientAimVariables.wallCheck = Value
    end,
})

SilentAimGroup:AddDivider()

SilentAimGroup:AddLabel("FOV Circle Color"):AddColorPicker("SalientAimFOVColor", {
    Default = Color3.fromRGB(255, 255, 255),
    Title = "FOV Circle Color",
    Callback = function(Value)
        SalientAimVariables.fovColor = Value
    end,
})

SilentAimGroup:AddSlider("SalientAimFOVTransparency", {
    Text = "FOV Transparency",
    Default = 0.8,
    Min = 0,
    Max = 1,
    Rounding = 1,
    Callback = function(Value)
        SalientAimVariables.fovTransparency = Value
    end,
})

SilentAimGroup:AddSlider("SalientAimFOVThickness", {
    Text = "FOV Thickness",
    Default = 1.5,
    Min = 0.5,
    Max = 5,
    Rounding = 1,
    Callback = function(Value)
        SalientAimVariables.fovThickness = Value
    end,
})

SilentAimGroup:AddDivider()

SilentAimGroup:AddLabel("Snapline Color"):AddColorPicker("SalientAimLineColor", {
    Default = Color3.fromRGB(255, 0, 0),
    Title = "Snapline Color",
    Callback = function(Value)
        SalientAimVariables.lineColor = Value
    end,
})

SilentAimGroup:AddSlider("SalientAimLineTransparency", {
    Text = "Snapline Transparency",
    Default = 0.9,
    Min = 0,
    Max = 1,
    Rounding = 1,
    Callback = function(Value)
        SalientAimVariables.lineTransparency = Value
    end,
})

SilentAimGroup:AddSlider("SalientAimLineThickness", {
    Text = "Snapline Thickness",
    Default = 1.5,
    Min = 0.5,
    Max = 5,
    Rounding = 1,
    Callback = function(Value)
        SalientAimVariables.lineThickness = Value
    end,
})

-- ===================== RAGE TAB: MOVEMENT =====================
local RageMovementGroup = RageTab:AddLeftGroupbox("Movement")

RageMovementGroup:AddToggle("SpinBotToggle", {
    Text = "Spin Bot",
    Default = RageVars.spinBotEnabled,
    Callback = function(Value)
        RageVars.spinBotEnabled = Value
    end,
})

RageMovementGroup:AddToggle("BhopToggle", {
    Text = "Bunny Hop",
    Default = RageVars.BunnyHop,
    Callback = function(Value)
        RageVars.BunnyHop = Value
    end,
})

RageMovementGroup:AddSlider("BhopDelaySlider", {
    Text = "Jump Delay",
    Default = RageVars.BhopDelay,
    Min = 0,
    Max = 0.5,
    Rounding = 2,
    Callback = function(Value)
        RageVars.BhopDelay = Value
    end,
})

RageMovementGroup:AddToggle("SpiderClimbToggle", {
    Text = "Spider Climb",
    Default = RageVars.SpiderClimb,
    Callback = function(Value)
        RageVars.SpiderClimb = Value
    end,
})

-- ===================== RAGE TAB: PLAYER =====================
local RagePlayerGroup = RageTab:AddLeftGroupbox("Player")

RagePlayerGroup:AddToggle("AutoRespawnToggle", {
    Text = "Auto Respawn",
    Default = RageVars.autoRespawnEnabled,
    Callback = function(Value)
        RageVars.autoRespawnEnabled = Value
    end,
})

RagePlayerGroup:AddToggle("AntiAFKToggle", {
    Text = "Anti AFK",
    Default = RageVars.AntiAFK,
    Callback = function(Value)
        RageVars.AntiAFK = Value
    end,
})

RagePlayerGroup:AddToggle("FOVToggle", {
    Text = "FOV Changer",
    Default = RageVars.FOVEnabled,
    Callback = function(Value)
        RageVars.FOVEnabled = Value
        if not Value then
            Workspace.CurrentCamera.FieldOfView = 70
        end
    end,
})

RagePlayerGroup:AddSlider("FOVSlider", {
    Text = "FOV",
    Default = RageVars.FOVValue,
    Min = 30,
    Max = 120,
    Rounding = 0,
    Callback = function(Value)
        RageVars.FOVValue = Value
    end,
})

-- ===================== RAGE TAB: UTILS =====================
local RageUtilsGroup = RageTab:AddRightGroupbox("Utils")

RageUtilsGroup:AddToggle("RadarToggle", {
    Text = "Radar",
    Default = RageVars.Radar,
    Callback = function(Value)
        RageVars.Radar = Value
        radarFrame.Visible = Value
    end,
})

RageUtilsGroup:AddToggle("FPSBoostToggle", {
    Text = "FPS Boost",
    Default = RageVars.FPSBoost,
    Callback = function(Value)
        RageVars.FPSBoost = Value
    end,
})

RageUtilsGroup:AddToggle("ServerHopToggle", {
    Text = "Server Hop",
    Default = RageVars.ServerHop,
    Callback = function(Value)
        RageVars.ServerHop = Value
    end,
})

RageUtilsGroup:AddToggle("RejoinToggle", {
    Text = "Rejoin",
    Default = RageVars.Rejoin,
    Callback = function(Value)
        RageVars.Rejoin = Value
    end,
})

-- ===================== RAGE TAB: WEAPON & VIEWMODEL =====================
local RageWeaponGroup = RageTab:AddRightGroupbox("Weapon & Viewmodel")

RageWeaponGroup:AddToggle("WeaponSkinToggle", {
    Text = "Weapon Skin",
    Default = RageVars.weaponSkinEnabled,
    Callback = function(Value)
        RageVars.weaponSkinEnabled = Value
    end,
})

RageWeaponGroup:AddSlider("WeaponTransparencySlider", {
    Text = "Gun Transparency",
    Default = RageVars.weaponTransparency,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        RageVars.weaponTransparency = Value
    end,
})

RageWeaponGroup:AddSlider("WeaponReflectanceSlider", {
    Text = "Gun Reflectance",
    Default = RageVars.weaponReflectance,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        RageVars.weaponReflectance = Value
    end,
})

RageWeaponGroup:AddToggle("BulletTracersToggle", {
    Text = "Bullet Tracers",
    Default = RageVars.bulletTracersEnabled,
    Callback = function(Value)
        RageVars.bulletTracersEnabled = Value
    end,
})

RageWeaponGroup:AddDivider()

RageWeaponGroup:AddToggle("ViewmodelChangerToggle", {
    Text = "Viewmodel Changer",
    Default = RageVars.viewmodelChanger,
    Callback = function(Value)
        RageVars.viewmodelChanger = Value
    end,
}):AddColorPicker("ViewmodelColorPicker", {
    Default = Color3.fromRGB(140, 140, 245),
    Title = "Arm Color",
    Callback = function(Value)
        RageVars.viewmodelColor = Value
    end,
})

RageWeaponGroup:AddDropdown("ViewmodelMaterialDropdown", {
    Values = {'Neon', 'ForceField', 'Glass', 'SmoothPlastic', 'Metal', 'Foil', 'DiamondPlate'},
    Default = 'Neon',
    Text = "Arm Material",
    Callback = function(Value)
        RageVars.viewmodelMaterial = Value
    end,
})

-- ===================== RAGE TAB: NIGHT LIGHTING =====================
local RageNightGroup = RageTab:AddRightGroupbox("Night Lighting")

RageNightGroup:AddToggle("NightLightingToggle", {
    Text = "Night Lighting",
    Default = RageVars.nightLightingEnabled,
    Callback = function(Value)
        RageVars.nightLightingEnabled = Value
        if Value then
            setupNightLighting()
        else
            removeNightLighting()
        end
    end,
})

-- ===================== VISUAL TAB =====================

-- HAT GROUPBOX
local HatGroupBox = VisualTab:AddLeftGroupbox("Chinese Hat")

HatGroupBox:AddToggle("HatToggle", {
    Text = "Enable Hat",
    Default = false,
    Callback = function(Value)
        Hat_ToggleEnabled(Value)
    end,
})

HatGroupBox:AddDropdown("HatStyle", {
    Values = {"Classic", "Drawing"},
    Default = "Classic",
    Text = "Hat Style",
    Callback = function(Value)
        Hat_ChangeStyle(Value)
    end,
})

HatGroupBox:AddToggle("HatRainbow", {
    Text = "Rainbow Mode",
    Default = false,
    Callback = function(Value)
        HatVariables.rainbow = Value
    end,
})

HatGroupBox:AddSlider("HatRainbowSpeed", {
    Text = "Rainbow Speed",
    Default = 5,
    Min = 1,
    Max = 20,
    Rounding = 0,
    Callback = function(Value)
        HatVariables.rainbowSpeed = Value
    end,
})

HatGroupBox:AddSlider("HatTransparency", {
    Text = "Transparency",
    Default = 0.3,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        HatVariables.transparency = Value
    end,
})

HatGroupBox:AddSlider("HatRadius", {
    Text = "Radius",
    Default = 2.4,
    Min = 0.5,
    Max = 10,
    Rounding = 1,
    Callback = function(Value)
        HatVariables.radius = Value
    end,
})

HatGroupBox:AddSlider("HatHeight", {
    Text = "Height",
    Default = 1.6,
    Min = 0.5,
    Max = 5,
    Rounding = 1,
    Callback = function(Value)
        HatVariables.height = Value
    end,
})

HatGroupBox:AddSlider("HatReflectance", {
    Text = "Reflectance",
    Default = 0,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        HatVariables.reflectance = Value
    end,
})

HatGroupBox:AddSlider("HatSides", {
    Text = "Sides",
    Default = 25,
    Min = 3,
    Max = 300,
    Rounding = 0,
    Callback = function(Value)
        Hat_UpdateSides(Value)
    end,
})

HatGroupBox:AddLabel("Hat Color"):AddColorPicker("HatColor", {
    Default = Color3.fromRGB(0, 255, 255),
    Title = "Hat Color",
    Callback = function(Value)
        HatVariables.color = Value
    end,
})

-- TRAIL GROUPBOX
local TrailGroupBox = VisualTab:AddLeftGroupbox("Trail")
TrailGroupBox:AddToggle("TrailToggle", {
    Text = "Enable Trail",
    Default = false,
    Callback = function(Value)
        Trail_ToggleEnabled(Value)
    end,
})
TrailGroupBox:AddToggle("TrailGradient", {
    Text = "Gradient Mode",
    Default = false,
    Callback = function(Value)
        TrailVariables.isGradient = Value
        if TrailVariables.enabled and player.Character then
            Trail_AddToCharacter(player.Character)
        end
    end,
})
TrailGroupBox:AddSlider("TrailLifetime", {
    Text = "Lifetime",
    Default = 0.5,
    Min = 0.1,
    Max = 3,
    Rounding = 1,
    Callback = function(Value)
        TrailVariables.lifetime = Value
        Trail_UpdateAll()
    end,
})
TrailGroupBox:AddSlider("TrailTransparency", {
    Text = "Start Transparency",
    Default = 0,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        TrailVariables.transparencyStart = Value
        Trail_UpdateAll()
    end,
})
TrailGroupBox:AddToggle("TrailRainbow", {
    Text = "Rainbow",
    Default = false,
    Callback = function(Value)
        TrailVariables.rainbow = Value
        Trail_UpdateAll()
    end,
})
TrailGroupBox:AddLabel("Static Color"):AddColorPicker("TrailColor", {
    Default = Color3.fromRGB(0, 255, 255),
    Title = "Trail Color",
    Callback = function(Value)
        TrailVariables.colorStatic = Value
        Trail_UpdateAll()
    end,
})
TrailGroupBox:AddLabel("Gradient 1"):AddColorPicker("TrailGradient1", {
    Default = Color3.fromRGB(0, 86, 255),
    Title = "Gradient Color 1",
    Callback = function(Value)
        TrailVariables.gradient1 = Value
        Trail_UpdateAll()
    end,
})
TrailGroupBox:AddLabel("Gradient 2"):AddColorPicker("TrailGradient2", {
    Default = Color3.fromRGB(255, 0, 0),
    Title = "Gradient Color 2",
    Callback = function(Value)
        TrailVariables.gradient2 = Value
        Trail_UpdateAll()
    end,
})

-- FORCE FIELD GROUPBOX
local FFGroupBox = VisualTab:AddRightGroupbox("Force Field")
FFGroupBox:AddToggle("FFToggle", {
    Text = "Enable Force Field",
    Default = false,
    Callback = function(Value)
        ForceField_ToggleEnabled(Value)
    end,
})
FFGroupBox:AddToggle("FFRainbow", {
    Text = "Rainbow Mode",
    Default = false,
    Callback = function(Value)
        ForceFieldVariables.rainbow = Value
        ForceField_Update()
    end,
})
FFGroupBox:AddLabel("Color"):AddColorPicker("FFColor", {
    Default = Color3.fromRGB(128, 128, 128),
    Title = "Force Field Color",
    Callback = function(Value)
        ForceFieldVariables.color = Value
        if ForceFieldVariables.enabled and not ForceFieldVariables.rainbow and player.Character then
            ForceField_Apply(player.Character)
        end
    end,
})

-- AURA TRAILER GROUPBOX
local AuraTrailerGroupBox = VisualTab:AddRightGroupbox("Aura Trailer")
AuraTrailerGroupBox:AddToggle("AuraTrailerToggle", {
    Text = "Enable Aura Trailer",
    Default = false,
    Callback = function(Value)
        AuraTrailerVariables.enabled = Value
        AuraTrailer_Toggle(Value)
    end,
})
AuraTrailerGroupBox:AddLabel("Color"):AddColorPicker("AuraTrailerColor", {
    Default = Color3.fromRGB(255, 0, 0),
    Title = "Aura Trailer Color",
    Callback = function(Value)
        AuraTrailerVariables.color = Value
        if AuraTrailerVariables.enabled then AuraTrailer_Update() end
    end,
})
AuraTrailerGroupBox:AddSlider("AuraTrailerLife", {
    Text = "Lifetime",
    Default = 0.5,
    Min = 0.1,
    Max = 3,
    Rounding = 1,
    Callback = function(Value)
        AuraTrailerVariables.lifetime = Value
        if AuraTrailerVariables.enabled then AuraTrailer_Update() end
    end,
})

-- CLASSIC AURA GROUPBOX
local ClassicAuraGb = VisualTab:AddRightGroupbox('Classic Aura')

ClassicAuraGb:AddToggle('ClassicAuraEnabled', {
    Text = 'Enable Classic Aura',
    Default = false,
    Callback = function(Value)
        ClassicAura_RefreshAll()
    end,
})

ClassicAuraGb:AddDropdown('ClassicAuraDropdown', {
    Values = AuraModels,
    Default = {},
    Multi = true,
    Text = 'Select Auras',
    Callback = function(Value)
        ClassicAura_RefreshAll()
    end,
})

-- PARTICLE AURA GROUPBOX
local ParticleAuraGb = VisualTab:AddLeftGroupbox('Particle Aura')

ParticleAuraGb:AddToggle('ParticleAuraEnabled', {
    Text = 'Enable Particle Aura',
    Default = false,
    Callback = function(Value)
        ParticleAura_RefreshAll()
    end,
})

ParticleAuraGb:AddLabel('Aura Color'):AddColorPicker('ParticleAuraColor', {
    Default = Color3.fromRGB(133, 220, 255),
    Title = 'Particle Aura Color',
    Callback = function()
        ParticleAura_RefreshAll()
    end,
})

ParticleAuraGb:AddDivider()

ParticleAuraGb:AddDropdown('ParticleAuraDropdown', {
    Values = PARTICLE_AURA_NAMES,
    Default = {},
    Multi = true,
    Text = 'Select Auras',
    Callback = function(Value)
        ParticleAura_RefreshAll()
    end,
})

-- SCREEN GROUPBOX
local ScreenGroupBox = VisualTab:AddLeftGroupbox("Screen Effect")
ScreenGroupBox:AddToggle("ScreenToggle", {
    Text = "Enable Screen Effect",
    Default = false,
    Callback = function(Value)
        Screen_Toggle(Value)
    end,
})
ScreenGroupBox:AddSlider("ScreenIntensity", {
    Text = "Screen Stretch",
    Default = 0,
    Min = 0,
    Max = 0.2,
    Rounding = 3,
    Callback = function(Value)
        WorldVariables.screenIntensity = Value
    end,
})

-- ANIME GROUPBOX
local AnimeGroupBox = VisualTab:AddLeftGroupbox("Utilities")
AnimeGroupBox:AddToggle("AnimeImageToggle", {
    Text = "Anime Image",
    Default = false,
    Callback = function(Value)
        Anime_Toggle(Value)
    end,
})
AnimeGroupBox:AddButton("FPS/Ping Counter 1", function()
    if not FPSVariables.fpsPing1Enabled then
        loadstring(game:HttpGet("https://raw.githubusercontent.com/GLAMOHGA/fling/refs/heads/main/хз%20как%20назвать%20типо%20фпс%20и%20пинг.md"))()
        FPSVariables.fpsPing1Enabled = true
    end
end)
AnimeGroupBox:AddButton("FPS/Ping Counter 2", function()
    if not FPSVariables.fpsPing2Enabled then
        loadstring(game:HttpGet("https://raw.githubusercontent.com/VetrexTheBest/Fps-ping/refs/heads/main/fps%2Bping.txt"))()
        FPSVariables.fpsPing2Enabled = true
    end
end)

-- SKYBOX GROUPBOX
local SkyboxGroupBox = VisualTab:AddRightGroupbox("Skybox")
local skyboxList = {}
for k in pairs(SkyboxAssets) do table.insert(skyboxList, k) end
table.sort(skyboxList)
SkyboxGroupBox:AddDropdown("SkyboxDropdown", {
    Values = skyboxList,
    Default = "HD",
    Text = "Select Skybox",
    Callback = function(Value)
        SkyboxVariables.current = Value
        if not SkyboxVariables.customEnabled then
            SkyboxVariables.customEnabled = true
            Toggles.SkyboxToggle:SetValue(true)
        end
        Skybox_Apply(SkyboxVariables.current)
    end,
})
SkyboxGroupBox:AddToggle("SkyboxToggle", {
    Text = "Enable Skybox",
    Default = false,
    Callback = function(Value)
        SkyboxVariables.customEnabled = Value
        if Value then
            Skybox_Apply(SkyboxVariables.current)
        else
            Skybox_RestoreDefault()
        end
    end,
})

-- LIGHTING GROUPBOX
local LightingGroupBox = VisualTab:AddLeftGroupbox("Lighting")
LightingGroupBox:AddToggle("TimeToggle", {
    Text = "Enable Time Changer",
    Default = false,
    Callback = function(Value)
        WorldVariables.timeEnabled = Value
    end,
})
LightingGroupBox:AddSlider("TimeSlider", {
    Text = "Time (0-24 hours)",
    Default = 12,
    Min = 0,
    Max = 24,
    Rounding = 1,
    Callback = function(Value)
        WorldVariables.timeValue = Value
    end,
})
LightingGroupBox:AddToggle("FullBright", {
    Text = "Full Bright",
    Default = false,
    Callback = function(Value)
        WorldVariables.fullBrightEnabled = Value
        if not Value then
            Lighting.Brightness = defaultLighting.Brightness
            Lighting.GlobalShadows = defaultLighting.GlobalShadows
            Lighting.OutdoorAmbient = defaultLighting.OutdoorAmbient
        end
    end,
})

-- ===================== SETTINGS TAB =====================
local MenuGroup = SettingsTab:AddLeftGroupbox("Menu Settings")
MenuGroup:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text = "Open Keybind Menu",
    Callback = function(value)
        Library.KeybindFrame.Visible = value
    end,
})
MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = true,
    Callback = function(Value)
        Library.ShowCustomCursor = Value
    end,
})
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI = true,
    Text = "Menu Keybind"
})
MenuGroup:AddButton("Unload Script", function()
    Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind

-- ===================== THEME & SAVE =====================
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("VisualMenu")
SaveManager:SetFolder("VisualMenu")
SaveManager:BuildConfigSection(SettingsTab)
ThemeManager:ApplyToTab(SettingsTab)
SaveManager:LoadAutoloadConfig()

print("✅ AWESOME HUB MENU LOADED SUCCESSFULLY!")
print("📌 Press RightShift to open menu")

-- ===================== HEARTBEAT =====================
RunService.Heartbeat:Connect(function()
    if WorldVariables.timeEnabled then
        Lighting.ClockTime = WorldVariables.timeValue
    end

    if WorldVariables.fullBrightEnabled then
        Lighting.Brightness = 3
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.ExposureCompensation = 0.3
    end
end)

-- ===================== AUTO REAPPLY ON CHARACTER SPAWN =====================
local function ReapplyVisuals_OnCharacterSpawned(char)
    task.wait(1)

    if HatVariables.enabled and HatVariables.style == "Classic" then
        Hat_AddClassic(char)
    end
    if TrailVariables.enabled then Trail_AddToCharacter(char) end
    if ForceFieldVariables.enabled then ForceField_Apply(char) end
    if AuraTrailerVariables.enabled then AuraTrailer_Toggle(true) end
    if AnimeVariables.enabled then Anime_Toggle(true) end
    ClassicAura_RefreshAll()
    ParticleAura_RefreshAll()
end

player.CharacterAdded:Connect(ReapplyVisuals_OnCharacterSpawned)
if player.Character then ReapplyVisuals_OnCharacterSpawned(player.Character) end