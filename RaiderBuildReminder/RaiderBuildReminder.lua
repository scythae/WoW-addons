-- mop-veins.tk, 2020-12-01
-- Use ingame chat command "/reload" after changing settings 

-- User's part:

local Settings = {    
    ["[HU] Warriors of Darkness"] = { 

        ["Triama"] = {
            ["Trade District"] = {
                ["Talents"] = {"Chi Wave"}
            },
        },

    },  

    ["[EN] Evermoon"] = {

        ["Triama"] = { 
            ["The Summer Terrace"] = {
                ["Talents"] = {"Tiger's Lust"}
            },
            ["Chamber of the Paragons"] = {
                ["Talents"] = {"Ascendance"}
            },             
        },

        ["Deviation"] = {
            ["The Summer Terrace"] = {
                ["Talents"] = {"Psyfiend", "Angelic Feather"}
            },
            ["Menagerie"] = {
                ["Talents"] = {"Power Infusion", "Divine Star"}
            },              
        },

    },  
}

-- Nerd's part:

local BackupTemplate = {    
    ["RealmName"] = {
        ["CharacterName"] = {
            ["SubzoneName"] = {
                ["Talents"] = {"Crushing Blows", "Arcane Currents"},
                ["Glyphs"] = {"Glyph of A", "Glyph of B"}
            },
        },
    }, 
}

local MainFrame = CreateFrame("Frame", nil, UIParent)
MainFrame:SetFrameStrata("BACKGROUND")
MainFrame:SetPoint("CENTER")
MainFrame:SetSize(1, 1)
MainFrame:Show()

local TextLine = MainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge3")
TextLine:SetTextHeight(24)
TextLine:SetPoint("CENTER", MainFrame, 0, 100)

local InCombat = false
local CharacterSettings

local function GetCurrentTalents()
    local result = {}
    for i = 1, 18
    do 
        local TalentName, Texture, row, col, Active = GetTalentInfo(i)
        if Active then
            table.insert(result, TalentName)
        end
    end

    return result
end

local function InitCharacterSettings()
    local r = GetRealmName()
    if Settings[r] then 
        local c = GetUnitName("player")        
        CharacterSettings = Settings[r][c]   
    end 
end

local function GetBuildMessage()
    if InCombat then return end

    local SubZone = GetSubZoneText()  
    local WantedSettings = CharacterSettings[SubZone]
    if WantedSettings == nil then return end

    local WantedTalents = WantedSettings["Talents"]
    if WantedTalents then
        local CurrentTalents = GetCurrentTalents()
        print(unpack(CurrentTalents))
        local i
        for i = 1, #WantedTalents
        do
            local TalentName = WantedTalents[i]
            if not tContains(CurrentTalents, TalentName) then 
                return SubZone.."\nMissing talent: "..TalentName
            end
        end
    end

    local Glyphs = WantedSettings["Glyphs"]

    return
end

local function OnEvent(Self, Event, ...)
    if Event == "PLAYER_ENTERING_WORLD" then 
        InitCharacterSettings() 
        if CharacterSettings == nil then
            print("RaiderBuildReminder - cannot load settings")
            return
        end
        MainFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
        MainFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
        MainFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
        MainFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    end
    if Event == "PLAYER_REGEN_DISABLED" then InCombat = true end
    if Event == "PLAYER_REGEN_ENABLED" then InCombat = false end

    TextLine:SetText(GetBuildMessage() or "")
end
MainFrame:SetScript("OnEvent", OnEvent)
MainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")