local types = require("./types")
type Fingerprint = types.Fingerprint

local function extractThumbnailToken(thumbnailUrl: string): string?
	return thumbnailUrl:match("%d+DAY%-%w+%-(%x+)%-%w+")
end

local function fingerprint(thumbnailUrl: string, userId: number?): Fingerprint
	local thumbnailToken = extractThumbnailToken(thumbnailUrl)
	assert(thumbnailToken ~= nil, "attempt to fingerprint invalid thumbnail url")

	if userId == nil then
		return thumbnailToken
	end

	return { thumbnailToken, userId }
end

local function readThumbnailToken(fingerprint: Fingerprint): string
	if typeof(fingerprint) == "string" then
		return fingerprint
	end

	return fingerprint[1] :: any
end

local function readUserId(fingerprint: Fingerprint): number?
	if typeof(fingerprint) == "string" then
		return nil
	end

	return fingerprint[2] :: any
end

local function compare(fingerprint: Fingerprint, otherFingerprint: Fingerprint): boolean
	return readThumbnailToken(fingerprint) == readThumbnailToken(otherFingerprint)
end

return {
	fingerprint = fingerprint,
	readThumbnailToken = readThumbnailToken,
	readUserId = readUserId,
	compare = compare,
}
