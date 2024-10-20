local serde = require("@lune/serde")
local requestWithRatelimit = require("./utils/request-with-ratelimit")

export type Pages<Entry> = () -> { Entry }?

local function pages<Entry>(baseUrl: string): Pages<Entry>
	local nextPageCursor = ""

	return function()
		if nextPageCursor == nil then
			return nil
		end

		local response = requestWithRatelimit(`{baseUrl}&cursor={nextPageCursor}`)

		if response.ok == false then
			return nil
		end

		local page = serde.decode("json", response.body)
		nextPageCursor = page.nextPageCursor

		return page.data
	end
end

return pages
