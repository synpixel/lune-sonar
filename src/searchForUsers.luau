local serde = require("@lune/serde")
local net = require("@lune/net")
local roblox = require("@lune/roblox")
local createPages = require("./createPages")
local createFingerprint = require("./createFingerprint")
local findInList = require("./utils/findInList")
local splitList = require("./utils/splitList")
local types = require("./types")

local QUERY_SORT_ORDER: "Asc" | "Desc" = "Asc"
local QUERY_PAGE_SIZE = 100
local QUERY_EXCLUDE_FULL_GAMES = false

local THUMBNAIL_USER_REQUEST_ID = "sonar:user:%s"
local THUMBNAIL_SERVER_REQUEST_ID = "sonar:server:%s"
local THUMBNAIL_TYPE = "AvatarHeadshot"
local THUMBNAIL_SIZE = "48x48"
local THUMBNAIL_FORMAT = "webp"
local THUMBNAIL_REQUEST_CHUNK_SIZE = 100

local DEFAULT_SEARCH_OPTIONS: types.SearchOptions = {
	serverType = "public",
	roblosecurity = roblox.getAuthCookie(true) :: string,
}

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
} | {
	requestId: string,
	targetId: number,
	imageUrl: string,
}

type Server = {
	id: string,
	ping: number,
	fps: number,
	playing: number,
	maxPlayers: number,
	playerTokens: { string },
}

local function fetchServers(placeId: number, searchOptions: types.SearchOptions): types.Pages<Server>
	return createPages(
		`https://games.roblox.com/v1/games/{placeId}/servers/{searchOptions.serverType}?sortOrder={QUERY_SORT_ORDER}&limit={QUERY_PAGE_SIZE}&excludeFullGames={QUERY_EXCLUDE_FULL_GAMES}`
	)
end

local function fetchThumbnails(
	thumbnailRequests: { ThumbnailRequest },
	searchOptions: types.SearchOptions
): { Thumbnail }
	local thumbnails = {}

	local thumbnailRequestChunks = splitList(thumbnailRequests, THUMBNAIL_REQUEST_CHUNK_SIZE)

	for _, thumbnailRequestChunk in thumbnailRequestChunks do
		local response = net.request({
			method = "POST",
			url = "https://thumbnails.roblox.com/v1/batch",
			body = serde.encode("json", thumbnailRequestChunk),
			headers = {
				["Content-Type"] = "application/json",
				Cookie = searchOptions.roblosecurity,
			},
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

local function collectFingerprints(userIds: { number }, searchOptions: types.SearchOptions): { types.Fingerprint }
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

	local thumbnails = fetchThumbnails(thumbnailRequests, searchOptions)

	local fingerprints = {}

	for _, thumbnail in thumbnails do
		local fingerprint = createFingerprint(thumbnail.imageUrl):attachUserId(thumbnail.targetId :: number)
		table.insert(fingerprints, fingerprint)
	end

	return fingerprints
end

local function searchServersForUsers(
	servers: { Server },
	fingerprints: { types.Fingerprint },
	searchOptions: types.SearchOptions
): { types.SearchResult }
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

	local thumbnails = fetchThumbnails(thumbnailRequests, searchOptions)

	local searchResults = {}

	for _, thumbnail in thumbnails do
		local fingerprint = createFingerprint(thumbnail.imageUrl)
		local matchingFingerprint = findInList(fingerprints, function(targetFingerprint)
			return fingerprint:matches(targetFingerprint)
		end)

		if matchingFingerprint == nil then
			continue
		end

		local searchResult = findInList(searchResults, function(targetResult)
			return thumbnail.requestId == THUMBNAIL_SERVER_REQUEST_ID:format(targetResult.serverId)
		end)

		if searchResult == nil then
			local server = findInList(servers, function(targetServer)
				return thumbnail.requestId == THUMBNAIL_SERVER_REQUEST_ID:format(targetServer.id)
			end)

			if server == nil then
				continue
			end

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

		table.insert(searchResult.userIds, matchingFingerprint.userId :: number)
	end

	return searchResults
end

local function patchSearchOptions(partialSearchOptions: types.PartialSearchOptions?): types.SearchOptions
	if partialSearchOptions == nil then
		return table.clone(DEFAULT_SEARCH_OPTIONS)
	end

	local searchOptions = {}

	for key, default in DEFAULT_SEARCH_OPTIONS do
		if partialSearchOptions[key] == nil then
			searchOptions[key] = default
		end
	end

	return searchOptions
end

local function searchForUsers(
	targetUserIds: { number },
	placeId: number,
	partialSearchOptions: types.PartialSearchOptions?
): { types.SearchResult }
	local searchOptions = patchSearchOptions(partialSearchOptions)
	assert(searchOptions.roblosecurity ~= nil, "Sonar needs a valid .ROBLOSECURITY cookie to function")

	local servers = fetchServers(placeId, searchOptions)
	local fingerprints = collectFingerprints(targetUserIds, searchOptions)

	local searchResults = {}

	while true do
		local serverSearchResults = searchServersForUsers(servers:nextPage(), fingerprints, searchOptions)

		for _, searchResult in serverSearchResults do
			table.insert(searchResults, searchResult)
		end

		if servers:isLastPage() then
			break
		end
	end

	return searchResults
end

return searchForUsers
