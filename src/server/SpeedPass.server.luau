--!strict
-- Server side of the 2x speed pass: ownership, purchases, the free trial,
-- and analytics for the upsell UI. The server alone decides who is fast.

local AnalyticsService = game:GetService("AnalyticsService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SpeedConfig = require(ReplicatedStorage:WaitForChild("SpeedConfig"))

local remotes = Instance.new("Folder")
remotes.Name = SpeedConfig.REMOTES_FOLDER

local startTrialRemote = Instance.new("RemoteEvent")
startTrialRemote.Name = "StartTrial"
startTrialRemote.Parent = remotes

local logRemote = Instance.new("RemoteEvent")
logRemote.Name = "LogUpsell"
logRemote.Parent = remotes

remotes.Parent = ReplicatedStorage

-- Only these names may be logged from the client.
local LOGGABLE_EVENTS: { [string]: boolean } = {
	SpeedOfferShown = true,
	SpeedOfferBuyClicked = true,
	SpeedHudClicked = true,
	SpeedTrialEndedOfferShown = true,
}
local LOG_INTERVAL = 2
local lastLogAt: { [Player]: number } = {}

local function isBoosted(player: Player): boolean
	if player:GetAttribute("HasSpeedPass") == true then
		return true
	end
	local trialEndsAt = player:GetAttribute("SpeedTrialEndsAt")
	return typeof(trialEndsAt) == "number" and trialEndsAt > workspace:GetServerTimeNow()
end

local function applySpeed(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local multiplier = if isBoosted(player) then SpeedConfig.MULTIPLIER else 1
	humanoid.WalkSpeed = SpeedConfig.BASE_WALKSPEED * multiplier
end

local function logEvent(player: Player, eventName: string)
	pcall(AnalyticsService.LogCustomEvent, AnalyticsService, player, eventName)
end

local function onCharacterAdded(player: Player, character: Model)
	character:WaitForChild("Humanoid", 10)
	applySpeed(player)
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)

	local ok, owns = pcall(
		MarketplaceService.UserOwnsGamePassAsync,
		MarketplaceService,
		player.UserId,
		SpeedConfig.GAMEPASS_ID
	)
	-- The client waits for this attribute before showing any upsell UI.
	player:SetAttribute("HasSpeedPass", ok and owns == true)

	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, purchased)
	if purchased and gamePassId == SpeedConfig.GAMEPASS_ID then
		player:SetAttribute("HasSpeedPass", true)
		applySpeed(player)
		logEvent(player, "SpeedPassPurchased")
	end
end)

startTrialRemote.OnServerEvent:Connect(function(player)
	if player:GetAttribute("HasSpeedPass") ~= false or player:GetAttribute("SpeedTrialUsed") == true then
		return
	end
	player:SetAttribute("SpeedTrialUsed", true)
	player:SetAttribute("SpeedTrialEndsAt", workspace:GetServerTimeNow() + SpeedConfig.TRIAL_SECONDS)
	applySpeed(player)
	logEvent(player, "SpeedTrialStarted")

	task.delay(SpeedConfig.TRIAL_SECONDS, function()
		if player.Parent then
			applySpeed(player)
		end
	end)
end)

logRemote.OnServerEvent:Connect(function(player, eventName: unknown)
	if typeof(eventName) ~= "string" or not LOGGABLE_EVENTS[eventName] then
		return
	end
	local now = os.clock()
	if now - (lastLogAt[player] or 0) < LOG_INTERVAL then
		return
	end
	lastLogAt[player] = now
	logEvent(player, eventName)
end)

Players.PlayerRemoving:Connect(function(player)
	lastLogAt[player] = nil
end)

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
