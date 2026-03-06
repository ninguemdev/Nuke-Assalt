--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Logger = require(ReplicatedStorage.Shared.Util.Logger)
local AvatarService = require(script.Parent.Parent.Services.AvatarService)
local ConfigSnapshotService = require(script.Parent.Parent.Services.ConfigSnapshotService)
local DebugStateService = require(script.Parent.Parent.Services.DebugStateService)
local DamageService = require(script.Parent.Parent.Services.DamageService)
local EconomyService = require(script.Parent.Parent.Services.EconomyService)
local EquipmentService = require(script.Parent.Parent.Services.EquipmentService)
local InventoryService = require(script.Parent.Parent.Services.InventoryService)
local MatchService = require(script.Parent.Parent.Services.MatchService)
local MatchCoordinatorService = require(script.Parent.Parent.Services.MatchCoordinatorService)
local MapService = require(script.Parent.Parent.Services.MapService)
local ObjectiveService = require(script.Parent.Parent.Services.ObjectiveService)
local RemoteRegistryService = require(script.Parent.Parent.Services.RemoteRegistryService)
local RoundService = require(script.Parent.Parent.Services.RoundService)
local ServiceRegistry = require(script.Parent.Parent.Services.ServiceRegistry)
local ShopService = require(script.Parent.Parent.Services.ShopService)
local SpawnService = require(script.Parent.Parent.Services.SpawnService)
local StatsService = require(script.Parent.Parent.Services.StatsService)
local UtilityService = require(script.Parent.Parent.Services.UtilityService)
local WeaponService = require(script.Parent.Parent.Services.WeaponService)

local ServerAppBootstrap = {}

function ServerAppBootstrap.StartServerApp()
	Logger.info("ServerBootstrap", "Starting server runtime")
	Config.ValidateGeneratedConfigs()

	local serviceRegistry = ServiceRegistry.new()
	local configSnapshotService = ConfigSnapshotService.new()
	serviceRegistry:Register("ConfigSnapshotService", configSnapshotService)
	local remoteRegistryService = serviceRegistry:Register("RemoteRegistryService", RemoteRegistryService.new())
	local mapService = serviceRegistry:Register("MapService", MapService.new(configSnapshotService))
	local avatarService = serviceRegistry:Register("AvatarService", AvatarService.new(configSnapshotService, remoteRegistryService))
	local damageService = serviceRegistry:Register("DamageService", DamageService.new(configSnapshotService, remoteRegistryService))
	local matchService = serviceRegistry:Register("MatchService", MatchService.new(configSnapshotService))
	local roundService = serviceRegistry:Register("RoundService", RoundService.new(configSnapshotService))
	serviceRegistry:Register("EconomyService", EconomyService.new(configSnapshotService))
	serviceRegistry:Register("ShopService", ShopService.new(configSnapshotService))
	serviceRegistry:Register("InventoryService", InventoryService.new(configSnapshotService))
	serviceRegistry:Register("WeaponService", WeaponService.new(configSnapshotService))
	serviceRegistry:Register("ObjectiveService", ObjectiveService.new(configSnapshotService))
	serviceRegistry:Register("UtilityService", UtilityService.new(configSnapshotService))
	serviceRegistry:Register("EquipmentService", EquipmentService.new(configSnapshotService))
	serviceRegistry:Register("StatsService", StatsService.new())
	local debugStateService = serviceRegistry:Register("DebugStateService", DebugStateService.new(configSnapshotService, serviceRegistry, remoteRegistryService))
	avatarService:BindMovementRemote()
	damageService:BindDebugRemote()
	mapService:EnsureMapWorkspace()
	debugStateService:Publish(nil, nil, mapService:GetStateSnapshot())
	local spawnService = SpawnService.new(mapService)
	local matchCoordinatorService = MatchCoordinatorService.new(matchService, roundService, spawnService, avatarService, debugStateService, remoteRegistryService)
	matchCoordinatorService:Start()

	local snapshot = configSnapshotService:GetSnapshot()
	Logger.info(
		"ServerBootstrap",
		string.format(
			"Loaded config bundle: match=%s economy=%s catalog=%s map=%s combat=%s runtime=%s network=%s",
			snapshot.match.id,
			snapshot.economy.id,
			snapshot.catalog.id,
			snapshot.map.id,
			snapshot.combat.id,
			snapshot.runtime.id,
			snapshot.network.id
		)
	)
	local mapState = mapService:GetStateSnapshot()
	Logger.info(
		"ServerBootstrap",
		string.format("Map workspace ready: %s (source=%s)", mapState.workspaceModelName, mapState.mapSource)
	)
	Logger.info("ServerBootstrap", "Match coordinator started")

	return serviceRegistry
end

return table.freeze(ServerAppBootstrap)
