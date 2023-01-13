--!strict

local Util = {}

function Util.getMoveDirection(part: BasePart): number
	local direction = -(part.CFrame.Rotation:Inverse() * part.AssemblyLinearVelocity).Z
	direction = math.abs(direction) <= 0.001 and 0 or math.sign(direction)
	return direction
end

function Util.isFlipped(part: BasePart): boolean
	local upVector = part.CFrame.UpVector
	local position = part.Position
	return position.Y > (position + upVector).Y
end

-- "Radians per second" to "revolutions per minute"
function Util.rpsToRPM(rps: number): number
	-- Extra "* 4" is for "weight" to better simulate RPM, don't ask me why...
	return rps * 9.5493 * 4
end

function Util.getEnumName(enum, value: string | number)
	for name, val in enum do
		if val == value then
			return name
		end
	end
end

--[[
	What is "ordinal" number?

	A number defining a thing's position in a series,
	such as "first," "second," or "third." Ordinal numbers
	are used as adjectives, nouns, and pronouns.

	For example:

	f(1) -> "st"
	f(2) -> "nd"
	f(3) -> "rd"
	f(4) -> "th"
	f(5) -> "th"
]]
function Util.getOrdinal(x: number): string
	if x == 1 then
		return "st"
	elseif x == 2 then
		return "nd"
	elseif x == 3 then
		return "rd"
	end

	return "th"
end

return Util
