local function split<T>(t: { T }, chunkSize: number): { { T } }
	local chunks = {}

	for index = 1, #t, chunkSize do
		table.insert(chunks, {
			unpack(t, index, math.min(index + chunkSize - 1, #t)),
		})
	end

	return chunks
end

local function map<T, U>(t: { T }, processor: (T) -> U): { U }
	local mapped = {}

	for _, value in t do
		table.insert(mapped, processor(value))
	end

	return mapped
end

return { split = split, map = map }
