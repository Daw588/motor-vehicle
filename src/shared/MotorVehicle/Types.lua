--!strict

export type Impl = {
	__index: Impl,

	-- Constructor
	new: (config: Config) -> MotorVehicle,

	-- External
	getPitch: (self: MotorVehicle) -> number,
	getSpeed: (self: MotorVehicle) -> number,
	getThrottleState: (self: MotorVehicle) -> number,
	getDirection: (self: MotorVehicle) -> number,
	compute: (self: MotorVehicle, deltaTime: number, config: { steerFloat: number, throttleFloat: number }?) -> {
		angularVelocity: number,
		angle: number,
		motorMaxTorque: number,
		motorMaxAngularAcceleration: number
	},

	-- Internal
	_calcSteer: (self: MotorVehicle, deltaTime: number) -> (),
	_calcThrottle: (self: MotorVehicle, deltaTime: number) -> (),
	_getAngularVelocity: (self: MotorVehicle) -> number,
	_getAverageDriveWheelsRPM: (self: MotorVehicle) -> number,
	_calcGear: (self: MotorVehicle) -> (),
	_calcEngineRPM: (self: MotorVehicle) -> (),
	_getThrottleInfluance: (self: MotorVehicle) -> number
}

export type Proto = {
	torque: number,
	gearRatio: {number},
	maxSteerAngle: number,
	wheels: {BasePart},
	maxEngineRPM: number,
	minEngineRPM: number,
	engineRPM: number,
	gear: number,
	steer: number,
	throttle: number,
	throttleFloat: number,
	steerFloat: number,
	throttleAcceleration: number,
	maxAngularAcceleration: number,
	turnSpeed: number,
	root: BasePart
}

export type MotorVehicle = typeof(setmetatable({} :: Proto, {} :: Impl))

export type Config = {
	root: BasePart,
	wheels: {BasePart},
	torque: number,
	gearRatio: {number},
	maxSteerAngle: number,
	turnSpeed: number
}

return {}