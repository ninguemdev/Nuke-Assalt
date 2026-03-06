--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Logger = require(ReplicatedStorage.Shared.Util.Logger)

local ClientRuntimeController = {}

function ClientRuntimeController.Start()
	local matchConfig = Config.GetMatchConfig()
	Logger.info(
		"ClientRuntimeController",
		string.format("Client runtime ready for format first-to-%d", matchConfig.format.roundsToWin)
	)
end

return table.freeze(ClientRuntimeController)
