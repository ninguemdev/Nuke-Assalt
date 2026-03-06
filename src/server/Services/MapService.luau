--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Logger = require(ReplicatedStorage.Shared.Util.Logger)

local MapService = {}
MapService.__index = MapService

local MANUAL_MAP_ATTRIBUTE = "NukeAssaltManualMap"

local function ensureFolder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		existing:ClearAllChildren()
		return existing
	end

	if existing then
		existing:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function ensureModel(parent: Instance, name: string): Model
	local existing = parent:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	return model
end

local function toVector3(value)
	return Vector3.new(value.x, value.y, value.z)
end

local function toColor3(value)
	return Color3.fromRGB(value.r, value.g, value.b)
end

local function getMaterial(materialName: string)
	local material = Enum.Material[materialName]
	if material == nil then
		return Enum.Material.Concrete
	end

	return material
end

local function isContainer(instance: Instance): boolean
	return instance:IsA("Folder") or instance:IsA("Model")
end

local function findContainer(parent: Instance, name: string): Instance?
	local child = parent:FindFirstChild(name)
	if child and isContainer(child) then
		return child
	end

	return nil
end

local function normalizeTeamName(value: string?): string?
	if value == nil then
		return nil
	end

	if value == "Attackers" or value == "Defenders" or value == "Spectators" or value == "Lobby" then
		return value
	end

	local lowered = string.lower(value)
	if string.find(lowered, "attack", 1, true) then
		return "Attackers"
	end

	if string.find(lowered, "defend", 1, true) then
		return "Defenders"
	end

	if string.find(lowered, "spect", 1, true) or string.find(lowered, "lobby", 1, true) then
		return "Spectators"
	end

	return nil
end

local function normalizeAnchorType(value: string?): string?
	if value == nil then
		return nil
	end

	if value == "Barricade" or value == "Camera" or value == "Mine" then
		return value
	end

	local lowered = string.lower(value)
	if string.find(lowered, "barric", 1, true) then
		return "Barricade"
	end

	if string.find(lowered, "camera", 1, true) then
		return "Camera"
	end

	if string.find(lowered, "mine", 1, true) then
		return "Mine"
	end

	return nil
end

local function collectDescendantParts(parent: Instance): { BasePart }
	local results = {}

	for _, descendant in ipairs(parent:GetDescendants()) do
		if descendant:IsA("BasePart") then
			table.insert(results, descendant)
		end
	end

	return results
end

local function countEntries(map): number
	local total = 0
	for _ in pairs(map) do
		total += 1
	end

	return total
end

function MapService.new(configSnapshotService)
	local snapshot = configSnapshotService:GetSnapshot()
	local self = {
		Name = "MapService",
		_config = snapshot.map,
		_activeModel = nil :: Instance?,
		_spawnParts = {} :: { [string]: SpawnLocation },
		_callouts = {} :: { [string]: BasePart },
		_routeMarkers = {} :: { Instance },
		_bombsiteRoots = {} :: { [string]: Instance },
		_plantZones = {} :: { [string]: { BasePart } },
		_anchorPoints = {} :: { BasePart },
		_source = "GeneratedConfig",
	}

	return setmetatable(self, MapService)
end

function MapService:_buildGeometry(parent: Instance)
	local geometryFolder = ensureFolder(parent, "Geometry")

	for _, block in ipairs(self._config.geometry) do
		local part = Instance.new("Part")
		part.Name = block.name
		part.Anchored = true
		part.CanCollide = block.canCollide
		part.Color = toColor3(block.color)
		part.Material = getMaterial(block.material)
		part.Position = toVector3(block.position)
		part.Size = toVector3(block.size)
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Transparency = block.transparency
		part:SetAttribute("GeometryId", block.id)
		part.Parent = geometryFolder
	end
end

