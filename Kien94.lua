-- Script Menu: √12kientomato
-- Source Link: https://raw.githubusercontent.com/cunnrnrn/Kiengame/refs/heads/main/Kien
-- Phiên bản: 2-Location Teleport + Anti-Player Tween + Player ESP + Fix Server Hop & Lag

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Biến cấu hình (Chỉ giữ 2 vị trí)
local savedPositions = {
    ["Vị trí 1"] = nil,
    ["Vị trí 2"] = nil,
}
local espObjects = {}
local playerEspObjects = {}
local selectedLocation = "Vị trí 1"
local moveMethod = "Teleport"
local travelSpeed = 165 -- Cố định tốc độ tối đa an toàn không bị anti-cheat (165)
local instantInteractEnabled = false
local espEnabled = true
local playerEspEnabled = true -- Bật/Tắt ESP người chơi
local isLocked = false
local isFixLagActive = false

-- Khởi tạo Folder chứa ESP
local espFolder = workspace:FindFirstChild("TomatoESPFolder")
if not espFolder then
    espFolder = Instance.new("Folder")
    espFolder.Name = "TomatoESPFolder"
    espFolder.Parent = workspace
end

local playerEspFolder = workspace:FindFirstChild("TomatoPlayerESPFolder")
if not playerEspFolder then
    playerEspFolder = Instance.new("Folder")
    playerEspFolder.Name = "TomatoPlayerESPFolder"
    playerEspFolder.Parent = workspace
end

