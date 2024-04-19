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

	-- Get each chapter
	for index, chapter in pairs(riders.MainQuest.Chapters) do			
		GetItemInfo(chapter.ItemID)	

		-- Get pages for each chapter
		for index, itemID in pairs(chapter.Pages) do	
			GetItemInfo(itemID)		
		end	
	end	
end

function riders:Announce()

	riders:PrintMessageWithridersPrefix("activated");	
end