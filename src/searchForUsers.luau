local serde = require("@lune/serde")
local net = require("@lune/net")
local createPages = require("./createPages")
local identification = require("./identification")
local findInList = require("./utils/findInList")
local splitList = require("./utils/splitList")
local mergeLists = require("./utils/mergeLists")
local deepClone = require("./utils/deepClone")
local types = require("./types")

type Pages<Entry> = types.Pages<Entry>
type Fingerprint = types.Fingerprint
type SearchOptions = types.SearchOptions
type PartialSearchOptions = types.PartialSearchOptions
type SearchResult = types.SearchResult

type ThumbnailRequest = {
	requestId: string,
	token: string,
	type: string,
	size: string,
	format: string,
} | {
	requestId: string,
	targetId: number,
	type: string,
	size: string,
	format: string,
}

type Thumbnail = {
	requestId: string,
	token: string,
	imageUrl: string,
	state: "Completed" | "Blocked",
} | {
	requestId: string,
	targetId: number,
	imageUrl: string,
	state: "Completed" | "Blocked",
}

type Server = {
	id: string,
	ping: number,
	fps: number,
	playing: number,
	maxPlayers: number,
	playerTokens: { string },
}

local SERVERS_SORT_ORDER: "Asc" | "Desc" = "Asc"
local SERVERS_PAGE_SIZE = 100
local SERVERS_EXCLUDE_FULL_GAMES = false

local THUMBNAIL_USER_REQUEST_ID = "sonar::user:%s"
local THUMBNAIL_SERVER_REQUEST_ID = "sonar::server:%s"
local THUMBNAIL_TYPE = "AvatarHeadshot"
local THUMBNAIL_SIZE = "48x48"
local THUMBNAIL_FORMAT = "webp"
local THUMBNAIL_REQUEST_CHUNK_SIZE = 100

local DEFAULT_SEARCH_OPTIONS: SearchOptions = {
	serverType = "public",
}

local function fetchServers(placeId: number, searchOptions: SearchOptions): Pages<Server>
	return createPages(
		`https://games.roblox.com/v1/games/{placeId}/servers/{searchOptions.serverType}?sortOrder={SERVERS_SORT_ORDER}&limit={SERVERS_PAGE_SIZE}&excludeFullGames={SERVERS_EXCLUDE_FULL_GAMES}`
	)
end

local function bulkFetchThumbnails(
	bulkThumbnailRequests: { ThumbnailRequest },
	searchOptions: SearchOptions
): { Thumbnail }
	local thumbnails = {}

	local thumbnailRequestChunks = splitList(bulkThumbnailRequests, THUMBNAIL_REQUEST_CHUNK_SIZE)

	for _, thumbnailRequests in thumbnailRequestChunks do
		local response = net.request({
			method = "POST",
			url = "https://thumbnails.roblox.com/v1/batch",
			body = serde.encode("json", thumbnailRequests),
			headers = { ["Content-Type"] = "application/json" },
		})

		-- sorry i just hated how `not` looked
		if response.ok == false then
			continue
		end

		for _, thumbnail in serde.decode("json", response.body).data do
			table.insert(thumbnails, thumbnail)
		end
	end

	return thumbnails
end

