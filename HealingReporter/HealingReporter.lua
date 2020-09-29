--mop-veins.tk, 29.09.2020

local Settings = {}
-- after changing settings use ingame chat command /reload
Settings.Position = {300, 0}
Settings.ReportInterval_Sec = 2
Settings.VSpeed_PxPerSec = 60
Settings.TravelHeight = 200
Settings.LineHeight = 32
Settings.ColorRGB_EfficientHeal = {0.2, 1, 0.2}
Settings.ColorRGB_OverHeal = {1, 0.82, 0}
Settings.FontStyle = "GameFontNormalHuge3" -- list is here https://www.townlong-yak.com/framexml/live/SharedFontStyles.xml
Settings.ShortNumbers = true

local HR = CreateFrame("Frame", nil, UIParent)
HR:SetFrameStrata("BACKGROUND")
HR:SetPoint("CENTER", unpack(Settings.Position))
HR:SetSize(10, 10)
HR:Show()

local Lines = {}
local LinesPool = {}
local Report = {}

local ElapsedSinceLastReport = 0

local function HR_CreateNewLine()
	local Line = HR:CreateFontString(nil, "OVERLAY", Settings.FontStyle)
	Line:SetTextColor(unpack(Settings.ColorRGB_EfficientHeal))
	Line:SetTextHeight(Settings.LineHeight)

	local LinePart_Overheal = HR:CreateFontString(nil, "OVERLAY", Settings.FontStyle)
	LinePart_Overheal:SetTextColor(unpack(Settings.ColorRGB_OverHeal))
	LinePart_Overheal:SetTextHeight(Settings.LineHeight)
	LinePart_Overheal:SetPoint("LEFT", Line, "RIGHT", 0, 0)
	Line.LinePart_Overheal = LinePart_Overheal

	local Icon = HR:CreateTexture(nil, "OVERLAY")
	Icon:SetPoint("LEFT", LinePart_Overheal, "RIGHT", 0, 0)
	Icon:SetSize(Settings.LineHeight, Settings.LineHeight)
	Line.Icon = Icon

	return Line
end

local function HR_GetFreshLine()
	local Line
	if #LinesPool > 0 then
		Line = table.remove(LinesPool)
	else
		Line = HR_CreateNewLine()
	end

	local yOffset = 0
	local PrevLine = Lines[1]
	if PrevLine then
		local PrevLineY = ({PrevLine:GetPoint()})[5]
		if PrevLineY > -Settings.LineHeight then
			yOffset = PrevLineY + Settings.LineHeight
		end
	end		
	Line:SetPoint("CENTER", 0, yOffset)
	
	table.insert(Lines, 1, Line)
	return Line
end

local function HR_FormatNumber(Val)
	if Settings.ShortNumbers and Val > 1000000 then
		return string.format("%.1fkk", Val / 1000000)
	end

	if Settings.ShortNumbers and Val > 1000 then
		return string.format("%.1fk", Val / 1000)
	end

	return Val
end

local function HR_Report()
	
	local SpellId, HealAmounts
	for SpellId, HealAmounts in pairs(Report)
	do
		local Line = HR_GetFreshLine()
		local EfficientHeal, Overheal = unpack(HealAmounts)
		Line:SetText(HR_FormatNumber(EfficientHeal))
		Line.Icon:SetTexture(GetSpellTexture(SpellId))
	
		if Overheal > 0 then
			Line.LinePart_Overheal:SetText(" ("..HR_FormatNumber(Overheal)..")")
		end
	end

	Report = {}
end

local function HR_OnUpdate(Self, Elapsed)	
	local VShift = Elapsed * Settings.VSpeed_PxPerSec

	ElapsedSinceLastReport = ElapsedSinceLastReport + Elapsed
	if ElapsedSinceLastReport > Settings.ReportInterval_Sec then
		HR_Report()
		ElapsedSinceLastReport = 0
	end

	local i, Line
	for i = #Lines, 1, -1
	do
		Line = Lines[i]
		point, relativeTo, relativePoint, xOfs, yOfs = Line:GetPoint()
		yOfs = yOfs - VShift
		if yOfs > -Settings.TravelHeight then
			Line:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs)
		else
			Line:SetText("")
			Line.LinePart_Overheal:SetText("")
			Line.Icon:SetTexture(nil)
			table.remove(Lines)
			table.insert(LinesPool, Line)
		end		
	end
end
HR:SetScript("OnUpdate", HR_OnUpdate);

local function HR_OnEvent(
	Self, Event, a1, EventType, _, _, SourceName, a6, _, _, 
	TargetName, a10, a11, SpellId, SpellName, _, Amount, Overheal, a17, a18,
...)
	local Healing = EventType == "SPELL_HEAL";
	local HealingPeriodic = EventType == "SPELL_PERIODIC_HEAL";
	local PlayerHeals = (Healing or HealingPeriodic) and SourceName 
		and UnitIsUnit(SourceName, "Player");

	if not PlayerHeals then return end

	local EfficientHeal = Amount - Overheal

	local ReportValues = Report[SpellId] or {0, 0}
	ReportValues[1] = ReportValues[1] + EfficientHeal
	ReportValues[2] = ReportValues[2] + Overheal
	Report[SpellId] = ReportValues
end
HR:SetScript("OnEvent", HR_OnEvent);
HR:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");


local function RunTests()
	local t = {}
	local passed = true
	local str
	
	table.insert(t, "asd");
	table.insert(t, "qwe");
	passed = passed and #t == 2 and t[1] == "asd" and t[2] == "qwe";
	
	str = ""
	local i
	for i = #t, 1, -1
	do
		str = str..t[i]
	end
	passed = passed and str == "qweasd"
	
	str = table.remove(t);
	passed = passed and #t == 1 and str == "qwe";
	
	str = table.remove(t);
	passed = passed and #t == 0 and str == "asd";
	
	table.insert(t, "asd");
	table.insert(t, "qwe");
	table.insert(t, 1, "zxc")
	passed = passed and #t == 3 and t[1] == "zxc" and t[3] == "qwe"
	
	local function TestArray()
		return "qwe", "asd", "zxc"
	end
	t = {TestArray()}
	passed = passed and #t == 3 and t[1] == "qwe" and t[3] == "zxc"
	
	local function TestUnpack(a, b, c)
		return a == 1 and b == 2 and c == 3
	end
	passed = passed and TestUnpack(unpack({1, 2, 3}))
	
	passed = passed and ({"a", "s", "d"})[3] == "d"
	
	--sparsed array
	t = {}
	t[123] = "a"
	t[234] = "b"
	str = ""
	local key, val
	for key, val in pairs(t)
	do
		str = str..key..val
	end
	passed = passed and str == "123a234b"
	
	
	print("passed: "..tostring(passed));
end

--RunTests()

