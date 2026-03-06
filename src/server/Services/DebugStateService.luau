--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DebugStateService = {}
DebugStateService.__index = DebugStateService

local function ensureFolder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	end

	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function countEntries(map)
	local total = 0
	for _ in pairs(map) do
		total += 1
	end
	return total
end

function DebugStateService.new(configSnapshotService, serviceRegistry, remoteRegistryService)
	local self = {
		Name = "DebugStateService",
		_configSnapshotService = configSnapshotService,
		_serviceRegistry = serviceRegistry,
		_remoteRegistryService = remoteRegistryService,
		_runtimeFolder = ensureFolder(ReplicatedStorage, "NukeAssaltRuntime"),
	}

	return setmetatable(self, DebugStateService)
end

function DebugStateService:Publish(matchState: any?, roundState: any?)
	local snapshot = self._configSnapshotService:GetSnapshot()
	local remoteFolder = self._remoteRegistryService:GetRemoteFolder()
	local services = self._serviceRegistry:GetAll()

	self._runtimeFolder:SetAttribute("MatchConfigId", snapshot.match.id)
	self._runtimeFolder:SetAttribute("EconomyConfigId", snapshot.economy.id)
	self._runtimeFolder:SetAttribute("CatalogConfigId", snapshot.catalog.id)
	self._runtimeFolder:SetAttribute("RuntimeConfigId", snapshot.runtime.id)
	self._runtimeFolder:SetAttribute("NetworkConfigId", snapshot.network.id)
	self._runtimeFolder:SetAttribute("NetworkVersion", snapshot.network.version)
	self._runtimeFolder:SetAttribute("RemoteRootName", snapshot.network.remoteRootName)
	self._runtimeFolder:SetAttribute("ServiceCount", countEntries(services))
	self._runtimeFolder:SetAttribute("EventCount", remoteFolder:GetAttribute("EventCount"))
	self._runtimeFolder:SetAttribute("FunctionCount", remoteFolder:GetAttribute("FunctionCount"))

	if matchState then
		self._runtimeFolder:SetAttribute("MatchPhase", matchState.phase)
		self._runtimeFolder:SetAttribute("CurrentRound", matchState.roundNumber)
		self._runtimeFolder:SetAttribute("AttackersScore", matchState.attackersScore)
		self._runtimeFolder:SetAttribute("DefendersScore", matchState.defendersScore)
		self._runtimeFolder:SetAttribute("SidesSwapped", matchState.sidesSwapped)
		self._runtimeFolder:SetAttribute("RoundWinner", matchState.roundWinner)
		self._runtimeFolder:SetAttribute("RoundReason", matchState.roundReason)
		self._runtimeFolder:SetAttribute("MatchWinner", matchState.winner)
	end

	if roundState then
		self._runtimeFolder:SetAttribute("RoundPhase", roundState.phase)
		self._runtimeFolder:SetAttribute("RoundTimeRemaining", math.floor(roundState.timeRemaining))
	end
end

function DebugStateService:GetRuntimeFolder()
	return self._runtimeFolder
end

return DebugStateService
