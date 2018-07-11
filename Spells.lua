
local MapIDAlteracValley = 91
local MapIDIsleOfThunder = 504
local MapIDDalaran = 125
local MapIDTanaanJungle = 534
local MapIDAzsuna = 627
local MapIDDalaranLegion = 1014
local MapIDAntoranWastes = 885

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
	return AtContinent(ContinentIdBrokenIsles)() or AtContinent(ContinentIdArgus)() or AtContinent(ContinentIdKulTiras)() or AtContinent(ContinentIdZandalar)()
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
	"Alterac Valley",
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
	"Antoran Wastes",
	{
		CreateConditionalItem(153226, AtZone(MapIDAntoranWastes))	-- Observer's Locus Resonator
	})

CreateDestination(
	"Argus",
	{
		CreateItem(151652)				-- Wormhole Generator: Argus
	})

CreateDestination(
	"Ashran",
	{
		CreateConsumable(116413),		-- Scroll of Town Portal
		CreateConsumable(119183),		-- Scroll of Risky Recall
		CreateSpell(176246),			-- Portal: Stormshield
		CreateSpell(176248),			-- Teleport: Stormshield
		CreateSpell(176244),			-- Portal: Warspear
		CreateSpell(176242),			-- Teleport: Warspear
	})

CreateDestination(
	"Azsuna",
	{
		CreateConditionalItem(129276, AtZone(MapIDAzsuna)),	-- Beginner's Guide to Dimensional Rifting
		CreateConditionalConsumable(141016, AtContinent(ContinentIdBrokenIsles)),	-- Scroll of Town Portal: Faronaar
		CreateConditionalItem(140493, OnDayAtContinent(DayWednesday, ContinentIdBrokenIsles)),	-- Adept's Guide to Dimensional Rifting
	})

CreateDestination(
	"Bizmo's Brawlpub",
	{
		CreateItem(95051),				-- The Brassiest Knuckle
		CreateItem(118907),				-- Pit Fighter's Punching Ring
		CreateItem(144391),				-- Pugilist's Powerful Punching Ring
	})			
			
CreateDestination(			
	"Black Temple",			
	{			
		CreateItem(32757),				-- Blessed Medallion of Karabor
		CreateItem(151016), 			-- Fractured Necrolyte Skull
	})			
				
CreateDestination(			
	"Blackrock Depths",			
	{			
		CreateItem(37863)				-- Direbrew's Remote
	})

CreateDestination(			
	"Blackrock Foundry",			
	{	
		CreateChallengeSpell(169771)	-- Teleport: Blackrock Foundry
	})

CreateDestination(			
	"Blackrock Foundry",	
	{
		CreateItem(30544),				-- Ultrasafe Transporter - Toshley's Station
	})

CreateDestination(			
	"Bladespire Fortress",	
	{
		CreateItem(118662), 			-- Bladespire Relic
	})

CreateDestination(			
	"Booty Bay",	
	{
		CreateItem(50287),				-- Boots of the Bay
	})
	
CreateDestination(			
	"Boralus",	
	{
		CreateSpell(281403),			-- Teleport: Boralus
		CreateSpell(281400),			-- Portal: Boralus
	})

CreateDestination(			
	"Brawl'gar Arena",	
	{
		CreateItem(95050),				-- The Brassiest Knuckle
		CreateItem(118908),				-- Pit Fighter's Punching Ring
		CreateItem(144392),				-- Pugilist's Powerful Punching Ring
	})
	
CreateDestination(			
	"Broken Isles",	
	{
		CreateConsumable(132523), 		-- Reaves Battery (can't always teleport, don't currently check).	
		CreateItem(144341), 			-- Rechargeable Reaves Battery
	})

CreateDestination(			
	"Dalaran (Legion)",	
	{
		CreateSpell(224871),		-- Portal: Dalaran - Broken Isles (UNTESTED)
		CreateSpell(224869),		-- Teleport: Dalaran - Broken Isles	(UNTESTED)
		CreateItem(138448),			-- Emblem of Margoss
		CreateItem(139599),			-- Empowered Ring of the Kirin Tor
		CreateItem(140192),			-- Dalaran Hearthstone
		CreateConditionalItem(43824, AtZone(MapIDDalaranLegion)),	-- The Schools of Arcane Magic - Mastery
	})

CreateDestination(			
	"Dalaran (WotLK)",	
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
	"Dalaran Crater",	
	{
		CreateSpell(120145),		-- Ancient Teleport: Dalaran
		CreateSpell(120146),		-- Ancient Portal: Dalaran
	})

CreateDestination(			
	"Darnassus",	
	{
		CreateSpell(3565),			-- Teleport: Darnassus
		CreateSpell(11419),			-- Portal: Darnassus
	})
	
CreateDestination(			
	"Dazar'alor",	
	{
		CreateSpell(281404),		-- Teleport: Dazar'alor
		CreateSpell(281402),		-- Portal: Dazar'alor
	})

CreateDestination(
	"Deepholm",
	{
		CreateConsumable(58487),	-- Potion of Deepholm
	})

