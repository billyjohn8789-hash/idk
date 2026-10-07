--!strict
-- Shared settings for the 2x speed game pass and its upsell UI.

local SpeedConfig = {
	GAMEPASS_ID = 0, -- TODO: paste your 2x speed game pass ID here
	PRICE = 3, -- shown on the buttons; keep in sync with the pass price

	BASE_WALKSPEED = 16,
	MULTIPLIER = 2,

	-- Free trial: one per server session. A taste of the speed sells it.
	TRIAL_SECONDS = 45,

	-- Popup pacing (seconds)
	FIRST_OFFER_DELAY = 40, -- first popup after joining
	ZONE_OFFER_DELAY = 3, -- popup shortly after entering an OFFER_ZONES zone
	STALL_SECONDS = 75, -- popup if the player hasn't reached a new zone in this long
	OFFER_COOLDOWN = 120, -- minimum gap between popups
	MAX_POPUPS_PER_SESSION = 4,

	-- Player attribute your zone code sets, e.g. player:SetAttribute("CurrentZone", "Plains")
	ZONE_ATTRIBUTE = "CurrentZone",

	-- Entering one of these zones triggers an offer that names the next zone.
	-- Plains -> Barnyard and Barnyard -> MoonlitPasture are where most players quit.
	OFFER_ZONES = {
		Plains = "Barnyard",
		Barnyard = "Moonlit Pasture",
		MoonlitPasture = "Thornwood Forest",
		ThornwoodForest = "Crystal Highlands",
	} :: { [string]: string },

	-- Image asset IDs for the Figma-designed UI (upload assets/speed-ui/*.png).
	-- Leave any at 0 to use the built-in code-drawn style for that piece.
	IMAGES = {
		HudButton = 0, -- speed_hud_bg.png
		Popup = 0, -- speed_popup_bg.png
		BuyButton = 0, -- speed_buy_btn.png
		TrialButton = 0, -- speed_trial_btn.png
		CloseButton = 0, -- speed_close_btn.png
		PriceTag = 0, -- speed_price_tag.png
	},

	REMOTES_FOLDER = "SpeedRemotes",
}

return SpeedConfig