function MapService:_buildSpawns(parent: Instance)
	local spawnFolder = ensureFolder(parent, "Spawns")
	self._spawnParts = {}

	for _, spawnDefinition in ipairs(self._config.spawns) do
		local spawnLocation = Instance.new("SpawnLocation")
		spawnLocation.Name = spawnDefinition.name
		spawnLocation.AllowTeamChangeOnTouch = false
		spawnLocation.Anchored = true
		spawnLocation.CanCollide = false
		spawnLocation.Neutral = true
		spawnLocation.Size = Vector3.new(8, 1, 8)
		spawnLocation.Transparency = 1
		spawnLocation.Position = toVector3(spawnDefinition.position)
		spawnLocation:SetAttribute("SpawnId", spawnDefinition.id)
		spawnLocation:SetAttribute("Team", spawnDefinition.team)
		spawnLocation.Parent = spawnFolder
		self._spawnParts[spawnDefinition.team] = spawnLocation
	end
end

function MapService:_buildCallouts(parent: Instance)
	local calloutFolder = ensureFolder(parent, "Callouts")

	for _, callout in ipairs(self._config.callouts) do
		local marker = Instance.new("Part")
		marker.Name = callout.name
		marker.Anchored = true
		marker.CanCollide = false
		marker.Shape = Enum.PartType.Ball
		marker.Size = Vector3.new(2, 2, 2)
		marker.Transparency = 1
		marker.Position = toVector3(callout.position)
		marker:SetAttribute("CalloutId", callout.id)
		marker.Parent = calloutFolder
	end
end

function MapService:_buildRoutes(parent: Instance)
	local routeFolder = ensureFolder(parent, "Routes")
	local calloutById = {}

	for _, callout in ipairs(self._config.callouts) do
		calloutById[callout.id] = callout
	end

	for _, route in ipairs(self._config.routes) do
		local fromCallout = calloutById[route.fromCalloutId]
		local toCallout = calloutById[route.toCalloutId]
		local midpoint = (toVector3(fromCallout.position) + toVector3(toCallout.position)) / 2

		local marker = Instance.new("Part")
		marker.Name = route.name
		marker.Anchored = true
		marker.CanCollide = false
		marker.Color = Color3.fromRGB(80, 180, 255)
		marker.Material = Enum.Material.Neon
		marker.Shape = Enum.PartType.Ball
		marker.Size = Vector3.new(3, 3, 3)
		marker.Transparency = 0.8
		marker.Position = midpoint
		marker:SetAttribute("RouteId", route.id)
		marker:SetAttribute("FromCalloutId", route.fromCalloutId)
		marker:SetAttribute("ToCalloutId", route.toCalloutId)
		marker:SetAttribute("SiteId", route.siteId)
		marker.Parent = routeFolder
	end
end

