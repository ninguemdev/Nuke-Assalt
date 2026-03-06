--!strict

local ShopService = {}
ShopService.__index = ShopService

function ShopService.new(configSnapshotService)
	local snapshot = configSnapshotService:GetSnapshot()
	local self = {
		Name = "ShopService",
		_catalog = snapshot.catalog,
		_featureFlags = snapshot.runtime.featureFlags,
	}

	return setmetatable(self, ShopService)
end

function ShopService:GetCatalog()
	return self._catalog
end

function ShopService:GetFeatureFlags()
	return self._featureFlags
end

return ShopService
