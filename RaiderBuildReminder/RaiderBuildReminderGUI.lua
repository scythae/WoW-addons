local AddonName, AddonTable = ...
local AT = AddonTable
local GUI = {}

AT.InitGUI = function()
    GUI.Init()
end

AT.SetCallbackOnGUIEvent = function(callback)
    GUI.OnEvent = callback
end

GUI.DoOnEvent = function(Event, ...)
    if type(GUI.OnEvent) == "function" then
        return GUI.OnEvent(Event, ...)
    end
end

local GlyphMenus = {}
local TalentCheckboxes = {}

local SettingsFrame = CreateFrame("Frame", nil, UIParent)
SettingsFrame.name = AddonName
InterfaceOptions_AddCategory(SettingsFrame)

GUI.AdjustableSubzone = AT.SiegeOfOrgrimmarSubzones[1][1]

GUI.Init = function()
    if GUI.Created ~= true then
        GUI.InitTalentSettings()
        GUI.InitGlyphSettings()
        GUI.InitSubzonesMenu()
        GUI.InitResetButtons()

        GUI.Created = true
    end

    GUI.LoadSettings()
end

GUI.InitTalentSettings = function()
    local Anchor = GUI.CreateTextLine(" ")
    Anchor:SetPoint("TOPLEFT", 20, -20)

    local Line = GUI.CreateTextLine("Talents")
    Line:SetPoint("TOPLEFT", Anchor, "TOPRIGHT", 30, 5)

    GUI.CreateTalentCheckboxes(Anchor)
end

GUI.CreateTalentCheckboxes = function(Anchor)
    local i
    for i = 1, 6 do
        local TalentId = i * 3 - 2
        local cb1 = GUI.CreateTalentCheckbox(TalentId)
        local cb2 = GUI.CreateTalentCheckbox(TalentId + 1)
        local cb3 = GUI.CreateTalentCheckbox(TalentId + 2)
        cb1:SetPoint("TOPLEFT", Anchor, "BOTTOMLEFT")
        cb2:SetPoint("TOPLEFT", cb1, "TOPRIGHT")
        cb3:SetPoint("TOPLEFT", cb2, "TOPRIGHT")
        Anchor = cb1
    end
end

GUI.CreateTalentCheckbox = function(TalentId)
    local cb = CreateFrame("CheckButton", nil, SettingsFrame, "OptionsBaseCheckButtonTemplate")
    cb:SetSize(32, 32)
    cb:SetHitRectInsets(0, 0, 0, 0)
    local TalentName = GetTalentInfo(TalentId)
    cb.TalentId = TalentId
    cb.tooltipText = TalentName        
    cb:HookScript("OnClick", function (...)
        GUI.TalentCheckboxOnClick(...)
    end)

    TalentCheckboxes[TalentId] = cb
    return cb
end

GUI.TalentCheckboxOnClick = function (self, button, down)
    local row = ceil(self.TalentId / 3)
    local TalentId
    for TalentId = row * 3 - 2, row * 3 do
        local cb = TalentCheckboxes[TalentId]
        if cb and cb ~= self then
            cb:SetChecked(false)
        end
    end

    GUI.SaveTalentCheckboxes()
end

GUI.InitGlyphSettings = function()
    local Anchor = GUI.CreateTextLine(" ")
    Anchor:SetPoint("TOPLEFT", 130, -21)

    local Line = GUI.CreateTextLine("Glyphs")
    Line:SetPoint("TOPLEFT", Anchor, "TOPRIGHT", 30, 6)

    GUI.CreateGlyphMenus(Anchor)
    GUI.LoadGlyphMenus()
end

GUI.CreateGlyphMenus = function(Anchor)  
    local Glyphs = { 
        { { Name = "-- Major (empty) --", Id = 0 } }, 
        { { Name = "-- Minor (empty) --", Id = 0 } }
    } 

    local i
    for i = 1, GetNumGlyphs() do
        local GlyphName, GlyphType, IsKnown, Icon, GlyphId = GetGlyphInfo(i)
        if GlyphId then            
            table.insert(Glyphs[GlyphType], { Name = GlyphName, Id = GlyphId })
        end
    end   

    for i = 1, 6 do
        local GlyphMenu = GUI.CreateGlyphMenu(Glyphs[ceil(i / 3)], i)
        GlyphMenu:SetPoint("TOPLEFT", Anchor, "BOTTOMLEFT", 0, 0)
        Anchor = GlyphMenu

        GlyphMenus[i] = GlyphMenu
    end    
end

