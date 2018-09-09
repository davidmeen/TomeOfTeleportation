
local MapIDAlteracValley = 91
local MapIDIsleOfThunder = 504
local MapIDDalaran = 125
local MapIDTanaanJungle = 534
local MapIDAzsuna = 627
local MapIDDalaranLegion = 1014
local MapIDAntoranWastes = 885
local MapIDAlterac = 943

local ContinentIdOutland = 101
local ContinentIdPandaria = 424
local ContinentIdDraenor = 946
local ContinentIdBrokenIsles = 619
local ContinentIdArgus = 905
local ContinentIdZandalar = 875
local ContinentIdKulTiras = 876

local function AtZone(requiredZone)
	return function()
		local mapID = C_Map.GetBestMapForUnit("player")
		while mapID ~= 0 do
			if mapID == requiredZone then
				return true
			end
			mapID = C_Map.GetMapInfo(mapID).parentMapID
		end
		return false
	end
end

local function AtContinent(requiredContinent)
	return AtZone(requiredContinent)
end

function AllowWhistle()
	return AtContinent(ContinentIdBrokenIsles)() or AtContinent(ContinentIdArgus)() or AtContinent(ContinentIdKulTiras)() or AtContinent(ContinentIdZandalar)() or AtZone(MapIdAlterac)
end

function InBFAZone()
	return AtContinent(ContinentIdKulTiras)() or AtContinent(ContinentIdZandalar)()
end

local function IsClass(requiredClass)
	return function()
		local _, playerClass = UnitClass("player")
		return playerClass == requiredClass
	end
end

local function HaveUpgradedZen()
	return IsQuestFlaggedCompleted(40236)
end

local DaySunday = 1
local DayMonday = 2
local DayTuesday = 3
local DayWednesday = 4
local DayThursday = 5
local DayFriday = 6
local DaySaturday = 7

local function OnDay(day)
	return function()
		local today = date("*t").wday
		return day == today
	end
end

local function OnDayAtContinent(day, continent)
	return function()
		return OnDay(day)() and AtContinent(continent)
	end
end

local function CreateDestination(zone, spells)	
	for i, spell in ipairs(spells) do
		spell.zone = zone
		tinsert(TeleporterDefaultSpells, spell)
	end
end

local function LocZone(name, mapID)
	if mapID == 0 then
		for i = 1, 10000 do
			local info = C_Map.GetMapInfo(i)
			if info and info.name == name then
				print(name .. " should be zone " .. i)
			end
		end
		return name
	else
		local locName = C_Map.GetMapInfo(mapID).name
		--if locName ~= name then
		--	print("Incorrect localization of " .. name)
		--end
		return locName
	end
end

local function LocArea(name, areaID)
	local locName
	if areaID == 0 then
		for i = 1, 10000 do
			if C_Map.GetAreaInfo(i) == name then
				print(name .. " should be area " .. i)
			end
		end
		return name
	else
		locName = C_Map.GetAreaInfo(areaID)
		--if locName ~= name then
		--	print("Incorrect localization of " .. name .. ", got " .. locName)		
		--end
	end
	return locName
end

local CreateSpell = TeleporterCreateSpell
local CreateItem = TeleporterCreateItem
local CreateChallengeSpell = TeleporterCreateChallengeSpell
local CreateConditionalItem = TeleporterCreateConditionalItem
local CreateConditionalSpell = TeleporterCreateConditionalSpell
local CreateConditionalConsumable = TeleporterCreateConditionalConsumable
local CreateConsumable = TeleporterCreateConsumable

TeleporterDefaultSpells = 
{	
}

CreateDestination(
	TeleporterHearthString,
	{
		CreateItem(93672),				-- Dark Portal
		CreateItem(54452),				-- Ethereal Portal
		CreateItem(6948 ),				-- Hearthstone
		CreateItem(28585),				-- Ruby Slippers
		CreateConsumable(37118),		-- Scroll of Recall
		CreateConsumable(44314),		-- Scroll of Recall II
		CreateConsumable(44315),		-- Scroll of Recall III
		CreateItem(64488),				-- The Innkeeper's Daughter	
		CreateItem(142298),				-- Astonishingly Scarlet Slippers
		CreateConsumable(142543),		-- Scroll of Town Portal
		CreateItem(142542),				-- Tome of Town Portal
		CreateItem(162973)				-- Greatfather Winter's Hearthstone
	})
	
