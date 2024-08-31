local task = require("@lune/task")
local net = require("@lune/net")

local DEFAULT_RETRY_AFTER = 5

local function requestWithRatelimit(config: net.FetchParams | string): net.FetchResponse
	local response = net.request(config)

	if response.statusCode == 429 then
		local retryAfter = tonumber(response.headers["retry-after"]) or DEFAULT_RETRY_AFTER
		task.wait(retryAfter)
		return requestWithRatelimit(config)
	end

	return response
end

return requestWithRatelimit
