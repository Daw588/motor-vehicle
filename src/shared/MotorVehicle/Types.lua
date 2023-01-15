--!strict

local Enums = require(script.Parent.Enums)

export type Impl = {
	__index: Impl,

	-- Constructor
	new: (config: Config) -> MotorVehicle,

	-- External
	Types: {},
	Enums: typeof(Enums),
	getRevPlaybackSpeed: (self: MotorVehicle) -> number,
	getAssemblyVelocity: (self: MotorVehicle) -> number,
	getAssemblyVelocityState: (self: MotorVehicle) -> number,
	getAssemblyDirection: (self: MotorVehicle) -> number,
	getGear: (self: MotorVehicle) -> number,
	getMotorRPM: (self: MotorVehicle) -> number,
	getMotorTorque: (self: MotorVehicle) -> number,
	getMotorHorsepower: (self: MotorVehicle) -> number,
	compute: (
		self: MotorVehicle,
		deltaTime: number,
		config: {
			steerFloat: number,
			throttleFloat: number
		}?
	) -> ComputeResult,

	-- Internal
	_calcSteer: (self: MotorVehicle, deltaTime: number) -> (),
	_calcThrottle: (self: MotorVehicle, deltaTime: number) -> (),
	_getAngularVelocity: (self: MotorVehicle) -> number,
	_getAverageDriveWheelsRPM: (self: MotorVehicle) -> number,
	_calcGear: (self: MotorVehicle) -> (),
	_calcEngineRPM: (self: MotorVehicle) -> (),
	_getThrottleInfluance: (self: MotorVehicle) -> number,
	_getTurnSpeed: (self: MotorVehicle) -> number
}

export type Proto = {
	-- Internal
	torque: number,
	gearRatio: {number},
	maxSteerAngle: number,
	wheels: {BasePart},
	throttleFloat: number,
	steerFloat: number,
	turnSpeed: number,
	root: BasePart,
	maxAngularAcceleration: number,

	-- External
	_maxEngineRPM: number,
	_minEngineRPM: number,
	_engineRPM: number,
	_gear: number,
	_steer: number,
	_throttle: number,
	_throttleAcceleration: number
}

export type ComputeResult = {
	angularVelocity: number,
	angle: number,
	motorMaxTorque: number,
	motorMaxAngularAcceleration: number
}

export type MotorVehicle = typeof(setmetatable({} :: Proto, {} :: Impl))

export type Config = {
	root: BasePart,
	wheels: {BasePart},
	torque: number,
	gearRatio: {number},
	maxSteerAngle: number,
	turnSpeed: number,
	maxAngularAcceleration: number
}

return {}