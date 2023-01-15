--!strict

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local MotorVehicle = require(ReplicatedStorage.Shared.MotorVehicle)
local MvTypes = require(ReplicatedStorage.Shared.MotorVehicle.Types)

local Util = require(ReplicatedStorage.Shared.Util)
local Stats = require(script.Stats)

local player = Players.LocalPlayer

local target = script:WaitForChild("Target") :: ObjectValue
local vehicle = target.Value :: Model

local chassis = vehicle:WaitForChild("Chassis") :: Model & {
	Wheels: Model & {
		FL: BasePart,
		FR: BasePart,
		RL: BasePart,
		RR: BasePart
	},
	VehicleSeat: VehicleSeat,
	Platform: Part & {
		Cylinders: Folder,
		Engine: Attachment & {
			Rev: Sound
		}
	}
}

local driverSeat = chassis.VehicleSeat

local cylinders = Util.getNamedChildren(chassis.Platform.Cylinders)
local attachments = Util.getNamedChildren(chassis.Platform :: Instance)
local gui = player.PlayerGui.ScreenGui
local stats = Stats.new(gui)

local config = require((vehicle :: any).Config :: any)

local bus = MotorVehicle.new({
	root = driverSeat,
	wheels = {chassis.Wheels.RL, chassis.Wheels.RR},
	torque = config.torque,
	maxSteerAngle = config.maxSteerAngle,
	turnSpeed = config.turnSpeed,
	gearRatio = config.gearRatio,
	maxAngularAcceleration = config.maxAngularAcceleration
})

chassis.Platform.Engine.Rev:Play()

--[[
local raycastParams = RaycastParams.new()
raycastParams.RespectCanCollide = true
raycastParams.IgnoreWater = false
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
raycastParams.FilterDescendantsInstances = {vehicle}
]]

local heartbeat
heartbeat = RunService.Heartbeat:Connect(function(deltaTime)
	local clockStart = os.clock()

	if not driverSeat.Occupant then
		chassis.Platform.Engine.Rev:Stop()
		heartbeat:Disconnect()
		stats:destroy()
	end

	local steerFloat = driverSeat.SteerFloat
	local throttleFloat = driverSeat.ThrottleFloat

	local output = bus:compute(deltaTime, {
		steerFloat = -steerFloat,
		throttleFloat = throttleFloat
	})

	attachments.FL.Orientation = Vector3.new(0, output.angle, 90)
	attachments.FR.Orientation = Vector3.new(0, output.angle + 180, 90)

	cylinders.FL.AngularVelocity = output.angularVelocity
	cylinders.FR.AngularVelocity = -output.angularVelocity
	cylinders.RL.AngularVelocity = output.angularVelocity
	cylinders.RR.AngularVelocity = -output.angularVelocity

	for _, cylinder: CylindricalConstraint in cylinders do
		cylinder.MotorMaxAngularAcceleration = output.motorMaxAngularAcceleration
		cylinder.MotorMaxTorque = output.motorMaxTorque
	end

	chassis.Platform.Engine.Rev.PlaybackSpeed = bus:getRevPlaybackSpeed() + config.revPlaybackSpeedOffset

	local clockEnd = os.clock()

	stats:compute({
		chassisInst = bus,
		vehicle = vehicle,
		clockStart = clockStart,
		clockEnd = clockEnd,
		deltaTime = deltaTime,
		steerFloat = steerFloat,
		throttleFloat = throttleFloat,
		output = output :: MvTypes.ComputeResult
	})
end)