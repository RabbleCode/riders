
function riders:HandleSlashCommand(cmd)

	if cmd ~= nil and cmd ~= "" then
		if(cmd == "delete all") then			
			riders:EraseAllCharacterProgress();
		elseif(cmd == "delete") then
			riders:ErasePlayerProgress();
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
		riders:PrintMessageWithridersPrefix("Progress for "..YELLOW_FONT_COLOR_CODE..name..RED_FONT_COLOR_CODE.." not found.")
	else		
		riders:PrintCharacterProgress(character, realm)
	end
end

function riders:ErasePlayerProgress()

	riders:PrintMessageWithridersPrefix(RED_FONT_COLOR_CODE.."Erasing |rdata for "..YELLOW_FONT_COLOR_CODE..riders.PlayerNameWithRealm)
	riders.PlayerProgress = nil
	riders:SavePlayerProgress()
end

function riders:EraseAllCharacterProgress()

	riders:PrintMessageWithridersPrefix(RED_FONT_COLOR_CODE.."Erasing data for all characters.")		
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


	if(riders.MainQuest ~= nil and riders.MainQuest.Chapters ~= nil) then
		riders:LoadPlayerData()
		riders.PlayerProgress.Faction = riders.PlayerFaction
		riders.PlayerProgress.Level = riders.PlayerLevel
		riders.PlayerProgress.Class = riders.PlayerClass

		local questID = riders.MainQuest.QuestID

		-- Quest is already completed and turned in
		if C_QuestLog.IsQuestFlaggedCompleted(questID) then
			riders.PlayerProgress.Completed = true
		-- Quest is complete and ready to be turned in
		elseif IsQuestComplete(questID) then
			riders.PlayerProgress.Ready = true
		-- Quest is not yet complete, check each individual chapter
		else
			riders:UpdateChapterProgress()
		end
		
		riders:SavePlayerProgress();
	else
		riders:PrintMessageWithridersPrefix(RED_FONT_COLOR_CODE.."Quest information corrupted. Please reinstall the addon.")
	end
end

function riders:UpdateChapterProgress()
	
	if(riders.MainQuest ~= nil and riders.MainQuest.Chapters ~= nil) then			
		local chapters = 0
		for _, chapter in pairs(riders.MainQuest.Chapters) do
			
			local chapterProgress = {}
			local questID = chapter.QuestID
			local isComplete = C_QuestLog.IsQuestFlaggedCompleted(questID) 
			local isReady = IsQuestComplete(questID)
			local hasChapter = GetItemCount(chapter.ItemID) > 0
			local hasPages = false
			local pages = {}

			-- If incomplete, record progress on individual pages
			if not isComplete and not isReady then
				hasPages, pages = riders:FindCollectedPages(chapter)
			end
			
			-- Only cache data if there's something to cache
			if(isComplete) then
				chapters = chapters + 1;
				chapterProgress.Completed = true
			elseif(isReady) then
				chapters = chapters + 1;
				chapterProgress.Ready = true
			elseif(hasPages) then
				chapters = chapters + 1;
				chapterProgress.Pages = pages
			else
				chapterProgress = nil
			end

			-- If progress on this chapter
			if(chapterProgress ~= nil) then
				-- Make sure the base Chapters node isn't empty
				if(riders.PlayerProgress.Chapters == nil) then
					riders.PlayerProgress.Chapters = {}
				end
				-- And update the node for this chapter
				riders.PlayerProgress.Chapters[chapter.QuestID] = chapterProgress
			-- If no progress on this chapter, remove the node for this chapter if it exists
			elseif(riders.PlayerProgress.Chapters ~= nil) then
				riders.PlayerProgress.Chapters[chapter.QuestID] = nil	
			end

			-- If no progress on any chapters, remove the entire Chapters node
			if(chapters == 0) then
				riders.PlayerProgress.Chapters = nil
			end
		end	
	else
		riders:PrintMessageWithridersPrefix(RED_FONT_COLOR_CODE.."Quest information corrupted. Please reinstall the addon.")
	end
end

function riders:FindCollectedPages(chapter)
	local hasPages = false
	local pages = {}

	for _, pageID in pairs(chapter.Pages) do			
		if GetItemCount(pageID) > 0 then
			hasPages = true;
			pages[pageID] = true
		end
	end

	return hasPages, pages
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
	local isReady = hasProgress and characterProgress.Ready == true
	
	-- Character info
	local faction = characterProgress.Faction or "UNKNOWN"
	local level = characterProgress.Level or 0
	local class = characterProgress.Class or "UNKNOWN"
	local classColoredName = riders:GetClassColoredName(class, character, realm)

	if(isCompleted) then
		riders:PrintMessageWithridersPrefix("Quest chain "..GREEN_FONT_COLOR_CODE.."already completed|r for "..YELLOW_FONT_COLOR_CODE..classColoredName);
	elseif(isReady) then
		riders:PrintMessageWithridersPrefix("Quest chain "..ORANGE_FONT_COLOR_CODE.."ready for turn in|r for "..YELLOW_FONT_COLOR_CODE..classColoredName);
	else
		riders:PrintMessageWithridersPrefix("Quest chain "..RED_FONT_COLOR_CODE.."incomplete|r for "..YELLOW_FONT_COLOR_CODE..classColoredName);
		riders:PrintChaptersProgress(characterProgress)
	end
end

function riders:PrintChaptersProgress(progress)

	for _, chapter in pairs(riders.MainQuest.Chapters) do

		local questID = chapter.QuestID
		local name = chapter.Name
		local hasProgress = progress ~= nil and progress.Chapters ~= nil and progress.Chapters[questID] ~= nil

		-- if character has recorded progress
		if(hasProgress) then
			local chapterProgress = progress.Chapters[questID]
			-- if chapter is already completed
			if(chapterProgress.Completed == true) then
				riders:PrintMessage("  "..YELLOW_FONT_COLOR_CODE..name..": "..GREEN_FONT_COLOR_CODE.."completed!")
			-- else if chapter is ready for turn in
			elseif(chapterProgress.Ready == true) then
				riders:PrintMessage("  "..YELLOW_FONT_COLOR_CODE..name..": "..ORANGE_FONT_COLOR_CODE.."ready for turn in.") 
			-- else if chapter is incomplete
			else
				riders:PrintMessage("  "..YELLOW_FONT_COLOR_CODE..name)
				riders:PrintPagesProgress(chapter, chapterProgress)
			end
		else
			-- no recorded progress
		riders:PrintMessage("  "..YELLOW_FONT_COLOR_CODE..name)
			riders:PrintPagesProgress(chapter, nil)
		end
	end
end

function riders:PrintPagesProgress(chapter, chapterProgress)

	for _, pageID in pairs(chapter.Pages) do
		local _, link = GetItemInfo(pageID)
		if(chapterProgress ~= nil and chapterProgress.Pages ~= nil and chapterProgress.Pages[pageID] ~= nil) then
			riders:PrintMessage("    "..link..": "..GREEN_FONT_COLOR_CODE.."collected")
		else
			riders:PrintMessage("    "..link..": "..RED_FONT_COLOR_CODE.."missing")
		end
	end
end

function riders:PrintHeader(characterName)

	riders:PrintMessageWithridersPrefix("progress for "..YELLOW_FONT_COLOR_CODE..characterName.."...");
end

function riders:PrintMessageWithridersPrefix(message)

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
	
	DEFAULT_CHAT_FRAME:AddMessage(YELLOW_FONT_COLOR_CODE.."riders|r DEBUG | "..message);
end