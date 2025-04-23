local CommanderHandler																		= {}

local ReplicatedStorage																		= game:GetService("ReplicatedStorage")
local Modules																				= ReplicatedStorage:WaitForChild("Modules")

CommanderHandler.Init																		= function()
	local Cmdr																				= require(ReplicatedStorage:WaitForChild("CmdrClient"))
	Cmdr:SetActivationKeys({ Enum.KeyCode.F2 })
end

return CommanderHandler
