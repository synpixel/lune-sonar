local searchForUsers = require("./searchForUsers")
local types = require("./types")

export type SearchOptions = types.SearchOptions
export type PartialSearchOptions = types.PartialSearchOptions
export type SearchResult = types.SearchResult

return {
	searchForUsers = searchForUsers,
}
