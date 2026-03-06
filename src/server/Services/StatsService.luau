--!strict

local StatsService = {}
StatsService.__index = StatsService

function StatsService.new()
	local self = {
		Name = "StatsService",
		_trackedFields = {
			"Kills",
			"Deaths",
			"Assists",
			"Plants",
			"Defuses",
			"Damage",
			"MoneySpent",
		},
	}

	return setmetatable(self, StatsService)
end

function StatsService:CreateEmptyPlayerStats()
	return {
		Kills = 0,
		Deaths = 0,
		Assists = 0,
		Plants = 0,
		Defuses = 0,
		Damage = 0,
		MoneySpent = 0,
	}
end

function StatsService:GetTrackedFields()
	return self._trackedFields
end

return StatsService
