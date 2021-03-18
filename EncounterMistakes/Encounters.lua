local AddonName, AddonTable = ...
local AT = AddonTable

local E = {}
AT.Encounters = E

local L
E.Init = function()
    L = AT.Localization[GetLocale()]
end

local CLEU = "COMBAT_LOG_EVENT_UNFILTERED"

local Id = {}
E.EncounterIdList = Id

--** Tirna Scithe **--
--** Ingra Maloch
Id[2397] = {
    Handlers = {
        [CLEU] = function(Self, ...)
            args = {...}
            if args[2] == "SPELL_AURA_APPLIED" then
                
                local Target = args[9]
                local SpellId = args[12]
                
                -- Bewildering Pollen
                if (SpellId == 323137) and (UnitIsPlayer(Target) or UnitInParty(Target)) then
                    Self.HitByPollen = true
                end
            end
        end,        
    },
    GetMistakes = function(Self)
        if Self.HitByPollen then
            return L.IngraMaloch.HitByPollen
        end
    end    
}

--** Mistcaller
Id[2392] = {
 
}

--** Tred'ova
Id[2393] = {
 
}


function RefineEncounterIdList()
    local id, encounter
    for id, encounter in pairs(E.EncounterIdList) do
        encounter.Handlers = encounter.Handlers or {}
        encounter.GetMistakes = encounter.GetMistakes or (function(Self) end)
    end
end
RefineEncounterIdList()