-- mop-veins.tk, 2020-12-01
-- Use ingame chat command "/reload" after changing settings 

-- User's part:

local Settings = {
    ["RealmName"] = {
        ["CharacterName"] = {
            ["SubzoneName"] = {
                ["Talents 1"] = {"TalentName1", "TalentName2"}, -- for spec 1
                ["Glyphs 1"] = {"Glyph of A"}, -- for spec 1
                ["Talents 2"] = {"TalentName3"}, -- for spec 2
                ["Glyphs 2"] = {"Glyph of B", "Glyph of C"}, -- for spec 2
            },
        },
    }, 

    ["[HU] Warriors of Darkness"] = { 

        ["Triama"] = {
            ["Trade District"] = {
                ["Talents 1"] = {"Chi Wave"}, 
            },
        },

    },  

    ["[EN] Evermoon"] = {

        ["Triama"] = { 
            ["The Summer Terrace"] = {
                ["Talents 1"] = {"Tiger's Lust"},
                ["Glyphs 1"] = {"Glyph of Detox", "Glyph of Mana Tea"},
                ["Talents 2"] = {"Chi Wave"},
                ["Glyphs 2"] = {"Glyph of Breath of Fire"},
            },
            ["Pools of Power"] = { -- for Immerseus
            },
            ["Scarred Vale"] = { -- for The Fallen Protectors
            },
            ["Chamber of Purification"] = { -- for Norushen
            },
            ["Vault of Y'Shaarj"] = { -- for Sha of Pride
            },
            ["Dranosh'ar Landing"] = { -- for Galakras
            },
            ["Before the Gates"] = { -- for Iron Juggernaut
            },
            ["Valley of Strength"] = { -- for Kor'kron Dark Shamans
            },
            ["Ragefire Chasm"] = { -- for General Nazgrim
            },
            ["Kor'kron Barracks"] = { -- for Malkorok
            },            
            ["Artifact Storage"] = { -- for Spoils of Pandaria
            },       
            ["The Menagerie"] = { -- for Thok the Bloodthirsty
                ["Talents 1"] = {"Chi Burst"}
            },
            ["The Siegeworks"] = { -- for Siegecrafter Blackfuse
            },
            ["Chamber of the Paragons"] = { -- for Paragons of the Klaxxi
                ["Talents 1"] = {"Ascendance"}
            },
            ["The Inner Sanctum"] = { -- for Garrosh Hellscream
            },
        },

        ["Deviation"] = {
            ["The Summer Terrace"] = {
                ["Talents 1"] = {"Psyfiend", "Angelic Feather"},
                ["Glyphs 1"] = {"Glyph of Binding Heal", "Glyph of Deep Wells"}
            },
            ["Menagerie"] = {
                ["Talents 1"] = {"Power Infusion", "Divine Star"}
            },
        },

    },
}

-- Nerd's part:

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

local function GetCurrentGlyphs()
    local result = {}
    for i = 1, 6
    do 
        local GlyphId = ({GetGlyphSocketInfo(i)})[4]
        if GlyphId then
            local GlyphName = GetSpellInfo(GlyphId)
            table.insert(result, GlyphName)
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

    local SpecId = GetActiveSpecGroup();

    local WantedTalents = WantedSettings["Talents "..SpecId]
    if WantedTalents then
        local CurrentTalents = GetCurrentTalents()
        local i
        for i = 1, #WantedTalents
        do
            local TalentName = WantedTalents[i]
            if not tContains(CurrentTalents, TalentName) then 
                return SubZone.."\nMissing talent: "..TalentName
            end
        end
    end

    local WantedGlyphs = WantedSettings["Glyphs "..SpecId]
    if WantedGlyphs then
        local CurrentGlyphs = GetCurrentGlyphs()
        local i
        for i = 1, #WantedGlyphs
        do
            local GlyphName = WantedGlyphs[i]
            if not tContains(CurrentGlyphs, GlyphName) then 
                return SubZone.."\nMissing glyph: "..GlyphName
            end
        end
    end

    return
end

local function OnEvent(Self, Event, ...)
    if Event == "PLAYER_ENTERING_WORLD" then 
        InitCharacterSettings() 
        if CharacterSettings == nil then
            print("RaiderBuildReminder - cannot load settings")
            return
        end
        MainFrame:RegisterEvent("ZONE_CHANGED")
        MainFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
        MainFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
        MainFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
        MainFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        MainFrame:RegisterEvent("GLYPH_ADDED")
        MainFrame:RegisterEvent("GLYPH_REMOVED")
        MainFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    end
    if Event == "PLAYER_REGEN_DISABLED" then InCombat = true end
    if Event == "PLAYER_REGEN_ENABLED" then InCombat = false end

    TextLine:SetText(GetBuildMessage() or "")
end
MainFrame:SetScript("OnEvent", OnEvent)
MainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")