---------------------------------------------------------
-- GIAO DIỆN CUSTOM MINI UI (240x260)
---------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TomatoCustomMiniUI"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- 1. NÚT NỔI ẨN / HIỆN MENU
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "TomatoToggle"
ToggleButton.Parent = ScreenGui
ToggleButton.Size = UDim2.new(0, 70, 0, 30)
ToggleButton.Position = UDim2.new(0.02, 0, 0.2, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ToggleButton.BackgroundTransparency = 0.2
ToggleButton.TextColor3 = Color3.fromRGB(255, 60, 60)
ToggleButton.Text = "🍅 Menu"
ToggleButton.TextSize = 13
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Active = true
ToggleButton.Draggable = true

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = ToggleButton

-- 2. KHUNG MENU CHÍNH
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.Size = UDim2.new(0, 240, 0, 260)
MainFrame.Position = UDim2.new(0.02, 0, 0.26, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BackgroundTransparency = 0.35
MainFrame.Active = true
MainFrame.Draggable = true

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1.5
MainStroke.Color = Color3.fromRGB(255, 60, 60)
MainStroke.Parent = MainFrame

-- Tiêu đề
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Parent = MainFrame
TitleLabel.Size = UDim2.new(1, -50, 0, 22)
TitleLabel.Position = UDim2.new(0, 8, 0, 2)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "√12kientomato Mini (Anti-Player)"
TitleLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
TitleLabel.TextSize = 12
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- NÚT CỐ ĐỊNH (KHÓA / MỞ KHÓA VỊ TRÍ)
local LockBtn = Instance.new("TextButton")
LockBtn.Name = "LockBtn"
LockBtn.Parent = MainFrame
LockBtn.Size = UDim2.new(0, 32, 0, 20)
LockBtn.Position = UDim2.new(1, -36, 0, 3)
LockBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
LockBtn.BackgroundTransparency = 0.2
LockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LockBtn.Text = "🔓"
LockBtn.TextSize = 12
LockBtn.Font = Enum.Font.SourceSansBold

local LockCorner = Instance.new("UICorner")
LockCorner.CornerRadius = UDim.new(0, 5)
LockCorner.Parent = LockBtn

LockBtn.MouseButton1Click:Connect(function()
    isLocked = not isLocked
    if isLocked then
        MainFrame.Draggable = false
        ToggleButton.Draggable = false
        LockBtn.Text = "🔒"
        LockBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    else
        MainFrame.Draggable = true
        ToggleButton.Draggable = true
        LockBtn.Text = "🔓"
        LockBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    end
end)

ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

---------------------------------------------------------
-- CÁC NÚT BẤM VÀ ĐIỀU KHIỂN
---------------------------------------------------------

-- Nút Chọn Vị Trí (Chuyển nhanh Vị trí 1 <-> Vị trí 2)
local LocBtn = Instance.new("TextButton")
LocBtn.Parent = MainFrame
LocBtn.Size = UDim2.new(0, 110, 0, 24)
LocBtn.Position = UDim2.new(0, 8, 0, 28)
LocBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
LocBtn.BackgroundTransparency = 0.2
LocBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LocBtn.Text = "Chọn: Vị trí 1"
LocBtn.TextSize = 11
LocBtn.Font = Enum.Font.SourceSansBold

local LocCorner = Instance.new("UICorner")
LocCorner.CornerRadius = UDim.new(0, 5)
LocCorner.Parent = LocBtn

LocBtn.MouseButton1Click:Connect(function()
    if selectedLocation == "Vị trí 1" then
        selectedLocation = "Vị trí 2"
    else
        selectedLocation = "Vị trí 1"
    end
    LocBtn.Text = "Chọn: " .. selectedLocation
end)

-- Nút Lưu Vị Trí
local SaveBtn = Instance.new("TextButton")
SaveBtn.Parent = MainFrame
SaveBtn.Size = UDim2.new(0, 110, 0, 24)
SaveBtn.Position = UDim2.new(0, 122, 0, 28)
SaveBtn.BackgroundColor3 = Color3.fromRGB(40, 90, 40)
SaveBtn.BackgroundTransparency = 0.2
SaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveBtn.Text = "💾 Lưu Vị Trí"
SaveBtn.TextSize = 11
SaveBtn.Font = Enum.Font.SourceSansBold

local SaveCorner = Instance.new("UICorner")
SaveCorner.CornerRadius = UDim.new(0, 5)
SaveCorner.Parent = SaveBtn

-- Nút Bay / Teleport Ngay
local TpBtn = Instance.new("TextButton")
TpBtn.Parent = MainFrame
TpBtn.Size = UDim2.new(1, -16, 0, 30)
TpBtn.Position = UDim2.new(0, 8, 0, 56)
TpBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
TpBtn.BackgroundTransparency = 0.1
TpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TpBtn.Text = "🚀 BAY / TELEPORT NÉ ĐÒN"
TpBtn.TextSize = 12
TpBtn.Font = Enum.Font.SourceSansBold

local TpCorner = Instance.new("UICorner")
TpCorner.CornerRadius = UDim.new(0, 6)
TpCorner.Parent = TpBtn

-- Nút Đổi Chế Độ (Teleport / Tween)
local ModeBtn = Instance.new("TextButton")
ModeBtn.Parent = MainFrame
ModeBtn.Size = UDim2.new(0, 110, 0, 24)
ModeBtn.Position = UDim2.new(0, 8, 0, 92)
ModeBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
ModeBtn.BackgroundTransparency = 0.2
ModeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ModeBtn.Text = "Chế độ: Teleport"
ModeBtn.TextSize = 11
ModeBtn.Font = Enum.Font.SourceSans

local ModeCorner = Instance.new("UICorner")
ModeCorner.CornerRadius = UDim.new(0, 5)
ModeCorner.Parent = ModeBtn

ModeBtn.MouseButton1Click:Connect(function()
    if moveMethod == "Teleport" then
        moveMethod = "Tween"
        ModeBtn.Text = "Chế độ: Tween Né"
    else
        moveMethod = "Teleport"
        ModeBtn.Text = "Chế độ: Teleport"
    end
end)

-- Nút Bật/Tắt ESP Điểm Lưu
local EspBtn = Instance.new("TextButton")
EspBtn.Parent = MainFrame
EspBtn.Size = UDim2.new(0, 110, 0, 24)
EspBtn.Position = UDim2.new(0, 122, 0, 92)
EspBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 150)
EspBtn.BackgroundTransparency = 0.2
EspBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
EspBtn.Text = "ESP Vị Trí: Bật"
EspBtn.TextSize = 11
EspBtn.Font = Enum.Font.SourceSans

local EspCorner = Instance.new("UICorner")
EspCorner.CornerRadius = UDim.new(0, 5)
EspCorner.Parent = EspBtn

EspBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    EspBtn.Text = espEnabled and "ESP Vị Trí: Bật" or "ESP Vị Trí: Tắt"
end)

