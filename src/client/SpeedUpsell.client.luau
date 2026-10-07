--!strict
-- Client upsell UI for the 2x speed pass:
--   * a pulsing HUD button that is always on screen
--   * a popup offer at the moments players tend to quit (after joining,
--     on reaching a zone, or when stuck in one zone too long)
--   * a free trial with a countdown, followed by a "keep it" offer

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SpeedConfig = require(ReplicatedStorage:WaitForChild("SpeedConfig"))
local remotes = ReplicatedStorage:WaitForChild(SpeedConfig.REMOTES_FOLDER)
local startTrialRemote = remotes:WaitForChild("StartTrial") :: RemoteEvent
local logRemote = remotes:WaitForChild("LogUpsell") :: RemoteEvent

local player = Players.LocalPlayer
local PRICE_TEXT = utf8.char(0xE002) .. tostring(SpeedConfig.PRICE) -- Robux icon + price

local GOLD = Color3.fromRGB(255, 200, 40)
local ORANGE = Color3.fromRGB(255, 120, 20)
local GREEN = Color3.fromRGB(60, 210, 90)
local DARK = Color3.fromRGB(24, 24, 32)

-- UI helpers ---------------------------------------------------------------

local function addCorner(parent: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(radius, 0)
	corner.Parent = parent
end

local function addStroke(parent: Instance, color: Color3, thickness: number)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
end

local function makeText(
	class: "TextLabel" | "TextButton",
	parent: Instance,
	text: string,
	position: UDim2,
	size: UDim2,
	maxTextSize: number
): TextLabel | TextButton
	local obj = Instance.new(class) :: any
	obj.BackgroundTransparency = 1
	obj.Text = text
	obj.Font = Enum.Font.FredokaOne
	obj.TextColor3 = Color3.new(1, 1, 1)
	obj.TextScaled = true
	obj.AnchorPoint = Vector2.new(0.5, 0.5)
	obj.Position = position
	obj.Size = size
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = maxTextSize
	limit.Parent = obj
	local outline = Instance.new("UIStroke")
	outline.Thickness = 2
	outline.Color = Color3.new(0, 0, 0)
	outline.Parent = obj
	obj.Parent = parent
	return obj
end

local function makeButton(parent: Instance, text: string, color: Color3, position: UDim2, size: UDim2): TextButton
	local button = makeText("TextButton", parent, text, position, size, 32) :: TextButton
	button.BackgroundTransparency = 0
	button.BackgroundColor3 = color
	button.AutoButtonColor = true
	addCorner(button, 0.25)
	addStroke(button, Color3.new(0, 0, 0), 3)
	return button
end

-- Build UI -----------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "SpeedUpsell"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10
gui.Parent = player:WaitForChild("PlayerGui")

-- HUD button (left side, always visible for non-owners)
local hudButton = Instance.new("ImageButton")
hudButton.Name = "SpeedHudButton"
hudButton.AnchorPoint = Vector2.new(0, 0.5)
hudButton.Position = UDim2.fromScale(0.015, 0.5)
hudButton.Size = UDim2.fromScale(0.12, 0.12)
hudButton.BackgroundColor3 = Color3.new(1, 1, 1)
hudButton.Visible = false
hudButton.Parent = gui
addCorner(hudButton, 0.2)
addStroke(hudButton, Color3.new(0, 0, 0), 3)

local hudAspect = Instance.new("UIAspectRatioConstraint")
hudAspect.AspectRatio = 1
hudAspect.Parent = hudButton

local hudGradient = Instance.new("UIGradient")
hudGradient.Color = ColorSequence.new(GOLD, ORANGE)
hudGradient.Rotation = 90
hudGradient.Parent = hudButton

local hudScale = Instance.new("UIScale")
hudScale.Parent = hudButton

makeText("TextLabel", hudButton, "⚡", UDim2.fromScale(0.5, 0.3), UDim2.fromScale(0.6, 0.4), 60)
makeText("TextLabel", hudButton, "2x SPEED", UDim2.fromScale(0.5, 0.64), UDim2.fromScale(0.9, 0.22), 24)

local priceTag = makeText("TextLabel", hudButton, PRICE_TEXT, UDim2.fromScale(0.85, 0.05), UDim2.fromScale(0.55, 0.28), 22)
priceTag.BackgroundTransparency = 0
priceTag.BackgroundColor3 = GREEN
priceTag.Rotation = 12
addCorner(priceTag, 0.4)
addStroke(priceTag, Color3.new(0, 0, 0), 2)

local trialTimer =
	makeText("TextLabel", hudButton, "", UDim2.fromScale(0.5, 1.2), UDim2.fromScale(1.4, 0.25), 24) :: TextLabel
trialTimer.TextColor3 = GOLD
trialTimer.Visible = false

-- Constant attention pulse
TweenService:Create(
	hudScale,
	TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ Scale = 1.1 }
):Play()

-- Popup offer (centre of screen)
local popup = Instance.new("Frame")
popup.Name = "SpeedOffer"
popup.AnchorPoint = Vector2.new(0.5, 0.5)
popup.Position = UDim2.fromScale(0.5, 0.5)
popup.Size = UDim2.fromScale(0.4, 0.45)
popup.BackgroundColor3 = DARK
popup.Visible = false
popup.Parent = gui
addCorner(popup, 0.08)
addStroke(popup, GOLD, 4)

