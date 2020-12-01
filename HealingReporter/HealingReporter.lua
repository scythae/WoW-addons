-- mop-veins.tk, 07.11.2020
-- Use ingame chat command "/reload" after changing settings 
local Preset = {}
Preset.DefaultFont = "GameFontNormalHuge3" -- list is here https://www.townlong-yak.com/framexml/live/SharedFontStyles.xml
Preset.ColorRGB_Green = {0.2, 1, 0.2}
Preset.ColorRGB_Yellow = {1, 0.82, 0}
Preset.ColorRGB_Gray = {0.8, 0.8, 0.8}

local SettingsHeal = {
	Position = {500, 0},
	ReportInterval_Sec = 3,
	VSpeed_PxPerSec = 70,
	TravelHeight = 200,
	LineHeight = 32,
	ColorRGB_EfficientAmount = Preset.ColorRGB_Green,
	ColorRGB_ExcessiveAmount = Preset.ColorRGB_Yellow,
	FontStyle = Preset.DefaultFont,
	ShortNumbers = true
}
local SettingsDamage = {
	Position = {-470, 0},
	ReportInterval_Sec = 3,
	VSpeed_PxPerSec = 70,
	TravelHeight = 180,
	LineHeight = 24,
	ColorRGB_EfficientAmount = Preset.ColorRGB_Yellow,
	ColorRGB_ExcessiveAmount = Preset.ColorRGB_Gray,
	FontStyle = Preset.DefaultFont,
	ShortNumbers = true
}



local MainFrame = CreateFrame("Frame", nil, UIParent)
MainFrame:SetFrameStrata("BACKGROUND")
MainFrame:SetPoint("CENTER")
MainFrame:SetSize(10, 10)
MainFrame:Show()

local ReportBlock = {}
function ReportBlock:new(Settings)
	local res = {}
	setmetatable(res, self)
	self.__index = self
	res.Settings = Settings or SettingsHeal
	res.Lines = {}
	res.LinesPool = {} 
	res.Report = {}
	res.ElapsedSinceLastReport = 0

	local Anchor = CreateFrame("Frame", nil, MainFrame)
	Anchor:SetFrameStrata("BACKGROUND")
	Anchor:SetPoint("CENTER", unpack(res.Settings.Position))
	Anchor:SetSize(10, 10)
	Anchor:Show()
	res.Anchor = Anchor

	return res
end

function ReportBlock:CreateNewLine()
	local S = self.Settings
	local Anchor = self.Anchor

	local Line = Anchor:CreateFontString(nil, "OVERLAY", S.FontStyle)
	Line:SetTextColor(unpack(S.ColorRGB_EfficientAmount))
	Line:SetTextHeight(S.LineHeight)

	local Icon = Anchor:CreateTexture(nil, "OVERLAY")
	Icon:SetPoint("LEFT", Line, "RIGHT", 0, 0)
	Icon:SetSize(S.LineHeight, S.LineHeight)
	Line.Icon = Icon

	local ExtraLine = Anchor:CreateFontString(nil, "OVERLAY", S.FontStyle)
	ExtraLine:SetTextColor(unpack(S.ColorRGB_ExcessiveAmount))
	ExtraLine:SetTextHeight(S.LineHeight)
	ExtraLine:SetPoint("LEFT", Icon, "RIGHT", 0, 0)
	Line.ExtraLine = ExtraLine

	return Line
end

function ReportBlock:GetFreshLine()
	local Line
	if #(self.LinesPool) > 0 then
		Line = table.remove(self.LinesPool)
	else
		Line = self:CreateNewLine()
	end

	local y = 0
	local PrevLine = self.Lines[1]
	if PrevLine then
		local yPrevLine = ({PrevLine:GetPoint()})[5]
		local yTmp = yPrevLine + self.Settings.LineHeight
		if yTmp > 0 then
			y = yTmp
		end
	end
	
	Line:SetPoint("RIGHT", 0, y)
	
	table.insert(self.Lines, 1, Line)
	return Line
