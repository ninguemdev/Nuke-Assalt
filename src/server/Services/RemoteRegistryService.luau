--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteRegistry = require(ReplicatedStorage.Shared.Net.RemoteRegistry)

local RemoteRegistryService = {}
RemoteRegistryService.__index = RemoteRegistryService

function RemoteRegistryService.new()
	local runtimeTree = RemoteRegistry.EnsureRuntimeObjects()
	local self = {
		Name = "RemoteRegistryService",
		_runtimeTree = runtimeTree,
	}

	return setmetatable(self, RemoteRegistryService)
end

function RemoteRegistryService:GetRemoteFolder()
	return self._runtimeTree.root
end

function RemoteRegistryService:GetDefinitions()
	return RemoteRegistry.GetDefinitions()
end

return RemoteRegistryService
