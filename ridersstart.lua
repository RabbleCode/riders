riders = {};

function riders:OnLoad()

	SLASH_riders1 = "/riders";
	SlashCmdList["riders"] = function(msg) riders:HandleSlashCommand(msg) end

	ridersFrame:RegisterEvent("PLAYER_LOGIN")
	ridersFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	ridersFrame:RegisterEvent("ADDON_LOADED")
end

function riders:OnEvent(self, event, ...)

	local arg1, arg2, arg3, arg4 = ...
	if event == "ADDON_LOADED" and arg1 == "riders" then
		ridersFrame:UnregisterEvent("ADDON_LOADED");
	elseif event == "PLAYER_LOGIN" then
		ridersFrame:UnregisterEvent("PLAYER_LOGIN");
		riders:LoadQuestData();
		riders:LoadPlayerData();
		riders:LoadAccountData();
		riders:PrimeItemCache();
		riders:UpdatePlayerProgress();
		riders:Announce();
	elseif event == "PLAYER_ENTERING_WORLD" then
		ridersFrame:UnregisterEvent("PLAYER_ENTERING_WORLD");
	end
end

function riders:LoadPlayerData()

	riders.CurrentRealm = GetRealmName();
	riders.PlayerName = UnitName("player");
	riders.PlayerNameWithRealm = riders.CurrentRealm.." - "..riders.PlayerName
	riders.PlayerClass = UnitClass("player");
	riders.PlayerFaction = UnitFactionGroup("player");
	riders.PlayerLevel = UnitLevel("player");
	riders.PlayerProgress = {}
	riders.PlayerProgress.Quests = {}
end

function riders:LoadAccountData()

	if(RidersCharacterProgress == nil) then 
		RidersCharacterProgress = {} 
	end
	
	if(RidersCharacterProgress[riders.CurrentRealm] == nil) then
		RidersCharacterProgress[riders.CurrentRealm] = {}
	end

end

-- Calls GetItemInfo on all related quest items to prime the local cache
function riders:PrimeItemCache()

	-- Get each quest's item info
	for _, quest in pairs(riders.Quests) do			
		GetItemInfo(quest.ItemID)
	end	
end

function riders:Announce()

	riders:PrintMessageWithRidersPrefix("activated");	
end