end

function ReportBlock:FormatNumber(Val)
	local ShortNumbers = self.Settings.ShortNumbers

	if ShortNumbers and Val > 1000000 then
		return string.format("%.1fkk", Val / 1000000)
	end

	if ShortNumbers and Val > 1000 then
		return string.format("%.1fk", Val / 1000)
	end

	return Val
end

function ReportBlock:DoReport()	
	local SpellId, Amounts
	for SpellId, Amounts in pairs(self.Report)
	do
		local Line = self:GetFreshLine()
		Line.Icon:SetTexture(GetSpellTexture(SpellId))
		
		local EfficientAmount, ExcessiveAmount = unpack(Amounts)
		if EfficientAmount > 0 then
			Line:SetText(self:FormatNumber(EfficientAmount))
		end	
		if ExcessiveAmount > 0 then
			Line.ExtraLine:SetText(self:FormatNumber(ExcessiveAmount))
		end
	end

	self.Report = {}
end

function ReportBlock:TryReport(Elapsed)
	self.ElapsedSinceLastReport = self.ElapsedSinceLastReport + Elapsed
	if self.ElapsedSinceLastReport > self.Settings.ReportInterval_Sec then
		self:DoReport()
		self.ElapsedSinceLastReport = 0
	end
end

function ReportBlock:SlideLines(Elapsed)
	local Lines = self.Lines
	local yOffset = Elapsed * self.Settings.VSpeed_PxPerSec

	local i, Line
	for i = #Lines, 1, -1
	do
		Line = Lines[i]
		point, relativeTo, relativePoint, x, y = Line:GetPoint()
		y = y - yOffset
		local CanSlideFurther = y >  -self.Settings.TravelHeight
		if CanSlideFurther then
			Line:SetPoint(point, relativeTo, relativePoint, x, y)
		else
			Line:SetText("")
			Line.ExtraLine:SetText("")
			Line.Icon:SetTexture(nil)
			table.remove(Lines)
			table.insert(self.LinesPool, Line)
		end		
	end
end

function ReportBlock:OnUpdate(Elapsed)
	self:TryReport(Elapsed)
	self:SlideLines(Elapsed)
end

function ReportBlock:AddToReport(SpellId, TotalAmount, ExcessiveAmount)
	local EfficientAmount = TotalAmount - ExcessiveAmount
	local ReportValues = self.Report[SpellId] or {0, 0}
	ReportValues[1] = ReportValues[1] + EfficientAmount
	ReportValues[2] = ReportValues[2] + ExcessiveAmount
	self.Report[SpellId] = ReportValues
end

local RB_Heal = ReportBlock:new(SettingsHeal)
local RB_Damage = ReportBlock:new(SettingsDamage)

local function HR_OnUpdate(Self, Elapsed)
	RB_Heal:OnUpdate(Elapsed)
	RB_Damage:OnUpdate(Elapsed)
end
MainFrame:SetScript("OnUpdate", HR_OnUpdate);

local function HR_OnEvent(
	Self, Event, a1, EventType, a3, a4, SourceName, a6, a7, a8, 
	TargetName, a10, a11, SpellId, SpellName, a14, TotalAmount, ExcessiveAmount, a17, a18,
...)
	local ActionsOfPlayer = SourceName and UnitIsUnit(SourceName, "Player")
	if not ActionsOfPlayer then return end	

	if EventType == "SPELL_HEAL" or EventType == "SPELL_PERIODIC_HEAL" then
		RB_Heal:AddToReport(SpellId, TotalAmount, ExcessiveAmount)
	end

	if EventType == "SPELL_DAMAGE" or EventType == "SPELL_PERIODIC_DAMAGE" then		
		RB_Damage:AddToReport(SpellId, TotalAmount, ExcessiveAmount)
	end
end
MainFrame:SetScript("OnEvent", HR_OnEvent)
MainFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")