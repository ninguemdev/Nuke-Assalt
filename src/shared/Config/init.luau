--!strict

local DeepFreeze = require(script.Parent.Util.DeepFreeze)
local ConfigValidator = require(script.ConfigValidator)

type ConfigTypes = require(script.Parent.Types.ConfigTypes)

export type ConfigModule = {
	GetMatchConfig: () -> ConfigTypes.MatchConfig,
	GetEconomyConfig: () -> ConfigTypes.EconomyConfig,
	GetCatalogConfig: () -> ConfigTypes.CatalogConfig,
	GetMapConfig: () -> ConfigTypes.MapConfig,
	GetCombatConfig: () -> ConfigTypes.CombatConfig,
	GetRuntimeConfig: () -> ConfigTypes.RuntimeConfig,
	GetNetworkConfig: () -> ConfigTypes.NetworkConfig,
	ValidateGeneratedConfigs: () -> boolean,
}

local matchConfig = DeepFreeze(require(script.Generated.MatchConfig)) :: ConfigTypes.MatchConfig
local economyConfig = DeepFreeze(require(script.Generated.EconomyConfig)) :: ConfigTypes.EconomyConfig
local catalogConfig = DeepFreeze(require(script.Generated.CatalogConfig)) :: ConfigTypes.CatalogConfig
local mapConfig = DeepFreeze(require(script.Generated.MapConfig)) :: ConfigTypes.MapConfig
local combatConfig = DeepFreeze(require(script.Generated.CombatConfig)) :: ConfigTypes.CombatConfig
local runtimeConfig = DeepFreeze(require(script.Generated.RuntimeConfig)) :: ConfigTypes.RuntimeConfig
local networkConfig = DeepFreeze(require(script.Generated.NetworkConfig)) :: ConfigTypes.NetworkConfig

local Config: ConfigModule = {} :: any

function Config.GetMatchConfig(): ConfigTypes.MatchConfig
	return matchConfig
end

function Config.GetEconomyConfig(): ConfigTypes.EconomyConfig
	return economyConfig
end

function Config.GetCatalogConfig(): ConfigTypes.CatalogConfig
	return catalogConfig
end

function Config.GetMapConfig(): ConfigTypes.MapConfig
	return mapConfig
end

function Config.GetCombatConfig(): ConfigTypes.CombatConfig
	return combatConfig
end

function Config.GetRuntimeConfig(): ConfigTypes.RuntimeConfig
	return runtimeConfig
end

function Config.GetNetworkConfig(): ConfigTypes.NetworkConfig
	return networkConfig
end

function Config.ValidateGeneratedConfigs(): boolean
	return ConfigValidator.Validate(matchConfig, economyConfig, catalogConfig, mapConfig, combatConfig, runtimeConfig, networkConfig)
end

Config.ValidateGeneratedConfigs()

return table.freeze(Config) :: ConfigModule
