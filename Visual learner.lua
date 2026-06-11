if getgenv().QuantumHUD_Running then
	pcall(function()
		game:GetService("RunService"):UnbindFromRenderStep("Quantum_Stationary_Engine")
		local legacyStorage = game:GetService("Workspace"):FindFirstChild("QUANTUM_STATIONARY_STORAGE")
		if legacyStorage then legacyStorage:Destroy() end
		local legacyUI = game:GetService("CoreGui"):FindFirstChild("QuantumPersonalHub") or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("QuantumPersonalHub")
		if legacyUI then legacyUI:Destroy() end
		if game:GetService("Workspace"):FindFirstChild("Quantum_PESnowLayer") then game:GetService("Workspace").Quantum_PESnowLayer:Destroy() end
	end)
end
getgenv().QuantumHUD_Running = true
getgenv().PESnow_Enabled = false 

getgenv().LaunchQuantumGraphicsPipeline = function(customConfig)
	customConfig = customConfig or {}
	
	local QuantumHUD = {}
	QuantumHUD.__index = QuantumHUD
	local Players = game:GetService("Players")
	local Workspace = game:GetService("Workspace")
	local RunService = game:GetService("RunService")
	local Lighting = game:GetService("Lighting") 
	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
	local CoreGui = game:GetService("CoreGui")
	local Debris = game:GetService("Debris")

	function QuantumHUD.new()
		local self = setmetatable({}, QuantumHUD)
		self.Locale = {
			PanelTitle = "BaroliMonth1.2",             
			IslandTitle = "⚡ Baroli Month",               
			TabOverview = "主页",                 
			TabSettings = "视觉",                
			TabWeather = "环境",                  
			
			CardCoreTitle = "CORE RESOLVER",              
			CardTargetTitle = "IDENTITY CLEARENCE",        
			CardNetworkTitle = "TELEMETRY CONSOLE",       
			CardSwitchTitle = "FEATURE INTERFACE PREFERENCE", 
			CardWeatherTitle = "ENVIRONMENTAL WEATHER CONSOLE", 
			
			LocalStatusPrefix = "💖 状态: ",               
			CoordPrefix = "坐标: X:%.1f / Y:%.1f / Z:%.1f", 
			ToolUnarmed = "[ UNARMED ]",                  
			LoveMessage = "🌸如果没人爱着你，还有开发者爱着你(=^▽^=)", 
			
			Switch3D = "3D HUD",
			SwitchHighlight = "身体高亮轮毂线",
			SwitchBlur = "允许面板背景模糊",
			SwitchGhost = "残影",
			
			SwitchPESnow = "环境粒子特效",
			
			LogSuccess = ">> [OK] Matrix clean setup complete.\n>> [FIXED] 15m proximity filter implemented seamlessly.\n>> [VISUAL] Click counter pipeline fully operational."
		}
		self.Config = {
			StorageName = "QUANTUM_STATIONARY_STORAGE",
			
			BodyReflectance = customConfig.BodyReflectance or 0.15,   
			HeadReflectance = customConfig.HeadReflectance or 0.01,   
			LightBrightness = customConfig.LightBrightness or 0.45,   
			LightRange = customConfig.LightRange or 11.0,             
			OutlineTransparency = customConfig.OutlineTransparency or 0.05, 
			
			PinkGlassBg = Color3.fromRGB(255, 230, 238),      
			PinkGlassStroke = Color3.fromRGB(255, 230, 238), 
			MyCardBg = Color3.fromRGB(45, 15, 22),             
			MyCardStroke = Color3.fromRGB(45, 15, 22),       
			
			HealthBarProgressColor = Color3.fromRGB(255, 120, 160), 
			HealthBarContainerColor = Color3.fromRGB(255, 255, 255), 
			
			TextHDMain = Color3.fromRGB(255, 255, 255),        
			TextHDSub = Color3.fromRGB(255, 190, 210),         
			ShadowColor = Color3.fromRGB(20, 5, 10),           
			
			CardSize = Vector3.new(4.6, 1.75, 0.05),            
			ShoulderHeight = 1.6,                             
			EyeSeparation = 4.3,                               
			ViewAngleThreshold = 0.12,
			
			BaseStiffness = 18.5,     
			FluidDragCoeff = 0.25,    
			ParallaxIntensity = 0.35, 
			MicroVibeFreq = 8.5,
			
			GhostDuration = 0.45,       
			GhostColor = Color3.fromRGB(255, 255, 255), 
			BodyTransparency = 0.35,    
			MinMoveDistance = 1.4,     
			GhostScale = 0.9,            
			GhostBackwardOffset = 0.35,  
			TpWalkSpeed = 5, 
			
			WindowSize = UDim2.new(0, 480, 0, 280),      
			IslandSize = UDim2.new(0, 150, 0, 30),
			BgColor = Color3.fromRGB(255, 255, 255),    
			BgTransparency = 0.15,          
			CardColor = Color3.fromRGB(255, 255, 255),   
			CardTransparency = 0.7,                     
			StrokeColor = Color3.fromRGB(255, 255, 255), 
			ActiveColor = Color3.fromRGB(25, 25, 30),    
			TextMain = Color3.fromRGB(30, 30, 35),       
			TextSub = Color3.fromRGB(115, 120, 130),     
			AccentColor = Color3.fromRGB(0, 122, 255),   
			DevUsername = "NayuemiA",
			LinearSmooth = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			ButtonBounce = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		}

		self.LocalPlayer = Players.LocalPlayer
		self.IsRunning = false
		self.StorageFolder = nil
		
		self.MyFluidState = { Position = Vector3.new(), Velocity = Vector3.new(), Rotation = Vector3.new() }
		self.TargetFluidState = { Position = Vector3.new(), Velocity = Vector3.new(), Rotation = Vector3.new() }
		self.GlobalCurrentAlpha = 1.0       
		
		self.CurrentTarget = nil         
		self.IsPressing = false          
		self.ActiveFeedbackHighlight = nil 
		self.PressID = 0 
		
		self.LastGhostPosition = Vector3.new(0, 0, 0)
		self.SmokeTemplate = nil
		
		self.FeatureStates = {
			Enable3DHUD = false,        
			ShowSelfHighlight = false,  
			EnableBackgroundBlur = true,
			EnableGhostTrail = false 
		}
		
		return self
	end

	local peFolder = nil
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local function createBaseMicroSnow(parentFolder)
		local snowball = Instance.new("Part")
		snowball.Shape = Enum.PartType.Ball
		local microSize = math.random(3, 6) / 100 
		snowball.Size = Vector3.new(microSize, microSize, microSize)
		snowball.Color = Color3.fromRGB(255, 255, 255)
		snowball.Material = Enum.Material.Neon
		snowball.CanCollide = false; snowball.CanTouch = false; snowball.CanQuery = false
		snowball.Anchored = true; snowball.CastShadow = false
		snowball.Parent = parentFolder
		return snowball
	end

	local function spawnPESnow(playerRoot)
		if not playerRoot or not peFolder then return end
		local localRadius = 4
		local startPos = playerRoot.Position + Vector3.new(
			math.random(-localRadius * 10, localRadius * 10) / 10,
			math.random(15, 65) / 10, 
			math.random(-localRadius * 10, localRadius * 10) / 10
		)
		local snowball = createBaseMicroSnow(peFolder)
		snowball.Position = startPos
		local fallDuration = math.random(15, 25) / 10
		local endPos = startPos + Vector3.new(math.random(-10, 10)/10, -9, math.random(-10, 10)/10)
		
		snowball.Transparency = 1
		TweenService:Create(snowball, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {Transparency = 0.05}):Play()
		TweenService:Create(snowball, TweenInfo.new(fallDuration, Enum.EasingStyle.Linear), {Position = endPos}):Play()
		
		task.delay(fallDuration - 0.4, function() 
			if snowball and snowball.Parent then 
				TweenService:Create(snowball, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {Transparency = 1}):Play() 
			end 
		end)
		task.delay(fallDuration, function() if snowball then snowball:Destroy() end end)
	end

	local function handleWeatherToggle(enabled, folderName)
		if enabled then
			local folder = Instance.new("Folder")
			folder.Name = folderName
			folder.Parent = Workspace
			return folder
		else
			local oldFolder = Workspace:FindFirstChild(folderName)
			if oldFolder then pcall(function() oldFolder:Destroy() end) end
			return nil
		end
	end

	function QuantumHUD:_calculateGhostBackwardOffset(rootPart, humanoid)
		local motionDirection = (humanoid and humanoid.MoveDirection.Magnitude > 0) and humanoid.MoveDirection or rootPart.CFrame.LookVector
		local backwardVector = -motionDirection.Unit * self.Config.GhostBackwardOffset
		local antiFlickerNoise = backwardVector + Vector3.new(
			(math.random() - 0.5) * 0.002,
			(math.random() - 0.5) * 0.002,
			(math.random() - 0.5) * 0.002
		)
		return antiFlickerNoise
	end
	
	function QuantumHUD:_setupGhostPartInstance(sourcePart, antiFlickerOffset)
		local clonePart = Instance.new("Part")
		clonePart.Size = sourcePart.Size * self.Config.GhostScale
		clonePart.CFrame = sourcePart.CFrame + antiFlickerOffset
		clonePart.Anchored = true
		clonePart.CanCollide = false; clonePart.CanTouch = false; clonePart.CanQuery = false
		clonePart.Material = Enum.Material.Neon
		clonePart.Color = self.Config.GhostColor
		
		if sourcePart:IsA("MeshPart") then
			local specialMesh = Instance.new("SpecialMesh")
			specialMesh.MeshType = Enum.MeshType.FileMesh
			specialMesh.MeshId = sourcePart.MeshId
			specialMesh.Scale = Vector3.new(self.Config.GhostScale, self.Config.GhostScale, self.Config.GhostScale)
			specialMesh.Parent = clonePart
		elseif sourcePart:FindFirstChildOfClass("SpecialMesh") then
			local meshClone = sourcePart:FindFirstChildOfClass("SpecialMesh"):Clone()
			meshClone.Scale = meshClone.Scale * self.Config.GhostScale
			meshClone.Parent = clonePart
		end
		
		if sourcePart.Name == "Head" or sourcePart.Name:find("Face") or sourcePart.Name:find("Eye") then
			clonePart.Transparency = math.clamp(self.Config.BodyTransparency + 0.2, 0, 0.95)
		else
			clonePart.Transparency = self.Config.BodyTransparency
		end
		
		return clonePart
	end

	function QuantumHUD:_createSingleGhostInstance(character)
		if not character then return end
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not rootPart then return end
		
		local ghostModel = Instance.new("Model")
		ghostModel.Name = "MyPerfectGhostInstance"
		
		local highlight = Instance.new("Highlight")
		highlight.Name = "TrueNeonOutline"
		highlight.FillColor = self.Config.GhostColor
		highlight.FillTransparency = 0.7 
		highlight.OutlineColor = self.Config.GhostColor 
		highlight.OutlineTransparency = 0.4  
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop 
		highlight.Parent = ghostModel
		
		local offsetVector = self:_calculateGhostBackwardOffset(rootPart, humanoid)
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Transparency < 0.9 then
				local clonePart = self:_setupGhostPartInstance(part, offsetVector)
				clonePart.Parent = ghostModel
				
				local fadeTween = TweenService:Create(clonePart, TweenInfo.new(self.Config.GhostDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1})
				fadeTween:Play()
			end
		end
		if #ghostModel:GetChildren() > 1 then
			ghostModel.Parent = workspace
			
			local hlTween = TweenService:Create(highlight, TweenInfo.new(self.Config.GhostDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {OutlineTransparency = 1, FillTransparency = 1})
			hlTween:Play()
			
			if self.SmokeTemplate then
				local smokeClone = self.SmokeTemplate:Clone()
				smokeClone.Parent = workspace
				smokeClone.Position = (rootPart.Position + offsetVector) - Vector3.new(0, 1.8, 0)
				Debris:AddItem(smokeClone, self.Config.GhostDuration)
			end
			
			Debris:AddItem(ghostModel, self.Config.GhostDuration)
		else
			ghostModel:Destroy()
		end
	end

	function QuantumHUD:_updateFluidEngine(state, targetPos, dt)
		local displacement = state.Position - targetPos
		local distance = displacement.Magnitude
		local dynamicDamping = 0.45 + math.clamp(1 / (distance + 0.1), 0, 1.8)
		
		local springForce = -self.Config.BaseStiffness * displacement
		local baseDampingForce = -dynamicDamping * state.Velocity
		local fluidDragForce = -state.Velocity.Unit * (state.Velocity.Magnitude ^ 2) * self.Config.FluidDragCoeff
		
		if state.Velocity.Magnitude == 0 then fluidDragForce = Vector3.new() end
		local acceleration = springForce + baseDampingForce + fluidDragForce
		
		state.Velocity = state.Velocity + acceleration * dt
		state.Position = state.Position + state.Velocity * dt
		return state.Position
	end

	function QuantumHUD:PurgeLegacyPipelines()
		pcall(function() RunService:UnbindFromRenderStep("Quantum_Stationary_Engine") end)
		local legacy = Workspace:FindFirstChild(self.Config.StorageName)
		if legacy then pcall(function() legacy:Destroy() end) end
		
		local targetParent = CoreGui:FindFirstChild("RobloxGui") or self.LocalPlayer:WaitForChild("PlayerGui")
		if targetParent:FindFirstChild("QuantumPersonalHub") then targetParent.QuantumPersonalHub:Destroy() end
		task.wait(0.02)
	end

	function QuantumHUD:_buildGlassContainer(name)
		if not self.StorageFolder then
			self.StorageFolder = Workspace:FindFirstChild(self.Config.StorageName) or Instance.new("Folder")
			self.StorageFolder.Name = self.Config.StorageName
			self.StorageFolder.Parent = Workspace
		end

		local masterPart = Instance.new("Part")
		masterPart.Name = "ST_Master_" .. name
		masterPart.Size = self.Config.CardSize
		masterPart.Transparency = 1
		masterPart.CanCollide = false; masterPart.CanTouch = false; masterPart.CanQuery = false
		masterPart.Anchored = true
		masterPart.Parent = self.StorageFolder

		local blurFilter = Instance.new("Part")
		blurFilter.Name = "GlassBlurFilter"
		blurFilter.Size = Vector3.new(self.Config.CardSize.X - 0.02, self.Config.CardSize.Y - 0.02, 0.01)
		blurFilter.Material = Enum.Material.Glass
		blurFilter.Transparency = 1 
		blurFilter.Color = self.Config.PinkGlassBg
		blurFilter.CanCollide = false; blurFilter.CanTouch = false; blurFilter.CanQuery = false
		blurFilter.Anchored = true
		blurFilter.Parent = masterPart

		return masterPart
	end

	function QuantumHUD:_attachUltraHDCanvas(parentPart, isLocal)
		local sGui = Instance.new("SurfaceGui")
		sGui.Name = "CanvasEngine"
		sGui.Face = Enum.NormalId.Front
		sGui.CanvasSize = Vector2.new(1380, 525)           
		sGui.PixelsPerStud = 300                             
		sGui.AlwaysOnTop = true
		sGui.LightInfluence = 0.0                          
		sGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		sGui.Enabled = false 
		sGui.Parent = parentPart

		local canvas = Instance.new("CanvasGroup")
		canvas.Name = "AlphaGroup"
		canvas.Size = UDim2.new(1, 0, 1, 0)
		canvas.BackgroundColor3 = isLocal and self.Config.MyCardBg or self.Config.PinkGlassBg
		canvas.GroupTransparency = 1                       
		canvas.BorderSizePixel = 0
		canvas.Parent = sGui
		Instance.new("UICorner", canvas).CornerRadius = UDim.new(0, 42) 

		local stroke = Instance.new("UIStroke", canvas)
		stroke.Thickness = 6.5                                         
		stroke.Color = isLocal and self.Config.MyCardStroke or self.Config.PinkGlassStroke

		local avatar = Instance.new("ImageLabel")
		avatar.Name = "UserAvatar"
		avatar.Size = UDim2.new(0, 130, 0, 130)
		avatar.Position = UDim2.new(0, 45, 0.5, -65)
		avatar.BackgroundTransparency = 1
		avatar.Parent = canvas
		Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)
		
		local avStroke = Instance.new("UIStroke", avatar)
		avStroke.Thickness = 4
		avStroke.Color = stroke.Color

		local function CreateHDText(name, size, pos, color, font)
			local label = Instance.new("TextLabel")
			label.Name = name
			label.Size = UDim2.new(0.75, 0, 0.22, 0)
			label.Position = pos
			label.BackgroundTransparency = 1
			label.TextColor3 = color
			label.TextSize = size
			label.Font = font
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextStrokeTransparency = 1
			
			local shadow = Instance.new("UIStroke", label)
			shadow.Color = self.Config.ShadowColor
			shadow.Thickness = 3.5
			shadow.LineJoinMode = Enum.LineJoinMode.Round
			label.Parent = canvas
			return label
		end

		CreateHDText("TitleLabel", 46, UDim2.new(0, 210, 0.16, 0), self.Config.TextHDMain, Enum.Font.GothamBold)
		CreateHDText("SubTagLabel", 32, UDim2.new(0, 210, 0.46, 0), self.Config.TextHDSub, Enum.Font.GothamBold)
		CreateHDText("StatusLabel", 34, UDim2.new(0, 210, 0.72, 0), self.Config.TextHDMain, Enum.Font.Code)

		if isLocal then
			local coordLabel = CreateHDText("CoordLabel", 28, UDim2.new(0, 210, 0.73, 0), self.Config.TextHDSub, Enum.Font.Code)
			coordLabel.Size = UDim2.new(0.75, 0, 0.18, 0)
			canvas.StatusLabel.Position = UDim2.new(0, 210, 0.56, 0)
			canvas.StatusLabel.TextSize = 30
			
			local hpContainer = Instance.new("Frame")
			hpContainer.Name = "HPContainer"
			hpContainer.Size = UDim2.new(0, 1120, 0, 14)
			hpContainer.Position = UDim2.new(0, 210, 0.43, 0)
			hpContainer.BackgroundColor3 = self.Config.HealthBarContainerColor
			hpContainer.BorderSizePixel = 0
			hpContainer.Parent = canvas
			Instance.new("UICorner", hpContainer).CornerRadius = UDim.new(0, 7)
			
			local hpProgress = Instance.new("Frame")
			hpProgress.Name = "HPProgress"
			hpProgress.Size = UDim2.new(1, 0, 1, 0) 
			hpProgress.BackgroundColor3 = self.Config.HealthBarProgressColor
			hpProgress.BorderSizePixel = 0
			hpProgress.Parent = hpContainer
			Instance.new("UICorner", hpProgress).CornerRadius = UDim.new(0, 7)
		end

		return canvas
	end

	function QuantumHUD:_calculateCinematicTransform(targetRoot, camera, state, gameTime, deltaTime)
		local camCF = camera.CFrame
		local baseShoulderPos = targetRoot.Position + Vector3.new(0, self.Config.ShoulderHeight, 0)
		local targetWorldPos = baseShoulderPos + (camCF.RightVector * self.Config.EyeSeparation)
		
		local slowLayer = math.sin(gameTime * 0.95) * math.cos(gameTime * 0.3) * 0.09
		local fastLayer = math.sin(gameTime * self.Config.MicroVibeFreq) * 0.006 
		local finalBobY = slowLayer + fastLayer
		local finalBobX = math.cos(gameTime * 1.1) * math.sin(gameTime * 0.4) * 0.06
		
		targetWorldPos = targetWorldPos + Vector3.new(finalBobX, finalBobY, finalBobX * 0.3)
		
		local dt = math.min(deltaTime, 0.03)
		local currentPhysicsPos = self:_updateFluidEngine(state, targetWorldPos, dt)
		
		local lookAtCF = CFrame.lookAt(currentPhysicsPos, camCF.Position, Vector3.new(0, 1, 0))
		local localTargetVec = camCF:ToObjectSpace(lookAtCF).Position.Unit
		
		local targetTiltX = -localTargetVec.Y * self.Config.ParallaxIntensity
		local targetTiltY = localTargetVec.X * self.Config.ParallaxIntensity
		state.Rotation = state.Rotation + (Vector3.new(targetTiltX, targetTiltY, 0) - state.Rotation) * 0.15
		
		return lookAtCF * CFrame.Angles(state.Rotation.X, state.Rotation.Y, math.sin(gameTime * 0.5) * 0.005)
	end

	function QuantumHUD:_evaluateGlobalState(myRoot, myHum, camera)
		local realSpeed = myRoot.AssemblyLinearVelocity.Magnitude
		if myHum.MoveDirection.Magnitude > 0.15 and realSpeed > 1.5 then 
			return 1.0 
		end
		local cameraToMeDirection = (camera.CFrame.Position - myRoot.Position).Unit
		local lookDirectionDot = myRoot.CFrame.LookVector:Dot(cameraToMeDirection)
		if lookDirectionDot > self.Config.ViewAngleThreshold then return 0.0 else return 1.0 end
	end

	function QuantumHUD:_forceShutDownAll3DParts()
		if self.My3DInstance then
			self.My3DInstance.CanvasEngine.Enabled = false
			self.My3DInstance.GlassBlurFilter.Transparency = 1
		end
		if self.Target3DCard then
			self.Target3DCard.Part.CanvasEngine.Enabled = false
			self.Target3DCard.Part.GlassBlurFilter.Transparency = 1
			self.Target3DCard.LastTarget = nil
		end
		if self.ActiveFeedbackHighlight then
			pcall(function() self.ActiveFeedbackHighlight:Destroy() end)
			self.ActiveFeedbackHighlight = nil
		end
		self.CurrentTarget = nil
		self.IsPressing = false
	end

	function QuantumHUD:_createLocalSmokeTemplate()
		local attachment = Instance.new("Attachment")
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "LocalDissolveSmoke"
		emitter.Texture = "rbxassetid://241901177"
		emitter.Rate = 2

		emitter.Lifetime = NumberRange.new(0.2, self.Config.GhostDuration)
		emitter.Speed = NumberRange.new(0.1, 0.3)
		emitter.VelocitySpread = 360
		emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0.9)})
		emitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 1)})
		emitter.Color = ColorSequence.new(self.Config.GhostColor)
		emitter.Parent = attachment
		return attachment
	end
	function QuantumHUD:_setupInteractionEngine()
		local clickRaycastParams = RaycastParams.new()
		clickRaycastParams.FilterType = Enum.RaycastFilterType.Exclude

		local isHolding = false
		local startCharacterPos = Vector3.new()
		local touchStartPos = Vector2.new()
		
		local firstClickTime = 0
		local clickCount = 0
		local lastClickTime = 0

		local MAX_INTERACT_DISTANCE = 15 * 3.57 

		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			
			if input.UserInputType == Enum.UserInputType.MouseWheel or 
			   input.UserInputType == Enum.UserInputType.MouseButton2 or 
			   input.UserInputType == Enum.UserInputType.MouseButton3 then
				return
			end

			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				local camera = Workspace.CurrentCamera
				if not camera then return end

				touchStartPos = Vector2.new(input.Position.X, input.Position.Y)
				local currentTime = os.clock()
				isHolding = true

				local timeSinceLastInput = currentTime - lastClickTime
				lastClickTime = currentTime

				if timeSinceLastInput <= 0.25 then
					clickCount = 0
					firstClickTime = 0
				else
					if clickCount == 0 or (currentTime - firstClickTime) > 0.7 then
						clickCount = 1
						firstClickTime = currentTime
					else
						clickCount = clickCount + 1
						if clickCount == 2 then
							clickCount = 0
							firstClickTime = 0
							self:_forceShutDownAll3DParts()
							isHolding = false
							return 
						end
					end
				end

				local unitRay = camera:ScreenPointToRay(touchStartPos.X, touchStartPos.Y)
				clickRaycastParams.FilterDescendantsInstances = {self.LocalPlayer.Character, self.StorageFolder}
				local raycastResult = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, clickRaycastParams)
				
				self.PressID = self.PressID + 1
				local currentPressID = self.PressID

				if raycastResult and raycastResult.Instance then
					local hitModel = raycastResult.Instance:FindFirstAncestorOfClass("Model")
					local targetPlayer = hitModel and Players:GetPlayerFromCharacter(hitModel)
					
					if targetPlayer and targetPlayer ~= self.LocalPlayer then
						local hum = hitModel:FindFirstChildOfClass("Humanoid")
						local root = hitModel:FindFirstChild("HumanoidRootPart")
						
						local myChar = self.LocalPlayer.Character
						local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
						
						if hum and root and hum.Health > 0 and myRoot then
							local currentDistance = (myRoot.Position - root.Position).Magnitude
							if currentDistance > MAX_INTERACT_DISTANCE then
								isHolding = false
								return
							end

							self:_forceShutDownAll3DParts()
							startCharacterPos = myRoot.Position

							local feedbackHighlight = Instance.new("Highlight")
							feedbackHighlight.Name = "Quantum_Interaction_Feedback"
							feedbackHighlight.FillColor = Color3.fromRGB(255, 255, 255)
							feedbackHighlight.FillTransparency = 1.0 
							feedbackHighlight.OutlineColor = Color3.fromRGB(255, 255, 255) 
							feedbackHighlight.OutlineTransparency = self.Config.OutlineTransparency
							feedbackHighlight.Adornee = hitModel
							feedbackHighlight.Parent = hitModel
							self.ActiveFeedbackHighlight = feedbackHighlight

							local destroyConn
							destroyConn = feedbackHighlight.AncestryChanged:Connect(function(_, parent)
								if not parent then
									destroyConn:Disconnect()
									if self.ActiveFeedbackHighlight == feedbackHighlight then
										self.ActiveFeedbackHighlight = nil
									end
									self.CurrentTarget = nil
									self.IsPressing = false
								end
							end)

							task.spawn(function()
								local elapsed = 0
								while elapsed < 1.0 do
									task.wait(0.05)
									elapsed = elapsed + 0.05
									
									local currentMyChar = self.LocalPlayer.Character
									local currentMyRoot = currentMyChar and currentMyChar:FindFirstChild("HumanoidRootPart")
									
									if currentMyRoot and isHolding then
										local moveDist = (currentMyRoot.Position - startCharacterPos).Magnitude
										local realTimeDist = (currentMyRoot.Position - root.Position).Magnitude
										
										if moveDist > 1.5 or realTimeDist > MAX_INTERACT_DISTANCE then
											if feedbackHighlight and feedbackHighlight.Parent then
												pcall(function() feedbackHighlight:Destroy() end)
											end
											isHolding = false
											return
										end
									end
								end

								if self.PressID == currentPressID and isHolding and feedbackHighlight.Parent then
									self.CurrentTarget = targetPlayer
									self.IsPressing = true
									
									local basePos = root.Position + (camera.CFrame.RightVector * self.Config.EyeSeparation)
									self.TargetFluidState.Position = basePos
									self.TargetFluidState.Velocity = Vector3.new()
								end
							end)
							return
						end
					end
				end
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				isHolding = false
				if not self.IsPressing then
					if self.ActiveFeedbackHighlight then
						pcall(function() self.ActiveFeedbackHighlight:Destroy() end)
						self.ActiveFeedbackHighlight = nil
					end
				end
			end
		end)
	end

	function QuantumHUD:_launchPipelineLoop()
		local MAX_INTERACT_DISTANCE = 15 * 3.57

		RunService:BindToRenderStep("Quantum_Stationary_Engine", Enum.RenderPriority.Camera.Value + 1, function(dt)
			if not self.IsRunning then return end
			
			local camera = Workspace.CurrentCamera
			local myChar = self.LocalPlayer.Character
			local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
			local myHum = myChar and myChar:FindFirstChild("Humanoid")
			local currentTime = os.clock()
			
			if myRoot then
				if getgenv().PESnow_Enabled then
					for _ = 1, 2 do spawnPESnow(myRoot) end
				end
			end

			if myChar and myHum and myRoot and self.FeatureStates.EnableGhostTrail then
				pcall(function()
					if myHum.MoveDirection.Magnitude > 0 then
						myChar:TranslateBy(myHum.MoveDirection * self.Config.TpWalkSpeed / 100)
						local currentPosition = myRoot.Position
						local distanceMoved = (currentPosition - self.LastGhostPosition).Magnitude
						if distanceMoved >= self.Config.MinMoveDistance then
							self:_createSingleGhostInstance(myChar)
							self.LastGhostPosition = currentPosition
						end
					end
				end)
			end

			if not self.FeatureStates.Enable3DHUD then
				self:_forceShutDownAll3DParts()
				return 
			end
			
			if not (camera and myRoot and myHum) then return end
			
			local targetGlobalAlpha = self:_evaluateGlobalState(myRoot, myHum, camera)
			local wasHidden = (self.GlobalCurrentAlpha > 0.95)
			
			local alphaSpeed = targetGlobalAlpha == 0 and 0.09 or 0.25
			self.GlobalCurrentAlpha = self.GlobalCurrentAlpha + (targetGlobalAlpha - self.GlobalCurrentAlpha) * alphaSpeed
			
			local isGlobalVisible = self.GlobalCurrentAlpha < 0.95
			local computedBlurTransparency = 0.45 + (self.GlobalCurrentAlpha * 0.55)

			if self.My3DInstance then
				if isGlobalVisible then
					self.My3DInstance.CanvasEngine.Enabled = true
					local alphaGroup = self.My3DInstance.CanvasEngine.AlphaGroup
					alphaGroup.GroupTransparency = self.GlobalCurrentAlpha
					self.My3DInstance.GlassBlurFilter.Transparency = computedBlurTransparency
					local hpRatio = math.clamp(myHum.Health / myHum.MaxHealth, 0, 1)
					alphaGroup.StatusLabel.Text = self.Locale.LocalStatusPrefix .. tostring(math.floor(hpRatio * 100)) .. "%"
					alphaGroup.HPContainer.HPProgress.Size = UDim2.new(hpRatio, 0, 1, 0)
					local pos = myRoot.Position
					alphaGroup.CoordLabel.Text = string.format(self.Locale.CoordPrefix, pos.X, pos.Y, pos.Z)
					if wasHidden then 
						local basePos = myRoot.Position + (camera.CFrame.RightVector * self.Config.EyeSeparation)
						self.MyFluidState.Position = basePos
						self.MyFluidState.Velocity = Vector3.new()
						self.MyFluidState.Rotation = Vector3.new()
					end
					
					local finalCF = self:_calculateCinematicTransform(myRoot, camera, self.MyFluidState, currentTime, dt)
					self.My3DInstance.CFrame = finalCF
					self.My3DInstance.GlassBlurFilter.CFrame = finalCF * CFrame.new(0, 0, -0.01)
				else
					self.My3DInstance.CanvasEngine.Enabled = false
					self.My3DInstance.GlassBlurFilter.Transparency = 1
				end
			end

			local slot = self.Target3DCard
			local tPlayer = self.CurrentTarget
			local tChar = tPlayer and tPlayer.Character
			local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
			local tHum = tChar and tChar:FindFirstChild("Humanoid")

			if tRoot and myRoot then
				local realTimeDist = (myRoot.Position - tRoot.Position).Magnitude
				if realTimeDist > MAX_INTERACT_DISTANCE then
					self:_forceShutDownAll3DParts()
					return
				end
			end

			if slot and isGlobalVisible and self.IsPressing and tRoot and tHum and tHum.Health > 0 then
				slot.Part.CanvasEngine.Enabled = true
				local alphaGroup = slot.Part.CanvasEngine.AlphaGroup
				alphaGroup.GroupTransparency = self.GlobalCurrentAlpha
				slot.Part.GlassBlurFilter.Transparency = computedBlurTransparency
				
				if slot.LastTarget ~= tPlayer then
					local basePos = tRoot.Position + (camera.CFrame.RightVector * self.Config.EyeSeparation)
					self.TargetFluidState = { Position = basePos, Velocity = Vector3.new(), Rotation = Vector3.new() }
				end
				
				local finalCF = self:_calculateCinematicTransform(tRoot, camera, self.TargetFluidState, currentTime, dt)
				slot.Part.CFrame = finalCF
				slot.Part.GlassBlurFilter.CFrame = finalCF * CFrame.new(0, 0, -0.01)
				
				if slot.LastTarget ~= tPlayer then
					slot.LastTarget = tPlayer
					alphaGroup.TitleLabel.Text = tPlayer.DisplayName
					
					local avatarUrl = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(tPlayer.UserId) .. "&w=150&h=150"
					if alphaGroup.UserAvatar.Image ~= avatarUrl then
						alphaGroup.UserAvatar.Image = avatarUrl
					end
					local tool = tChar:FindFirstChildOfClass("Tool")
					alphaGroup.SubTagLabel.Text = tool and ("🌸 " .. tool.Name) or self.Locale.ToolUnarmed
				end
				alphaGroup.StatusLabel.Text = "💢 HP: " .. tostring(math.floor(tHum.Health)) .. " / " .. tostring(tHum.MaxHealth)
			else
				if slot and slot.Part then
					slot.Part.CanvasEngine.Enabled = false
					slot.Part.GlassBlurFilter.Transparency = 1
				end
				if slot then slot.LastTarget = nil end
			end
		end)
	end

	function QuantumHUD:_applySelfHighlight(character)
		if not character then return end
		local old1 = character:FindFirstChild("SelfTacticalOutline")
		local old2 = character:FindFirstChild("Quantum_Self_Highlight")
		if old1 then old1:Destroy() end
		if old2 then old2:Destroy() end

		if not self.FeatureStates.ShowSelfHighlight then return end

		local highlight = Instance.new("Highlight")
		highlight.Name = "SelfTacticalOutline"
		highlight.FillColor = Color3.fromRGB(255, 255, 255)
		highlight.FillTransparency = 1.0            
		highlight.OutlineColor = Color3.fromRGB(255, 255, 255) 
		highlight.OutlineTransparency = self.Config.OutlineTransparency          
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop 
		highlight.Adornee = character
		highlight.Parent = character
	end

	function QuantumHUD:_applyVisualEnhancements(character)
		if not character then return end
		local oldLight = character:FindFirstChild("Quantum_Self_PointLight")
		if oldLight then oldLight:Destroy() end

		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("MeshPart") or part:IsA("BasePart") then
				if part:IsA("MeshPart") then part.RenderFidelity = Enum.RenderFidelity.Precise end
				part.CastShadow = true
				pcall(function()
					if part.Material == Enum.Material.Plastic then part.Material = Enum.Material.SmoothPlastic end
					if part.Name == "Head" or part.Name == "Face" or part.Name:find("Face") then
						part.Reflectance = self.Config.HeadReflectance
					else
						part.Reflectance = self.Config.BodyReflectance
					end
				end)
			end
		end

		local lowerTorso = character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso")
		if lowerTorso then
			local light = Instance.new("PointLight")
			light.Name = "Quantum_Self_PointLight"
			light.Color = Color3.fromRGB(255, 245, 250) 
			light.Brightness = self.Config.LightBrightness                      
			light.Range = self.Config.LightRange                           
			light.Shadows = true                        
			light.Parent = lowerTorso
		end
	end
	function QuantumHUD:_maximizeMobileGraphicsPipeline()
		pcall(function()
			settings().Rendering.QualityLevel = Enum.QualityLevel.Level21
			Lighting.Technology = Enum.Technology.Future
			Lighting.ShadowMapEnabled = true
			Lighting.GlobalShadows = true
			Lighting.EnvironmentDiffuseScale = 1.0  
			Lighting.EnvironmentSpecularScale = 1.0 
			Lighting.Ambient = Color3.fromRGB(35, 32, 38)
			Lighting.OutdoorAmbient = Color3.fromRGB(45, 42, 50)
		end)

		for _, fx in ipairs(Lighting:GetChildren()) do
			if fx.Name:find("QuantumFX_") then fx:Destroy() end
		end

		local colorCorrection = Instance.new("ColorCorrectionEffect")
		colorCorrection.Name = "QuantumFX_ColorMax"
		colorCorrection.Brightness = 0.02; colorCorrection.Contrast = 0.20; colorCorrection.Saturation = 0.16     
		colorCorrection.TintColor = Color3.fromRGB(255, 252, 248) 
		colorCorrection.Parent = Lighting

		local bloom = Instance.new("BloomEffect")
		bloom.Name = "QuantumFX_BloomMax"
		bloom.Intensity = 0.95; bloom.Size = 32; bloom.Threshold = 0.80                
		bloom.Parent = Lighting

		local sunRays = Instance.new("SunRaysEffect")
		sunRays.Name = "QuantumFX_SunRaysMax"
		sunRays.Intensity = 0.40; sunRays.Spread = 0.92
		sunRays.Parent = Lighting

		local blur = Instance.new("BlurEffect")
		blur.Name = "QuantumFX_MotionBlurMax"
		blur.Size = 2.6
		blur.Parent = Lighting

		task.spawn(function()
			for _, desc in ipairs(Workspace:GetDescendants()) do
				if desc:IsA("BasePart") and not desc:IsDescendantOf(Players.LocalPlayer.Character) then
					pcall(function()
						if desc.Material == Enum.Material.Plastic then desc.Material = Enum.Material.SmoothPlastic end
						if desc.Reflectance < 0.05 then desc.Reflectance = 0.06 end
					end)
				end
			end
		end)
	end

	function QuantumHUD:_buildInteractiveControlHub()
		local targetParent = CoreGui:FindFirstChild("RobloxGui") or self.LocalPlayer:WaitForChild("PlayerGui")
		
		local screenGui = Instance.new("ScreenGui")
		screenGui.Name = "QuantumPersonalHub"
		screenGui.ResetOnSpawn = false
		screenGui.Parent = targetParent

		local modalModal = Instance.new("TextButton") 
		modalModal.Name = "ModalBackdrop"
		modalModal.Size = UDim2.new(1, 0, 1, 0)
		modalModal.BackgroundTransparency = 1 
		modalModal.Text = ""
		modalModal.Active = true 
		modalModal.Parent = screenGui

		local function isDeveloper(username)
			return string.lower(username) == string.lower(self.Config.DevUsername)
		end

		local canvas = Instance.new("CanvasGroup")
		canvas.Name = "MainCanvas"
		canvas.Size = self.Config.WindowSize 
		canvas.Position = UDim2.new(0.5, -240, 0.4, -140)
		canvas.BackgroundColor3 = self.Config.BgColor
		canvas.BackgroundTransparency = self.Config.BgTransparency
		canvas.GroupTransparency = 1 
		canvas.BorderSizePixel = 0
		canvas.Parent = screenGui 
		Instance.new("UICorner", canvas).CornerRadius = UDim.new(0, 12)

		local mainStroke = Instance.new("UIStroke", canvas)
		mainStroke.Thickness = 1.2
		mainStroke.Color = self.Config.StrokeColor
		mainStroke.Transparency = 0.25

		local topBar = Instance.new("Frame")
		topBar.Name = "TopBarHandle"
		topBar.Size = UDim2.new(1, 0, 0, 40)
		topBar.BackgroundTransparency = 1 
		topBar.Active = true 
		topBar.Parent = canvas

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -60, 1, 0)
		title.Position = UDim2.new(0, 16, 0, 0)
		title.BackgroundTransparency = 1
		title.Text = self.Locale.PanelTitle
		title.TextColor3 = self.Config.TextMain
		title.TextSize = 11
		title.Font = Enum.Font.GothamBold
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Parent = topBar

		local topSep = Instance.new("Frame", topBar)
		topSep.Size = UDim2.new(1, -32, 0, 1)
		topSep.Position = UDim2.new(0, 16, 1, -1)
		topSep.BackgroundColor3 = self.Config.TextMain
		topSep.BackgroundTransparency = 0.92

		local miniButton = Instance.new("TextButton")
		miniButton.Size = UDim2.new(0, 20, 0, 20)
		miniButton.Position = UDim2.new(1, -30, 0, 10)
		miniButton.BackgroundColor3 = self.Config.TextMain
		miniButton.BackgroundTransparency = 0.93
		miniButton.Text = "✕"
		miniButton.TextColor3 = self.Config.TextMain
		miniButton.TextSize = 10
		miniButton.Font = Enum.Font.GothamBold
		miniButton.Parent = topBar
		Instance.new("UICorner", miniButton).CornerRadius = UDim.new(1, 0)

		local islandBar = Instance.new("TextButton")
		islandBar.Name = "DynamicIsland"
		islandBar.Size = self.Config.IslandSize
		islandBar.Position = UDim2.new(0.5, -75, 0, -40) 
		islandBar.BackgroundColor3 = self.Config.BgColor
		islandBar.BackgroundTransparency = 0.1
		islandBar.Text = self.Locale.IslandTitle 
		islandBar.TextColor3 = self.Config.TextMain
		islandBar.TextSize = 10
		islandBar.Font = Enum.Font.GothamBold
		islandBar.Visible = false
		islandBar.Parent = screenGui
		Instance.new("UICorner", islandBar).CornerRadius = UDim.new(1, 0)
		local islandStroke = Instance.new("UIStroke", islandBar)
		islandStroke.Color = self.Config.StrokeColor

		local mainBody = Instance.new("Frame")
		mainBody.Name = "MainBody"
		mainBody.Size = UDim2.new(1, -32, 1, -56)
		mainBody.Position = UDim2.new(0, 16, 0, 48)
		mainBody.BackgroundTransparency = 1
		mainBody.Parent = canvas

		local sidebar = Instance.new("Frame")
		sidebar.Name = "Sidebar"
		sidebar.Size = UDim2.new(0, 100, 1, 0)
		sidebar.BackgroundTransparency = 1
		sidebar.Parent = mainBody

		local sidebarLayout = Instance.new("UIListLayout")
		sidebarLayout.Padding = UDim.new(0, 4)
		sidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
		sidebarLayout.Parent = sidebar

		local contentArea = Instance.new("Frame")
		contentArea.Name = "ContentArea"
		contentArea.Size = UDim2.new(1, -112, 1, 0)
		contentArea.Position = UDim2.new(0, 112, 0, 0)
		contentArea.BackgroundTransparency = 1
		contentArea.Parent = mainBody

		local tabs = {}
		local tabButtons = {}
		local currentTab = nil

		local function createTab(id, name)
			local panel = Instance.new("Frame")
			panel.Name = id .. "Panel"
			panel.Size = UDim2.new(1, 0, 1, 0)
			panel.BackgroundTransparency = 1
			panel.Visible = false
			panel.Parent = contentArea

			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, 0, 0, 30)
			btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			btn.BackgroundTransparency = 1 
			btn.Text = " " .. name
			btn.TextColor3 = self.Config.TextSub
			btn.TextSize = 11
			btn.Font = Enum.Font.GothamBold
			btn.TextXAlignment = Enum.TextXAlignment.Left
			btn.Parent = sidebar
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

			local btnStroke = Instance.new("UIStroke", btn)
			btnStroke.Color = self.Config.StrokeColor
			btnStroke.Thickness = 1
			btnStroke.Transparency = 1

			btn.MouseButton1Click:Connect(function()
				if currentTab and tabs[currentTab] then
					tabs[currentTab].Visible = false
					TweenService:Create(tabButtons[currentTab], self.Config.ButtonBounce, {BackgroundTransparency = 1, TextColor3 = self.Config.TextSub}):Play()
					TweenService:Create(tabButtons[currentTab]:FindFirstChildOfClass("UIStroke"), self.Config.ButtonBounce, {Transparency = 1}):Play()
				end
				currentTab = id
				panel.Visible = true

				TweenService:Create(btn, self.Config.ButtonBounce, {BackgroundTransparency = 0.5, BackgroundColor3 = self.Config.CardColor, TextColor3 = self.Config.AccentColor}):Play()
				TweenService:Create(btnStroke, self.Config.ButtonBounce, {Transparency = 0.5}):Play()
			end)

			tabs[id] = panel
			tabButtons[id] = btn
			return panel
		end
		
		local panelOverview = createTab("overview", self.Locale.TabOverview)
		local panelSettings = createTab("settings", self.Locale.TabSettings)
		local panelWeather = createTab("weather", self.Locale.TabWeather) 

		local function createGridCard(parent, titleText, size, position)
			local card = Instance.new("Frame", parent)
			card.Size = size; card.Position = position; card.BackgroundColor3 = self.Config.CardColor; card.BackgroundTransparency = self.Config.CardTransparency
			Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
			local cardStroke = Instance.new("UIStroke", card)
			cardStroke.Color = self.Config.StrokeColor; cardStroke.Thickness = 1; cardStroke.Transparency = 0.55

			local cardTitle = Instance.new("TextLabel", card)
			cardTitle.Size = UDim2.new(1, -16, 0, 20); cardTitle.Position = UDim2.new(0, 10, 0, 4); cardTitle.BackgroundTransparency = 1
			cardTitle.Text = titleText; cardTitle.TextColor3 = self.Config.AccentColor; cardTitle.TextSize = 9; cardTitle.Font = Enum.Font.GothamBold; cardTitle.TextXAlignment = Enum.TextXAlignment.Left

			local container = Instance.new("Frame", card)
			container.Size = UDim2.new(1, -20, 1, -26); container.Position = UDim2.new(0, 10, 0, 22); container.BackgroundTransparency = 1
			return container
		end
		
		local cCore = createGridCard(panelOverview, self.Locale.CardCoreTitle, UDim2.new(0.5, -4, 0.45, 0), UDim2.new(0, 0, 0, 0))
		local coreList = Instance.new("UIListLayout", cCore); coreList.Padding = UDim.new(0, 2)

		local function addStatusRow(parent, label, value)
			local row = Instance.new("TextLabel", parent)
			row.Size = UDim2.new(1, 0, 0, 14); row.BackgroundTransparency = 1;
			row.Text = "• " .. label .. ": " .. value
			row.TextColor3 = self.Config.TextMain; row.TextSize = 10; row.Font = Enum.Font.Code; row.TextXAlignment = Enum.TextXAlignment.Left
		end
		addStatusRow(cCore, "STYLE", "ACRYLIC PURE v2")
		addStatusRow(cCore, "BYPASS", "ACTIVE")
		addStatusRow(cCore, "OWN USER", self.LocalPlayer.Name)
		
		local cTarget = createGridCard(panelOverview, self.Locale.CardTargetTitle, UDim2.new(0.5, -4, 0.45, 0), UDim2.new(0.5, 4, 0, 0))
		local tacList = Instance.new("UIListLayout", cTarget); tacList.Padding = UDim.new(0, 2)
		addStatusRow(cTarget, "DEV_TARGET", self.Config.DevUsername)
		addStatusRow(cTarget, "SELF_IS_DEV", isDeveloper(self.LocalPlayer.Name) and "YES (ACTIVE)" or "NO (USER)")
		addStatusRow(cTarget, "PRIVILEGE", "STABLE MASKING")
		
		local cNetwork = createGridCard(panelOverview, self.Locale.CardNetworkTitle, UDim2.new(1, 0, 0.5, 0), UDim2.new(0, 0, 0.5, 0))
		local netText = Instance.new("TextLabel", cNetwork)
		netText.Size = UDim2.new(1, 0, 1, 0); netText.BackgroundTransparency = 1
		netText.Text = self.Locale.LogSuccess
		netText.TextColor3 = self.Config.TextSub; netText.TextSize = 10; netText.Font = Enum.Font.Code; netText.TextXAlignment = Enum.TextXAlignment.Left; netText.TextYAlignment = Enum.TextYAlignment.Top
		
		local cSwitches = createGridCard(panelSettings, self.Locale.CardSwitchTitle, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0))
		local switchList = Instance.new("UIListLayout", cSwitches); switchList.Padding = UDim.new(0, 4)

		local cWeatherSwitches = createGridCard(panelWeather, self.Locale.CardWeatherTitle, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0))
		local weatherSwitchList = Instance.new("UIListLayout", cWeatherSwitches); weatherSwitchList.Padding = UDim.new(0, 4)

		local function createToggleRow(cardContainer, label, defaultState, callback)
			local rowFrame = Instance.new("Frame", cardContainer)
			rowFrame.Size = UDim2.new(1, 0, 0, 32)
			rowFrame.BackgroundTransparency = 1

			local text = Instance.new("TextLabel", rowFrame)
			text.Size = UDim2.new(0.7, 0, 1, 0)
			text.BackgroundTransparency = 1
			text.Text = "⚙️ " .. label
			text.TextColor3 = self.Config.TextMain; text.TextSize = 11; text.Font = Enum.Font.GothamBold; text.TextXAlignment = Enum.TextXAlignment.Left

			local toggleBtn = Instance.new("TextButton", rowFrame)
			toggleBtn.Size = UDim2.new(0, 48, 0, 22)
			toggleBtn.Position = UDim2.new(1, -48, 0.5, -11)
			toggleBtn.BackgroundColor3 = defaultState and self.Config.AccentColor or Color3.fromRGB(200, 202, 205)
			toggleBtn.Text = ""
			Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)

			local pill = Instance.new("Frame", toggleBtn)
			pill.Size = UDim2.new(0, 16, 0, 16)
			pill.Position = defaultState and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
			pill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

			local currentState = defaultState
			toggleBtn.MouseButton1Click:Connect(function()
				currentState = not currentState
				local targetColor = currentState and self.Config.AccentColor or Color3.fromRGB(200, 202, 205)
				local targetPillPos = currentState and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)

				TweenService:Create(toggleBtn, self.Config.ButtonBounce, {BackgroundColor3 = targetColor}):Play()
				TweenService:Create(pill, self.Config.ButtonBounce, {Position = targetPillPos}):Play()

				if callback then callback(currentState) end
			end)
		end
		
		createToggleRow(cSwitches, self.Locale.Switch3D, self.FeatureStates.Enable3DHUD, function(v)
			self.FeatureStates.Enable3DHUD = v
			if not v then self:_forceShutDownAll3DParts() end
		end)
		createToggleRow(cSwitches, self.Locale.SwitchHighlight, self.FeatureStates.ShowSelfHighlight, function(v)
			self.FeatureStates.ShowSelfHighlight = v
			self:_applySelfHighlight(self.LocalPlayer.Character)
		end)
		createToggleRow(cSwitches, self.Locale.SwitchBlur, self.FeatureStates.EnableBackgroundBlur, function(v)
			self.FeatureStates.EnableBackgroundBlur = v
			local existingBlur = Lighting:FindFirstChild("AcrylicGlobalBlur")
			if existingBlur then existingBlur.Size = v and 22 or 0 end
		end)
		createToggleRow(cSwitches, self.Locale.SwitchGhost, self.FeatureStates.EnableGhostTrail, function(v)
			self.FeatureStates.EnableGhostTrail = v
			if v and self.LocalPlayer.Character and self.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
				self.LastGhostPosition = self.LocalPlayer.Character.HumanoidRootPart.Position
			end
		end)
		
		createToggleRow(cWeatherSwitches, self.Locale.SwitchPESnow, getgenv().PESnow_Enabled, function(v)
			getgenv().PESnow_Enabled = v
			peFolder = handleWeatherToggle(v, "Quantum_PESnowLayer")
		end)

		tabButtons["overview"].BackgroundTransparency = 0.5;
		tabButtons["overview"].BackgroundColor3 = self.Config.CardColor; tabButtons["overview"].TextColor3 = self.Config.AccentColor
		tabButtons["overview"]:FindFirstChildOfClass("UIStroke").Transparency = 0.5; tabs["overview"].Visible = true;
		currentTab = "overview"

		local function updateGlobalBlur(enable)
			local existingBlur = Lighting:FindFirstChild("AcrylicGlobalBlur")
			if enable and self.FeatureStates.EnableBackgroundBlur then 
				if not existingBlur then 
					local b = Instance.new("BlurEffect")
					b.Name = "AcrylicGlobalBlur"
					b.Size = 22
					b.Parent = Lighting 
				end
			else 
				if existingBlur then existingBlur:Destroy() end 
			end
		end

		local function minimize()
			topBar.Visible = false
			mainBody.Visible = false
			updateGlobalBlur(false)
			modalModal.Visible = false 
			local t1 = TweenService:Create(canvas, self.Config.LinearSmooth, {GroupTransparency = 1})
			t1:Play()
			t1.Completed:Connect(function() 
				canvas.Visible = false
				islandBar.Visible = true
				islandBar.Position = UDim2.new(0.5, -75, 0, -40)
				TweenService:Create(islandBar, self.Config.LinearSmooth, {Position = UDim2.new(0.5, -75, 0, 15)}):Play() 
			end)
		end

		local function expand()
			modalModal.Visible = true
			updateGlobalBlur(true) 
			local tIsland = TweenService:Create(islandBar, self.Config.LinearSmooth, {Position = UDim2.new(0.5, -75, 0, -50)})
			tIsland:Play()
			tIsland.Completed:Connect(function()
				islandBar.Visible = false
				canvas.Visible = true
				canvas.Size = self.Config.WindowSize
				canvas.Position = UDim2.new(0.5, -240, 0.4, -140)

				local t2 = TweenService:Create(canvas, self.Config.LinearSmooth, {GroupTransparency = 0})
				t2:Play()
				t2.Completed:Connect(function() 
					topBar.Visible = true
					mainBody.Visible = true 
				end)
			end)
		end

		miniButton.MouseButton1Click:Connect(minimize)
		islandBar.MouseButton1Click:Connect(expand)

		local dragging, dragInput, dragStart, startPos
		topBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = canvas.Position 
				input.Changed:Connect(function() 
					if input.UserInputState == Enum.UserInputState.End then dragging = false end 
				end)
			end
		end)

		topBar.InputChanged:Connect(function(input) 
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end 
		end)

		UserInputService.InputChanged:Connect(function(input)
			if dragging and input == dragInput then
				local delta = input.Position - dragStart
				TweenService:Create(canvas, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
				}):Play()
			end
		end)

		canvas.GroupTransparency = 1
		canvas.Visible = false
		topBar.Visible = false
		mainBody.Visible = false
		modalModal.Visible = false
		islandBar.Visible = true
		islandBar.Position = UDim2.new(0.5, -75, 0, 15)
	end
	
	function QuantumHUD:Start()
		self:PurgeLegacyPipelines()
		self.IsRunning = true
		
		self:_maximizeMobileGraphicsPipeline()
		self.SmokeTemplate = self:_createLocalSmokeTemplate()
		
		self.My3DInstance = self:_buildGlassContainer("LocalPlayer")
		local myCanvas = self:_attachUltraHDCanvas(self.My3DInstance, true)
		myCanvas.TitleLabel.Text = "👑 " .. self.LocalPlayer.DisplayName
		myCanvas.SubTagLabel.Text = self.Locale.LoveMessage
		myCanvas.UserAvatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(self.LocalPlayer.UserId) .. "&w=150&h=150"
		
		if self.LocalPlayer.Character then
			self:_applyVisualEnhancements(self.LocalPlayer.Character)
			self:_applySelfHighlight(self.LocalPlayer.Character)
			self.LastGhostPosition = self.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and self.LocalPlayer.Character.HumanoidRootPart.Position or Vector3.new()
		end

		self.LocalPlayer.CharacterAdded:Connect(function(newCharacter)
			self:_applyVisualEnhancements(newCharacter)
			self:_applySelfHighlight(newCharacter)
			if newCharacter:WaitForChild("HumanoidRootPart") then
				self.LastGhostPosition = newCharacter.HumanoidRootPart.Position
			end
		end)
		
		local part = self:_buildGlassContainer("InteractionSlot")
		local canvas = self:_attachUltraHDCanvas(part, false)
		self.Target3DCard = {Part = part, Canvas = canvas, LastTarget = nil}
		
		self:_buildInteractiveControlHub()
		self:_setupInteractionEngine() 
		self:_launchPipelineLoop()
	end

	local RunInstance = QuantumHUD.new()
	RunInstance:Start()
end

LaunchQuantumGraphicsPipeline({
	BodyReflectance = 0.15,    
	HeadReflectance = 0.01,    
	LightBrightness = 0.45,    
	LightRange = 11.0,         
	OutlineTransparency = 0.05 
})
