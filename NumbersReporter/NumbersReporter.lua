-- mop-veins.tk, 07.11.2020
-- Use ingame chat command "/reload" after changing settings 
local Color = {	
	Green = {0.2, 1, 0.2},
	Yellow = {1, 0.82, 0},
	Gray = {0.8, 0.8, 0.8},
	Red = {0.7, 0, 0}
}

local SettingsDefault = {
	Enabled = true, --false
	Position = {0, 0},
	ReportInterval_Sec = 3,
	VSpeed_PxPerSec = -70,
	TravelDistance = 200,
	LineHeight = 32,
	ColorRGB_EfficientAmount = Color.Yellow,
	ColorRGB_ExcessiveAmount = Color.Yellow,
	FontName = [[Fonts\FRIZQT__.TTF]], -- list of fontstyles is here https://www.townlong-yak.com/framexml/live/SharedFontStyles.xml
	ShortNumbers = true	
}

function SettingsDefault:copy(SourceObject)
	local res = SourceObject or {}
	setmetatable(res, self)
	self.__index = self
	return res	
end

local SettingsHealOut = SettingsDefault:copy({
	Position = {500, 0},
	ReportInterval_Sec = 3,
	ColorRGB_EfficientAmount = Color.Green	
})

local SettingsDamageOut = SettingsDefault:copy({
	Position = {-470, 0},
	ColorRGB_ExcessiveAmount = Color.Gray,
	LineHeight = 24	
})

local SettingsHealIn = SettingsHealOut:copy({
	Enabled = true, 
	Position = {200, 200},
	ReportInterval_Sec = 2,
	LineHeight = 16,
	VSpeed_PxPerSec = 40,
	TravelDistance = 100
})

local SettingsDamageIn = SettingsDamageOut:copy({
	Enabled = true, 
	Position = {-280, 200},
	ReportInterval_Sec = 0,
	ColorRGB_EfficientAmount = Color.Red,
	LineHeight = 18,
	VSpeed_PxPerSec = 40,
	TravelDistance = 100
})

local SwingSpellId = -1
local SwingTexture = [[Interface\Icons\INV_Sword_04]]

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
	res.Settings = Settings or SettingsDefault
	res.Lines = {}
	res.LinesPool = {} 
	res.Report = {}
	res.ElapsedSinceLastReport = 0

	local Anchor = MainFrame:CreateFontString(nil, "OVERLAY", nil)
	Anchor:SetPoint("CENTER", unpack(res.Settings.Position))
	Anchor:SetSize(10, 10)
	Anchor:Show()
	res.Anchor = Anchor

	return res
end

function ReportBlock:CreateNewLine()
	local S = self.Settings
	local Frame = MainFrame

	local CreateFontString = function(Size, ColorRGB)
		local l = MainFrame:CreateFontString(nil, "OVERLAY")
		l:SetTextColor(unpack(ColorRGB))
		l:SetFont(S.FontName, Size, "OUTLINE")
		return l
	end

	local Line = CreateFontString(S.LineHeight, S.ColorRGB_EfficientAmount)

	local Icon = MainFrame:CreateTexture(nil, "OVERLAY")
	Icon:SetPoint("LEFT", Line, "RIGHT", 0, 0)
	Icon:SetSize(S.LineHeight, S.LineHeight)
	Line.Icon = Icon

	local ExtraLine = CreateFontString(S.LineHeight, S.ColorRGB_ExcessiveAmount)	
	ExtraLine:SetPoint("LEFT", Icon, "RIGHT", 0, 0)
	Line.ExtraLine = ExtraLine
	
	local ExtraLine2 = CreateFontString(S.LineHeight * 0.6, Color.Gray)	
	ExtraLine2:SetPoint("LEFT", ExtraLine, "RIGHT", 0, 0)
	Line.ExtraLine2 = ExtraLine2

	return Line
end

local function sign(a)
	if a < 0 then
		return -1
	elseif a > 0 then
		return 1
	else
		return 0
	end
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
		local _, _, _, _, yPrevLine = PrevLine:GetPoint()
		local direction = sign(self.Settings.VSpeed_PxPerSec);
		local yTmp = yPrevLine - direction * self.Settings.LineHeight
		if yTmp * direction < 0 then
			y = yTmp
		end
	end
	
	Line:SetPoint("RIGHT", self.Anchor, "LEFT", 0, y)
	
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

local function GetSpellTextureLocal(SpellId)
	if SpellId == SwingSpellId then
		return SwingTexture
	else
		return GetSpellTexture(SpellId)
	end
end

