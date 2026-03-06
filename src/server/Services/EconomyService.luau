--!strict

local EconomyService = {}
EconomyService.__index = EconomyService

function EconomyService.new(configSnapshotService)
	local snapshot = configSnapshotService:GetSnapshot()
	local self = {
		Name = "EconomyService",
		_config = snapshot.economy,
	}

	return setmetatable(self, EconomyService)
end

function EconomyService:GetConfig()
	return self._config
end

function EconomyService:GetStartingMoney()
	return self._config.startingMoney
end

function EconomyService:GetLossBonusSequence()
	return self._config.lossBonusSequence
end

return EconomyService
