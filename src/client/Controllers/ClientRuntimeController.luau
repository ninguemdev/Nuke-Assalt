--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Logger = require(ReplicatedStorage.Shared.Util.Logger)
local FpsController = require(script.Parent.FpsController)

local ClientRuntimeController = {}

function ClientRuntimeController.Start()
	local matchConfig = Config.GetMatchConfig()
	local combatConfig = Config.GetCombatConfig()
	local networkConfig = Config.GetNetworkConfig()
	FpsController.Start()
	Logger.info(
		"ClientRuntimeController",
		string.format("Client runtime ready for format first-to-%d", matchConfig.format.roundsToWin)
	)
	Logger.info(
		"ClientRuntimeController",
		string.format("Combat defaults loaded: maxHealth=%d walk=%.1f sprint=%.1f", combatConfig.health.maxHealth, combatConfig.movement.walkSpeed, combatConfig.movement.sprintSpeed)
	)
	Logger.info(
		"ClientRuntimeController",
		string.format(
			"Avatar profile active: rig=%s animation=%s armsOnly=%s fallback=%s",
			combatConfig.avatar.expectedRigType,
			combatConfig.animation.profileId,
			tostring(combatConfig.avatar.showOnlyArmsInFirstPerson),
			combatConfig.avatar.studioFallbackAppearance.mode
		)
	)
	Logger.info(
		"ClientRuntimeController",
		string.format("Client network contract %s expects %d events and %d functions", networkConfig.version, #networkConfig.events, #networkConfig.functions)
	)

	local remoteRoot = ReplicatedStorage:WaitForChild(networkConfig.remoteRootName)
	local eventsFolder = remoteRoot:WaitForChild(networkConfig.folders.events)
	local matchStateChanged = eventsFolder:WaitForChild("MatchStateChanged")
	local roundStateChanged = eventsFolder:WaitForChild("RoundStateChanged")
	local playerEliminated = eventsFolder:WaitForChild("PlayerEliminated")

	if matchStateChanged:IsA("RemoteEvent") then
		matchStateChanged.OnClientEvent:Connect(function(matchState)
			Logger.info(
				"ClientRuntimeController",
				string.format(
					"Match state -> phase=%s round=%d score=%d-%d",
					matchState.phase,
					matchState.roundNumber,
					matchState.attackersScore,
					matchState.defendersScore
				)
			)
		end)
	end

	if roundStateChanged:IsA("RemoteEvent") then
		roundStateChanged.OnClientEvent:Connect(function(roundState)
			Logger.info(
				"ClientRuntimeController",
				string.format(
					"Round state -> phase=%s round=%d timeLeft=%d",
					roundState.phase,
					roundState.currentRound,
					math.floor(roundState.timeRemaining)
				)
			)
		end)
	end

	if playerEliminated:IsA("RemoteEvent") then
		playerEliminated.OnClientEvent:Connect(function(payload)
			Logger.info(
				"ClientRuntimeController",
				string.format("Player eliminated -> %s via %s", payload.name, payload.hitZone)
			)
		end)
	end
end

return table.freeze(ClientRuntimeController)
