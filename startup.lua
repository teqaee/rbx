local StartupHandler = {}
local Connections = {}
local SortedTabs = {}
local Draggables = {}

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Modules = ReplicatedStorage:WaitForChild("Modules")

local Red = require(Modules.Red)
local Icon = require(Modules.Icon)
local Dragify = require(Modules.DraggableObject)
local Net = Red.Client("Network")

local Client = Players.LocalPlayer
local Mouse = Client:GetMouse()

local AddConnection = function(Object, Function, Name)
    local Result = Object:Connect(Function)

    if Name then
        Connections[Name] = Result
    else
        table.insert(Connections, Result)
    end

    return Result
end

local ClearConnection = function(Name)
    if not Connections[Name] then
        return
    end

    Connections[Name]:Disconnect()
    Connections[Name] = nil
end

local ClearConnections = function()
    for i, v in next, Connections do
        v:Disconnect()
    end
end

local Sound = function(Id)
    local SoundEffect = Instance.new("Sound")
    SoundEffect.SoundId, SoundEffect.PlayOnRemove, SoundEffect.Volume, SoundEffect.Parent, SoundEffect.Name =
        Id,
        true,
        .7,
        workspace,
        "?"
    SoundEffect:Destroy()
end

local Tween = function(Object, Info, Properties, Wait)
    local Tween = TweenService:Create(Object, Info, Properties)
    Tween:Play()

    if Wait then
        Tween.Completed:Wait()
    end
end

local Ripple = function(Object, Duration)
end

