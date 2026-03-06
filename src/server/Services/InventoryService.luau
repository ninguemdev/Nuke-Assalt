--!strict

local InventoryService = {}
InventoryService.__index = InventoryService

function InventoryService.new(configSnapshotService)
	local snapshot = configSnapshotService:GetSnapshot()
	local self = {
		Name = "InventoryService",
		_loadoutRules = snapshot.catalog.loadoutRules,
		_slotDefinitions = {
			primary = "PrimaryWeapon",
			secondary = "SecondaryWeapon",
			utility = "Utility",
			special = "SpecialEquipment",
			defuseKit = "DefuseKit",
			armor = "Armor",
		},
	}

	return setmetatable(self, InventoryService)
end

function InventoryService:GetLoadoutRules()
	return self._loadoutRules
end

function InventoryService:GetSlotDefinitions()
	return self._slotDefinitions
end

return InventoryService
