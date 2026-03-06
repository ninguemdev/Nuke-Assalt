--!strict

local DeepFreeze = require(script.Parent.Util.DeepFreeze)
local ConfigValidator = require(script.ConfigValidator)

local matchConfig = DeepFreeze(require(script.Generated.MatchConfig))
local economyConfig = DeepFreeze(require(script.Generated.EconomyConfig))
local catalogConfig = DeepFreeze(require(script.Generated.CatalogConfig))

local Config = {}

function Config.GetMatchConfig()
	return matchConfig
end

function Config.GetEconomyConfig()
	return economyConfig
end

function Config.GetCatalogConfig()
	return catalogConfig
end

function Config.ValidateGeneratedConfigs()
	return ConfigValidator.Validate(matchConfig, economyConfig, catalogConfig)
end

Config.ValidateGeneratedConfigs()

return table.freeze(Config)
