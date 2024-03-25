Timer Module for complex timing needs.

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
