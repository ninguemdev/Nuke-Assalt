--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MatchPhase = require(ReplicatedStorage.Shared.Enums.MatchPhase)

local MatchService = {}
MatchService.__index = MatchService

function MatchService.new(configSnapshotService)
	local snapshot = configSnapshotService:GetSnapshot()
	local self = {
		Name = "MatchService",
		_config = snapshot.match,
		_state = {
			phase = MatchPhase.WaitingForPlayers,
			roundsToWin = snapshot.match.format.roundsToWin,
			swapAfterRounds = snapshot.match.format.swapAfterRounds,
		},
	}

	return setmetatable(self, MatchService)
end

function MatchService:GetConfig()
	return self._config
end

function MatchService:GetStateSnapshot()
	return self._state
end

return MatchService
