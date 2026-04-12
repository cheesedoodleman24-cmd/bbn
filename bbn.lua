local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local lp = Players.LocalPlayer
local cam = workspace.CurrentCamera

local targets = {}
local lockTarget = nil
local isLocked = false
local lHeld = false

local function applyGlow(object)
    if object:FindFirstChild("GenOutline") then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "GenOutline"
    highlight.FillTransparency = 1
    highlight.OutlineColor = Color3.fromRGB(0, 255, 255)
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = object
end

task.spawn(function()
    while true do
        local currentTargets = {}
        for _, item in ipairs(game:GetDescendants()) do
            local isGen = item.Name == "Generator" and (item:IsA("BasePart") or item:IsA("Model"))
            local isPlayer = item:IsA("Model") and Players:GetPlayerFromCharacter(item) and item ~= lp.Character
            
            if (isGen or isPlayer) and not item:IsDescendantOf(game:GetService("CoreGui")) then
                applyGlow(item)
                table.insert(currentTargets, item)
            end
        end
        targets = currentTargets
        task.wait(1)
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if input.KeyCode == Enum.KeyCode.L then
        if isLocked then
            isLocked = false
            lockTarget = nil
        else
            lHeld = true
        end
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mousePos = UserInputService:GetMouseLocation()
        local bestTarget = nil
        local closestDist = 80 

        for _, target in ipairs(targets) do
            local part = target:IsA("Model") and (target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")) or target
            if part then
                local screenPos, onScreen = cam:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        bestTarget = part
                    end
                end
            end
        end

        if bestTarget and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = lp.Character.HumanoidRootPart
            if lHeld then
                lockTarget = bestTarget
                isLocked = true
            else
                local ti = TweenInfo.new(0.65, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
                TweenService:Create(hrp, ti, {CFrame = bestTarget.CFrame + Vector3.new(0, 5, 0)}):Play()
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.L then
        lHeld = false
    end
end)

RunService.RenderStepped:Connect(function()
    if isLocked and lockTarget and lockTarget.Parent and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        lp.Character.HumanoidRootPart.CFrame = lockTarget.CFrame + Vector3.new(0, 5, 0)
    elseif isLocked and (not lockTarget or not lockTarget.Parent) then
        isLocked = false
        lockTarget = nil
    end
end)
