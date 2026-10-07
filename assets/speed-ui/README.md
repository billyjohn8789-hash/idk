# 2x Speed UI images

Designed in Figma: https://www.figma.com/design/PKqZDsNx55iZbS69u55ZKG

1. In Roblox Studio, open **Window > Asset Manager**, click **Bulk Import**, and pick every
   `speed_*.png` in this folder (skip `_preview.png`).
2. Right-click each uploaded image > **Copy Asset ID**.
3. Paste the numbers into `IMAGES` in `src/shared/SpeedConfig.luau`:

| File | Config key |
|---|---|
| speed_hud_bg.png | HudButton |
| speed_popup_bg.png | Popup |
| speed_buy_btn.png | BuyButton |
| speed_trial_btn.png | TrialButton |
| speed_close_btn.png | CloseButton |
| speed_price_tag.png | PriceTag |

Any key left at `0` falls back to the code-drawn style. `speed_bolt.png` is a spare icon.
Text (titles, prices, countdown) stays live Roblox text in Fredoka One, so it can change at runtime.
