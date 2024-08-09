local function deepClone<T>(toClone: T): T
	if typeof(toClone) ~= "table" then
		return toClone
	end

	local clone = {}

	for index, value in toClone do
		clone[index] = deepClone(value)
	end

	return clone :: any
end

return deepClone