GUI.CreateGlyphMenu = function (Glyphs, MenuIndex)
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
        info.arg1 = self
        info.func = function(self, arg1, arg2)
            arg1:SetGlyph(arg2)
            GUI.SaveGlyphMenus()                
        end

        AT.utils.foreach_(Glyphs, function(glyph)
            info.arg2 = glyph
            info.text = glyph.Name
            info.checked = glyph.Id == Menu:GetGlyph().Id
            UIDropDownMenu_AddButton(info)
        end)
    end) 

    return Menu
end

GUI.GetData = function(DataType)
    return GUI.DoOnEvent("GET_DATA", GUI.AdjustableSubzone, DataType)
end

GUI.SetData = function(DataType, Content)    
    GUI.DoOnEvent("SET_DATA", GUI.AdjustableSubzone, DataType, Content)
end

GUI.SaveTalentCheckboxes = function()
    local Talents = {}

    local i
    for i = 1, #TalentCheckboxes do
        Talents[i] = TalentCheckboxes[i]:GetChecked() == 1
    end  

    GUI.SetData("Talents", Talents)
end

GUI.LoadTalentCheckboxes = function()
    local Talents = GUI.GetData("Talents")
    
    local i
    for i = 1, #TalentCheckboxes do
        TalentCheckboxes[i]:SetChecked(Talents[i] or false)
    end
end

GUI.SaveGlyphMenus = function()
    local Glyphs = {}
    
    local i
    for i = 1, #GlyphMenus do
        Glyphs[i] = GlyphMenus[i]:GetGlyph()
    end
    
    GUI.SetData("Glyphs", Glyphs)
end

GUI.LoadGlyphMenus = function()
    local Glyphs = GUI.GetData("Glyphs")

    local i
    for i = 1, #GlyphMenus do
        GlyphMenus[i]:SetGlyph(Glyphs[i])
    end
end

GUI.LoadSettings = function()
    GUI.LoadTalentCheckboxes()
    GUI.LoadGlyphMenus()
end

GUI.InitSubzonesMenu = function()
    local Menu = CreateFrame("Frame", AddonName.."SubzonesMenu", SettingsFrame, "UIDropDownMenuTemplate")
    
    Menu:SetPoint("TOPLEFT", TalentCheckboxes[16], "BOTTOMLEFT", 0, -20)
    UIDropDownMenu_SetText(Menu, GUI.AdjustableSubzone)
    UIDropDownMenu_SetWidth(Menu, 200)
    
    UIDropDownMenu_Initialize(Menu, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()    
        info.arg1 = self
        info.func = GUI.SubzoneMenuOnChange

        AT.utils.foreach_(AT.SiegeOfOrgrimmarSubzones, function(subzone)
            info.arg2 = subzone[1]
            info.text = subzone[1].." ("..subzone[2]..")"
            info.checked = info.arg1 == GUI.AdjustableSubzone
            UIDropDownMenu_AddButton(info)
        end)
    end)

    GUI.SubzonesMenu = Menu
end

GUI.SubzoneMenuOnChange = function(self, arg1, arg2)
    GUI.AdjustableSubzone = arg2
    UIDropDownMenu_SetText(arg1, arg2)
    GUI.LoadSettings()
end

GUI.InitResetButtons = function()
    local ResetThisSubzone = CreateFrame("Button", nil, SettingsFrame, "UIPanelButtonTemplate ")
    ResetThisSubzone:SetText("Reset for this subzone")
    local w, h = ResetThisSubzone:GetSize()
    ResetThisSubzone:SetSize(150, h)
    ResetThisSubzone:SetPoint("TOPRIGHT", SettingsFrame, "TOPRIGHT", -20, -150)
    ResetThisSubzone:HookScript("OnClick", function(...)
        GUI.DoOnEvent("RESET_ZONE", GUI.AdjustableSubzone)
    end)
    
    local ResetAllSubzones = CreateFrame("Button", nil, SettingsFrame, "UIPanelButtonTemplate ")
    ResetAllSubzones:SetText("Reset for ALL subzones")
    ResetAllSubzones:SetSize(150, h)
    ResetAllSubzones:SetPoint("TOPRIGHT", SettingsFrame, "TOPRIGHT", -20, -35)    
    ResetAllSubzones:HookScript("OnClick", function(...)
        GUI.DoOnEvent("RESET_ALL_ZONES")
    end)
end    

GUI.CreateTextLine = function(Text)
    local Result = SettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge3")
    Result:SetText(Text)
    Result:SetTextHeight(12)
    return Result
end