CreateDestination(
	"Draenor",
	{
		CreateConditionalConsumable(117389, AtContinent(ContinentIdDraenor)), -- Draenor Archaeologist's Lodestone
		CreateItem(112059),			-- Wormhole Centrifuge
		CreateConditionalItem(129929, AtContinent(ContinentIdOutland)),	-- Ever-Shifting Mirror
	})
	
CreateDestination(
	"Draenor Dungeons",
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
	"Ebon Hold",
	{
		CreateSpell(50977),			-- Death Gate
	})

CreateDestination(
	"Emerald Dreamway",
	{
		CreateSpell(193753), 		-- Dreamwalk
	})

CreateDestination(
	"Exodar",
	{
		CreateSpell(32271),			-- Teleport: Exodar
		CreateSpell(32266),			-- Portal: Exodar
	})

CreateDestination(
	"Fishing Pool",
	{	
		CreateConditionalSpell(201891, AtContinent(ContinentIdBrokenIsles)),		-- Undercurrent
		CreateConditionalConsumable(162515, InBFAZone),	-- Midnight Salmon
	})
	
CreateDestination(
	"Garrison",
	{
		CreateItem(110560),				-- Garrison Hearthstone
	})

	
CreateDestination(
	"Hall of the Guardian",
	{
		CreateChallengeSpell(193759), 	-- Teleport: Hall of the Guardian
	})
--	
CreateDestination(
	"Highmountain",
	{
		CreateConditionalConsumable(141017, AtContinent(ContinentIdBrokenIsles)),				-- Scroll of Town Portal: Lian'tril
		CreateConditionalItem(140493, OnDayAtContinent(DayThursday, ContinentIdBrokenIsles)),	-- Adept's Guide to Dimensional Rifting
	})

CreateDestination(
	"Icecrown",
	{
		CreateItem(46874),				-- Argent Crusader's Tabard
	})

CreateDestination(
	"Ironforge",
	{
		CreateSpell(3562),				-- Teleport: Ironforge
		CreateSpell(11416)				-- Portal: Ironforge
	})

CreateDestination(
	"Isle of Thunder",
	{
		CreateConditionalItem(95567, AtZone(MapIDIsleOfThunder )),	-- Kirin Tor Beacon
		CreateConditionalItem(95568, AtZone(MapIDIsleOfThunder )),	-- Sunreaver Beacon
	})

CreateDestination(
	"Karabor",
	{
		CreateItem(118663),				-- Relic of Karabor
	})

CreateDestination(
	"Karazhan",
	{
		CreateItem(22589),		-- Atiesh, Greatstaff of the Guardian
		CreateItem(22630),		-- Atiesh, Greatstaff of the Guardian
		CreateItem(22631),		-- Atiesh, Greatstaff of the Guardian
		CreateItem(22632),		-- Atiesh, Greatstaff of the Guardian
		CreateItem(142469), 	-- Violet Seal of the Grand Magus
	})

CreateDestination(
	"Kun Lai Summit",
	{
		CreateConditionalSpell(126892, function() return not HaveUpgradedZen() end ),	-- Zen Pilgrimage
	})
	
CreateDestination(
	"Mole Machine",
	{
		CreateSpell(265225),		-- Mole Machine
	})

CreateDestination(
	"Moonglade",
	{
		CreateSpell(18960),		-- Teleport: Moonglade
		CreateItem(21711),		-- Lunar Festival Invitation
	})

CreateDestination(
	"Netherstorm",
	{
		CreateItem(30542),		-- Dimensional Ripper - Area 52
	})

CreateDestination(
	"Northrend",
	{
		CreateItem(48933),		-- Wormhole Generator: Northrend
	})

CreateDestination(
	"Orgrimmar",
	{
		CreateSpell(3567),		-- Teleport: Orgrimmar
		CreateSpell(11417),		-- Portal: Orgrimmar
		CreateItem(63207),		-- Wrap of Unity
		CreateItem(63353),		-- Shroud of Cooperation
		CreateItem(65274),		-- Cloak of Coordination
	})

CreateDestination(
	"Outland",
	{
		CreateConditionalItem(129929, AtContinent(ContinentIdDraenor) ),	-- Ever-Shifting Mirror
	})

CreateDestination(
	"Pandaria",
	{
		CreateConditionalConsumable(87548, AtContinent(ContinentIdPandaria)), 	-- Lorewalker's Lodestone
		CreateItem(87215),														-- Wormhole Generator: Pandaria
	})

CreateDestination(
	"Pandaria Dungeons",
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
	"Random",
	{
		CreateSpell(147420),								-- One With Nature
		CreateItem(64457), 									-- The Last Relic of Argus
		CreateConditionalItem(136849, IsClass("DRUID")),	-- Nature's Beacon
	})

CreateDestination(
	"Ravenholdt",
	{
		CreateItem(139590),		-- Scroll of Teleport: Ravenholdt
	})