-- NÚT ESP NGƯỜI CHƠI (PLAYER ESP)
local PlayerEspBtn = Instance.new("TextButton")
PlayerEspBtn.Parent = MainFrame
PlayerEspBtn.Size = UDim2.new(1, -16, 0, 24)
PlayerEspBtn.Position = UDim2.new(0, 8, 0, 122)
PlayerEspBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 150)
PlayerEspBtn.BackgroundTransparency = 0.2
PlayerEspBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayerEspBtn.Text = "👁️ ESP Người Chơi: Đang Bật"
PlayerEspBtn.TextSize = 11
PlayerEspBtn.Font = Enum.Font.SourceSansBold

local PlayerEspCorner = Instance.new("UICorner")
PlayerEspCorner.CornerRadius = UDim.new(0, 5)
PlayerEspCorner.Parent = PlayerEspBtn

PlayerEspBtn.MouseButton1Click:Connect(function()
    playerEspEnabled = not playerEspEnabled
    PlayerEspBtn.Text = playerEspEnabled and "👁️ ESP Người Chơi: Đang Bật" or "👁️ ESP Người Chơi: Đang Tắt"
    if not playerEspEnabled then
        for _, obj in pairs(playerEspObjects) do
            if obj then obj:Destroy() end
        end
        playerEspObjects = {}
    end
end)

-- Nút Server Hop & Nhặt Tức Thì
local InstantEBtn = Instance.new("TextButton")
InstantEBtn.Parent = MainFrame
InstantEBtn.Size = UDim2.new(0, 110, 0, 22)
InstantEBtn.Position = UDim2.new(0, 8, 0, 154)
InstantEBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
InstantEBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
InstantEBtn.Text = "Bấm 'E' Nhanh: Tắt"
InstantEBtn.TextSize = 10
InstantEBtn.Font = Enum.Font.SourceSans

local ECorner = Instance.new("UICorner")
ECorner.CornerRadius = UDim.new(0, 4)
ECorner.Parent = InstantEBtn

InstantEBtn.MouseButton1Click:Connect(function()
    instantInteractEnabled = not instantInteractEnabled
    InstantEBtn.Text = instantInteractEnabled and "Bấm 'E' Nhanh: Bật" or "Bấm 'E' Nhanh: Tắt"
end)

local HopBtn = Instance.new("TextButton")
HopBtn.Parent = MainFrame
HopBtn.Size = UDim2.new(0, 110, 0, 22)
HopBtn.Position = UDim2.new(0, 122, 0, 154)
HopBtn.BackgroundColor3 = Color3.fromRGB(80, 50, 120)
HopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HopBtn.Text = "🌐 Chuyển Server"
HopBtn.TextSize = 10
HopBtn.Font = Enum.Font.SourceSans

local HopCorner = Instance.new("UICorner")
HopCorner.CornerRadius = UDim.new(0, 4)
HopCorner.Parent = HopBtn