CreateDestination(
	TeleporterRecallString,
	{
		CreateSpell(556)				-- Astral Recall
	})

CreateDestination(
	TeleporterFlightString,
	{ 
		CreateConditionalItem(141605, AllowWhistle) 	-- Flight Master's Whistle
	})
	
CreateDestination(
	LocZone("Alterac Valley", 91),
	{
		CreateConditionalItem(17690, AtZone(MapIDAlteracValley) ),	-- Frostwolf Insignia Rank 1
		CreateConditionalItem(17905, AtZone(MapIDAlteracValley) ),	-- Frostwolf Insignia Rank 2
		CreateConditionalItem(17906, AtZone(MapIDAlteracValley) ),	-- Frostwolf Insignia Rank 3
		CreateConditionalItem(17907, AtZone(MapIDAlteracValley) ),	-- Frostwolf Insignia Rank 4
		CreateConditionalItem(17908, AtZone(MapIDAlteracValley) ),	-- Frostwolf Insignia Rank 5
		CreateConditionalItem(17909, AtZone(MapIDAlteracValley) ),	-- Frostwolf Insignia Rank 6
		CreateConditionalItem(17691, AtZone(MapIDAlteracValley) ),	-- Stormpike Insignia Rank 1
		CreateConditionalItem(17900, AtZone(MapIDAlteracValley) ),	-- Stormpike Insignia Rank 2
		CreateConditionalItem(17901, AtZone(MapIDAlteracValley) ),	-- Stormpike Insignia Rank 3
		CreateConditionalItem(17902, AtZone(MapIDAlteracValley) ),	-- Stormpike Insignia Rank 4
		CreateConditionalItem(17903, AtZone(MapIDAlteracValley) ),	-- Stormpike Insignia Rank 5
		CreateConditionalItem(17904, AtZone(MapIDAlteracValley) ),	-- Stormpike Insignia Rank 6
	})

CreateDestination(
	LocZone("Antoran Wastes", 885),
	{
		CreateConditionalItem(153226, AtZone(MapIDAntoranWastes))	-- Observer's Locus Resonator
	})

CreateDestination(
	LocZone("Argus", 905),
	{
		CreateItem(151652)				-- Wormhole Generator: Argus
	})

CreateDestination(
	LocZone("Ashran", 588),
	{
		CreateConsumable(116413),		-- Scroll of Town Portal
		CreateConsumable(119183),		-- Scroll of Risky Recall
		CreateSpell(176246),			-- Portal: Stormshield
		CreateSpell(176248),			-- Teleport: Stormshield
		CreateSpell(176244),			-- Portal: Warspear
		CreateSpell(176242),			-- Teleport: Warspear
	})

CreateDestination(
	LocZone("Azsuna", 630),
	{
		CreateConditionalItem(129276, AtZone(MapIDAzsuna)),	-- Beginner's Guide to Dimensional Rifting
		CreateConditionalConsumable(141016, AtContinent(ContinentIdBrokenIsles)),	-- Scroll of Town Portal: Faronaar
		CreateConditionalItem(140493, OnDayAtContinent(DayWednesday, ContinentIdBrokenIsles)),	-- Adept's Guide to Dimensional Rifting
	}, 630)

CreateDestination(
	LocArea("Bizmo's Brawlpub", 6618),
	{
		CreateItem(95051),				-- The Brassiest Knuckle
		CreateItem(118907),				-- Pit Fighter's Punching Ring
		CreateItem(144391),				-- Pugilist's Powerful Punching Ring
	})			
			
CreateDestination(			
	LocZone("Black Temple", 490),
	{			
		CreateItem(32757),				-- Blessed Medallion of Karabor
		CreateItem(151016), 			-- Fractured Necrolyte Skull
	})
				
CreateDestination(			
	LocZone("Blackrock Depths", 242),
	{			
		CreateItem(37863)				-- Direbrew's Remote
	})

CreateDestination(			
	LocZone("Blackrock Foundry", 596),
	{	
		CreateChallengeSpell(169771)	-- Teleport: Blackrock Foundry
	})

