--!strict

local function assertNonEmptyString(value: any, label: string)
	assert(type(value) == "string" and value ~= "", string.format("%s must be a non-empty string", label))
end

local function assertPositiveNumber(value: any, label: string)
	assert(type(value) == "number" and value > 0, string.format("%s must be a positive number", label))
end

local function assertNonNegativeNumber(value: any, label: string)
	assert(type(value) == "number" and value >= 0, string.format("%s must be a non-negative number", label))
end

local function validateVector3(value: any, label: string)
	assert(type(value) == "table", string.format("%s must be a table", label))
	assert(type(value.x) == "number", string.format("%s.x must be a number", label))
	assert(type(value.y) == "number", string.format("%s.y must be a number", label))
	assert(type(value.z) == "number", string.format("%s.z must be a number", label))
end

local function validateColor3(value: any, label: string)
	assert(type(value) == "table", string.format("%s must be a table", label))
	assert(type(value.r) == "number" and value.r >= 0 and value.r <= 255, string.format("%s.r must be between 0 and 255", label))
	assert(type(value.g) == "number" and value.g >= 0 and value.g <= 255, string.format("%s.g must be between 0 and 255", label))
	assert(type(value.b) == "number" and value.b >= 0 and value.b <= 255, string.format("%s.b must be between 0 and 255", label))
end

local function assertBoolean(value: any, label: string)
	assert(type(value) == "boolean", string.format("%s must be a boolean", label))
end

local function validateCatalogItems(items: { any }, collectionName: string, seenIds: { [string]: boolean }, seenNames: { [string]: boolean })
	for _, item in ipairs(items) do
		assert(type(item) == "table", string.format("%s entries must be tables", collectionName))
		assertNonEmptyString(item.id, string.format("%s.id", collectionName))
		assertNonEmptyString(item.name, string.format("%s.name", collectionName))
		assertNonEmptyString(item.itemType, string.format("%s.itemType", collectionName))
		assertNonEmptyString(item.slot, string.format("%s.slot", collectionName))
		assertNonEmptyString(item.team, string.format("%s.team", collectionName))
		assertNonEmptyString(item.economyClass, string.format("%s.economyClass", collectionName))
		assert(type(item.cost) == "number" and item.cost >= 0, string.format("%s.cost must be zero or greater", collectionName))
		assert(type(item.maxPerLoadout) == "number" and item.maxPerLoadout >= 1, string.format("%s.maxPerLoadout must be one or greater", collectionName))
		assert(not seenIds[item.id], string.format("Duplicate catalog id detected: %s", item.id))
		assert(not seenNames[item.name], string.format("Duplicate catalog name detected: %s", item.name))
		seenIds[item.id] = true
		seenNames[item.name] = true
	end
end

local function validateRemoteDefinitions(collectionName: string, items: { any }, seenNames: { [string]: boolean })
	for _, item in ipairs(items) do
		assert(type(item) == "table", string.format("%s entries must be tables", collectionName))
		assertNonEmptyString(item.name, string.format("%s.name", collectionName))
		assertNonEmptyString(item.channel, string.format("%s.channel", collectionName))
		assertNonEmptyString(item.scope, string.format("%s.scope", collectionName))
		assert(not seenNames[item.name], string.format("Duplicate remote contract detected: %s", item.name))
		seenNames[item.name] = true
	end
end

