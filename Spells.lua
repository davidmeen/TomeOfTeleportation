
local MapIDAlteracValley = 91
local MapIDAlteracValleyKorrak = 1537
local MapIDIsleOfThunder = 504
local MapIDDalaran = 125
local MapIDTanaanJungle = 534
local MapIDAzsuna = 627
local MapIDDalaranLegion = 1014
local MapIDAntoranWastes = 885
local MapIDAlterac = 943
local MapIDMaw = 1543
local MapIDKorthia = 1961
local MapIDMechagon = 1462
local MapIDGilneas = 202

local ContinentIdOutland = 101
local ContinentIdPandaria = 424
local ContinentIdDraenor = 946
local ContinentIdBrokenIsles = 619
local ContinentIdArgus = 905
local ContinentIdZandalar = 875
local ContinentIdKulTiras = 876
local ContinentIdNazjatar = 1355

local function AtZone(requiredZone)
	return function()
		if TeleporterGetOption("showInWrongZone") then
			return true
		end
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

local function AllowWhistle()
	--return AtContinent(ContinentIdBrokenIsles)() or AtContinent(ContinentIdArgus)() or AtContinent(ContinentIdKulTiras)() or AtContinent(ContinentIdZandalar)() or AtZone(MapIdAlterac)
	-- This is getting complicated - until I find a better way, always allow it.
	return true
end

local function InBFAZone()
	return AtContinent(ContinentIdKulTiras)() or AtContinent(ContinentIdZandalar)()
end

local function IsInAlteracValley()
	return AtZone(MapIDAlteracValley)() or AtZone(MapIDAlteracValleyKorrak)()
end

local function IsClass(requiredClass)
	return function()
		local _, playerClass = UnitClass("player")
		return playerClass == requiredClass
	end
end

local function IsRace(requiredRace)
	return function()
		local _, playerRace = UnitRace("player")
		return playerRace == requiredRace
	end
end

local function IsDraenei()
	return IsRace("Draenei")() or IsRace("LightforgedDraenei")()
end

local function HaveUpgradedZen()
	return C_QuestLog.IsQuestFlaggedCompleted(40236)
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
	if zone then
		for i, spell in ipairs(spells) do
			if TeleporterIsUnsupportedItem(spell) ~= 1 then
				spell:SetZone(zone)
				tinsert(TeleporterDefaultSpells, spell)
			end
		end
	end
end

local function PrintZoneIndex(name)
	for i = 1, 10000 do
		local info = C_Map.GetMapInfo(i)
		if info and info.name == name then
			print(name .. " should be zone " .. i)
			return
		end
	end
	print("Unknown zone " .. name)
end

local function LocZone(name, mapID)
	if mapID == 0 then
		PrintZoneIndex(name)
		return name
	else
		local mapInfo =	C_Map.GetMapInfo(mapID)
		if not mapInfo then
			--PrintZoneIndex(name)
			return name
		end
		local locName = mapInfo.name
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

