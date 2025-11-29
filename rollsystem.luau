-- The code below was made by BlackTide Studios

-- This is a fly systeme for admins on my One Piece game

-- I explained the majority of the script

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local KeyCode = Enum.KeyCode.Space -- Key used to toggle flying
local WindSoundEnabled = true -- Enables/Disables wind SFX

local player = Players.LocalPlayer
local Character = player.Character or player.CharacterAdded:Wait()
local Humanoid = Character:FindFirstChild("Humanoid") or Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Camera = workspace.Camera

-- Clone forces used for flying
local BodyVelocity = script:WaitForChild("BodyVelocity"):Clone()
local BodyGyro = script:WaitForChild("BodyGyro"):Clone()
BodyVelocity.Parent = Character
BodyGyro.Parent = Character

-- Idle and flying animations
local Hover = script.Idle
local Fly = script.Idle

local v10 = Humanoid.Animator:LoadAnimation(Hover)
local v11 = Humanoid.Animator:LoadAnimation(Fly)

-- Wind sound played while flying/moving
local Sound1 = Instance.new("Sound", HumanoidRootPart)
Sound1.SoundId = "rbxassetid://3308152153"
Sound1.Name = "Sound1"
if WindSoundEnabled == false then
	Sound1.Volume = 0
end

local Flymoving = script:WaitForChild("Flymoving")
local boost = false -- Shift boost active
local Flying = false -- Flying state
local lastTime = tick() -- Used for double-tap detection
local deb = false
local cdb = false -- Cooldown for boost

-- Directional animations
local ranim = Humanoid:LoadAnimation(script.Right)
local lanim = Humanoid:LoadAnimation(script.Left)
local wanim = Humanoid:LoadAnimation(script.Front)
local aanim = Humanoid:LoadAnimation(script.Back)
local forwardLeft = Humanoid:LoadAnimation(script:WaitForChild("ForwardLeft"))
local forwardRight = Humanoid:LoadAnimation(script:WaitForChild("ForwardRight"))
local backLeft = Humanoid:LoadAnimation(script:WaitForChild("BackLeft"))
local backRight = Humanoid:LoadAnimation(script:WaitForChild("BackRight"))

-- Boost animations
local bst = Humanoid:LoadAnimation(script.BOOST)
local bstStart = Humanoid:LoadAnimation(script.BOOSTStart)

-- Converts movement direction relative to camera
local function getMoveVector()
	if Humanoid.MoveDirection == Vector3.new(0, 0, 0) then
		return Humanoid.MoveDirection
	end
	local flatLook = Vector3.new(Camera.CFrame.lookVector.x, 0, Camera.CFrame.lookVector.z)
	local transformed = (Camera.CFrame * CFrame.new((CFrame.new(Camera.CFrame.p, Camera.CFrame.p + flatLook):VectorToObjectSpace(Humanoid.MoveDirection)))).p - Camera.CFrame.p
	if transformed == Vector3.new() then
		return transformed
	end
	return transformed.Unit
end

-- Stops all directional flying animations
local function stopAllDirectionAnims()
	ranim:Stop()
	lanim:Stop()
	wanim:Stop()
	aanim:Stop()
	forwardLeft:Stop()
	forwardRight:Stop()
	backLeft:Stop()
	backRight:Stop()
end

-- Plays correct flying directional animation based on WASD
local function playDirectionalAnim()
	if not Flying then return end

	local w = UIS:IsKeyDown(Enum.KeyCode.W)
	local a = UIS:IsKeyDown(Enum.KeyCode.A)
	local s = UIS:IsKeyDown(Enum.KeyCode.S)
	local d = UIS:IsKeyDown(Enum.KeyCode.D)

	stopAllDirectionAnims()

	if w and a then
		forwardLeft:Play()
	elseif w and d then
		forwardRight:Play()
	elseif s and a then
		backLeft:Play()
	elseif s and d then
		backRight:Play()
	elseif w then
		wanim:Play()
	elseif s then
		aanim:Play()
	elseif d then
		ranim:Play()
	elseif a then
		lanim:Play()
	end

	v10:Stop()
	v11:Stop()
end

-- MAIN flying update loop
RunService.RenderStepped:Connect(function()
	if script.Parent ~= Character then return end

	if Flying then
		Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		BodyGyro.CFrame = Camera.CFrame -- Always face camera direction

		-- Detect if player is moving
		if getMoveVector() == Vector3.new(0, 0, 0) then
			Flymoving.Value = false
		else
			Flymoving.Value = true
		end

		-- Velocity changes based on boost
		local targetVel = getMoveVector() * (boost and 250 or 49)
		TweenService:Create(BodyVelocity, TweenInfo.new(0.3), {Velocity = targetVel}):Play()
	end
end)

