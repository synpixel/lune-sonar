local types = require("./types")

local function extractThumbnailToken(thumbnailUrl: string)
	return thumbnailUrl:match("%d+DAY%-%w+%-(%x+)%-%w+")
end

local function createFingerprint(thumbnailUrl: string): types.Fingerprint
	local fingerprint = {}
	fingerprint.thumbnailUrl = thumbnailUrl
	fingerprint.userId = nil

	function fingerprint:attachUserId(userId)
		fingerprint.userId = userId
		return fingerprint
	end

	function fingerprint:matches(otherFingerprint)
		local thumbnailToken = extractThumbnailToken(fingerprint.thumbnailUrl)
		local otherThumbnailToken = extractThumbnailToken(otherFingerprint.thumbnailUrl)
		return thumbnailToken == otherThumbnailToken
	end

	return fingerprint
end

return createFingerprint
