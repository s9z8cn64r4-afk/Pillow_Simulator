--!strict
-- Token-Bucket pro Schlüssel. Reine Logik: Zeit wird übergeben (testbar).
export type RateLimiter = {
	take: (RateLimiter, key: any, now: number) -> boolean,
	forget: (RateLimiter, key: any) -> (),
}

local RateLimiter = {}
RateLimiter.__index = RateLimiter

function RateLimiter.new(rate: number, burst: number): RateLimiter
	return (setmetatable({ rate = rate, burst = burst, buckets = {} }, RateLimiter) :: any) :: RateLimiter
end

function RateLimiter:take(key, now)
	local b = self.buckets[key]
	if not b then
		b = { tokens = self.burst, last = now }
		self.buckets[key] = b
	end
	b.tokens = math.min(self.burst, b.tokens + (now - b.last) * self.rate)
	b.last = now
	if b.tokens >= 1 then
		b.tokens -= 1
		return true
	end
	return false
end

function RateLimiter:forget(key)
	self.buckets[key] = nil
end

return RateLimiter
