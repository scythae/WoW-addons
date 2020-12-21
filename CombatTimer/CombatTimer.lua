local A = {}

A.Run = function()
	local f = CreateFrame("Frame", nil, UIParent)
	f:SetFrameStrata("BACKGROUND")
	f:SetSize(128, 64)
	f:SetPoint("CENTER", 0, 400)

	A.Frame = f

	A.Text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
	A.Text:SetAllPoints(f)

	f:SetScript("OnEvent", A.OnEvent)
	f:RegisterEvent("ENCOUNTER_START")
	f:RegisterEvent("ENCOUNTER_END")	
end

A.OnEvent = function(Self, Event)
	if Event == "ENCOUNTER_START" then
		A.WhenCombatStarted = GetTime()
		A.Brake = 0
		A.Frame:SetScript("OnUpdate", A.OnUpdate)
	end

	if Event == "ENCOUNTER_END" then
		A.Frame:SetScript("OnUpdate", nil)
	end
end

A.OnUpdate = function(Self, Elapsed)	
	A.Brake = A.Brake + Elapsed
	if A.Brake < 1 then return end
	A.Brake = A.Brake - 1

	local SecondsElapsed = math.floor(GetTime() - A.WhenCombatStarted)
	
	local h, m, s;
	
	h = math.floor(SecondsElapsed / 3600);
	h = A.EnsureTwoDigits(h);
	m = math.floor(SecondsElapsed / 60);
	m = A.EnsureTwoDigits(m);
	s = SecondsElapsed - m * 60;	
	s = A.EnsureTwoDigits(s);
	
	A.Text:SetText(h..":"..m..":"..s);
end

A.EnsureTwoDigits = function(num)
	if num < 10 then
		return "0"..num;
	else
		return num;
	end	
end




A.Run()