local function deepCopy<T, K>(input: { [T]: K }): { [T]: K }
	local copy = {}

	for index, value in input do
		if typeof(value) == "table" then
			copy[index] = deepCopy(value)
		else
			copy[index] = value
		end
	end

	return copy
end

return deepCopy
