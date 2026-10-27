--!strict
-- Integration: Feedback (PS-37) – nur gefilterter Text wird gespeichert, Filterfehler speichert nichts,
-- Limit je Sitzung, Validierer.
return function(it, expect, ctx)
	local reg = ctx.registry
	local player = ctx.player
	local FB = reg.FeedbackService
	local Validate = require(game:GetService("ReplicatedStorage").Shared.Net.Validate)

	local origFilter, origSave = FB.filter, FB.save
	local saved: { [string]: any } = {}
	FB.save = function(key, value)
		saved[key] = value
	end
	FB.filter = function(text)
		return (string.gsub(text, "secret", "######"))
	end
	FB:resetCount(player)

	it("Gefilterter Text wird mit Kontext gespeichert", function()
		local ok, key = FB:submit(player, "bug", "my secret pillow is stuck")
		expect(ok).toBeTruthy()
		local entry = saved[key]
		expect(entry ~= nil).toBeTruthy()
		expect(entry.text).toBe("my ###### pillow is stuck")
		expect(entry.category).toBe("bug")
		expect(type(entry.rank)).toBe("number")
	end)

	it("Filterfehler: nichts gespeichert", function()
		table.clear(saved)
		FB.filter = function()
			error("filter down")
		end
		local ok, why = FB:submit(player, "idea", "more pillows please")
		expect(ok).toBeFalsy()
		expect(why).toBe("filterFailed")
		expect(next(saved) == nil).toBeTruthy()
	end)

	it("Limit je Sitzung", function()
		FB.filter = function(text)
			return text
		end
		FB:resetCount(player)
		for _ = 1, FB.MAX_PER_SESSION do
			expect((FB:submit(player, "other", "hello there"))).toBeTruthy()
		end
		local ok, why = FB:submit(player, "other", "one more")
		expect(ok).toBeFalsy()
		expect(why).toBe("limit")
	end)

	it("Validierer: Kategorie und Textlänge", function()
		local cat, txt = Validate.validators.feedbackCategory, Validate.validators.feedbackText
		expect(cat("bug")).toBeTruthy()
		expect(cat("hack")).toBeFalsy()
		expect(txt("ok!")).toBeTruthy()
		expect(txt("no")).toBeFalsy()
		expect(txt(string.rep("a", 301))).toBeFalsy()
		expect(txt(string.rep("ä", 300))).toBeTruthy()
		expect(txt("\255\254bad")).toBeFalsy()
		expect(txt(42)).toBeFalsy()
	end)

	FB.filter, FB.save = origFilter, origSave
	FB:resetCount(player)
end
