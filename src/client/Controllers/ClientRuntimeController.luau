--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Logger = require(ReplicatedStorage.Shared.Util.Logger)

local ClientRuntimeController = {}

function ClientRuntimeController.Start()
	local matchConfig = Config.GetMatchConfig()
	local networkConfig = Config.GetNetworkConfig()
	Logger.info(
		"ClientRuntimeController",
		string.format("Client runtime ready for format first-to-%d", matchConfig.format.roundsToWin)
	)
	Logger.info(
		"ClientRuntimeController",
		string.format("Client network contract %s expects %d events and %d functions", networkConfig.version, #networkConfig.events, #networkConfig.functions)
	)
end

return table.freeze(ClientRuntimeController)
