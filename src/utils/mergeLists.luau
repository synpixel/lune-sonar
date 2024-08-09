local function mergeLists<T>(...: { T }): { T }
	local mergedList = {}

	for _, list in { ... } do
		for _, value in list do
			table.insert(mergedList, value)
		end
	end

	return mergedList
end

return mergeLists
