-- tauriwow.com, 2020-12-21

local AddonName = ...
local SlashCommand = "/delayscript"

local function ExecuteScript(st)
	RunScript(st)
end

local function ScheduleScript(CommandText)
	local DelayInSeconds, ScriptText = strsplit(" ", CommandText, 2)
	DelayInSeconds = tonumber(DelayInSeconds)

	if not(
		type(DelayInSeconds) == "number" 
		and type(ScriptText) == "string"
	) then	
		local err = "Usage: %s DelayInSeconds ScriptText"
		err = string.format(err, SlashCommand)
		error(err, 2)
	end

	Delay(DelayInSeconds, ExecuteScript, {ScriptText})
end

local function RegisterSlashCommand()
	_G["SLASH_"..AddonName.."1"] = SlashCommand
	SlashCmdList[AddonName] = ScheduleScript
end

RegisterSlashCommand()