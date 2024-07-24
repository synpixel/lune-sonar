local net = require("@lune/net")

local csrfTokenCache = {}

local function ensureFetchParams(partialFetchParams: string | net.FetchParams): net.FetchParams
	if typeof(partialFetchParams) == "string" then
		return { method = "GET", url = partialFetchParams }
	end

	return table.clone(partialFetchParams)
end

local function extractCookie(fetchParams: net.FetchParams): string?
	if fetchParams.headers == nil then
		return nil
	end

	return fetchParams.headers.Cookie :: string
end

local function requestRoblox(partialFetchParams: string | net.FetchParams): net.FetchResponse
	local fetchParams = ensureFetchParams(partialFetchParams)
	if fetchParams.headers == nil then
		fetchParams.headers = {}
	end

	local cookie = extractCookie(fetchParams)
	fetchParams.headers["X-Csrf-Token"] = csrfTokenCache[cookie]

	local response = net.request(fetchParams)
	local csrfToken = response.headers["x-csrf-token"]

	if csrfToken ~= nil then
		csrfTokenCache[cookie] = csrfToken
		fetchParams.headers["X-Csrf-Token"] = csrfToken
		return requestRoblox(fetchParams)
	end

	return response
end

return requestRoblox
