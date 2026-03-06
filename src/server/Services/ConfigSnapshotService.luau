--!strict

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local ConfigSnapshotService = {}
ConfigSnapshotService.__index = ConfigSnapshotService

function ConfigSnapshotService.new()
	local self = {
		Name = "ConfigSnapshotService",
		_snapshot = {
			match = Config.GetMatchConfig(),
			economy = Config.GetEconomyConfig(),
			catalog = Config.GetCatalogConfig(),
			map = Config.GetMapConfig(),
			combat = Config.GetCombatConfig(),
			runtime = Config.GetRuntimeConfig(),
			network = Config.GetNetworkConfig(),
		},
	}

	return setmetatable(self, ConfigSnapshotService)
end

function ConfigSnapshotService:GetSnapshot()
	return self._snapshot
end

return ConfigSnapshotService
