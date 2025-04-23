_G.Controller = {}
local Controller = _G.Controller

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local ServerModules = ServerStorage:WaitForChild("Modules")
local ReplicatedModules = ReplicatedStorage:WaitForChild("Modules")
local Storage = ServerStorage.Storage

local FX = require(ServerModules:WaitForChild("Effects"))
local Animation = require(ServerModules:WaitForChild("Animation"))
local InsideBoundary = require(ServerModules:WaitForChild("InsideBoundary"))

if not PhysicsService:IsCollisionGroupRegistered("Entities") then
    PhysicsService:RegisterCollisionGroup("Entities")
    PhysicsService:CollisionGroupSetCollidable("Entities", "Entities", false)
end

local Opposites = {
    ["Male"] = "Female",
    ["Female"] = "Male",
    ["Futa"] = "Female",
    ["Femboy"] = "Male"
}

local function FindWhatValue(Method, ...)
    local Args = {...}
    local GenderMappings = {
        FM = "Female",
        ML = "Male",
        FT = "Futa",
        FB = "Femboy"
    }

    if Method == "Side" then
        local One = Args[1]
        local Two = Args[2]

        if One == "Female" then
            if Two == "Male" or Two == "Futa" or Two == "Femboy" then
                return "Bottom"
            else
                return "Top"
            end
        elseif One == "Male" then
            if Two == "Female" or Two == "Futa" or Two == "Femboy" then
                return "Top"
            else
                return "Bottom"
            end
        elseif One == "Futa" then
            if Two == "Female" or Two == "Futa" or Two == "Femboy" then
                return "Top"
            else
                return "Bottom"
            end
        elseif One == "Femboy" then
            if Two == "Female" or Two == "Futa" then
                return "Top"
            else
                return "Bottom"
            end
        else
            return "Top"
        end
    elseif Method == "Type" then
        local Input = Args[1]

        for Key, Value in pairs(GenderMappings) do
            if Value == Input then
                return Key
            end
        end
    end
end

local function GenerateRoomPosition(existingRooms, minDistance)
    local position
    local isOverlapping = true

    while isOverlapping do
        position = Vector3.new(500 + math.random(-9500, 4000), -100, 500 + math.random(-9500, 4000))
        isOverlapping = false

        for _, room in ipairs(existingRooms) do
            if (room.Primary.Position - position).Magnitude < minDistance then
                isOverlapping = true
                break
            end
        end
    end

    return position
end

Controller.CreateRoom = function(Master, Name, Allowed)
    if not Master or not Name then
        return
    end
    if Workspace.Rooms:FindFirstChild(Master.Name .. "-ROOM") then
        return
    end
    if not ReplicatedStorage.Rooms:FindFirstChild(Name) then
        return
    end

    local Room = ReplicatedStorage.Rooms[Name]:Clone()
    Room.Name = Master.Name .. "-ROOM"
    Room.TP.Transparency = 1
    Room.TP.CanCollide = false

    local existingRooms = Workspace.Rooms:GetChildren()
    Room:SetPrimaryPartCFrame(CFrame.new(GenerateRoomPosition(existingRooms, 50)))

    if Allowed then
        local AllowedValue = Instance.new("ObjectValue")
        AllowedValue.Value = Allowed
        AllowedValue.Name = "Allowed"
        AllowedValue.Parent = Room
    end

    Room.Parent = Workspace.Rooms
    Master.Character.HumanoidRootPart.CFrame = Room.TP.CFrame
end

Controller.RemoveRoom = function(Master)
    if not Master then
        return
    end
    if Master.Character:FindFirstChild("Scene") then
        return
    end
    if not Workspace.Rooms:FindFirstChild(Master.Name .. "-ROOM") then
        return
    end

    local Room = Workspace.Rooms:FindFirstChild(Master.Name .. "-ROOM")

    for i, v in next, Workspace:GetChildren() do
        if Players:FindFirstChild(v.Name) then
            if InsideBoundary.Intersects(v, Room, 1.0023) then
                Players[v.Name]:LoadCharacter()
            end
        end
    end

    Room:Destroy()
end

Controller.TeleportRoom = function(Target, Master)
    if not Target then
        Target = Master
    end

    if not Workspace.Rooms:FindFirstChild(Master.Name .. "-ROOM") then
        return
    end
    if not Target.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    if Master.Character:FindFirstChild("Scene") then
        return
    end

    local Room = Workspace.Rooms:FindFirstChild(Master.Name .. "-ROOM")

    if Room.Allowed.Value == Target or Master == Target then
        Target.Character.HumanoidRootPart.CFrame = Room.TP.CFrame
    end
