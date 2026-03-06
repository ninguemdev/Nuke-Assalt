--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Shared.Util.Logger)

local DamageService = {}
DamageService.__index = DamageService

local function normalizeZoneName(zoneName: string): string
	local lowered = string.lower(zoneName)
	if lowered == "head" then
		return "Head"
	elseif lowered == "torso" then
		return "Torso"
	elseif lowered == "arms" then
		return "Arms"
	elseif lowered == "legs" then
		return "Legs"
	end

	return "Torso"
end

local function buildAliasLookup(combatConfig)
	local lookup = {}

	for zoneName, aliases in pairs(combatConfig.hitZones.aliases) do
		local normalizedZone = normalizeZoneName(zoneName)
		for _, alias in ipairs(aliases) do
			lookup[string.lower(alias)] = normalizedZone
		end
	end

	return lookup
end

function DamageService.new(configSnapshotService, remoteRegistryService)
	local snapshot = configSnapshotService:GetSnapshot()
	local self = setmetatable({
		Name = "DamageService",
		_config = snapshot.combat,
		_networkConfig = snapshot.network,
		_remoteRegistryService = remoteRegistryService,
		_aliasLookup = buildAliasLookup(snapshot.combat),
		_lastHitZones = {} :: { [Humanoid]: string },
		_boundPlayers = {} :: { [Player]: boolean },
	}, DamageService)

	for _, player in ipairs(Players:GetPlayers()) do
		self:BindPlayerCharacter(player)
	end

	Players.PlayerAdded:Connect(function(player)
		self:BindPlayerCharacter(player)
	end)

	return self
end

function DamageService:_getRemoteEvent(name: string)
	local remoteRoot = self._remoteRegistryService:GetRemoteFolder()
	local eventsFolder = remoteRoot and remoteRoot:FindFirstChild(self._networkConfig.folders.events)
	if not eventsFolder then
		return nil
	end

	local remoteEvent = eventsFolder:FindFirstChild(name)
	if remoteEvent and remoteEvent:IsA("RemoteEvent") then
		return remoteEvent
	end

	return nil
end

function DamageService:_getRemoteFunction(name: string)
	local remoteRoot = self._remoteRegistryService:GetRemoteFolder()
	local functionsFolder = remoteRoot and remoteRoot:FindFirstChild(self._networkConfig.folders.functions)
	if not functionsFolder then
		return nil
	end

	local remoteFunction = functionsFolder:FindFirstChild(name)
	if remoteFunction and remoteFunction:IsA("RemoteFunction") then
		return remoteFunction
	end

	return nil
end

function DamageService:_emitElimination(player: Player, hitZone: string)
	local playerEliminated = self:_getRemoteEvent("PlayerEliminated")
	if playerEliminated then
		playerEliminated:FireAllClients({
			userId = player.UserId,
			name = player.Name,
			hitZone = hitZone,
		})
	end
end

function DamageService:_bindCharacter(player: Player, character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid")
	humanoid.MaxHealth = self._config.health.maxHealth
	humanoid.Health = humanoid.MaxHealth
	humanoid.UseJumpPower = true

	humanoid.Died:Connect(function()
		local hitZone = self._lastHitZones[humanoid] or self._config.hitZones.defaultZone
		Logger.info("DamageService", string.format("Player eliminated: %s via %s", player.Name, hitZone))
		self:_emitElimination(player, hitZone)
		self._lastHitZones[humanoid] = nil
	end)
end

function DamageService:GetCombatConfig()
	return self._config
end

function DamageService:GetHitZoneMultiplier(zoneName: string)
	local normalizedZone = normalizeZoneName(zoneName)
	if normalizedZone == "Head" then
		return self._config.hitZones.multipliers.head
	elseif normalizedZone == "Arms" then
		return self._config.hitZones.multipliers.arms
	elseif normalizedZone == "Legs" then
		return self._config.hitZones.multipliers.legs
	end

	return self._config.hitZones.multipliers.torso
end

function DamageService:ResolveHitZone(partName: string)
	return self._aliasLookup[string.lower(partName)] or self._config.hitZones.defaultZone
end

function DamageService:ApplyHumanoidDamage(humanoid: Humanoid, baseDamage: number, hitZone: string)
	if humanoid.Health <= 0 then
		return nil
	end

	local normalizedZone = normalizeZoneName(hitZone)
	local multiplier = self:GetHitZoneMultiplier(normalizedZone)
	local finalDamage = math.max(0, baseDamage * multiplier)
	self._lastHitZones[humanoid] = normalizedZone
	humanoid:TakeDamage(finalDamage)

	return {
		hitZone = normalizedZone,
		baseDamage = baseDamage,
		multiplier = multiplier,
		finalDamage = finalDamage,
		remainingHealth = math.max(humanoid.Health, 0),
	}
end

function DamageService:BindPlayerCharacter(player: Player)
	if self._boundPlayers[player] then
		return
	end

	self._boundPlayers[player] = true

	player.CharacterAdded:Connect(function(character)
		self:_bindCharacter(player, character)
	end)

	if player.Character then
		self:_bindCharacter(player, player.Character)
	end
end

function DamageService:BindDebugRemote()
	if not self._config.debug.enableDebugDamageRemote then
		return
	end

	local debugDamageRequest = self:_getRemoteFunction("DebugDamageRequest")
	if not debugDamageRequest then
		return
	end

	debugDamageRequest.OnServerInvoke = function(player, hitZone, baseDamage)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return {
				success = false,
				reason = "NoHumanoid",
			}
		end

		local resolvedZone = if type(hitZone) == "string" then hitZone else self._config.hitZones.defaultZone
		local resolvedDamage = self._config.debug.defaultDamage
		if type(baseDamage) == "number" then
			resolvedDamage = math.clamp(baseDamage, 1, self._config.debug.defaultDamage * 4)
		end
		local result = self:ApplyHumanoidDamage(humanoid, resolvedDamage, resolvedZone)

		return {
			success = result ~= nil,
			result = result,
		}
	end
end

return DamageService
