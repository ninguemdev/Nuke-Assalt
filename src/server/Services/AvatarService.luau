--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Logger = require(ReplicatedStorage.Shared.Util.Logger)
local MovementMode = require(ReplicatedStorage.Shared.Enums.MovementMode)

type MovementPayload = {
	sprintRequested: boolean,
	crouchRequested: boolean,
}

type JointEntry = {
	motor: Motor6D,
	baseC0: CFrame,
}

type JointMap = {
	[string]: JointEntry,
}

type CachedDescriptionEntry = {
	description: HumanoidDescription,
	appearanceSource: string,
}

local JOINT_CANDIDATES = {
	RootJoint = true,
	Root = true,
	Waist = true,
	Neck = true,
	RightShoulder = true,
	LeftShoulder = true,
	RightHip = true,
	LeftHip = true,
	["Right Shoulder"] = true,
	["Left Shoulder"] = true,
	["Right Hip"] = true,
	["Left Hip"] = true,
}

local ACCESSORY_FIELDS = {
	"BackAccessory",
	"FaceAccessory",
	"FrontAccessory",
	"HairAccessory",
	"HatAccessory",
	"NeckAccessory",
	"ShouldersAccessory",
	"WaistAccessory",
}

local AvatarService = {}
AvatarService.__index = AvatarService

local function rad(degrees: number): number
	return math.rad(degrees)
end

local function colorFromConfig(colorValue): Color3
	return Color3.fromRGB(colorValue.r, colorValue.g, colorValue.b)
end

local function getExpectedRigEnum(expectedRigType: string): Enum.HumanoidRigType
	return if expectedRigType == "R15" then Enum.HumanoidRigType.R15 else Enum.HumanoidRigType.R6
end

