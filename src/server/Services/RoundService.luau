--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RoundPhase = require(ReplicatedStorage.Shared.Enums.RoundPhase)

local RoundService = {}
RoundService.__index = RoundService

function RoundService.new(configSnapshotService)
	local snapshot = configSnapshotService:GetSnapshot()
	local self = {
		Name = "RoundService",
		_config = snapshot.match,
		_state = {
			phase = RoundPhase.Waiting,
			buyPhaseSeconds = snapshot.match.timers.buyPhaseSeconds,
			roundSeconds = snapshot.match.timers.roundSeconds,
			postPlantSeconds = snapshot.match.timers.postPlantSeconds,
		},
	}

	return setmetatable(self, RoundService)
end

function RoundService:GetConfig()
	return self._config
end

function RoundService:GetStateSnapshot()
	return self._state
end

return RoundService