end

Controller.CreateRig = function(Character, ID)
    if not ID then
        return
    end

    local Name = Players:GetNameFromUserIdAsync(ID)
    local Success, Description = pcall(Players.GetHumanoidDescriptionFromUserId, Players, ID)

    if not Success then
        Description = Storage.Extra.DefaultDescription:Clone()
        Name = "Deleted User " .. ID
    end

    Description.Torso = 0
    Description.LeftArm = 0
    Description.RightArm = 0
    Description.LeftLeg = 0
    Description.RightLeg = 0
    local Success, Created =
        pcall(Players.CreateHumanoidModelFromDescription, Players, Description, Enum.HumanoidRigType.R6)

    if not Success then
        return
    end

    local Humanoid = Created:FindFirstChildOfClass("Humanoid")
    Humanoid.NameDisplayDistance = 0
    Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

    local Tag = Storage.Extra.Info:Clone()
    Tag.Main.User.Text = Name

    Tag.Main.Tags.Age.Visible = false
    Tag.Main.Tags.Gender.Visible = true
    Tag.Main.Tags.Gender.Label.Text = "  BOT  "
    Tag.Main.Tags.Gender.BackgroundColor3 = Color3.fromRGB(86, 221, 165)

    Tag.Parent = Created.Head
    Tag.Adornee = Created.Head
    Created.PrimaryPart = Created.HumanoidRootPart

    return Created
end

Controller.CreateBot = function(Master, Target)
    local Success, ID =
        pcall(
        function()
            return Players:GetUserIdFromNameAsync(Target)
        end
    )

    if not Success then
        return
    end
    if not Master:FindFirstChild("Gender") then
        return
    end

    local NPC = Controller.CreateRig(Master, ID)
    NPC.Name = string.format("%s-BOT", Master.Name)
    NPC.Parent = Workspace

    local Gender = Instance.new("StringValue")
    Gender.Name = "Gender"
    Gender.Value = Opposites[Master.Gender.Value]
    Gender.Parent = NPC

    for Index, Object in next, NPC:GetDescendants() do
        if Object:IsA("Part") or Object:IsA("MeshPart") then
            Object.CollisionGroup = "Entities"
        end
    end

    return NPC
end

Controller.CreateScene = function(Type, Master, Target)
    if Master:FindFirstChild("Scene") then
        return
    end
    if Target:FindFirstChild("Scene") then
        return
    end

    local Scene = nil

    if Type == "Duo" then
        Scene = Storage.Extra.Controller.Duo:Clone()
        Scene.Name = Master.Name .. "-SCENE"

        Scene.Target.Value = Target
        Scene.Master.Value = Master

        local CurrentSceneMaster = Instance.new("ObjectValue")
        CurrentSceneMaster.Name = "Scene"
        CurrentSceneMaster.Value = Scene
        CurrentSceneMaster.Parent = Master

        local CurrentSceneTarget = Instance.new("ObjectValue")
        CurrentSceneTarget.Name = "Scene"
        CurrentSceneTarget.Value = Scene
        CurrentSceneTarget.Parent = Target

        local GenderOne = Master.Gender.Value
        local GenderTwo = Target.Gender.Value

        local Directory =
            (GenderOne == GenderTwo) and ((GenderOne == "Female" or GenderOne == "Male") and "Solo" or "Same") or
            "Different"
        local Subdirectory = ReplicatedStorage.Animations[Directory]
        local Main = nil

        for i, Folder in next, Subdirectory:GetChildren() do
            Main = Folder

            break
        end

        local LoadedOne = Animation.LoadAnimation(Master, Main[FindWhatValue("Side", GenderOne, GenderTwo)])
        local LoadedTwo = Animation.LoadAnimation(Target, Main[FindWhatValue("Side", GenderTwo, GenderOne)])

        Scene.Master.Animation.Value = LoadedOne
        Scene.Target.Animation.Value = LoadedTwo

        Master:SetPrimaryPartCFrame(Master.HumanoidRootPart.CFrame)
        Controller.CreateApplies(Master, GenderOne)
        Animation.Play(LoadedOne)

        Target:SetPrimaryPartCFrame(Master.HumanoidRootPart.CFrame)
        Controller.CreateApplies(Target, GenderTwo)
        Animation.Play(LoadedTwo)

        Master.Humanoid.WalkSpeed = 3
        Master.Humanoid.JumpPower = 0
        Master.Humanoid.AutoRotate = true

        Target.Humanoid.AutoRotate = false
        Target.Humanoid.JumpPower = 0
        Target.Humanoid.AutoRotate = false

        Scene.Holder.Part0 = Master.HumanoidRootPart
        Scene.Holder.Part1 = Target.HumanoidRootPart
    end

    Scene.Parent = Workspace.Scenes

    return Scene
