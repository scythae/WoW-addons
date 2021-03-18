local AddonName, AddonTable = ...
local AT = AddonTable
local SlashCommand = "/enmi"

AT.Localization = {}

local Core = {}
local Encounter

Core.Run = function()
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetFrameStrata("BACKGROUND")
    f:SetPoint("CENTER")
    f:SetSize(1, 1)
    f:SetScript("OnEvent", Core.OnAddonLoaded)
    f:RegisterEvent("ADDON_LOADED")
end

Core.OnAddonLoaded = function(Frame, Event, Name)
    if Name ~= AddonName then return end

    _G["SLASH_"..AddonName.."1"] = SlashCommand
    SlashCmdList[AddonName] = Core.OnSlashCommand
    Core.Report(AddonName.." - "..SlashCommand)

    local s = AddonName.."Settings"
    if not _G[s] then _G[s] = {} end
    Core.Settings = _G[s]

    AT.Encounters.Init()

    Frame:UnregisterEvent("ADDON_LOADED")

    Frame:SetScript("OnEvent", Core.OnEvent)
    Frame:RegisterEvent("ENCOUNTER_START")
    Frame:RegisterEvent("ENCOUNTER_END")
end

Core.OnEvent = function(Frame, Event, ...)
    if Event == "ENCOUNTER_START" then
        Core.OnEncounterStart(Frame, ...)
    elseif Event == "ENCOUNTER_END" then
        Core.OnEncounterEnd(Frame, ...)
    else
        Core.OnEncounterCustomEvent(Event, ...)
    end
end

Core.OnEncounterStart = function(Frame, ...)
    local EncounterId = ({...})[1]

    Encounter = AT.Encounters.EncounterIdList[EncounterId]
    if not Encounter then return end

    Encounter.Title = ({...})[2]

    local EncounterEvent, Handler
    for EncounterEvent, Handler in pairs(Encounter.Handlers) do
        Frame:RegisterEvent(EncounterEvent)
    end

    Core.Report("Encounter started: "..Encounter.Title)
end

Core.OnEncounterEnd = function(Frame, ...)
    if not Encounter then return end
        
    for EncounterEvent, Handler in pairs(Encounter.Handlers) do
        Frame:UnregisterEvent(EncounterEvent)
    end
    
    local Success = ({...})[5] == 1    
    Core.Report((Success and "Victory" or "Wipe")..": "..Encounter.Title)
    
    local Mistakes = Encounter.GetMistakes(Encounter)
    if Mistakes then Core.Report("Mistakes: "..Mistakes) end
    
    Encounter = nil
end

Core.OnEncounterCustomEvent = function(Event, ...)
    if not Encounter then return end

    local Handler = Encounter.Handlers[Event]
    if Handler then
        if Event == "COMBAT_LOG_EVENT_UNFILTERED" then
            Handler(Encounter, CombatLogGetCurrentEventInfo())
        else
            Handler(Encounter, ...)
        end
    end
end


Core.Report = print

-- SlashCommand handlers --

Core.OnSlashCommand = function(Msg)
    local Handler = Core.SlashCommands[strlower(Msg)]
    if Handler then 
        Core.Report(SlashCommand.." "..Msg.." command has been executed")
        Handler()
    else
        Core.Report(AddonName)
    end
end

Core.SlashCommands = {}
Core.SlashCommands["help"] = function()
    Core.Report("No help yet")
end


Core.Run()