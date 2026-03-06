--!strict

local function deepFreeze(value)
	if type(value) ~= "table" then
		return value
	end

	for _, child in pairs(value) do
		if type(child) == "table" then
			deepFreeze(child)
		end
	end

	if not table.isfrozen(value) then
		table.freeze(value)
	end

	return value
end

return deepFreeze