end

Controller.GetScene = function(Player)
    local Scene
    if not Player then
        return
    end

    for i, v in next, Workspace.Scenes:GetChildren() do
        if v:FindFirstChild("Master") and v:FindFirstChild("Target") then
            if v.Master.Value == Player.Character or v.Target.Value == Player.Character then
                Scene = v
                break
            end
        end
    end

    return Scene
end

Controller.RemoveScene = function(Folder)
    if not Workspace.Scenes:FindFirstChild(Folder.Name) then
        return
    end

    if Folder.Type.Value == "Duo" then
        local LoadedOne = Folder.Master.Animation.Value
        local LoadedTwo = Folder.Target.Animation.Value

        local Master = Folder.Master.Value
        local Target = Folder.Target.Value

        if LoadedOne then
            Animation.Clear(LoadedOne)
        end
        if LoadedTwo then
            Animation.Clear(LoadedTwo)
        end

        Controller.RemoveApplies(Master)
        Controller.RemoveApplies(Target)

        if Master then
            Master.Scene:Destroy()
            Master.Humanoid.AutoRotate = true
            Master.Humanoid.WalkSpeed = 16
            Master.Humanoid.JumpPower = 50
        end

        if Target then
            Target.Scene:Destroy()
            Target.Humanoid.AutoRotate = true
            Target.Humanoid.WalkSpeed = 16
            Target.Humanoid.JumpPower = 50

            if string.find(Target.Name, "-BOT") then
                Target:Destroy()
            end
        end

        Folder:Destroy()

        return
    end

    if Folder.Type.Value == "Solo" then
        local Loaded = Folder.Master.Animation.Value
        local Master = Folder.Master.Value

        Animation.Clear(Loaded)
        Controller.RemoveApplies(Master)
        Master.Scene:Destroy()

        Master.HumanoidRootPart.Anchored = false
        Master.Humanoid.AutoRotate = true

        return
    end
end

Controller.UpdateScene = function(Master, Method, ...)
    local Method = Method
    local Arguments = {...}

    if not Workspace.Scenes:FindFirstChild(Master.Name .. "-SCENE") then
        return
    end

    if Method == "Animation" then
        local Folder = Workspace.Scenes:FindFirstChild(Master.Name .. "-SCENE")

        if not Folder then
            return
        end

        local LoadedOne = Folder.Master.Animation
        local LoadedTwo = Folder.Target.Animation

        local Master = Folder.Master.Value
        local Target = Folder.Target.Value

        local GenderMaster = Master.Gender.Value
        local GenderTarget = Target.Gender.Value

        local Pattern1 = GenderMaster .. "%-" .. GenderTarget
        local Pattern2 = GenderTarget .. "%-" .. GenderMaster

        local Directory =
            (GenderMaster == GenderTarget) and
            ((GenderMaster == "Female" or GenderMaster == "Male") and "Solo" or "Same") or
            "Different"
        local Subdirectory = ReplicatedStorage.Animations[Directory]:FindFirstChild(Arguments[1])

        if not Pattern1 then
            return
        end
        if not Pattern2 then
            return
        end
        if
            not string.find(Subdirectory.Allowed.Value, Pattern1) and
                not string.find(Subdirectory.Allowed.Value, Pattern2)
         then
            return
        end

        local OldSpeed = LoadedOne.Value.Speed.Value or LoadedTwo.Value.Speed.Value

        Animation.Clear(LoadedOne.Value)
        Animation.Clear(LoadedTwo.Value)

        local LoadedNewOne =
            Animation.LoadAnimation(Master, Subdirectory[FindWhatValue("Side", GenderMaster, GenderTarget)])
        local LoadedNewTwo =
            Animation.LoadAnimation(Target, Subdirectory[FindWhatValue("Side", GenderTarget, GenderMaster)])

        LoadedNewOne.Speed.Value = OldSpeed
        LoadedNewTwo.Speed.Value = OldSpeed

        LoadedOne.Value = LoadedNewOne
        LoadedTwo.Value = LoadedNewTwo

        Folder.Animation.Value = Subdirectory.Name

        Animation.Play(LoadedNewOne)
        Animation.Play(LoadedNewTwo)

        return
    end

    if Method == "Speed" then
        local Folder = Workspace.Scenes:FindFirstChild(Master.Name .. "-SCENE")

        local LoadedOne = Folder.Master.Animation.Value
        local LoadedTwo = Folder.Target.Animation.Value

        if not LoadedOne or not LoadedTwo then
            return
        end

        LoadedOne.Speed.Value = Arguments[1]
        LoadedTwo.Speed.Value = Arguments[1]

        return
    end

    if Method == "Master" then
        local Folder = Workspace.Scenes:FindFirstChild(Master.Name .. "-SCENE")

        local Master = Folder.Master.Value
        local Target = Folder.Target.Value

        if string.find(Target.Name, "-BOT") then
            return
        end

        Folder.Master.Value = Target
        Folder.Target.Value = Master
        Folder.Name = Target.Name .. "-SCENE"

        Folder.Master.Value.Humanoid.WalkSpeed = 3
        Folder.Master.Value.Humanoid.JumpPower = 0
        Folder.Master.Value.Humanoid.AutoRotate = true

        Folder.Target.Value.Humanoid.WalkSpeed = 0
        Folder.Target.Value.Humanoid.JumpPower = 0
        Folder.Target.Value.Humanoid.AutoRotate = false

        return
    end
