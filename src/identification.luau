local types = require("./types")

local function extractThumbnailToken(thumbnailUrl: string): string?
	return thumbnailUrl:match("%d+DAY%-%w+%-(%x+)%-%w+")
end

local function fingerprint(thumbnailUrl: string, userId: number?): types.Fingerprint
	local thumbnailToken = extractThumbnailToken(thumbnailUrl)
	assert(thumbnailToken ~= nil, "attempt to fingerprint invalid thumbnail url")

	if userId == nil then
		return thumbnailToken
	end

	return { thumbnailToken, userId }
end

local function compareFingerprints(fingerprint: types.Fingerprint, otherFingerprint: types.Fingerprint): boolean
	local thumbnailToken = if typeof(fingerprint) == "string" then fingerprint else fingerprint[1]
	local otherThumbnailToken = if typeof(otherFingerprint) == "string" then otherFingerprint else otherFingerprint[1]
	return thumbnailToken == otherThumbnailToken
end

local function extractUserId(fingerprint: types.Fingerprint): number?
	if typeof(fingerprint) == "string" then
		return nil
	end

	return fingerprint[2] :: any
end

return {
	fingerprint = fingerprint,
	compareFingerprints = compareFingerprints,
	extractUserId = extractUserId,
}
