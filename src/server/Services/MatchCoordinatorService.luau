--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Shared.Util.Logger)
local MatchPhase = require(ReplicatedStorage.Shared.Enums.MatchPhase)

local MatchCoordinatorService = {}
MatchCoordinatorService.__index = MatchCoordinatorService

function MatchCoordinatorService.new(matchService, roundService, spawnService, avatarService, debugStateService, remoteRegistryService)
	local self = {
		Name = "MatchCoordinatorService",
		_matchService = matchService,
		_roundService = roundService,
		_spawnService = spawnService,
		_avatarService = avatarService,
		_debugStateService = debugStateService,
		_remoteRegistryService = remoteRegistryService,
		_running = false,
	}

	return setmetatable(self, MatchCoordinatorService)
end

function MatchCoordinatorService:_getEvent(name: string)
	local remoteRoot = self._remoteRegistryService:GetRemoteFolder()
	local eventsFolder = remoteRoot and remoteRoot:FindFirstChild("Events")
	if not eventsFolder then
		return nil
	end

	local remoteEvent = eventsFolder:FindFirstChild(name)
	if remoteEvent and remoteEvent:IsA("RemoteEvent") then
		return remoteEvent
	end

	return nil
end

function MatchCoordinatorService:_publishState()
	local matchState = self._matchService:GetStateSnapshot()
	local roundState = self._roundService:GetStateSnapshot()
	self._debugStateService:Publish(matchState, roundState)

	local matchStateChanged = self:_getEvent("MatchStateChanged")
	if matchStateChanged then
		matchStateChanged:FireAllClients(matchState)
	end

	local roundStateChanged = self:_getEvent("RoundStateChanged")
	if roundStateChanged then
		roundStateChanged:FireAllClients(roundState)
	end
end

function MatchCoordinatorService:_spawnAssignedPlayers()
	local assignments = self._matchService:GetAssignments()

	for teamName, players in pairs(assignments) do
		for _, player in ipairs(players) do
			if player.Parent == Players then
				local character = self._avatarService:LoadStandardCharacter(player)
				self._spawnService:MoveCharacterToTeamSpawn(character, teamName)
			end
		end
	end
end

function MatchCoordinatorService:_sendPlayersToLobby(players: { Player })
	local expectedRigType = self._avatarService:GetAvatarConfig().expectedRigType
	local expectedRigEnum = if expectedRigType == "R15" then Enum.HumanoidRigType.R15 else Enum.HumanoidRigType.R6

	for _, player in ipairs(players) do
		if player.Parent == Players then
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local needsStandardCharacter = character == nil
				or character:GetAttribute("NukeAssaltExpectedRig") ~= expectedRigType
				or humanoid == nil
				or humanoid.RigType ~= expectedRigEnum

			if needsStandardCharacter then
				character = self._avatarService:LoadStandardCharacter(player)
			end

			self._spawnService:MoveCharacterToLobby(character)
		end
	end
end

function MatchCoordinatorService:_countAlivePlayers(teamName: string)
	local alive = 0

	for _, player in ipairs(self._matchService:GetAssignments()[teamName]) do
		if player.Parent == Players then
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				alive += 1
			end
		end
	end

	return alive
end

function MatchCoordinatorService:_waitForMinimumPlayers()
	self._matchService:SetWaitingForPlayers()
	self._roundService:ResetToWaiting()

	while self._running do
		local players = Players:GetPlayers()
		self._matchService:AssignSpectators(players)
		self:_sendPlayersToLobby(players)
		self:_publishState()

		if self._matchService:CanStartMatch(players) then
			return players
		end

		task.wait(0.5)
	end

	return nil
end

function MatchCoordinatorService:_playerCountDroppedBelowMinimum()
	return not self._matchService:CanStartMatch(Players:GetPlayers())
end

function MatchCoordinatorService:_waitForBuyPhase()
	while not self._roundService:HasTimerExpired() do
		if self:_playerCountDroppedBelowMinimum() then
			return false
		end

		task.wait(0.1)
	end

	return true
end

function MatchCoordinatorService:_waitForRoundResolution()
	while self._running do
		if self:_playerCountDroppedBelowMinimum() then
			return nil, nil
		end

		local attackersAlive = self:_countAlivePlayers("Attackers")
		local defendersAlive = self:_countAlivePlayers("Defenders")
		local winner, reason = self._roundService:DetermineWinner(attackersAlive, defendersAlive, self._roundService:HasTimerExpired())

		if winner then
			return winner, reason
		end

		task.wait(0.1)
	end

	return nil, nil
end

function MatchCoordinatorService:_abortMatchToWaiting()
	Logger.warn("MatchCoordinator", "Roster dropped below minimum players; returning to waiting state")
	self._matchService:SetWaitingForPlayers()
	self._roundService:ResetToWaiting()
	self:_publishState()
end

function MatchCoordinatorService:Start()
	if self._running then
		return
	end

	self._running = true
	Players.CharacterAutoLoads = false

	task.spawn(function()
		while self._running do
			local players = self:_waitForMinimumPlayers()
			if not players then
				return
			end

			Logger.info("MatchCoordinator", string.format("Starting match with %d players", #players))
			self._matchService:StartMatch(players)
			self._roundService:BeginBuyPhase(self._matchService:GetCurrentRoundNumber())
			self:_spawnAssignedPlayers()
			self:_publishState()

			while self._running do
				local buyCompleted = self:_waitForBuyPhase()
				if not buyCompleted then
					self:_abortMatchToWaiting()
					break
				end

				self._matchService:SetPhase(MatchPhase.LiveRound)
				self._roundService:BeginLiveRound(self._matchService:GetCurrentRoundNumber())
				self:_publishState()

				local winner, reason = self:_waitForRoundResolution()
				if winner == nil then
					self:_abortMatchToWaiting()
					break
				end

				Logger.info(
					"MatchCoordinator",
					string.format("Round %d resolved: winner=%s reason=%s", self._matchService:GetCurrentRoundNumber(), winner, reason)
				)

				self._roundService:ResolveRound(winner, reason)
				self._matchService:ApplyRoundResult(winner, reason)
				self:_publishState()

				while not self._roundService:HasTimerExpired() do
					task.wait(0.1)
				end

				self._roundService:CompleteRound()
				self:_publishState()

				if self._matchService:HasWinner() then
					Logger.info("MatchCoordinator", string.format("Match complete: winner=%s", self._matchService:GetStateSnapshot().winner))
					break
				end

				if self._matchService:IsSideSwapPending() then
					self._matchService:ExecuteSideSwap()
					self:_publishState()
					task.wait(1)
				end

				self._matchService:PrepareNextRound()
				self._roundService:BeginBuyPhase(self._matchService:GetCurrentRoundNumber())
				self:_spawnAssignedPlayers()
				self:_publishState()
			end

			if self._matchService:HasWinner() then
				task.wait(self._matchService:GetPostRoundDuration())
			end
		end
	end)
end

return MatchCoordinatorService
