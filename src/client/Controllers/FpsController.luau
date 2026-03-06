--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Logger = require(ReplicatedStorage.Shared.Util.Logger)

type ActiveCharacterState = {
	character: Model,
	humanoid: Humanoid,
	bodyParts: { BasePart },
}

local FpsController = {}

local started = false

local function isVisibleArm(part: BasePart): boolean
	return part.Name == "LeftUpperArm"
		or part.Name == "LeftLowerArm"
		or part.Name == "LeftHand"
		or part.Name == "RightUpperArm"
		or part.Name == "RightLowerArm"
		or part.Name == "RightHand"
		or part.Name == "Left Arm"
		or part.Name == "Right Arm"
end

function FpsController.Start()
	if started then
		return
	end

	started = true

	local player = Players.LocalPlayer
	local combatConfig = Config.GetCombatConfig()
	local networkConfig = Config.GetNetworkConfig()
	local sprintHeld = false
	local crouchHeld = false
	local activeState = nil :: ActiveCharacterState?
	local movementRemote = nil :: RemoteEvent?

	local remoteRoot = ReplicatedStorage:WaitForChild(networkConfig.remoteRootName)
	local eventsFolder = remoteRoot:WaitForChild(networkConfig.folders.events)
	local movementStateChanged = eventsFolder:WaitForChild("MovementStateChanged")
	if movementStateChanged:IsA("RemoteEvent") then
		movementRemote = movementStateChanged
	end

	local function publishMovementState()
		if movementRemote then
			movementRemote:FireServer({
				sprintRequested = sprintHeld and not crouchHeld,
				crouchRequested = crouchHeld,
			})
		end
	end

	local function applyCameraSettings()
		player.CameraMode = Enum.CameraMode.LockFirstPerson
		player.CameraMinZoomDistance = combatConfig.movement.firstPersonMinZoom
		player.CameraMaxZoomDistance = combatConfig.movement.firstPersonMaxZoom
	end

	local function applyBodyVisibility()
		if not activeState then
			return
		end

		for _, part in ipairs(activeState.bodyParts) do
			if combatConfig.avatar.showOnlyArmsInFirstPerson then
				part.LocalTransparencyModifier = if isVisibleArm(part) then 0 else 1
			elseif combatConfig.avatar.showLocalBodyInFirstPerson then
				part.LocalTransparencyModifier = if combatConfig.avatar.hideHeadInFirstPerson and part.Name == "Head" then 1 else 0
			else
				part.LocalTransparencyModifier = 1
			end
		end
	end

	local function applyMovementSettings()
		if not activeState or activeState.humanoid.Health <= 0 then
			return
		end

		local targetSpeed = combatConfig.movement.walkSpeed
		if crouchHeld then
			targetSpeed = combatConfig.movement.crouchSpeed
		elseif sprintHeld and activeState.humanoid.MoveDirection.Magnitude > 0.05 then
			targetSpeed = combatConfig.movement.sprintSpeed
		end

		activeState.humanoid.UseJumpPower = true
		activeState.humanoid.WalkSpeed = targetSpeed
		activeState.humanoid.JumpPower = combatConfig.movement.jumpPower
		activeState.humanoid.CameraOffset = Vector3.new(0, if crouchHeld then combatConfig.movement.crouchCameraOffsetY else 0, 0)
	end

	local function bindCharacter(character: Model)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid

		local bodyParts = {}
		for _, descendant in ipairs(character:GetDescendants()) do
			if descendant:IsA("BasePart") then
				table.insert(bodyParts, descendant)
			end
		end

		activeState = {
			character = character,
			humanoid = humanoid,
			bodyParts = bodyParts,
		}

		sprintHeld = false
		crouchHeld = false
		applyCameraSettings()
		applyBodyVisibility()
		publishMovementState()
		applyMovementSettings()
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end

		if input.KeyCode == Enum.KeyCode.LeftShift then
			sprintHeld = true
		elseif input.KeyCode == Enum.KeyCode.LeftControl then
			crouchHeld = true
		else
			return
		end

		publishMovementState()
		applyMovementSettings()
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftShift then
			sprintHeld = false
		elseif input.KeyCode == Enum.KeyCode.LeftControl then
			crouchHeld = false
		else
			return
		end

		publishMovementState()
		applyMovementSettings()
	end)

	RunService.RenderStepped:Connect(function()
		applyCameraSettings()
		applyBodyVisibility()
		applyMovementSettings()
	end)

	player.CharacterAdded:Connect(bindCharacter)
	if player.Character then
		bindCharacter(player.Character)
	end

	Logger.info(
		"FpsController",
		string.format(
			"FPS controller active: walk=%.1f sprint=%.1f crouch=%.1f jump=%.1f",
			combatConfig.movement.walkSpeed,
			combatConfig.movement.sprintSpeed,
			combatConfig.movement.crouchSpeed,
			combatConfig.movement.jumpPower
		)
	)
	Logger.info(
		"FpsController",
		string.format(
			"Avatar standardization active: rig=%s armsOnly=%s animation=%s",
			combatConfig.avatar.expectedRigType,
			tostring(combatConfig.avatar.showOnlyArmsInFirstPerson),
			combatConfig.animation.profileId
		)
	)
end

return table.freeze(FpsController)