CreateDestination(
	"Shattrath",
	{
		CreateSpell(33690),		-- Teleport: Shattrath (Alliance)
		CreateSpell(33691),		-- Portal: Shattrath (Alliance)
		CreateSpell(35715),		-- Teleport: Shattrath (Horde)
		CreateSpell(35717),		-- Portal: Shattrath (Horde)
	})

CreateDestination(
	"Shipyard",
	{
		CreateItem(128353),		-- Admiral's Compass
	})

CreateDestination(
	"Silvermoon",
	{
		CreateSpell(32272),		-- Teleport: Silvermoon
		CreateSpell(32267),		-- Portal: Silvermoon
	})

CreateDestination(
	"Stonard",
	{
		CreateSpell(49358),		-- Teleport: Stonard
		CreateSpell(49361),		-- Portal: Stonard
	})

CreateDestination(
	"Stormheim",
	{
		CreateConditionalItem(140493, OnDayAtContinent(DayFriday, ContinentIdBrokenIsles)),	-- Adept's Guide to Dimensional Rifting
	})

CreateDestination(
	"Stormwind",
	{
		CreateSpell(3561),		-- Teleport: Stormwind
		CreateSpell(10059),		-- Portal: Stormwind
		CreateItem(63206),		-- Wrap of Unity
		CreateItem(63352),		-- Shroud of Cooperation
		CreateItem(65360),		-- Cloak of Coordination
	})

CreateDestination(
	"Suramar",
	{
		CreateItem(140324),																		-- Mobile Telemancy Beacon
		CreateConditionalConsumable(141014, AtContinent(ContinentIdBrokenIsles)),				-- Scroll of Town Portal: Sashj'tar
		CreateConditionalItem(140493, OnDayAtContinent(DayTuesday, ContinentIdBrokenIsles)),	-- Adept's Guide to Dimensional Rifting
	})
		
CreateDestination(
	"Tanaan Jungle",
	{
		CreateConditionalItem(128502, AtZone(MapIDTanaanJungle)),	-- Hunter's Seeking Crystal
		CreateConditionalItem(128503, AtZone(MapIDTanaanJungle)),	-- Master Hunter's Seeking Crystal
	})

CreateDestination(
	"Tanaris",
	{
		CreateItem(18986),		-- Ultrasafe Transporter - Gadgetzan
	})

CreateDestination(
	"Temple of Five Dawns",
	{
		CreateConditionalSpell(126892, function() return HaveUpgradedZen() end ),	-- Zen Pilgrimage
	})

CreateDestination(
	"Theramore",
	{
		CreateSpell(49359),		-- Teleport: Theramore
		CreateSpell(49360),		-- Portal: Theramore
	})

CreateDestination(
	"Timeless Isle",
	{
		CreateItem(103678),		-- Time-Lost Artifact
	})

CreateDestination(
	"Thunder Bluff",
	{
		CreateSpell(3566),		-- Teleport: Thunder Bluff
		CreateSpell(11420),		-- Portal: Thunder Bluff
	})

CreateDestination(
	"Tol Barad",
	{
		CreateItem(63378),		-- Hellscream's Reach Tabard
		CreateItem(63379),		-- Baradin's Wardens Tabard
		CreateSpell(88342),		-- Teleport: Tol Barad (Alliance)
		CreateSpell(88344),		-- Teleport: Tol Barad (Horde)
		CreateSpell(88345),		-- Portal: Tol Barad (Alliance)
		CreateSpell(88346),		-- Portal: Tol Barad (Horde)
	})

CreateDestination(
	"Undercity",
	{
		CreateSpell(3563),		-- Teleport: Undercity
		CreateSpell(11418),		-- Portal: Undercity
	})

CreateDestination(
	"Val'sharah",
	{
		CreateConditionalConsumable(141013, AtContinent(ContinentIdBrokenIsles)),			-- Scroll of Town Portal: Shala'nir
		CreateConditionalConsumable(141015, AtContinent(ContinentIdBrokenIsles)),			-- Scroll of Town Portal: Kal'delar	
		CreateConditionalItem(140493, OnDayAtContinent(DayMonday, ContinentIdBrokenIsles)),	-- Adept's Guide to Dimensional Rifting
	})

-- I don't know why there are so many of these, not sure which is right but it's now safe to
-- list them all.
CreateDestination(
	"Vale of Eternal Blossoms",
	{
		CreateSpell(132621),	-- Teleport: Vale of Eternal Blossoms
		CreateSpell(132627),	-- Teleport: Vale of Eternal Blossoms
		CreateSpell(132620),	-- Portal: Vale of Eternal Blossoms
		CreateSpell(132622),	-- Portal: Vale of Eternal Blossoms
		CreateSpell(132624),	-- Portal: Vale of Eternal Blossoms
		CreateSpell(132626),	-- Portal: Vale of Eternal Blossoms
	})

CreateDestination(
	"Winterspring",
	{
		CreateItem(18984),		-- Dimensional Ripper - Everlook
	})

CreateDestination(
	"Zuldazar",
	{
		CreateConsumable(157542),	-- Portal Scroll of Specificity
		CreateConsumable(160218),	-- Portal Scroll of Specificity
	})