local function collectFingerprints(userIds: { number }, searchOptions: SearchOptions): { Fingerprint }
	local thumbnailRequests = {}

	for _, userId in userIds do
		table.insert(thumbnailRequests, {
			requestId = THUMBNAIL_USER_REQUEST_ID:format(userId),
			targetId = userId,
			type = THUMBNAIL_TYPE,
			size = THUMBNAIL_SIZE,
			format = THUMBNAIL_FORMAT,
		})
	end

	local thumbnails = bulkFetchThumbnails(thumbnailRequests, searchOptions)

	local fingerprints = {}

	for _, thumbnail in thumbnails do
		if thumbnail.state ~= "Completed" then
			continue
		end

		-- luau gets angry :(
		local targetId = (thumbnail :: any).targetId :: number
		local fingerprint = identification.fingerprint(thumbnail.imageUrl, targetId)
		table.insert(fingerprints, fingerprint)
	end

	return fingerprints
end

local function patchDuplicateSearchResults(searchResults: { SearchResult }): { SearchResult }
	local patchedSearchResults = deepClone(searchResults)

	for index, searchResult in patchedSearchResults do
		for otherIndex, otherSearchResult in patchedSearchResults do
			if otherIndex == index then
				continue
			end

			if otherSearchResult.serverId ~= searchResult.serverId then
				continue
			end

			otherSearchResult.userIds = mergeLists(searchResult.userIds, otherSearchResult.userIds)
			table.remove(patchedSearchResults, index)
		end
	end

	return patchedSearchResults
end

local function searchServersForUsers(
	servers: { Server },
	fingerprints: { Fingerprint },
	searchOptions: SearchOptions
): { SearchResult }
	local thumbnailRequests = {}

	for _, server in servers do
		for _, playerToken in server.playerTokens do
			table.insert(thumbnailRequests, {
				requestId = THUMBNAIL_SERVER_REQUEST_ID:format(server.id),
				token = playerToken,
				type = THUMBNAIL_TYPE,
				size = THUMBNAIL_SIZE,
				format = THUMBNAIL_FORMAT,
			})
		end
	end

	local thumbnails = bulkFetchThumbnails(thumbnailRequests, searchOptions)

	local searchResults = {} :: { SearchResult }

	for _, thumbnail in thumbnails do
		if thumbnail.state ~= "Completed" then
			continue
		end

		local thumbnailFingerprint = identification.fingerprint(thumbnail.imageUrl)
		local fingerprint = findInList(fingerprints, function(fingerprint)
			return identification.compare(fingerprint, thumbnailFingerprint)
		end)

		if fingerprint == nil then
			continue
		end

		local searchResult = findInList(searchResults, function(searchResult)
			return THUMBNAIL_SERVER_REQUEST_ID:format(searchResult.serverId) == thumbnail.requestId
		end) :: SearchResult

		if searchResult == nil then
			local server = findInList(servers, function(server)
				return THUMBNAIL_SERVER_REQUEST_ID:format(server.id) == thumbnail.requestId
			end) :: Server

			searchResult = {
				serverId = server.id,
				serverPing = server.ping,
				serverFps = server.fps,
				activePlayers = server.playing,
				maxPlayers = server.maxPlayers,
				userIds = {},
			}

			table.insert(searchResults, searchResult)
		end

		local userId = identification.readUserId(fingerprint)
		table.insert(searchResult.userIds, userId :: number)
	end

	return searchResults
end

local function patchSearchOptions(partialSearchOptions: PartialSearchOptions?): SearchOptions
	if partialSearchOptions == nil then
		return table.clone(DEFAULT_SEARCH_OPTIONS)
	end

	local searchOptions = {}

	for key, default in DEFAULT_SEARCH_OPTIONS do
		if partialSearchOptions[key] == nil then
			searchOptions[key] = default
		end
	end

	return searchOptions :: SearchOptions
end

local function searchForUsers(
	userIds: { number },
	placeId: number,
	partialSearchOptions: PartialSearchOptions?
): { SearchResult }
	local searchOptions = patchSearchOptions(partialSearchOptions)

	local servers = fetchServers(placeId, searchOptions)
	local fingerprints = collectFingerprints(userIds, searchOptions)

	local searchResults = {}
	local targetsFound = 0

	while true do
		local serverSearchResults = searchServersForUsers(servers:nextPage(), fingerprints, searchOptions)

		for _, searchResult in serverSearchResults do
			table.insert(searchResults, searchResult)
			targetsFound += #searchResult.userIds
		end

		if targetsFound >= #userIds then
			break
		end

		if servers:isLastPage() then
			break
		end
	end

	return patchDuplicateSearchResults(searchResults)
end

return searchForUsers
