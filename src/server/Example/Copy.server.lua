local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Util = require(ReplicatedStorage.Shared.Util)

Util.InstanceTagged("Vehicle", function(taggedInstance)
	local server = script.Parent.Server:Clone()
	server.Parent = taggedInstance.Chassis
	server.Enabled = true
end)