CreateDestination(			
	LocZone("Blade's Edge Mountains", 105),	
	{
		CreateItem(30544),				-- Ultrasafe Transporter - Toshley's Station
	})

CreateDestination(			
	LocArea("Bladespire Citadel", 6864),
	{
		CreateItem(118662), 			-- Bladespire Relic
	})

CreateDestination(			
	LocArea("Booty Bay", 35),	
	{
		CreateItem(50287),				-- Boots of the Bay
	})
	
CreateDestination(			
	LocZone("Boralus", 1161),
	{
		CreateSpell(281403),			-- Teleport: Boralus
		CreateSpell(281400),			-- Portal: Boralus
	})

CreateDestination(			
	LocZone("Brawl'gar Arena", 503),	
	{
		CreateItem(95050),				-- The Brassiest Knuckle
		CreateItem(118908),				-- Pit Fighter's Punching Ring
		CreateItem(144392),				-- Pugilist's Powerful Punching Ring
	}, 503)
	
CreateDestination(			
	LocZone("Broken Isles",	619),
	{
		CreateConsumable(132523), 		-- Reaves Battery (can't always teleport, don't currently check).	
		CreateItem(144341), 			-- Rechargeable Reaves Battery
	})

CreateDestination(			
	LocZone("Dalaran", 625) .. " (Legion)",	
	{
		CreateSpell(224871),		-- Portal: Dalaran - Broken Isles (UNTESTED)
		CreateSpell(224869),		-- Teleport: Dalaran - Broken Isles	(UNTESTED)
		CreateItem(138448),			-- Emblem of Margoss
		CreateItem(139599),			-- Empowered Ring of the Kirin Tor
		CreateItem(140192),			-- Dalaran Hearthstone
		CreateConditionalItem(43824, AtZone(MapIDDalaranLegion)),	-- The Schools of Arcane Magic - Mastery
	})

CreateDestination(			
	LocZone("Dalaran", 625) .. " (WotLK)",	
	{
		CreateSpell(53140),			-- Teleport: Dalaran
		CreateSpell(53142),			-- Portal: Dalaran
	-- ilvl 200 rings
		CreateItem(40586),			-- Band of the Kirin Tor
		CreateItem(44934),			-- Loop of the Kirin Tor
		CreateItem(44935),			-- Ring of the Kirin Tor
		CreateItem(40585),			-- Signet of the Kirin Tor
	-- ilvl 213 rings
		CreateItem(45688),			-- Inscribed Band of the Kirin Tor
		CreateItem(45689),			-- Inscribed Loop of the Kirin Tor
		CreateItem(45690),			-- Inscribed Ring of the Kirin Tor
		CreateItem(45691),			-- Inscribed Signet of the Kirin Tor
	-- ilvl 226 rings
		CreateItem(48954),			-- Etched Band of the Kirin Tor
		CreateItem(48955),			-- Etched Loop of the Kirin Tor
		CreateItem(48956),			-- Etched Ring of the Kirin Tor
		CreateItem(48957),			-- Etched Signet of the Kirin Tor
	-- ilvl 251 rings
		CreateItem(51560),			-- Runed Band of the Kirin Tor
		CreateItem(51558),			-- Runed Loop of the Kirin Tor
		CreateItem(51559),			-- Runed Ring of the Kirin Tor
		CreateItem(51557),			-- Runed Signet of the Kirin Tor

		CreateConditionalItem(43824, AtZone(MapIDDalaran)),	-- The Schools of Arcane Magic - Mastery
		CreateItem(52251),			-- Jaina's Locket
	})
	
CreateDestination(			
	LocArea("Dalaran Crater", 279),
	{
		CreateSpell(120145),		-- Ancient Teleport: Dalaran
		CreateSpell(120146),		-- Ancient Portal: Dalaran
	})

CreateDestination(			
	LocZone("Darnassus", 89),
	{
		CreateSpell(3565),			-- Teleport: Darnassus
		CreateSpell(11419),			-- Portal: Darnassus
	})
	
CreateDestination(			
	LocZone("Dazar'alor", 1163),
	{
		CreateSpell(281404),		-- Teleport: Dazar'alor
		CreateSpell(281402),		-- Portal: Dazar'alor
	})

