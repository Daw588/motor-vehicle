--!strict

local Util = require(script.Util)
local Types = require(script.Types)
local Enums = require(script.Enums)

local MotorVehicle: Types.Impl = {} :: Types.Impl
MotorVehicle.__index = MotorVehicle

function MotorVehicle.new(config: Types.Config)
	local self = setmetatable({} :: Types.Proto, MotorVehicle)

	self.torque = config.torque
	self.gearRatio = config.gearRatio
	self.maxSteerAngle = config.maxSteerAngle
	self.turnSpeed = config.turnSpeed
	self.root = config.root
	self.wheels = config.wheels

	self.maxEngineRPM = 2000 -- @readonly
	self.minEngineRPM = 500 -- @readonly

	self.engineRPM = 0
	self.gear = 1
	self.steer = 0
	self.throttle = 0

	self.throttleFloat = 0
	self.steerFloat = 0

	self.throttleAcceleration = 0.5
	self.maxAngularAcceleration = 5

	return self
end

function MotorVehicle.getPitch(self: Types.MotorVehicle): number
	local pitch = math.abs(self.engineRPM / self.maxEngineRPM)

	--[[
		We dont want to apply excessive pitch,
		this is really helpful when vehicle
		drops into void, or glitches out which
		would normally cause the pitch to go crazy
		due to enormous velocity, but since we are
		limiting the number to max of 2 and min 0,
		it won't go too crazy.
	]]
	return math.clamp(pitch, 0, 2)
end

function MotorVehicle.getSpeed(self: Types.MotorVehicle): number
	return self.root.AssemblyLinearVelocity.Magnitude
end

function MotorVehicle.getThrottleState(self: Types.MotorVehicle): number
	if self.throttleFloat == 0 then
		-- Gas is not being applied, therefore, it's a neutral state
		return Enums.ThrottleState.Neutral
	elseif self.throttleFloat < 0 and Util.getMoveDirection(self.root) > 0 then
		--[[
			We can tell that the user is applying breaks
			because their throttle is in the "backwards" state,
			and the vehicle is not moving in the "backwards" direction.
		]]
		return Enums.ThrottleState.Breaking
	else
		return Enums.ThrottleState.Accelerating
	end
end

function MotorVehicle.getDirection(self: Types.MotorVehicle): number
	return Util.getMoveDirection(self.root)
end

function MotorVehicle._calcSteer(self: Types.MotorVehicle, deltaTime: number)
	--[[
		Dynamic Steer Speed (DSS)

		The turn speed decreases as the steer angle decreases,
		resulting in making sharper turns harder than the light turns.

		Turn Speed : Steer Angle
		    1            1
		   0.5           2
		   0.3           3
		   0.25          4
		   0.2           5
	]]
	local turnSpeed = self.turnSpeed / math.clamp(math.abs(self.steer), 1, 2)

	-- Smooth out steering
	local steerGoal = self.steerFloat * self.maxSteerAngle
	self.steer += (steerGoal - self.steer) * math.min((deltaTime * turnSpeed), 1)
end

function MotorVehicle._calcThrottle(self: Types.MotorVehicle, deltaTime: number)
	local throttleState = self:getThrottleState()

	if throttleState == Enums.ThrottleState.Neutral then
		--[[
			We want to immediately stop
			accelerating when in the neutral mode
		]]
		self.throttle = 0
	else
		self.throttle += (self.throttleFloat - self.throttle) * math.min((deltaTime * self.throttleAcceleration), 1)
	end
end

function MotorVehicle._getAngularVelocity(self: Types.MotorVehicle)
	return self.torque * self.gearRatio[self.gear] * self.throttle
end

function MotorVehicle:_getAverageDriveWheelsRPM()
	local leftWheelRPM = Util.rpsToRPM(self.wheels[1].AssemblyAngularVelocity.Magnitude)
	local rightWheelRPM = Util.rpsToRPM(self.wheels[2].AssemblyAngularVelocity.Magnitude)

	-- Gets the average RPM of the 2 wheels
	return (leftWheelRPM + rightWheelRPM) / 2
end

--[[
	Automatic transmission, shifts to different
	gear depending on the engine RPM.
]]
function MotorVehicle._calcGear(self: Types.MotorVehicle)
	if self.engineRPM >= self.maxEngineRPM then
		for i = 1, #self.gearRatio do
			if self:_getAverageDriveWheelsRPM() * self.gearRatio[i] < self.maxEngineRPM then
				self.gear = i
				break
			end
		end
	end

	if self.engineRPM <= self.minEngineRPM then
		for i = 1, #self.gearRatio do
			if self:_getAverageDriveWheelsRPM() * self.gearRatio[i] > self.minEngineRPM then
				self.gear = i
				break
			end
		end
	end
end

function MotorVehicle._calcEngineRPM(self: Types.MotorVehicle)
	self.engineRPM = self:_getAverageDriveWheelsRPM() * self.gearRatio[self.gear]
end

--[[
	Used to multiply torque and max angular
	acceleration depending on throttle actions.
	
	When breaking, we want the motor to apply
	velocity at higher torque and acceleration.
	This is because breaks will need to deaccelerate
	the vehicle at faster rate than regular acceleration.
	Breaks don't need to apply ton of energy to result in
	high velocity reduction.
	
	When in neutral, we want the motor to apply
	little BUT NOT ZERO torque and acceleration. This is
	because we don't want the vehicle to deaccelerate
	as fast as it would with torque and acceleration.
	
	On the note, it is possible that changing
	torque in the neutral mode has zero effect
	on the outcome, the deacceleration rate.
]]
function MotorVehicle._getThrottleInfluance(self: Types.MotorVehicle)
	local throttleState = self:getThrottleState()

	if throttleState == Enums.ThrottleState.Breaking then
		--[[
			Since we are breaking the throttle will be negative or positive depending
			on the direction that the vehicle is breaking in, to reverse this effect,
			we will make an opposite number by using negative sign (-) in front of our "modifier" number.

			return -0.5 * -1 = 0.5

			To simulate how breaks work in real life, we will multiply
			the throttle by a somewhat big number which will make deaccelerating
			much faster and therefore feeling like actual breaks.

			return -0.5 * -10 = 5
		]]
		return self.throttle * -10
	elseif throttleState == Enums.ThrottleState.Neutral then
		--[[
			We will reduce the torque and acceleration to almost
			zero BUT NEVER ZERO (this is because we want the vehicle to deaccelerate over time),
			this will cause the vehicle to freely move and won't
			deaccelerate as fast as it normally it would.
		]]
		return self.throttle
	else
		--[[
			Since the vehicle is accelerating,
			we won't make any modification to the
			output torque and max acceleration.

			To that, we will use 1, since x * 1 will remain x,
			in other words x * 1 = 1 no matter what the x is.
		]]
		return 1
	end
end

function MotorVehicle.compute(self: Types.MotorVehicle, deltaTime: number, config: { steerFloat: number, throttleFloat: number }?)
	if config then
		self.steerFloat = config.steerFloat
		self.throttleFloat = config.throttleFloat
	end

	self:_calcSteer(deltaTime)
	self:_calcThrottle(deltaTime)

	self:_calcEngineRPM()
	self:_calcGear()

	local throttleInfluance = self:_getThrottleInfluance()

	return {
		angularVelocity = self:_getAngularVelocity(),
		angle = self.steer,
		motorMaxTorque = self.torque * throttleInfluance,
		motorMaxAngularAcceleration = self.maxAngularAcceleration * throttleInfluance
	}
end

return MotorVehicle
