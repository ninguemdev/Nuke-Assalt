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
			currentRound = 0,
			winner = nil,
			reason = nil,
			deadline = 0,
		},
	}

	return setmetatable(self, RoundService)
end

function RoundService:ResetToWaiting()
	self._state.phase = RoundPhase.Waiting
	self._state.currentRound = 0
	self._state.winner = nil
	self._state.reason = nil
	self._state.deadline = 0
end

function RoundService:BeginBuyPhase(roundNumber: number)
	self._state.phase = RoundPhase.Buy
	self._state.currentRound = roundNumber
	self._state.winner = nil
	self._state.reason = nil
	self._state.deadline = time() + self._config.timers.buyPhaseSeconds
end

function RoundService:BeginLiveRound(roundNumber: number)
	self._state.phase = RoundPhase.Live
	self._state.currentRound = roundNumber
	self._state.deadline = time() + self._config.timers.roundSeconds
end

function RoundService:ResolveRound(winnerTeam: string, reason: string)
	self._state.phase = RoundPhase.Resolution
	self._state.winner = winnerTeam
	self._state.reason = reason
	self._state.deadline = time() + self._config.timers.roundEndSeconds
end

function RoundService:CompleteRound()
	self._state.phase = RoundPhase.Complete
end

function RoundService:HasTimerExpired()
	return self._state.deadline > 0 and time() >= self._state.deadline
end

function RoundService:GetTimeRemaining()
	if self._state.deadline <= 0 then
		return 0
	end

	return math.max(0, self._state.deadline - time())
end

function RoundService:DetermineWinner(attackersAliveCount: number, defendersAliveCount: number, liveTimerExpired: boolean)
	if attackersAliveCount <= 0 and defendersAliveCount > 0 then
		return "Defenders", "Elimination"
	end

	if defendersAliveCount <= 0 and attackersAliveCount > 0 then
		return "Attackers", "Elimination"
	end

	if attackersAliveCount <= 0 and defendersAliveCount <= 0 then
		return "Defenders", "Elimination"
	end

	if liveTimerExpired then
		return "Defenders", "Timeout"
	end

	return nil, nil
end

function RoundService:GetConfig()
	return self._config
end

function RoundService:GetStateSnapshot()
	return {
		phase = self._state.phase,
		currentRound = self._state.currentRound,
		winner = self._state.winner,
		reason = self._state.reason,
		timeRemaining = self:GetTimeRemaining(),
		buyPhaseSeconds = self._config.timers.buyPhaseSeconds,
		roundSeconds = self._config.timers.roundSeconds,
		postRoundSeconds = self._config.timers.roundEndSeconds,
	}
end

return RoundService
