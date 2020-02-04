--Atlantiss.eu, 16.01.2018

-- Addon for WoW 4.3.4
-- Hides "Leave party" item from ingame dropdown menu, so you will not accidentally leave party, while you was going only to tp out of dungeon.
-- To install that addon you have to copy files AccidentalLeaver.lua and AccidentalLeaver.toc into folder "$WowRootFolder/Interface/AddOns/AccidentalLeaver/"

local AddonName = "AccidentalLeaver";
local MenuItemsToBeHidden = {
	"Leave party",
	"Leave Guild"
};
local LeavePartySlashCommand = "/leavep"; 
local MainDropDownMenuName = "DropDownList1";
local LoadSuccess = "Use "..LeavePartySlashCommand.." to leave party.";
local LoadFail = "Failed loading.";
local MenuItem;

local function RegisterSlashCommand()
	SlashCmdList[AddonName] = function(commmand)
		LeaveParty();
	end;
	SLASH_AccidentalLeaver1 = LeavePartySlashCommand; 
end;

local function Containing(Array, Value)
	for _, NextValue in ipairs(Array) do
		if NextValue == Value then return true; end;
	end;	
	return false;
end;

local function ShouldBeHidden()	
	return Containing(MenuItemsToBeHidden, MenuItem:GetText());
end;

local function IsCorrectMenuItem()	
	return MenuItem:GetObjectType() == "Button";
end;

local function TryToHideMenuItem()	
	if IsCorrectMenuItem() and ShouldBeHidden()	then 
		MenuItem:Hide();	
	end;
end;

local function OnMenuShow(Menu)
	for _, localvarMenuItem in ipairs({Menu:GetChildren()}) do
		MenuItem = localvarMenuItem;
		TryToHideMenuItem();
	end;
end;

local function FindAndHookPopupMenu()
	local Menu = getglobal(MainDropDownMenuName);
	if Menu then 
		Menu:HookScript("OnShow", OnMenuShow);
	end;
	return Menu;
end;

local function Print(Text)
	DEFAULT_CHAT_FRAME:AddMessage(AddonName..". "..tostring(Text));
end;

local function DoFrameLoad(FrameName)
	local Frame = getglobal(FrameName);
	if not Frame then 
		Print("Frame named "..FrameName.." not found");
		return;	
	end;	
	
	local OnLoad = Frame:GetScript("OnLoad");
	if not OnLoad then return; end;
	
	OnLoad(Frame);
end;

local function Start()
	if FindAndHookPopupMenu() then
		RegisterSlashCommand();	
		Print(LoadSuccess);
	else
		Print(LoadFail);	
	end;
end;

Start();

function al_checkmacro()
	if IsShiftKeyDown() then al_InitMacroFrame(); end;
	
	
	Print(MAX_ACCOUNT_MACROS);
	Print(MAX_CHARACTER_MACROS);	
end;

function al_print(Text)
	Print(Text);
end;

function al_HookShowMacro()
	local old_func = MacroFrame_Show;
	
	MacroFrame_Show = function ()
		al_print(debugstack());
		old_func();
	end
end;




