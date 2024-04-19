
function riders:HandleSlashCommand(cmd)

	if cmd ~= nil and cmd ~= "" then
		if(cmd == "delete all") then			
			--riders:EraseAllCharacterProgress();
			riders:PrintMessageWithRidersPrefix("delete all command not yet implemented")
		elseif(cmd == "delete") then
			--riders:ErasePlayerProgress();
			riders:PrintMessageWithRidersPrefix("delete command not yet implemented")
		else
			local character, realm = riders:GetCharacterAndRealm(cmd)
			if(realm ~= nil) then
				riders:CheckSpecificCharacter(character, realm);
			else
				riders:CheckSpecificCharacter(character, riders.CurrentRealm);
			end			
		end
	else
		riders:UpdatePlayerProgress();
		riders:PrintCharacterProgress(riders.PlayerName, riders.CurrentRealm);
	end
end

function riders:GetCharacterAndRealm(arguments)
	local character, realm = arguments:match("^(%S*)%s*(.-)$")
	character = riders:ConvertToTitleCase(character)
	if(realm ~= nil and realm ~= '') then
		realm = riders:ConvertToTitleCase(realm)	
	else
		realm = nil
	end
	return character, realm
end

function riders:ConvertToTitleCase(text)
	return string.gsub(text, "(%a)([%w_']*)", function(first, rest) return first:upper()..rest:lower() end)
end

function riders:GetClassColor(class)
	class = string.upper(class)
	local colorStr = RAID_CLASS_COLORS[class]["colorStr"] or YELLOW_FONT_COLOR_CODE
	return "|c"..colorStr
end

function riders:GetClassColoredName(class, character, realm)
	return riders:GetClassColor(class)..character.."|r"..YELLOW_FONT_COLOR_CODE.." - "..realm
end

function riders:CheckSpecificCharacter(character, realm)

	local name = character.." - "..realm
	local progress = nil
	if(RidersCharacterProgress[realm] ~= nil and RidersCharacterProgress[realm][character] ~= nil) then
		progress = RidersCharacterProgress[realm][character]	
	end
	if progress == nil then	
		riders:PrintMessageWithRidersPrefix("Progress for "..YELLOW_FONT_COLOR_CODE..name..RED_FONT_COLOR_CODE.." not found.")
	else		
		riders:PrintCharacterProgress(character, realm)
	end
end

function riders:ErasePlayerProgress()

	riders:PrintMessageWithRidersPrefix(RED_FONT_COLOR_CODE.."Erasing |rdata for "..YELLOW_FONT_COLOR_CODE..riders.PlayerNameWithRealm)
	riders.PlayerProgress = nil
	riders:SavePlayerProgress()
end

function riders:EraseAllCharacterProgress()

	riders:PrintMessageWithRidersPrefix(RED_FONT_COLOR_CODE.."Erasing data for all characters.")		
	RidersCharacterProgress = nil
end

function riders:SavePlayerProgress()
	if(RidersCharacterProgress[riders.CurrentRealm] ~= nil) then
		-- Delete character progress if it's nil
		if(riders.PlayerProgress == nil) then
			RidersCharacterProgress[riders.CurrentRealm][riders.PlayerName] = nil
		-- Save character progress
		else
			RidersCharacterProgress[riders.CurrentRealm][riders.PlayerName] = riders.PlayerProgress	
		end

		-- After updating character progress, check if there are any characters recorded on this realm
		local realmCount = 0
		for _,_ in pairs(RidersCharacterProgress[riders.CurrentRealm]) do	
			realmCount = realmCount + 1
		end

		-- If there are no recorded characters on this realm, delete the realm too
		if(realmCount == 0) then
			RidersCharacterProgress[riders.CurrentRealm] = nil
		end
	end
end