function AvatarService.new(configSnapshotService, remoteRegistryService)
	local snapshot = configSnapshotService:GetSnapshot()
	local self = setmetatable({
		Name = "AvatarService",
		_config = snapshot.combat,
		_networkConfig = snapshot.network,
		_remoteRegistryService = remoteRegistryService,
		_boundPlayers = {} :: { [Player]: boolean },
		_jointMaps = {} :: { [Model]: JointMap },
		_loggedRigWarnings = {} :: { [Player]: boolean },
		_loggedAppearanceFallbacks = {} :: { [Player]: boolean },
		_descriptionCache = {} :: { [number]: CachedDescriptionEntry },
		_pendingAppearanceSources = {} :: { [Player]: string },
		_placeholderDescription = nil :: HumanoidDescription?,
	}, AvatarService)

	for _, player in ipairs(Players:GetPlayers()) do
		self:BindPlayerCharacter(player)
	end

	Players.PlayerAdded:Connect(function(player)
		self:BindPlayerCharacter(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self._boundPlayers[player] = nil
		self._loggedRigWarnings[player] = nil
		self._loggedAppearanceFallbacks[player] = nil
		self._pendingAppearanceSources[player] = nil
	end)

	return self
end

function AvatarService:_getRemoteEvent(name: string)
	local remoteRoot = self._remoteRegistryService:GetRemoteFolder()
	local eventsFolder = remoteRoot and remoteRoot:FindFirstChild(self._networkConfig.folders.events)
	if not eventsFolder then
		return nil
	end

	local remoteEvent = eventsFolder:FindFirstChild(name)
	if remoteEvent and remoteEvent:IsA("RemoteEvent") then
		return remoteEvent
	end

	return nil
end

function AvatarService:_captureJoints(character: Model): JointMap?
	local jointMap = {} :: JointMap

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Motor6D") and JOINT_CANDIDATES[descendant.Name] and jointMap[descendant.Name] == nil then
			jointMap[descendant.Name] = {
				motor = descendant,
				baseC0 = descendant.C0,
			}
		end
	end

	if next(jointMap) == nil then
		return nil
	end

	return jointMap
end

function AvatarService:_sanitizeCharacterAppearance(character: Model)
	if self._config.avatar.stripAccessories then
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Accessory") then
				child:Destroy()
			end
		end
	end

	if self._config.avatar.stripCharacterMeshes then
		for _, descendant in ipairs(character:GetDescendants()) do
			if descendant:IsA("CharacterMesh") then
				descendant:Destroy()
			end
		end
	end
end

function AvatarService:_applyStandardAnimationProfile(description: HumanoidDescription)
	description.IdleAnimation = self._config.animation.tracks.idle
	description.WalkAnimation = self._config.animation.tracks.walk
	description.RunAnimation = self._config.animation.tracks.run
	description.JumpAnimation = self._config.animation.tracks.jump
	description.FallAnimation = self._config.animation.tracks.fall
end

function AvatarService:_buildBaseDescription(): HumanoidDescription
	local description = Instance.new("HumanoidDescription")

	description.Head = 0
	description.Torso = 0
	description.LeftArm = 0
	description.RightArm = 0
	description.LeftLeg = 0
	description.RightLeg = 0

	description.HeightScale = 1
	description.WidthScale = 1
	description.DepthScale = 1
	description.HeadScale = 1
	description.BodyTypeScale = 0
	description.ProportionScale = 0

	for _, accessoryField in ipairs(ACCESSORY_FIELDS) do
		description[accessoryField] = ""
	end

	description.Face = 0
	description.Shirt = 0
	description.Pants = 0
	description.GraphicTShirt = 0

	self:_applyStandardAnimationProfile(description)
	return description
end

function AvatarService:_applyBodyColorsFromDescription(description: HumanoidDescription, sourceDescription: HumanoidDescription)
	description.HeadColor = sourceDescription.HeadColor
	description.TorsoColor = sourceDescription.TorsoColor
	description.LeftArmColor = sourceDescription.LeftArmColor
	description.RightArmColor = sourceDescription.RightArmColor
	description.LeftLegColor = sourceDescription.LeftLegColor
	description.RightLegColor = sourceDescription.RightLegColor
end

function AvatarService:_applyBodyColorsFromFallback(description: HumanoidDescription)
	local bodyColors = self._config.avatar.studioFallbackAppearance.bodyColors
	description.HeadColor = colorFromConfig(bodyColors.head)
	description.TorsoColor = colorFromConfig(bodyColors.torso)
	description.LeftArmColor = colorFromConfig(bodyColors.leftArm)
	description.RightArmColor = colorFromConfig(bodyColors.rightArm)
	description.LeftLegColor = colorFromConfig(bodyColors.leftLeg)
	description.RightLegColor = colorFromConfig(bodyColors.rightLeg)
end

function AvatarService:_applyAppearanceOverlay(description: HumanoidDescription, sourceDescription: HumanoidDescription)
	local preserveFields = {}
	for _, fieldName in ipairs(self._config.avatar.preserveAppearanceFields) do
		preserveFields[fieldName] = true
	end

	if preserveFields.bodyColors then
		self:_applyBodyColorsFromDescription(description, sourceDescription)
	end

	if preserveFields.face then
		description.Face = sourceDescription.Face
	end

	if preserveFields.shirt then
		description.Shirt = sourceDescription.Shirt
	end

	if preserveFields.pants then
		description.Pants = sourceDescription.Pants
	end

	if preserveFields.graphicTShirt then
		description.GraphicTShirt = sourceDescription.GraphicTShirt
	end
end

function AvatarService:_buildFallbackDescription(): HumanoidDescription
	if self._placeholderDescription then
		return self._placeholderDescription:Clone()
	end

	local fallbackAppearance = self._config.avatar.studioFallbackAppearance
	local description = self:_buildBaseDescription()

	self:_applyBodyColorsFromFallback(description)
	description.Face = fallbackAppearance.face
	description.Shirt = fallbackAppearance.shirt
	description.Pants = fallbackAppearance.pants
	description.GraphicTShirt = fallbackAppearance.graphicTShirt

	self._placeholderDescription = description:Clone()
	return description
end

function AvatarService:_buildStandardizedDescription(sourceDescription: HumanoidDescription): HumanoidDescription
	local description = self:_buildBaseDescription()
	self:_applyAppearanceOverlay(description, sourceDescription)
	return description
end

function AvatarService:_logAppearanceFallback(player: Player, reason: string)
	if self._loggedAppearanceFallbacks[player] then
		return
	end

	self._loggedAppearanceFallbacks[player] = true

	if RunService:IsStudio() or player.UserId <= 0 then
		Logger.info(
			"AvatarService",
			string.format(
				"Using %s avatar fallback for %s (%s)",
				self._config.avatar.studioFallbackAppearance.mode,
				player.Name,
				reason
			)
		)
	else
		Logger.warn(
			"AvatarService",
			string.format(
				"Using %s avatar fallback for %s (%s)",
				self._config.avatar.studioFallbackAppearance.mode,
				player.Name,
				reason
			)
		)
	end
end

function AvatarService:BuildSpawnDescription(player: Player)
	local cached = if player.UserId > 0 then self._descriptionCache[player.UserId] else nil
	if cached then
		return cached.description:Clone(), cached.appearanceSource
	end

	if player.UserId > 0 then
		local success, result = pcall(function()
			return Players:GetHumanoidDescriptionFromUserIdAsync(player.UserId)
		end)

		if success and result and result:IsA("HumanoidDescription") then
			local standardized = self:_buildStandardizedDescription(result)
			self._descriptionCache[player.UserId] = {
				description = standardized:Clone(),
				appearanceSource = "PlayerAppearance",
			}
			return standardized, "PlayerAppearance"
		end

		self:_logAppearanceFallback(player, "AvatarDescriptionUnavailable")
	else
		self:_logAppearanceFallback(player, "SyntheticStudioPlayer")
	end

	local placeholderDescription = self:_buildFallbackDescription()
	if player.UserId > 0 then
		self._descriptionCache[player.UserId] = {
			description = placeholderDescription:Clone(),
			appearanceSource = "StudioPlaceholder",
		}
	end

	return placeholderDescription, "StudioPlaceholder"
end

function AvatarService:_applyCrouchPose(character: Model, isCrouching: boolean)
	local jointMap = self._jointMaps[character]
	if not jointMap then
		jointMap = self:_captureJoints(character)
		if not jointMap then
			return
		end

		self._jointMaps[character] = jointMap
	end

	local pose = self._config.animation.crouchPose

	local function assign(name: string, targetC0: CFrame)
		local entry = jointMap[name]
		if entry then
			entry.motor.C0 = targetC0
		end
	end

	if not isCrouching then
		for _, entry in pairs(jointMap) do
			entry.motor.C0 = entry.baseC0
		end

		return
	end

	local rootJoint = jointMap.RootJoint or jointMap.Root
	if rootJoint then
		local rootName = if jointMap.RootJoint then "RootJoint" else "Root"
		assign(
			rootName,
			rootJoint.baseC0
				* CFrame.new(0, pose.torsoOffsetY, 0)
				* CFrame.Angles(rad(pose.rootPitchDegrees), 0, 0)
		)
	end

	local waist = jointMap.Waist
	if waist then
		assign("Waist", waist.baseC0 * CFrame.Angles(rad(pose.rootPitchDegrees * 0.45), 0, 0))
	end

	local neck = jointMap.Neck
	if neck then
		assign("Neck", neck.baseC0 * CFrame.Angles(rad(pose.neckPitchDegrees), 0, 0))
	end

	local rightShoulder = jointMap.RightShoulder or jointMap["Right Shoulder"]
	if rightShoulder then
		local rightShoulderName = if jointMap.RightShoulder then "RightShoulder" else "Right Shoulder"
		assign(rightShoulderName, rightShoulder.baseC0 * CFrame.Angles(0, 0, rad(-pose.shoulderRollDegrees)))
	end

	local leftShoulder = jointMap.LeftShoulder or jointMap["Left Shoulder"]
	if leftShoulder then
		local leftShoulderName = if jointMap.LeftShoulder then "LeftShoulder" else "Left Shoulder"
		assign(leftShoulderName, leftShoulder.baseC0 * CFrame.Angles(0, 0, rad(pose.shoulderRollDegrees)))
	end

	local rightHip = jointMap.RightHip or jointMap["Right Hip"]
	if rightHip then
		local rightHipName = if jointMap.RightHip then "RightHip" else "Right Hip"
		assign(rightHipName, rightHip.baseC0 * CFrame.Angles(rad(pose.hipPitchDegrees), 0, 0))
	end

	local leftHip = jointMap.LeftHip or jointMap["Left Hip"]
	if leftHip then
		local leftHipName = if jointMap.LeftHip then "LeftHip" else "Left Hip"
		assign(leftHipName, leftHip.baseC0 * CFrame.Angles(rad(pose.hipPitchDegrees), 0, 0))
	end
end

function AvatarService:_configureCharacter(player: Player, character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid")
	local expectedRigType = self._config.avatar.expectedRigType
	local expectedRigEnum = getExpectedRigEnum(expectedRigType)
	local appearanceSource = self._pendingAppearanceSources[player] or (character:GetAttribute("NukeAssaltAppearanceSource") :: string?) or "ExistingCharacter"

	self._pendingAppearanceSources[player] = nil

	character:SetAttribute("NukeAssaltExpectedRig", expectedRigType)
	character:SetAttribute("NukeAssaltAnimationProfile", self._config.animation.profileId)
	character:SetAttribute("NukeAssaltAppearanceSource", appearanceSource)
	character:SetAttribute("NukeAssaltCrouching", false)
	character:SetAttribute("NukeAssaltSprinting", false)
	character:SetAttribute("NukeAssaltMovementMode", MovementMode.Walk)
	humanoid.UseJumpPower = true
	humanoid.WalkSpeed = self._config.movement.walkSpeed
	humanoid.JumpPower = self._config.movement.jumpPower

	if humanoid.RigType ~= expectedRigEnum and not self._loggedRigWarnings[player] then
		self._loggedRigWarnings[player] = true
		Logger.warn(
			"AvatarService",
			string.format(
				"Player '%s' spawned as %s instead of %s; verify StarterPlayer.GameSettingsAvatar in Studio",
				player.Name,
				tostring(humanoid.RigType),
				expectedRigType
			)
		)
	end

	self._jointMaps[character] = self:_captureJoints(character) or {}
	self:_sanitizeCharacterAppearance(character)
	self:_applyCrouchPose(character, false)
end

function AvatarService:GetAvatarConfig()
	return self._config.avatar
end

function AvatarService:GetAnimationConfig()
	return self._config.animation
end

function AvatarService:LoadStandardCharacter(player: Player)
	local description, appearanceSource = self:BuildSpawnDescription(player)
	self._pendingAppearanceSources[player] = appearanceSource
	player:LoadCharacterWithHumanoidDescriptionAsync(description)
	return player.Character or player.CharacterAdded:Wait()
end

function AvatarService:UpdateMovementState(player: Player, sprintRequested: boolean, crouchRequested: boolean)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid or humanoid.Health <= 0 then
		return {
			success = false,
			reason = "NoHumanoid",
		}
	end

	local shouldCrouch = crouchRequested
	local shouldSprint = sprintRequested and not shouldCrouch
	local walkSpeed = self._config.movement.walkSpeed
	local movementMode = MovementMode.Walk

	if shouldCrouch then
		walkSpeed = self._config.movement.crouchSpeed
		movementMode = MovementMode.Crouch
	elseif shouldSprint then
		walkSpeed = self._config.movement.sprintSpeed
		movementMode = MovementMode.Sprint
	end

	humanoid.WalkSpeed = walkSpeed
	humanoid.JumpPower = self._config.movement.jumpPower
	character:SetAttribute("NukeAssaltCrouching", shouldCrouch)
	character:SetAttribute("NukeAssaltSprinting", shouldSprint)
	character:SetAttribute("NukeAssaltMovementMode", movementMode)
	self:_applyCrouchPose(character, shouldCrouch)

	return {
		success = true,
		movementMode = movementMode,
		walkSpeed = walkSpeed,
	}
end

function AvatarService:BindPlayerCharacter(player: Player)
	if self._boundPlayers[player] then
		return
	end

	self._boundPlayers[player] = true

	player.CharacterAdded:Connect(function(character)
		self:_configureCharacter(player, character)
	end)

	player.CharacterAppearanceLoaded:Connect(function(character)
		self:_sanitizeCharacterAppearance(character)
	end)

	if player.Character then
		self:_configureCharacter(player, player.Character)
	end
end

function AvatarService:BindMovementRemote()
	local movementStateChanged = self:_getRemoteEvent("MovementStateChanged")
	if not movementStateChanged then
		return
	end

	movementStateChanged.OnServerEvent:Connect(function(player, payload: MovementPayload?)
		if type(payload) ~= "table" then
			return
		end

		local sprintRequested = payload.sprintRequested == true
		local crouchRequested = payload.crouchRequested == true
		self:UpdateMovementState(player, sprintRequested, crouchRequested)
	end)

	Logger.info(
		"AvatarService",
		string.format(
			"Avatar profile enforced: rig=%s accessoriesStripped=%s animationProfile=%s",
			self._config.avatar.expectedRigType,
			tostring(self._config.avatar.stripAccessories),
			self._config.animation.profileId
		)
	)
end

return AvatarService
