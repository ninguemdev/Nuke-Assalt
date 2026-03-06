--!strict

type ServiceMap = { [string]: any }

local ServiceRegistry = {}
ServiceRegistry.__index = ServiceRegistry

function ServiceRegistry.new()
	local self = {
		_services = {} :: ServiceMap,
	}

	return setmetatable(self, ServiceRegistry)
end

function ServiceRegistry:Register(name: string, service: any)
	assert(name ~= "", "Service name must not be empty")
	assert(self._services[name] == nil, string.format("Service '%s' is already registered", name))
	self._services[name] = service
	return service
end

function ServiceRegistry:Resolve(name: string)
	local service = self._services[name]
	assert(service ~= nil, string.format("Service '%s' is not registered", name))
	return service
end

return ServiceRegistry
