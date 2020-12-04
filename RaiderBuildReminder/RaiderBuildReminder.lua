-- tauriwow.com, 2020-12-01
local AddonName, AddonTable = ...
local AT = AddonTable
local SlashCommand = "/rbr" 

AT.HelpText = AddonName.."\n"..
SlashCommand.." - show settings UI\n"..
SlashCommand.." help - show this message\n"..
SlashCommand.." reset - reset settings for insettings-selected zone\n"..
SlashCommand.." resetspec - reset settings for all zones for current specialization\n"..
SlashCommand.." resetchar - reset settings for all zones for both specializations"

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

local Core = {}
local InCombat = false
local Data

Core.Run = function()
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetFrameStrata("BACKGROUND")
    f:SetPoint("CENTER")
    f:SetSize(1, 1)
    f:SetScript("OnEvent", Core.OnEvent)
    f:RegisterEvent("PLAYER_LOGIN")
    
    local w = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge3")
    w:SetTextHeight(24)
    w:SetPoint("CENTER", f, 0, 100)
    Core.BuildWarning = w
end

Core.OnEvent = function(Self, Event, ...)
    if Event == "PLAYER_LOGIN" then 
        Core.StartLoadingTimer(Self)
    end

    if Event == "PLAYER_REGEN_DISABLED" then InCombat = true end
    if Event == "PLAYER_REGEN_ENABLED" then InCombat = false end
    if Event == "PLAYER_SPECIALIZATION_CHANGED" then 
        AT.InitGUI()
    end

    Core.CheckBuild()
end

Core.StartLoadingTimer = function(Frame)
    local TimeElapsed = 0

    function OnUpdate(Self, Elapsed)
        if TimeElapsed < 5 then
            TimeElapsed = TimeElapsed + Elapsed;
            return;
        end;
        Self:SetScript("OnUpdate", nil)
        
        Core.OnLoad(Self)
        Core.CheckBuild()
    end

    Frame:SetScript("OnUpdate", OnUpdate)
end

Core.OnLoad = function(Frame)    
    _G["SLASH_"..AddonName.."1"] = SlashCommand
    SlashCmdList[AddonName] = Core.OnSlashCommand
    Core.Report(AddonName.." - "..SlashCommand)

    Frame:RegisterEvent("ZONE_CHANGED")
    Frame:RegisterEvent("ZONE_CHANGED_INDOORS")
    Frame:RegisterEvent("PLAYER_TALENT_UPDATE")
    Frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    Frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    Frame:RegisterEvent("GLYPH_ADDED")
    Frame:RegisterEvent("GLYPH_REMOVED")
    Frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

    Core.AfterLoad()
end

Core.Report = print

Core.AfterLoad = function()    
    Core.InitData() 
    AT.SetCallbackOnGUIEvent(Core.OnGUIEvent)
    AT.InitGUI()   
end

Core.InitData = function()
    if RaiderBuildReminderSettings == nil then
        RaiderBuildReminderSettings = {}
    end
    Data = RaiderBuildReminderSettings

    AT.utils.foreach_(AT.SiegeOfOrgrimmarSubzones, function(subzone)
        local SubzoneName = subzone[1]

        if Data[SubzoneName] == nil then
            Data[SubzoneName] = { Core.GetEmptyDataChunk(), Core.GetEmptyDataChunk() }
        end 
    end)
end

Core.CheckBuild = function()
    Core.BuildWarning:SetText(Core.GetBuildMessage() or "")
end

Core.GetBuildMessage = function()
    if InCombat then return end
    if Data == nil then return end
    local Subzone = GetSubZoneText()
    
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
    
    local CurrentGlyphs = Core.GetCurrentGlyphs()
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

Core.GetCurrentGlyphs = function()
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

-- GUIEvent handlers --

Core.OnGUIEvent = function(Event, ...)
    local Handler = Core.GUIEventHandlers[Event]
    if Handler then
        return Handler(...)
    end
end

Core.GUIEventHandlers = {}
Core.GUIEventHandlers["GET_DATA"] = function(ZoneName, DataType)
    if DataType ~= "Talents" and DataType ~= "Glyphs" then return end

    local SpecId = GetActiveSpecGroup()
    
    return Core.GetZoneDataChunk(ZoneName)[SpecId][DataType]
end

Core.GUIEventHandlers["SET_DATA"] = function(ZoneName, DataType, Content)
    if DataType ~= "Talents" and DataType ~= "Glyphs" then return end

    local SpecId = GetActiveSpecGroup()
    Core.GetZoneDataChunk(ZoneName)[SpecId][DataType] = Content

    Core.CheckBuild()
end

Core.GUIEventHandlers["SHOW_INFO"] = function(ZoneName, DataType, Content)
    Core.ShowInfo()
end

Core.GetZoneDataChunk = function(ZoneName)
    if Data[ZoneName] == nil then
        Data[ZoneName] = { Core.GetEmptyDataChunk(), Core.GetEmptyDataChunk() }
    end

    return Data[ZoneName]
end

Core.GetEmptyDataChunk = function()
    return {
        ["Talents"] = {},
        ["Glyphs"] = {}
    }
end

Core.ShowInfo = function()
    Core.Report(AT.HelpText)
end

-- SlashCommand handlers --

Core.OnSlashCommand = function(Msg)
    local Handler = Core.SlashCommands[strlower(Msg)]
    if Handler then 
        Core.Report(SlashCommand.." "..Msg.." command has been executed")
        Handler()
    else
        AT.ShowGUI()
    end
end

Core.SlashCommands = {}
Core.SlashCommands["help"] = function()
    Core.ShowInfo()
end

local function AfterReset()    
    Core.InitData()
    Core.CheckBuild()
    AT.InitGUI()
end

Core.SlashCommands["reset"] = function()
    local ZoneName = AT.GetSelectedZone()
    local SpecId = GetActiveSpecGroup()    
    Data[ZoneName][SpecId] = Core.GetEmptyDataChunk()
    AfterReset()  
end

Core.SlashCommands["resetspec"] = function()
    local SpecId = GetActiveSpecGroup()
    local key, val
    for key, val in pairs(Data) do
        val[SpecId] = Core.GetEmptyDataChunk()
    end   
    AfterReset()  
end

Core.SlashCommands["resetchar"] = function()
    RaiderBuildReminderSettings = nil
    AfterReset()
end





Core.Run()