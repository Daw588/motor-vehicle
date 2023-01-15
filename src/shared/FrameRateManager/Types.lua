--!strict

export type Impl = {
	__index: Impl,

	-- Constructor
	new: () -> FrameRateManager,

	-- External
	getFps: (self: FrameRateManager) -> number,
}

export type Proto = {
	lastIteration: number,
	frameUpdateTable: {number},
	start: number
}

export type FrameRateManager = typeof(setmetatable({} :: Proto, {} :: Impl))

return {}