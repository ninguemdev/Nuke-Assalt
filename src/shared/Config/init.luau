--!strict

local DeepFreeze = require(script.Parent.Util.DeepFreeze)
local ConfigValidator = require(script.ConfigValidator)

local matchConfig = DeepFreeze(require(script.Generated.MatchConfig))
local economyConfig = DeepFreeze(require(script.Generated.EconomyConfig))
local catalogConfig = DeepFreeze(require(script.Generated.CatalogConfig))
local runtimeConfig = DeepFreeze(require(script.Generated.RuntimeConfig))
local networkConfig = DeepFreeze(require(script.Generated.NetworkConfig))

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

function Config.GetRuntimeConfig()
	return runtimeConfig
end

function Config.GetNetworkConfig()
	return networkConfig
end

function Config.ValidateGeneratedConfigs()
	return ConfigValidator.Validate(matchConfig, economyConfig, catalogConfig, runtimeConfig, networkConfig)
end

Config.ValidateGeneratedConfigs()

return table.freeze(Config)
