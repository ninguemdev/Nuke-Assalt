--!strict

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MatchPhase = require(ReplicatedStorage.Shared.Enums.MatchPhase)

local MatchService = {}
MatchService.__index = MatchService

local function ensureTeam(name: string, colorName: string): Team
	local existing = Teams:FindFirstChild(name)
	if existing and existing:IsA("Team") then
		return existing
	end

	local team = Instance.new("Team")
	team.Name = name
	team.AutoAssignable = false
	team.TeamColor = BrickColor.new(colorName)
	team.Parent = Teams
	return team
end

function MatchService.new(configSnapshotService)
	local snapshot = configSnapshotService:GetSnapshot()
	local self = {
		Name = "MatchService",
		_config = snapshot.match,
		_assignments = {
			Attackers = {},
			Defenders = {},
		},
		_teams = {},
		_state = {
			phase = MatchPhase.WaitingForPlayers,
			roundNumber = 0,
			roundsCompleted = 0,
			roundsToWin = snapshot.match.format.roundsToWin,
			swapAfterRounds = snapshot.match.format.swapAfterRounds,
			minimumPlayersToStart = snapshot.match.format.minimumPlayersToStart,
			attackersScore = 0,
			defendersScore = 0,
			sidesSwapped = false,
			winner = nil,
			roundWinner = nil,
			roundReason = nil,
			attackerCount = 0,
			defenderCount = 0,
		},
	}

	return setmetatable(self, MatchService)
end

function MatchService:EnsureTeams()
	self._teams.Attackers = ensureTeam("Attackers", "Bright orange")
	self._teams.Defenders = ensureTeam("Defenders", "Bright blue")
	self._teams.Spectators = ensureTeam("Spectators", "Medium stone grey")
end

function MatchService:ResetForNewMatch()
	self._state.phase = MatchPhase.WaitingForPlayers
	self._state.roundNumber = 0
	self._state.roundsCompleted = 0
	self._state.attackersScore = 0
	self._state.defendersScore = 0
	self._state.sidesSwapped = false
	self._state.winner = nil
	self._state.roundWinner = nil
	self._state.roundReason = nil
	self._assignments.Attackers = {}
	self._assignments.Defenders = {}
end

function MatchService:SetWaitingForPlayers()
	self._state.phase = MatchPhase.WaitingForPlayers
	self._state.roundNumber = 0
	self._state.roundsCompleted = 0
	self._state.attackersScore = 0
	self._state.defendersScore = 0
	self._state.sidesSwapped = false
	self._state.winner = nil
	self._state.roundWinner = nil
	self._state.roundReason = nil
	self._state.attackerCount = 0
	self._state.defenderCount = 0
	self._assignments.Attackers = {}
	self._assignments.Defenders = {}
end

function MatchService:SetPhase(phase: string)
	self._state.phase = phase
end

function MatchService:CanStartMatch(players: { Player })
	return #players >= self._state.minimumPlayersToStart
end

function MatchService:AssignSpectators(players: { Player })
	self:EnsureTeams()

	for _, player in ipairs(players) do
		player.Neutral = false
		player.Team = self._teams.Spectators
	end
end

function MatchService:AssignBalancedTeams(players: { Player })
	self:EnsureTeams()
	table.sort(players, function(left: Player, right: Player)
		return left.UserId < right.UserId
	end)

	local attackers = {}
	local defenders = {}

	for index, player in ipairs(players) do
		local targetTeamName = if index % 2 == 1 then "Attackers" else "Defenders"
		player.Neutral = false
		player.Team = self._teams[targetTeamName]

		if targetTeamName == "Attackers" then
			table.insert(attackers, player)
		else
			table.insert(defenders, player)
		end
	end

	self._assignments.Attackers = attackers
	self._assignments.Defenders = defenders
	self._state.attackerCount = #attackers
	self._state.defenderCount = #defenders
end

function MatchService:StartMatch(players: { Player })
	self:ResetForNewMatch()
	self:AssignBalancedTeams(players)
	self._state.roundNumber = 1
	self._state.phase = MatchPhase.BuyPhase
end

function MatchService:PrepareNextRound()
	self._state.roundWinner = nil
	self._state.roundReason = nil
	self._state.roundNumber = self._state.roundsCompleted + 1
	self._state.phase = MatchPhase.BuyPhase
end

function MatchService:ApplyRoundResult(winnerTeam: string, reason: string)
	self._state.roundWinner = winnerTeam
	self._state.roundReason = reason
	self._state.roundsCompleted += 1
	self._state.phase = MatchPhase.PostRound

	if winnerTeam == "Attackers" then
		self._state.attackersScore += 1
	else
		self._state.defendersScore += 1
	end

	if self._state.attackersScore >= self._state.roundsToWin or self._state.defendersScore >= self._state.roundsToWin then
		self._state.winner = winnerTeam
		self._state.phase = MatchPhase.MatchComplete
		return
	end

	if not self._state.sidesSwapped and self._state.roundsCompleted == self._state.swapAfterRounds then
		self._state.phase = MatchPhase.SideSwap
	end
end

function MatchService:ExecuteSideSwap()
	local attackers = self._assignments.Attackers
	local defenders = self._assignments.Defenders

	self._assignments.Attackers = defenders
	self._assignments.Defenders = attackers

	for _, player in ipairs(self._assignments.Attackers) do
		if player.Parent == Players then
			player.Team = self._teams.Attackers
		end
	end

	for _, player in ipairs(self._assignments.Defenders) do
		if player.Parent == Players then
			player.Team = self._teams.Defenders
		end
	end

	self._state.attackerCount = #self._assignments.Attackers
	self._state.defenderCount = #self._assignments.Defenders
	self._state.sidesSwapped = true
	self._state.phase = MatchPhase.BuyPhase
end

function MatchService:GetConfig()
	return self._config
end

function MatchService:GetAssignments()
	return self._assignments
end

function MatchService:GetCurrentRoundNumber()
	return self._state.roundNumber
end

function MatchService:GetMinimumPlayersToStart()
	return self._state.minimumPlayersToStart
end

function MatchService:GetPostRoundDuration()
	return self._config.timers.roundEndSeconds
end

function MatchService:IsSideSwapPending()
	return self._state.phase == MatchPhase.SideSwap
end

function MatchService:HasWinner()
	return self._state.winner ~= nil
end

function MatchService:GetStateSnapshot()
	return {
		phase = self._state.phase,
		roundNumber = self._state.roundNumber,
		roundsCompleted = self._state.roundsCompleted,
		roundsToWin = self._state.roundsToWin,
		swapAfterRounds = self._state.swapAfterRounds,
		minimumPlayersToStart = self._state.minimumPlayersToStart,
		attackersScore = self._state.attackersScore,
		defendersScore = self._state.defendersScore,
		sidesSwapped = self._state.sidesSwapped,
		winner = self._state.winner,
		roundWinner = self._state.roundWinner,
		roundReason = self._state.roundReason,
		attackerCount = self._state.attackerCount,
		defenderCount = self._state.defenderCount,
	}
end

return MatchService
