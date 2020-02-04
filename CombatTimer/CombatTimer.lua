local CT = CreateFrame("Frame", nil, UIParent);
CT:SetFrameStrata("BACKGROUND");
CT:SetWidth(128);
CT:SetHeight(64); 
CT:SetPoint("CENTER", 0, 400);
CT.Text = CT:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge");
CT.Text:SetAllPoints(CT);
CT:Show();


local WhenCombatStarted = GetTime();
local LastStateWasCombat = true;
local LastSecondsElapsed;

local function AnyOfMembersInCombat()
	local raidIndex, memberName;
	for raidIndex = 1, 40, 1 do
		memberName = GetRaidRosterInfo(raidIndex);
		if memberName == nil then
			if raidIndex == 1 then
				memberName = "player";
			else
				break;
			end
		end
			
		if UnitAffectingCombat(memberName) then
			return true;
		end
	end
	
	return false;
end

local function ensureTwoDigits(num)
	if num < 10 then
		return "0"..num;
	else
		return num;
	end	
end

local function CombatTimer_OnUpdate(Self, Elapsed)	
	local StateIsCombat = AnyOfMembersInCombat();
	
	if not StateIsCombat then
		if LastStateWasCombat then			
			LastStateWasCombat = false;
			LastSecondsElapsed = -1;
		end
		
		return;
	end
	
	if not LastStateWasCombat then
		LastStateWasCombat = true;
		WhenCombatStarted = GetTime();
	end

	local SecondsElapsed = math.floor(GetTime() - WhenCombatStarted);
	if SecondsElapsed == LastSecondsElapsed then
		return;
	end
	
	LastSecondsElapsed = SecondsElapsed;
	
	local h, m, s;
	
	h = math.floor(SecondsElapsed / 3600);
	h = ensureTwoDigits(h);
	m = math.floor(SecondsElapsed / 60);
	m = ensureTwoDigits(m);
	s = SecondsElapsed - m * 60;	
	s = ensureTwoDigits(s);
	
	CT.Text:SetText(h..":"..m..":"..s);
end

CT:SetScript("OnUpdate", CombatTimer_OnUpdate);
