-- Made by: Roblox: KinderBarrel | Discord: kinderbarrel

--[[ USER GUIDE:
	>Making A Timer ->
		local TimerModule = require(path.to.script)
		local Timer = TimerModule.new(goal, rate, increment, start)
			goal: GOAL (IN SECONDS) TO REACH
			rate: TICK THE TIMER FOR EVERY rate SECOND(S)
			increment: TICK INCREASE EVERY rate SECOND(S)
			start: WHAT TIME SHOULD WE START FROM
		-> TimerModule.new(10, 1, 1, 0):Play() -> finishes in 10 seconds, counts 1 every second from 0
		-> TimerModule.new(-50, .5, -1, 0):Play() -> finishes in 25 seconds, counts -1 every .5 seconds from 0
		-> TimerModule.new(1, 1, 0, 0):Play() -> never finishes, counts every second until :Stop()
		
		Rate must be a positive value above 0.
	>Timer Methods ->
		:Play() -> Starts timer. Errors if starting a started timer.
		:Pause() -> Pauses timer. Call :Play() to unpause.
		:Stop() -> Stops timer. Also done when timer reaches goal.
		:Set[Rate, Increment, Goal, Time](x: number) -> Sets requested value.
		
		:GetTime() -> Returns 2 values. First is the increment (number of ticks * increment) and the true increment (mathematically crafted number based on increment and rate from start).
		^ Returns multiples of increment.
        ^ TimerModule.new(100, 1, 22, 0) - After 2 seconds, Timer:getTime() will return 44.
		:GetTimeToEnd() -> Returns total amount of seconds at the rate of rate and increment for start to reach goal.
		
		Methods may be chained:
		Timer:Play():Pause():Stop()
	>Timer Events ->
		Timer.onCount:Connect(function( Time, TrueTime (for debug) ))
		Timer.onComplete:Connect(function(  ))

]]

--!strict

export type Timer = typeof(setmetatable({}:: { 
	goal: number;
	rate: number;
	increment: number;
	start: number;

	trueStart: number;
	trueIncrement: number;
	pauseTime: number;

	_countBindable: BindableEvent;
	_completeBindable: BindableEvent;

	onCount: RBXScriptSignal?;
	onComplete: RBXScriptSignal?;

	_completeThread: thread;
	_countThread: thread;

	_onCompleteListener: RBXScriptConnection;
}, {}:: module ))

type module = {
	__index: module;
	new: (goal: number, rate: number, increment: number, start: number) -> Timer;

	Play: (self: Timer) -> Timer;
	Pause: (self: Timer) -> Timer;
	Stop: (self: Timer) -> nil;

	SetGoal: (self: Timer, goal: number) -> Timer;
	SetRate: (self: Timer, rate: number) -> Timer;
	SetIncrement: (self: Timer, increment: number) -> Timer;
	SetTime: (self: Timer, time: number) -> Timer;

	GetTime: (self: Timer) -> (number, number);
	GetTrueTime: (self: Timer) -> number;
	GetTimeToNextTick: (self: Timer) -> number;
	GetTimeToEnd: (self: Timer) -> number;

	CancelThreads: (self: Timer) -> nil
}

local module = {}:: module
module.__index = module

module.new = function(goal, rate, increment, start)
	if not goal or not rate or not increment or not start then error(".new() requires all parameters to be filled") end
	if type(goal) ~= "number" or type(rate) ~= "number" or type(increment) ~= "number" or type(start) ~= "number" then error(".new() requires all parameters to be numbers") end
	if -rate > 0 then error(".new() requires rate parameter to be positive and above zero") end

	local _countBindable = Instance.new("BindableEvent")
	local _completeBindable = Instance.new("BindableEvent")

	local self = setmetatable({
		goal = goal;
		rate = rate;
		increment = increment;
		start = start;

		trueStart = tick();
		trueIncrement = start;
		pauseTime = 0;

		_countBindable = _countBindable;
		_completeBindable = _completeBindable;

		onCount = _countBindable.Event;
		onComplete = _completeBindable.Event;

		_completeThread = task.spawn(function() end);
		_countThread = task.spawn(function() end);
	}, module)

	self._onCompleteListener = self.onComplete:Once(function()
		if self.Stop then
			self:Stop()
		end
	end)

	return self
end

module.CancelThreads = function(self)
	if coroutine.status(self._completeThread) == "normal" or coroutine.status(self._countThread) == "normal" then
		task.wait()
	end

	task.cancel(self._completeThread)
	task.cancel(self._countThread)
end

function module:Play()
	if coroutine.status(self._completeThread) == "running" or coroutine.status(self._countThread) == "running" then 
		error("timer is already Playing")
	end

	if self.pauseTime > 0 then
		self.pauseTime = tick() - self.pauseTime
	end

	local timeToEnd = self:GetTimeToEnd()
	self._completeThread = task.delay(timeToEnd, function()
		if self.increment == 0 then return end
		self._completeBindable:Fire()
	end)

	local function createCountThread()
		self._countThread = task.delay(self:GetTimeToNextTick(), function()
			if self.GetTime then
				self.trueIncrement += self.increment
				self._countBindable:Fire(self:GetTime())
				createCountThread()
			end
		end)
	end
	
	createCountThread()

	return self
end

function module:Pause()
	self:CancelThreads()
	self.pauseTime = tick()
	return self
end

function module:Stop()
	self._countBindable:Destroy()
	self._completeBindable:Destroy()

	self._onCompleteListener:Disconnect()
	
	if self.CancelThreads then
		self:CancelThreads()
	end
	
	setmetatable(self, nil)
end

function module:GetTime()
	local elapsedTime = self:GetTrueTime() - self.pauseTime
	return self.trueIncrement, (elapsedTime / self.rate) * self.increment
end

function module:GetTrueTime()
	return (tick() + self.start) - (self.trueStart + self.start)
end

function module:GetTimeToNextTick()
	local elapsedTime = self:GetTrueTime() - self.pauseTime
	local timeToNextTick = (self.rate - (elapsedTime % self.rate))
	return timeToNextTick
end

function module:GetTimeToEnd()
	local elapsedTime = self:GetTrueTime() - self.pauseTime
	local timeToEnd = ((self.goal - self.start) / self.increment) * self.rate - elapsedTime
	return timeToEnd
end

function module:SetGoal(goal)
	self:Pause()
	self.goal = goal
	self:Play()
	return self
end

function module:SetTime(time)
	self:Pause()
	self.start = time
	self.trueStart = tick()
	self.trueIncrement = time
	self:Play()
	return self
end

function module:SetRate(rate)
	self:Pause()
	self.rate = rate
	self:Play()
	return self
end

function module:SetIncrement(increment)
	self:Pause()
	self.increment = increment
	self:Play()
	return self
end

return module
