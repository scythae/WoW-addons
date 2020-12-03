-- mop-veins.tk, 2020-12-01
local AddonName = "RaiderBuildReminder"
local SlashCommand = "/rbr"

local SiegeOfOrgrimmarSubzones = {
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

local TextLine = MainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge3")
TextLine:SetTextHeight(24)
TextLine:SetPoint("CENTER", MainFrame, 0, 100)

local PlayerEnteredWorld = false
local InCombat = false

local Data
local SettingsGUI = {}

local SessionData = {
    Subzone = "NoData"
}

local function foreach(table, func)
    local i
    for i = 1, #table do
        func(table[i])        
    end      
end

local function GetCurrentGlyphs()
    local result = {}
    for i = 1, 6
    do 
        local GlyphId = ({GetGlyphSocketInfo(i)})[4]
        if GlyphId then
            table.insert(result, GlyphId)
        end
    end

    return result
end

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

local function InitSettings()
    if RaiderBuildReminderSettings == nil then
        RaiderBuildReminderSettings = {}
        RaiderBuildReminderSettings["Counter"] = 0
    end
    Data = RaiderBuildReminderSettings

    foreach(SiegeOfOrgrimmarSubzones, function(subzone)
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
    local SubZone = Data.LastSubzone or GetSubZoneText()
    
    local SubzoneSettings = Data[SubZone]
    if SubzoneSettings == nil then return end
    
    local SpecId = GetActiveSpecGroup()
    
    local Talents = SubzoneSettings[SpecId]["Talents"]
    local i
    for i = 1, #Talents
    do
        if Talents[i] then
            local TalentName, Texture, row, col, Active = GetTalentInfo(i)
            if Active ~= true then
                return SubZone.."\nMissing talent: "..TalentName               
            end
        end
    end
    
    local CurrentGlyphs = GetCurrentGlyphs()
    local Glyphs = SubzoneSettings[SpecId]["Glyphs"]
    for i = 1, #Glyphs
    do 
        local Glyph = Glyphs[i]
        if (Glyph.Id > 0) and not tContains(CurrentGlyphs, Glyph.Id) then 
            return SubZone.."\nMissing glyph: "..Glyph.Name
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
    
    InitSettings() 
    SettingsGUI.Init()

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
        TextLine:SetText(GetBuildMessage() or "")
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

local GlyphMenus = {}
local TalentCheckboxes = {}

local SettingsFrame = CreateFrame("Frame", nil, UIParent)
SettingsFrame.name = AddonName
InterfaceOptions_AddCategory(SettingsFrame)

SettingsGUI.AdjustableSubzone = SiegeOfOrgrimmarSubzones[1][1]

SettingsGUI.Init = function()
    SettingsGUI.InitTalentSettings()
    SettingsGUI.InitGlyphSettings()
    SettingsGUI.InitSubzonesMenu()
    SettingsGUI.InitResetButtons()

    SettingsGUI.LoadSettings()
end

SettingsGUI.InitGlyphSettings = function()
    local Anchor = SettingsGUI.CreateTextLine(" ")
    Anchor:SetPoint("TOPLEFT", 130, -21)

    local Line = SettingsGUI.CreateTextLine("Glyphs")
    Line:SetPoint("TOPLEFT", Anchor, "TOPRIGHT", 30, 6)

    SettingsGUI.CreateGlyphMenus(Anchor)
    SettingsGUI.LoadGlyphMenus()
end

SettingsGUI.CreateTextLine = function(Text)
    local Result = SettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge3")
    Result:SetText(Text)
    Result:SetTextHeight(12)
    return Result
end

SettingsGUI.CreateGlyphMenus = function(Anchor)  
    local GlyphsMajor = { { Name = "-- Major (empty) --", Id = 0 } }
    local GlyphsMinor = { { Name = "-- Minor (empty) --", Id = 0 } }
    local Glyphs 

    local i
    for i = 1, GetNumGlyphs() do
        local GlyphName, GlyphType, IsKnown, Icon, GlyphId = GetGlyphInfo(i)        
        if GlyphType == 1 then Glyphs = GlyphsMajor else Glyphs = GlyphsMinor end

        if GlyphName ~= "header" then            
            table.insert(Glyphs, { Name = GlyphName, Id = GlyphId })
        end
    end   

    local function CreateGlyphMenu(Glyphs, MenuIndex)
        local Menu = CreateFrame("Frame", AddonName.."GlyphMenu"..MenuIndex, SettingsFrame, "UIDropDownMenuTemplate")

        function Menu:SetGlyph(Glyph)
            self.Glyph = Glyph or Glyphs[1]
            UIDropDownMenu_SetText(self, self.Glyph.Name)
        end
        function Menu:GetGlyph()
            return self.Glyph or Glyphs[1]
        end        
        
        UIDropDownMenu_SetWidth(Menu, 200)

        UIDropDownMenu_Initialize(Menu, function(self, level, menuList)
            local info = UIDropDownMenu_CreateInfo()
        
            info.func = function(self, arg1, arg2)
                arg2:SetGlyph(arg1)
                SettingsGUI.SaveGlyphMenus()                
            end
            info.arg2 = self

            foreach(Glyphs, function(glyph)
                info.arg1 = glyph
                info.text = glyph.Name
                info.checked = glyph.Id == Menu:GetGlyph().Id
                UIDropDownMenu_AddButton(info)
            end)
        end) 

        return Menu
    end

    local i
    for i = 1, 6 do
        if i < 4 then Glyphs = GlyphsMajor else Glyphs = GlyphsMinor end

        local GlyphMenu = CreateGlyphMenu(Glyphs, i)
        GlyphMenu:SetPoint("TOPLEFT", Anchor, "BOTTOMLEFT", 0, 0)
        Anchor = GlyphMenu

        GlyphMenus[i] = GlyphMenu
    end    
end

SettingsGUI.InitTalentSettings = function()
    local Anchor = SettingsGUI.CreateTextLine(" ")
    Anchor:SetPoint("TOPLEFT", 20, -20)

    local Line = SettingsGUI.CreateTextLine("Talents")
    Line:SetPoint("TOPLEFT", Anchor, "TOPRIGHT", 30, 5)

    SettingsGUI.CreateTalentCheckboxes(Anchor)
end

SettingsGUI.CreateTalentCheckboxes = function(Anchor)
    local CreateTalentCheckbox = function(TalentId)
        local cb = CreateFrame("CheckButton", nil, SettingsFrame, "OptionsBaseCheckButtonTemplate")
        cb:SetSize(32, 32)
        cb:SetHitRectInsets(0, 0, 0, 0)
        local TalentName = GetTalentInfo(TalentId)
        cb.TalentId = TalentId
        cb.tooltipText = TalentName        
        cb:HookScript("OnClick", function (...)
            SettingsGUI.TalentCheckboxOnClick(...)
        end)

        TalentCheckboxes[TalentId] = cb
        return cb
    end

    local i
    for i = 1, 6 do
        local TalentId = i * 3 - 2
        local cb1 = CreateTalentCheckbox(TalentId)
        local cb2 = CreateTalentCheckbox(TalentId + 1)
        local cb3 = CreateTalentCheckbox(TalentId + 2)
        cb1:SetPoint("TOPLEFT", Anchor, "BOTTOMLEFT")
        cb2:SetPoint("TOPLEFT", cb1, "TOPRIGHT")
        cb3:SetPoint("TOPLEFT", cb2, "TOPRIGHT")
        Anchor = cb1
    end
end

SettingsGUI.TalentCheckboxOnClick = function (self, button, down)
    local row = ceil(self.TalentId / 3)
    local TalentId
    for TalentId = row * 3 - 2, row * 3 do
        local cb = TalentCheckboxes[TalentId]
        if cb and cb ~= self then
            cb:SetChecked(false)
        end
    end

    SettingsGUI.SaveTalentCheckboxes()
end

SettingsGUI.GetMemorySpot = function()
    local SpecId = GetActiveSpecGroup()
    return Data[SettingsGUI.AdjustableSubzone][SpecId]
end

SettingsGUI.SaveTalentCheckboxes = function()
    local Talents = {}

    local i
    for i = 1, #TalentCheckboxes do
        Talents[i] = TalentCheckboxes[i]:GetChecked() == 1
    end  

    SettingsGUI.GetMemorySpot()["Talents"] = Talents
    CheckBuild()
end

SettingsGUI.LoadTalentCheckboxes = function()
    local Talents = SettingsGUI.GetMemorySpot()["Talents"]
    
    local i
    for i = 1, #TalentCheckboxes do
        TalentCheckboxes[i]:SetChecked(Talents[i] or false)
    end
end

SettingsGUI.SaveGlyphMenus = function()
    local Glyphs = {}
    
    local i
    for i = 1, #GlyphMenus do
        Glyphs[i] = GlyphMenus[i]:GetGlyph()
    end
    
    SettingsGUI.GetMemorySpot()["Glyphs"] = Glyphs
    CheckBuild()
end

SettingsGUI.LoadGlyphMenus = function()
    local Glyphs = SettingsGUI.GetMemorySpot()["Glyphs"]

    local i
    for i = 1, #GlyphMenus do
        GlyphMenus[i]:SetGlyph(Glyphs[i])
    end
end

SettingsGUI.LoadSettings = function()
    SettingsGUI.LoadTalentCheckboxes()
    SettingsGUI.LoadGlyphMenus()
end

SettingsGUI.InitSubzonesMenu = function()
    SettingsGUI.SubzonesMenu = CreateFrame("Frame", AddonName.."SubzonesMenu", SettingsFrame, "UIDropDownMenuTemplate")
    local menu = SettingsGUI.SubzonesMenu
    menu:SetPoint("TOPLEFT", TalentCheckboxes[16], "BOTTOMLEFT", 0, -20)
    UIDropDownMenu_SetText(menu, SettingsGUI.AdjustableSubzone)
    UIDropDownMenu_SetWidth(menu, 200)
    
    UIDropDownMenu_Initialize(menu, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
    
        info.func = SettingsGUI.SubzoneMenuOnChange
        info.arg2 = menu

        foreach(SiegeOfOrgrimmarSubzones, function(subzone)
            info.arg1 = subzone[1]
            info.text = subzone[1].." ("..subzone[2]..")"
            info.checked = info.arg1 == SettingsGUI.AdjustableSubzone
            UIDropDownMenu_AddButton(info)
        end)
    end)
end

SettingsGUI.SubzoneMenuOnChange = function(self, arg1, arg2)
    SettingsGUI.AdjustableSubzone = arg1
    UIDropDownMenu_SetText(arg2, SettingsGUI.AdjustableSubzone)
    SettingsGUI.LoadTalentCheckboxes()
    SettingsGUI.LoadGlyphMenus()
end

SettingsGUI.InitResetButtons = function()
    local ResetThis = CreateFrame("Button", nil, SettingsFrame, "UIPanelButtonTemplate ")
    ResetThis:SetText("Reset for this subzone")
    local w, h = ResetThis:GetSize()
    ResetThis:SetSize(150, h)
    ResetThis:SetPoint("TOPRIGHT", SettingsFrame, "TOPRIGHT", -20, -150)

    function Reload()
        InitSettings()
        SettingsGUI.LoadSettings()
        CheckBuild()
    end

    ResetThis:HookScript("OnClick", function (...)
        RaiderBuildReminderSettings[SettingsGUI.AdjustableSubzone] = nil
        Reload()
    end)

    local ResetAll = CreateFrame("Button", nil, SettingsFrame, "UIPanelButtonTemplate ")
    ResetAll:SetText("Reset for ALL subzones")
    ResetAll:SetSize(150, h)
    ResetAll:SetPoint("TOPRIGHT", SettingsFrame, "TOPRIGHT", -20, -35)

    ResetAll:HookScript("OnClick", function (...)
        RaiderBuildReminderSettings = nil
        Reload()
    end)
end    