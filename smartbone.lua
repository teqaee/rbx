local SmartboneHandler = {}

local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")

SmartboneHandler.Init = function()
	local SmartBone = require(Modules:WaitForChild("SmartBone"))
	SmartBone.Start()
	_G.SmartBone = SmartBone
end

return SmartboneHandler
