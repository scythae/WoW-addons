-- mop-veins.tk, 2020-12-01
local AddonName, AddonTable = ...
local AT = AddonTable
local SlashCommand = "/rbr"
-- local Core = {}
-- AT.Core = Core


AT.SiegeOfOrgrimmarSubzones = {
    {"The Summer Terrace", "Test"},
    {"Pools of Power", "Immerseus"},
    {"Scarred Vale", "The Fallen Protectors"},
    {"Chamber of Purification", "Norushen"},
    {"Vault of Y'Shaarj", "Sha of Pride"},
    {"Dranosh'ar Landing", "Galakras"},
    {"Before the Gates", "Iron Juggernaut"},
    {"Valley of Strength", "Kor'kron Dark Shamans"},
    {"Ragefire Chasm", "General Nazgrim"},
    {"Kor'kron Barracks", "Malkorok"},
    {"Artifact Storage", "Spoils of Pandaria"},
    {"The Menagerie", "Thok the Bloodthirsty"},
    {"The Siegeworks", "Siegecrafter Blackfuse"},
    {"Chamber of the Paragons", "Paragons of the Klaxxi"},
    {"The Inner Sanctum", "Garrosh Hellscream"},
}

local MainFrame = CreateFrame("Frame", nil, UIParent)
MainFrame:SetFrameStrata("BACKGROUND")
MainFrame:SetPoint("CENTER")
MainFrame:SetSize(1, 1)
MainFrame:Show()

local BuildWarning = MainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge3")
BuildWarning:SetTextHeight(24)
BuildWarning:SetPoint("CENTER", MainFrame, 0, 100)

local PlayerEnteredWorld = false
local InCombat = false

local Data
local SessionData = {
    Subzone = "NoData"
}

local function GetCurrentGlyphs()
    local result = {}
    for i = 1, 6
    do 
        local GlyphId = ({GetGlyphSocketInfo(i)})[6]
        if GlyphId then
            table.insert(result, GlyphId)
        end
    end

    return result
end

local function InitData()
    if RaiderBuildReminderSettings == nil then
        RaiderBuildReminderSettings = {}
    end
    Data = RaiderBuildReminderSettings
    AT.Data = Data

    AT.utils.foreach_(AT.SiegeOfOrgrimmarSubzones, function(subzone)
        local SubzoneName = subzone[1]

        if Data[SubzoneName] == nil then
            Data[SubzoneName] = {
                {
                    ["Talents"] = {},
                    ["Glyphs"] = {}
                },
                {
                    ["Talents"] = {},
                    ["Glyphs"] = {}
                }
            }
        end 
    end)
end

local function GetBuildMessage()
    if InCombat then return end
    
    if Data == nil then return end
    local Subzone = Data.LastSubzone or GetSubZoneText()
    
    local SubzoneSettings = Data[Subzone]
    if SubzoneSettings == nil then return end
    
    local SpecId = GetActiveSpecGroup()
    
    local Talents = SubzoneSettings[SpecId]["Talents"]
    local i
    for i = 1, #Talents do
        if Talents[i] then
            local TalentName, Texture, row, col, Active = GetTalentInfo(i)
            if Active ~= true then
                return Subzone.."\nMissing talent: "..TalentName               
            end
        end
    end
    
    local CurrentGlyphs = GetCurrentGlyphs()
    local Glyphs = SubzoneSettings[SpecId]["Glyphs"]
    for i = 1, #Glyphs
    do 
        local Glyph = Glyphs[i]
        if (Glyph.Id > 0) and not tContains(CurrentGlyphs, Glyph.Id) then 
            return Subzone.."\nMissing glyph: "..Glyph.Name
        end
    end
    
    return
end

local function OnLoad()    
    _G["SLASH_"..AddonName.."1"] = SlashCommand
    SlashCmdList[AddonName] = function(msg)
        InterfaceOptionsFrame_Show()
        InterfaceOptionsFrame_OpenToCategory(AddonName)
    end
    print(AddonName.." - "..SlashCommand)    
    
    InitData() 
    AT.GUI.Init()

    MainFrame:RegisterEvent("ZONE_CHANGED")
    MainFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
    MainFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
    MainFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    MainFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    MainFrame:RegisterEvent("GLYPH_ADDED")
    MainFrame:RegisterEvent("GLYPH_REMOVED")
    MainFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
end

local function CheckBuild()
    if PlayerEnteredWorld then
        BuildWarning:SetText(GetBuildMessage() or "")
    end
end

local function OnEvent(Self, Event, ...)
    if Event == "PLAYER_ENTERING_WORLD" then
        OnLoad()
        PlayerEnteredWorld = true
    end

    if Event == "PLAYER_REGEN_DISABLED" then InCombat = true end
    if Event == "PLAYER_REGEN_ENABLED" then InCombat = false end
    if Event == "ZONE_CHANGED" or Event == "ZONE_CHANGED_INDOORS" then 
        Data.LastSubzone = GetSubZoneText()
    end

    CheckBuild()
end
MainFrame:SetScript("OnEvent", OnEvent)
MainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

AT.Core = {}
AT.Core.InitData = function()
    InitData() 
end

AT.Core.CheckBuild = function()    
    CheckBuild()    
end