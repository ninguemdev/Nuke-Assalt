--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ObjectiveState = require(ReplicatedStorage.Shared.Enums.ObjectiveState)

local ObjectiveService = {}
ObjectiveService.__index = ObjectiveService

function ObjectiveService.new(configSnapshotService)
	local snapshot = configSnapshotService:GetSnapshot()
	local self = {
		Name = "ObjectiveService",
		_network = snapshot.network,
	}

	return setmetatable(self, ObjectiveService)
end

function ObjectiveService:GetObjectiveStates()
	return ObjectiveState
end

function ObjectiveService:GetNetworkContract()
	return self._network
end

return ObjectiveService