StartupHandler.Init = function()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

    local Scene = ReplicatedStorage:WaitForChild("GUIs"):FindFirstChild("Scene")
    Scene.Parent = Client.PlayerGui

    local Authorize = ReplicatedStorage:WaitForChild("GUIs"):FindFirstChild("Authorize")
    Authorize.Parent = Client.PlayerGui

    local Blur = Instance.new("BlurEffect")
    Blur.Size = 50
    Blur.Parent = game.Workspace.CurrentCamera

    repeat
        RunService.Heartbeat:Wait()
    until game:IsLoaded()

    Players.LocalPlayer:GetAttributeChangedSignal("BeingRaped"):Connect(
        function()
            if Players.LocalPlayer:GetAttribute("BeingRaped") then
                RunService.RenderStepped:Wait()
                game:GetService("StarterGui"):SetCore("ResetButtonCallback", false)
            else
                RunService.RenderStepped:Wait()
                game:GetService("StarterGui"):SetCore("ResetButtonCallback", true)
            end
        end
    )

    Net:On(
        "Update",
        function(Character, Origin)
            Character:SetPrimaryPartCFrame(Origin)
        end
    )

    Net:On(
        "Buzz",
        function(TransparencyValue, StartDuration, WaitDuration, EndDuration, FOVDecrease)
            TransparencyValue = TransparencyValue or 0.5
            StartDuration = StartDuration or 1
            WaitDuration = WaitDuration or 3
            EndDuration = EndDuration or 0.5
            FOVDecrease = FOVDecrease or 5

            local FOV = workspace.CurrentCamera.FieldOfView

            local End = TweenInfo.new(EndDuration, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
            local Start = TweenInfo.new(StartDuration, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

            local FOVStart = TweenInfo.new(StartDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            local FOVEnd = TweenInfo.new(EndDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

            task.spawn(
                function()
                    TweenService:Create(Scene.Frame, Start, {ImageTransparency = TransparencyValue}):Play()
                    task.wait(WaitDuration + StartDuration)
                    TweenService:Create(Scene.Frame, End, {ImageTransparency = 1}):Play()
                end
            )

            task.spawn(
                function()
                    TweenService:Create(workspace.CurrentCamera, FOVStart, {FieldOfView = FOV - FOVDecrease}):Play()
                    task.wait(WaitDuration + StartDuration)
                    TweenService:Create(workspace.CurrentCamera, FOVEnd, {FieldOfView = FOV}):Play()
                end
            )
        end
    )

    Net:On(
        "Request",
        function(Event, Args1, Args2, Args3, Args4)
            Sound("rbxassetid://7218169592")

            if (Event == "Collar") then
                local Callback = Instance.new("BindableFunction")
                Callback.Parent = workspace.CurrentCamera

                Callback.OnInvoke = function(Result)
                    if Result == "Yes" then
                        Net:Fire("Collar", "Accept", Args2)
                    end

                    if Result == "No" then
                        Net:Fire("Collar", "Decline", Args2)
                    end

                    Callback:Destroy()
                end

                StarterGui:SetCore(
                    "SendNotification",
                    {
                        Title = "XYZ | Collar",
                        Text = tostring(Args1) .. " would like to collar you. Accept?",
                        Duration = 15,
                        Button1 = "Yes",
                        Button2 = "No",
                        Callback = Callback
                    }
                )

                task.delay(
                    15,
                    function()
                        if Callback.Parent == nil then
                            return
                        end

                        Net:Fire("Collar", "Expired", Args2)
                    end
                )

                return
            end

            if (Event == "Notify") then
                local Callback = Instance.new("BindableFunction")
                Callback.Parent = workspace.CurrentCamera

                Callback.OnInvoke = function(Result)
                    if Result == "Yes" then
                        Net:Fire("Mate", "Accept", Players[Args1])
                    end

                    if Result == "No" then
                        Net:Fire("Mate", "Decline", Players[Args1])
                    end

                    Callback:Destroy()
                end

                StarterGui:SetCore(
                    "SendNotification",
                    {
                        Title = "XYZ | Link",
                        Text = tostring(Args1) .. " would like to link with you. Accept?",
                        Duration = 15,
                        Button1 = "Yes",
                        Button2 = "No",
                        Callback = Callback
                    }
                )

                task.delay(
                    15,
                    function()
                        if Callback.Parent == nil then
                            return
                        end

                        Net:Fire("Mate", "Expired", Players[Args1])
                    end
                )

                return
            end

            if (Event == "Error" or Event == "Notice") then
                if (not Args2) then
                    StarterGui:SetCore(
                        "SendNotification",
                        {
                            Title = "XYZ",
                            Text = Args1,
                            Duration = 15,
                            Button1 = Args3 or "Close",
                            Button2 = Args4 or nil
                        }
                    )

                    return
                end

                StarterGui:SetCore(
                    "SendNotification",
                    {
                        Title = string.format("XYZ | %s", Args1),
                        Text = Args2 or "???",
                        Duration = 15,
                        Button1 = Args3 or "Close",
                        Button2 = Args4 or nil
                    }
                )

                return
            end
        end
    )

    Tween(
        Authorize.Avatar,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
        {Position = UDim2.fromScale(0.5, 0.5)},
        true
    )

    AddConnection(
        Authorize.Avatar.Buttons.Submit.Activated,
        function()
            Net:Fire("Avatar", Authorize.Avatar.Buttons.Box.Text)
            repeat
                task.wait()
            until Client:GetAttribute("MorphUserId")

            Ripple(Authorize.Avatar.Buttons.Submit, 0.25)
            Sound("rbxassetid://7218169592")
            Tween(
                Authorize.Avatar,
                TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                {Position = UDim2.fromScale(0.5, -0.1)},
                true
            )
            Tween(
                Authorize.Age,
                TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                {Position = UDim2.fromScale(0.5, 0.5)},
                true
            )
        end
    )

    repeat
        task.wait()
    until Client:GetAttribute("MorphUserId")

    AddConnection(
        Authorize.Age.Buttons.Box:GetPropertyChangedSignal("Text"),
        function()
            Authorize.Age.Buttons.Box.Text =
                #Authorize.Age.Buttons.Box.Text > 2 and string.sub(Authorize.Age.Buttons.Box.Text, 1, 2) or
                Authorize.Age.Buttons.Box.Text
        end
    )

    AddConnection(
        Authorize.Age.Buttons.Submit.Activated,
        function()
            Net:Fire("Age", Authorize.Age.Buttons.Box.Text)
            repeat
                task.wait()
            until Client:GetAttribute("Age")

            Ripple(Authorize.Age.Buttons.Submit, 0.25)
            Sound("rbxassetid://7218169592")
        end
    )

    repeat
        task.wait()
    until Client:GetAttribute("Age")
    ClearConnections()

    RunService.Heartbeat:Wait(0.3)

    Tween(
        Authorize.Age,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
        {Position = UDim2.fromScale(0.5, -0.1)},
        true
    )
    RunService.Heartbeat:Wait(0.25)
    Tween(
        Authorize.Gender,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
        {Position = UDim2.fromScale(0.5, 0.5)},
        true
    )

    AddConnection(
        Authorize.Gender.Buttons.One.Activated,
        function()
            Sound("rbxassetid://7218169592")
            Net:Fire("Gender", "Male")
            repeat
                task.wait()
            until Client:GetAttribute("Gender")

            Ripple(Authorize.Gender.Buttons.One, 0.25)
        end
    )

    AddConnection(
        Authorize.Gender.Buttons.Two.Activated,
        function()
            Sound("rbxassetid://7218169592")
            Net:Fire("Gender", "Female")
            repeat
                task.wait()
            until Client:GetAttribute("Gender")

            Ripple(Authorize.Gender.Buttons.Two, 0.25)
        end
    )

    AddConnection(
        Authorize.Gender.Buttons.Three.Activated,
        function()
            Sound("rbxassetid://7218169592")
            Net:Fire("Gender", "Femboy")
            repeat
                task.wait()
            until Client:GetAttribute("Gender")

            Ripple(Authorize.Gender.Buttons.Three, 0.25)
        end
    )

    AddConnection(
        Authorize.Gender.Buttons.Four.Activated,
        function()
            Sound("rbxassetid://7218169592")
            Net:Fire("Gender", "Futa")
            repeat
                task.wait()
            until Client:GetAttribute("Gender")

            Ripple(Authorize.Gender.Buttons.Four, 0.25)
        end
    )

    repeat
        task.wait()
    until Client:GetAttribute("Gender")
    ClearConnections()

    RunService.Heartbeat:Wait(0.3)

    Tween(
        Authorize.Gender,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
        {Position = UDim2.fromScale(0.5, -1)},
        true
    )
    Tween(Blur, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = 0}, true)

    Blur:Destroy()
    Authorize:Destroy()

    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
    Client.Character.HumanoidRootPart.Anchored = false

    local Main = ReplicatedStorage:WaitForChild("GUIs"):FindFirstChild("UI")
    local Options = Main.Options

    Main.Parent = Client.PlayerGui

    for i, v in next, Main.Tabs:GetChildren() do
        if v:IsA("Frame") then
            SortedTabs[v.Name] = v
            Draggables[v.Name] = Dragify.new(v)
            print("done" , v.Name)
        end
    end

    local Connection = nil
    local Menu = Icon.new()
    Menu:setImage(10734887784)
    Menu:setMenu(
        {
            Icon.new():setLabel("Apply Morph"):setImage(10734920149):bindEvent(
                "selected",
                function(icon)
                    ClearConnection("Mouse")
                    AddConnection(
                        RunService.RenderStepped,
                        function()
                            if (workspace.CurrentCamera.CFrame.p - workspace.CurrentCamera.Focus.p).Magnitude > 0.6 then
                                return
                            end
                            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                        end,
                        "Mouse"
                    )

                    Net:Fire("Morph")
                end
            ):oneClick()
        }
    )

    local Watermark = Icon.new()
    Watermark:setLabel("BEST GAMES - INVITE YOUR FRIENDS")
    Watermark:autoDeselect(false)
    Watermark:align("Center")
    Watermark:oneClick()

    local Minutes = Icon.new()
    Minutes:setLabel(
        string.format("%s minutes", tostring(math.floor((os.time() - workspace:GetAttribute("Startup")) / 60)))
    )
    Minutes:autoDeselect(false)
    Minutes:align("Right")
    Minutes:oneClick()
    Minutes:setImage(6026568260)

    task.spawn(
        function()
            while task.wait(1) do
                Minutes:setLabel(
                    string.format(
                        "%s minutes",
                        tostring(math.floor((os.time() - workspace:GetAttribute("Startup")) / 60))
                    )
                )
            end
        end
    )

    if SortedTabs.Bot then
        local Bot = SortedTabs.Bot
            local Buttons = Bot.Buttons.Main
            local Input = Bot.Buttons.Box

            local function GetUserInfo(Input)
                if not Input or #Input < 3 then
                    return nil
                end

                local Name, UserId = "", 0

                if tonumber(Input) then
                    local Success, NameOrError =
                        pcall(
                        function()
                            return Players:GetNameFromUserIdAsync(tonumber(Input))
                        end
                    )

                    if Success then
                        Name, UserId = NameOrError, tonumber(Input)
                    end
                else
                    local Success, UserIdOrError =
                        pcall(
                        function()
                            return Players:GetUserIdFromNameAsync(Input)
                        end
                    )

                    if Success and UserIdOrError > 0 then
                        Name, UserId = Input, UserIdOrError
                    end
                end

                if UserId > 0 then
                    local Success, ImageOrError =
                        pcall(
                        function()
                            return Players:GetUserThumbnailAsync(
                                UserId,
                                Enum.ThumbnailType.AvatarThumbnail,
                                Enum.ThumbnailSize.Size420x420
                            )
                        end
                    )

                    if Success then
                        Bot.Display.Render.Image = ImageOrError
                    end

                    return {Name = Name, UserId = UserId}
                end

                return nil
            end

            AddConnection(
                Input.FocusLost,
                function()
                    GetUserInfo(Input.Text)
                end
            )

            AddConnection(
                Buttons.Create.Activated,
                function()
                    Sound("rbxassetid://7218169592")
                    Ripple(Buttons.Create, 0.25)

                    local Information = GetUserInfo(Input.Text)

                    if not Information then
                        return
                    end

                    Net:Fire("Bot", "Create", Information.Name)
                end
            )

            AddConnection(
                Buttons.Erase.Activated,
                function()
                    Sound("rbxassetid://7218169592")
                    Ripple(Buttons.Erase, 0.25)
                    Net:Fire("Unlink", "Bot")
                end
            )
    end

    if SortedTabs.Animations then
        local function CreateAnimationButton(AnimationFolder)
            local AnimationName = AnimationFolder.Name
            local Button = SortedTabs.Animations.Scroller.Template:Clone()

            Button.Text = AnimationName
            Button.Name = AnimationName
            Button.Visible = true

            AddConnection(
                Button.Activated,
                function()
                    Ripple(Button, 0.25)
                    Sound("rbxassetid://7218169592")
                    Net:Fire("Animation", "Update", AnimationFolder.Name)
                end
            )

            Button.Parent = SortedTabs.Animations.Scroller

            return Button
        end

        local function CreateDivider(Name)
            if SortedTabs.Animations.Scroller:FindFirstChild(Name) then
                -- Do nothing if divider exists
            else
                local Divider = SortedTabs.Animations.Scroller.Divider:Clone()
                Divider.Text = Name
                Divider.Name = Name
                Divider.Visible = true
                Divider.Parent = SortedTabs.Animations.Scroller

                return Divider
            end
        end

        for _, Ordered in next, game.ReplicatedStorage.Animations:GetChildren() do
            for _, AnimationType in next, Ordered:GetChildren() do
                if AnimationType:IsA("Folder") then
                    local DividerName

                    if Ordered.Name == "Different" then
                        DividerName = "Different"
                    elseif Ordered.Name == "Same" then
                        local Gender = AnimationType.Allowed.Value
                        DividerName = Gender == "F to F" and "FM Only" or "ML Only"
                    elseif Ordered.Name == "Solo" then
                        local Gender = AnimationType.Allowed.Value
                        DividerName = (Gender == "Female" and "F Solo") or (Gender == "M" and "M Solo")
                    end

                    local Divider = SortedTabs.Animations.Scroller:FindFirstChild(DividerName) or CreateDivider(DividerName)
                    CreateAnimationButton(AnimationType)
                end
            end
        end

        local Animations = SortedTabs.Animations
            AddConnection(
                Animations.Buttons.Speed.FocusLost,
                function()
                    local Number = tonumber(Animations.Buttons.Speed.Text)

                    if not Number then
                        return
                    end
                    if Number > 10 then
                        return
                    end
                    if Number < 0.1 then
                        return
                    end

                    Net:Fire("Animation", "Speed", Number)
                end
            )

            AddConnection(
                Animations.Buttons.Search:GetPropertyChangedSignal("Text"),
                function()
                    local InputText = string.lower(Animations.Buttons.Search.Text)

                    for _, Button in next, SortedTabs.Animations.Scroller:GetChildren() do
                        Button.Visible = string.find(string.lower(Button.Name), InputText, 1, true) and true or false
                    end
                end
            )

            AddConnection(
                Animations.Buttons.Transfer.Activated,
                function()
                    Ripple(Animations.Buttons.Transfer, 0.25)
                    Sound("rbxassetid://7218169592")
                    Net:Fire("Animation", "Transfer")
                end
            )
    end

    if SortedTabs.Rooms then
        local function CreateRoomButton(Folder)
            local RoomType = Folder.Name
            local Button = SortedTabs.Rooms.Scroller.Template:Clone()

            Button.Text = RoomType
            Button.Name = RoomType
            Button.Visible = true

            AddConnection(
                Button.Activated,
                function()
                    Net:Fire("Room", "Create", RoomType, Players:FindFirstChild(Players.LocalPlayer.Name))
                    Ripple(Button, 0.25)
                    Sound("rbxassetid://7218169592")
                end
            )

            Button.Parent = SortedTabs.Rooms.Scroller

            return Button
        end

        for _, Ordered in next, game.ReplicatedStorage.Rooms:GetChildren() do
            CreateRoomButton(Ordered)
        end

        local Rooms = SortedTabs.Rooms
            local Frame = Rooms.Buttons.Box.Suggestions.ScrollingFrame.Player:Clone()
            local Count = 0

            for _, Player in next, Players:GetPlayers() do
                local Frame = Frame:Clone()
                Frame.Visible = true
                Frame.Name = Player.Name
                Frame.Highlighted.Text = ""
                Frame.Full.Text = Player.Name
                Frame.Parent = Rooms.Buttons.Box.Suggestions.ScrollingFrame
            end

            AddConnection(
                Players.PlayerAdded,
                function(Player)
                    local Frame = Frame:Clone()
                    Frame.Visible = true
                    Frame.Name = Player.Name
                    Frame.Highlighted.Text = ""
                    Frame.Full.Text = Player.Name
                    Frame.Parent = Rooms.Buttons.Box.Suggestions.ScrollingFrame
                end
            )

            AddConnection(
                Rooms.Buttons.Main.Erase.Activated,
                function()
                    Ripple(Rooms.Buttons.Main.Erase, 0.25)
                    Sound("rbxassetid://7218169592")
                    Net:Fire("Room", "Erase")
                end
            )

            AddConnection(
                Rooms.Buttons.Main.Teleport.Activated,
                function()
                    for _, Player in next, Players:GetPlayers() do
                        if Player.Name:lower():sub(1, #Rooms.Buttons.Box.Text) == Rooms.Buttons.Box.Text:lower() then
                            Rooms.Buttons.Box.Text = Player.Name
                        end
                    end

                    Ripple(Rooms.Buttons.Main.Teleport, 0.25)
                    Sound("rbxassetid://7218169592")

                    Net:Fire("Room", "Teleport", Players:FindFirstChild(Rooms.Buttons.Box.Text))
                end
            )

            AddConnection(
                Rooms.Buttons.Box:GetPropertyChangedSignal("Text"),
                function()
                    for _, Object in next, Rooms.Buttons.Box.Suggestions.ScrollingFrame:GetChildren() do
                        if Object:IsA("Frame") and Object.Name ~= "Player" then
                            Count = Count + 1

                            local Label = Object.Full
                            Object.Highlighted.Visible = false

                            if Label.Text:lower():sub(1, #Rooms.Buttons.Box.Text) ~= Rooms.Buttons.Box.Text:lower() then
                                Object.Visible = false
                            else
                                Object.Visible = true
                                Object.Highlighted.Visible = true
                                Object.Highlighted.Text = Label.Text:sub(1, #Rooms.Buttons.Box.Text)
                            end
                        end

                        if Count > 5 then
                            break
                        end
                    end

                    Count = 0
                end
            )

            AddConnection(
                Rooms.Buttons.Box.Focused,
                function()
                    Rooms.Buttons.Box.Suggestions.Visible = true

                    for _, Object in next, Rooms.Buttons.Box.Suggestions.ScrollingFrame:GetChildren() do
                        if Object:IsA("Frame") and Object.Name ~= "Player" then
                            Object.Visible = true
                        end
                    end
                end
            )

            AddConnection(
                Rooms.Buttons.Box.FocusLost,
                function()
                    Rooms.Buttons.Box.Suggestions.Visible = false

                    for _, Object in next, Rooms.Buttons.Box.Suggestions.ScrollingFrame:GetChildren() do
                        if Object:IsA("Frame") and Object.Name ~= "Player" then
                            Object.Visible = false
                        end
                    end
                end
            )
    end

    if SortedTabs.Collar then
        local Collar = SortedTabs.Collar
        do
            local Frame = Collar.Buttons.Box.Suggestions.ScrollingFrame.Player:Clone()
            local Count = 0

            for _, Player in next, Players:GetPlayers() do
                local Frame = Frame:Clone()
                Frame.Visible = true
                Frame.Name = Player.Name
                Frame.Highlighted.Text = ""
                Frame.Full.Text = Player.Name
                Frame.Parent = Collar.Buttons.Box.Suggestions.ScrollingFrame
            end

            AddConnection(
                Players.PlayerAdded,
                function(Player)
                    local Frame = Frame:Clone()
                    Frame.Visible = true
                    Frame.Name = Player.Name
                    Frame.Highlighted.Text = ""
                    Frame.Full.Text = Player.Name
                    Frame.Parent = Collar.Buttons.Box.Suggestions.ScrollingFrame
                end
            )

            AddConnection(
                Players.PlayerRemoving,
                function(Player)
                    if Collar.Buttons.Box.Suggestions.ScrollingFrame:FindFirstChild(Player.Name) then
                        Collar.Buttons.Box.Suggestions.ScrollingFrame[Player.Name]:Destroy()
                    end
                end
            )

            AddConnection(
                Collar.Buttons.Box.Main:GetPropertyChangedSignal("Text"),
                function()
                    for _, Object in next, Collar.Buttons.Box.Suggestions.ScrollingFrame:GetChildren() do
                        if Object:IsA("Frame") and Object.Name ~= "Player" then
                            Count = Count + 1

                            local Label = Object.Full
                            Object.Highlighted.Visible = false

                            if
                                Label.Text:lower():sub(1, #Collar.Buttons.Box.Main.Text) ~=
                                    Collar.Buttons.Box.Main.Text:lower()
                             then
                                Object.Visible = false
                            else
                                Object.Visible = true
                                Object.Highlighted.Visible = true
                                Object.Highlighted.Text = Label.Text:sub(1, #Collar.Buttons.Box.Main.Text)
                            end
                        end

                        if Count > 5 then
                            break
                        end
                    end

                    Count = 0
                end
            )

            AddConnection(
                Collar.Buttons.Box.Main.Focused,
                function()
                    Collar.Buttons.Box.Suggestions.Visible = true

                    for _, Object in next, Collar.Buttons.Box.Suggestions.ScrollingFrame:GetChildren() do
                        if Object:IsA("Frame") and Object.Name ~= "Player" then
                            Object.Visible = true
                        end
                    end
                end
            )

            AddConnection(
                Collar.Buttons.Box.Main.FocusLost,
                function()
                    Collar.Buttons.Box.Suggestions.Visible = false

                    for _, Object in next, Collar.Buttons.Box.Suggestions.ScrollingFrame:GetChildren() do
                        if Object:IsA("Frame") and Object.Name ~= "Player" then
                            Object.Visible = false
                        end
                    end
                end
            )

            AddConnection(
                Collar.Buttons.Free.Activated,
                function()
                    Sound("rbxassetid://7218169592")
                    Ripple(Collar.Buttons.Request, 0.25)
                    Net:Fire("Collar", "Free")
                end
            )

            AddConnection(
                Collar.Buttons.Request.Activated,
                function()
                    for _, Player in next, Players:GetPlayers() do
                        if Player.Name == Collar.Buttons.Box.Main.Text then
                            -- Do nothing
                        elseif
                            Player.Name:lower():sub(1, #Collar.Buttons.Box.Main.Text) ~=
                                Collar.Buttons.Box.Main.Text:lower()
                         then
                            -- Do nothing
                        else
                            Collar.Buttons.Box.Main.Text = Player.Name
                        end
                    end

                    Sound("rbxassetid://7218169592")
                    Ripple(Collar.Buttons.Request, 0.25)
                    Net:Fire("Collar", "Request", Players:FindFirstChild(Collar.Buttons.Box.Main.Text))
                end
            )
        end
    end

    if SortedTabs.Mate then
        local Mate = SortedTabs.Mate
        do
            local Frame = Mate.Buttons.Box.Suggestions.ScrollingFrame.Player:Clone()
            local Count = 0

            for _, Player in next, Players:GetPlayers() do
                local Frame = Frame:Clone()
                Frame.Visible = true
                Frame.Name = Player.Name
                Frame.Highlighted.Text = ""
                Frame.Full.Text = Player.Name
                Frame.Parent = Mate.Buttons.Box.Suggestions.ScrollingFrame
            end

            AddConnection(
                Players.PlayerAdded,
                function(Player)
                    local Frame = Frame:Clone()
                    Frame.Visible = true
                    Frame.Name = Player.Name
                    Frame.Highlighted.Text = ""
                    Frame.Full.Text = Player.Name
                    Frame.Parent = Mate.Buttons.Box.Suggestions.ScrollingFrame
                end
            )

            AddConnection(
                Players.PlayerRemoving,
                function(Player)
                    if Mate.Buttons.Box.Suggestions.ScrollingFrame:FindFirstChild(Player.Name) then
                        Mate.Buttons.Box.Suggestions.ScrollingFrame[Player.Name]:Destroy()
                    end
                end
            )

            AddConnection(
                Mate.Buttons.Box.Main:GetPropertyChangedSignal("Text"),
                function()
                    for _, Object in next, Mate.Buttons.Box.Suggestions.ScrollingFrame:GetChildren() do
                        if Object:IsA("Frame") and Object.Name ~= "Player" then
                            Count = Count + 1

                            local Label = Object.Full
                            Object.Highlighted.Visible = false

                            if
                                Label.Text:lower():sub(1, #Mate.Buttons.Box.Main.Text) ~=
                                    Mate.Buttons.Box.Main.Text:lower()
                             then
                                Object.Visible = false
                            else
                                Object.Visible = true
                                Object.Highlighted.Visible = true
                                Object.Highlighted.Text = Label.Text:sub(1, #Mate.Buttons.Box.Main.Text)
                            end
                        end

                        if Count > 5 then
                            break
                        end
                    end

                    Count = 0
                end
            )

            AddConnection(
                Mate.Buttons.Box.Main.Focused,
                function()
                    Mate.Buttons.Box.Suggestions.Visible = true

                    for _, Object in next, Mate.Buttons.Box.Suggestions.ScrollingFrame:GetChildren() do
                        if Object:IsA("Frame") and Object.Name ~= "Player" then
                            Object.Visible = true
                        end
                    end
                end
            )

            AddConnection(
                Mate.Buttons.Box.Main.FocusLost,
                function()
                    Mate.Buttons.Box.Suggestions.Visible = false

                    for _, Object in next, Mate.Buttons.Box.Suggestions.ScrollingFrame:GetChildren() do
                        if Object:IsA("Frame") and Object.Name ~= "Player" then
                            Object.Visible = false
                        end
                    end
                end
            )

            AddConnection(
                Mate.Buttons.Request.Activated,
                function()
                    for _, Player in next, Players:GetPlayers() do
                        if Player.Name == Mate.Buttons.Box.Main.Text then
                            -- Do nothing
                        elseif
                            Player.Name:lower():sub(1, #Mate.Buttons.Box.Main.Text) ~=
                                Mate.Buttons.Box.Main.Text:lower()
                         then
                            -- Do nothing
                        else
                            Mate.Buttons.Box.Main.Text = Player.Name
                        end
                    end

                    Sound("rbxassetid://7218169592")
                    Ripple(Mate.Buttons.Request, 0.25)
                    Net:Fire("Mate", "Request", Players:FindFirstChild(Mate.Buttons.Box.Main.Text))
                end
            )

            AddConnection(
                Mate.Buttons.Unlink.Activated,
                function()
                    Sound("rbxassetid://7218169592")
                    Ripple(Mate.Buttons.Unlink, 0.25)
                    Net:Fire("Unlink", "Human")
                end
            )
        end
    end

    task.spawn(
        function()
            while task.wait() do
                if Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("Scene") then
                    Main.Finish.Visible = true
                else
                    Main.Finish.Visible = false
                end
            end
        end
    )

    AddConnection(
        Main.Finish.Activated,
        function()
            Net:Fire("Buzz")
        end
    )

    local function Lerp(a, b, t)
        return a + (b - a) * t
    end

    local function Rescale(Size, Scale)
        return UDim2.new(Size.X.Scale * Scale, Size.X.Offset * Scale, Size.Y.Scale * Scale, Size.Y.Offset * Scale)
    end

    local CurrentlyOpen = nil -- Keeps track of the currently open menu

    for i, v in next, Options.Buttons:GetChildren() do
        if not v:IsA("ImageButton") then
            -- Do nothing
        else
            local Tab = SortedTabs[v.Name]
            local Size = v.Size
            local TweenCancel =
                TweenService:Create(
                Instance.new("NumberValue"),
                TweenInfo.new(45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1),
                {}
            ).Cancel
            local Jingle

            local Renderable = v:Clone()
            Renderable.Size = UDim2.new(1, 0, 1, 0)
            Renderable.Parent = v
            Renderable.Name = "Renderable"
            Renderable.Selectable = false
            Renderable.ZIndex = -10

            v.ImageTransparency = 0.99999

            -- MouseEnter
            v.MouseEnter:Connect(
                function()
                    pcall(TweenCancel, Tween)
                    local tweenObject =
                        TweenService:Create(
                        v,
                        TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
                        {Size = Rescale(Size, 1.35)}
                    )
                    tweenObject:Play()

                    Jingle =
                        coroutine.create(
                        function()
                            local Sine, Scale, Rate, Rotation, RateOfChange = 0, 25, 0, 0, 0.01
                            while task.wait() and RateOfChange <= 1 do
                                Sine = Sine + 1
                                Rate = Rate + 0.1
                                RateOfChange = RateOfChange * 1.0125
                                Rotation =
                                    Lerp(Lerp(Rotation, math.cos(Sine / (7 + Rate)) * Scale, 0.2), 0, RateOfChange)
                                Renderable.Rotation = Rotation
                            end
                            TweenService:Create(
                                Renderable,
                                TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                                {Rotation = 0}
                            ):Play()
                        end
                    )
                    coroutine.resume(Jingle)
                end
            )

            -- MouseLeave
            v.MouseLeave:Connect(
                function()
                    pcall(TweenCancel, Tween)
                    -- Revert to original size
                    Tween =
                        TweenService:Create(
                        v,
                        TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
                        {Size = Size}
                    )
                    Tween:Play()

                    -- Reset Renderable Rotation
                    Tween =
                        TweenService:Create(
                        Renderable,
                        TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                        {Rotation = 0}
                    )
                    Tween:Play()
                    pcall(coroutine.close, Jingle)
                end
            )

            if not Tab then
                local Debounce = tick() - 5
                Renderable.Activated:Connect(
                    function()
                        if (tick() - Debounce) < 0.5 then
                            return
                        end
                    end
                )
            else
                local Visible = false
                local Debounce = tick() - 5

                Renderable.MouseButton1Click:Connect(
                    function()
                        if (tick() - Debounce) < 1.5 then
                            return
                        end

                        local TweenFunc = function(Object, Info, Properties, Wait)
                            local TweenObj = TweenService:Create(Object, Info, Properties)
                            TweenObj:Play()

                            if Wait then
                                TweenObj.Completed:Wait()
                            end
                        end

                        -- Close the currently open menu if it's not the same as the clicked one
                        if CurrentlyOpen and CurrentlyOpen ~= v.Name then
                            local OpenTab = SortedTabs[CurrentlyOpen]
                            TweenFunc(
                                OpenTab,
                                TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                                {Position = UDim2.fromScale(0.5, -1)},
                                true
                            )
                            Draggables[CurrentlyOpen]:Disable()
                            CurrentlyOpen = nil
                        end

                        if not Visible then
                            -- Open the current menu
                            TweenFunc(
                                SortedTabs[v.Name],
                                TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                                {Position = UDim2.fromScale(0.5, 0.5)},
                                true
                            )
                            Draggables[v.Name]:Enable()
                            ClearConnection("Mouse")
                            AddConnection(
                                RunService.RenderStepped,
                                function()
                                    if
                                        (workspace.CurrentCamera.CFrame.p - workspace.CurrentCamera.Focus.p).Magnitude >
                                            0.6
                                     then
                                        return
                                    end
                                    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                                end,
                                "Mouse"
                            )

                            CurrentlyOpen = v.Name
                            Visible = true
                            return
                        end

                        if Visible then
                            -- Close the current menu
                            ClearConnection("Mouse")
                            TweenFunc(
                                SortedTabs[v.Name],
                                TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                                {Position = UDim2.fromScale(0.5, -1)},
                                true
                            )
                            Draggables[v.Name]:Disable()

                            CurrentlyOpen = nil
                            Visible = false
                            return
                        end
                    end
                )
            end
        end
    end
end

return StartupHandler
