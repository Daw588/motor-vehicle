--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MvTypes = require(ReplicatedStorage.Shared.MotorVehicle.Types)
local FrameRateManager = require(ReplicatedStorage.Shared.FrameRateManager)

export type Impl = {
	__index: Impl,

	-- Constructor
	new: (gui: ScreenGui) -> Stats,

	-- External
	labels: {
		[number]: TextLabel
	},
	index: number,
	gui: ScreenGui,
	executionTimes: {number},
	frameRateManager: typeof(FrameRateManager),
	compute: (self: Stats, info: Info) -> nil,
	destroy: (self: Stats) -> nil,

	-- Internal
	_append: (self: Stats, str: string) -> nil,
}

export type Proto = {
	lastIteration: number,
	frameUpdateTable: {number},
	start: number
}

export type Stats = typeof(setmetatable({} :: Proto, {} :: Impl))

export type Info = {
	chassisInst: MvTypes.Proto | MvTypes.Impl,
	vehicle: Model,
	clockStart: number,
	clockEnd: number,
	deltaTime: number,
	steerFloat: number,
	throttleFloat: number,
	output: MvTypes.ComputeResult
}

return {}