CreateDestination(
	LocZone("Deepholm", 207),
	{
		CreateConsumable(58487),	-- Potion of Deepholm
	})

CreateDestination(
	LocZone("Draenor", 572),
	{
		CreateConditionalConsumable(117389, AtContinent(ContinentIdDraenor)), -- Draenor Archaeologist's Lodestone
		CreateItem(112059),			-- Wormhole Centrifuge
		CreateConditionalItem(129929, AtContinent(ContinentIdOutland)),	-- Ever-Shifting Mirror
	})
	
CreateDestination(
	"Draenor Dungeons",					-- No localization
	{
		CreateChallengeSpell(159897),	-- Teleport: Auchindoun
		CreateChallengeSpell(159895),	-- Teleport: Bloodmaul Slag Mines
		CreateChallengeSpell(159901),	-- Teleport: Overgrown Outpost
		CreateChallengeSpell(159900),	-- Teleport: Grimrail Depot
		CreateChallengeSpell(159896),	-- Teleport: Iron Docks
		CreateChallengeSpell(159899),	-- Teleport: Shadowmoon Burial Grounds
		CreateChallengeSpell(159898),	-- Teleport: Skyreach
		CreateChallengeSpell(159902),	-- Teleport: Upper Blackrock Spire
	})

CreateDestination(
	LocZone("Acherus: The Ebon Hold", 647),
	{
		CreateSpell(50977),			-- Death Gate
	})

CreateDestination(
	LocZone("Emerald Dreamway", 715),
	{
		CreateSpell(193753), 		-- Dreamwalk
	})

CreateDestination(
	LocZone("The Exodar", 103),
	{
		CreateSpell(32271),			-- Teleport: Exodar
		CreateSpell(32266),			-- Portal: Exodar
	})

CreateDestination(
	"Fishing Pool",					-- No localization.
	{	
		CreateConditionalSpell(201891, AtContinent(ContinentIdBrokenIsles)),		-- Undercurrent
		CreateConditionalConsumable(162515, InBFAZone),	-- Midnight Salmon
	})
	
CreateDestination(
	GARRISON_LOCATION_TOOLTIP,
	{
		CreateItem(110560),				-- Garrison Hearthstone
	})

	
CreateDestination(
	LocZone("Hall of the Guardian", 734),
	{
		CreateChallengeSpell(193759), 	-- Teleport: Hall of the Guardian
	})
--	
CreateDestination(
	LocZone("Highmountain", 869),
	{
		CreateConditionalConsumable(141017, AtContinent(ContinentIdBrokenIsles)),				-- Scroll of Town Portal: Lian'tril
		CreateConditionalItem(140493, OnDayAtContinent(DayThursday, ContinentIdBrokenIsles)),	-- Adept's Guide to Dimensional Rifting
	})

CreateDestination(
	LocZone("Icecrown", 118),
	{
		CreateItem(46874),				-- Argent Crusader's Tabard
	})

CreateDestination(
	LocZone("Ironforge", 87),
	{
		CreateSpell(3562),				-- Teleport: Ironforge
		CreateSpell(11416)				-- Portal: Ironforge
	})

CreateDestination(
	LocZone("Isle of Thunder", 504),
	{
		CreateConditionalItem(95567, AtZone(MapIDIsleOfThunder )),	-- Kirin Tor Beacon
		CreateConditionalItem(95568, AtZone(MapIDIsleOfThunder )),	-- Sunreaver Beacon
	})

CreateDestination(
	LocArea("Karabor", 6930),
	{
		CreateItem(118663),				-- Relic of Karabor
	})

CreateDestination(
	LocZone("Karazhan", 794),
	{
		CreateItem(22589),		-- Atiesh, Greatstaff of the Guardian
		CreateItem(22630),		-- Atiesh, Greatstaff of the Guardian
		CreateItem(22631),		-- Atiesh, Greatstaff of the Guardian
		CreateItem(22632),		-- Atiesh, Greatstaff of the Guardian
		CreateItem(142469), 	-- Violet Seal of the Grand Magus
	})

