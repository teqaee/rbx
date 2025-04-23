local NetworkingHandler = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local ServerModules = ServerStorage:WaitForChild("Modules")
local ReplicatedModules = ReplicatedStorage:WaitForChild("Modules")
local Storage = ServerStorage.Storage

local Red = require(ReplicatedModules:WaitForChild("Red"))

local Flood = require(ServerModules:WaitForChild("Flood"))

local Controller = _G.Controller
local Networking = Red.Server("Network")
shared.Network = Networking

local Opposites = {
    ["Male"] = "Female",
    ["Female"] = "Male",
    ["Futa"] = "Femboy",
    ["Femboy"] = "Futa"
}

NetworkingHandler.Init = function()
    Networking:On(
        "Age",
        function(Player, Age)
            if not tonumber(Age) then
                Networking:Fire(Player, "Request", "Error", "That's not an valid age.")
                return
            end
            if tonumber(Age) < 16 then
                Networking:Fire(Player, "Request", "Error", "You can't play our games if you are younger than 16")
                return
            end

            Player:SetAttribute("Age", tonumber(Age))
        end
    )

    Networking:On(
        "Gender",
        function(Player, Gender)
            if Gender ~= "Female" and Gender ~= "Male" and Gender ~= "Futa" and Gender ~= "Femboy" then
                return
            end
            if Player:GetAttribute("Gender") then
                return
            end

            Player:SetAttribute("Gender", Gender)
        end
    )

    Networking:On(
        "Update",
        function()
        end
    )
    Networking:On(
        "Request",
        function()
        end
    )

    Networking:On(
        "Collar",
        function(Player, Method, Target)
            if not Flood:Check(Player, "Collar", 1) then
                return
            end

            -- Ensure valid Player and Target
            if not Player or not Player.Character then
                return
            end

            if Method == "Free" then
                local OldCFrame = Player.Character.HumanoidRootPart.CFrame
                Player:LoadCharacter()

                repeat
                    task.wait()
                until Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                Player.Character.HumanoidRootPart.CFrame = OldCFrame

                return
            end

            if not Target or not Target.Character then
                return
            end
            if Player == Target then
                return
            end

            -- Prevent duplicate requests
            if Player:GetAttribute("CollarRequesting") == Target.Name then
                Networking:Fire(
                    Player,
                    "Request",
                    "Error",
                    "You're already requesting this person, wait for them to accept."
                )
                return
            end

            if Method == "Request" then
                if Player.Character:FindFirstChild("Collar") or Target.Character:FindFirstChild("Collar") then
                    Networking:Fire(
                        Player,
                        "Request",
                        "Error",
                        "You can't request this user at this time, try again later."
                    )
                    return
                end

                Player:SetAttribute("CollarRequesting", Target.Name)
                Networking:Fire(Target, "Request", "Collar", Player.Name .. " has sent you a collar request.", Player)

                return
            end

            if Method == "Accept" then
                -- Verify mutual request
                if
                    Target:GetAttribute("CollarRequesting") ~= Player.Name and
                        Player:GetAttribute("CollarRequesting") ~= Target.Name
                 then
                    return
                end

                -- Clear request attributes
                Target:SetAttribute("CollarRequesting", nil)
                Player:SetAttribute("CollarRequesting", nil)

                -- Create the collar link and notify both players
                local MasterPlayer = Target
                local MasterCharacter = Target.Character

                local TargetPlayer = Player
                local TargetCharacter = Player.Character

                Networking:Fire(Target, "Request", "Notice", string.format("Successfully collared %s!", Player.Name))
                Networking:Fire(
                    Player,
                    "Request",
                    "Notice",
                    string.format("Successfully got collared by %s!", Target.Name)
                )

                Player.Character.AncestryChanged:Connect(
                    function()
                        local OldCFrame = Target.Character.HumanoidRootPart.CFrame
                        Target:LoadCharacter()

                        repeat
                            task.wait()
                        until Target.Character and Target.Character:FindFirstChild("HumanoidRootPart")
                        Target.Character.HumanoidRootPart.CFrame = OldCFrame
                    end
                )

                Player.Character.Humanoid.Died:Connect(
                    function()
                        local OldCFrame = Target.Character.HumanoidRootPart.CFrame
                        Target:LoadCharacter()

                        repeat
                            task.wait()
                        until Target.Character and Target.Character:FindFirstChild("HumanoidRootPart")
                        Target.Character.HumanoidRootPart.CFrame = OldCFrame
                    end
                )

                return
            end

            if Method == "Decline" or Method == "Expired" then
                Networking:Fire(
                    Target,
                    "Request",
                    "Notice",
                    Method == "Decline" and string.format("%s declined your collar request.", Target.Name) or
                        string.format("Your collar request to %s expired.", Target.Name)
                )

                Target:SetAttribute("CollarRequesting", nil)
                Player:SetAttribute("CollarRequesting", nil)

                return
            end
        end
    )

    Networking:On(
        "Morph",
        function(Player)
            if not Flood:Check(Player, "Morph", 1) then
                return
            end

            if not Player then
                return
            end
            if not Player.Character then
                return
            end

            if not Player:GetAttribute("Age") then
                return
            end
            if not Player:GetAttribute("Gender") then
                return
            end

            if not Player.Character:FindFirstChild("Body") then
                return Controller.CreateApplies(Player.Character, Player:GetAttribute("Gender"))
            end
            if Player.Character:FindFirstChild("Body") then
                return Controller.RemoveApplies(Player.Character)
            end
        end
    )

    Networking:On(
        "Avatar",
        function(Player, Username)
            if Player:GetAttribute("MorphUserId") then
                return
            end

            local Success, UserId = pcall(Players.GetUserIdFromNameAsync, Players, Username)

            if (Success) then
                Player:SetAttribute("MorphUserId", UserId)

                local SuccessDescription, Description = pcall(Players.GetHumanoidDescriptionFromUserId, Players, UserId)

                if (SuccessDescription) then
                    local Humanoid = Player.Character:WaitForChild("Humanoid")

                    if (Humanoid) then
                        Humanoid:ApplyDescription(Description)
                    end
                else
                    Networking:Fire(
                        Player,
                        "Request",
                        "Error",
                        "Something went wrong while trying to obtain the selected character"
                    )
                    error(
                        "[XYZ::Network::Avatar] Something went wrong while trying to obtain humanoid description: " ..
                            tostring(Description)
                    )
                    return
                end
            else
                if (UserId == "Players:GetUserIdFromNameAsync() failed: Unknown user") then
                    Networking:Fire(
                        Player,
                        "Request",
                        "Error",
                        "We didn't find any valid results out of that username, make sure it's an existing player"
                    )
                    return
                end

                Networking:Fire(
                    Player,
                    "Request",
                    "Error",
                    "Something went wrong while trying to obtain this username information, try again"
                )
                error(
                    "[XYZ::Network::Avatar] Something went wrong while trying to obtain the player user id out of username: " ..
                        tostring(UserId)
                )
                return
            end
        end
    )

    Networking:On(
        "Unlink",
        function(Player, Method)
            if not Flood:Check(Player, "Mate", 1) then
                return
            end

            if not Player then
                return
            end
            if not Player.Character then
                return
            end
            if not Player.Character:FindFirstChild("Scene") then
                return
            end

            if Method == "Bot" then
                local Scene = Workspace.Scenes:FindFirstChild(Player.Name .. "-SCENE")

                if not Scene then
                    return
                end
                if not string.find(Scene.Target.Value.Name, "-BOT") then
                    return
                end

                Controller.RemoveScene(Workspace.Scenes:FindFirstChild({Player.Name} .. "SCENE"))
            end

            if Method == "Human" then
                local Scene = Player.Character.Scene.Value
                local Master = Scene.Master.Value
                local Target = Scene.Target.Value

                if string.find(Master.Name, "-BOT") then
                    return
                end
                if string.find(Target.Name, "-BOT") then
                    return
                end

                if Workspace.Scenes:FindFirstChild(Player.Name .. "-SCENE") then
                    Controller.RemoveScene(Workspace.Scenes:FindFirstChild(Player.Name .. "-SCENE"))
                end
                if Workspace.Scenes:FindFirstChild(Target.Name .. "-SCENE") then
                    Controller.RemoveScene(Workspace.Scenes:FindFirstChild(Target.Name .. "-SCENE"))
                end
            end
        end
    )

    Networking:On(
        "Buzz",
        function(Player)
            local LastBuzz = os.time()
            local OldBuzz = Player:GetAttribute("LastBuzz")

            if (typeof(OldBuzz) == "number" and typeof(LastBuzz) == "number") then
                if ((LastBuzz - OldBuzz) < 15) then
                    Networking:Fire(Player, "Request", "Error", "You have finished too recently! Give it a rest..")
                    return
                end
            end

            if not Player then
                return
            end
            if not Player.Character then
                return
            end
            if not Player.Character:FindFirstChild("Scene") then
                return
            end

            -- Variables
            local Scene = Controller.GetScene(Player)

            local Target = Players:GetPlayerFromCharacter(Scene.Target.Value)
            local Master = Players:GetPlayerFromCharacter(Scene.Master.Value)

            -- Showing the scene to both players

            Scene.Master.Animation.Value.Paused.Value = true
            Scene.Target.Animation.Value.Paused.Value = true

            if not (Target == nil) then
                Networking:Fire(Target, "Buzz")
            end

            if not (Master == nil) then
                Networking:Fire(Master, "Buzz")
            end

            task.wait(3)

            Scene.Master.Animation.Value.Paused.Value = false
            Scene.Target.Animation.Value.Paused.Value = false

            Player:SetAttribute("LastBuzz", os.time())
        end
    )

    Networking:On(
        "Room",
        function(Player, Method, ...)
            if not Player then
                return
            end
            if not Player.Character then
                return
            end

            local Arguments = {...}

            if Method == "Erase" then
                Controller.RemoveRoom(Player)
            end

            if Method == "Create" then
                Controller.CreateRoom(Player, Arguments[1], Arguments[2])
            end

            if Method == "Teleport" then
                Controller.TeleportRoom(Player, Arguments[1])
            end
        end
    )

    Networking:On(
        "Mate",
        function(Player, Method, Target)
            if not Flood:Check(Player, "Mate", 1) then
                return
            end

            if not Player then
                return
            end
            if not Player.Character then
                return
            end

            if not Target then
                return
            end
            if not Target.Character then
                return
            end

            if not Target then
                return
            end
            if Player == Target then
                return
            end

            if not Player:GetAttribute("Age") then
                return
            end
            if not Player:GetAttribute("Gender") then
                return
            end
            if not Target:IsA("Player") then
                return
            end

            if (Player:GetAttribute("Requesting") == Target.Name) then
                Networking:Fire(
                    Player,
                    "Request",
                    "Error",
                    "You're already requesting this person, wait the person to accept."
                )

                return
            end

            if Player.Character:FindFirstChild("Scene") or Target.Character:FindFirstChild("Scene") then
                Networking:Fire(
                    Player,
                    "Request",
                    "Error",
                    "You can't request this user at this time, try again later."
                )

                return
            end

            if Method == "Request" then
                if Target.Character.Gender.Value == "Female" and Player.Character.Gender.Value == "Female" then
                    return Networking:Fire(
                        Player,
                        "Request",
                        "Error",
                        "You can't request this player, female with female interactions are not done yet."
                    )
                end

                Player:SetAttribute("Requesting", Target.Name)
                Networking:Fire(Target, "Request", "Notify", Player.Name)

                return
            end

            if Method == "Accept" then
                if Target:GetAttribute("Requesting") ~= Player.Name and Player:GetAttribute("Requesting") ~= Target.Name then
                    return
                end

                Target:SetAttribute("Requesting", nil)
                Player:SetAttribute("Requesting", nil)

                if Target.Character.Gender.Value == "Female" and Player.Character.Gender.Value == "Female" then
                    return Networking:Fire(
                        Player,
                        "Request",
                        "Error",
                        "You can't request this player, female with female interactions are not done yet."
                    )
                end

                local MasterPlayer = Target
                local MasterCharacter = Target.Character

                local TargetPlayer = Player
                local TargetCharacter = Player.Character

                Controller.CreateScene("Duo", MasterCharacter, TargetCharacter)
                Networking:FireAll("Update", MasterCharacter, MasterCharacter.HumanoidRootPart.CFrame)
                Networking:FireAll("Update", TargetCharacter, MasterCharacter.HumanoidRootPart.CFrame)

                Networking:Fire(Player, "Request", "Notice", string.format("Successfully linked with %s!", Target.Name))
                Networking:Fire(Target, "Request", "Notice", string.format("Successfully linked with %s!", Player.Name))

                return
            end

            if Method == "Decline" or Method == "Expired" then
                Networking:Fire(
                    Target,
                    "Request",
                    "Notice",
                    Method == "Decline" and string.format("%s declined your request.", Target.Name) or
                        string.format("request to %s expired.", Target.Name)
                )

                Target:SetAttribute("Requesting", nil)
                Player:SetAttribute("Requesting", nil)

                return
            end
        end
    )

    Networking:On(
        "Bot",
        function(Player, Method, Name)
            if not Flood:Check(Player, "Bot", 1) then
                return
            end

            if not Player then
                return
            end
            if not Player.Character then
                return
            end

            if not Player:GetAttribute("Age") then
                return
            end
            if not Player:GetAttribute("Gender") then
                return
            end

            Method = Method
            Name = Name and Name or nil

            if Method == "Create" then
                local Bot = Controller.CreateBot(Player.Character, Name)
                local Scene = Controller.CreateScene("Duo", Player.Character, Bot)

                Networking:FireAll("Update", Player.Character, Player.Character.HumanoidRootPart.CFrame)
            end
        end
    )

    Networking:On(
        "Animation",
        function(Player, Method, ...)
            if not Flood:Check(Player, "Animation", 1) then
                return
            end

            if not Player then
                return
            end
            if not Player.Character then
                return
            end
            if not Player.Character:FindFirstChild("Scene") then
                return
            end

            if Player.Character:GetAttribute("Buzz") == true then
                return Networking:Fire(Player, "Request", "Error", "You can't change anything at this moment.")
            end

            local Arguments = {...}

            if Method == "Speed" then
                Controller.UpdateScene(Player.Character, "Speed", Arguments[1])
            end

            if Method == "Update" then
                Controller.UpdateScene(Player.Character, "Animation", Arguments[1])
            end

            if Method == "Transfer" then
                Controller.UpdateScene(Player.Character, "Master")
            end
        end
    )

    RunService.Stepped:Connect(
        function()
            for i, v in next, CollectionService:GetTagged("Entities") do
                if not v.Name == "Torso" and not v.Name == "HumanoidRootPart" then
                    v.CanCollide = false
                end
            end
        end
    )
end

NetworkingHandler.Init()
return NetworkingHandler
