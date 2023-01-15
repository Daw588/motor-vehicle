--!strict

local Util = require(script.Util)
local Types = require(script.Types)
local Enums = require(script.Enums)

local MotorVehicle: Types.Impl = {} :: Types.Impl
MotorVehicle.__index = MotorVehicle

-- Expose helpful modules
MotorVehicle.Types = Types
MotorVehicle.Enums = Enums

function MotorVehicle.new(config: Types.Config)
	local self = setmetatable({} :: Types.Proto, MotorVehicle)

	--[[
		The current RPM that the engine is running at.
		Used for computing the gear.

		@readonly
		@external
	]]
	self._engineRPM = 0

	--[[
		The measurement of your car's ability to do work,
		meaning that the more torque, the greater amount
		of power an engine can produce. If your engine has
		a lot of torque, your vehicle can accelerate more quickly
		when the vehicle is beginning to start.

		@readonly
		@external
	]]
	self.torque = config.torque

	--[[
		Ordered list of floats that determinate ratio per gear
		(their order matters as the system takes ratio from the
		left side and as the gear goes up the index which is used
		to take the gear ratio will also increase, move to the right).

		```txt
		{2.97, 2.07, 1.43}
		  ^     ^     ^
		 First Second Third
		```

		@readonly
		@external
	]]
	self.gearRatio = config.gearRatio

	--[[
		Determinates how far the wheel can be turned (angle in degrees).

		@readonly
		@external
	]]
	self.maxSteerAngle = config.maxSteerAngle

	--[[
		Arbitrary number which defines the top speed
		at which the wheels can turn.

		@readonly
		@external
	]]
	self.turnSpeed = config.turnSpeed

	--[[
		The most important part of the vehicle,
		it will be used to determinate certain things
		like direction, speed, etc.

		@readonly
		@external
	]]
	self.root = config.root

	--[[
		List of wheels that will be driven (aka "powered")
		by the motor, those will be used to determinate
		certain states, the library will not drive them,
		that will be your job to do so.

		@readonly
		@external
	]]
	self.wheels = config.wheels

	--[[
		Currently used input for the computation.

		@readonly
		@external
	]]

	self.throttleFloat = 0

	--[[
		Currently used input for the computation.

		@readonly
		@external
	]]
	self.steerFloat = 0

	--[[
		The current gear the transmission is at.

		@internal
	]]
	self._gear = 1

	--[[
		The maximum RPM range for the engine.

		@internal
	]]
	self._maxEngineRPM = 2000

	--[[
		The minimum RPM range for the engine.

		@internal
	]]
	self._minEngineRPM = 500

	--[[
		Target wheel steer angle in degrees.

		@internal
	]]
	self._steer = 0

	--[[
		The current throttle target.

		@internal
	]]
	self._throttle = 0

	--[[
		Throttle acceleration modifier.

		@internal
	]]
	self._throttleAcceleration = 0.5

	--[[
		Maximum angular acceleration used
		during vehicle acceleration.

		@internal
	]]
	self.maxAngularAcceleration = config.maxAngularAcceleration

	return self
end

function MotorVehicle.getRevPlaybackSpeed(self: Types.MotorVehicle): number
	local pitch = math.abs(self._engineRPM / self._maxEngineRPM)

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

function MotorVehicle.getAssemblyVelocity(self: Types.MotorVehicle): number
	return self.root.AssemblyLinearVelocity.Magnitude
end

--[[
	Returns arbitrary number representing the state
	of the assembly velocity.

	You can get human readable representation of it
	by comparing the returned number with an enum
	called `AssemblyVelocityState`.

	For example:
	```lua
	if instance:getAssemblyVelocityState() == Enums.AssemblyVelocityState.Accelerating then
		print("We are accelerating!")
	end
	```
]]
function MotorVehicle.getAssemblyVelocityState(self: Types.MotorVehicle): number
	if self.throttleFloat == 0 then
		-- Gas is not being applied, therefore, it's a neutral state
		return Enums.AssemblyVelocityState.Neutral
	elseif self.throttleFloat < 0 and Util.getMoveDirection(self.root) > 0 then
		--[[
			We can tell that the user is applying breaks
			because their throttle is in the "backwards" state,
			and the vehicle is not moving in the "backwards" direction.
		]]
		return Enums.AssemblyVelocityState.Breaking
	else
		return Enums.AssemblyVelocityState.Accelerating
	end
end

--[[
	Returns arbitrary number representing direction of the assembly.

	Possible outputs are as follows:
	```lua
	1 -- forward
	0 -- at rest
	-1 -- backwards
	```
]]
function MotorVehicle.getAssemblyDirection(self: Types.MotorVehicle): number
	return Util.getMoveDirection(self.root)
end

--[[
	Returns the current gear used by
	the transmission.
]]
function MotorVehicle.getGear(self: Types.MotorVehicle): number
	return self._gear
