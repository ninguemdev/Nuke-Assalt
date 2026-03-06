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
		assertNonEmptyString(item.team, string.format("%s.team", collectionName))
		assert(type(item.cost) == "number" and item.cost >= 0, string.format("%s.cost must be zero or greater", collectionName))
		assert(not seenIds[item.id], string.format("Duplicate catalog id detected: %s", item.id))
		assert(not seenNames[item.name], string.format("Duplicate catalog name detected: %s", item.name))
		seenIds[item.id] = true
		seenNames[item.name] = true
	end
end

local ConfigValidator = {}

function ConfigValidator.Validate(matchConfig: any, economyConfig: any, catalogConfig: any)
	assert(type(matchConfig) == "table", "Match config must be a table")
	assert(type(economyConfig) == "table", "Economy config must be a table")
	assert(type(catalogConfig) == "table", "Catalog config must be a table")

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
	assert(type(catalogConfig.weapons) == "table", "catalogConfig.weapons must be a table")
	assert(type(catalogConfig.utilities) == "table", "catalogConfig.utilities must be a table")
	assert(type(catalogConfig.equipment) == "table", "catalogConfig.equipment must be a table")

	local seenIds = {
		[matchConfig.id] = true,
		[economyConfig.id] = true,
		[catalogConfig.id] = true,
	}
	local seenNames = {
		[matchConfig.name] = true,
		[economyConfig.name] = true,
		[catalogConfig.name] = true,
	}

	validateCatalogItems(catalogConfig.weapons, "catalogConfig.weapons", seenIds, seenNames)
	validateCatalogItems(catalogConfig.utilities, "catalogConfig.utilities", seenIds, seenNames)
	validateCatalogItems(catalogConfig.equipment, "catalogConfig.equipment", seenIds, seenNames)

	return true
end

return ConfigValidator