local popupAspect = Instance.new("UIAspectRatioConstraint")
popupAspect.AspectRatio = 1.5
popupAspect.Parent = popup

local popupScale = Instance.new("UIScale")
popupScale.Parent = popup

local titleLabel =
	makeText("TextLabel", popup, "", UDim2.fromScale(0.5, 0.17), UDim2.fromScale(0.85, 0.2), 48) :: TextLabel
titleLabel.TextColor3 = GOLD
local bodyLabel = makeText("TextLabel", popup, "", UDim2.fromScale(0.5, 0.38), UDim2.fromScale(0.85, 0.16), 28) :: TextLabel

local buyButton = makeButton(popup, "", GREEN, UDim2.fromScale(0.5, 0.6), UDim2.fromScale(0.7, 0.2))
local trialButton = makeButton(popup, "", Color3.fromRGB(70, 120, 255), UDim2.fromScale(0.5, 0.83), UDim2.fromScale(0.55, 0.14))
local closeButton = makeButton(popup, "X", Color3.fromRGB(220, 60, 60), UDim2.fromScale(0.97, 0.03), UDim2.fromScale(0.09, 0.13))

-- State --------------------------------------------------------------------

local popupsShown = 0
local lastPopupAt = -math.huge
local lastZoneChangeAt = os.clock()
local trialWasActive = false

local function ownsPass(): boolean
	return player:GetAttribute("HasSpeedPass") == true
end

local function ownershipKnown(): boolean
	return player:GetAttribute("HasSpeedPass") ~= nil
end

local function trialSecondsLeft(): number
	local endsAt = player:GetAttribute("SpeedTrialEndsAt")
	if typeof(endsAt) ~= "number" then
		return 0
	end
	return math.max(0, endsAt - workspace:GetServerTimeNow())
end

local function trialAvailable(): boolean
	return player:GetAttribute("SpeedTrialUsed") ~= true
end

local function promptPurchase()
	MarketplaceService:PromptGamePassPurchase(player, SpeedConfig.GAMEPASS_ID)
end

local function hidePopup()
	popup.Visible = false
end

local function showPopup(title: string, body: string, eventName: string)
	titleLabel.Text = title
	bodyLabel.Text = body
	buyButton.Text = "BUY 2x SPEED  " .. PRICE_TEXT
	trialButton.Text = `TRY FREE ({SpeedConfig.TRIAL_SECONDS}s)`
	trialButton.Visible = trialAvailable()

	popupsShown += 1
	lastPopupAt = os.clock()
	popupScale.Scale = 0.2
	popup.Visible = true
	TweenService:Create(popupScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
		:Play()
	logRemote:FireServer(eventName)
end

-- Automatic offers respect the cooldown and session cap so they don't nag.
local function tryAutoOffer(body: string)
	if not ownershipKnown() or ownsPass() or trialSecondsLeft() > 0 or popup.Visible then
		return
	end
	if popupsShown >= SpeedConfig.MAX_POPUPS_PER_SESSION then
		return
	end
	if os.clock() - lastPopupAt < SpeedConfig.OFFER_COOLDOWN then
		return
	end
	showPopup("GO 2x FASTER! ⚡", body, "SpeedOfferShown")
end

local function refreshVisibility()
	local owned = ownsPass()
	hudButton.Visible = ownershipKnown() and not owned
	if owned then
		hidePopup()
	end
end

-- Wiring -------------------------------------------------------------------

hudButton.Activated:Connect(function()
	logRemote:FireServer("SpeedHudClicked")
	promptPurchase()
end)

buyButton.Activated:Connect(function()
	logRemote:FireServer("SpeedOfferBuyClicked")
	promptPurchase()
end)

trialButton.Activated:Connect(function()
	startTrialRemote:FireServer()
	hidePopup()
end)

closeButton.Activated:Connect(hidePopup)

player:GetAttributeChangedSignal("HasSpeedPass"):Connect(refreshVisibility)
refreshVisibility()

player:GetAttributeChangedSignal(SpeedConfig.ZONE_ATTRIBUTE):Connect(function()
	lastZoneChangeAt = os.clock()
	local zone = player:GetAttribute(SpeedConfig.ZONE_ATTRIBUTE)
	local nextZone = typeof(zone) == "string" and SpeedConfig.OFFER_ZONES[zone]
	if nextZone then
		task.delay(SpeedConfig.ZONE_OFFER_DELAY, function()
			tryAutoOffer(`Reach {nextZone} in half the time!`)
		end)
	end
end)

task.delay(SpeedConfig.FIRST_OFFER_DELAY, function()
	tryAutoOffer("Explore every zone twice as fast!")
end)

-- Trial countdown and stall detection
while true do
	task.wait(0.25)

	local secondsLeft = trialSecondsLeft()
	if secondsLeft > 0 then
		trialWasActive = true
		trialTimer.Visible = true
		trialTimer.Text = `2x TRIAL: {math.ceil(secondsLeft)}s`
	elseif trialWasActive then
		trialWasActive = false
		trialTimer.Visible = false
		lastZoneChangeAt = os.clock()
		if not ownsPass() then
			showPopup("Speed trial over!", "Keep 2x speed FOREVER", "SpeedTrialEndedOfferShown")
		end
	end

	if os.clock() - lastZoneChangeAt > SpeedConfig.STALL_SECONDS then
		lastZoneChangeAt = os.clock()
		tryAutoOffer("Stuck? Get there twice as fast!")
	end
end
