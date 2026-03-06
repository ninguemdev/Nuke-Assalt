--!strict

local WeaponService = {}
WeaponService.__index = WeaponService

function WeaponService.new(configSnapshotService)
	local snapshot = configSnapshotService:GetSnapshot()
	local self = {
		Name = "WeaponService",
		_weapons = snapshot.catalog.weapons,
	}

	return setmetatable(self, WeaponService)
end

function WeaponService:GetWeaponCatalog()
	return self._weapons
end

return WeaponService
