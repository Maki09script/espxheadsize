-- Lightweight ESP (Name + Distance + Health) + Full Body Outline
-- ESP ONLY – White text, fully readable

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ESP SETTINGS
local ESPEnabled = true
local ESPToggleKey = Enum.KeyCode.P
local ESPColor = Color3.fromRGB(255, 0, 0) -- outline color
local TEXTColor = Color3.fromRGB(255, 255, 255) -- text color (white)
local ESP_SIZE = UDim2.new(0, 100, 0, 24)
local ESP_UPDATE_INTERVAL = 0.15
local OUTLINE_TRANSPARENCY = 0.95 -- faint outline

-- INTERNAL CACHE
local espByPlayer = {}
local activePlayers = {}

local math_floor = math.floor

-- CREATE OUTLINE
local function createOutline(character)
	if not character or not character.Parent then return end
	if character:FindFirstChild("ESPHighlight") then return end
	local highlight = Instance.new("Highlight")
	highlight.Name = "ESPHighlight"
	highlight.FillTransparency = 1 -- invisible fill
	highlight.OutlineColor = ESPColor
	highlight.OutlineTransparency = OUTLINE_TRANSPARENCY
	highlight.Adornee = character
	highlight.Parent = character
end

-- REMOVE OUTLINE
local function removeOutline(character)
	local highlight = character:FindFirstChild("ESPHighlight")
	if highlight then
		highlight:Destroy()
	end
end

-- CREATE ESP
local function createESP(player, character)
	if not character or not character.Parent then return end
	local head = character:FindFirstChild("Head")
	if not head then return end

	if head:FindFirstChild("NameESP") then
		head.NameESP:Destroy()
	end

	-- BillboardGui
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NameESP"
	billboard.Adornee = head
	billboard.AlwaysOnTop = true
	billboard.Size = ESP_SIZE
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.Enabled = ESPEnabled
	billboard.Parent = head

	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Size = UDim2.new(1, 0, 1, 0)
	text.TextColor3 = TEXTColor -- white
	text.TextStrokeColor3 = Color3.new(0, 0, 0) -- black stroke for readability
	text.TextStrokeTransparency = 0.2
	text.TextScaled = true
	text.Font = Enum.Font.SourceSansBold
	text.Parent = billboard

	espByPlayer[player] = {
		billboard = billboard,
		text = text,
		head = head,
		character = character
	}

	createOutline(character)
end

-- ENSURE ESP
local function ensureESP(player)
	if player == LocalPlayer then return end
	local char = player.Character
	if not char or not char.Parent then return end

	local info = espByPlayer[player]
	if info and info.character == char then return end

	createESP(player, char)
end

-- REMOVE ESP
local function removeESP(player)
	local info = espByPlayer[player]
	if info then
		if info.billboard then
			info.billboard:Destroy()
		end
		if info.character then
			removeOutline(info.character)
		end
	end
	espByPlayer[player] = nil
end

-- ACTIVE PLAYER LIST
local function rebuildPlayers()
	table.clear(activePlayers)
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			table.insert(activePlayers, p)
		end
	end
end

-- INITIALIZE
rebuildPlayers()
for _, p in ipairs(activePlayers) do
	ensureESP(p)
end

-- PLAYER EVENTS
Players.PlayerAdded:Connect(function(player)
	rebuildPlayers()
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		ensureESP(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	removeESP(player)
	rebuildPlayers()
end)

for _, p in ipairs(Players:GetPlayers()) do
	p.CharacterAdded:Connect(function()
		task.wait(0.5)
		ensureESP(p)
	end)
end

-- ESP UPDATE LOOP
do
	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator < ESP_UPDATE_INTERVAL then return end
		accumulator = 0

		local camPos = Camera.CFrame.Position
		for _, player in ipairs(activePlayers) do
			local info = espByPlayer[player]
			if info and info.head and info.head.Parent then
				local humanoid = info.character:FindFirstChildOfClass("Humanoid")
				local healthText = humanoid and math_floor(humanoid.Health) or 0
				if ESPEnabled then
					local dist = math_floor((camPos - info.head.Position).Magnitude)
					info.text.Text = player.DisplayName .. "(" .. dist .. "m)HP: ".. healthText .. ""
					info.billboard.Enabled = true

					local highlight = info.character:FindFirstChild("ESPHighlight")
					if highlight then
						highlight.OutlineTransparency = OUTLINE_TRANSPARENCY
					end
				else
					info.billboard.Enabled = false
					local highlight = info.character:FindFirstChild("ESPHighlight")
					if highlight then
						highlight.OutlineTransparency = 1
					end
				end
			else
				ensureESP(player)
			end
		end
	end)
end

-- TOGGLE ESP
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == ESPToggleKey then
		ESPEnabled = not ESPEnabled
	end
end)

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- SETTINGS
local OnKey = Enum.KeyCode.T
local OffKey = Enum.KeyCode.E
local HeadSize = Vector3.new(3, 3, 3)
local ResizeEnabled = false
local normalSizes = {} -- store each player's original head size
local UPDATE_INTERVAL = 0.15

-- FUNCTION TO RESIZE HEAD
local function resizeHead(player, size)
    local char = player.Character
    if char then
        local head = char:FindFirstChild("Head")
        if head then
            local mesh = head:FindFirstChildOfClass("SpecialMesh")
            if mesh then
                mesh.Scale = size
            else
                head.Size = size
            end
        end
    end
end

-- ENSURE HEAD SIZE STORED
local function ensureNormalSize(player)
    if normalSizes[player] then return end
    local char = player.Character
    if char then
        local head = char:FindFirstChild("Head")
        if head then
            local mesh = head:FindFirstChildOfClass("SpecialMesh")
            normalSizes[player] = mesh and mesh.Scale or head.Size
        end
    end
end

-- MAIN LOOP
local accumulator = 0
RunService.Heartbeat:Connect(function(dt)
    accumulator += dt
    if accumulator < UPDATE_INTERVAL then return end
    accumulator = 0

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            ensureNormalSize(player)
            if ResizeEnabled then
                resizeHead(player, HeadSize)
            else
                resizeHead(player, normalSizes[player])
            end
        end
    end
end)

-- INPUT HANDLER
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == OnKey then
        ResizeEnabled = true
    elseif input.KeyCode == OffKey then
        ResizeEnabled = false
    end
end)

-- HANDLE PLAYER JOIN/RESPAWN
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        ensureNormalSize(player)
    end)
end)

for _, player in pairs(Players:GetPlayers()) do
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        ensureNormalSize(player)
    end)
end
