--!strict

local EquipmentService = {}
EquipmentService.__index = EquipmentService

function EquipmentService.new(configSnapshotService)
	local snapshot = configSnapshotService:GetSnapshot()
	local self = {
		Name = "EquipmentService",
		_equipment = snapshot.catalog.equipment,
		_rules = {
			maxSpecialEquipment = snapshot.catalog.loadoutRules.maxSpecialEquipment,
			maxDefuseKits = snapshot.catalog.loadoutRules.maxDefuseKits,
		},
	}

	return setmetatable(self, EquipmentService)
end

function EquipmentService:GetEquipmentCatalog()
	return self._equipment
end

function EquipmentService:GetEquipmentRules()
	return self._rules
end

return EquipmentService
