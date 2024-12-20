function riders:LoadQuestData()

	riders.FinalQuest = {}
	riders.FinalQuest.QuestID = 80120

	local deadwind = {}
	deadwind.QuestID = 80098
	deadwind.ItemID = 216945
	deadwind.LocationID = 41
	deadwind.Location = C_Map.GetAreaInfo(deadwind.LocationID)
	deadwind.Coordinates = "43,29"

	local duskwood = {}
	duskwood.QuestID = 80147
	duskwood.ItemID = 216946
	duskwood.LocationID = 10
	duskwood.Location = C_Map.GetAreaInfo(duskwood.LocationID)
	duskwood.Coordinates = "23,47"

	local swamp = {}
	swamp.QuestID = 80149
	swamp.ItemID = 216948
	swamp.LocationID = 8
	swamp.Location = C_Map.GetAreaInfo(swamp.LocationID)
	swamp.Coordinates = "69,28"

	local arathi = {}
	arathi.QuestID = 80148
	arathi.ItemID = 216947
	arathi.LocationID = 45
	arathi.Location = C_Map.GetAreaInfo(arathi.LocationID)
	arathi.Coordinates = "60,40"

	local badlands = {}
	badlands.QuestID = 80152
	badlands.ItemID = 216951
	badlands.LocationID = 3
	badlands.Location = C_Map.GetAreaInfo(badlands.LocationID)
	badlands.Coordinates = "58,54"

	local barrens = {}
	barrens.QuestID = 80150
	barrens.ItemID = 216949
	barrens.LocationID = 17
	barrens.Location = C_Map.GetAreaInfo(barrens.LocationID)
	barrens.Coordinates = "52,36"

	local desolace = {}
	desolace.QuestID = 80151
	desolace.ItemID = 216950
	desolace.LocationID = 405
	desolace.Location = C_Map.GetAreaInfo(desolace.LocationID)
	desolace.Coordinates = "65,25"	

	riders.Quests = {deadwind, duskwood, swamp, arathi, badlands, barrens, desolace}
end