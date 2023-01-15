--!strict

local CollectionService = game:GetService("CollectionService")

local Util = {}

function Util.showCharacter(player: Player)
	local character = player.Character or player.CharacterAdded:Wait()
	for _, object in pairs(character:GetDescendants()) do
		if object == character.PrimaryPart or object.Name == "HumanoidRootPart" then
			continue
		end

		if not object:IsA("BasePart") and not object:IsA("Decal") and not object:IsA("Texture") then
			continue
		end

		object.Transparency = 0

		if object.Name == "Head" then
			local face = script:FindFirstChild("face")
			if face then
				face.Transparency = 0
				face.Parent = object
			end
		end

		if not object:IsA("BasePart") then
			continue
		end
		object.CanCollide = true
	end
end

function Util.hideCharacter(player: Player)
	local character = player.Character or player.CharacterAdded:Wait()
	for _, object in pairs(character:GetDescendants()) do
		if object == character.PrimaryPart or object.Name == "HumanoidRootPart" then
			continue
		end

		if not object:IsA("BasePart") and not object:IsA("Decal") and not object:IsA("Texture") then
			continue
		end

		object.Transparency = 1

		if string.lower(object.Name) == "face" then
			object.Parent = script
		end

		if not object:IsA("BasePart") then
			continue
		end
		object.CanCollide = false
	end
end

function Util.getNamedChildren(parent: Instance)
	local children = {}
	for _, child in parent:GetChildren() do
		children[child.Name] = child
	end
	return children
end

function Util.InstanceTagged(tagName: string, callback)
	CollectionService:GetInstanceAddedSignal(tagName):Connect(function(taggedInstance)
		callback(taggedInstance)
	end)

	for _, taggedInstance in CollectionService:GetTagged(tagName) do
		callback(taggedInstance)
	end
end

--[[
	Converts roblox units of mass to real world mass in kilograms

	source: https://devforum.roblox.com/t/conversion-of-roblox-and-real-world-units/133327/4
]]
function Util.toKg(mass: number)
	return mass / 8
end

function Util.getAssemblyMass(assembly: Model)
	local sum = 0

	for _, v in assembly:GetDescendants() do
		if v:IsA("BasePart") then
			sum += v.AssemblyMass
		end
	end

	return sum
end

function Util.fmtInt(number: number)
	local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')

	-- reverse the int-string and append a comma to all blocks of 3 digits
	int = int:reverse():gsub("(%d%d%d)", "%1,")

	-- reverse the int-string back remove an optional comma and put the
	-- optional minus and fractional part back
	return minus .. int:reverse():gsub("^,", "") .. fraction
end

function Util.toKilometerPerSec(velocity: number)
	return velocity * 1.09728
end

function Util.toMeterPerSec(velocity: number)
	return Util.toKilometerPerSec(velocity) / 3.6
end

function Util.toMilesPerHour(velocity: number)
	return (velocity * 3600) * 0.0001739839
end


return Util