end

--[[
	Returns angular frequency of the motor measured in RPM.
]]
function MotorVehicle.getMotorRPM(self: Types.MotorVehicle): number
	return self._engineRPM
end

--[[
	Returns torque of the motor measured in newton-meters.
]]
function MotorVehicle.getMotorTorque(self: Types.MotorVehicle): number
	return self.torque
end

--[[
	Returns horsepower of the motor,
	the value is computed with the formula
	shown below:

	```
	horsepower = (RPM * torque) / 5_252
	```
]]
function MotorVehicle.getMotorHorsepower(self: Types.MotorVehicle): number
	local RPM = self:getMotorRPM()
	local torque = self:getMotorTorque()

	return (RPM * torque) / 5_252
end

function MotorVehicle._getTurnSpeed(self: Types.MotorVehicle): number
	local turnSpeed = self.turnSpeed

	--[[
		If player is no longer steering, make the wheels
		steer back to their neutral position faster.

		This should not interfere with joystick,
		and steer wheel inputs, as they will
		keep providing steer float value other than 0
		until their position goes back to the neutral
		state, which should occur whenever the player
		stops physically steering the device, similarly
		to the keyboard input.
	]]
	if self.steerFloat == 0 then
		turnSpeed = 10
	end

	--[[
		The turn speed decreases as the steer angle
		increases, resulting in making sharp turns
		harder than the light ones.

		Turn Speed : Steer Angle
		    1            1
		   0.5           2
		   0.3           3
		   0.25          4
		   0.2           5
	]]

	turnSpeed = turnSpeed / math.clamp(math.abs(self._steer), 1, 2)

	return turnSpeed
end

function MotorVehicle._calcSteer(self: Types.MotorVehicle, deltaTime: number)
	local turnSpeed = self:_getTurnSpeed()

	-- Smooth out steering
	local steerGoal = self.steerFloat * self.maxSteerAngle
	self._steer += (steerGoal - self._steer) * math.min((deltaTime * turnSpeed), 1)
end

function MotorVehicle._calcThrottle(self: Types.MotorVehicle, deltaTime: number)
	local assemblyVelocityState = self:getAssemblyVelocityState()

	if assemblyVelocityState == Enums.AssemblyVelocityState.Neutral then
		--[[
			We want to immediately stop
			accelerating when in the neutral mode
		]]
		self._throttle = 0
	else
		self._throttle += (self.throttleFloat - self._throttle) * math.min((deltaTime * self._throttleAcceleration), 1)
	end
end

function MotorVehicle._getAngularVelocity(self: Types.MotorVehicle)
	return self.torque * self.gearRatio[self._gear] * self._throttle
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
	if self._engineRPM >= self._maxEngineRPM then
		for i = 1, #self.gearRatio do
			if self:_getAverageDriveWheelsRPM() * self.gearRatio[i] < self._maxEngineRPM then
				self._gear = i
				break
			end
		end
	end

	if self._engineRPM <= self._minEngineRPM then
		for i = 1, #self.gearRatio do
			if self:_getAverageDriveWheelsRPM() * self.gearRatio[i] > self._minEngineRPM then
				self._gear = i
				break
			end
		end
	end
end

function MotorVehicle._calcEngineRPM(self: Types.MotorVehicle)
	self._engineRPM = self:_getAverageDriveWheelsRPM() * self.gearRatio[self._gear]
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
	local assemblyVelocityState = self:getAssemblyVelocityState()

	if assemblyVelocityState == Enums.AssemblyVelocityState.Breaking then
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
		return self._throttle * -10
	elseif assemblyVelocityState == Enums.AssemblyVelocityState.Neutral then
		--[[
			We will reduce the torque and acceleration to almost
			zero BUT NEVER ZERO (this is because we want the vehicle to deaccelerate over time),
			this will cause the vehicle to freely move and won't
			deaccelerate as fast as it normally it would.
		]]
		return self._throttle
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
	--[[
		If config is provided to us,
		overwrite the current computation input.

		Sometimes someone does not want to pass
		anything due to no change, and that is fine.
	]]
	if config then
		self.steerFloat = config.steerFloat
		self.throttleFloat = config.throttleFloat
	end

	--[[
		READ THIS COMMENT, WARNING!

		The order of function calls here matters,
		changing the order can lead to getting
		undesired output!
	]]

	self:_calcSteer(deltaTime)
	self:_calcThrottle(deltaTime)

	self:_calcEngineRPM()
	self:_calcGear()

	local throttleInfluance = self:_getThrottleInfluance()

	return {
		angularVelocity = self:_getAngularVelocity(),
		angle = self._steer,
		motorMaxTorque = self.torque * throttleInfluance,
		motorMaxAngularAcceleration = self.maxAngularAcceleration * throttleInfluance
	}
end

return MotorVehicle
