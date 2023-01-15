local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Util = require(ReplicatedStorage.Shared.Util)

local chassis = script.Parent :: Model
local vehicle = chassis.Parent :: Model

local driverSeat = chassis:FindFirstChildOfClass("VehicleSeat") :: VehicleSeat

local client = script.Client

local driver = Instance.new("ObjectValue")
driver.Name = "Driver"
driver.Parent = driverSeat

local target = Instance.new("ObjectValue")
target.Name = "Target"
target.Value = vehicle
target.Parent = client

local function updateWheelPhysicalProperties()
	local properties = {
		density = 0.7, -- Wheel weight
		friction = 0.3, -- Higher values = less drifting/sliding, Lower values = more drifting/sliding
		elasticity = 0.5, -- 0.5
		frictionWeight = 1, -- 1
		elasticityWeight = 1 -- 1
	}
	
	for _, name in pairs({"FL", "FR", "RL", "RR"}) do
		chassis.Wheels:FindFirstChild(name).CustomPhysicalProperties = PhysicalProperties.new(
			properties.density,
			properties.friction,
			properties.elasticity,
			properties.frictionWeight,
			properties.elasticityWeight
		)
	end
end

local function driverJoined(occupant)
	local character = occupant.Parent
	if not character then
		return
	end

	local player = Players:FindFirstChild(character.Name)
	if not player then
		return
	end

	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then
		return
	end

	driverSeat:SetNetworkOwner(player)
	driver.Value = player

	local clonedClient = client:Clone()
	clonedClient.Parent = playerGui
	clonedClient.Disabled = false

	Util.hideCharacter(player)
end

local function driverLeft()
	driverSeat:SetNetworkOwnershipAuto()

	local player = driver.Value
	if not player then
		return
	end

	driver.Value = nil

	Util.showCharacter(player)
end

driverSeat:GetPropertyChangedSignal("Occupant"):Connect(function()
	local occupant = driverSeat.Occupant
	if occupant then
		driverJoined(occupant)
		return
	end
	driverLeft()
end)

updateWheelPhysicalProperties()