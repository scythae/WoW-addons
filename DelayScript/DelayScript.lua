--mop-veins.tk, 10.04.2019

local AddonName = "DelayScript";
local DelaySlashCommand = "/delayscript";
local Schedule = {};

local function Print(Text)
	DEFAULT_CHAT_FRAME:AddMessage(AddonName..". "..tostring(Text));
end;

local function Trim(Text, TrimChar)
	if not Text then return; end;
	TrimChar = TrimChar or " ";
	return string.gsub(Text, "^["..TrimChar.."]*(.-)["..TrimChar.."]*$", "%1", 1);
end;

local function CutLexem(Text, Delimiter)
	if not strfind(Text, Delimiter) then
		return Text, nil;
	end;
	
	Text = Trim(Text, Delimiter);	
	local Lexem = string.gsub(Text, "^(.-)["..Delimiter.."]+.*$", "%1");
	local RestText = string.gsub(Text, "^.-["..Delimiter.."]+(.*)$", "%1");
	
	return Lexem, RestText; 
end;

local function PutDelayedScript(DelayInSeconds, ScriptText)
	local WhenExecute = GetTime() + tonumber(DelayInSeconds);
	
	local Task = {};
	Task.Time = WhenExecute;
	Task.Script = ScriptText;
	
	table.insert(Schedule, Task);
end;

local function ScheduleScript(CommandText)
	local DelayInSeconds, ScriptText = CutLexem(CommandText, " "); 
	if not DelayInSeconds or not ScriptText then
		return;
	end;
	
	PutDelayedScript(DelayInSeconds, ScriptText);
end;

local function RegisterSlashCommand()
	SlashCmdList[AddonName] = function(command)
		ScheduleScript(command);
	end;
	SLASH_DelayScript1 = DelaySlashCommand; 
end;

RegisterSlashCommand();	
Print("Is loaded.");

local function RunScheduledScripts()
	if #Schedule == 0 then
		return;
	end;	
	
	local Now = GetTime();
	local CountOfPassed = 0;
	local index, Task;
	
	for index, Task in ipairs(Schedule) do
		if Task.Time < Now then
			CountOfPassed = CountOfPassed + 1;	
			
			xpcall(
				function()
					RunScript(Task.Script);
				end,
				function()
					Print("Failure of executing script. "..Task.Script);
				end
			);
		end;
	end;	
	
	while (CountOfPassed > 0) do 
		table.remove(Schedule, CountOfPassed);
		CountOfPassed = CountOfPassed - 1; 
	end;
end;

local ElapsedSinceLastCheck = 0;
local function DelayScript_OnUpdate(Self, Elapsed)
	if ElapsedSinceLastCheck < 0.3 then
		ElapsedSinceLastCheck = ElapsedSinceLastCheck + Elapsed;
		return;
	end;
	ElapsedSinceLastCheck = 0;	
	
	RunScheduledScripts();
end

function dsdebug_print(text)
	Print(text);
end;

local function NotifyAboutPull(Text)
	SendChatMessage(Text, "Say", nil, nil);
end;

function ds_pull(SecondsRemained)
	local DelayBeforeNextWarning = 1;
	local Message;	

	if SecondsRemained > 0 then
		PutDelayedScript(DelayBeforeNextWarning, "ds_pull("..(SecondsRemained - DelayBeforeNextWarning)..")");
		Message = "Pull in "..SecondsRemained;
	else
		Message = "Go";
	end;
	
	NotifyAboutPull(Message);
end;

local DS = CreateFrame("Frame", nil, UIParent);
DS:SetScript("OnUpdate", DelayScript_OnUpdate);