local function CreatePortalSpell(spell)
	return TeleporterCreateConditionalSpell(spell,
		function()
			return TeleporterGetOption("showInWrongZone") or IsInGroup()
		end)
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
		CreateItem(162973),				-- Greatfather Winter's Hearthstone
		CreateItem(163045),				-- Headless Horseman's Hearthstone
		CreateItem(166747),				-- Brewfest Reveler's Hearthstone
		CreateItem(166746),				-- Fire Eater's Hearthstone
		CreateItem(165802),				-- Noble Gardener's Hearthstone
		CreateItem(168907),				-- Holographic Digitalization Hearthstone
		CreateItem(165669),				-- Lunar Elder's Hearthstone
		CreateItem(165670),				-- Peddlefeet's Lovely Hearthstone
		CreateItem(172179),				-- Eternal Traveler's Hearthstone
		-- I don't know how to check if a covenant hearthstone can be used. To work
		-- around this, only make them available for other covenants when not using
		-- the random hearthstone option.
		CreateConditionalItem(180290, TeleporterCanUseCovenantHearthstone(3)),	-- Night Fae Hearthstone
		CreateConditionalItem(182773, TeleporterCanUseCovenantHearthstone(4)),	-- Necrolord Hearthstone
		CreateConditionalItem(183716, TeleporterCanUseCovenantHearthstone(2)),	-- Venthyr Sinstone
		CreateConditionalItem(184353, TeleporterCanUseCovenantHearthstone(1)),	-- Kyrian Hearthstone
		CreateItem(188952),				-- Dominated Hearthstone
		CreateItem(190196),				-- Enlightened Hearthstone
		CreateItem(190237),				-- Broker Translocation Matrix
		CreateItem(193588),				-- Timewalker's Hearthstone
		CreateItem(200630),				-- Ohn'ir Windsage's Hearthstone
		CreateItem(206195),				-- Path of the Naaru
		CreateItem(208704),				-- Deepdweller's Earthen Hearthstone
		CreateItem(209035),				-- Hearthstone of the Flame
		CreateItem(212337),				-- Stone of the Hearth
		CreateConditionalItem(210455, IsDraenei),	-- Draenic Hologem
	})

-- Any hearthstones that shouldn't be randomised.
CreateDestination(
	TeleporterRecallString,
	{
		CreateSpell(556),				-- Astral Recall (separate cooldown)
		CreateItem(169064),				-- Mountebank's Colorful Cloak (needs to be equipped)
	})

CreateDestination(
	TeleporterFlightString,
	{
		CreateConditionalItem(141605, AllowWhistle), 	-- Flight Master's Whistle
		CreateConditionalItem(168862, AllowWhistle), 	-- G.E.A.R. Tracking Beacon
	})

CreateDestination(
	LocZone("Alterac Valley", 91),
	{
		CreateConditionalItem(17690, IsInAlteracValley ),	-- Frostwolf Insignia Rank 1
		CreateConditionalItem(17905, IsInAlteracValley ),	-- Frostwolf Insignia Rank 2
		CreateConditionalItem(17906, IsInAlteracValley ),	-- Frostwolf Insignia Rank 3
		CreateConditionalItem(17907, IsInAlteracValley ),	-- Frostwolf Insignia Rank 4
		CreateConditionalItem(17908, IsInAlteracValley ),	-- Frostwolf Insignia Rank 5
		CreateConditionalItem(17909, IsInAlteracValley ),	-- Frostwolf Insignia Rank 6
		CreateConditionalItem(17691, IsInAlteracValley ),	-- Stormpike Insignia Rank 1
		CreateConditionalItem(17900, IsInAlteracValley ),	-- Stormpike Insignia Rank 2
		CreateConditionalItem(17901, IsInAlteracValley ),	-- Stormpike Insignia Rank 3
		CreateConditionalItem(17902, IsInAlteracValley ),	-- Stormpike Insignia Rank 4
		CreateConditionalItem(17903, IsInAlteracValley ),	-- Stormpike Insignia Rank 5
		CreateConditionalItem(17904, IsInAlteracValley ),	-- Stormpike Insignia Rank 6
		CreateConditionalItem(18149, IsInAlteracValley ), -- Rune of Recall6
		CreateConditionalItem(18150, IsInAlteracValley ), -- Rune of Recall6
	})

CreateDestination(
	LocZone("Antoran Wastes", 885),
	{
		CreateConditionalItem(153226, AtZone(MapIDAntoranWastes))	-- Observer's Locus Resonator
	})