function ReportBlock:DoReport()	
	local SpellId, ReportData
	for SpellId, ReportData in pairs(self.Report)
	do
		local Line = self:GetFreshLine()
		Line.Icon:SetTexture(GetSpellTextureLocal(SpellId))
		
		local EfficientAmount, ExcessiveAmount, SourceName = unpack(ReportData)
		if EfficientAmount > 0 then
			Line:SetText(self:FormatNumber(EfficientAmount))
		end	
		if ExcessiveAmount > 0 then
			Line.ExtraLine:SetText(self:FormatNumber(ExcessiveAmount))
		end		
		if SourceName then 
			Line.ExtraLine2:SetText(SourceName)
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
		y = y + yOffset
		local CanSlideFurther = y / self.Settings.TravelDistance * sign(self.Settings.VSpeed_PxPerSec) < 1	

		if CanSlideFurther then
			Line:SetPoint(point, relativeTo, relativePoint, x, y)
		else
			Line:SetText("")
			Line.ExtraLine:SetText("")
			Line.ExtraLine2:SetText("")
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

function ReportBlock:AddToReport(args)
	local SpellId, TotalAmount, ExcessiveAmount, ExtraText = unpack(args)
	TotalAmount = TotalAmount or 0
	ExcessiveAmount = ExcessiveAmount or 0
	local EfficientAmount = TotalAmount - ExcessiveAmount
	local ReportValues = self.Report[SpellId] or {0, 0}
	ReportValues[1] = ReportValues[1] + EfficientAmount
	ReportValues[2] = ReportValues[2] + ExcessiveAmount
	ReportValues[3] = ExtraText
	self.Report[SpellId] = ReportValues
end

local RB_Heal_Out = nil
if SettingsHealOut.Enabled then RB_Heal_Out = ReportBlock:new(SettingsHealOut) end
local RB_Damage_Out = nil
if SettingsDamageOut.Enabled then RB_Damage_Out = ReportBlock:new(SettingsDamageOut) end
local RB_Heal_In = nil
if SettingsHealIn.Enabled then RB_Heal_In = ReportBlock:new(SettingsHealIn) end
local RB_Damage_In = nil
if SettingsDamageIn.Enabled then RB_Damage_In = ReportBlock:new(SettingsDamageIn) end


local function OnUpdate(Self, Elapsed)
	if RB_Heal_Out then RB_Heal_Out:OnUpdate(Elapsed) end
	if RB_Damage_Out then RB_Damage_Out:OnUpdate(Elapsed) end
	if RB_Heal_In then RB_Heal_In:OnUpdate(Elapsed) end
	if RB_Damage_In then RB_Damage_In:OnUpdate(Elapsed) end
end
MainFrame:SetScript("OnUpdate", OnUpdate);

local function OnEvent(
	Self, Event, a1, EventType, a3, SourceGUID, SourceName, a6, a7, a8, 
	TargetName, a10, a11, a12, a13, a14, a15, a16, a17, a18,
...)
	local SpellHeal = EventType == "SPELL_HEAL" or EventType == "SPELL_PERIODIC_HEAL"
	local SpellDamage = EventType == "SPELL_DAMAGE" or EventType == "SPELL_PERIODIC_DAMAGE" or EventType == "RANGE_DAMAGE"
	local Swing = EventType == "SWING_DAMAGE"

	local SpellMissed = EventType == "SPELL_MISSED" or EventType == "SPELL_PERIODIC_MISSED" or EventType == "RANGE_MISSED"
	local SwingMissed = EventType == "SWING_MISSED"

	local MissType = nil

	local FromPlayer = SourceGUID == UnitGUID("Player")
	local FromPet = SourceGUID == UnitGUID("Pet")
	local ToPlayer = TargetName and UnitIsUnit(TargetName, "Player")
	


	local args = {}
	if SpellHeal or SpellDamage then
		args = {a12, a15, a16} --SpellId, TotalAmount, ExcessiveAmount
	end
	if Swing then
		args = {SwingSpellId, a12, a13} --SpellId, TotalAmount, ExcessiveAmount
	end
	if SpellMissed then
		args = {a12, a17, 0} --SpellId, TotalAmount, ExcessiveAmount
		MissType = a15
	end	
	if SwingMissed then
		args = {SwingSpellId, a14, 0} --SpellId, TotalAmount, ExcessiveAmount
		MissType = a12
	end	


	if FromPlayer or FromPet then
		if RB_Heal_Out and SpellHeal then
			RB_Heal_Out:AddToReport(args)
		end

		if RB_Damage_Out then
			if SpellDamage or Swing then		
				RB_Damage_Out:AddToReport(args)
			end
		end
	end

	if ToPlayer then
		local ExtraText = "("..(SourceName or "Unknown")..")"..(MissType or "")
		table.insert(args, ExtraText)

		if RB_Heal_In and SpellHeal then
			RB_Heal_In:AddToReport(args)
		end

		if RB_Damage_In then
			if SpellDamage or Swing or SwingMissed or SpellMissed then		
				RB_Damage_In:AddToReport(args)
			end
		end
	end		
end
MainFrame:SetScript("OnEvent", OnEvent)
MainFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")