-- tauriwow.com, 2020-12-21

local AddonName = ...
local GlobalFunctionName = "Delay"
local CheckInterval = 0.2

local Core = {}
Core.Tasks = {}
local ElapsedSinceLastCheck = 0

Core.Run = function()
	CreateFrame("Frame"):SetScript("OnUpdate", Core.OnUpdate)
	_G[GlobalFunctionName] = Core.PutTask
end

Core.PutTask = function(DelayInSeconds, Callback, Parameters)
	if Parameters == nil then Parameters = {} end

	if not(
		type(DelayInSeconds) == "number" 
		and type(Callback) == "function"
		and type(Parameters) == "table"		
	) then
		local err = "Usage: %s(DelayInSeconds: number, Callback: function, [Parameters: table])"
		err = string.format(err, GlobalFunctionName)
		error(err, 2)
	end

	local WhenExecute = GetTime() + tonumber(DelayInSeconds)	

	local Task = {}
	Task.Time = WhenExecute
	Task.Callback = Callback
	Task.Parameters = Parameters
	
	table.insert(Core.Tasks, Task)
end

Core.OnUpdate = function(Self, Elapsed)
	ElapsedSinceLastCheck = ElapsedSinceLastCheck + Elapsed
	if ElapsedSinceLastCheck < CheckInterval then return end
	ElapsedSinceLastCheck = ElapsedSinceLastCheck - CheckInterval	
	
	Core.RunTasks()
end

Core.RunTasks = function()
	local Tasks = Core.Tasks
	if #Tasks == 0 then return end
	
	local Now = GetTime()
	
	local i
	for i = #Tasks, 1, -1
	do
		local Task = Tasks[i]
		if Task.Time < Now then 
			table.remove(Tasks, i)
			Task.Callback(unpack(Task.Parameters))
		end
	end
end

Core.Run()