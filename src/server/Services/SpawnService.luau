--!strict

local Workspace = game:GetService("Workspace")

local SpawnService = {}
SpawnService.__index = SpawnService

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

local function ensureSpawn(folder: Folder, name: string, position: Vector3): SpawnLocation
	local existing = folder:FindFirstChild(name)
	if existing and existing:IsA("SpawnLocation") then
		return existing
	end

	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = name
	spawnLocation.Anchored = true
	spawnLocation.Transparency = 1
	spawnLocation.CanCollide = false
	spawnLocation.Neutral = true
	spawnLocation.AllowTeamChangeOnTouch = false
	spawnLocation.Size = Vector3.new(6, 1, 6)
	spawnLocation.Position = position
	spawnLocation.Parent = folder
	return spawnLocation
end

function SpawnService.new()
	local self = {
		Name = "SpawnService",
		_spawnFolder = ensureFolder(Workspace, "NukeAssaltSpawns"),
	}

	self._spawns = {
		Lobby = ensureSpawn(self._spawnFolder, "Lobby", Vector3.new(0, 4, -24)),
		Attackers = ensureSpawn(self._spawnFolder, "Attackers", Vector3.new(-24, 4, 0)),
		Defenders = ensureSpawn(self._spawnFolder, "Defenders", Vector3.new(24, 4, 0)),
	}

	return setmetatable(self, SpawnService)
end

function SpawnService:GetSpawnForTeam(teamName: string)
	return self._spawns[teamName]
end

function SpawnService:MoveCharacterToTeamSpawn(character: Model, teamName: string)
	local spawnLocation = self:GetSpawnForTeam(teamName)
	assert(spawnLocation ~= nil, string.format("Missing spawn location for team '%s'", teamName))
	character:PivotTo(spawnLocation.CFrame + Vector3.new(0, 3, 0))
end

function SpawnService:MoveCharacterToLobby(character: Model)
	character:PivotTo(self._spawns.Lobby.CFrame + Vector3.new(0, 3, 0))
end

return SpawnService
