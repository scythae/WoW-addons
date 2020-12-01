-- mop-veins.tk, 2020-12-01
-- Use ingame chat command "/reload" after changing settings 

-- User's part:

local Talents = {}
Talents["The Summer Terrace"] = {2, 15}
Talents["Chamber of the Paragons"] = {2, 15}
--[[
Talents Ids:
lvl15 | 01 02 03
lvl30 | 04 05 06
lvl45 | 07 08 09
lvl60 | 10 11 12
lvl75 | 13 14 15
lvl90 | 16 17 18
]]


-- Nerd's part:

local MainFrame = CreateFrame("Frame", nil, UIParent)
MainFrame:SetFrameStrata("BACKGROUND")
MainFrame:SetPoint("CENTER")
MainFrame:SetSize(1, 1)
MainFrame:Show()

local TextLine = MainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge3")
TextLine:SetTextHeight(24)
TextLine:SetText("RaiderBuildReminder")
TextLine:SetPoint("CENTER", MainFrame, 0, 100)

local InCombat = false

local function GetCurrentTalents()
    local result = {}
    for i = 1,6
    do 
        local a, TalentId = GetTalentRowSelectionInfo(i)
        if TalentId then
            table.insert(result, TalentId)
        end
    end

    return result
end

local function GetBuildMessage()
    if InCombat then return "" end

    local CurrentTalents = GetCurrentTalents()
    local SubZone = GetSubZoneText()
    local WantedTalents = Talents[SubZone]

    if WantedTalents then
        local i
        for i = 1, #WantedTalents
        do
            local TalentId = WantedTalents[i]
            if not tContains(CurrentTalents, TalentId) then 
                return SubZone.."\nMissing talent: "..TalentId
            end
        end
    end

    return ""
end

local function HR_OnEvent(Self, Event, ...)
    if Event == "PLAYER_REGEN_DISABLED" then InCombat = true end
    if Event == "PLAYER_REGEN_ENABLED" then InCombat = false end

    TextLine:SetText(GetBuildMessage())
end
MainFrame:SetScript("OnEvent", HR_OnEvent)
MainFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
MainFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
MainFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
MainFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