function riders:UpdatePlayerProgress()
	if(riders.Quests ~= nil) then
		riders:LoadPlayerData()
		riders.PlayerProgress.Faction = riders.PlayerFaction
		riders.PlayerProgress.Level = riders.PlayerLevel
		riders.PlayerProgress.Class = riders.PlayerClass

		if(C_QuestLog.IsQuestFlaggedCompleted(riders.FinalQuest.QuestID)) then
			riders.PlayerProgress.Completed = true;
			riders.PlayerProgress.Quests = nil
		elseif(IsQuestComplete(riders.FinalQuest.QuestID)) then
			riders.PlayerProgress.Ready = true;
			riders.PlayerProgress.Quests = nil
		else
			local progressedQuests = 0

			for _, quest in pairs(riders.Quests) do

				local questID = quest.QuestID
				local itemID = quest.ItemID
				local locationID = quest.LocationID
				local location = quest.Location
				
				local questProgress = {}

				-- Quest is already completed and turned in
				if C_QuestLog.IsQuestFlaggedCompleted(questID) then
					questProgress.Completed = true;
					progressedQuests = progressedQuests + 1
				-- Quest is complete and ready to be turned in
				elseif GetItemCount(itemID) > 0 then
					questProgress.Ready = true
					progressedQuests = progressedQuests + 1
				-- Quest is not yet complete, check each individual chapter
				else
					questProgress = nil;
				end

				riders.PlayerProgress.Quests[questID] = questProgress
			end		
			
			-- Else if no quests progressed, erase all progress
			if(progressedQuests == 0) then
				riders.PlayerProgress = nil
			end
		end

		riders:SavePlayerProgress();
	else
		riders:PrintMessageWithRidersPrefix(RED_FONT_COLOR_CODE.."Quest information corrupted. Please reinstall the addon.")
	end
end

function riders:PrintCharacterProgress(character, realm)

	local realmProgress = RidersCharacterProgress[realm]
	local characterProgress 
	if(realmProgress ~= nil) then
		characterProgress = RidersCharacterProgress[realm][character]
	end

	-- Progress flags
	local hasProgress = characterProgress ~= nil
	local isCompleted = hasProgress and characterProgress.Completed == true
	
	-- Character info
	local faction = characterProgress.Faction or "UNKNOWN"
	local level = characterProgress.Level or 0
	local class = characterProgress.Class or "UNKNOWN"
	local classColoredName = riders:GetClassColoredName(class, character, realm)

	if(isCompleted) then
		riders:PrintMessageWithRidersPrefix("Quest chain "..GREEN_FONT_COLOR_CODE.."already completed|r for "..YELLOW_FONT_COLOR_CODE..classColoredName);
	else
		riders:PrintMessageWithRidersPrefix("Quest chain "..RED_FONT_COLOR_CODE.."incomplete|r for "..YELLOW_FONT_COLOR_CODE..classColoredName);
		riders:PrintQuestsProgress(characterProgress)
	end
end

function riders:PrintQuestsProgress(progress)

	for _, quest in pairs(riders.Quests) do

		local questID = quest.QuestID
		local hasProgress = progress ~= nil and progress.Quests ~= nil and progress.Quests[questID] ~= nil
		local location = quest.Location

		-- if character has recorded progress
		if(hasProgress) then
			local questProgress = progress.Quests[questID]
			-- if chapter is already completed
			if(questProgress.Completed == true) then
				riders:PrintMessage("  "..YELLOW_FONT_COLOR_CODE..location..": "..GREEN_FONT_COLOR_CODE.."completed!")
			-- else if chapter is ready for turn in
			elseif(questProgress.Ready == true) then
				riders:PrintMessage("  "..YELLOW_FONT_COLOR_CODE..location..": "..ORANGE_FONT_COLOR_CODE.."ready for turn in.") 
			end
		else
			-- no recorded progress
			riders:PrintMessage("  "..YELLOW_FONT_COLOR_CODE..location.." |r("..quest.Coordinates.."): "..RED_FONT_COLOR_CODE.."incomplete.")
		end
	end
end

function riders:PrintHeader(characterName)

	riders:PrintMessageWithRidersPrefix("progress for "..YELLOW_FONT_COLOR_CODE..characterName.."...");
end

function riders:PrintMessageWithRidersPrefix(message)

	riders:PrintMessage(YELLOW_FONT_COLOR_CODE.."RIDERS|r | "..message)
end

function riders:PrintMessage(message)

	DEFAULT_CHAT_FRAME:AddMessage(message)
end

function riders:PrintFooter(completed)

	riders:PrintSeparatorLine();
end

function riders:PrintSeparatorLine()

	DEFAULT_CHAT_FRAME:AddMessage("|r");
end

function riders:PrintDebug(message)
	
	DEFAULT_CHAT_FRAME:AddMessage(YELLOW_FONT_COLOR_CODE.."Riders|r DEBUG | "..message);
end