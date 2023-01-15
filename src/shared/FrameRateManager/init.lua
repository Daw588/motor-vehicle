--!strict

local Types = require(script.Types)

local FrameRateManager: Types.Impl = {} :: Types.Impl
FrameRateManager.__index = FrameRateManager

function FrameRateManager.new()
	local self = setmetatable({} :: Types.Proto, FrameRateManager)

	self.start = os.clock()
	self.frameUpdateTable = {}

	return self
end

function FrameRateManager.getFps(self: Types.FrameRateManager)
	self.lastIteration = os.clock()

	for index = #self.frameUpdateTable, 1, -1 do
		self.frameUpdateTable[index + 1] =
			self.frameUpdateTable[index] >= self.lastIteration - 1 and
			self.frameUpdateTable[index] or
			nil
	end

	self.frameUpdateTable[1] = self.lastIteration

	local fps =
		os.clock() - self.start >= 1 and
		#self.frameUpdateTable or
		#self.frameUpdateTable / (os.clock() - self.start)

	return math.floor(fps)
end

return FrameRateManager