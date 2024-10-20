local serde = require("@lune/serde")
local pages = require("./pages")
local array = require("./utils/array")
local requestWithRatelimit = require("./utils/request-with-ratelimit")

type Server = {
	id: string,
	ping: number,
	fps: number,
	playing: number,
	maxPlayers: number,
	playerTokens: { string },
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
	targetId: number?,
	token: string?,
	imageUrl: string,
	state: "Completed" | "Blocked",
}

export type Report = {
	server: Server,
	contains: { number },
}

local function matchThumbnailToken(url: string): string?
	return url:match("%d+DAY%-%w+%-(%x+)%-%w+")
end

local function fetchServers(
	placeId: number,
	with: {
		serverType: "Public" | "Private",
		sortOrder: "Asc" | "Desc",
		limit: number,
		excludeFullGames: boolean,
	}
): pages.Pages<Server>
	return pages(
		`https://games.roblox.com/v1/games/{placeId}/servers/{with.serverType}?sortOrder={with.sortOrder}&limit={with.limit}&excludeFullGames={with.excludeFullGames}`
	)
end

local function bulkFetchThumbnails(bulkRequests: { ThumbnailRequest }): { Thumbnail }
	local thumbnails = {}

	local requestChunks = array.split(bulkRequests, 100)
	for _, requests in requestChunks do
		local response = requestWithRatelimit({
			method = "POST",
			url = "https://thumbnails.roblox.com/v1/batch",
			body = serde.encode("json", requests),
			headers = { ["Content-Type"] = "application/json" },
		})

		if response.ok == false then
			continue
		end

		local body = serde.decode("json", response.body) :: { data: { Thumbnail } }

		for _, thumbnail in body.data do
			if thumbnail.state ~= "Completed" then
				continue
			end

			table.insert(thumbnails, thumbnail)
		end
	end

	return thumbnails
end

local function collectUserFingerprints(userIds: { number }): { [string]: number }
	local thumbnailRequests = array.map(userIds, function(userId)
		return {
			requestId = tostring(userId),
			targetId = userId,
			type = "AvatarHeadshot",
			size = "48x48",
			format = "webp",
		}
	end)
	local thumbnails = bulkFetchThumbnails(thumbnailRequests)

	local fingerprints = {}

	for _, thumbnail in thumbnails do
		local token = matchThumbnailToken(thumbnail.imageUrl) :: string
		fingerprints[token] = thumbnail.targetId :: number
	end

	return fingerprints
end

local function search(userIds: { number }, placeId: number, onReport: (report: Report) -> ()?): { Report }
	local fingerprints = collectUserFingerprints(userIds)

	local nextServers = fetchServers(placeId, {
		serverType = "Public",
		sortOrder = "Asc",
		limit = 100,
		excludeFullGames = false,
	})

	local summary = {
		serverIds = {} :: { string },
		userCount = 0,
		reports = {} :: { Report },
	}

	while true do
		if summary.userCount >= #userIds then
			break
		end

		local servers = nextServers()
		if servers == nil then
			break
		end

		local thumbnailRequests: { ThumbnailRequest } = {}

		for _, server in servers do
			if table.find(summary.serverIds, server.id) ~= nil then
				continue
			end

			for _, token in server.playerTokens do
				table.insert(thumbnailRequests, {
					requestId = server.id,
					token = token,
					type = "AvatarHeadshot",
					size = "48x48",
					format = "webp",
				})
			end
		end

		local thumbnails = bulkFetchThumbnails(thumbnailRequests)

		local reports: { [string]: { number } } = {}

		for _, thumbnail in thumbnails do
			local token = matchThumbnailToken(thumbnail.imageUrl) :: string
			local userId = fingerprints[token]

			if userId == nil then
				continue
			end

			if reports[thumbnail.requestId] == nil then
				reports[thumbnail.requestId] = {}
			end

			table.insert(reports[thumbnail.requestId], userId)
		end

		for serverId, userIds in reports do
			local server = nil

			for _, otherServer in servers do
				if otherServer.id ~= serverId then
					continue
				end

				server = otherServer
				break
			end

			local report = {
				server = server,
				contains = userIds,
			}

			table.insert(summary.reports, report)
			if onReport ~= nil then
				onReport(report)
			end

			table.insert(summary.serverIds, serverId)
			summary.userCount += #userIds
		end
	end

	return summary.reports
end

return search