-- NÚT SUPER FIX LAG
local FixLagBtn = Instance.new("TextButton")
FixLagBtn.Parent = MainFrame
FixLagBtn.Size = UDim2.new(1, -16, 0, 26)
FixLagBtn.Position = UDim2.new(0, 8, 0, 184)
FixLagBtn.BackgroundColor3 = Color3.fromRGB(180, 100, 0)
FixLagBtn.BackgroundTransparency = 0.1
FixLagBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FixLagBtn.Text = "⚡ FIX LAG SIÊU MƯỢT (MAX FPS)"
FixLagBtn.TextSize = 11
FixLagBtn.Font = Enum.Font.SourceSansBold

local FixLagCorner = Instance.new("UICorner")
FixLagCorner.CornerRadius = UDim.new(0, 5)
FixLagCorner.Parent = FixLagBtn

---------------------------------------------------------
-- TÍNH NĂNG FIX LAG CỰC KỲ MƯỢT
---------------------------------------------------------
local function applySuperFixLag()
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.Brightness = 1
        Lighting.Technology = Enum.Technology.Compatibility
    end)

    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") or effect:IsA("BlurEffect") or effect:IsA("SunRaysEffect") then
            effect.Enabled = false
        end
    end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
            obj.Enabled = false
        elseif obj:IsA("Explosion") then
            obj.Visible = false
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Transparency = 1
        elseif obj:IsA("BasePart") then
            local isImportantItem = obj:FindFirstChildOfClass("ProximityPrompt") 
                or obj:FindFirstChildOfClass("ClickDetector") 
                or obj:FindFirstChildOfClass("TouchTransmitter")
                or obj:IsDescendantOf(LocalPlayer.Character)
                or (obj.Parent and obj.Parent:FindFirstChildOfClass("Humanoid"))

            if not isImportantItem then
                obj.Material = Enum.Material.SmoothPlastic
                obj.Reflectance = 0
                obj.CastShadow = false
            end
        end
    end
end

FixLagBtn.MouseButton1Click:Connect(function()
    isFixLagActive = not isFixLagActive
    if isFixLagActive then
        applySuperFixLag()
        FixLagBtn.Text = "✔ ĐÃ BẬT FIX LAG SIÊU MƯỢT"
        FixLagBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 60)
    else
        FixLagBtn.Text = "⚡ FIX LAG SIÊU MƯỢT (MAX FPS)"
        FixLagBtn.BackgroundColor3 = Color3.fromRGB(180, 100, 0)
    end
end)

---------------------------------------------------------
-- HỆ THỐNG PLAYER ESP (HIỂN THỊ NGƯỜI CHƠI KHÁC)
---------------------------------------------------------
local function updatePlayerESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if playerEspEnabled and char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") and char.Humanoid.Health > 0 then
                local hrp = char.HumanoidRootPart
                if not playerEspObjects[player] then
                    local highlight = Instance.new("Highlight")
                    highlight.Adornee = char
                    highlight.FillColor = Color3.fromRGB(255, 0, 0)
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.Parent = playerEspFolder

                    local bbGui = Instance.new("BillboardGui")
                    bbGui.Size = UDim2.new(0, 120, 0, 30)
                    bbGui.StudsOffset = Vector3.new(0, 2.5, 0)
                    bbGui.AlwaysOnTop = true
                    bbGui.Adornee = hrp
                    bbGui.Parent = playerEspFolder

                    local txt = Instance.new("TextLabel")
                    txt.Size = UDim2.new(1, 0, 1, 0)
                    txt.BackgroundTransparency = 1
                    txt.TextColor3 = Color3.fromRGB(255, 100, 100)
                    txt.TextStrokeTransparency = 0
                    txt.TextSize = 11
                    txt.Font = Enum.Font.SourceSansBold
                    txt.Parent = bbGui

                    playerEspObjects[player] = {Highlight = highlight, Gui = bbGui, Text = txt}
                else
                    local data = playerEspObjects[player]
                    if data and data.Text and data.Gui then
                        data.Highlight.Enabled = true
                        data.Gui.Enabled = true
                        local localHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if localHrp then
                            local dist = math.floor((localHrp.Position - hrp.Position).Magnitude)
                            data.Text.Text = string.format("%s (%dm)", player.Name, dist)
                        end
                    end
                end
            else
                if playerEspObjects[player] then
                    playerEspObjects[player].Highlight.Enabled = false
                    playerEspObjects[player].Gui.Enabled = false
                end
            end
        end
    end
