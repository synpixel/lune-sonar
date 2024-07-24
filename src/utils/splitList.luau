local function splitList<T>(list: { T }, chunkSize: number): { { T } }
	local chunks = {}

	for index = 1, #list, chunkSize do
		table.insert(chunks, {
			unpack(list, index, math.min(index + chunkSize - 1, #list)),
		})
	end

	return chunks
end

return splitList