-- Animation + camera FOV changes when flying/moving
Flymoving.Changed:Connect(function(p1)
	if p1 == true then
		-- Moving
		if boost then
			TweenService:Create(Camera, TweenInfo.new(0.5), {FieldOfView = 200}):Play()
		else
			TweenService:Create(Camera, TweenInfo.new(0.5), {FieldOfView = 100}):Play()
		end
		v10:Stop()
		Sound1:Play()
		return
	end

	-- Not moving
	if p1 == false then
		if boost then
			TweenService:Create(Camera, TweenInfo.new(0.5), {FieldOfView = 130}):Play()
		else
			TweenService:Create(Camera, TweenInfo.new(0.5), {FieldOfView = 70}):Play()
		end
		v11:Stop()
		Sound1:Stop()
		v10:Play()
	end
end)

-- FLY TOGGLE (double-space)
UIS.InputBegan:Connect(function(input, gameProcessed)
	if Flying then
		playDirectionalAnim()
	end
	if gameProcessed then return end
	if input.KeyCode ~= KeyCode then return end

	if deb then return end

	local now = tick()
	local difference = now - lastTime
	lastTime = tick()

	-- Double-tap space
	if difference <= 0.5 then
		deb = true
		task.wait(1)
		deb = false

		-- Start flying
		if not Flying then
			stopAllDirectionAnims()
			v10:Stop()
			v11:Stop()

			-- Small upward impulse before flying
			local BodyVelocity2 = Instance.new("BodyVelocity")
			BodyVelocity2.MaxForce = Vector3.new(0, 1e8, 0)
			BodyVelocity2.Velocity = HumanoidRootPart.CFrame.UpVector * 55
			BodyVelocity2.Parent = HumanoidRootPart
			game.Debris:AddItem(BodyVelocity2, 0.2)

			task.delay(0.3, function()
				Flying = true
			end)

			task.wait(0.33)

			-- Enable flying physics
			v10:Play(0.1, 1, 1)
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)

			if HumanoidRootPart:FindFirstChild("Running") then
				HumanoidRootPart.Running.Volume = 0
			end

			Humanoid:ChangeState(6)
			BodyVelocity.Parent = HumanoidRootPart
			BodyGyro.Parent = HumanoidRootPart

		-- Stop flying
		else
			stopAllDirectionAnims()
			v10:Stop()
			v11:Stop()

			Flying = false
			Flymoving.Value = false

			-- Re-enable humanoid states
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)

			if HumanoidRootPart:FindFirstChild("Running") then
				HumanoidRootPart.Running.Volume = 0.65
			end

			Humanoid:ChangeState(8)
			BodyVelocity.Parent = Character
			BodyGyro.Parent = Character
		end
	end
end)

-- BOOST (LeftShift)
local vfx
UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if not Flying then return end
	if Humanoid.MoveDirection.Magnitude == 0 then return end
	if input.KeyCode == Enum.KeyCode.LeftShift and not cdb then
		
		bst:Play()
		bstStart:Play()
		boost = true
		script.Boost:Play()

		-- Spawn boost VFX
		vfx = game.ReplicatedStorage.Assets.Flight:Clone()
		vfx.Parent = HumanoidRootPart
		vfx.CFrame = HumanoidRootPart.CFrame

		local m6d = Instance.new("Motor6D")
		m6d.Part0 = HumanoidRootPart
		m6d.Part1 = vfx
		m6d.Parent = vfx

		-- Enable particles after delay
		task.delay(.3,function()
			for _,v in vfx:GetDescendants() do
				if v:IsA("ParticleEmitter") then
					v.Enabled = true
				end
			end
		end)
	end
end)

-- BOOST END
UIS.InputEnded:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		bst:Stop()
		cdb = true -- Boost cooldown

		task.delay(1.5, function()
			cdb = false
		end)

		-- Disable VFX
		task.delay(.3,function()
			for _,v in vfx:GetDescendants() do
				if v:IsA("ParticleEmitter") then
					v.Enabled = false
				end
			end
		end)

		game.Debris:AddItem(vfx,1)
		boost = false
	end
end)

-- DASH SYSTEM (Double-tap W)
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RE = RS:WaitForChild("DashRequest")

local player = Players.LocalPlayer
local function char()
	return player.Character or player.CharacterAdded:Wait()
end

local lastW = 0
local window = 0.4 -- Max time between W taps

UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode ~= Enum.KeyCode.W then return end

	local now = time()

	-- Double-tap detection
	if now - lastW <= window then
		local c = char()
		local hrp = c:WaitForChild("HumanoidRootPart")
		local origin = hrp.Position
		local look = hrp.CFrame.LookVector
		local dir = Vector3.new(look.X, 0, look.Z).Unit

		if dir.Magnitude == 0 then return end

		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {c}

		local distance = 40
		local result = workspace:Raycast(origin, dir * distance, params)

		-- Only dash if nothing blocks the path
		if not result then
			RE:FireServer()
		end
	end

	lastW = now
end)
