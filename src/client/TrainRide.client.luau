--!strict
-- Keeps the player glued to a moving train.
-- Anchored trains moved by CFrame/TweenService don't carry characters with physics,
-- so each frame we move the player by however much the train they stand on moved.
-- Setup: give each train Model the CollectionService tag "Train".

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local TRAIN_TAG = "Train"
local RAY_LENGTH = 12 -- long enough to keep carrying the player mid-jump

local player = Players.LocalPlayer
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local currentTrain: Model? = nil
local lastTrainCFrame: CFrame? = nil

local function findTrain(hit: Instance): Model?
	for _, train in CollectionService:GetTagged(TRAIN_TAG) do
		if train:IsA("Model") and hit:IsDescendantOf(train) then
			return train
		end
	end
	return nil
end

local function stopRiding()
	currentTrain = nil
	lastTrainCFrame = nil
end

RunService.PreSimulation:Connect(function()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (character and root and root:IsA("BasePart") and humanoid) or humanoid.Health <= 0 then
		stopRiding()
		return
	end

	rayParams.FilterDescendantsInstances = { character }
	local result = workspace:Raycast(root.Position, Vector3.new(0, -RAY_LENGTH, 0), rayParams)
	local train = result and findTrain(result.Instance)
	if not train then
		stopRiding()
		return
	end

	-- Use the whole train's pivot, not the part we hit, so stepping between
	-- carriages or floor parts doesn't cause a jump.
	local trainCFrame = train:GetPivot()
	if train == currentTrain and lastTrainCFrame then
		local delta = trainCFrame * lastTrainCFrame:Inverse()
		root.CFrame = delta * root.CFrame
	end
	currentTrain = train
	lastTrainCFrame = trainCFrame
end)
