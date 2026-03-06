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

type CachedDescriptionEntry = {
	description: HumanoidDescription,
	appearanceSource: string,
}

type AnimationState = {
	animator: Animator,
	crouchAnimation: Animation,
	crouchTrack: AnimationTrack?,
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

local APPEARANCE_RETRY_COOLDOWN_SECONDS = 15

local AvatarService = {}
AvatarService.__index = AvatarService

local function colorFromConfig(colorValue): Color3
	return Color3.fromRGB(colorValue.r, colorValue.g, colorValue.b)
end

local function getExpectedRigEnum(expectedRigType: string): Enum.HumanoidRigType
	return if expectedRigType == "R15" then Enum.HumanoidRigType.R15 else Enum.HumanoidRigType.R6
end

local function toAssetUri(assetId: number): string
	return string.format("rbxassetid://%d", assetId)
end

local function isSyntheticStudioPlayer(player: Player): boolean
	if not RunService:IsStudio() then
		return false
	end

	if player.UserId <= 0 then
		return true
	end

	return string.match(player.Name, "^Player%d+$") ~= nil
end

local function ensureChildOfClass(parent: Instance, className: string, name: string): Instance
	local existing = parent:FindFirstChild(name)
	if existing and existing.ClassName == className then
		return existing
	end

	if existing then
		existing:Destroy()
	end

	local child = Instance.new(className)
	child.Name = name
	child.Parent = parent
	return child
end

function AvatarService.new(configSnapshotService, remoteRegistryService)
	local snapshot = configSnapshotService:GetSnapshot()
	local self = setmetatable({
		Name = "AvatarService",
		_config = snapshot.combat,
		_networkConfig = snapshot.network,
		_remoteRegistryService = remoteRegistryService,
		_boundPlayers = {} :: { [Player]: boolean },
		_loggedRigWarnings = {} :: { [Player]: boolean },
		_loggedAppearanceFallbacks = {} :: { [Player]: boolean },
		_descriptionCache = {} :: { [number]: CachedDescriptionEntry },
		_retryCooldowns = {} :: { [number]: number },
		_pendingAppearanceSources = {} :: { [Player]: string },
		_animationStates = {} :: { [Model]: AnimationState },
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

		if player.UserId > 0 then
			self._retryCooldowns[player.UserId] = nil
			self._descriptionCache[player.UserId] = nil
		end
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

function AvatarService:_sanitizeCharacterAppearance(character: Model)
	if not self._config.avatar.stripAccessories then
		return
	end

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Accessory") then
			child:Destroy()
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

	local message = string.format(
		"Using %s avatar fallback for %s (%s)",
		self._config.avatar.studioFallbackAppearance.mode,
		player.Name,
		reason
	)

	if RunService:IsStudio() or player.UserId <= 0 then
		Logger.info("AvatarService", message)
	else
		Logger.warn("AvatarService", message)
	end
end

function AvatarService:BuildSpawnDescription(player: Player)
	if isSyntheticStudioPlayer(player) then
		self:_logAppearanceFallback(player, "SyntheticStudioPlayer")
		return self:_buildFallbackDescription(), "StudioPlaceholder"
	end

	local cached = self._descriptionCache[player.UserId]
	if cached then
		return cached.description:Clone(), cached.appearanceSource
	end

	local retryAt = self._retryCooldowns[player.UserId]
	if retryAt and retryAt > time() then
		self:_logAppearanceFallback(player, "AvatarDescriptionCooldown")
		return self:_buildFallbackDescription(), "StudioPlaceholder"
	end

	local success, result = pcall(function()
		return Players:GetHumanoidDescriptionFromUserIdAsync(player.UserId)
	end)

	if success and result and result:IsA("HumanoidDescription") then
		local standardized = self:_buildStandardizedDescription(result)
		self._descriptionCache[player.UserId] = {
			description = standardized:Clone(),
			appearanceSource = "PlayerAppearance",
		}
		self._retryCooldowns[player.UserId] = nil
		self._loggedAppearanceFallbacks[player] = nil
		return standardized, "PlayerAppearance"
	end

	self._retryCooldowns[player.UserId] = time() + APPEARANCE_RETRY_COOLDOWN_SECONDS
	self:_logAppearanceFallback(player, "AvatarDescriptionUnavailable")
	return self:_buildFallbackDescription(), "StudioPlaceholder"
end

function AvatarService:_destroyAnimationState(character: Model)
	local animationState = self._animationStates[character]
	if not animationState then
		return
	end

	if animationState.crouchTrack then
		pcall(function()
			animationState.crouchTrack:Stop(0)
			animationState.crouchTrack:Destroy()
		end)
	end

	if animationState.crouchAnimation.Parent then
		animationState.crouchAnimation:Destroy()
	end

	self._animationStates[character] = nil
end

function AvatarService:_ensureAnimationState(character: Model, humanoid: Humanoid): AnimationState
	local existing = self._animationStates[character]
	if existing then
		return existing
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local crouchAnimation = Instance.new("Animation")
	crouchAnimation.Name = "NukeAssaltCrouch"
	crouchAnimation.AnimationId = toAssetUri(self._config.animation.tracks.crouch)
	crouchAnimation.Parent = animator

	local crouchTrack = nil :: AnimationTrack?
	local loaded, trackOrError = pcall(function()
		return animator:LoadAnimation(crouchAnimation)
	end)

	if loaded and trackOrError then
		crouchTrack = trackOrError :: AnimationTrack
		crouchTrack.Priority = Enum.AnimationPriority.Movement
		crouchTrack.Looped = true
	else
		Logger.warn(
			"AvatarService",
			string.format("Failed to load crouch animation track '%s'", tostring(trackOrError))
		)
	end

	local animationState = {
		animator = animator,
		crouchAnimation = crouchAnimation,
		crouchTrack = crouchTrack,
	}

	self._animationStates[character] = animationState

	character.Destroying:Connect(function()
		self:_destroyAnimationState(character)
	end)

	return animationState
end

function AvatarService:_setCrouchAnimationState(character: Model, isCrouching: boolean)
	local animationState = self._animationStates[character]
	if not animationState or not animationState.crouchTrack then
		return
	end

	local crouchTrack = animationState.crouchTrack
	if isCrouching then
		if not crouchTrack.IsPlaying then
			crouchTrack:Play(self._config.animation.blendTimeSeconds)
		end

		crouchTrack:AdjustSpeed(self._config.animation.crouchTrackSpeed)
	else
		if crouchTrack.IsPlaying then
			crouchTrack:Stop(self._config.animation.blendTimeSeconds)
		end
	end
end

function AvatarService:_applyStudioPlaceholderVisuals(character: Model)
	local fallbackAppearance = self._config.avatar.studioFallbackAppearance
	local shirt = ensureChildOfClass(character, "Shirt", "PlaceholderShirt") :: Shirt
	local pants = ensureChildOfClass(character, "Pants", "PlaceholderPants") :: Pants

	shirt.ShirtTemplate = toAssetUri(fallbackAppearance.shirt)
	pants.PantsTemplate = toAssetUri(fallbackAppearance.pants)

	local graphicTShirt = character:FindFirstChild("PlaceholderGraphic")
	if fallbackAppearance.graphicTShirt > 0 then
		local graphic = if graphicTShirt and graphicTShirt:IsA("ShirtGraphic")
			then (graphicTShirt :: ShirtGraphic)
			else (ensureChildOfClass(character, "ShirtGraphic", "PlaceholderGraphic") :: ShirtGraphic)
		graphic.Graphic = toAssetUri(fallbackAppearance.graphicTShirt)
	elseif graphicTShirt then
		graphicTShirt:Destroy()
	end

	local head = character:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		for _, child in ipairs(head:GetChildren()) do
			if child:IsA("Decal") and (child.Name == "PlaceholderFace" or child.Face == Enum.NormalId.Front) then
				child:Destroy()
			end
		end

		local face = Instance.new("Decal")
		face.Name = "PlaceholderFace"
		face.Face = Enum.NormalId.Front
		face.Texture = toAssetUri(fallbackAppearance.face)
		face.Parent = head
	end
end

function AvatarService:_configureCharacter(player: Player, character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid")
	local expectedRigType = self._config.avatar.expectedRigType
	local expectedRigEnum = getExpectedRigEnum(expectedRigType)
	local appearanceSource = self._pendingAppearanceSources[player] or (character:GetAttribute("NukeAssaltAppearanceSource") :: string?) or "ExistingCharacter"

	self._pendingAppearanceSources[player] = nil
	self:_destroyAnimationState(character)

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

	self:_sanitizeCharacterAppearance(character)
	self:_ensureAnimationState(character, humanoid)
	self:_setCrouchAnimationState(character, false)

	if appearanceSource == "StudioPlaceholder" then
		self:_applyStudioPlaceholderVisuals(character)
	end
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
	self:_setCrouchAnimationState(character, shouldCrouch)

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
		if character:GetAttribute("NukeAssaltAppearanceSource") == "StudioPlaceholder" then
			self:_applyStudioPlaceholderVisuals(character)
		end
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
