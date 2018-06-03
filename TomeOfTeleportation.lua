-- Tome of Teleportation by Remeen.

-- TODO:
-- More Battle for Azeroth items
-- Improve speed

-- Low priority:
-- Proper options dialog

local AddonName = "TomeOfTeleportation"
local AddonTitle = "Tome of Teleportation"
-- Special case strings start with number to force them to be sorted first.
local HearthString = "0 Hearth"
local RecallString = "1 Astral Recall"
local FlightString = "2 Flight Master"

local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local icon = LibStub("LibDBIcon-1.0")
local dataobj = ldb:NewDataObject("TomeTele", {
	label = "TomeOfTeleportation", 
	type = "data source", 
	icon = "Interface\\Icons\\Spell_Arcane_TeleportDalaran", 
	text = "Teleport"
})

local TeleporterParentFrame = nil
local CastSpell = nil
local ItemSlot = nil
local OldItems = {}
local RemoveItem = {}
local ButtonSettings = {}
local IsVisible = false
local NeedUpdate = false
local OpenTime = 0
local ShouldNotBeEquiped = {}
local ShouldBeEquiped = {}
local EquipTime = 0
local CustomizeSpells = false
local RemoveIconOffset = 0
local ShowIconOffset = 0
local SortUpIconOffset = 0
local SortDownIconOffset = 0
local AddItemButton = nil
local AddSpellButton = nil

_G["BINDING_HEADER_TOMEOFTELEPORTATION"] = "Tome of Teleportation"

local InvTypeToSlot = 
{	
	["INVTYPE_HEAD"] = 1,
	["INVTYPE_NECK"] = 2,
	["INVTYPE_SHOULDER"] = 3,
	["INVTYPE_BODY"] = 4,
	["INVTYPE_CHEST"] = 5,
	["INVTYPE_ROBE"] = 5,
	["INVTYPE_WAIST"] = 6,
	["INVTYPE_LEGS"] = 7,
	["INVTYPE_FEET"] = 8,
	["INVTYPE_WRIST"] = 9,
	["INVTYPE_HAND"] = 10,
	["INVTYPE_FINGER"] = 11,
	["INVTYPE_TRINKET"] = 13,
	["INVTYPE_CLOAK"] = 15,
	["INVTYPE_2HWEAPON"] = 16,
	["INVTYPE_WEAPONMAINHAND"] = 16,
	["INVTYPE_TABARD"] = 19
}

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

local ST_Item = 1
local ST_Spell = 2
local ST_Challenge = 3

-- TODO: Always look up by name, not index.
local SpellIdIndex = 1
local SpellTypeIndex = 2
local SpellZoneIndex = 3
local SpellConditionIndex = 4
local SpellConsumableIndex = 5
local SpellNameIndex = 6

local SortByDestination = 1
local SortByType = 2
local SortCustom = 3

local TitleFrameBG

local DefaultOptions = 
{
	["theme"] = "Default",
	["scale"] = 1, 
	["buttonHeight"] = 26,
	["buttonWidth"] = 128,
	["labelHeight"] = 16,
	["maximumHeight"] = 200,
	["fontHeight"] = 10,
	["buttonInset"] = 6,
	["showHelp"] = false,
	["background"] = "Interface/AchievementFrame/UI-Achievement-Parchment-Horizontal",
	["edge"] = "Interface/DialogFrame/UI-DialogBox-Border",
	["backgroundR"] = 1,
	["backgroundG"] = 1,
	["backgroundB"] = 1,
	["backgroundA"] = 0.5,
	["frameEdgeSize"] = 16,
	["showTitle"] = true,
	["titleBackground"] = "Interface/DialogFrame/UI-DialogBox-Header",
	["titleFont"] = "GameFontNormalSmall",
	["titleWidth"] = 280,
	["titleHeight"] = 50,
	["titleOffset"] = 12,
	["buttonFont"] = GameFontNormal:GetFont(),
	["buttonBackground"] = "Interface/Tooltips/UI-Tooltip-Background",
	["buttonEdge"] = "Interface/Tooltips/UI-Tooltip-Border",
	["buttonEdgeSize"] = 16,
	["buttonTileSize"] = 16,
	["readyColourR"] = 0,
	["readyColourG"] = 0.7,
	["readyColourB"] = 0,
	["unequipedColourR"] = 1,
	["unequipedColourG"] = 0,
	["unequipedColourB"] = 0,
	["cooldownColourR"] = 1,
	["cooldownColourG"] = 0.7,
	["cooldownColourB"] = 0,
	["disabledColourR"] = 0.5,
	["disabledColourG"] = 0.5,
	["disabledColourB"] = 0.5,
	["QuickMenuSize"] = 50,
	["sortUpIcon"] = "Interface/Icons/misc_arrowlup",
	["sortDownIcon"] = "Interface/Icons/misc_arrowdown",
	["showButtonIcon"] = "Interface/Icons/levelupicon-lfd",
	["removeButtonIcon"] = "Interface/Icons/INV_Misc_Bone_Skull_03"
}

-- Themes. For now there aren't many of these. Message me on curse.com
-- if you create a theme that you'd like to be included. Also let me know
-- if you need to change a parameter that isn't exposed.
-- Note that every value is enclosed in {}.
local DefaultTheme = 
{
}

local FlatTheme = 
{
	["background"] = {"Interface/DialogFrame/UI-DialogBox-Gold-Background"},
	["edge"] = {nil},
	["buttonEdge"] = {nil},
	["titleBackground"] = {"Interface/DialogFrame/UI-DialogBox-Gold-Background"},
	["backgroundA"] = {1},
	["showTitle"] = {false},
	["titleHeight"] = {20},
	["titleWidth"] = {150},
	["titleOffset"] = {5},
}

local Themes = 
{
	["Default"] = DefaultTheme,
	["Flat"] = FlatTheme	
}

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

local function CreateSpell(id, dest)
	local spell = {}
	spell[SpellIdIndex] = id
	spell[SpellTypeIndex] = ST_Spell
	spell[SpellZoneIndex] = dest
	spell.spellId = id
	spell.spellType = ST_Spell
	spell.zone = dest
	return spell
end

local function CreateItem(id, dest)
	local spell = {}
	spell[SpellIdIndex] = id
	spell[SpellTypeIndex] = ST_Item
	spell[SpellZoneIndex] = dest	
	spell.spellId = id
	spell.spellType = ST_Item
	spell.zone = dest
	return spell
end

local function CreateChallengeSpell(id, dest)
	local spell = {}
	spell[SpellIdIndex] = id
	spell[SpellTypeIndex] = ST_Challenge
	spell[SpellZoneIndex] = dest
	spell.spellId = id
	spell.spellType = ST_Challenge
	spell.zone = dest
	return spell
end

local function CreateConditionalItem(id, condition, dest)
	local spell = {}
	spell[SpellIdIndex] = id
	spell[SpellTypeIndex] = ST_Item
	spell[SpellConditionIndex] = condition
	spell[SpellZoneIndex] = dest	
	spell.spellId = id
	spell.spellType = ST_Item
	spell.condition = condition
	spell.zone = dest
	return spell
end

local function CreateConditionalSpell(id, condition, dest)
	local spell = {}
	spell[SpellIdIndex] = id
	spell[SpellTypeIndex] = ST_Spell
	spell[SpellConditionIndex] = condition
	spell[SpellZoneIndex] = dest	
	spell.spellId = id
	spell.spellType = ST_Spell
	spell.condition = condition
	spell.zone = dest
	return spell
end

local function CreateConditionalConsumable(id, condition, dest)
	local spell = {}
	spell[SpellIdIndex] = id
	spell[SpellTypeIndex] = ST_Item
	spell[SpellConditionIndex] = condition
	spell[SpellZoneIndex] = dest	
	spell[SpellConsumableIndex] = true
	spell.spellId = id
	spell.spellType = ST_Item
	spell.condition = condition
	spell.zone = dest
	spell.consumable = true
	return spell
end

local function CreateConsumable(id, dest)
	local spell = {}
	spell[SpellIdIndex] = id
	spell[SpellTypeIndex] = ST_Item
	spell[SpellZoneIndex] = dest
	spell[SpellConsumableIndex] = true
	spell.spellId = id
	spell.spellType = ST_Spell
	spell.zone = dest
	spell.consumable = true
	return spell
end

-- { id, isItem, destination, condition, consumable, spellName }
-- It probably won't work if a single player has two different items
-- with the same name in their inventory, but I don't think that's possible.
-- spellName will be filled in when the addon loads.
local TeleporterDefaultSpells = 
{	
}

local function CreateDestination(zone, spells)
	for i, spell in ipairs(spells) do
		spell.zone = zone
		spell[SpellZoneIndex] = zone
		tinsert(TeleporterDefaultSpells, spell)
	end
end

---------------------------------------------------------------
-- Start spells
CreateDestination(
	HearthString,
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
	RecallString,
	{
		CreateSpell(556)				-- Astral Recall
	})

