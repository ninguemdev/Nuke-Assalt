--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local ServiceContracts = require(ReplicatedStorage.Shared.Types.ServiceContracts)

type ServiceMap = { [string]: any }

local ServiceRegistry = {}
ServiceRegistry.__index = ServiceRegistry

function ServiceRegistry.new()
	local self = {
		_services = {} :: ServiceMap,
	}

	return setmetatable(self, ServiceRegistry)
end

local function validateContract(name: string, service: any)
	if not Config.GetRuntimeConfig().featureFlags.enforceServiceContracts then
		return
	end

	local descriptor = ServiceContracts[name]
	assert(descriptor ~= nil, string.format("Missing service contract descriptor for '%s'", name))

	for _, methodName in ipairs(descriptor.methods) do
		assert(type(service[methodName]) == "function", string.format("Service '%s' is missing method '%s'", name, methodName))
	end
end

function ServiceRegistry:Register(name: string, service: any)
	assert(name ~= "", "Service name must not be empty")
	assert(self._services[name] == nil, string.format("Service '%s' is already registered", name))
	validateContract(name, service)
	self._services[name] = service
	return service
end

function ServiceRegistry:Resolve(name: string)
	local service = self._services[name]
	assert(service ~= nil, string.format("Service '%s' is not registered", name))
	return service
end

function ServiceRegistry:GetAll()
	return self._services
end

return ServiceRegistry
