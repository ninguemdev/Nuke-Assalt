--!strict

local function assertNonEmptyString(value: any, label: string)
	assert(type(value) == "string" and value ~= "", string.format("%s must be a non-empty string", label))
end

local function assertPositiveNumber(value: any, label: string)
	assert(type(value) == "number" and value > 0, string.format("%s must be a positive number", label))
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

local ConfigValidator = {}

function ConfigValidator.Validate(matchConfig: any, economyConfig: any, catalogConfig: any, runtimeConfig: any, networkConfig: any)
	assert(type(matchConfig) == "table", "Match config must be a table")
	assert(type(economyConfig) == "table", "Economy config must be a table")
	assert(type(catalogConfig) == "table", "Catalog config must be a table")
	assert(type(runtimeConfig) == "table", "Runtime config must be a table")
	assert(type(networkConfig) == "table", "Network config must be a table")

	assertNonEmptyString(matchConfig.id, "matchConfig.id")
	assertNonEmptyString(matchConfig.name, "matchConfig.name")
	assert(type(matchConfig.format) == "table", "matchConfig.format must be a table")
	assert(type(matchConfig.timers) == "table", "matchConfig.timers must be a table")
	assert(type(matchConfig.format.roundsToWin) == "number", "matchConfig.format.roundsToWin must be a number")
	assert(type(matchConfig.format.swapAfterRounds) == "number", "matchConfig.format.swapAfterRounds must be a number")
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
		[runtimeConfig.id] = true,
		[networkConfig.id] = true,
	}
	local seenNames = {
		[matchConfig.name] = true,
		[economyConfig.name] = true,
		[catalogConfig.name] = true,
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
