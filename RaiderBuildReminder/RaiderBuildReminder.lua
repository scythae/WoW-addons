-- mop-veins.tk, 2020-12-01
local AddonName, AddonTable = ...
local AT = AddonTable
local SlashCommand = "/rbr" 
-- for opening settings use "/rbr" command
-- for hard reset use "/rbr reset" with subsequent "/reload"

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

local GUIEventHandlers = {}

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

local function GetEmptyDataChunk()
    return {
        ["Talents"] = {},
        ["Glyphs"] = {}
    }
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
            Data[SubzoneName] = { GetEmptyDataChunk(), GetEmptyDataChunk() }
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

local function CheckBuild()
    if PlayerEnteredWorld then
        BuildWarning:SetText(GetBuildMessage() or "")
    end
end

local function AfterLoad()
    InitData() 

    AT.SetCallbackOnGUIEvent(function(Event, ...)
        if GUIEventHandlers[Event] then
            return GUIEventHandlers[Event](...)
        end
    end)
    AT.InitGUI()   
end

local function OnLoad()    
    _G["SLASH_"..AddonName.."1"] = SlashCommand
    SlashCmdList[AddonName] = function(msg)
        if strlower(msg) == "reset" then
            RaiderBuildReminderSettings = nil
            AfterLoad()
            return    
        end

        InterfaceOptionsFrame_Show()
        InterfaceOptionsFrame_OpenToCategory(AddonName)
    end
    print(AddonName.." - "..SlashCommand)

    MainFrame:RegisterEvent("ZONE_CHANGED")
    MainFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
    MainFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
    MainFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    MainFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    MainFrame:RegisterEvent("GLYPH_ADDED")
    MainFrame:RegisterEvent("GLYPH_REMOVED")
    MainFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

    AfterLoad()
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
    if Event == "PLAYER_SPECIALIZATION_CHANGED" then 
        AT.InitGUI()
    end

    CheckBuild()
end
MainFrame:SetScript("OnEvent", OnEvent)
MainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")


local function AfterReset()    
    InitData()
    CheckBuild()
    AT.InitGUI()
end

GUIEventHandlers["RESET_ZONE"] = function(ZoneName)
    local SpecId = GetActiveSpecGroup()    
    Data[ZoneName][SpecId] = GetEmptyDataChunk()
    AfterReset()  
end

GUIEventHandlers["RESET_ALL_ZONES"] = function()
    local SpecId = GetActiveSpecGroup()
    local key, val
    for key, val in pairs(Data) do
        val[SpecId] = GetEmptyDataChunk()
    end   
    AfterReset()  
end

local function GetZoneDataChunk(ZoneName)
    if Data[ZoneName] == nil then
        Data[ZoneName] = { GetEmptyDataChunk(), GetEmptyDataChunk() }
    end

    return Data[ZoneName]
end

GUIEventHandlers["GET_DATA"] = function(ZoneName, DataType)
    if DataType ~= "Talents" and DataType ~= "Glyphs" then return end

    local SpecId = GetActiveSpecGroup()
    
    return GetZoneDataChunk(ZoneName)[SpecId][DataType]
end

GUIEventHandlers["SET_DATA"] = function(ZoneName, DataType, Content)
    if DataType ~= "Talents" and DataType ~= "Glyphs" then return end

    local SpecId = GetActiveSpecGroup()
    GetZoneDataChunk(ZoneName)[SpecId][DataType] = Content

    CheckBuild()
end