CreateDestination(
	LocZone("Ardenweald", 1565),
	{
		CreateConsumable(184503),	-- Attendant's Pocket Portal: Ardenweald
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
		CreatePortalSpell(176246),		-- Portal: Stormshield
		CreateSpell(176248),			-- Teleport: Stormshield
		CreatePortalSpell(176244),		-- Portal: Warspear
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
	LocZone("Badlands",	15),
	{
		CreateChallengeSpell(393222, 2355),	-- Path of the Watcher's Legacy	 	Uldaman: Legacy of Tyr
	})

CreateDestination(
	LocZone("Bastion", 1533),
	{
		CreateConsumable(184500),	-- Attendant's Pocket Portal: Bastion
	})


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
		CreateChallengeSpell(169771, 900)	-- Teleport: Blackrock Foundry			Blackrock Foundry
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
		CreatePortalSpell(281400),		-- Portal: Boralus
		CreateItem(166560),				-- Captain's Signet of Command
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
	"Camp",
	{
		CreateSpell(312372),
	})

CreateDestination(
	LocZone("Dalaran", 41) .. " (Legion)",
	{
		CreatePortalSpell(224871),	-- Portal: Dalaran - Broken Isles
		CreateSpell(224869),		-- Teleport: Dalaran - Broken Isles
		CreateItem(138448),			-- Emblem of Margoss
		CreateItem(139599),			-- Empowered Ring of the Kirin Tor
		CreateItem(140192),			-- Dalaran Hearthstone
		CreateConditionalItem(43824, AtZone(MapIDDalaranLegion)),	-- The Schools of Arcane Magic - Mastery
	})

CreateDestination(
	LocZone("Dalaran", 41) .. " (WotLK)",
	{
		CreateSpell(53140),			-- Teleport: Dalaran
		CreatePortalSpell(53142),	-- Portal: Dalaran
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
		CreatePortalSpell(120146),	-- Ancient Portal: Dalaran
	})

CreateDestination(
	LocZone("Darnassus", 89),
	{
		CreateSpell(3565),			-- Teleport: Darnassus
		CreatePortalSpell(11419),	-- Portal: Darnassus
	})

