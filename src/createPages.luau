local serde = require("@lune/serde")
local requestRoblox = require("./requestRoblox")
local types = require("./types")

local function createPages<Entry>(baseRequestUrl: string): types.Pages<Entry>
	local currentPage: {
		previousPageCursor: string?,
		nextPageCursor: string?,
		data: { Entry },
	} = {
		previousPageCursor = "",
		nextPageCursor = "",
		data = {},
	}

	local pages = {}

	function pages:toCursor(cursor)
		local response = requestRoblox(`{baseRequestUrl}&cursor={cursor}`)
		currentPage = serde.decode("json", response.body)
		return currentPage.data
	end

	function pages:nextPage()
		return pages:toCursor(currentPage.nextPageCursor)
	end

	function pages:previousPage()
		return pages:toCursor(currentPage.previousPageCursor)
	end

	function pages:isLastPage()
		return currentPage.nextPageCursor == nil
	end

	function pages:isFirstPage()
		return currentPage.previousPageCursor == nil
	end

	return pages
end

return createPages