end

Controller.CreateApplies = function(Character, Type)
    if not Character then
        return {Success = false, Message = string.format("Character Does not exist.")}
    end
    if typeof(Character) ~= "Instance" then
        return {Success = false, Message = string.format("Character is not an instance.")}
    end
    if not Storage.Rigs:FindFirstChild(FindWhatValue("Type", Type)) then
        return {Success = false, Message = string.format("Type Argument: %s Does not exist.", Type)}
    end

    Controller.RemoveApplies(Character)
    FX("Smoke", Character)

    local Rig = Storage.Rigs:FindFirstChild(FindWhatValue("Type", Type)):FindFirstChild("Body"):Clone()
    Rig.Parent = Character

    local Folder = Character:FindFirstChild("Clothing") or Instance.new("Folder")
    Folder.Parent = Character
    Folder.Name = "Clothing"

    local Meshes = Character:FindFirstChild("Meshes") or Instance.new("Folder")
    Meshes.Parent = Character
    Meshes.Name = "Meshes"

    local Head = Character:FindFirstChild("Head")
    local Torso = Character:FindFirstChild("Torso")

    local LeftArm = Character:FindFirstChild("Left Arm")
    local RightArm = Character:FindFirstChild("Right Arm")

    local LeftLeg = Character:FindFirstChild("Left Leg")
    local RightLeg = Character:FindFirstChild("Right Leg")

    local Shirt = Character:FindFirstChild("Shirt") or Folder:FindFirstChild("Shirt") or nil
    local Pants = Character:FindFirstChild("Pants") or Folder:FindFirstChild("Pants") or nil
    local TShirt = Character:FindFirstChild("Shirt Graphic") or Folder:FindFirstChild("Shirt Graphic") or nil
    local Colors = {
        HeadColor3 = Head.Color,
        TorsoColor3 = Torso.Color,
        RightArmColor3 = RightArm.Color,
        LeftArmColor3 = LeftArm.Color,
        RightLegColor3 = RightLeg.Color,
        LeftLegColor3 = LeftLeg.Color
    }

    local Hue, Saturation, Value = Colors["TorsoColor3"]:ToHSV()
    Value = math.clamp(Value - 0.2, 0, 1)
    local Saturated = Color3.fromHSV(Hue, Saturation, Value)
    Colors["Saturated"] = Saturated

    for _, Object in next, Character:GetChildren() do
        if Object:IsA("CharacterMesh") then
            Object.Parent = Meshes
        end
    end

    if Shirt then
        Shirt.Parent = Folder
    end
    if Pants then
        Pants.Parent = Folder
    end
    if TShirt then
        TShirt.Parent = Folder
    end

    do
        Head.Transparency = 0
        Torso.Transparency = 0

        LeftArm.Transparency = 0
        RightArm.Transparency = 0

        LeftLeg.Transparency = 0
        RightLeg.Transparency = 0
    end

    for i, BodyPart in next, Character:GetChildren() do
        if BodyPart:IsA("Part") then
            if Rig:FindFirstChild(string.format("%s Weld", BodyPart.Name)) then
                local Weld = Rig:FindFirstChild(string.format("%s Weld", BodyPart.Name))
                local Body = Rig:FindFirstChild(string.format("%s Body", BodyPart.Name))

                BodyPart.Transparency = 1
                Body.CFrame = BodyPart.CFrame
                Body.Color = Colors[string.format("%sColor3", string.gsub(BodyPart.Name, " ", ""))]

                Weld.Part0 = BodyPart
                Weld.Part1 = Body
                Weld.Enabled = true
            end
        end
    end

    for i, Motor in next, Rig["Motors"]:GetChildren() do
        if Motor:IsA("Motor6D") then
            Motor.Part0 = Torso
        end
    end

    for i, Part in next, Rig["Muscles"]:GetChildren() do
        if string.find(Part.Name, "Muscle") then
            Part["Color"] = Colors["TorsoColor3"]
        end

        if string.find(Part.Name, "Formula") then
            Part["Areola 1"]["Color3"] = Colors["Saturated"]
            Part["Areola 2"]["Color3"] = Colors["Saturated"]
            Part["Generators"]["Color"] = Colors["Saturated"]
            Part["Color"] = Colors["TorsoColor3"]
        end

        if string.find(Part.Name, "Longers") then
            for i, v in next, Part:GetChildren() do
                if v.Name ~= "Darker" then
                    -- continue
                else
                    v["Color3"] = Colors["Saturated"]
                end
            end

            Part["Dongle"]["Color"] = Colors["Saturated"]
            Part["Point"]["Color"] = Colors["Saturated"]
            Part["Color"] = Colors["TorsoColor3"]
        end

        if string.find(Part.Name, "no") then
            Part["no1"]["Color"] = Colors["TorsoColor3"]
            Part["no2"]["Color"] = Colors["TorsoColor3"]
            Part["Color"] = Colors["TorsoColor3"]
        end
    end

    return {Success = true, Message = string.format("Successfully applied a %s rig on %s's", Type, Character.Name)}
