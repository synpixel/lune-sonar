local function appendList<T>(list: { T }, ...: T): { T }
	local copy = table.clone(list)

	for _, value in { ... } do
		table.insert(copy, value)
	end

	return copy
end

return appendList
