--!strict

export type ServiceContractDescriptor = {
	name: string,
	methods: { string },
}

local ServiceContracts = {
	ConfigSnapshotService = {
		name = "ConfigSnapshotService",
		methods = { "GetSnapshot" },
	},
	RemoteRegistryService = {
		name = "RemoteRegistryService",
		methods = { "GetRemoteFolder", "GetDefinitions" },
	},
	MapService = {
		name = "MapService",
		methods = {
			"GetConfig",
			"EnsureMapWorkspace",
			"GetMapRoot",
			"GetSpawnPart",
			"GetCalloutMarker",
			"GetRouteMarkers",
			"GetBombsiteRoot",
			"GetPlantZones",
			"GetAnchorPoints",
			"GetStateSnapshot",
		},
	},
	AvatarService = {
		name = "AvatarService",
		methods = {
			"GetAvatarConfig",
			"GetAnimationConfig",
			"BuildSpawnDescription",
			"BindPlayerCharacter",
			"BindMovementRemote",
			"LoadStandardCharacter",
			"UpdateMovementState",
		},
	},
	DamageService = {
		name = "DamageService",
		methods = {
			"GetCombatConfig",
			"GetHitZoneMultiplier",
			"ResolveHitZone",
			"ApplyHumanoidDamage",
			"BindPlayerCharacter",
			"BindDebugRemote",
		},
	},
	MatchService = {
		name = "MatchService",
		methods = { "GetConfig", "GetStateSnapshot" },
	},
	RoundService = {
		name = "RoundService",
		methods = { "GetConfig", "GetStateSnapshot" },
	},
	EconomyService = {
		name = "EconomyService",
		methods = { "GetConfig", "GetStartingMoney", "GetLossBonusSequence" },
	},
	ShopService = {
		name = "ShopService",
		methods = { "GetCatalog", "GetFeatureFlags" },
	},
	InventoryService = {
		name = "InventoryService",
		methods = { "GetLoadoutRules", "GetSlotDefinitions" },
	},
	WeaponService = {
		name = "WeaponService",
		methods = { "GetWeaponCatalog" },
	},
	ObjectiveService = {
		name = "ObjectiveService",
		methods = { "GetObjectiveStates", "GetNetworkContract" },
	},
	UtilityService = {
		name = "UtilityService",
		methods = { "GetUtilityCatalog", "GetUtilityRules" },
	},
	EquipmentService = {
		name = "EquipmentService",
		methods = { "GetEquipmentCatalog", "GetEquipmentRules" },
	},
	StatsService = {
		name = "StatsService",
		methods = { "CreateEmptyPlayerStats", "GetTrackedFields" },
	},
	DebugStateService = {
		name = "DebugStateService",
		methods = { "Publish", "GetRuntimeFolder" },
	},
}

return table.freeze(ServiceContracts)