CreateDestination(
	FlightString,
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
--
--	{ 50977, ST_Spell, "Ebon Hold" },		-- Death Gate
--	
--	{ 193753, ST_Spell, "Emerald Dreamway" }, -- Dreamwalk
--	
--	{ 110560, ST_Item, "Garrison" },		-- Garrison Hearthstone
--	
--	{ 32271, ST_Spell, "Exodar" },			-- Teleport: Exodar
--	{ 32266, ST_Spell, "Exodar" },			-- Portal: Exodar
--	
--	{ 201891, ST_Spell, "Fishing Pool", AtContinent(ContinentIdBrokenIsles) },	-- Undercurrent
--	
--	{ 193759, ST_Spell, "Hall of the Guardian" }, -- Teleport: Hall of the Guardian
--	
--	{ 141017, ST_Item, "Highmountain", AtContinent(ContinentIdBrokenIsles), true },	-- Scroll of Town Portal: Lian'tril
--	{ 140493, ST_Item, "Highmountain", OnDayAtContinent(DayThursday, ContinentIdBrokenIsles) },	-- Adept's Guide to Dimensional Rifting
--	
--	{ 46874, ST_Item, "Icecrown" },		-- Argent Crusader's Tabard
--	
--	{ 3562, ST_Spell, "Ironforge" },		-- Teleport: Ironforge
--	{ 11416, ST_Spell, "Ironforge" },		-- Portal: Ironforge
--	
--	{ 95567, ST_Item, "Isle of Thunder", AtZone(MapIDIsleOfThunder ) },	-- Kirin Tor Beacon
--	{ 95568, ST_Item, "Isle of Thunder", AtZone(MapIDIsleOfThunder ) },	-- Sunreaver Beacon
--
--	{ 118663, ST_Item, "Karabor" },		-- Relic of Karabor
--	
--	{ 22589, ST_Item, "Karazhan" },		-- Atiesh, Greatstaff of the Guardian
--	{ 22630, ST_Item, "Karazhan" },		-- Atiesh, Greatstaff of the Guardian
--	{ 22631, ST_Item, "Karazhan" },		-- Atiesh, Greatstaff of the Guardian
--	{ 22632, ST_Item, "Karazhan" },		-- Atiesh, Greatstaff of the Guardian
--	{ 142469, ST_Item, "Karazhan" }, 	-- Violet Seal of the Grand Magus
--	
--	{ 126892, ST_Spell, "Kun Lai Summit", function() return not HaveUpgradedZen() end },	-- Zen Pilgrimage
--	
--	{ 18960, ST_Spell, "Moonglade" },		-- Teleport: Moonglade
--	{ 21711, ST_Item, "Moonglade" },		-- Lunar Festival Invitation
--
--	{ 30542, ST_Item, "Netherstorm" },		-- Dimensional Ripper - Area 52
--
--	{ 48933, ST_Item, "Northrend" },		-- Wormhole Generator: Northrend
--
--	{ 3567, ST_Spell, "Orgrimmar" },		-- Teleport: Orgrimmar
--	{ 11417, ST_Spell, "Orgrimmar" },		-- Portal: Orgrimmar
--	{ 63207, ST_Item, "Orgrimmar" },		-- Wrap of Unity
--	{ 63353, ST_Item, "Orgrimmar" },		-- Shroud of Cooperation
--	{ 65274, ST_Item, "Orgrimmar" },		-- Cloak of Coordination
--	
--	{ 129929, ST_Item, "Outland", AtContinent(ContinentIdDraenor) },	-- Ever-Shifting Mirror
--	
--	{ 87548, ST_Item, "Pandaria", AtContinent(ContinentIdPandaria), true }, -- Lorewalker's Lodestone
--	{ 87215, ST_Item, "Pandaria" },			-- Wormhole Generator: Pandaria
--	
--	{ 131225, ST_Challenge, "Pandaria Dungeons" },	-- Path of the Setting Sun	
--	{ 131222, ST_Challenge, "Pandaria Dungeons" },	-- Path of the Mogu King
--	{ 131231, ST_Challenge, "Pandaria Dungeons" },	-- Path of the Scarlet Blade	
--	{ 131229, ST_Challenge, "Pandaria Dungeons" },	-- Path of the Scarlet Mitre	
--	{ 131232, ST_Challenge, "Pandaria Dungeons" },	-- Path of the Necromancer
--	{ 131206, ST_Challenge, "Pandaria Dungeons" },	-- Path of the Shado-Pan
--	{ 131228, ST_Challenge, "Pandaria Dungeons" },	-- Path of the Black Ox
--	{ 131205, ST_Challenge, "Pandaria Dungeons" },	-- Path of the Stout Brew
--	{ 131204, ST_Challenge, "Pandaria Dungeons" },	-- Path of the Jade Serpent
--	
--	{ 147420, ST_Spell, "Random" },			-- One With Nature
--	{ 64457, ST_Item, "Random" }, 			-- The Last Relic of Argus
--	{ 136849, ST_Item, "Random", IsClass("DRUID") },			-- Nature's Beacon
--	
--	{ 139590, ST_Item, "Ravenholdt" },		-- Scroll of Teleport: Ravenholdt
--		
--	{ 33690, ST_Spell, "Shattrath" },		-- Teleport: Shattrath (Alliance)
--	{ 33691, ST_Spell, "Shattrath" },		-- Portal: Shattrath (Alliance)
--	{ 35715, ST_Spell, "Shattrath" },		-- Teleport: Shattrath (Horde)
--	{ 35717, ST_Spell, "Shattrath" },		-- Portal: Shattrath (Horde)
--	
--	{ 128353, ST_Item, "Shipyard" },		-- Admiral's Compass
--	
--	{ 32272, ST_Spell, "Silvermoon" },		-- Teleport: Silvermoon
--	{ 32267, ST_Spell, "Silvermoon" },		-- Portal: Silvermoon
--	
--	{ 49358, ST_Spell, "Stonard" },		-- Teleport: Stonard
--	{ 49361, ST_Spell, "Stonard" },		-- Portal: Stonard
--	
--	{ 140493, ST_Item, "Stormheim", OnDayAtContinent(DayFriday, ContinentIdBrokenIsles) },	-- Adept's Guide to Dimensional Rifting
--	
--	{ 3561, ST_Spell, "Stormwind" },		-- Teleport: Stormwind
--	{ 10059, ST_Spell, "Stormwind" },		-- Portal: Stormwind
--	{ 63206, ST_Item, "Stormwind" },		-- Wrap of Unity
--	{ 63352, ST_Item, "Stormwind" },		-- Shroud of Cooperation
--	{ 65360, ST_Item, "Stormwind" },		-- Cloak of Coordination
--	
--	{ 140324, ST_Item, "Suramar" },			-- Mobile Telemancy Beacon
--	{ 141014, ST_Item, "Suramar", AtContinent(ContinentIdBrokenIsles), true },	-- Scroll of Town Portal: Sashj'tar
--	{ 140493, ST_Item, "Suramar", OnDayAtContinent(DayTuesday, ContinentIdBrokenIsles) },	-- Adept's Guide to Dimensional Rifting
--
--	{ 128502, ST_Item, "Tanaan Jungle", AtZone(MapIDTanaanJungle) },	-- Hunter's Seeking Crystal
--	{ 128503, ST_Item, "Tanaan Jungle", AtZone(MapIDTanaanJungle) },	-- Master Hunter's Seeking Crystal
--	
--	{ 18986, ST_Item, "Tanaris" },			-- Ultrasafe Transporter - Gadgetzan
--	
--	{ 126892, ST_Spell, "Temple of Five Dawns", function() return HaveUpgradedZen() end },	-- Zen Pilgrimage
--	
--	{ 49359, ST_Spell, "Theramore" },		-- Teleport: Theramore
--	{ 49360, ST_Spell, "Theramore" },		-- Portal: Theramore
--	
--	{ 103678, ST_Item, "Timeless Isle" },	-- Time-Lost Artifact
--
--	{ 3566, ST_Spell, "Thunder Bluff" },	-- Teleport: Thunder Bluff
--	{ 11420, ST_Spell, "Thunder Bluff" },	-- Portal: Thunder Bluff
--	
--	{ 63378, ST_Item, "Tol Barad" },		-- Hellscream's Reach Tabard
--	{ 63379, ST_Item, "Tol Barad" },		-- Baradin's Wardens Tabard
--	{ 88342, ST_Spell, "Tol Barad" },		-- Teleport: Tol Barad (Alliance)
--	{ 88344, ST_Spell, "Tol Barad" },		-- Teleport: Tol Barad (Horde)
--	{ 88345, ST_Spell, "Tol Barad" },		-- Portal: Tol Barad (Alliance)
--	{ 88346, ST_Spell, "Tol Barad" },		-- Portal: Tol Barad (Horde)
--	
--
--	{ 3563, ST_Spell, "Undercity" },		-- Teleport: Undercity
--	{ 11418, ST_Spell, "Undercity" },		-- Portal: Undercity
--	
--	{ 141013, ST_Item, "Val'sharah", AtContinent(ContinentIdBrokenIsles), true },	-- Scroll of Town Portal: Shala'nir
--	{ 141015, ST_Item, "Val'sharah", AtContinent(ContinentIdBrokenIsles), true },	-- Scroll of Town Portal: Kal'delar	
--	{ 140493, ST_Item, "Val'sharah", OnDayAtContinent(DayMonday, ContinentIdBrokenIsles) },	-- Adept's Guide to Dimensional Rifting
--	
--	-- I don't know why there are so many of these, not sure which is right but it's now safe to
--	-- list them all.
--	{ 132621, ST_Spell, "Vale of Eternal Blossoms" },		-- Teleport: Vale of Eternal Blossoms
--	{ 132627, ST_Spell, "Vale of Eternal Blossoms" },		-- Teleport: Vale of Eternal Blossoms
--	{ 132620, ST_Spell, "Vale of Eternal Blossoms" },		-- Portal: Vale of Eternal Blossoms
--	{ 132622, ST_Spell, "Vale of Eternal Blossoms" },		-- Portal: Vale of Eternal Blossoms
--	{ 132624, ST_Spell, "Vale of Eternal Blossoms" },		-- Portal: Vale of Eternal Blossoms
--	{ 132626, ST_Spell, "Vale of Eternal Blossoms" },		-- Portal: Vale of Eternal Blossoms
--	
--	{ 18984, ST_Item, "Winterspring" },	-- Dimensional Ripper - Everlook


---------------------------------------------------------------
	
-- [Orignal spell ID] = { Alt spell ID, Buff }
-- Currently unused
local SpellBuffs = 
{
	--[126892] = { 126896, 126896 }	-- Zen Pilgrimage / Zen Pilgrimage: Return
}

local TeleporterSpells = {}

local function GetTheme()
	if TomeOfTele_ShareOptions then
		if TomeOfTele_OptionsGlobal == nil or TomeOfTele_OptionsGlobal["theme"] == nil then
			return DefaultOptions["theme"]
		else
			return TomeOfTele_OptionsGlobal["theme"]
		end
	else
		if TomeOfTele_Options == nil or TomeOfTele_Options["theme"] == nil then
			return DefaultOptions["theme"]
		else
			return TomeOfTele_Options["theme"]
		end
	end
end

local function GetOption(option)
	local value = nil
	if TomeOfTele_ShareOptions then
		if TomeOfTele_OptionsGlobal then
			value = TomeOfTele_OptionsGlobal[option]
		end
	else
		if TomeOfTele_Options then
			value = TomeOfTele_Options[option]
		end
	end
	
	if value == nil then
		local theme = Themes[GetTheme()]
		if theme and theme[option] then
			return theme[option][1]
		else
			return DefaultOptions[option]
		end
	else
		return value
	end
end


local function GetScale()
	return GetOption("scale") * UIParent:GetEffectiveScale()
end

local function GetScaledOption(option)
	return GetOption(option) * GetScale()
end

local function SetOption(option, value)
	if TomeOfTele_Options == nil then
		TomeOfTele_Options = {}
	end
	if TomeOfTele_ShareOptions then
		TomeOfTele_OptionsGlobal[option] = value
	else
		TomeOfTele_Options[option] = value
	end
end


local function GetOptionId(spell)
	return spell.spellId .. "." .. spell.zone
end

function Teleporter_OnEvent(self, event, ...)
	if event == "ADDON_LOADED" then
		local loadedAddon = ...
		if string.upper(loadedAddon) == string.upper(AddonName) then
			Teleporter_OnAddonLoaded()			
		end
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		local player, guid, spell = ...
		if player == "player" then
			if GetSpellInfo(spell) == CastSpell then
				TeleporterClose()
			end
		end
	elseif event == "UNIT_INVENTORY_CHANGED" then
		if IsVisible then
			TeleporterUpdateAllButtons()
		end
	elseif event == "PLAYER_REGEN_DISABLED" then
		-- Can't close while in combat due to secure buttons, so disable Esc key
		if TeleporterParentFrame then
			local frameIndex = TeleporterFindInSpecialFrames()
			if frameIndex then
				tremove(UISpecialFrames,frameIndex);
			end
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		if TeleporterParentFrame then
			if not TeleporterFindInSpecialFrames() then
				tinsert(UISpecialFrames,TeleporterParentFrame:GetName());
			end
		end
	elseif event == "ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED_INDOORS" then
		TeleporterCheckItemsWereEquiped()
	end
end

function TeleporterFindInSpecialFrames()
	for i,f in ipairs(UISpecialFrames) do
		if f == TeleporterParentFrame:GetName() then
			return i
		end
	end
	return nil
end

local function RebuildSpellList()
	TeleporterSpells = {}
	for i,spell in ipairs(TeleporterDefaultSpells) do
		tinsert(TeleporterSpells, spell)
	end
	
	local extraSpells = GetOption("extraSpells")
	if extraSpells then		
		for id,dest in pairs(extraSpells) do
			local spell = CreateSpell(id,dest)
			spell.isCustom = true
			tinsert(TeleporterSpells, spell)
		end
	end
	
	local extraItems = GetOption("extraItems")
	if extraItems then
		for id,dest in pairs(extraItems) do
			local spell = CreateItem(id,dest)
			spell.isCustom = true
			tinsert(TeleporterSpells, spell)
		end
	end
end

function Teleporter_OnLoad() 
	SlashCmdList["TELEPORTER"] = TeleporterSlashCmdFunction
	SLASH_TELEPORTER1 = "/tomeofteleport"
	SLASH_TELEPORTER2 = "/tele"	

	SlashCmdList["TELEPORTEREQUIP"] = TeleporterEquipSlashCmdFunction
	SLASH_TELEPORTEREQUIP1 = "/teleporterequip"

	SlashCmdList["TELEPORTERUSEITEM"] = TeleporterUseItemSlashCmdFunction
	SLASH_TELEPORTERUSEITEM1 = "/teleporteruseitem"

	SlashCmdList["TELEPORTERCASTSPELL"] = TeleporterCastSpellSlashCmdFunction
	SLASH_TELEPORTERCASTSPELL1 = "/teleportercastspell"

	SlashCmdList["TELEPORTERCREATEMACRO"] = TeleporterCreateMacroSlashCmdFunction
	SLASH_TELEPORTERCREATEMACRO1 = "/teleportercreatemacro"
end 

local function SavePosition()
	local points = {}
	for i = 1,TeleporterParentFrame:GetNumPoints(),1 do
		tinsert(points,{TeleporterParentFrame:GetPoint(i)})
	end
	SetOption("points", points)
end


local function Refresh()
	if IsVisible then 
		TeleporterClose()
		TeleporterOpenFrame()
	end
end

local TeleporterMenu = nil
local TeleporterOptionsMenu = nil

local function OnHideOption(info, option)
	local hide = not GetOption(option)
	info.checked = hide
	SetOption(option, hide)
	
	Refresh()
end

local function TomeOfTele_SetSort(value)
	SetOption("sort", value)
	
	Refresh()
end

local function TomeOfTele_SetScale(scale)
	SetOption("scale", scale)
	if IsVisible then		
		TeleporterClose()
		TeleporterOpenFrame()
	end	
end

local function TomeOfTele_SetTheme(scale)
	SetOption("theme", scale)
	if IsVisible then		
		TeleporterClose()
		TeleporterOpenFrame()
	end	
end

local function AddHideOptionMenu(index, text, option, owner, level)
	local info = UIDropDownMenu_CreateInfo()
	info.text = text
	info.value = index
	info.func = function(info) OnHideOption(info, option) end
	info.owner = owner
	info.checked = GetOption(option)
	UIDropDownMenu_AddButton(info, level)
end

local function InitTeleporterOptionsMenu(frame, level, menuList, topLevel)
	if level == 1 or topLevel then 		
		local info = UIDropDownMenu_CreateInfo()
		info.owner = frame
		
		AddHideOptionMenu(1, "Hide Items", "hideItems", frame, level)
		AddHideOptionMenu(2, "Hide Challenge Mode Spells", "hideChallenge", frame, level)
		AddHideOptionMenu(3, "Hide Spells", "hideSpells", frame, level)
		AddHideOptionMenu(4, "Hide Consumables", "hideConsumable", frame, level)
				
		info.text = "Sort"
		info.hasArrow = true
		info.menuList = "Sort"
		info.value = 5
		info.func = nil
		info.checked = nil
		UIDropDownMenu_AddButton(info, level)	
		
		info.text = "Scale"
		info.hasArrow = true
		info.menuList = "Scale"
		info.value = 6
		info.checked =nil
		UIDropDownMenu_AddButton(info, level)	
		
		info.text = "Theme"
		info.hasArrow = true
		info.menuList = "Theme"
		info.value = 7
		info.checked = nil
		UIDropDownMenu_AddButton(info, level)
		
		info.text = "Use Shared Settings"
		info.value = 8
		info.hasArrow = false
		info.menuList = nil
		info.func = function(info) TomeOfTele_ShareOptions = not TomeOfTele_ShareOptions; Refresh(); end
		info.owner = frame
		info.checked = TomeOfTele_ShareOptions
		UIDropDownMenu_AddButton(info, level)
		
		info.text = "Customize Spells"
		info.value = 9
		info.hasArrow = false
		info.menuList = nil
		info.func = function(info) CustomizeSpells = not CustomizeSpells; Refresh(); end
		info.owner = frame
		info.checked = CustomizeSpells
		UIDropDownMenu_AddButton(info, level)	
		
	elseif menuList == "Scale" then
		local scales = { 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160, 170, 180, 190, 200 }
		for i,s in ipairs(scales) do
			local info = UIDropDownMenu_CreateInfo()
			info.text = s
			info.value = s / 10 + 20
			info.func = function(info) TomeOfTele_SetScale(s / 100) end
			info.owner = frame
			info.checked = function(info) return GetOption("scale") == s / 100 end
			UIDropDownMenu_AddButton(info, level)	
		end
	elseif menuList == "Theme" then
		local index = 40
		for themeName, theme in pairs(Themes) do
			local info = UIDropDownMenu_CreateInfo()
			info.text = themeName
			info.value = index
			info.func = function(info) TomeOfTele_SetTheme(themeName) end
			info.owner = frame
			info.checked = function(info) return GetOption("theme") == themeName end
			UIDropDownMenu_AddButton(info, level)	
			
			index = index + 1
		end
	elseif menuList== "Sort" then
		local info = UIDropDownMenu_CreateInfo()
		info.text = "Destination"
		info.value = 1
		info.func = function(info) TomeOfTele_SetSort(1) end
		info.owner = frame
		info.checked = function(info) sortMode = GetOption("sort"); return sortMode == nil or sortMode == 1; end
		UIDropDownMenu_AddButton(info, level)
		
		info.text = "Type"
		info.value = 2
		info.func = function(info) TomeOfTele_SetSort(2) end
		info.owner = frame
		info.checked = function(info) return GetOption("sort") == 2; end
		UIDropDownMenu_AddButton(info, level)
		
		info.text = "Custom"
		info.value = 3
		info.func = function(info) TomeOfTele_SetSort(3) end
		info.owner = frame
		info.checked = function(info) return GetOption("sort") == 3; end
		UIDropDownMenu_AddButton(info, level)
	end
end


local function InitTeleporterMenu(frame, level, menuList)
	if level == 1 then
		local info = UIDropDownMenu_CreateInfo()
		
		info.owner = frame
		info.text = "Right click a spell to add favourites"
		info.hasArrow = false
		info.menuList = nil
		info.value = 0
		info.checked = nil
		UIDropDownMenu_AddButton(info, level)
		
		info.owner = frame
		info.text = "Options"
		info.hasArrow = true
		info.menuList = "Options"
		info.value = 0
		info.checked = nil
		UIDropDownMenu_AddButton(info, level)
	elseif level == 2 then
		InitTeleporterOptionsMenu(frame, level, menuList, true)
	else
		InitTeleporterOptionsMenu(frame, level, menuList, false)
	end
end

local function ShowOptionsMenu()
	if not TeleporterOptionsMenu then
		TeleporterOptionsMenu = CreateFrame("Frame", "TomeOfTeleOptionsMenu", UIParent, "UIDropDownMenuTemplate")
		UIDropDownMenu_Initialize(TeleporterOptionsMenu, InitTeleporterOptionsMenu, "MENU")
	end
	
	ToggleDropDownMenu(1, nil, TeleporterOptionsMenu, "cursor", 3, -3)
end


local function SortSpells(spell1, spell2, sortType)
	local spellId1 = spell1.spellId
	local spellId2 = spell2.spellId
	local spellName1 = spell1.spellName
	local spellName2 = spell2.spellName
	local spellType1 = spell1.spellType
	local spellType2 = spell2.spellType
	local zone1 = spell1.zone
	local zone2 = spell2.zone
	
	local so = GetOption("sortOrder")
	
	if sortType == SortCustom then
		local optId1 = GetOptionId(spell1)
		local optId2 = GetOptionId(spell2)
		-- New spells always sort last - not ideal, but makes it easier to have a deterministic sort.
		if so[optId1] and so[optId2] then
			return so[optId1] < so[optId2]			
		elseif so[optId1] then
			return true
		elseif so[optId2] then
			return false
		end
	elseif sortType == SortByType then
		if spellType1 ~= spellType2 then
			return spellType1 < spellType2
		end
	end
	
	if zone1 ~= zone2 then
		return zone1 < zone2
	end
	
	return spellName1 < spellName2
end

local function SetupSpells()
	for index, spell in ipairs(TeleporterSpells) do		
		if spell[2] == ST_Item then
			spell[SpellNameIndex] = GetItemInfo( spell[1] )
			spell.spellName = GetItemInfo( spell[1] )
		else
			spell[SpellNameIndex] = GetSpellInfo( spell[1] )
			spell.spellName = GetSpellInfo( spell[1] )
		end
		
		if not spell.spellName then
			spell[SpellNameIndex] = "<Loading>"
			spell.spellName = "<Loading>"
		end
		
		-- The final stage of the refactor should get rid of these
		spell.zone = spell[SpellZoneIndex]
		spell.spellId = spell[SpellIdIndex]
		spell.spellType = spell[SpellTypeIndex]
		spell.isItem = spell.spellType == ST_Item
		spell.condition = spell[SpellConditionIndex]
		spell.consumable = spell[SpellConsumableIndex]
	end
end

local function GetSortedFavourites(favourites)
	SetupSpells()
	
	local sorted = {}
	local index = 1

	for spellId, isItem in pairs(favourites) do
		for i,spell in ipairs(TeleporterSpells) do
			if spell.spellId == spellId then
				sorted[index] = spell
				index = index + 1
				break
			end
		end		
	end
	
	local sortType = GetOption("sort")
	table.sort(sorted, function(a,b) return SortSpells(a, b, sortType) end)
	
	return sorted
end

local function ShowMenu()
	local favourites = GetOption("favourites")
	local next = next
	if favourites and next(favourites) ~= nil and not UnitAffectingCombat("player") then
		TeleToggleQuickMenu(GetSortedFavourites(favourites), GetScaledOption("QuickMenuSize"))
	else
		TeleporterMenu = CreateFrame("Frame", "TomeOfTeleMenu", UIParent, "UIDropDownMenuTemplate")	
		UIDropDownMenu_Initialize(TeleporterMenu, InitTeleporterMenu, "MENU")
		
		ToggleDropDownMenu(1, nil, TeleporterMenu, "cursor", 3, -3)
	end
end

function TeleporterItemMustBeEquipped(item)
	if IsEquippableItem( item ) then
		return not IsEquippedItem ( item )
	else
		return false
	end
end

local function IsSpellVisible(spell)
	local showSpells = GetOption("showSpells")
	local visible = showSpells[GetOptionId(spell)]
	if visible ~= nil then
		return visible
	else
		return true
	end
end

local function InitTeleporterMenu(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	info.owner = frame
	info.text = "Options"
	info.hasArrow = true
	info.menuList = "Options"
	info.value = 0
	info.checked = nil
	UIDropDownMenu_AddButton(info, level)
end

local FavouriteToAddRemove = nil
local FavouriteToAddRemoveIsItem
local AddFavouriteMenu = nil
local RemoveFavouriteMenu = nil
local CantAddFavouriteMenu = nil

local function CreateAddFavouriteMenu()
	if not AddFavouriteMenu then
		AddFavouriteMenu = CreateFrame("Frame", "TomeOfTeleAddFavouriteMenu", UIParent, "UIDropDownMenuTemplate")
			
		UIDropDownMenu_Initialize(
			AddFavouriteMenu, 
			function(frame, level, menuList)
				local info = UIDropDownMenu_CreateInfo()
				
				info.owner = frame
				info.hasArrow = false
				info.value = 1000
				info.checked = nil
				
				info.text = "Add favourite"
				info.func = function()
					local favourites = GetOption("favourites")
					favourites[FavouriteToAddRemove] = FavouriteToAddRemoveIsItem
				end
		
				UIDropDownMenu_AddButton(info, level)
			end, 
			"MENU")
	end
end

local function CreateRemoveFavouriteMenu()
	if not RemoveFavouriteMenu then
		RemoveFavouriteMenu = CreateFrame("Frame", "TomeOfTeleRemoveFavouriteMenu", UIParent, "UIDropDownMenuTemplate")
		
		UIDropDownMenu_Initialize(
			RemoveFavouriteMenu, 
			function(frame, level, menuList)
				local info = UIDropDownMenu_CreateInfo()
				
				info.owner = frame
				info.hasArrow = false
				info.value = 1001
				info.checked = nil
				
				info.text = "Remove favourite"
				info.func = function()
					local favourites = GetOption("favourites")
					favourites[FavouriteToAddRemove] = nil
				end
				UIDropDownMenu_AddButton(info, level)
			end, 
			"MENU")
	end
end

local function CreateCantAddFavouriteMenu()
	if not RemoveFavouriteMenu then
		CantAddFavouriteMenu = CreateFrame("Frame", "TomeOfTeleCantAddFavouriteMenu", UIParent, "UIDropDownMenuTemplate")
		
		UIDropDownMenu_Initialize(
			CantAddFavouriteMenu, 
			function(frame, level, menuList)
				local info = UIDropDownMenu_CreateInfo()
				
				info.owner = frame
				info.hasArrow = false
				info.value = 1002
				info.checked = nil
				
				info.text = "This item can not be added to favourites"
				info.func = nil
				UIDropDownMenu_AddButton(info, level)
			end, 
			"MENU")
	end
end

local function OnClickTeleButton(frame,button)
	if button == "RightButton" then	
		local spellId = ButtonSettings[frame].spellId
		local isItem = ButtonSettings[frame].isItem
		
		local favourites = GetOption("favourites")
				
		if not favourites then
			favourites = {}
			SetOption("favourites", favourites)
		end
		
		FavouriteToAddRemove = spellId
		FavouriteToAddRemoveIsItem = isItem
		
		local isFavourite = favourites[spellId] ~= nil
		
		if isItem and IsEquippableItem(spellId) then
			CreateCantAddFavouriteMenu()
			ToggleDropDownMenu(1, nil, CantAddFavouriteMenu, "cursor", 3, -3)
		elseif not isFavourite then
			CreateAddFavouriteMenu()
			ToggleDropDownMenu(1, nil, AddFavouriteMenu, "cursor", 3, -3)
		else
			CreateRemoveFavouriteMenu()
			ToggleDropDownMenu(1, nil, RemoveFavouriteMenu, "cursor", 3, -3)
		end
	end
end

function TeleporterUpdateButton(button)

	if UnitAffectingCombat("player") then
		return
	end

	local settings = ButtonSettings[button]
	local isItem = settings.isItem
	
	local item = settings.spellName
	local cooldownbar = settings.cooldownbar
	local cooldownString = settings.cooldownString
	local itemId = settings.spellId
	local countString = settings.countString
	local toySpell = settings.toySpell
	local spell = settings.spell
	local onCooldown = false
	local buttonInset = GetScaledOption("buttonInset")
	
	if item then
		local cooldownStart, cooldownDuration
		if isItem then
			cooldownStart, cooldownDuration = GetItemCooldown(itemId)
		else
			cooldownStart, cooldownDuration = GetSpellCooldown(itemId)
		end

		if cooldownStart and cooldownStart > 0 then
			if GetTime() < cooldownStart then
				-- Long cooldowns seem to be reported incorrectly after a server reset.  Looks like the
				-- time is taken from a 32 bit unsigned int.
				cooldownStart = cooldownStart - 4294967.295
			end

			onCooldown = true
			local durationRemaining = cooldownDuration - ( GetTime() - cooldownStart )
			
			local parentWidth = button:GetWidth()
			local inset = 8
			cooldownbar:SetWidth( inset + ( parentWidth - inset ) * durationRemaining / cooldownDuration )
			
			if durationRemaining > 3600 then
				cooldownString:SetText(string.format("%.0fh", durationRemaining / 3600))
			elseif durationRemaining > 60 then
				cooldownString:SetText(string.format("%.0fm", durationRemaining / 60))
			else
				cooldownString:SetText(string.format("%.0fs", durationRemaining))
			end
			
			cooldownbar:SetBackdropColor(1, 1, 1, 1)
		else			
			cooldownString:SetText("")
			cooldownbar:SetWidth( 1 )
			cooldownbar:SetBackdropColor(0, 0, 0, 0)
		end		
		
		cooldownString:SetPoint("TOPLEFT",button,"TOPRIGHT",-cooldownString:GetStringWidth()*1.1-buttonInset-2,-buttonInset)
		cooldownString:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",-buttonInset - 2,6)
		
		if countString and isItem then
			countString:SetText(GetItemCount(itemId))
		end

		if CustomizeSpells then
			local alpha = 1
			if not IsSpellVisible(spell) then
				alpha = 0.5
			end
			button:SetBackdropColor(GetOption("disabledColourR"), GetOption("disabledColourG"), GetOption("disabledColourB"), alpha)
			button:SetAttribute("macrotext1", nil)
		elseif isItem and TeleporterItemMustBeEquipped( item ) then 
			button:SetBackdropColor(GetOption("unequipedColourR"), GetOption("unequipedColourG"), GetOption("unequipedColourB"), 1)

			button:SetAttribute(
				"macrotext1",
				"/teleporterequip " .. item)
		elseif onCooldown then
			if cooldownDuration >2 then
				button:SetBackdropColor(GetOption("cooldownColourR"), GetOption("cooldownColourG"), GetOption("cooldownColourB"), 1)
			else
				button:SetBackdropColor(GetOption("readyColourR"), GetOption("readyColourG"), GetOption("readyColourB"), 1)
			end
			button:SetAttribute(
				"macrotext1",
				"/script print( \"" .. item .. " is currently on cooldown.\")")
		else
			button:SetBackdropColor(GetOption("readyColourR"), GetOption("readyColourG"), GetOption("readyColourB"), 1)
			
			if toySpell then		
				button:SetAttribute(
					"macrotext1",
					"/teleportercastspell " .. toySpell .. "\n" ..
					"/cast " .. item .. "\n" )
			elseif isItem then
				button:SetAttribute(
					"macrotext1",
					"/teleporteruseitem " .. item .. "\n" ..
					"/use " .. item .. "\n" )
			else
				button:SetAttribute(
					"macrotext1",
					"/teleportercastspell " .. item .. "\n" ..
					"/cast " .. item .. "\n" )
			end
		end

		button:SetAttribute(
			"ctrl-macrotext1",
			"/teleportercreatemacro " .. item )
	end
end

function TeleporterUpdateAllButtons()	
	for button, settings in pairs(ButtonSettings) do
		TeleporterUpdateButton( button )
	end
end

function TeleporterShowItemTooltip( item, button )
	local _,link = GetItemInfo(item)
	if link then
		GameTooltip:SetOwner(button, "ANCHOR_BOTTOMRIGHT")
		GameTooltip:SetHyperlink(link)
		GameTooltip:Show()
	end
end

function TeleporterShowSpellTooltip( item, button )
	local link = GetSpellLink(item)
	if link then
		GameTooltip:SetOwner(button, "ANCHOR_BOTTOMRIGHT")
		GameTooltip:SetHyperlink(link)
		GameTooltip:Show()
	end
end

local function OnClickFrame(frame, button)
	if button == "RightButton" then
		ShowOptionsMenu()
	end
end

local function ApplyResort()
	local newSo = {}
	
	for index, spell in ipairs(TeleporterSpells) do		
		local optId = GetOptionId(spell)
		newSo[optId] = index
	end
		
	SetOption("sortOrder", newSo)
end

local function RebuildCustomSort()
	SetupSpells()
	local oldSo = GetOption("sortOrder")
	
	table.sort(TeleporterSpells, function(a, b) return SortSpells(a, b, SortCustom) end)
	
	ApplyResort()
end

local function OnClickShow(spell)
	local showSpells = GetOption("showSpells")
	showSpells[GetOptionId(spell)] = not IsSpellVisible(spell)
end



local function CanUseSpell(spell)
	local spellId = spell.spellId
	local spellType = spell.spellType
	local isItem = (spellType == ST_Item)
	local condition = spell.condition
	local consumable = spell.consumable
	local itemTexture = nil
	
	local haveSpell = false
	local haveToy = false
	if isItem then
		haveToy = PlayerHasToy(spellId) and C_ToyBox.IsToyUsable(spellId)
		haveSpell = GetItemCount( spellId ) > 0 or haveToy
	else
		haveSpell = IsSpellKnown( spellId )					
		
		-- This isn't currently used - delete it if it's not needed in BfA, move it to the right place if it is.
		--if haveSpell and SpellBuffs[spellId] then
		--	local targetSpell = SpellBuffs[spellId][1]
		--	local targetBuff = SpellBuffs[spellId][2]
		--	local buffIndex = 1
		--	local buffName, _, _, _, _, _, _, _, _, _, buffID = UnitBuff("player", buffIndex)
		--	while buffName do
		--		if  buffID == targetBuff  then
		--			spellId = targetSpell
		--			displaySpellName = GetSpellInfo(spellId)
		--			buffName = nil
		--		else
		--			buffIndex = buffIndex + 1
		--			buffName, _, _, _, _, _, _, _, _, _, buffID = UnitBuff("player", buffIndex)							
		--		end
		--	end
		--end
	end
	
	if condition and not CustomizeSpells then
		if not condition() then
			haveSpell = false
		end
	end
	
	-- Uncomment this to test all items.
	--haveSpell = true
	
	if GetOption("hideItems") and spellType == ST_Item then
		haveSpell = false
	end
	
	if GetOption("hideConsumable") and consumable then
		haveSpell = false
	end
	
	if GetOption("hideSpells") and spellType == ST_Spell then
		haveSpell = false
	end
	
	if GetOption("hideChallenge") and spellType == ST_Challenge then
		haveSpell = false
	end
	
	if not CustomizeSpells and not IsSpellVisible(spell) then
		haveSpell = false
	end
	
	return haveSpell
end


local function OnClickSortUp(spell)
	RebuildCustomSort()
	
	local so = GetOption("sortOrder")
	local id = GetOptionId(spell)	
	if so[id] and so[id] > 1 then
		local potentialPos = so[id] - 1
		while potentialPos > 0 do
			local spellToSwap = TeleporterSpells[potentialPos]
			TeleporterSpells[potentialPos] = spell
			TeleporterSpells[potentialPos+1] = spellToSwap
			if CanUseSpell(spellToSwap) then
				break
			end
			potentialPos = potentialPos - 1
		end
	end
	
	ApplyResort()
	
	Refresh()
end

local function OnClickSortDown(spell)
	RebuildCustomSort()
	
	local so = GetOption("sortOrder")
	local id = GetOptionId(spell)	
	if so[id] and so[id] < #TeleporterSpells then
		local potentialPos = so[id] + 1
		while potentialPos <= #TeleporterSpells do
			local spellToSwap = TeleporterSpells[potentialPos]
			TeleporterSpells[potentialPos] = spell
			TeleporterSpells[potentialPos-1] = spellToSwap
			if CanUseSpell(spellToSwap) then
				break
			end
			potentialPos = potentialPos + 1
		end
	end
	
	ApplyResort()
	
	Refresh()
end

local function OnClickRemove(spell)
	local dialogText = "Are you sure you want to remove " .. spell.spellName .. "?"
	
	StaticPopupDialogs["TELEPORTER_CONFIRM_REMOVE"] = 
	{
		text = dialogText,
		button1 = "Yes",
		button2 = "No",
		OnAccept = function() 
			if spell.spellType == ST_Item then
				GetOption("extraItems")[spell.spellId] = nil
			else
				GetOption("extraSpells")[spell.spellId] = nil
			end
			RebuildSpellList()
			Refresh()
		end,
		OnCancel = function() end,
		hideOnEscape = true
	}
	
	StaticPopup_Show("TELEPORTER_CONFIRM_REMOVE")
end

local function AddCustomizationIcon(existingIcon, buttonFrame, xOffset, yOffset, width, height, optionName, onClick, forceHidden)
	local iconObject = existingIcon
	if not iconObject then		
		iconObject = {}
		iconObject.icon = buttonFrame:CreateTexture(frameName)
		-- Invisible frame use for button notifications
		iconObject.frame = TeleporterCreateReusableFrame("Frame","TeleporterIconFrame",buttonFrame)	
	end
	
	if iconObject.icon then
		iconObject.icon:SetPoint("TOPRIGHT",buttonFrame,"TOPRIGHT", xOffset, yOffset)
		iconObject.icon:SetTexture(GetOption(optionName))
		
		iconObject.icon:SetWidth(width)
		iconObject.icon:SetHeight(height)
		
		iconObject.frame:SetPoint("TOPRIGHT",buttonFrame,"TOPRIGHT", xOffset, yOffset)
		iconObject.frame:SetWidth(width)
		iconObject.frame:SetHeight(height)
		
		if CustomizeSpells and not forceHidden then
			iconObject.icon:Show()
			iconObject.frame:Show()
		else
			iconObject.icon:Hide()
			iconObject.frame:Hide()
		end
		
		iconObject.frame:SetScript("OnMouseUp", onClick)	
	end
	
	return iconObject
end


local function InitalizeOptions()
	if not TomeOfTele_OptionsGlobal then TomeOfTele_OptionsGlobal = {} end
	if not TomeOfTele_OptionsGlobal["showSpells"] then TomeOfTele_OptionsGlobal["showSpells"] = {} end
	if not TomeOfTele_OptionsGlobal["sortOrder"] then TomeOfTele_OptionsGlobal["sortOrder"] = {} end
	if not TomeOfTele_Options then TomeOfTele_Options = {} end
	if not TomeOfTele_Options["showSpells"] then TomeOfTele_Options["showSpells"] = {} end
	if not TomeOfTele_Options["sortOrder"] then TomeOfTele_Options["sortOrder"] = {} end
end

local IsAdding = false

local function FinishAddingItem(dialog, isItem, id)
	IsAdding = false
	
	if isItem then
		local extraItems = GetOption("extraItems")
		if not extraItems then
			extraItems = {}
			SetOption("extraItems", extraItems)
		end
		extraItems[id] = dialog.editBox:GetText()
	else
		local extraSpells = GetOption("extraSpells")
		if not extraSpells then
			extraSpells = {}
			SetOption("extraSpells", extraSpells)
		end
		extraSpells[id] = dialog.editBox:GetText()
	end
	
	RebuildSpellList()
	Refresh()
end

local function ShowSelectDestinationUI(dialog, isItem)
	local id = dialog.editBox:GetText()
	local name
	if isItem then
		name = GetItemInfo(id)
	else
		name = GetSpellInfo(id)
	end
	
	if name then
		local dialogText = "Adding " .. name .. ".\nWhat zone does it teleport to?"
		
		StaticPopupDialogs["TELEPORTER_ADDITEM_DEST"] = 
		{
			text = dialogText,
			button1 = "OK",
			button2 = "Cancel",
			OnAccept = function(dialog) FinishAddingItem(dialog, isItem, id) end,
			OnCancel = function() IsAdding = false; end,
			hideOnEscape = true,
			hasEditBox = true
		}
		
		StaticPopup_Show("TELEPORTER_ADDITEM_DEST")
	else
		local dialogText
		
		if isItem then
			dialogText = "Could not find an item with this ID."
		else
			dialogText = "Could not find a spell with this ID."
		end
		
		StaticPopupDialogs["TELEPORTER_ADDITEM_FAIL"] = 
		{
			text = dialogText,
			button1 = "OK",
			OnAccept = function() IsAdding = false; end,
			OnCancel = function() IsAdding = false; end,
			hideOnEscape = true
		}
		
		StaticPopup_Show("TELEPORTER_ADDITEM_FAIL")
	end
	
	
end

local function ShowAddItemUI(isItem)
	local dialogText
	
	if IsAdding then return end
	
	IsAdding = true
	
	if isItem then
		dialogText = "Enter the item ID. You can get this from wowhead.com."
	else
		dialogText = "Enter the spell ID. You can get this from wowhead.com."
	end
	
	StaticPopupDialogs["TELEPORTER_ADDITEM"] = 
	{
		text = dialogText,
		button1 = "OK",
		button2 = "Cancel",
		OnAccept = function(dialog) ShowSelectDestinationUI(dialog, isItem) end,
		OnCancel = function() IsAdding = false; end,
		hideOnEscape = true,
		hasEditBox = true
	}
	
	StaticPopup_Show("TELEPORTER_ADDITEM")
end

local function CreateMainFrame()
	TeleporterParentFrame = TeleporterFrame
	TeleporterParentFrame:SetFrameStrata("HIGH")		
	
	local buttonHeight = GetScaledOption("buttonHeight")
	local buttonWidth = GetScaledOption("buttonWidth")
	local labelHeight = GetScaledOption("labelHeight")
	local numColumns = 1
	local lastDest = nil
	local maximumHeight = GetScaledOption("maximumHeight")
	local fontHeight = GetScaledOption("fontHeight")
	local frameEdgeSize = GetOption("frameEdgeSize")
	local fontFile = GetOption("buttonFont")
	local fontFlags = nil 
	local titleWidth = GetScaledOption("titleWidth")
	local titleHeight = GetScaledOption("titleHeight")
	local buttonInset = GetOption("buttonInset")	
	
	TeleporterParentFrame:ClearAllPoints()
	local points = GetOption("points")
	if points then
		for i,pt in ipairs(points) do
			TeleporterParentFrame:SetPoint(pt[1], pt[2], pt[3], pt[4], pt[5])
		end
	else
		TeleporterParentFrame:SetPoint("CENTER",0,0)
	end
				
	tinsert(UISpecialFrames,TeleporterParentFrame:GetName());
	--TeleporterParentFrame:SetScript( "OnHide", TeleporterClose )

	-- Title bar
	local titleFrame = CreateFrame("Frame","TeleporterTitleFrame",TeleporterParentFrame)	
	TitleFrameBG = titleFrame:CreateTexture()
	TitleFrameBG:SetTexture(GetOption("titleBackground"))
	TitleFrameBG:SetAllPoints( titleFrame )
	titleFrame:SetPoint("TOP",TeleporterParentFrame,"TOP",0,titleHeight / 2 - GetScaledOption("titleOffset"))
	titleFrame:SetWidth(titleWidth)
	titleFrame:SetHeight(titleHeight)

	local titleString = titleFrame:CreateFontString("TeleporterTitleString", nil, GetOption("titleFont"))
	titleString:SetFont(fontFile, fontHeight, fontFlags)
	titleString:SetText( AddonTitle )
	titleString:SetPoint("TOP", titleFrame, "TOP", 0, -titleHeight / 5)
	
	TeleporterParentFrame:RegisterForDrag("LeftButton")			
	TeleporterParentFrame:SetScript("OnDragStart", function() TeleporterParentFrame:StartMoving() end )
	TeleporterParentFrame:SetScript("OnDragStop", function() TeleporterParentFrame:StopMovingOrSizing(); SavePosition(); end )
	TeleporterParentFrame:EnableMouse(true)
	TeleporterParentFrame:SetMovable(true)
	TeleporterParentFrame:SetScript("OnMouseUp", OnClickFrame)
	
	-- Close button
	local closeButton = CreateFrame( "Button", "TeleporterCloseButton", TeleporterParentFrame, "UIPanelButtonTemplate" )
	closeButton:SetText( "X" )
	closeButton:SetPoint( "TOPRIGHT", TeleporterParentFrame, "TOPRIGHT", -buttonInset, -buttonInset )
	closeButton:SetWidth( buttonWidth )
	closeButton:SetHeight( buttonHeight )
	closeButton:SetScript( "OnClick", TeleporterClose )			
	
	-- Help text
	if GetOption("showHelp") then
		local helpString = TeleporterParentFrame:CreateFontString("TeleporterHelpString", nil, GetOption("titleFont"))
		helpString:SetFont(fontFile, fontHeight, fontFlags)
		helpString:SetText( "Click to teleport, Ctrl+click to create a macro." )
		helpString:SetJustifyV("CENTER")
		helpString:SetJustifyH("LEFT")
	end
	
	AddItemButton = CreateFrame( "Button", "TeleporterAddItemButton", TeleporterParentFrame, "UIPanelButtonTemplate" )
	AddItemButton:SetText( "Add Item" )
	AddItemButton:SetPoint( "BOTTOMLEFT", TeleporterParentFrame, "BOTTOMLEFT", buttonInset, buttonInset )
	AddItemButton:SetScript( "OnClick", function() ShowAddItemUI(true) end )
	
	AddSpellButton = CreateFrame( "Button", "TeleporterAddSpellButton", TeleporterParentFrame, "UIPanelButtonTemplate" )
	AddSpellButton:SetText( "Add Spell" )
	AddSpellButton:SetPoint( "BOTTOMRIGHT", TeleporterParentFrame, "BOTTOMRIGHT", -buttonInset, buttonInset )
	AddSpellButton:SetScript( "OnClick", function() ShowAddItemUI(false) end )
end

function TeleporterOpenFrame()

	if UnitAffectingCombat("player") then
		print( "Cannot use " .. AddonTitle .. " while in combat." )
		return
	end
	
	InitalizeOptions()
	
	if not IsVisible then		
		local buttonHeight = GetScaledOption("buttonHeight")
		local buttonWidth = GetScaledOption("buttonWidth")
		local labelHeight = GetScaledOption("labelHeight")
		local numColumns = 1
		local lastDest = nil
		local maximumHeight = GetScaledOption("maximumHeight")
		local fontHeight = GetScaledOption("fontHeight")
		local frameEdgeSize = GetOption("frameEdgeSize")
		local fontFile = GetOption("buttonFont")
		local fontFlags = nil 
		local titleWidth = GetScaledOption("titleWidth")
		local titleHeight = GetScaledOption("titleHeight")
		local buttonInset = GetOption("buttonInset")		
		
		IsVisible = true
		NeedUpdate = true
		OpenTime = GetTime()

		if TeleporterParentFrame == nil then
			CreateMainFrame()			
		end
		
		if GetOption("showTitle")then
			TeleporterTitleFrame:Show()
		else
			TeleporterTitleFrame:Hide()
		end
		
		TeleporterParentFrame:SetBackdrop({bgFile = GetOption("background"), 
											edgeFile = GetOption("edge"), 
											tile = false, edgeSize = frameEdgeSize, 
											insets = { left = buttonInset, right = buttonInset, top = buttonInset, bottom = buttonInset }});
		TeleporterParentFrame:SetBackdropColor(
				GetOption("backgroundR"),
				GetOption("backgroundG"),
				GetOption("backgroundB"),
				GetOption("backgroundA"))
		
		-- UI scale may have changed, resize
		TeleporterCloseButton:SetWidth( buttonHeight )
		TeleporterCloseButton:SetHeight( buttonHeight )		
		TeleporterCloseButtonText:SetFont(fontFile, fontHeight, fontFlags)
		
		if TeleporterHelpString then
			TeleporterHelpString:SetFont(fontFile, fontHeight, fontFlags)
		end
		
		if TeleporterTitleFrame then
			TeleporterTitleFrame:SetWidth(titleWidth)
			TeleporterTitleFrame:SetHeight(titleHeight)
			TeleporterTitleFrame:SetPoint("TOP",TeleporterParentFrame,"TOP",0,titleHeight / 2 - GetScaledOption("titleOffset"))
			TeleporterTitleString:SetFont(fontFile, fontHeight, fontFlags)
			TeleporterTitleString:SetPoint("TOP", TeleporterTitleFrame, "TOP", 0, -titleHeight / 5)				
			
			TitleFrameBG:SetTexture(GetOption("titleBackground"))
			TitleFrameBG:SetAllPoints( TeleporterTitleFrame )
		end

		local minyoffset = -buttonInset - 10
		local yoffset = minyoffset
		local maxyoffset = -yoffset
		local xoffset = buttonInset

		ButtonSettings = {}
		
		SetupSpells()
		local SortType = GetOption("sort")
		if CustomizeSpells then
			SortType = SortCustom
		end
		table.sort(TeleporterSpells, function(a,b) return SortSpells(a, b, SortType) end)

		for index, spell in ipairs(TeleporterSpells) do		
			local spellId = spell.spellId
			local spellType = spell.spellType
			local isItem = (spellType == ST_Item)
			local destination = spell.zone
			local consumable = spell.consumable
			local spellName = spell.spellName
			local displaySpellName = spellName
			local isValidSpell = true
			local itemTexture = nil

			if destination == HearthString or destination == RecallString then
				local bindLocation = GetBindLocation()
				if bindLocation then
					destination = "Hearth (" .. bindLocation .. ")"
				else
					destination = "Hearth"
				end
			end
						
			if destination == FlightString then
				destination = "Flight Master"
			end


			if isItem then
				_, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo( spellId )
				if not spellName then
					isValidSpell = false
				end
			else
				_,_,itemTexture = GetSpellInfo( spellId )
				if not spellName then
					isValidSpell = false
				end
			end
			
			local haveSpell = isValidSpell and CanUseSpell(spell)	

			local toySpell = nil
			if isItem then
				if PlayerHasToy(spellId) then
					toySpell = GetItemSpell(spellId)
				end			
			end
			
			if haveSpell then
				-- Add extra column if needed
				local newColumn = false
				if -yoffset > maximumHeight then
					yoffset = minyoffset
					xoffset = xoffset + buttonWidth
					numColumns = numColumns + 1
					newColumn = true
				end		

				-- Title
				if newColumn or lastDest ~= destination then
					local destString = TeleporterCreateReusableFontString("TeleporterDL", TeleporterParentFrame, "GameFontNormalSmall")
					destString:SetFont(fontFile, fontHeight, fontFlags)
					destString:SetPoint("TOPLEFT", TeleporterParentFrame, "TOPLEFT", xoffset, yoffset)
					destString:SetPoint("BOTTOMRIGHT", TeleporterParentFrame, "TOPLEFT", buttonWidth + xoffset, yoffset - labelHeight)
					destString:SetText(destination)
					yoffset = yoffset - labelHeight
				end
				lastDest = destination	

				-- Main button
				local buttonFrame = TeleporterCreateReusableFrame("Button","TeleporterB",TeleporterParentFrame,"SecureActionButtonTemplate")
				--buttonFrame:SetFrameStrata("MEDIUM")
				buttonFrame:SetWidth(buttonWidth)
				buttonFrame:SetHeight(buttonHeight)
				buttonFrame:SetPoint("TOPLEFT",TeleporterParentFrame,"TOPLEFT",xoffset,yoffset)
				yoffset = yoffset - buttonHeight
				
				local buttonBorder = 4 * GetScale()
		
				buttonFrame:SetBackdrop({bgFile = GetOption("buttonBackground"), 
													edgeFile = GetOption("buttonEdge"), 
													tile = true, tileSize = GetOption("buttonTileSize"), 
													edgeSize = GetScaledOption("buttonEdgeSize"), 
													insets = { left = buttonBorder, right = buttonBorder, top = buttonBorder, bottom = buttonBorder }});
											
				buttonFrame:SetAttribute("type", "macro")
				buttonFrame:Show()

				if isItem then
					buttonFrame:SetScript(
						"OnEnter",
						function()
							TeleporterShowItemTooltip( spellName, buttonFrame )
						end )
				else
					buttonFrame:SetScript(
						"OnEnter",
						function()
							TeleporterShowSpellTooltip( spellName, buttonFrame )
						end )
				end

				buttonFrame:SetScript(
					"OnLeave",
					function()
						GameTooltip:Hide()
					end )

				-- Icon
				local iconOffsetX = 6 * GetScale()
				local iconOffsetY = -5 * GetScale()
				local iconW = 1
				local iconH = 1
				
				local teleicon = buttonFrame.TeleporterIcon
				if not teleicon then
					teleicon = buttonFrame:CreateTexture(frameName)
					buttonFrame.TeleporterIcon = teleicon
				end
				
				if teleicon then
					teleicon:SetPoint("TOPLEFT",buttonFrame,"TOPLEFT", iconOffsetX, iconOffsetY)
					if itemTexture then
						iconW = buttonHeight - 10 * GetScale()
						iconH = buttonHeight - 10 * GetScale()
						teleicon:SetTexture(itemTexture)
					end
					
					teleicon:SetWidth(iconW)
					teleicon:SetHeight(iconH)
				end

				-- Cooldown bar
				local cooldownbar = TeleporterCreateReusableFrame( "Frame", "TeleporterCB", buttonFrame, nil )
				--cooldownbar:SetFrameStrata("MEDIUM")
				cooldownbar:SetWidth(64)
				cooldownbar:SetHeight(buttonHeight)
				cooldownbar:SetPoint("TOPLEFT",buttonFrame,"TOPLEFT",0,0)
				cooldownbar:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background",insets = { left = 4, right = 4, top = 3, bottom = 3 }})

				-- Cooldown label
				local cooldownString = TeleporterCreateReusableFontString("TeleporterCL", cooldownbar, "GameFontNormalSmall")
				cooldownString:SetFont(fontFile, fontHeight, fontFlags)
				cooldownString:SetJustifyH("RIGHT")
				cooldownString:SetJustifyV("CENTER")
				cooldownString:SetPoint("TOPLEFT",buttonFrame,"TOPRIGHT",-50,-buttonInset - 2)
				cooldownString:SetPoint("BOTTOMRIGHT",buttonFrame,"BOTTOMRIGHT",-buttonInset - 2,6)
				
				-- Name label
				local nameString = TeleporterCreateReusableFontString("TeleporterSNL", cooldownbar, "GameFontNormalSmall")
				nameString:SetFont(fontFile, fontHeight, fontFlags)
				nameString:SetJustifyH("LEFT")
				nameString:SetJustifyV("CENTER")
				nameString:SetPoint("TOP",cooldownString,"TOPRIGHT",0,0)
				nameString:SetPoint("LEFT", buttonFrame, "TOPLEFT", iconOffsetX + iconW + 2, iconOffsetY - 1)
				if CustomizeSpells then
					nameString:SetPoint("BOTTOMRIGHT",cooldownString,"BOTTOMLEFT",-iconW * 4,0)
				else
					nameString:SetPoint("BOTTOMRIGHT",cooldownString,"BOTTOMLEFT",0,0)
				end
				nameString:SetText( displaySpellName )
				
				-- Count label
				local countString = nil
				if consumable then
					countString = TeleporterCreateReusableFontString("TeleporterCT", buttonFrame, "SystemFont_Outline_Small")
					countString:SetJustifyH("RIGHT")
					countString:SetJustifyV("CENTER")
					countString:SetPoint("TOPLEFT",buttonFrame,"TOPLEFT",iconOffsetX,iconOffsetY)
					countString:SetPoint("BOTTOMRIGHT", buttonFrame, "TOPLEFT", iconOffsetX + iconW, iconOffsetY - iconH - 2)
					countString:SetText("")
				end
			
				if -yoffset > maxyoffset then
					maxyoffset = -yoffset
				end
				
				RemoveIconOffset = -iconOffsetX - iconW * 3
				ShowIconOffset = -iconOffsetX - iconW * 2
				SortUpIconOffset = -iconOffsetX - iconW
				SortDownIconOffset = -iconOffsetX
				
				buttonFrame.RemoveIcon = AddCustomizationIcon(buttonFrame.RemoveIcon, buttonFrame, RemoveIconOffset, iconOffsetY, iconW, iconH, "removeButtonIcon", function() OnClickRemove(spell) end, not spell.isCustom)
				buttonFrame.ShowIcon = AddCustomizationIcon(buttonFrame.ShowIcon, buttonFrame, ShowIconOffset, iconOffsetY, iconW, iconH, "showButtonIcon", function() OnClickShow(spell) end)				
				buttonFrame.SortUpIcon = AddCustomizationIcon(buttonFrame.SortUpIcon, buttonFrame, SortUpIconOffset, iconOffsetY, iconW, iconH, "sortUpIcon", function() OnClickSortUp(spell) end)
				buttonFrame.SortDownIcon = AddCustomizationIcon(buttonFrame.SortDownIcon, buttonFrame, SortDownIconOffset, iconOffsetY, iconW, iconH, "sortDownIcon", function() OnClickSortDown(spell) end)
				
				buttonFrame:SetScript("OnMouseUp", OnClickTeleButton)
				
				local buttonSetting = { }	
				buttonSetting.isItem = isItem
				buttonSetting.spellName = spellName
				buttonSetting.cooldownbar = cooldownbar
				buttonSetting.cooldownString = cooldownString
				buttonSetting.spellId = spellId
				buttonSetting.countString = countString
				buttonSetting.toySpell = toySpell
				buttonSetting.spell = spell
				buttonSetting.spellType = spellType
				ButtonSettings[buttonFrame] = buttonSetting
			end	
		end
		
		local helpTextHeight		
		
		if TeleporterHelpString then
			if numColumns == 1 then
				helpTextHeight = 40
			else
				helpTextHeight = 10
			end
			TeleporterHelpString:SetPoint("TOPLEFT", TeleporterParentFrame, "TOPLEFT", 4 + buttonInset, -maxyoffset - 3 )
			TeleporterHelpString:SetPoint("RIGHT", TeleporterParentFrame, "RIGHT", -buttonInset, 0)
			TeleporterHelpString:SetHeight( helpTextHeight )	
		else
			helpTextHeight = 0
		end
		
		local addRemoveButtonsHeight = 0
	
		if CustomizeSpells then
			if numColumns < 2 then
				numColumns = 2
			end
			
			AddItemButton:SetWidth((numColumns * buttonWidth) / 2)			
			AddSpellButton:SetWidth((numColumns * buttonWidth) / 2)			
			addRemoveButtonsHeight = buttonInset + buttonHeight
			
			AddItemButton:Show()
			AddSpellButton:Show()
		else
			AddItemButton:Hide()
			AddSpellButton:Hide()
		end
		
		TeleporterParentFrame:SetWidth(numColumns * buttonWidth + buttonInset * 2)
		TeleporterParentFrame:SetHeight(maxyoffset + buttonInset * 2 + 2 + helpTextHeight + addRemoveButtonsHeight)
		
	end

	TeleporterUpdateAllButtons()	
	TeleporterParentFrame:Show()
end


function TeleporterRestoreEquipment()
	ShouldNotBeEquiped = {}
	for slot,item in pairs(OldItems) do		
		ShouldNotBeEquiped[slot] = GetInventoryItemID("player", slot)
		ShouldBeEquiped[slot] = item
		RemoveItem[slot](item)
	end
	OldItems = {}
	EquipTime = GetTime()
end

function TeleporterCheckItemsWereEquiped()
	-- Sometimes equipping after casting fails. If that happens
	-- then try equipping after the next teleport.
	if GetTime() < EquipTime + 60 then 
		for slot, item in pairs(ShouldNotBeEquiped) do
			if IsEquippedItem ( item ) then
				RemoveItem[slot](ShouldBeEquiped[slot])
			end
		end
	end
	ShouldNotBeEquiped = {}
	ShouldBeEquiped = {}
end

function TeleporterClose()
	if IsVisible and UnitAffectingCombat("player") then
		print( "Sorry, cannot close " .. AddonTitle .. " while in combat." )
	else
		if TeleporterParentFrame then
			TeleporterParentFrame:Hide()
			IsVisible = false
		end
		if TeleporterQuickMenuFrame then
			TeleporterQuickMenuFrame:Hide()
		end
	end
end

function TeleporterSlashCmdFunction(args)
	
	local splitArgs = {}
	if args then
		for v in string.gmatch(args, "[^ ]+") do
		  tinsert(splitArgs, v)
		end
	end
	
	if splitArgs[1] == "move" then
		local x = splitArgs[2]
		local y = splitArgs[3]
		if TeleporterParentFrame then
			TeleporterParentFrame:ClearAllPoints()
			TeleporterParentFrame:SetPoint("TOPLEFT", "UIParent", "TOPLEFT", x, -y)
			SavePoints()
		end
	elseif splitArgs[1] == "reset" then
		SetOption("points", nil)
		if TeleporterParentFrame then
			TeleporterParentFrame:ClearAllPoints()
			TeleporterParentFrame:SetPoint("CENTER", "UIParent", "CENTER", 0, 0)
		end
	elseif splitArgs[1] == "showicon" then
		TomeOfTele_Icon.hide = false
		icon:Show("TomeTele")
	elseif splitArgs[1] == "hideicon" then
		TomeOfTele_Icon.hide = true
		icon:Hide("TomeTele")
	elseif splitArgs[1] == "set" then
		SetOption(splitArgs[2], splitArgs[3])
	elseif splitArgs[1] == nil then
		if IsVisible then
			TeleporterClose()
		else
			TeleporterOpenFrame()
		end	
	else
		print("Tome of Teleportation usage")
		print("/tele: Opens of closes the main window")
		print("/tele move x y: Move the window to a new location")
		print("/tele reset: Move the window back to the middle of the screen")
		print("/tele showicon: Show the minimap icon")
		print("/tele hideicon: Show the minimap icon")
		print("/tele set scale <scale>: Sets the scale of the window (default=1.0)")
	end
end

local function PrepareUnequippedSlot(item, itemSlot)
	OldItems[ itemSlot ] = 0
	
	local inBag = 0
	for bagIdx = 1,NUM_BAG_SLOTS,1 do
		for slotIdx = 1, GetContainerNumSlots(bagIdx), 1 do
			local itemInBag = GetContainerItemID(bagIdx, slotIdx)
			if itemInBag then
				local bagItemName = GetItemInfo(itemInBag)
				if bagItemName == item or itemInBag == item then
					inBag = bagIdx
				end
			end
		end
	end
	
	if inBag == 0 then
		RemoveItem[itemSlot] = function(newItem)
			PickupInventoryItem(itemSlot)
			PutItemInBackpack()
		end
	else
		RemoveItem[itemSlot] = function(newItem)
			PickupInventoryItem(itemSlot)
			PutItemInBag(inBag + 19)
		end
	end
end

function TeleporterEquipSlashCmdFunction( item )
	CastSpell = nil

	if not IsEquippedItem ( item ) then
		if IsEquippableItem( item ) then 
			local _, _, _, _, _, _, _, _,itemEquipLoc = GetItemInfo(item)
			local itemSlot = InvTypeToSlot[ itemEquipLoc ]
			if itemSlot == nil then
				print( "Unrecognised equipable item type: " .. itemEquipLoc )
				return
			end
			local OldItem = GetInventoryItemID( "player", itemSlot )
			if OldItem then
				OldItems[ itemSlot ] = OldItem
				RemoveItem[itemSlot] = function(newItem)
					EquipItemByName( newItem, itemSlot )
				end
			else
				PrepareUnequippedSlot(item, itemSlot)				
			end
			EquipItemByName( item, itemSlot )
		end
	end
end

function TeleporterUseItemSlashCmdFunction( item )
	local spell = GetItemSpell( item )
	TeleporterCastSpellSlashCmdFunction( spell )
end

function TeleporterCastSpellSlashCmdFunction( spell )
	CastSpell = spell
end

function TeleporterCreateMacroSlashCmdFunction( spell )
	if spell then
		local macro
		local printEquipInfo = false

		if GetItemInfo( spell ) then
			if IsEquippableItem( spell ) then
				macro =
					"#showtooltip " .. spell .. "\n" ..
					"/teleporterequip " .. spell .. "\n" ..
					"/teleporteruseitem " .. spell .. "\n" ..
					"/use " .. spell .. "\n"
				printEquipInfo = true
			else
				macro =
					"#showtooltip " .. spell .. "\n" ..
					"/use " .. spell .. "\n"
			end
		else
			macro =
				"#showtooltip " .. spell .. "\n" ..
				"/cast " .. spell .. "\n"
		end

		local macroName = "Use" .. string.gsub( spell, "[^%a%d]", "" )
		if GetMacroInfo( macroName ) then
			DeleteMacro( macroName )
		end
		CreateMacro( macroName, 1, macro, 1, 1 )

		local extraInstructions = ""
		if printEquipInfo then
			extraInstructions = "If the item is not equipped then the first click of the macro will equip it and the second click will use it."
		end
		print( "Created macro " .. macroName .. ". " .. extraInstructions )

		PickupMacro( macroName )
	end
end

function Teleporter_OnAddonLoaded()
	if TomeOfTele_Icon == nil then
		TomeOfTele_Icon = {}
	end
	
	icon:Register("TomeTele", dataobj, TomeOfTele_Icon)		
	
	RebuildSpellList()
	
	for index, spell in ipairs(TeleporterSpells) do		
		-- TODO: Replace indices with names after refactor
		local spellId = spell[SpellIdIndex]
		local spellType = spell[SpellTypeIndex]
		local isItem = (spellType == ST_Item)
		if isItem then
			-- Query this early so it will be ready when we need it.
			C_ToyBox.IsToyUsable(spellId)			
		end
	end
end

function Teleporter_OnUpdate()
	if IsVisible then	
		-- The first time the UI is opened toy ownership may be incorrect. Reopen once it's correct.
		if NeedUpdate then			
			-- Assume it's ready after 1 second.
			if GetTime() > OpenTime + 1 then
				--TeleporterClose()
				TeleporterOpenFrame()
				NeedUpdate = false
			end
		end
		TeleporterUpdateAllButtons()		
		
		--if not TeleporterParentFrame:IsVisible() then			
		--	TeleporterHideCreatedUI()
		--	IsVisible = false			
		--	TeleporterRestoreEquipment()
		--end
	end
end

function Teleporter_OnHide()
	TeleporterHideCreatedUI()
	IsVisible = false
	TeleporterRestoreEquipment()
end

-----------------------------------------------------------------------
-- UI reuse

local uiElements = {}
local numUIElements = {}

-- Returns frame,frameName.  if frame is null then the caller must create a new object with this name
function TeleporterFindOrAddUIElement( prefix, parentFrame )
	local fullPrefix = parentFrame:GetName() .. prefix

	local numElementsWithPrefix = numUIElements[ fullPrefix ]
	if not numElementsWithPrefix then
		numElementsWithPrefix = 0
	end

	local frameName = fullPrefix .. numElementsWithPrefix
	local oldFrame = getglobal( frameName )
	if oldFrame then
		oldFrame:Show()
	end

	tinsert(uiElements, frameName)

	numElementsWithPrefix = numElementsWithPrefix + 1
	numUIElements[ fullPrefix ] = numElementsWithPrefix	
	
	return oldFrame, frameName
end


function TeleporterCreateReusableFrame( frameType, prefix, parentFrame, inheritsFrame )
	local frame, frameName = TeleporterFindOrAddUIElement( prefix, parentFrame )

	if not frame then
		frame = CreateFrame( frameType, frameName, parentFrame, inheritsFrame )
	end	
	
	return frame
end

function TeleporterCreateReusableFontString( prefix, parentFrame, font )
	local frame, frameName = TeleporterFindOrAddUIElement( prefix, parentFrame )

	if not frame then
		frame = parentFrame:CreateFontString(frameName, nil, font)
	end	
	
	return frame
end

function TeleporterHideCreatedUI()
	for index, itemName in pairs( uiElements ) do		
		local item = getglobal(itemName)
		if item then
			item:Hide()
		end
	end
	numUIElements = {}
	uiElements = {}
end

function dataobj:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
    GameTooltip:ClearLines()

    GameTooltip:AddLine(AddonTitle, 1, 1, 1)

    GameTooltip:Show()
end

function dataobj:OnLeave()
    GameTooltip:Hide()
end

function dataobj:OnClick(button)
	if button == "LeftButton" then
		TeleporterSlashCmdFunction("")
	elseif button == "RightButton" then
		ShowMenu()
	end
	NeedUpdate = false
end

function TeleporterAddTheme(name, theme)
	Themes[name] = theme
end

function TeleporterAddSpell(id, dest)
	TeleporterSpells[#TeleporterSpells + 1] = {id, ST_Spell, dest}
end

function TeleporterAddItem(id, dest)
	TeleporterSpells[#TeleporterSpells + 1] = {id, ST_Item, dest}
end