CreateDestination(
	LocZone("Dazar'alor", 1163),
	{
		CreateSpell(281404),		-- Teleport: Dazar'alor
		CreatePortalSpell(281402),	-- Portal: Dazar'alor
		CreateItem(166559),			-- Commander's Signet of Battle
		CreateConditionalItem(165581, AtZone(1163)), -- Crest of Pa'ku
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
	LocZone("Drustvar", 896),
	{
		CreateChallengeSpell(424167, 1706)	-- Path of Heart's Bane				Waycrest Manor
	})

CreateDestination(
	"Draenor Dungeons",
	{
		CreateChallengeSpell(159897, 1975),	-- Path of the Vigilant				Auchindoun
		CreateChallengeSpell(159895, 1005),	-- Path of the Bloodmaul			Bloodmaul Slag Mines
		CreateChallengeSpell(159901, 1003),	-- Path of the Verdant				The Everbloom
		CreateChallengeSpell(159900, 1006),	-- Path of the Dark Rail			Grimrail Depot
		CreateChallengeSpell(159896, 1007),	-- Path of the Iron Prow			Iron Docks
		CreateChallengeSpell(159899, 1009),	-- Path of the Crescent Moon		Shadowmoon Burial Grounds
		CreateChallengeSpell(159898, 1010),	-- Path of the Skies				Skyreach
		CreateChallengeSpell(159902, 1004),	-- Path of the Burning Mountain		Upper Blackrock Spire
	})

CreateDestination(
	LocZone("Dragon Isles", 1978),
	{
		CreateItem(198156), -- Wyrmhole Generator
	})

CreateDestination(
	"Dragon Isles Dungeons",
	{
		CreateChallengeSpell(393279, 2335),	-- Path of Arcane Secrets			The Azure Vault
		CreateChallengeSpell(393273, 2367),	-- Path of the Draconic Diploma		Algeth'ar Academy
		CreateChallengeSpell(393262, 2378),	-- Path of the Windswept Plains		The Nokhud Offensive
		CreateChallengeSpell(393256, 2376),	-- Path of the Clutch Defender		Ruby Life Pools
		CreateChallengeSpell(393276, 2359),	-- Path of the Obsidian Hoard		Neltharus
		CreateChallengeSpell(393283, 2382),	-- Path of the Titanic Reservoir	Halls of Infusion
		CreateChallengeSpell(393267, 2380),	-- Path of the Rotting Woods		Brackenhide Hollow
	})

CreateDestination(
	"Dragon Isles Raids",
	{
		CreateChallengeSpell(432257, 2405),	-- Path of the Bitter Legacy		Aberrus
		CreateChallengeSpell(432254, 2388),	-- Path of the Primal Prison		Vault of the Incarnates
		CreateChallengeSpell(432258, 2502),	-- Path of the Scorching Dream		Amirdrassil
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
		CreatePortalSpell(32266),	-- Portal: Exodar
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
	LocZone("Gilneas", 202),
	{
		CreateConditionalItem(211788, IsRace("Worgen")),	-- Gilneas City
	})

CreateDestination(
	LocZone("Hall of the Guardian", 734),
	{
		CreateSpell(193759), 	-- Teleport: Hall of the Guardian
	})

-- TODO: Include destination in name
CreateDestination(
	"Hearth (Necrolord)",
	{
		CreateSpell(324547)		-- Hearth Kidneystone
	})

CreateDestination(
	LocZone("Highmountain", 869),
	{
		CreateConditionalConsumable(141017, AtContinent(ContinentIdBrokenIsles)),				-- Scroll of Town Portal: Lian'tril
		CreateConditionalItem(140493, OnDayAtContinent(DayThursday, ContinentIdBrokenIsles)),	-- Adept's Guide to Dimensional Rifting
		CreateChallengeSpell(410078, 1207),	-- Path of the Earth-Warder			Neltharion's Lair
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
		CreatePortalSpell(11416)		-- Portal: Ironforge
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
		CreateChallengeSpell(373262, 175), -- Path of the Fallen Guardian		Karazhan
	})

CreateDestination(
	LocZone("Kul Tiras", 876),
	{
		CreateItem(168807)		-- Wormhole Generator: Kul Tiras
	})

CreateDestination(
	LocZone("Kun-Lai Summit", 379),
	{
		CreateConditionalSpell(126892, function() return not HaveUpgradedZen() end ),	-- Zen Pilgrimage
	})

CreateDestination(
	LocZone("Maldraxxus", 1536),
	{
		CreateItem(181163),			-- Scroll of Teleport: Theater of Pain
		CreateConsumable(184502),	-- Attendant's Pocket Portal: Maldraxxus
	})

CreateDestination(
	LocZone("Mechagon", 1490),
	{
		CreateConsumable(167075),									-- Ultrasafe Transporter: Mechagon
		CreateChallengeSpell(373274, 2006),							-- Path of the Scrappy Prince	Operation: Mechagon
		CreateConditionalConsumable(169114, AtZone(MapIDMechagon))	-- Personal Time Displacer
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
	LocZone("Nazmir", 863),
	{
		CreateChallengeSpell(410074, 1712),	-- Path of Festering Rot	The Underrot
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
	LocZone("Ohn'ahran Plains", 2023),
	{
		CreateConsumable(200613), -- Aylaag Windstone Fragment
	})

CreateDestination(
	LocZone("Orgrimmar", 85),
	{
		CreateSpell(3567),			-- Teleport: Orgrimmar
		CreatePortalSpell(11417),	-- Portal: Orgrimmar
		CreateItem(63207),			-- Wrap of Unity
		CreateItem(63353),			-- Shroud of Cooperation
		CreateItem(65274),			-- Cloak of Coordination
	})

CreateDestination(
	LocZone("Oribos", 1670),
	{
		CreateSpell(344587),		-- Teleport: Oribos
		CreatePortalSpell(344597),	-- Portal: Oribos
		CreateConsumable(184504),	-- Attendant's Pocket Portal: Oribos
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
		CreateConsumable(217930)												-- Nostwin's Voucher
	})

CreateDestination(
	"Pandaria Dungeons",
	{
		CreateChallengeSpell(131225, 471),	-- Path of the Setting Sun		Gate of the Setting Sun
		CreateChallengeSpell(131222, 519),	-- Path of the Mogu King		Mogu'shan Palace
		CreateChallengeSpell(131232, 472),	-- Path of the Necromancer		Scholomance
		CreateChallengeSpell(131206, 470),	-- Path of the Shado-Pan		Shado-Pan Monastery
		CreateChallengeSpell(131228, 554),	-- Path of the Black Ox			Siege of Niuzao
		CreateChallengeSpell(131205, 469),	-- Path of the Stout Brew		Stormstout Brewery
		CreateChallengeSpell(131204, 464),	-- Path of the Jade Serpent		Temple of the Jade Serpent
	})

CreateDestination(
	"Random",		-- No localization.
	{
		CreateSpell(147420),								-- One With Nature
		CreateItem(64457), 									-- The Last Relic of Argus
		CreateConditionalItem(136849, IsClass("DRUID")),	-- Nature's Beacon
		CreateItem(153004),									-- Unstable Portal Emitter
		CreateItem(189827),									-- Cartel Xy's Proof of Initiation
		CreateItem(192443),									-- Element-Infused Rocket Helmet
		CreateItem(193000),									-- Ring-Bound Hourglass
		CreateConditionalItem(163073, function() return AtContinent(ContinentIdKulTiras)() or AtContinent(ContinentIdZandalar)() or AtContinent(ContinentIdNazjatar)() end),	-- Conch of Wa'mundi
	})

CreateDestination(
	LocArea("Ravenholdt", 0),
	{
		CreateItem(139590),		-- Scroll of Teleport: Ravenholdt
	})

CreateDestination(
	LocZone("Revendreth", 1525),
	{
		CreateItem(184501),		-- 184501
	})

CreateDestination(
	LocZone("Scarlet Monastery", 302),
	{
		CreateChallengeSpell(131231, 473),	-- Path of the Scarlet Blade		Scarlet Halls
		CreateChallengeSpell(131229, 474),	-- Path of the Scarlet Mitre		Scarlet Monastery
	})

CreateDestination(
	"Shadowlands Dungeons",
	{
		CreateChallengeSpell(354462, 2123),	-- Path of the Courageous			The Necrotic Wake
		CreateChallengeSpell(354463, 2121),	-- Path of the Plagued				Plaguefall
		CreateChallengeSpell(354464, 2120),	-- Path of the Misty Forest			Mists of Tirna Scithe
		CreateChallengeSpell(354465, 2119),	-- Path of the Sinful Soul			Halls of Atonement
		CreateChallengeSpell(354466, 2122),	-- Path of the Ascendant			Spires of Ascension
		CreateChallengeSpell(354467, 2124),	-- Path of the Undefeated			Theater of Pain
		CreateChallengeSpell(354468, 2118),	-- Path of the Scheming Loa			De Other Side
		CreateChallengeSpell(354469, 2117),	-- Path of the Stone Warden			Sanguine Depths
		CreateChallengeSpell(367416, 2225),	-- Path of the Streetwise Merchant	Tazavesh, the Veiled Market
		CreateChallengeSpell(373190, 2093),	-- Path of the Sire					Castle Nathria
		CreateChallengeSpell(373191, 2228),	-- Path of the Tormented Soul		Sanctum of Domination
		CreateChallengeSpell(373192, 2290),	-- Path of the First Ones			Sepulcher of the First Ones
	})

CreateDestination(
	LocZone("Shattrath City", 111),
	{
		CreateSpell(33690),			-- Teleport: Shattrath (Alliance)
		CreatePortalSpell(33691),	-- Portal: Shattrath (Alliance)
		CreateSpell(35715),			-- Teleport: Shattrath (Horde)
		CreatePortalSpell(35717),	-- Portal: Shattrath (Horde)
	})

CreateDestination(
	LocArea("Shipyard", 6668),
	{
		CreateItem(128353),		-- Admiral's Compass
	})

CreateDestination(
	LocZone("Silvermoon City", 110),
	{
		CreateSpell(32272),			-- Teleport: Silvermoon
		CreatePortalSpell(32267),	-- Portal: Silvermoon
	})

CreateDestination(
	LocArea("Stonard", 75),
	{
		CreateSpell(49358),			-- Teleport: Stonard
		CreatePortalSpell(49361),	-- Portal: Stonard
	})

CreateDestination(
	LocZone("Stormheim", 634),
	{
		CreateConditionalItem(140493, OnDayAtContinent(DayFriday, ContinentIdBrokenIsles)),	-- Adept's Guide to Dimensional Rifting
		CreateChallengeSpell(393764, 1194),	-- Path of Proven Worth		Halls of Valor
	})


	CreateDestination(
		LocZone("Stormsong Valley", 942),
		{
			CreateItem(202046)		-- Lucky Tortollan Charm
		})

CreateDestination(
	LocZone("Stormwind City", 84),
	{
		CreateSpell(3561),			-- Teleport: Stormwind
		CreatePortalSpell(10059),	-- Portal: Stormwind
		CreateItem(63206),			-- Wrap of Unity
		CreateItem(63352),			-- Shroud of Cooperation
		CreateItem(65360),			-- Cloak of Coordination
	})

CreateDestination(
	LocZone("Suramar", 680),
	{
		CreateItem(140324),																		-- Mobile Telemancy Beacon
		CreateConditionalConsumable(141014, AtContinent(ContinentIdBrokenIsles)),				-- Scroll of Town Portal: Sashj'tar
		CreateConditionalItem(140493, OnDayAtContinent(DayTuesday, ContinentIdBrokenIsles)),	-- Adept's Guide to Dimensional Rifting
		CreateChallengeSpell(393766, 1319),	-- Path of the Grand Magistrix		Court of Stars
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
	LocZone("Thaldraszus", 2025),
	{
		CreateChallengeSpell(424197, 2430)	-- Path of Twisted Time		Dawn of the Infinite
	})

CreateDestination(
	LocZone("The Forbidden Reach", 2151),
	{
		CreateConditionalConsumable(204481, AtZone(2151)),		-- Morqut Hearth Totem
		CreateConsumable(204802),								-- Scroll of Teleport: Zskera Vaults
	})

CreateDestination(
	LocZone("The Maw", 1543),
	{
		CreateConditionalConsumable(180817, function() return TeleporterGetOption("showInWrongZone") or (AtZone(MapIDMaw)() and not AtZone(MapIDKorthia)()) end),	-- Cypher of Relocation
	})

CreateDestination(
	LocZone("The Shadowlands", 1550),
	{
		CreateItem(172924),		-- Wormhole Generator: Shadowlands
	})

CreateDestination(
	LocArea("Theramore Isle", 513),
	{
		CreateSpell(49359),			-- Teleport: Theramore
		CreatePortalSpell(49360),	-- Portal: Theramore
	})

CreateDestination(
	LocZone("Timeless Isle", 554),
	{
		CreateItem(103678),		-- Time-Lost Artifact
		CreateItem(219222),		-- Time-Lost Artifact
	})

CreateDestination(
	LocZone("Thunder Bluff", 88),
	{
		CreateSpell(3566),			-- Teleport: Thunder Bluff
		CreatePortalSpell(11420),	-- Portal: Thunder Bluff
	})

CreateDestination(
	LocZone("Tiragarde Sound", 8567),
	{
		CreateChallengeSpell(410071, 1704)	-- Path of the Freebooter		Freehold
	})

CreateDestination(
	LocZone("Tirisfal Glades", 18),
	{
		CreateItem(173523),		-- Tirisfal Camp Scroll
	})

CreateDestination(
	LocZone("Tol Barad", 773),
	{
		CreateItem(63378),			-- Hellscream's Reach Tabard
		CreateItem(63379),			-- Baradin's Wardens Tabard
		CreateSpell(88342),			-- Teleport: Tol Barad (Alliance)
		CreateSpell(88344),			-- Teleport: Tol Barad (Horde)
		CreatePortalSpell(88345),	-- Portal: Tol Barad (Alliance)
		CreatePortalSpell(88346),	-- Portal: Tol Barad (Horde)
	})

CreateDestination(
	LocZone("Uldum", 5034),
	{
		CreateChallengeSpell(410080, 319)	-- Path of Wind's Domain		Vortex Pinnacle
	})

CreateDestination(
	LocZone("Undercity", 90),
	{
		CreateSpell(3563),			-- Teleport: Undercity
		CreatePortalSpell(11418),	-- Portal: Undercity
	})

CreateDestination(
	LocZone("Valdrakken", 2112),
	{
		CreateSpell(395277),		-- Teleport: Valdrakken
		CreatePortalSpell(395289),	-- Portal: Valdrakken
	})

CreateDestination(
	LocZone("Val'sharah", 641),
	{
		CreateConditionalConsumable(141013, AtContinent(ContinentIdBrokenIsles)),			-- Scroll of Town Portal: Shala'nir
		CreateConditionalConsumable(141015, AtContinent(ContinentIdBrokenIsles)),			-- Scroll of Town Portal: Kal'delar
		CreateConditionalItem(140493, OnDayAtContinent(DayMonday, ContinentIdBrokenIsles)),	-- Adept's Guide to Dimensional Rifting
		CreateChallengeSpell(424163, 1202),	-- Path of the Nightmare Lord		Darkheart Thicket
		CreateChallengeSpell(424153, 1205),	-- Path of Ancient Horrors			Black Rook Hold
	})

-- I don't know why there are so many of these, not sure which is right but it's now safe to
-- list them all.
CreateDestination(
	LocZone("Vale of Eternal Blossoms", 390),
	{
		CreateSpell(132621),		-- Teleport: Vale of Eternal Blossoms
		CreateSpell(132627),		-- Teleport: Vale of Eternal Blossoms
		CreatePortalSpell(132620),	-- Portal: Vale of Eternal Blossoms
		CreatePortalSpell(132622),	-- Portal: Vale of Eternal Blossoms
		CreatePortalSpell(132624),	-- Portal: Vale of Eternal Blossoms
		CreatePortalSpell(132626),	-- Portal: Vale of Eternal Blossoms
	})

CreateDestination(
	LocZone("Vashj'ir", 203),
	{
		CreateChallengeSpell(424142, 324)	-- Path of the Tidehunter			Throne of the Tides
	})

CreateDestination(
	LocZone("Winterspring", 83),
	{
		CreateItem(18984),		-- Dimensional Ripper - Everlook
	})

CreateDestination(
	LocZone("Zandalar", 875),
	{
		CreateItem(168808)		-- Wormhole Generator: Zandalar
	})

CreateDestination(
	LocZone("Zaralek Cavern", 2133),
	{
		CreateConditionalItem(205255, AtZone(2133))		-- Niffen Diggin' Mitts
	})

CreateDestination(
	LocZone("Zuldazar", 862),
	{
		CreateConsumable(157542),	-- Portal Scroll of Specificity
		CreateConsumable(160218),	-- Portal Scroll of Specificity
		CreateChallengeSpell(424187, 2107),	-- Path of the Golden Tomb		Atal'Dazar
	})
