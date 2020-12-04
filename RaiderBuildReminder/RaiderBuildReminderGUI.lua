local AddonName, AddonTable = ...
local AT = AddonTable
local GUI = {}

AT.InitGUI = function()
    GUI.Init()
end

AT.ShowGUI = function()
    GUI.Show()
end

AT.GetSelectedZone = function()
    return GUI.SelectedSubzone
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
local SettingsFrame

GUI.SelectedSubzone = AT.SiegeOfOrgrimmarSubzones[1][1]

GUI.Init = function()
    if GUI.Created ~= true then
        GUI.CreateSettingsFrame()
        GUI.InitTalentSettings()
        GUI.InitGlyphSettings()
        GUI.InitSubzonesMenu()

        GUI.Created = true
    end

    GUI.LoadSettings()
end

GUI.CreateSettingsFrame = function()
    local f = CreateFrame("Frame", AddonName.."SettingsFrame2", UIParent)
    SettingsFrame = f    

    f:SetFrameStrata("DIALOG")
    f:SetPoint("TOPRIGHT", -150, -150)
    f:SetSize(400, 300)
    f:Hide()

    tinsert(UISpecialFrames, f:GetName()) -- makes it to close when Esc is hit

    f:SetClampedToScreen()
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    
    f:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f:SetBackdropColor(0.5, 0.5, 0, 0.5)

    local function CreateButton(text)
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate");
        b:SetSize(20, 20)
        b:SetText(text)
        return b
    end

    local CloseButton = CreateButton("X")
    CloseButton:SetPoint("TOPRIGHT", -5, -5)
    CloseButton:HookScript("OnClick", function(self, ...)
        HideUIPanel(self:GetParent())
    end)   

    local InfoButton = CreateButton("?")
    InfoButton:SetPoint("RIGHT", CloseButton, "LEFT" , -5, 0)
    InfoButton:HookScript("OnClick", function(self, ...)
        GUI.DoOnEvent("SHOW_INFO")
    end)    
end

GUI.Show = function()
    ShowUIPanel(SettingsFrame)
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
    Anchor:SetPoint("TOPRIGHT", -250, -21)

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

    local GlyphTypes = {1, 1, 1, 2, 2, 2}
    for i = 1, 6 do
        local GlyphType = GlyphTypes[i]
        local GlyphMenu = GUI.CreateGlyphMenu(Glyphs[GlyphType], i)
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
        info.func = GUI.ClyphMenuOnChange

        AT.utils.foreach_(Glyphs, function(glyph)
            info.arg2 = glyph
            info.text = glyph.Name
            info.checked = glyph.Id == self:GetGlyph().Id
            UIDropDownMenu_AddButton(info)
        end)
    end) 

    return Menu
end

GUI.ClyphMenuOnChange = function(self, arg1, arg2)
    local Menu, Subzone = arg1, arg2
    Menu:SetGlyph(Subzone)
    GUI.SaveGlyphMenus()                
end

GUI.GetData = function(DataType)
    return GUI.DoOnEvent("GET_DATA", GUI.SelectedSubzone, DataType)
end

GUI.SetData = function(DataType, Content)    
    GUI.DoOnEvent("SET_DATA", GUI.SelectedSubzone, DataType, Content)
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
    UIDropDownMenu_SetText(Menu, GUI.SelectedSubzone)
    UIDropDownMenu_SetWidth(Menu, 200)
    
    UIDropDownMenu_Initialize(Menu, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()    
        info.arg1 = self
        info.func = GUI.SubzoneMenuOnChange

        AT.utils.foreach_(AT.SiegeOfOrgrimmarSubzones, function(subzone)
            info.arg2 = subzone[1]
            info.text = subzone[1].." ("..subzone[2]..")"
            info.checked = info.arg2 == GUI.SelectedSubzone
            UIDropDownMenu_AddButton(info)
        end)
    end)

    GUI.SubzonesMenu = Menu
end

GUI.SubzoneMenuOnChange = function(self, arg1, arg2)
    local Menu, Subzone = arg1, arg2
    GUI.SelectedSubzone = Subzone
    UIDropDownMenu_SetText(Menu, Subzone)
    GUI.LoadSettings()
end

GUI.CreateTextLine = function(Text)
    local Result = SettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalMed3")
    Result:SetText(Text)
    Result:SetTextHeight(14)
    return Result
end