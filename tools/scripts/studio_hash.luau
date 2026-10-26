-- In Studio (Edit) per execute_luau ausführen; Ausgabe in eine Datei kopieren und mit source_hash.py vergleichen.
local roots = {
	game.ServerScriptService.Server,
	game.StarterPlayer.StarterPlayerScripts.Client,
	game.ReplicatedStorage.Shared,
	game.ServerStorage.Tests,
}
local function h(s)
	local v = 0
	for i = 1, #s do
		v = (v * 31 + string.byte(s, i)) % 2147483647
	end
	return v
end
local out = {}
for _, r in roots do
	for _, d in { r, table.unpack(r:GetDescendants()) } do
		if d:IsA("LuaSourceContainer") then
			local src = (d :: any).Source:gsub("\n+$", "")
			table.insert(out, d:GetFullName() .. "=" .. h(src))
		end
	end
end
table.sort(out)
return table.concat(out, "\n")
