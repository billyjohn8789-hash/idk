--!strict
-- HUD shortcut to the 2x speed game pass: a shoe with a spinning shine behind it,
-- "2x SPEED" and the price underneath. Clicking it opens the purchase prompt.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SpeedConfig = require(ReplicatedStorage:WaitForChild("SpeedConfig"))

local player = Players.LocalPlayer

local function addSquare(parent: Instance)
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1
	aspect.Parent = parent
end

local function makeText(parent: Instance, text: string, position: UDim2, size: UDim2, color: Color3): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = position
	label.Size = size
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	local outline = Instance.new("UIStroke")
	outline.Thickness = 2.5
	outline.Parent = label
	label.Parent = parent
	return label
end

local gui = Instance.new("ScreenGui")
gui.Name = "SpeedShortcut"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("ImageButton")
button.Name = "SpeedButton"
button.BackgroundTransparency = 1
button.AnchorPoint = Vector2.new(0, 0.5)
button.Position = UDim2.fromScale(0.015, 0.5)
button.Size = UDim2.fromScale(0.08, 0.2)
button.Visible = false
button.Parent = gui

local buttonAspect = Instance.new("UIAspectRatioConstraint")
buttonAspect.AspectRatio = 0.8
buttonAspect.Parent = button

local shine = Instance.new("ImageLabel")
shine.Name = "Shine"
shine.BackgroundTransparency = 1
shine.AnchorPoint = Vector2.new(0.5, 0.5)
shine.Position = UDim2.fromScale(0.5, 0.38)
shine.Size = UDim2.fromScale(1.5, 1.5)
shine.Image = "rbxassetid://" .. SpeedConfig.IMAGES.Shine
shine.Visible = SpeedConfig.IMAGES.Shine ~= 0
shine.Parent = button
addSquare(shine)

if SpeedConfig.IMAGES.Shoe ~= 0 then
	local shoe = Instance.new("ImageLabel")
	shoe.Name = "Shoe"
	shoe.BackgroundTransparency = 1
	shoe.AnchorPoint = Vector2.new(0.5, 0.5)
	shoe.Position = UDim2.fromScale(0.5, 0.38)
	shoe.Size = UDim2.fromScale(0.95, 0.95)
	shoe.Image = "rbxassetid://" .. SpeedConfig.IMAGES.Shoe
	shoe.Parent = button
	addSquare(shoe)
else
	makeText(button, "👟", UDim2.fromScale(0.5, 0.38), UDim2.fromScale(0.8, 0.5), Color3.new(1, 1, 1))
end

makeText(button, "2x SPEED", UDim2.fromScale(0.5, 0.8), UDim2.fromScale(1.2, 0.18), Color3.new(1, 1, 1))
makeText(
	button,
	utf8.char(0xE002) .. tostring(SpeedConfig.PRICE), -- Robux icon + price
	UDim2.fromScale(0.5, 0.96),
	UDim2.fromScale(0.8, 0.15),
	Color3.fromRGB(107, 242, 127)
)

TweenService:Create(shine, TweenInfo.new(8, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = 360 })
	:Play()

button.Activated:Connect(function()
	MarketplaceService:PromptGamePassPurchase(player, SpeedConfig.GAMEPASS_ID)
end)

-- Hide the button for players who already own the pass.
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(buyer, gamePassId, purchased)
	if buyer == player and gamePassId == SpeedConfig.GAMEPASS_ID and purchased then
		button.Visible = false
	end
end)

local ok, owns = pcall(
	MarketplaceService.UserOwnsGamePassAsync,
	MarketplaceService,
	player.UserId,
	SpeedConfig.GAMEPASS_ID
)
button.Visible = not (ok and owns == true)