function MapService:_buildBombsites(parent: Instance)
	local bombsiteFolder = ensureFolder(parent, "Bombsites")

	for _, bombsite in ipairs(self._config.bombsites) do
		local siteFolder = ensureFolder(bombsiteFolder, bombsite.name)
		siteFolder:SetAttribute("BombsiteId", bombsite.id)
		siteFolder:SetAttribute("EntryRouteCount", #bombsite.entryRouteIds)

		for _, plantZone in ipairs(bombsite.plantZones) do
			local zone = Instance.new("Part")
			zone.Name = plantZone.name
			zone.Anchored = true
			zone.CanCollide = false
			zone.Color = Color3.fromRGB(235, 188, 52)
			zone.Material = Enum.Material.ForceField
			zone.Size = toVector3(plantZone.size)
			zone.Position = toVector3(plantZone.position)
			zone.Transparency = 0.75
			zone:SetAttribute("PlantZoneId", plantZone.id)
			zone:SetAttribute("BombsiteId", bombsite.id)
			zone.Parent = siteFolder
		end
	end
end

function MapService:_buildAnchorPoints(parent: Instance)
	local anchorFolder = ensureFolder(parent, "AnchorPoints")

	for _, anchorPoint in ipairs(self._config.anchorPoints) do
		local marker = Instance.new("Part")
		marker.Name = anchorPoint.name
		marker.Anchored = true
		marker.CanCollide = false
		marker.Material = Enum.Material.Neon
		marker.Size = Vector3.new(2.5, 2.5, 2.5)
		marker.Position = toVector3(anchorPoint.position)
		marker.Transparency = 0.25
		marker.Shape = if anchorPoint.anchorType == "Camera" then Enum.PartType.Ball else Enum.PartType.Block

		if anchorPoint.anchorType == "Barricade" then
			marker.Color = Color3.fromRGB(180, 180, 180)
		elseif anchorPoint.anchorType == "Camera" then
			marker.Color = Color3.fromRGB(80, 180, 255)
		else
			marker.Color = Color3.fromRGB(255, 110, 80)
		end

		marker:SetAttribute("AnchorPointId", anchorPoint.id)
		marker:SetAttribute("AnchorType", anchorPoint.anchorType)
		marker:SetAttribute("SiteId", anchorPoint.siteId)
		marker:SetAttribute("CalloutId", anchorPoint.calloutId)
		marker.Parent = anchorFolder
	end
end

function MapService:_findManualMapRoot(): Instance?
	for _, child in ipairs(Workspace:GetChildren()) do
		if isContainer(child) and child:GetAttribute(MANUAL_MAP_ATTRIBUTE) == true then
			return child
		end
	end

	return nil
end

function MapService:_indexMapRoot(root: Instance, source: string): (boolean, string?)
	local spawnsFolder = findContainer(root, "Spawns")
	if not spawnsFolder then
		return false, "Map root is missing a 'Spawns' folder"
	end

	local bombsitesFolder = findContainer(root, "Bombsites")
	if not bombsitesFolder then
		return false, "Map root is missing a 'Bombsites' folder"
	end

	self._spawnParts = {}
	self._callouts = {}
	self._routeMarkers = {}
	self._bombsiteRoots = {}
	self._plantZones = {}
	self._anchorPoints = {}
	self._activeModel = root
	self._source = source

	for _, descendant in ipairs(spawnsFolder:GetDescendants()) do
		if descendant:IsA("SpawnLocation") then
			local teamName = normalizeTeamName(descendant:GetAttribute("Team") or descendant.Name)
			if teamName then
				self._spawnParts[teamName] = descendant
			end
		end
	end

	if not self._spawnParts.Attackers or not self._spawnParts.Defenders or not self._spawnParts.Spectators then
		return false, "Manual map authoring requires SpawnLocations for Attackers, Defenders and Spectators"
	end

	local calloutsFolder = findContainer(root, "Callouts")
	if calloutsFolder then
		for _, part in ipairs(collectDescendantParts(calloutsFolder)) do
			local calloutId = part:GetAttribute("CalloutId") or part.Name
			if type(calloutId) == "string" and calloutId ~= "" then
				self._callouts[calloutId] = part
			end
		end
	end

	local routesFolder = findContainer(root, "Routes")
	if routesFolder then
		for _, descendant in ipairs(routesFolder:GetDescendants()) do
			if descendant ~= routesFolder then
				local routeId = descendant:GetAttribute("RouteId")
				if type(routeId) == "string" and routeId ~= "" then
					table.insert(self._routeMarkers, descendant)
				end
			end
		end
	end

	for _, child in ipairs(bombsitesFolder:GetChildren()) do
		if isContainer(child) or child:IsA("BasePart") then
			local bombsiteId = child:GetAttribute("BombsiteId") or child.Name
			if type(bombsiteId) == "string" and bombsiteId ~= "" then
				self._bombsiteRoots[bombsiteId] = child
				self._plantZones[bombsiteId] = {}

				for _, descendant in ipairs(child:GetDescendants()) do
					if descendant:IsA("BasePart") then
						local plantZoneId = descendant:GetAttribute("PlantZoneId")
						if type(plantZoneId) == "string" and plantZoneId ~= "" then
							table.insert(self._plantZones[bombsiteId], descendant)
						end
					end
				end

				if #self._plantZones[bombsiteId] == 0 then
					return false, string.format("Bombsite '%s' must define at least one plant zone", bombsiteId)
				end
			end
		end
	end

	if countEntries(self._bombsiteRoots) < 2 then
		return false, "Manual map authoring requires at least two bombsites under 'Bombsites'"
	end

	local anchorPointsFolder = findContainer(root, "AnchorPoints")
	if anchorPointsFolder then
		for _, part in ipairs(collectDescendantParts(anchorPointsFolder)) do
			local anchorType = normalizeAnchorType(part:GetAttribute("AnchorType") or part.Name)
			if anchorType then
				part:SetAttribute("AnchorType", anchorType)
				table.insert(self._anchorPoints, part)
			end
		end
	end

	return true, nil
end

function MapService:EnsureMapWorkspace()
	local manualRoot = self:_findManualMapRoot()
	if manualRoot then
		local success, errorMessage = self:_indexMapRoot(manualRoot, "StudioManual")
		if success then
			Logger.info("MapService", string.format("Using Studio-authored map root '%s'", manualRoot.Name))
			return manualRoot
		end

		Logger.warn("MapService", string.format("Manual map root '%s' is invalid: %s", manualRoot.Name, errorMessage or "unknown error"))
	end

	local mapModel = ensureModel(Workspace, self._config.workspaceModelName)
	mapModel:SetAttribute("MapId", self._config.id)
	mapModel:SetAttribute("MapName", self._config.name)
	mapModel:SetAttribute("Theme", self._config.theme)

	self:_buildGeometry(mapModel)
	self:_buildSpawns(mapModel)
	self:_buildCallouts(mapModel)
	self:_buildRoutes(mapModel)
	self:_buildBombsites(mapModel)
	self:_buildAnchorPoints(mapModel)

	local success, errorMessage = self:_indexMapRoot(mapModel, "GeneratedConfig")
	assert(success, errorMessage or "Generated map root failed to index")
	Logger.info("MapService", string.format("Using generated config map root '%s'", mapModel.Name))

	return mapModel
end

function MapService:GetConfig()
	return self._config
end

function MapService:GetMapRoot()
	return self._activeModel
end

function MapService:GetSpawnPart(teamName: string)
	return self._spawnParts[teamName]
end

function MapService:GetCalloutMarker(calloutId: string)
	return self._callouts[calloutId]
end

function MapService:GetRouteMarkers()
	return self._routeMarkers
end

function MapService:GetBombsiteRoot(bombsiteId: string)
	return self._bombsiteRoots[bombsiteId]
end

function MapService:GetPlantZones(bombsiteId: string?)
	if bombsiteId ~= nil then
		return self._plantZones[bombsiteId] or {}
	end

	local allPlantZones = {}
	for _, plantZones in pairs(self._plantZones) do
		for _, zone in ipairs(plantZones) do
			table.insert(allPlantZones, zone)
		end
	end

	return allPlantZones
end

function MapService:GetAnchorPoints(anchorType: string?)
	if anchorType == nil then
		return self._anchorPoints
	end

	local results = {}
	for _, anchorPoint in ipairs(self._anchorPoints) do
		if anchorPoint:GetAttribute("AnchorType") == anchorType then
			table.insert(results, anchorPoint)
		end
	end

	return results
end

function MapService:GetStateSnapshot()
	local activeModel = self._activeModel
	local geometryFolder = activeModel and findContainer(activeModel, "Geometry")

	return {
		mapId = if activeModel then (activeModel:GetAttribute("MapId") or self._config.id) else self._config.id,
		mapName = if activeModel then (activeModel:GetAttribute("MapName") or activeModel.Name) else self._config.name,
		theme = if activeModel then (activeModel:GetAttribute("Theme") or self._config.theme) else self._config.theme,
		workspaceModelName = if activeModel then activeModel.Name else self._config.workspaceModelName,
		mapSource = self._source,
		calloutCount = countEntries(self._callouts),
		routeCount = #self._routeMarkers,
		bombsiteCount = countEntries(self._bombsiteRoots),
		anchorPointCount = #self._anchorPoints,
		geometryCount = if geometryFolder then #collectDescendantParts(geometryFolder) else 0,
	}
end

return MapService