CreateDestination(
	LocZone("Kun-Lai Summit", 379),
	{
		CreateConditionalSpell(126892, function() return not HaveUpgradedZen() end ),	-- Zen Pilgrimage
	})
	
CreateDestination(
	"Mole Machine",					-- No localization.
	{
		CreateSpell(265225),		-- Mole Machine
	})

CreateDestination(
	LocZone("Moonglade", 80),
	{
		CreateSpell(18960),		-- Teleport: Moonglade
		CreateItem(21711),		-- Lunar Festival Invitation
	})

CreateDestination(
	LocZone("Netherstorm", 109),
	{
		CreateItem(30542),		-- Dimensional Ripper - Area 52
	})

CreateDestination(
	LocZone("Northrend", 113),
	{
		CreateItem(48933),		-- Wormhole Generator: Northrend
	})

CreateDestination(
	LocZone("Orgrimmar", 85),
	{
		CreateSpell(3567),		-- Teleport: Orgrimmar
		CreateSpell(11417),		-- Portal: Orgrimmar
		CreateItem(63207),		-- Wrap of Unity
		CreateItem(63353),		-- Shroud of Cooperation
		CreateItem(65274),		-- Cloak of Coordination
	})

CreateDestination(
	LocZone("Outland", 101),
	{
		CreateConditionalItem(129929, AtContinent(ContinentIdDraenor) ),	-- Ever-Shifting Mirror
	})

CreateDestination(
	LocZone("Pandaria", 424),
	{
		CreateConditionalConsumable(87548, AtContinent(ContinentIdPandaria)), 	-- Lorewalker's Lodestone
		CreateItem(87215),														-- Wormhole Generator: Pandaria
	})

CreateDestination(
	"Pandaria Dungeons",		-- No localization.
	{
		CreateChallengeSpell(131225),	-- Path of the Setting Sun	
		CreateChallengeSpell(131222),	-- Path of the Mogu King
		CreateChallengeSpell(131231),	-- Path of the Scarlet Blade	
		CreateChallengeSpell(131229),	-- Path of the Scarlet Mitre	
		CreateChallengeSpell(131232),	-- Path of the Necromancer
		CreateChallengeSpell(131206),	-- Path of the Shado-Pan
		CreateChallengeSpell(131228),	-- Path of the Black Ox
		CreateChallengeSpell(131205),	-- Path of the Stout Brew
		CreateChallengeSpell(131204),	-- Path of the Jade Serpent
	})

CreateDestination(
	"Random",		-- No localization.
	{
		CreateSpell(147420),								-- One With Nature
		CreateItem(64457), 									-- The Last Relic of Argus
		CreateConditionalItem(136849, IsClass("DRUID")),	-- Nature's Beacon
	})

CreateDestination(
	LocArea("Ravenholdt", 0),
	{
		CreateItem(139590),		-- Scroll of Teleport: Ravenholdt
	})

CreateDestination(
	LocZone("Shattrath City", 111),
	{
		CreateSpell(33690),		-- Teleport: Shattrath (Alliance)
		CreateSpell(33691),		-- Portal: Shattrath (Alliance)
		CreateSpell(35715),		-- Teleport: Shattrath (Horde)
		CreateSpell(35717),		-- Portal: Shattrath (Horde)
	})

CreateDestination(
	LocArea("Shipyard", 6668),
	{
		CreateItem(128353),		-- Admiral's Compass
	})

CreateDestination(
	LocZone("Silvermoon City", 110),
	{
		CreateSpell(32272),		-- Teleport: Silvermoon
		CreateSpell(32267),		-- Portal: Silvermoon
	})

CreateDestination(
	LocArea("Stonard", 75),
	{
		CreateSpell(49358),		-- Teleport: Stonard
		CreateSpell(49361),		-- Portal: Stonard
	})

CreateDestination(
	LocZone("Stormheim", 634),
	{
		CreateConditionalItem(140493, OnDayAtContinent(DayFriday, ContinentIdBrokenIsles)),	-- Adept's Guide to Dimensional Rifting
	})

CreateDestination(
	LocZone("Stormwind City", 84),
	{
		CreateSpell(3561),		-- Teleport: Stormwind
		CreateSpell(10059),		-- Portal: Stormwind
		CreateItem(63206),		-- Wrap of Unity
		CreateItem(63352),		-- Shroud of Cooperation
		CreateItem(65360),		-- Cloak of Coordination
	})

