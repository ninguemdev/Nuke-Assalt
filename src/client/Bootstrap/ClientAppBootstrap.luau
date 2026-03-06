--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Logger = require(ReplicatedStorage.Shared.Util.Logger)
local ClientRuntimeController = require(script.Parent.Parent.Controllers.ClientRuntimeController)

local ClientAppBootstrap = {}

function ClientAppBootstrap.StartClientApp()
	Logger.info("ClientBootstrap", "Starting client runtime")
	Config.ValidateGeneratedConfigs()
	ClientRuntimeController.Start()
	Logger.info("ClientBootstrap", "Client runtime initialized")
end

return table.freeze(ClientAppBootstrap)
