--!strict

local UtilityService = {}
UtilityService.__index = UtilityService

function UtilityService.new(configSnapshotService)
	local snapshot = configSnapshotService:GetSnapshot()
	local self = {
		Name = "UtilityService",
		_utilities = snapshot.catalog.utilities,
		_rules = {
			maxUtilityTotal = snapshot.catalog.loadoutRules.maxUtilityTotal,
		},
	}

	return setmetatable(self, UtilityService)
end

function UtilityService:GetUtilityCatalog()
	return self._utilities
end

function UtilityService:GetUtilityRules()
	return self._rules
end

return UtilityService