CreateDestination(
	LocZone("Suramar", 680),
	{
		CreateItem(140324),																		-- Mobile Telemancy Beacon
		CreateConditionalConsumable(141014, AtContinent(ContinentIdBrokenIsles)),				-- Scroll of Town Portal: Sashj'tar
		CreateConditionalItem(140493, OnDayAtContinent(DayTuesday, ContinentIdBrokenIsles)),	-- Adept's Guide to Dimensional Rifting
	})
		
CreateDestination(
	LocZone("Tanaan Jungle", 534),
	{
		CreateConditionalItem(128502, AtZone(MapIDTanaanJungle)),	-- Hunter's Seeking Crystal
		CreateConditionalItem(128503, AtZone(MapIDTanaanJungle)),	-- Master Hunter's Seeking Crystal
	})

CreateDestination(
	LocZone("Tanaris", 71),
	{
		CreateItem(18986),		-- Ultrasafe Transporter - Gadgetzan
	})

CreateDestination(
	LocArea("Temple of Five Dawns", 5820),
	{
		CreateConditionalSpell(126892, function() return HaveUpgradedZen() end ),	-- Zen Pilgrimage
	})

CreateDestination(
	LocArea("Theramore Isle", 513),
	{
		CreateSpell(49359),		-- Teleport: Theramore
		CreateSpell(49360),		-- Portal: Theramore
	})

CreateDestination(
	LocZone("Timeless Isle", 554),
	{
		CreateItem(103678),		-- Time-Lost Artifact
	})

CreateDestination(
	LocZone("Thunder Bluff", 88),
	{
		CreateSpell(3566),		-- Teleport: Thunder Bluff
		CreateSpell(11420),		-- Portal: Thunder Bluff
	})

CreateDestination(
	LocZone("Tol Barad", 773),
	{
		CreateItem(63378),		-- Hellscream's Reach Tabard
		CreateItem(63379),		-- Baradin's Wardens Tabard
		CreateSpell(88342),		-- Teleport: Tol Barad (Alliance)
		CreateSpell(88344),		-- Teleport: Tol Barad (Horde)
		CreateSpell(88345),		-- Portal: Tol Barad (Alliance)
		CreateSpell(88346),		-- Portal: Tol Barad (Horde)
	})

CreateDestination(
	LocZone("Undercity", 90),
	{
		CreateSpell(3563),		-- Teleport: Undercity
		CreateSpell(11418),		-- Portal: Undercity
	})

CreateDestination(
	LocZone("Val'sharah", 641),
	{
		CreateConditionalConsumable(141013, AtContinent(ContinentIdBrokenIsles)),			-- Scroll of Town Portal: Shala'nir
		CreateConditionalConsumable(141015, AtContinent(ContinentIdBrokenIsles)),			-- Scroll of Town Portal: Kal'delar	
		CreateConditionalItem(140493, OnDayAtContinent(DayMonday, ContinentIdBrokenIsles)),	-- Adept's Guide to Dimensional Rifting
	})

-- I don't know why there are so many of these, not sure which is right but it's now safe to
-- list them all.
CreateDestination(
	LocZone("Vale of Eternal Blossoms", 390),
	{
		CreateSpell(132621),	-- Teleport: Vale of Eternal Blossoms
		CreateSpell(132627),	-- Teleport: Vale of Eternal Blossoms
		CreateSpell(132620),	-- Portal: Vale of Eternal Blossoms
		CreateSpell(132622),	-- Portal: Vale of Eternal Blossoms
		CreateSpell(132624),	-- Portal: Vale of Eternal Blossoms
		CreateSpell(132626),	-- Portal: Vale of Eternal Blossoms
	})

CreateDestination(
	LocZone("Winterspring", 83),
	{
		CreateItem(18984),		-- Dimensional Ripper - Everlook
	})

CreateDestination(
	LocZone("Zuldazar", 862),
	{
		CreateConsumable(157542),	-- Portal Scroll of Specificity
		CreateConsumable(160218),	-- Portal Scroll of Specificity
	})
