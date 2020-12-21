local DebugMode = true


local DBM = {}
local PlayerName = UnitName("player")
local CountdownInProgress = false

DBM.Run = function()
	local f = CreateFrame("Frame")
	f:SetScript("OnEvent", DBM.OnEvent)
	f:RegisterEvent("CHAT_MSG_ADDON")
	f:RegisterEvent("PLAYER_ENTERING_WORLD")

	if DebugMode then
		SLASH_DBMPULLTIMER1 = "/dbm"
		SlashCmdList["DBMPULLTIMER"] = DBM.OnSlashDBM
	end
end

DBM.OnEvent = function (self, event, ...)
	local Handler = DBM[event]
	if Handler and not IsEncounterInProgress() then
		Handler(DBM, ...)
	end
end

function DBM:PLAYER_ENTERING_WORLD()
	if type(RegisterAddonMessagePrefix) == "function" then
		RegisterAddonMessagePrefix("D4")
	end
end

function DBM:CHAT_MSG_ADDON(Prefix, Msg, Channel, Sender)
	Sender = Ambiguate(Sender, "none")

	local ChannelIsFine = Channel == "PARTY" or Channel == "RAID" 
		or Channel == "INSTANCE_CHAT" 
		or Channel == "WHISPER" and Sender == PlayerName
	
	local Command, Timer

	if Prefix == "D4" and Msg and (ChannelIsFine or Channel == "GUILD") then
		Command, Timer = strsplit("\t", Msg)
	elseif Prefix == "BigWigs" and Msg and ChannelIsFine then
		Command, Timer = Msg:match("^(%u-):(.+)")
		if not (Command == "VR" or Command == "VRA") then return end
	else
		return
	end
		
	if Command == "PT" and not DBM.IgnorePull(Sender) then 
		DBM.ShowPullTimer(Timer)
	end
end

DBM.IgnorePull = function(Sender)
	local SenderIsBad = not UnitIsGroupLeader(Sender) and not UnitIsGroupAssistant(Sender)
	
	return (SenderIsBad and IsInGroup()) or select(2, IsInInstance()) == "pvp" or IsEncounterInProgress()
end

DBM.ShowPullTimer = function(Timer)
	Timer = tonumber(Timer or 0)

	if Timer == 0 then
		CountdownInProgress = false 
		RaidWarningFrame_OnEvent(RaidWarningFrame, "CHAT_MSG_RAID_WARNING", "DBM: Cancelled!")
		return
	end	

	if CountdownInProgress then return end

	CountdownInProgress = true
	DBM.CountdownFunc(Timer)
end

DBM.CountdownFunc = function(Timer)		
	if not CountdownInProgress then return end
	
	if (Timer < 5) or (Timer % 5 == 0) then		
		local TimerText
		if Timer == 0 then 
			TimerText = "DBM: Pull now!"
		else
			TimerText = "DBM: Pull in "..Timer.." sec"
		end
			
		RaidWarningFrame_OnEvent(RaidWarningFrame, "CHAT_MSG_RAID_WARNING", TimerText)				
	end
	
	if Timer <= 0 then 
		CountdownInProgress = false
		return
	end	

	Delay(1, DBM.CountdownFunc, {Timer - 1})
end

DBM.OnSlashDBM = function(Msg)
	local Msg = Msg:lower()
	if Msg:sub(1, 4) == "pull" then
		if DBM.IgnorePull(PlayerName) then return end
		
		local Timer = tonumber(Msg:sub(5)) or 10

		local ChannelName, TargetPlayerName
		if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and IsInInstance() then
			ChannelName = "INSTANCE_CHAT"
		elseif IsInRaid() then			
			ChannelName = "RAID"
		elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then
			ChannelName = "PARTY"
		else
			ChannelName, TargetPlayerName = "WHISPER", PlayerName
		end

		SendAddonMessage("D4", "PT\t" .. Timer, ChannelName, TargetPlayerName)
	end
end



DBM.Run()