end

Controller.RemoveApplies = function(Character)
    if not Character then
        return {Success = false, Message = string.format("Character Does not exist.")}
    end
    if typeof(Character) ~= "Instance" then
        return {Success = false, Message = string.format("Character is not an instance.")}
    end
    if not Character:FindFirstChild("Body") then
        return {Success = false, Message = string.format("Character does not have any rig's applied.")}
    end

    local Body = Character:FindFirstChild("Body")
    local Folder = Character:FindFirstChild("Clothing")
    local Meshes = Character:FindFirstChild("Meshes") or Instance.new("Folder")

    local Shirt = Folder:FindFirstChild("Shirt") or nil
    local Pants = Folder:FindFirstChild("Pants") or nil
    local TShirt = Folder:FindFirstChild("Shirt Graphic") or nil

    local Head = Character:FindFirstChild("Head")
    local Torso = Character:FindFirstChild("Torso")

    local LeftArm = Character:FindFirstChild("Left Arm")
    local RightArm = Character:FindFirstChild("Right Arm")

    local LeftLeg = Character:FindFirstChild("Left Leg")
    local RightLeg = Character:FindFirstChild("Right Leg")

    for _, Object in next, Meshes:GetChildren() do
        if Object:IsA("CharacterMesh") then
            Object.Parent = Character
        end
    end

    if Shirt then
        Shirt.Parent = Character
    end
    if Pants then
        Pants.Parent = Character
    end
    if TShirt then
        TShirt.Parent = Character
    end

    if Head then
        Head.Transparency = 0
    end
    if Torso then
        Torso.Transparency = 0
    end
    if LeftArm then
        LeftArm.Transparency = 0
    end
    if RightArm then
        RightArm.Transparency = 0
    end
    if LeftLeg then
        LeftLeg.Transparency = 0
    end
    if RightLeg then
        RightLeg.Transparency = 0
    end

    Body:Destroy()
    Folder:Destroy()

    return {Success = true, Message = string.format("Successfully removed rig from %s's", Character.Name)}
end

Controller.CreateAccessory = function(Character)
end
