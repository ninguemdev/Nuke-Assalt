--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Logger = require(ReplicatedStorage.Shared.Util.Logger)

local networkConfig = Config.GetNetworkConfig()

local function ensureChild(parent: Instance, className: string, name: string): Instance
	local existing = parent:FindFirstChild(name)
	if existing then
		if existing.ClassName == className then
			return existing
		end

		existing:Destroy()
	end

	local child = Instance.new(className)
	child.Name = name
	child.Parent = parent
	return child
end

local RemoteRegistry = {}

function RemoteRegistry.GetDefinitions()
	return {
		events = networkConfig.events,
		functions = networkConfig.functions,
	}
end

function RemoteRegistry.GetRemoteFolder()
	return ReplicatedStorage:FindFirstChild(networkConfig.remoteRootName)
end

function RemoteRegistry.EnsureRuntimeObjects()
	local remoteRoot = ensureChild(ReplicatedStorage, "Folder", networkConfig.remoteRootName)
	local eventsFolder = ensureChild(remoteRoot, "Folder", networkConfig.folders.events)
	local functionsFolder = ensureChild(remoteRoot, "Folder", networkConfig.folders.functions)

	for _, definition in ipairs(networkConfig.events) do
		local remoteEvent = ensureChild(eventsFolder, "RemoteEvent", definition.name)
		remoteEvent:SetAttribute("Channel", definition.channel)
		remoteEvent:SetAttribute("Scope", definition.scope)
		remoteEvent:SetAttribute("Kind", "Event")
	end

	for _, definition in ipairs(networkConfig.functions) do
		local remoteFunction = ensureChild(functionsFolder, "RemoteFunction", definition.name)
		remoteFunction:SetAttribute("Channel", definition.channel)
		remoteFunction:SetAttribute("Scope", definition.scope)
		remoteFunction:SetAttribute("Kind", "Function")
	end

	remoteRoot:SetAttribute("ContractVersion", networkConfig.version)
	remoteRoot:SetAttribute("EventCount", #networkConfig.events)
	remoteRoot:SetAttribute("FunctionCount", #networkConfig.functions)

	Logger.info(
		"RemoteRegistry",
		string.format("Ensured remote contract tree: events=%d functions=%d", #networkConfig.events, #networkConfig.functions)
	)

	return {
		root = remoteRoot,
		eventsFolder = eventsFolder,
		functionsFolder = functionsFolder,
	}
end

return table.freeze(RemoteRegistry)
