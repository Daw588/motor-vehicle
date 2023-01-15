--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local MvUtil = require(ReplicatedStorage.Shared.MotorVehicle.Util)
local MvEnums = require(ReplicatedStorage.Shared.MotorVehicle.Enums)

local FrameRateManager = require(ReplicatedStorage.Shared.FrameRateManager)
local Util = require(ReplicatedStorage.Shared.Util)

local Types = require(script.Types)

local Stats: Types.Impl = {} :: Types.Impl
Stats.__index = Stats

function Stats.new(gui: ScreenGui)
	local self = setmetatable({} :: Types.Proto, Stats)

	local thisGui = gui :: ScreenGui & {
		Stats: Frame & {
			Template: TextLabel,
			UIGridLayout: UIGridLayout
		}
	}

	self.gui = gui
	self.frameRateManager = FrameRateManager.new()
	self.labels = {}
	self.index = 0
	self.executionTimes = {}

	local template = thisGui.Stats.Template
	template.Parent = thisGui.Stats.UIGridLayout

	-- Be aware, the end index defines how many labels we will have
	for i = 1, 24 do
		local stat = template:Clone()
		stat.Name = i
		stat.Parent = thisGui.Stats
		self.labels[i] = stat
	end

	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		-- Ignore already processed events
		if gameProcessedEvent then
			return
		end

		-- Toggle stats menu UI
		if input.KeyCode == Enum.KeyCode.T then
			gui.Enabled = not gui.Enabled
		end
	end)

	return self
end

-- Appends information to a label by the call order
function Stats._append(self: Types.Stats, str: string)
	--[[
		Verify that label exists because
		sometimes after destroy method is
		called, this causes an error.
	]]
	if self.labels[self.index] then
		self.labels[self.index].Text = str
		self.index += 1
	end
end

function Stats.compute(self: Types.Stats, info: Types.Info)
	local state = MvUtil.getEnumName(MvEnums.AssemblyVelocityState, info.chassisInst:getAssemblyVelocityState())
	local direction = if info.chassisInst:getAssemblyVelocity() < 1 then "None" else (info.chassisInst:getAssemblyDirection() > 0 and "Forward" or "Backwards")
	local assemblyMass = Util.getAssemblyMass(info.vehicle)
	local assemblyVelocity = math.floor(math.abs(info.chassisInst:getAssemblyVelocity()))

	--[[
		Average out execution time to make it
		change less drastically, and, therefore,
		make it readable to a human.
	]]
	local executionTime = info.clockEnd - info.clockStart
	table.insert(self.executionTimes, executionTime)

	if #self.executionTimes > 100 then
		table.remove(self.executionTimes, 1)
	end

	local executionTimeSum = 0

	for _, execTime in self.executionTimes do
		executionTimeSum += execTime * 1_000_000 -- From seconds to microseconds
	end

	local avgExecutionTime = executionTimeSum / #self.executionTimes

	-- Reset the index (it is incremented by each "append()" call)

	self.index = 1

	self:_append("<b>Performance</b>")

	self:_append(
		string.format(
			"Frame Rate: %d fps",
			self.frameRateManager:getFps()
		)
	)

	self:_append(
		string.format(
			"Avg. Execution Time: %.2fμs",
			avgExecutionTime
		)
	)

	self:_append(
		string.format(
			"Delta Time: %.2fms",
			info.deltaTime * 1_000 -- From seconds to milliseconds
		)
	)

	self:_append("<b>Assembly</b>")

	self:_append(
		string.format(
			"Mass: %s (%skg)",
			Util.fmtInt(math.floor(assemblyMass)),
			Util.fmtInt(math.floor(Util.toKg(assemblyMass)))
		)
	)

	self:_append(
		string.format(
			"Direction: %d (%s)",
			info.chassisInst:getAssemblyDirection(),
			direction
		)
	)

	self:_append(
		string.format(
			"State: %d (%s)",
			info.chassisInst:getAssemblyVelocityState(),
			state
		)
	)

	self:_append(
		string.format(
			"Velocity: %d (%dmph)",
			assemblyVelocity,
			Util.toMilesPerHour(assemblyVelocity)
		)
	)

	self:_append("<b>Input</b>")

	self:_append(
		string.format(
			"Steer Float: %d (%s)",
			info.steerFloat,
			if info.steerFloat == 0 then "Straight" else if info.steerFloat < 0 then "Left" else "Right"
		)
	)

	self:_append(
		string.format(
			"Throttle Float: %d (%s)",
			info.throttleFloat,
			if info.throttleFloat == 0 then "Neutral" else if info.throttleFloat > 0 then "Forward" else "Backwards"
		)
	)

	self:_append("<b>Motor</b>")

	self:_append(
		string.format(
			"Pitch: %.2f",
			info.chassisInst:getRevPlaybackSpeed()
		)
	)

	self:_append(
		string.format(
			"Torque: %d",
			info.chassisInst:getMotorTorque()
		)
	)

	self:_append(
		string.format(
			"Horsepower: %d",
			info.chassisInst:getMotorHorsepower()
		)
	)

	self:_append(
		string.format(
			"Angular Velocity: %s",
			Util.fmtInt(math.floor(info.output.angularVelocity))
		)
	)

	self:_append(
		string.format(
			"Angular Frequency: %drpm",
			math.floor(info.chassisInst:getMotorRPM())
		)
	)

	self:_append(
		string.format(
			"Max Angular Acceleration: %d",
			info.output.motorMaxAngularAcceleration
		)
	)

	self:_append(
		string.format(
			"Max Torque: %d",
			info.output.motorMaxTorque
		)
	)

	self:_append("<b>Transmission</b>")

	self:_append(
		string.format(
			"Gear: %s",
			info.chassisInst:getGear().. MvUtil.getOrdinal(info.chassisInst:getGear())
		)
	)

	self:_append("<b>Wheel</b>")

	self:_append(
		string.format(
			"Turn Angle: %.2fdeg",
			info.output.angle
		)
	)
end

function Stats.destroy(self: Types.Stats)
	for _, label in self.labels do
		label:Destroy()
	end
	self.labels = {}
	self.index = 0

	for _, child: Instance in self.gui.Stats:GetChildren() do
		if not child:IsA("UIGridLayout") then
			child:Destroy()
		end
	end

	self.gui.Stats.UIGridLayout.Template.Parent = self.gui.Stats
end

return Stats