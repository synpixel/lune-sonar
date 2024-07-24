local function findInList<T>(list: { T }, predicate: (T) -> boolean): T?
	for _, value in list do
		if predicate(value) then
			return value
		end
	end

	return nil
end

return findInList
