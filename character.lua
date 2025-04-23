local CharacterHandler = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")

local Opened																				= os.time()
local Client																				= Players.LocalPlayer
local Icon																					= require(Modules:WaitForChild("Icon"))
local Character																				= Client.Character or Client.CharacterAdded:Wait()

local Camera                                                                                = workspace.CurrentCamera

local Added																					= function(New)
	Character																				= New
end

CharacterHandler.Init																		= function()
	Client.CharacterAdded:Connect(Added)

	RunService.RenderStepped:Connect(function(deltaTime)
		if not Character then return end

		if not Character:FindFirstChild("Head") then return end
		if not Character:FindFirstChild("Humanoid") then return end
		if not Character:FindFirstChild("HumanoidRootPart") then return end

		if GuiService.MenuIsOpen then
			Opened = os.time()
		end

		if os.time() - Opened <= 1 then
			local targetPosition = Vector3.new(0, 0, 0)
			Camera.CFrame = CFrame.new(targetPosition)
			Icon.setTopbarEnabled(false)

		else
			Character.Humanoid.CameraOffset = (Character.HumanoidRootPart.CFrame + Vector3.new(0, 1.5, 0)):ToObjectSpace(Character.Head.CFrame).Position
			Icon.setTopbarEnabled(true)
		end
	end)

	Added(Character)
end

return CharacterHandler
