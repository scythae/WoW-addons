local ST = CreateFrame("Frame", nil, UIParent);
ST:SetFrameStrata("BACKGROUND");
ST:SetWidth(128);
ST:SetHeight(64); 
ST:SetPoint("CENTER",-250,-150);
ST.Text = ST:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge");
ST.Text:SetAllPoints(ST);
ST:Show();

local function StaggerTracker_OnEvent(
	Self, Event, _, EventType, _, _, _, _, _, _, 
	UnitId, _, _, _, SpellName, _, DamageAmount,
...)
	if not UnitId or not UnitIsUnit(UnitId, "Player") then return; end;
	if not SpellName or not string.find(SpellName, "Stagger") then return; end;
	if not EventType then return; end;
	
	if (EventType == "SPELL_PERIODIC_DAMAGE") then 
		ST.Text:SetText("Stagger: "..(DamageAmount * 10));
		return;
	end;
	
	if (EventType == "SPELL_AURA_REMOVED") then 
		ST.Text:SetText("");
		return;
	end;
end

ST:SetScript("OnEvent", StaggerTracker_OnEvent);
ST:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
