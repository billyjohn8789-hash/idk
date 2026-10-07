--!strict
-- Settings for the 2x speed shortcut button.

local SpeedConfig = {
	GAMEPASS_ID = 0, -- TODO: paste your existing 2x speed game pass ID here
	PRICE = 3, -- shown under the button; keep in sync with the pass price

	-- Image asset IDs (upload assets/speed-ui/*.png in Studio's Asset Manager)
	IMAGES = {
		Shoe = 0, -- speed_shoe.png
		Shine = 0, -- speed_shine.png
	},
}

return SpeedConfig