local function validateMapDefinitions(mapConfig: any)
	assertNonEmptyString(mapConfig.id, "mapConfig.id")
	assertNonEmptyString(mapConfig.name, "mapConfig.name")
	assertNonEmptyString(mapConfig.theme, "mapConfig.theme")
	assertNonEmptyString(mapConfig.workspaceModelName, "mapConfig.workspaceModelName")
	assert(type(mapConfig.spawns) == "table", "mapConfig.spawns must be a table")
	assert(type(mapConfig.callouts) == "table", "mapConfig.callouts must be a table")
	assert(type(mapConfig.routes) == "table", "mapConfig.routes must be a table")
	assert(type(mapConfig.bombsites) == "table", "mapConfig.bombsites must be a table")
	assert(type(mapConfig.anchorPoints) == "table", "mapConfig.anchorPoints must be a table")
	assert(type(mapConfig.geometry) == "table", "mapConfig.geometry must be a table")
	assert(#mapConfig.bombsites >= 2, "mapConfig.bombsites must contain at least two bombsites")
	assert(#mapConfig.geometry > 0, "mapConfig.geometry must not be empty")

	local calloutIds = {}
	local calloutNames = {}
	local routeIds = {}
	local bombsiteIds = {}
	local spawnTeams = {}

	for _, spawn in ipairs(mapConfig.spawns) do
		assertNonEmptyString(spawn.id, "mapConfig.spawns.id")
		assertNonEmptyString(spawn.name, "mapConfig.spawns.name")
		assertNonEmptyString(spawn.team, "mapConfig.spawns.team")
		validateVector3(spawn.position, "mapConfig.spawns.position")
		spawnTeams[spawn.team] = true
	end

	assert(spawnTeams.Attackers, "mapConfig.spawns must include an Attackers spawn")
	assert(spawnTeams.Defenders, "mapConfig.spawns must include a Defenders spawn")
	assert(spawnTeams.Spectators, "mapConfig.spawns must include a Spectators spawn")

	for _, callout in ipairs(mapConfig.callouts) do
		assertNonEmptyString(callout.id, "mapConfig.callouts.id")
		assertNonEmptyString(callout.name, "mapConfig.callouts.name")
		validateVector3(callout.position, "mapConfig.callouts.position")
		assert(not calloutIds[callout.id], string.format("Duplicate map callout id detected: %s", callout.id))
		assert(not calloutNames[callout.name], string.format("Duplicate map callout name detected: %s", callout.name))
		calloutIds[callout.id] = true
		calloutNames[callout.name] = true
	end

	for _, route in ipairs(mapConfig.routes) do
		assertNonEmptyString(route.id, "mapConfig.routes.id")
		assertNonEmptyString(route.name, "mapConfig.routes.name")
		assertNonEmptyString(route.fromCalloutId, "mapConfig.routes.fromCalloutId")
		assertNonEmptyString(route.toCalloutId, "mapConfig.routes.toCalloutId")
		assertNonEmptyString(route.siteId, "mapConfig.routes.siteId")
		assert(calloutIds[route.fromCalloutId], string.format("Unknown route fromCalloutId: %s", route.fromCalloutId))
		assert(calloutIds[route.toCalloutId], string.format("Unknown route toCalloutId: %s", route.toCalloutId))
		assert(not routeIds[route.id], string.format("Duplicate map route id detected: %s", route.id))
		routeIds[route.id] = true
	end

	for _, bombsite in ipairs(mapConfig.bombsites) do
		assertNonEmptyString(bombsite.id, "mapConfig.bombsites.id")
		assertNonEmptyString(bombsite.name, "mapConfig.bombsites.name")
		assert(type(bombsite.calloutIds) == "table", "mapConfig.bombsites.calloutIds must be a table")
		assert(type(bombsite.entryRouteIds) == "table", "mapConfig.bombsites.entryRouteIds must be a table")
		assert(type(bombsite.plantZones) == "table", "mapConfig.bombsites.plantZones must be a table")
		assert(#bombsite.entryRouteIds >= 2, string.format("Bombsite '%s' must expose at least two entry routes", bombsite.id))
		assert(#bombsite.plantZones > 0, string.format("Bombsite '%s' must define at least one plant zone", bombsite.id))
		bombsiteIds[bombsite.id] = true

		for _, calloutId in ipairs(bombsite.calloutIds) do
			assert(calloutIds[calloutId], string.format("Bombsite '%s' references unknown callout '%s'", bombsite.id, calloutId))
		end

		for _, routeId in ipairs(bombsite.entryRouteIds) do
			assert(routeIds[routeId], string.format("Bombsite '%s' references unknown route '%s'", bombsite.id, routeId))
		end

		for _, plantZone in ipairs(bombsite.plantZones) do
			assertNonEmptyString(plantZone.id, "mapConfig.bombsites.plantZones.id")
			assertNonEmptyString(plantZone.name, "mapConfig.bombsites.plantZones.name")
			validateVector3(plantZone.position, "mapConfig.bombsites.plantZones.position")
			validateVector3(plantZone.size, "mapConfig.bombsites.plantZones.size")
		end
	end

	for _, route in ipairs(mapConfig.routes) do
		assert(route.siteId == "Mid" or bombsiteIds[route.siteId], string.format("Unknown route.siteId '%s'", route.siteId))
	end

	for _, anchorPoint in ipairs(mapConfig.anchorPoints) do
		assertNonEmptyString(anchorPoint.id, "mapConfig.anchorPoints.id")
		assertNonEmptyString(anchorPoint.name, "mapConfig.anchorPoints.name")
		assertNonEmptyString(anchorPoint.anchorType, "mapConfig.anchorPoints.anchorType")
		assertNonEmptyString(anchorPoint.siteId, "mapConfig.anchorPoints.siteId")
		assertNonEmptyString(anchorPoint.calloutId, "mapConfig.anchorPoints.calloutId")
		validateVector3(anchorPoint.position, "mapConfig.anchorPoints.position")
		assert(type(anchorPoint.insidePlantZone) == "boolean", "mapConfig.anchorPoints.insidePlantZone must be a boolean")
		assert(anchorPoint.siteId == "Mid" or bombsiteIds[anchorPoint.siteId], string.format("Unknown anchorPoint.siteId '%s'", anchorPoint.siteId))
		assert(calloutIds[anchorPoint.calloutId], string.format("Unknown anchorPoint.calloutId '%s'", anchorPoint.calloutId))
		assert(not anchorPoint.insidePlantZone, string.format("Anchor point '%s' must not be inside a plant zone", anchorPoint.id))
	end

	for _, geometry in ipairs(mapConfig.geometry) do
		assertNonEmptyString(geometry.id, "mapConfig.geometry.id")
		assertNonEmptyString(geometry.name, "mapConfig.geometry.name")
		validateVector3(geometry.position, "mapConfig.geometry.position")
		validateVector3(geometry.size, "mapConfig.geometry.size")
		validateColor3(geometry.color, "mapConfig.geometry.color")
		assertNonEmptyString(geometry.material, "mapConfig.geometry.material")
		assertNonNegativeNumber(geometry.transparency, "mapConfig.geometry.transparency")
		assert(type(geometry.canCollide) == "boolean", "mapConfig.geometry.canCollide must be a boolean")
	end
end

local function validateCombatDefinitions(combatConfig: any)
	assertNonEmptyString(combatConfig.id, "combatConfig.id")
	assertNonEmptyString(combatConfig.name, "combatConfig.name")
	assert(type(combatConfig.health) == "table", "combatConfig.health must be a table")
	assert(type(combatConfig.hitZones) == "table", "combatConfig.hitZones must be a table")
	assert(type(combatConfig.movement) == "table", "combatConfig.movement must be a table")
	assert(type(combatConfig.avatar) == "table", "combatConfig.avatar must be a table")
	assert(type(combatConfig.animation) == "table", "combatConfig.animation must be a table")
	assert(type(combatConfig.debug) == "table", "combatConfig.debug must be a table")

	assertPositiveNumber(combatConfig.health.maxHealth, "combatConfig.health.maxHealth")
	assert(type(combatConfig.health.allowFriendlyFire) == "boolean", "combatConfig.health.allowFriendlyFire must be a boolean")

	assertNonEmptyString(combatConfig.hitZones.defaultZone, "combatConfig.hitZones.defaultZone")
	assert(type(combatConfig.hitZones.aliases) == "table", "combatConfig.hitZones.aliases must be a table")
	assert(type(combatConfig.hitZones.multipliers) == "table", "combatConfig.hitZones.multipliers must be a table")
	assert(#combatConfig.hitZones.aliases.head > 0, "combatConfig.hitZones.aliases.head must not be empty")
	assert(#combatConfig.hitZones.aliases.torso > 0, "combatConfig.hitZones.aliases.torso must not be empty")
	assert(#combatConfig.hitZones.aliases.arms > 0, "combatConfig.hitZones.aliases.arms must not be empty")
	assert(#combatConfig.hitZones.aliases.legs > 0, "combatConfig.hitZones.aliases.legs must not be empty")
	assertPositiveNumber(combatConfig.hitZones.multipliers.head, "combatConfig.hitZones.multipliers.head")
	assertPositiveNumber(combatConfig.hitZones.multipliers.torso, "combatConfig.hitZones.multipliers.torso")
	assertPositiveNumber(combatConfig.hitZones.multipliers.arms, "combatConfig.hitZones.multipliers.arms")
	assertPositiveNumber(combatConfig.hitZones.multipliers.legs, "combatConfig.hitZones.multipliers.legs")
	assert(
		combatConfig.hitZones.multipliers.head > combatConfig.hitZones.multipliers.torso,
		"combatConfig.hitZones.multipliers.head must be greater than torso"
	)
	assert(
		combatConfig.hitZones.multipliers.torso > combatConfig.hitZones.multipliers.legs,
		"combatConfig.hitZones.multipliers.torso must be greater than legs"
	)

	assertPositiveNumber(combatConfig.movement.walkSpeed, "combatConfig.movement.walkSpeed")
	assertPositiveNumber(combatConfig.movement.sprintSpeed, "combatConfig.movement.sprintSpeed")
	assertPositiveNumber(combatConfig.movement.crouchSpeed, "combatConfig.movement.crouchSpeed")
	assertPositiveNumber(combatConfig.movement.jumpPower, "combatConfig.movement.jumpPower")
	assert(type(combatConfig.movement.crouchCameraOffsetY) == "number", "combatConfig.movement.crouchCameraOffsetY must be a number")
	assertPositiveNumber(combatConfig.movement.firstPersonMinZoom, "combatConfig.movement.firstPersonMinZoom")
	assertPositiveNumber(combatConfig.movement.firstPersonMaxZoom, "combatConfig.movement.firstPersonMaxZoom")
	assertPositiveNumber(combatConfig.movement.moveAccuracyMultiplier, "combatConfig.movement.moveAccuracyMultiplier")
	assertPositiveNumber(combatConfig.movement.sprintAccuracyMultiplier, "combatConfig.movement.sprintAccuracyMultiplier")
	assertPositiveNumber(combatConfig.movement.crouchAccuracyMultiplier, "combatConfig.movement.crouchAccuracyMultiplier")
	assertPositiveNumber(combatConfig.movement.jumpAccuracyMultiplier, "combatConfig.movement.jumpAccuracyMultiplier")
	assert(combatConfig.movement.crouchSpeed < combatConfig.movement.walkSpeed, "crouchSpeed must be lower than walkSpeed")
	assert(combatConfig.movement.walkSpeed < combatConfig.movement.sprintSpeed, "walkSpeed must be lower than sprintSpeed")
	assert(
		combatConfig.movement.crouchAccuracyMultiplier < 1,
		"crouchAccuracyMultiplier should improve accuracy and stay below 1"
	)
	assert(combatConfig.movement.moveAccuracyMultiplier >= 1, "moveAccuracyMultiplier must be at least 1")
	assert(
		combatConfig.movement.sprintAccuracyMultiplier >= combatConfig.movement.moveAccuracyMultiplier,
		"sprintAccuracyMultiplier must be at least moveAccuracyMultiplier"
	)
	assert(
		combatConfig.movement.jumpAccuracyMultiplier >= combatConfig.movement.sprintAccuracyMultiplier,
		"jumpAccuracyMultiplier must be at least sprintAccuracyMultiplier"
	)

	assertNonEmptyString(combatConfig.avatar.expectedRigType, "combatConfig.avatar.expectedRigType")
	assertBoolean(combatConfig.avatar.loadCharacterAppearance, "combatConfig.avatar.loadCharacterAppearance")
	assertBoolean(combatConfig.avatar.stripAccessories, "combatConfig.avatar.stripAccessories")
	assertBoolean(combatConfig.avatar.stripCharacterMeshes, "combatConfig.avatar.stripCharacterMeshes")
	assertBoolean(combatConfig.avatar.showLocalBodyInFirstPerson, "combatConfig.avatar.showLocalBodyInFirstPerson")
	assertBoolean(combatConfig.avatar.showOnlyArmsInFirstPerson, "combatConfig.avatar.showOnlyArmsInFirstPerson")
	assertBoolean(combatConfig.avatar.hideHeadInFirstPerson, "combatConfig.avatar.hideHeadInFirstPerson")
	assert(type(combatConfig.avatar.preserveAppearanceFields) == "table", "combatConfig.avatar.preserveAppearanceFields must be a table")
	assert(type(combatConfig.avatar.studioFallbackAppearance) == "table", "combatConfig.avatar.studioFallbackAppearance must be a table")
	assert(combatConfig.avatar.expectedRigType == "R15", "combatConfig.avatar.expectedRigType must be R15 for the current beta")
	assert(not combatConfig.avatar.showLocalBodyInFirstPerson, "combatConfig.avatar.showLocalBodyInFirstPerson must be false when arms-only first person is enabled")
	assert(combatConfig.avatar.showOnlyArmsInFirstPerson, "combatConfig.avatar.showOnlyArmsInFirstPerson must stay enabled")

	local preserveFieldSet = {
		face = true,
		shirt = true,
		pants = true,
		graphicTShirt = true,
		bodyColors = true,
	}
	local seenPreserveFields = {}
	for _, field in ipairs(combatConfig.avatar.preserveAppearanceFields) do
		assertNonEmptyString(field, "combatConfig.avatar.preserveAppearanceFields")
		assert(preserveFieldSet[field], string.format("Unsupported preserved appearance field: %s", field))
		assert(not seenPreserveFields[field], string.format("Duplicate preserved appearance field: %s", field))
		seenPreserveFields[field] = true
	end

	for fieldName in pairs(preserveFieldSet) do
		assert(seenPreserveFields[fieldName], string.format("Missing preserved appearance field: %s", fieldName))
	end

	assertNonEmptyString(combatConfig.avatar.studioFallbackAppearance.mode, "combatConfig.avatar.studioFallbackAppearance.mode")
	assertPositiveNumber(combatConfig.avatar.studioFallbackAppearance.face, "combatConfig.avatar.studioFallbackAppearance.face")
	assertNonNegativeNumber(combatConfig.avatar.studioFallbackAppearance.shirt, "combatConfig.avatar.studioFallbackAppearance.shirt")
	assertNonNegativeNumber(combatConfig.avatar.studioFallbackAppearance.pants, "combatConfig.avatar.studioFallbackAppearance.pants")
	assertNonNegativeNumber(combatConfig.avatar.studioFallbackAppearance.graphicTShirt, "combatConfig.avatar.studioFallbackAppearance.graphicTShirt")
	validateColor3(combatConfig.avatar.studioFallbackAppearance.bodyColors.head, "combatConfig.avatar.studioFallbackAppearance.bodyColors.head")
	validateColor3(combatConfig.avatar.studioFallbackAppearance.bodyColors.torso, "combatConfig.avatar.studioFallbackAppearance.bodyColors.torso")
	validateColor3(combatConfig.avatar.studioFallbackAppearance.bodyColors.leftArm, "combatConfig.avatar.studioFallbackAppearance.bodyColors.leftArm")
	validateColor3(combatConfig.avatar.studioFallbackAppearance.bodyColors.rightArm, "combatConfig.avatar.studioFallbackAppearance.bodyColors.rightArm")
	validateColor3(combatConfig.avatar.studioFallbackAppearance.bodyColors.leftLeg, "combatConfig.avatar.studioFallbackAppearance.bodyColors.leftLeg")
	validateColor3(combatConfig.avatar.studioFallbackAppearance.bodyColors.rightLeg, "combatConfig.avatar.studioFallbackAppearance.bodyColors.rightLeg")

	assertNonEmptyString(combatConfig.animation.profileId, "combatConfig.animation.profileId")
	assertPositiveNumber(combatConfig.animation.blendTimeSeconds, "combatConfig.animation.blendTimeSeconds")
	assertPositiveNumber(combatConfig.animation.walkTrackSpeed, "combatConfig.animation.walkTrackSpeed")
	assertPositiveNumber(combatConfig.animation.runTrackSpeed, "combatConfig.animation.runTrackSpeed")
	assertPositiveNumber(combatConfig.animation.crouchTrackSpeed, "combatConfig.animation.crouchTrackSpeed")
	assert(type(combatConfig.animation.tracks) == "table", "combatConfig.animation.tracks must be a table")
	assert(type(combatConfig.animation.crouchPose) == "table", "combatConfig.animation.crouchPose must be a table")
	assertPositiveNumber(combatConfig.animation.tracks.idle, "combatConfig.animation.tracks.idle")
	assertPositiveNumber(combatConfig.animation.tracks.walk, "combatConfig.animation.tracks.walk")
	assertPositiveNumber(combatConfig.animation.tracks.run, "combatConfig.animation.tracks.run")
	assertPositiveNumber(combatConfig.animation.tracks.jump, "combatConfig.animation.tracks.jump")
	assertPositiveNumber(combatConfig.animation.tracks.fall, "combatConfig.animation.tracks.fall")
	assertPositiveNumber(combatConfig.animation.tracks.crouch, "combatConfig.animation.tracks.crouch")
	assert(type(combatConfig.animation.crouchPose.torsoOffsetY) == "number", "combatConfig.animation.crouchPose.torsoOffsetY must be a number")
	assert(type(combatConfig.animation.crouchPose.rootPitchDegrees) == "number", "combatConfig.animation.crouchPose.rootPitchDegrees must be a number")
	assert(type(combatConfig.animation.crouchPose.neckPitchDegrees) == "number", "combatConfig.animation.crouchPose.neckPitchDegrees must be a number")
	assert(type(combatConfig.animation.crouchPose.shoulderRollDegrees) == "number", "combatConfig.animation.crouchPose.shoulderRollDegrees must be a number")
	assert(type(combatConfig.animation.crouchPose.hipPitchDegrees) == "number", "combatConfig.animation.crouchPose.hipPitchDegrees must be a number")
	assert(
		combatConfig.animation.crouchTrackSpeed < combatConfig.animation.walkTrackSpeed,
		"combatConfig.animation.crouchTrackSpeed must be below walkTrackSpeed"
	)
	assert(
		combatConfig.animation.runTrackSpeed >= combatConfig.animation.walkTrackSpeed,
		"combatConfig.animation.runTrackSpeed must be at least walkTrackSpeed"
	)
	assert(combatConfig.animation.profileId == "standard-r15", "combatConfig.animation.profileId must be standard-r15")

	local uniqueTrackIds = {}
	for trackName, trackId in pairs(combatConfig.animation.tracks) do
		assert(not uniqueTrackIds[trackId], string.format("Duplicate animation asset id detected for %s", trackName))
		uniqueTrackIds[trackId] = trackName
	end

	assert(type(combatConfig.debug.enableDebugDamageRemote) == "boolean", "combatConfig.debug.enableDebugDamageRemote must be a boolean")
	assertPositiveNumber(combatConfig.debug.defaultDamage, "combatConfig.debug.defaultDamage")
end

local ConfigValidator = {}

function ConfigValidator.Validate(matchConfig: any, economyConfig: any, catalogConfig: any, mapConfig: any, combatConfig: any, runtimeConfig: any, networkConfig: any)
	assert(type(matchConfig) == "table", "Match config must be a table")
	assert(type(economyConfig) == "table", "Economy config must be a table")
	assert(type(catalogConfig) == "table", "Catalog config must be a table")
	assert(type(mapConfig) == "table", "Map config must be a table")
	assert(type(combatConfig) == "table", "Combat config must be a table")
	assert(type(runtimeConfig) == "table", "Runtime config must be a table")
	assert(type(networkConfig) == "table", "Network config must be a table")

	assertNonEmptyString(matchConfig.id, "matchConfig.id")
	assertNonEmptyString(matchConfig.name, "matchConfig.name")
	assert(type(matchConfig.format) == "table", "matchConfig.format must be a table")
	assert(type(matchConfig.timers) == "table", "matchConfig.timers must be a table")
	assert(type(matchConfig.format.roundsToWin) == "number", "matchConfig.format.roundsToWin must be a number")
	assert(type(matchConfig.format.swapAfterRounds) == "number", "matchConfig.format.swapAfterRounds must be a number")
	assertPositiveNumber(matchConfig.format.minimumPlayersToStart, "matchConfig.format.minimumPlayersToStart")
	assertPositiveNumber(matchConfig.timers.buyPhaseSeconds, "matchConfig.timers.buyPhaseSeconds")
	assertPositiveNumber(matchConfig.timers.roundSeconds, "matchConfig.timers.roundSeconds")
	assertPositiveNumber(matchConfig.timers.postPlantSeconds, "matchConfig.timers.postPlantSeconds")
	assert(matchConfig.timers.buyPhaseSeconds < matchConfig.timers.roundSeconds, "Buy phase must be shorter than the live round")
	assert(matchConfig.format.swapAfterRounds >= 1, "Side swap must happen after at least one round")

	assertNonEmptyString(economyConfig.id, "economyConfig.id")
	assertNonEmptyString(economyConfig.name, "economyConfig.name")
	assert(type(economyConfig.startingMoney) == "number" and economyConfig.startingMoney >= 0, "economyConfig.startingMoney must be zero or greater")
	assert(type(economyConfig.lossBonusSequence) == "table", "economyConfig.lossBonusSequence must be a table")
	assert(#economyConfig.lossBonusSequence > 0, "economyConfig.lossBonusSequence must not be empty")

	for index, amount in ipairs(economyConfig.lossBonusSequence) do
		assertPositiveNumber(amount, string.format("economyConfig.lossBonusSequence[%d]", index))
		if index > 1 then
			local previousAmount = economyConfig.lossBonusSequence[index - 1]
			assert(amount >= previousAmount, "Loss bonus sequence must be non-decreasing")
		end
	end

	assertNonEmptyString(catalogConfig.id, "catalogConfig.id")
	assertNonEmptyString(catalogConfig.name, "catalogConfig.name")
	assert(type(catalogConfig.loadoutRules) == "table", "catalogConfig.loadoutRules must be a table")
	assert(type(catalogConfig.weapons) == "table", "catalogConfig.weapons must be a table")
	assert(type(catalogConfig.utilities) == "table", "catalogConfig.utilities must be a table")
	assert(type(catalogConfig.equipment) == "table", "catalogConfig.equipment must be a table")
	assertPositiveNumber(catalogConfig.loadoutRules.maxUtilityTotal, "catalogConfig.loadoutRules.maxUtilityTotal")
	assertPositiveNumber(catalogConfig.loadoutRules.maxSpecialEquipment, "catalogConfig.loadoutRules.maxSpecialEquipment")
	assertPositiveNumber(catalogConfig.loadoutRules.maxPrimaryWeapons, "catalogConfig.loadoutRules.maxPrimaryWeapons")
	assertPositiveNumber(catalogConfig.loadoutRules.maxSecondaryWeapons, "catalogConfig.loadoutRules.maxSecondaryWeapons")
	assertPositiveNumber(catalogConfig.loadoutRules.maxArmor, "catalogConfig.loadoutRules.maxArmor")
	assertPositiveNumber(catalogConfig.loadoutRules.maxDefuseKits, "catalogConfig.loadoutRules.maxDefuseKits")

	validateMapDefinitions(mapConfig)
	validateCombatDefinitions(combatConfig)

	assertNonEmptyString(runtimeConfig.id, "runtimeConfig.id")
	assertNonEmptyString(runtimeConfig.name, "runtimeConfig.name")
	assert(type(runtimeConfig.featureFlags) == "table", "runtimeConfig.featureFlags must be a table")
	assert(type(runtimeConfig.tuning) == "table", "runtimeConfig.tuning must be a table")
	assert(type(runtimeConfig.featureFlags.publishRuntimeDebugAttributes) == "boolean", "runtimeConfig.featureFlags.publishRuntimeDebugAttributes must be a boolean")
	assert(type(runtimeConfig.featureFlags.createNetworkRemotesOnBoot) == "boolean", "runtimeConfig.featureFlags.createNetworkRemotesOnBoot must be a boolean")
	assert(type(runtimeConfig.featureFlags.enforceServiceContracts) == "boolean", "runtimeConfig.featureFlags.enforceServiceContracts must be a boolean")

	assertNonEmptyString(networkConfig.id, "networkConfig.id")
	assertNonEmptyString(networkConfig.name, "networkConfig.name")
	assertNonEmptyString(networkConfig.version, "networkConfig.version")
	assertNonEmptyString(networkConfig.remoteRootName, "networkConfig.remoteRootName")
	assert(type(networkConfig.folders) == "table", "networkConfig.folders must be a table")
	assertNonEmptyString(networkConfig.folders.events, "networkConfig.folders.events")
	assertNonEmptyString(networkConfig.folders.functions, "networkConfig.folders.functions")
	assert(type(networkConfig.events) == "table", "networkConfig.events must be a table")
	assert(type(networkConfig.functions) == "table", "networkConfig.functions must be a table")

	local seenIds = {
		[matchConfig.id] = true,
		[economyConfig.id] = true,
		[catalogConfig.id] = true,
		[mapConfig.id] = true,
		[combatConfig.id] = true,
		[runtimeConfig.id] = true,
		[networkConfig.id] = true,
	}
	local seenNames = {
		[matchConfig.name] = true,
		[economyConfig.name] = true,
		[catalogConfig.name] = true,
		[mapConfig.name] = true,
		[combatConfig.name] = true,
		[runtimeConfig.name] = true,
		[networkConfig.name] = true,
	}

	validateCatalogItems(catalogConfig.weapons, "catalogConfig.weapons", seenIds, seenNames)
	validateCatalogItems(catalogConfig.utilities, "catalogConfig.utilities", seenIds, seenNames)
	validateCatalogItems(catalogConfig.equipment, "catalogConfig.equipment", seenIds, seenNames)

	for _, item in ipairs(catalogConfig.weapons) do
		assert(item.team == "Both", string.format("Weapon '%s' must be available to both teams", item.id))
	end

	for _, item in ipairs(catalogConfig.utilities) do
		assert(item.team == "Both", string.format("Utility '%s' must be available to both teams", item.id))
		assert(item.maxPerLoadout <= catalogConfig.loadoutRules.maxUtilityTotal, string.format("Utility '%s' exceeds maxUtilityTotal", item.id))
	end

	for _, item in ipairs(catalogConfig.equipment) do
		if item.itemType == "DefenderEquipment" or item.itemType == "DefuseKit" then
			assert(item.team == "Defenders", string.format("Exclusive defender item '%s' must be restricted to defenders", item.id))
		else
			assert(item.team == "Both", string.format("Shared item '%s' must be available to both teams", item.id))
		end

		if item.slot == "SpecialEquipment" then
			assert(item.maxPerLoadout <= catalogConfig.loadoutRules.maxSpecialEquipment, string.format("Special equipment '%s' exceeds maxSpecialEquipment", item.id))
		end

		if item.slot == "DefuseKit" then
			assert(item.maxPerLoadout <= catalogConfig.loadoutRules.maxDefuseKits, string.format("Defuse kit '%s' exceeds maxDefuseKits", item.id))
		end
	end

	local remoteNames = {}
	validateRemoteDefinitions("networkConfig.events", networkConfig.events, remoteNames)
	validateRemoteDefinitions("networkConfig.functions", networkConfig.functions, remoteNames)

	return true
end

return ConfigValidator
