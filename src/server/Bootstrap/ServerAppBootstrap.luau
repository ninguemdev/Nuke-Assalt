--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Logger = require(ReplicatedStorage.Shared.Util.Logger)
local ConfigSnapshotService = require(script.Parent.Parent.Services.ConfigSnapshotService)
local ServiceRegistry = require(script.Parent.Parent.Services.ServiceRegistry)

local ServerAppBootstrap = {}

function ServerAppBootstrap.StartServerApp()
	Logger.info("ServerBootstrap", "Starting server runtime")
	Config.ValidateGeneratedConfigs()

	local serviceRegistry = ServiceRegistry.new()
	local configSnapshotService = ConfigSnapshotService.new()
	serviceRegistry:Register("ConfigSnapshotService", configSnapshotService)

	local snapshot = configSnapshotService:GetSnapshot()
	Logger.info(
		"ServerBootstrap",
		string.format(
			"Loaded config bundle: match=%s economy=%s catalog=%s",
			snapshot.match.id,
			snapshot.economy.id,
			snapshot.catalog.id
		)
	)

	return serviceRegistry
end

return table.freeze(ServerAppBootstrap)
