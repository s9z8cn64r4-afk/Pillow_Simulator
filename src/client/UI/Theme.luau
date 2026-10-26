--!strict
-- VERTRAG (nur UI/UX ändert): Design-Tokens, siehe docs/design/ui-design-system.md
local function rgb(hex: string): Color3
	return Color3.fromHex(hex)
end

return table.freeze({
	color = table.freeze({
		bg = rgb("#2B2350"),
		bgSoft = rgb("#3A3170"),
		surface = rgb("#FFF6EC"),
		primary = rgb("#FF8FB1"),
		secondary = rgb("#7FD8FF"),
		success = rgb("#7EE08A"),
		danger = rgb("#FF6B6B"),
		robux = rgb("#00B06F"),
		feather = rgb("#FFE27A"),
		stroke = rgb("#1A1433"),
		muted = rgb("#9C93C9"),
		locked = rgb("#5A5385"),
	}),
	font = table.freeze({
		display = Enum.Font.FredokaOne,
		body = Enum.Font.GothamBold,
	}),
	size = table.freeze({ xs = 14, sm = 18, md = 24, lg = 32, xl = 48 }),
	radius = table.freeze({ button = 12, panel = 18 }),
	space = table.freeze({ xs = 4, sm = 8, md = 12, lg = 16, xl = 24 }),
	motion = table.freeze({ fast = 0.12, base = 0.18, slow = 0.35 }),
	-- Referenzhöhe für UIScale (Layout wird für 720 px hoch entworfen)
	referenceHeight = 720,
})