end

task.spawn(function()
    while true do
        task.wait(0.3)
        pcall(updatePlayerESP)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if playerEspObjects[player] then
        playerEspObjects[player].Highlight:Destroy()
        playerEspObjects[player].Gui:Destroy()
        playerEspObjects[player] = nil
    end
end)

---------------------------------------------------------
-- LOGIC CẢI TIẾN SERVER HOP
---------------------------------------------------------
local function HopToLowestServer()
    HopBtn.Text = "⌛ Đang tìm..."
    local placeId = game.PlaceId
    local req = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
    
    if not req then
        HopBtn.Text = "❌ Lỗi Executor"
        task.wait(1.5)
        HopBtn.Text = "🌐 Chuyển Server"
        return
    end
    
    local url = string.format("https://games.roblox.com/v1/games/%d/servers/0?sortOrder=Asc&limit=100", placeId)
    local success, response = pcall(function()
        return HttpService:JSONDecode(req({Url = url, Method = "GET"}).Body)
    end)
    
    if success and response and response.data then
        local validServers = {}
        for _, server in ipairs(response.data) do
            if server.playing > 0 and server.playing < (server.maxPlayers - 2) and server.id ~= game.JobId then
                table.insert(validServers, server)
            end
        end
        
        table.sort(validServers, function(a, b) return a.playing < b.playing end)
        
        if #validServers > 0 then
            HopBtn.Text = "🚀 Đang chuyển..."
            local targetServer = validServers[math.random(1, math.min(3, #validServers))]
            TeleportService:TeleportToPlaceInstance(placeId, targetServer.id, LocalPlayer)
        else
            HopBtn.Text = "❌ Không thấy SV"
            task.wait(1.5)
            HopBtn.Text = "🌐 Chuyển Server"
        end
    else
        HopBtn.Text = "❌ Lỗi HTTP"
        task.wait(1.5)
        HopBtn.Text = "🌐 Chuyển Server"
    end
end

HopBtn.MouseButton1Click:Connect(function()
    HopToLowestServer()
end)

---------------------------------------------------------
-- LOGIC TÍNH NĂNG ESP ĐIỂM LƯU & BAY NÉ ĐÒN THÔNG MINH
---------------------------------------------------------
local function createESP(locName, cframe)
    if espObjects[locName] then
        if espObjects[locName].Part then espObjects[locName].Part:Destroy() end
        espObjects[locName] = nil
    end

    local espPart = Instance.new("Part")
    espPart.Name = "ESP_" .. locName
    espPart.Size = Vector3.new(2, 4, 1)
    espPart.CFrame = cframe
    espPart.Anchored = true
    espPart.CanCollide = false
    espPart.Transparency = 0.5
    espPart.Color = Color3.fromRGB(255, 50, 50)
    espPart.Material = Enum.Material.Neon
    espPart.Parent = espFolder

    local highlight = Instance.new("Highlight")
    highlight.Adornee = espPart
    highlight.FillColor = Color3.fromRGB(255, 80, 80)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.3
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = espPart

    local bbGui = Instance.new("BillboardGui")
    bbGui.Name = "ESP_Text"
    bbGui.Size = UDim2.new(0, 150, 0, 40)
    bbGui.StudsOffset = Vector3.new(0, 3, 0)
    bbGui.AlwaysOnTop = true
    bbGui.Adornee = espPart
    bbGui.Parent = espPart

    local txtLabel = Instance.new("TextLabel")
    txtLabel.Size = UDim2.new(1, 0, 1, 0)
    txtLabel.BackgroundTransparency = 1
    txtLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    txtLabel.TextStrokeTransparency = 0
    txtLabel.TextSize = 12
    txtLabel.Font = Enum.Font.SourceSansBold
    txtLabel.Text = string.format("[%s]\n0m", locName)
    txtLabel.Parent = bbGui

    espObjects[locName] = {
        Part = espPart,
        TextLabel = txtLabel,
        Position = cframe.Position
    }
end

task.spawn(function()
    while true do
        task.wait(0.1)
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local hrpP
        task.spawn(function()
    while true do
        task.wait(0.1)
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local hrpPos = character.HumanoidRootPart.Position
            for name, data in pairs(espObjects) do
                if data and data.Part and data.Part.Parent then
                    data.Part.Transparency = espEnabled and 0.5 or 1
                    data.TextLabel.Visible = espEnabled
                    
                    if espEnabled then
                        local dist = math.floor((hrpPos - data.Position).Magnitude)
                        data.TextLabel.Text = string.format("[%s]\n%dm", name, dist)
                    end
                end
            end
        end
    end
end)

SaveBtn.MouseButton1Click:Connect(function()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local cframe = character.HumanoidRootPart.CFrame
        savedPositions[selectedLocation] = cframe
        createESP(selectedLocation, cframe)
    end
end)

-- Thuật toán bay né tránh khi Tween
TpBtn.MouseButton1Click:Connect(function()
    local targetCFrame = savedPositions[selectedLocation]
    if not targetCFrame then return end

    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = character.HumanoidRootPart

    if moveMethod == "Teleport" then
        hrp.CFrame = targetCFrame
    elseif moveMethod == "Tween" then
        local startPos = hrp.Position
        local targetPos = targetCFrame.Position
        
        -- Bay cao lên 55m so với vị trí đích để né đòn
        local highTargetPos = Vector3.new(targetPos.X, targetPos.Y + 55, targetPos.Z)
        
        -- Tính thời gian bay đến điểm cao với tốc độ 165
        local distanceHigh = (hrp.Position - highTargetPos).Magnitude
        local durationHigh = distanceHigh / travelSpeed
        
        local tweenHigh = TweenService:Create(hrp, TweenInfo.new(durationHigh, Enum.EasingStyle.Linear), {CFrame = CFrame.new(highTargetPos)})
        tweenHigh:Play()
        tweenHigh.Completed:Wait()
        
        -- Vòng lặp lạng lách trái/phải 20m mỗi 3.5 giây trên không trung
        local dodging = true
        local sideToggle = 1
        
        task.spawn(function()
            while dodging do
                task.wait(3.5)
                if not dodging then break end
                sideToggle = sideToggle * -1
                
                local currentHrp = character:FindFirstChild("HumanoidRootPart")
                if currentHrp then
                    local rightVec = currentHrp.CFrame.RightVector
                    local dodgeTarget = Vector3.new(targetPos.X, targetPos.Y + 55, targetPos.Z) + (rightVec * (20 * sideToggle))
                    local dodgeTween = TweenService:Create(currentHrp, TweenInfo.new(1.2, Enum.EasingStyle.Sine), {CFrame = CFrame.new(dodgeTarget, targetPos)})
                    dodgeTween:Play()
                end
            end
        end)
        
        -- Bay từ từ về vị trí chính xác cuối cùng với tốc độ 165
        local finalDistance = (hrp.Position - targetPos).Magnitude
        local finalDuration = finalDistance / travelSpeed
        local tweenFinal = TweenService:Create(hrp, TweenInfo.new(finalDuration, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
        tweenFinal:Play()
        tweenFinal.Completed:Wait()
        
        dodging = false
    end
end)

task.spawn(function()
    while true do
        task.wait(0.2)
        if instantInteractEnabled then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    obj.HoldDuration = 0
                end
            end
        end
    end
end)
        
