-- Tome of Teleportation by Remeen.

-- TODO:
-- Improve speed
-- Optional compact UI
-- Tests for search

-- Known issues:
-- Overlapping buttons

local AddonName = "TomeOfTeleportation"
local AddonTitle = "Tome of Teleportation"
-- Special case strings start with number to force them to be sorted first.
TeleporterHearthString = "0 Hearth"
TeleporterRecallString = "1 Astral Recall"
TeleporterFlightString = "2 Flight Master"

local DungeonsTitle = "Dungeons"

local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local icon = LibStub("LibDBIcon-1.0")
local dataobj = ldb:NewDataObject("TomeTeleGlobal", {
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
local OrderedButtonSettings = {}
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
local DebugUnsupported = nil
local ChosenHearth = nil
local IsRefreshing = nil

TomeOfTele_ShareOptions = true

BINDING_NAME_TOMEOFTELEPORTATION = "Tome of Teleportation"

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
	["heightScalePercent"] = 100,
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
	["cooldownBarInset"] = 4,
	["disabledColourR"] = 0.5,
	["disabledColourG"] = 0.5,
	["disabledColourB"] = 0.5,
	["QuickMenuSize"] = 50,
	["sortUpIcon"] = "Interface/Icons/misc_arrowlup",
	["sortDownIcon"] = "Interface/Icons/misc_arrowdown",
	["showButtonIcon"] = "Interface/Icons/levelupicon-lfd",
	["removeButtonIcon"] = "Interface/Icons/INV_Misc_Bone_Skull_03",
	["conciseDungeonSpells"] = 1,
	["showSearch"] = 1,
	["searchHidden"] = 1,
}

-- Themes. For now there aren't many of these. Message me on curseforge.com
-- if you create a theme that you'd like to be included. Also let me know
-- if you need to change a parameter that isn't exposed.
-- Note that every value is enclosed in {}.
local DefaultTheme =
{
}

local FlatTheme =
{
	["background"] = {"Interface/DialogFrame/UI-DialogBox-Gold-Background"},
	["edge"] = {""},
	["buttonEdge"] = {""},
	["titleBackground"] = {"Interface/DialogFrame/UI-DialogBox-Gold-Background"},
	["backgroundA"] = {1},
	["showTitle"] = {false},
	["titleHeight"] = {20},
	["titleWidth"] = {150},
	["titleOffset"] = {5},
}

local WideTheme =
{
	["buttonWidth"] = {225},
	["maximumHeight"] = {320}
}

local Themes =
{
	["Default"] = DefaultTheme,
	["Flat"] = FlatTheme,
	["Wide Buttons"] = WideTheme
}

---------------------------------------------------------------

local ItemsFound = {}
local EmulateSlowServer = false

-- Emulating slow server.
local function GetCachedItemInfo(itemId)
	if EmulateSlowServer then
		if ItemsFound[itemId] == nil then
			ItemsFound[itemId] = true
			return nil
		else
			return GetItemInfo(itemId)
		end
	else
		return GetItemInfo(itemId)
	end
end

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

function TeleporterGetOption(option)
	return GetOption(option)
end

function TeleporterIsOptionModified(option)
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

	if value ~= nil then
		return true
	else
		return false
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


function TeleporterSetOption(option, value)
	local oldValue = GetOption(option)
	local isSame = value == oldValue
	if type(value) == "number" and type(oldValue) == "number" then
		isSame = math.abs(value - oldValue) < 0.0001
	end

	if not isSame then
		SetOption(option, value)
	end
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
			if C_Spell and C_Spell.GetSpellInfo then
				if C_Spell.GetSpellInfo(spell).name == CastSpell then
					TeleporterClose()
				end
			else
				if GetSpellInfo(spell) == CastSpell then
					TeleporterClose()
				end
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
			local spell = TeleporterCreateSpell(id,dest)
			spell.isCustom = true
			tinsert(TeleporterSpells, spell)
		end
	end

	local extraItems = GetOption("extraItems")
	if extraItems then
		for id,dest in pairs(extraItems) do
			local spell = TeleporterCreateItem(id,dest)
			spell.isCustom = true
			tinsert(TeleporterSpells, spell)
		end
	end

	local extraSpellsAndItems = GetOption("extraSpellsAndItems")
	if extraSpellsAndItems then
		for index = #extraSpellsAndItems,1,-1 do
			local spell = extraSpellsAndItems[index]
			local isDuplicate = false
			for id2, spell2 in ipairs(TeleporterSpells) do
				if spell2:Equals(spell) then
					isDuplicate = true
					table.remove(extraSpellsAndItems, index)
				end
			end
			if not isDuplicate then
				TeleporterInitSpell(spell)
				tinsert(TeleporterSpells, spell)
			end
		end
	end
end

function TeleporterRebuildSpellList()
	RebuildSpellList()
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

	if TeleporterSettings_OnLoad then
		TeleporterSettings_OnLoad()
	end
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
		IsRefreshing = true
		TeleporterClose()
		TeleporterOpenFrame()
		IsRefreshing = false
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
	Refresh()
end

local function TomeOfTele_SetHeightScale(scale)
	SetOption("heightScalePercent", scale)
	Refresh()
end

local function TomeOfTele_SetTheme(scale)
	SetOption("theme", scale)
	Refresh()
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

local MenuIDHideItems 			= 1
local MenuIDHideChallenge 		= 2
local MenuIDHideSpells 			= 3
local MenuIDHideConsumables 	= 4
local MenuIDSort 				= 5
local MenuIDScale 				= 6
local MenuIDTheme 				= 7
local MenuIDSharedSettings 		= 8
local MenuIDCustomize 			= 9
local MenuIDHeight 				= 10
local MenuIDDungeonNames		= 11
local MenuIDWrongZone			= 12
local MenuIDCurrentDungeons		= 13
local MenuIDGroupDungeons		= 14
local MenuIDRandomHearth		= 15
local MenuIDCloseAfterCast		= 16

local function InitTeleporterOptionsMenu(frame, level, menuList, topLevel)
	if level == 1 or topLevel then
		local info = UIDropDownMenu_CreateInfo()
		info.owner = frame

		AddHideOptionMenu(MenuIDHideItems, "Hide Items", "hideItems", frame, level)
		AddHideOptionMenu(MenuIDHideChallenge, "Hide Dungeon Spells", "hideChallenge", frame, level)
		AddHideOptionMenu(MenuIDHideSpells, "Hide Spells", "hideSpells", frame, level)
		AddHideOptionMenu(MenuIDHideConsumables, "Hide Consumables", "hideConsumable", frame, level)
		AddHideOptionMenu(MenuIDDungeonNames, "Show Dungeon Names", "showDungeonNames", frame, level)
		AddHideOptionMenu(MenuIDCurrentDungeons, "Current Dungeons Only", "seasonOnly", frame, level)
		AddHideOptionMenu(MenuIDGroupDungeons, "Group Dungeons", "groupDungeons", frame, level)
		AddHideOptionMenu(MenuIDRandomHearth, "Random Hearthstone", "randomHearth", frame, level)
		AddHideOptionMenu(MenuIDWrongZone, "Show Spells When In Wrong Zone", "showInWrongZone", frame, level)
		AddHideOptionMenu(MenuIDCloseAfterCast, "Close When Cast Finishes", "closeAfterCast", frame, level)

		info.text = "Sort"
		info.hasArrow = true
		info.menuList = "Sort"
		info.value = MenuIDSort
		info.func = nil
		info.checked = nil
		UIDropDownMenu_AddButton(info, level)

		info.text = "Scale"
		info.hasArrow = true
		info.menuList = "Scale"
		info.value = MenuIDScale
		info.checked = nil
		UIDropDownMenu_AddButton(info, level)

		info.text = "Height"
		info.hasArrow = true
		info.menuList = "Height"
		info.value = MenuIDHeight
		info.checked = nil
		UIDropDownMenu_AddButton(info, level)

		info.text = "Theme"
		info.hasArrow = true
		info.menuList = "Theme"
		info.value = MenuIDTheme
		info.checked = nil
		UIDropDownMenu_AddButton(info, level)

		info.text = "Use Shared Settings"
		info.value = MenuIDSharedSettings
		info.hasArrow = false
		info.menuList = nil
		info.func = function(info) TomeOfTele_ShareOptions = not TomeOfTele_ShareOptions; Refresh(); end
		info.owner = frame
		info.checked = TomeOfTele_ShareOptions
		UIDropDownMenu_AddButton(info, level)

		-- I'd like to split this up, but the Wow API doesn't let you select sub categories.
		info.text = "Customize Spells and More Settings"
		info.value = MenuIDCustomize
		info.hasArrow = false
		info.menuList = nil
		info.func = function(info)
			if GetOption("oldCustomizer") then
				CustomizeSpells = not CustomizeSpells; Refresh();
			else
				TeleporterClose()
				TeleporterOpenSettings()
			end
		end
		info.owner = frame
		info.checked = CustomizeSpells
		UIDropDownMenu_AddButton(info, level)

	elseif menuList == "Scale" then
		local scales = { 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160, 170, 180, 190, 200 }
		for i,s in ipairs(scales) do
			local info = UIDropDownMenu_CreateInfo()
			info.text = s .. "%"
			info.value = s / 10 + 20			-- 26 to 40
			info.func = function(info) TomeOfTele_SetScale(s / 100) end
			info.owner = frame
			info.checked = function(info) return GetOption("scale") == s / 100 end
			UIDropDownMenu_AddButton(info, level)
		end
	elseif menuList == "Height" then
		local scales = { 100, 150, 200, 250, 300 }
		for i,s in ipairs(scales) do
			local info = UIDropDownMenu_CreateInfo()
			info.text = s .. "%"
			info.value = s / 50 + 50	-- 52 to 56
			info.func = function(info) TomeOfTele_SetHeightScale(s) end
			info.owner = frame
			info.checked = function(info) return GetOption("heightScalePercent") == s end
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
	local zone1 = spell1:GetZone()
	local zone2 = spell2:GetZone()

	if GetOption("groupDungeons") then
		if spell1:IsDungeonSpell() then zone1 = DungeonsTitle end
		if spell2:IsDungeonSpell() then zone2 = DungeonsTitle end
	end

	local so = GetOption("sortOrder") or {}

	if sortType == SortCustom then
		local optId1 = spell1:GetOptionId()
		local optId2 = spell2:GetOptionId()
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

function TeleporterGetSearchString()
	if GetOption("showSearch") then
		local searchString = TeleporterSearchBox:GetText()
		if searchString == "" then
			return nil
		else
			return searchString
		end
	else
		return nil
	end
end

local function SetupSpells()
	local loaded = true
	for index, spell in ipairs(TeleporterSpells) do
		if spell:IsItem() then
			spell.spellName = GetCachedItemInfo( spell.spellId )
		else
			if C_Spell and C_Spell.GetSpellInfo then
				spell.spellName = C_Spell.GetSpellInfo( spell.spellId).name
			else
				spell.spellName = GetSpellInfo( spell.spellId)
			end
		end

		if not spell.spellName then
			if DebugUnsupported then
				print(spell.spellType .. " " .. spell.spellId)
			end
			spell.spellName = "<Loading>"
			if spell:CanUse() then
				loaded = false
			end
		end

		spell.isItem = spell:IsItem()
	end

	return loaded
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

local RightClickMenuSpell = nil
local RightClickMenuSpellIsItem
local RightClickMenuSpellName = nil
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
					favourites[RightClickMenuSpell] = RightClickMenuSpellIsItem
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
					favourites[RightClickMenuSpell] = nil
				end
				UIDropDownMenu_AddButton(info, level)
			end,
			"MENU")
	end
end

local function CreateEquipableItemRightClickMenu()
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

				-- The macros this creates crash the game!
				-- info = UIDropDownMenu_CreateInfo()

				-- info.owner = frame
				-- info.hasArrow = false
				-- info.value = 1003
				-- info.checked = nil

				-- info.text = "Create macro"
				-- info.func = function()
				-- 	TeleporterCreateMacroSlashCmdFunction(RightClickMenuSpellName)
				-- end
				-- UIDropDownMenu_AddButton(info, level)
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

		RightClickMenuSpell = spellId
		RightClickMenuSpellName = ButtonSettings[frame].spellName
		RightClickMenuSpellIsItem = isItem

		local isFavourite = favourites[spellId] ~= nil

		if isItem and IsEquippableItem(spellId) then
			CreateEquipableItemRightClickMenu()
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

local function SafeGetItemCooldown(itemId)
	if GetItemCooldown ~= nil then
		return GetItemCooldown(itemId)
	else
		return C_Container.GetItemCooldown(itemId)
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
			cooldownStart, cooldownDuration = SafeGetItemCooldown(itemId)
		else
			if C_Spell and C_Spell.GetSpellCooldown then
				local spellCooldownInfo = C_Spell.GetSpellCooldown(itemId);
				cooldownStart = spellCooldownInfo.startTime
				cooldownDuration = spellCooldownInfo.duration
			else
				cooldownStart, cooldownDuration = GetSpellCooldown(itemId)
			end
		end

		if cooldownStart and cooldownStart > 0 then
			if GetTime() < cooldownStart then
				-- Long cooldowns seem to be reported incorrectly after a server reset.  Looks like the
				-- time is taken from a 32 bit unsigned int.
				cooldownStart = cooldownStart - 4294967.295
			end

			onCooldown = true
			local durationRemaining = cooldownDuration - ( GetTime() - cooldownStart )

			if durationRemaining < 0 then
				durationRemaining = 0
			end
			if durationRemaining > cooldownDuration then
				durationRemaining = cooldownDuration
			end

			local parentWidth = button:GetWidth()
			local inset = GetOption("cooldownBarInset") * 2
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
			countString:SetText(GetItemCount(itemId, false, true))
		end

		if CustomizeSpells then
			local alpha = 1
			if not spell:IsVisible() then
				alpha = 0.5
			end
			button.backdrop:SetBackdropColor(GetOption("disabledColourR"), GetOption("disabledColourG"), GetOption("disabledColourB"), alpha)
			button:SetAttribute("macrotext", nil)
		elseif isItem and TeleporterItemMustBeEquipped( item ) then
			button.backdrop:SetBackdropColor(GetOption("unequipedColourR"), GetOption("unequipedColourG"), GetOption("unequipedColourB"), 1)

			button:SetAttribute(
				"macrotext",
				"/teleporterequip " .. item)
		elseif onCooldown then
			if cooldownDuration >2 then
				button.backdrop:SetBackdropColor(GetOption("cooldownColourR"), GetOption("cooldownColourG"), GetOption("cooldownColourB"), 1)
			else
				button.backdrop:SetBackdropColor(GetOption("readyColourR"), GetOption("readyColourG"), GetOption("readyColourB"), 1)
			end
			button:SetAttribute(
				"macrotext",
				"/script print( \"" .. item .. " is currently on cooldown.\")")
		else
			button.backdrop:SetBackdropColor(GetOption("readyColourR"), GetOption("readyColourG"), GetOption("readyColourB"), 1)

			if toySpell then
				button:SetAttribute(
					"macrotext",
					"/teleportercastspell " .. toySpell .. "\n" ..
					"/cast " .. item .. "\n" )
			elseif isItem then
				button:SetAttribute(
					"macrotext",
					"/teleporteruseitem " .. item .. "\n" ..
					"/use " .. item .. "\n" )
			else
				button:SetAttribute(
					"macrotext",
					"/teleportercastspell " .. item .. "\n" ..
					"/cast " .. item .. "\n" )
			end
		end
	end
end

function TeleporterUpdateAllButtons()
	for button, settings in pairs(ButtonSettings) do
		TeleporterUpdateButton( button )
	end
end

function TeleporterShowItemTooltip( item, button )
	local _,link = GetCachedItemInfo(item)
	if link then
		GameTooltip:SetOwner(button, "ANCHOR_BOTTOMRIGHT")
		GameTooltip:SetHyperlink(link)
		GameTooltip:Show()
	end
end

function TeleporterShowSpellTooltip( item, button )
	local link
	if C_Spell and C_Spell.GetSpellLink then
		link = C_Spell.GetSpellLink(item)
	else
		link = GetSpellLink(item)
	end
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
		local optId = spell:GetOptionId()
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
	showSpells[spell:GetOptionId()] = not spell:IsVisible()
end

local function OnClickSortUp(spell)
	RebuildCustomSort()

	local so = GetOption("sortOrder")
	local id = spell:GetOptionId()
	if so[id] and so[id] > 1 then
		local potentialPos = so[id] - 1
		while potentialPos > 0 do
			local spellToSwap = TeleporterSpells[potentialPos]
			TeleporterSpells[potentialPos] = spell
			TeleporterSpells[potentialPos+1] = spellToSwap
			if spellToSwap:CanUse() then
				break
			end
			potentialPos = potentialPos - 1
		end
	end

	ApplyResort()

	Refresh()
end

function RenormalizeCustomSort()
	RebuildCustomSort()

	local so = GetOption("sortOrder")

	for i = 1, #TeleporterSpells do
		local id = TeleporterSpells[i]:GetOptionId()
		so[id] = i
	end

	RebuildCustomSort()
end

function TeleporterMoveSpellBefore(movingSpell, destSpell)
	RebuildCustomSort()

	local so = GetOption("sortOrder")
	local movingId = movingSpell:GetOptionId()
	local destId = destSpell:GetOptionId()

	so[movingId] = so[destId] - 0.5

	RenormalizeCustomSort()
end

function TeleporterMoveSpellAfter(movingSpell, destSpell)
	RebuildCustomSort()

	local so = GetOption("sortOrder")
	local movingId = movingSpell:GetOptionId()
	local destId = destSpell:GetOptionId()

	so[movingId] = so[destId] + 0.5

	RenormalizeCustomSort()
end

function TeleporterResetSort()
	SetOption("sortOrder", {})
	RebuildCustomSort()
end


local function OnClickSortDown(spell)
	RebuildCustomSort()

	local so = GetOption("sortOrder")
	local id = spell:GetOptionId()
	if so[id] and so[id] < #TeleporterSpells then
		local potentialPos = so[id] + 1
		while potentialPos <= #TeleporterSpells do
			local spellToSwap = TeleporterSpells[potentialPos]
			TeleporterSpells[potentialPos] = spell
			TeleporterSpells[potentialPos-1] = spellToSwap
			if spellToSwap:CanUse() then
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
			if spell:IsItem() then
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

local function AddCustomizationIcon(existingIcon, buttonFrame, showAboveFrame, xOffset, yOffset, width, height, optionName, onClick, forceHidden)
	local iconObject = existingIcon
	if not iconObject then
		iconObject = {}
		iconObject.icon = showAboveFrame:CreateTexture()
		-- Invisible frame use for button notifications
		iconObject.frame = TeleporterCreateReusableFrame("Frame","TeleporterIconFrame",showAboveFrame)
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
	if not TomeOfTele_OptionsGlobal["alwaysShowSpells"] then TomeOfTele_OptionsGlobal["alwaysShowSpells"] = {} end
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
		name = GetCachedItemInfo(id)
	else
		if C_Spell and C_Spell.GetSpellInfo then
			name = C_Spell.GetSpellInfo(id).name
		else
			name = GetSpellInfo(id)
		end
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

local function GetMaximumHeight()
	return GetScaledOption("maximumHeight") * GetOption("heightScalePercent") / 100
end

local function UpdateSearch(searchString)
	if  UnitAffectingCombat("player") then
		print("Cannot search while in combat")
	else
		IsRefreshing = true
		TeleporterHideCreatedUI()
		TeleporterOpenFrame(true)
		IsRefreshing = false
	end
end

local function CreateMainFrame()
	TeleporterParentFrame = TeleporterFrame
	TeleporterParentFrame:SetFrameStrata("HIGH")

	local buttonHeight = GetScaledOption("buttonHeight")
	local buttonWidth = GetScaledOption("buttonWidth")
	local labelHeight = GetScaledOption("labelHeight")
	local numColumns = 1
	local lastDest = nil
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

	-- Search box
	local searchFrame = CreateFrame("EditBox", "TeleporterSearchBox", TeleporterParentFrame, "InputBoxTemplate")
	searchFrame:SetPoint("LEFT", TeleporterParentFrame, "LEFT", buttonInset * 2, 0)
	searchFrame:SetPoint("TOPRIGHT", closeButton, "TOPLEFT", -4, -2)
	searchFrame:SetHeight(buttonHeight)
	searchFrame:SetAutoFocus(false)
	searchFrame:SetMultiLine(false)

	searchFrame:SetScript("OnTextChanged", function(self, userInput)
		if userInput then
			UpdateSearch(searchFrame:GetText())
		end
	end)
	if GetOption("showSearch") then
		searchFrame:Show()
	else
		searchFrame:Hide()
	end

	-- Help text
	if GetOption("showHelp") then
		local helpString = TeleporterParentFrame:CreateFontString("TeleporterHelpString", nil, GetOption("titleFont"))
		helpString:SetFont(fontFile, fontHeight, fontFlags)
		helpString:SetText( "Click to teleport, Ctrl+click to create a macro." )
		helpString:SetJustifyV("MIDDLE")
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

local function GetRandomHearth(validSpells)
	if ChosenHearth then
		return ChosenHearth
	end
	local hearthSpellsFastestCooldown = {}
	local hearthSpellsNotCooldown = {}
	local fastestCooldownEnd = 0
	for index, spell in ipairs(validSpells) do
		if spell:GetZone() == TeleporterHearthString then
			local cooldownStart, cooldownDuration = SafeGetItemCooldown(spell.spellId)
			if cooldownStart and cooldownStart > 0 then
				local cooldownEnd = cooldownStart + cooldownDuration
				if fastestCooldownEnd == 0 or cooldownEnd < fastestCooldownEnd then
					hearthSpellsFastestCooldown = {}
					fastestCooldownEnd = cooldownEnd
				end
				if cooldownEnd == fastestCooldownEnd then
					tinsert(hearthSpellsFastestCooldown, spell.spellId)
				end
			else
				tinsert(hearthSpellsNotCooldown, spell.spellId)
			end
		end
	end
	if  #hearthSpellsNotCooldown > 0 then
		ChosenHearth =  hearthSpellsNotCooldown[math.random(#hearthSpellsNotCooldown)]
		return ChosenHearth
	elseif  #hearthSpellsFastestCooldown > 0 then
		ChosenHearth =  hearthSpellsFastestCooldown[math.random(#hearthSpellsFastestCooldown)]
		return ChosenHearth
	else
		return nil
	end
end

local function FindValidSpells()
	local validSpells = {}

	for index, spell in ipairs(TeleporterSpells) do
		local spellId = spell.spellId
		local spellType = spell.spellType
		local isItem = spell:IsItem()
		local spellName = spell.spellName
		local isValidSpell = true
		local zone = spell:GetZone()

		spell.displayDestination = zone
		if zone == TeleporterHearthString or zone == TeleporterRecallString then
			local bindLocation = GetBindLocation()
			if bindLocation then
				spell.displayDestination = "Hearth (" .. bindLocation .. ")"
			else
				spell.displayDestination = "Hearth"
			end
		end

		if zone == TeleporterFlightString then
			spell.displayDestination = MINIMAP_TRACKING_FLIGHTMASTER
		end

		if spell:IsDungeonSpell() and GetOption("groupDungeons") then
			spell.displayDestination = DungeonsTitle
		end

		if isItem then
			_, _, _, _, _, _, _, _, _, spell.itemTexture = GetCachedItemInfo( spellId )
			if not spellName then
				isValidSpell = false
			end
		else
			if C_Spell and C_Spell.GetSpellInfo then
				spell.itemTexture = C_Spell.GetSpellInfo(spellId).iconID
			else
				_,_,spell.itemTexture = GetSpellInfo( spellId )
			end
			if not spellName then
				isValidSpell = false
			end
		end

		local haveSpell = isValidSpell and spell:CanUse()

		spell.toySpell = nil
		if isItem then
			if C_ToyBox and PlayerHasToy(spellId) then
				spell.toySpell = GetItemSpell(spellId)
			end
		end

		if haveSpell then
			tinsert(validSpells, spell)
		end
	end

	return validSpells
end

function TeleporterSortSpells()
	local SortType = GetOption("sort")
	if CustomizeSpells then
		SortType = SortCustom
	end
	table.sort(TeleporterSpells, function(a,b) return SortSpells(a, b, SortType) end)
end

function TeleporterOpenFrame(isSearching)
	if UnitAffectingCombat("player") then
		print( "Cannot use " .. AddonTitle .. " while in combat." )
		return
	end

	InitalizeOptions()

	if not IsVisible or isSearching then
		local buttonHeight = GetScaledOption("buttonHeight")
		local buttonWidth = GetScaledOption("buttonWidth")
		local labelHeight = GetScaledOption("labelHeight")
		local numColumns = 1
		local lastDest = nil
		local maximumHeight = GetMaximumHeight()
		local fontHeight = GetScaledOption("fontHeight")
		local frameEdgeSize = GetOption("frameEdgeSize")
		local fontFile = GetOption("buttonFont")
		local fontFlags = nil
		local titleWidth = GetScaledOption("titleWidth")
		local titleHeight = GetScaledOption("titleHeight")
		local buttonInset = GetOption("buttonInset")

		local _,_,_,version = GetBuildInfo()

		IsVisible = true

		if not IsRefreshing then
			ChosenHearth = nil
		end

		if TeleporterParentFrame == nil then
			CreateMainFrame()
		end

		if GetOption("showTitle")then
			TeleporterTitleFrame:Show()
		else
			TeleporterTitleFrame:Hide()
		end

		TeleporterParentFrame.backdropInfo =
			{bgFile = GetOption("background"),
			edgeFile = GetOption("edge"),
			tile = false, edgeSize = frameEdgeSize,
			insets = { left = buttonInset, right = buttonInset, top = buttonInset, bottom = buttonInset }};
		TeleporterParentFrame:ApplyBackdrop();
		TeleporterParentFrame:SetBackdropColor(
				GetOption("backgroundR"),
				GetOption("backgroundG"),
				GetOption("backgroundB"),
				GetOption("backgroundA"))

		-- UI scale may have changed, resize
		TeleporterCloseButton:SetWidth( buttonHeight )
		TeleporterCloseButton:SetHeight( buttonHeight )
		TeleporterCloseButtonText:SetFont(fontFile, fontHeight, fontFlags)
		TeleporterSearchBox:SetHeight(buttonHeight)

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

		local searchString = TeleporterGetSearchString()
		if GetOption("showSearch") then
			TeleporterSearchBox:Show()
			minyoffset = -2 * buttonInset - TeleporterSearchBox:GetHeight()
			maximumHeight = maximumHeight + TeleporterSearchBox:GetHeight() - buttonInset
		else
			TeleporterSearchBox:Hide()
		end

		local yoffset = minyoffset
		local maxyoffset = -yoffset
		local xoffset = buttonInset

		ButtonSettings = {}

		if not SetupSpells() then
			NeedUpdate = true
			OpenTime = GetTime()
		end

		TeleporterSortSpells()

		local validSpells = FindValidSpells()

		local onlyHearth = GetRandomHearth(validSpells)

		local ShowDungeonNames = GetOption("showDungeonNames")

		local spellIndex = 1

		for index, spell in ipairs(validSpells) do
			local spellId = spell.spellId
			local spellType = spell.spellType
			local isItem = spell:IsItem()
			local destination = spell.displayDestination
			local consumable = spell.consumable
			local spellName = spell.spellName
			local displaySpellName = spell:CleanupName(spellName, spellType)
			local itemTexture = spell.itemTexture
			local toySpell = spell.toySpell

			local haveSpell = true
			if spell:GetZone() == TeleporterHearthString and GetOption("randomHearth") then
				if spellId ~= onlyHearth and not CustomizeSpells then
					haveSpell = false
				end
			end

			if searchString and searchString ~= "" then
				if not spell:MatchesSearch(searchString) then
					haveSpell = false
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

				if spell:IsDungeonSpell() and ShowDungeonNames and spell.dungeon then
					displaySpellName = spell.dungeon
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
				local buttonFrame = TeleporterCreateReusableFrame("Button","TeleporterB",TeleporterParentFrame,"InsecureActionButtonTemplate")
				--buttonFrame:SetFrameStrata("MEDIUM")
				buttonFrame:SetWidth(buttonWidth)
				buttonFrame:SetHeight(buttonHeight)
				buttonFrame:SetPoint("TOPLEFT",TeleporterParentFrame,"TOPLEFT",xoffset,yoffset)
				if version >= 100000 then
					buttonFrame:RegisterForClicks("LeftButtonUp", "LeftButtonDown")
				end
				yoffset = yoffset - buttonHeight

				buttonFrame.backdrop = TeleporterCreateReusableFrame("Frame","TeleporterBD", buttonFrame,"BackdropTemplate")
				buttonFrame.backdrop:SetPoint("TOPLEFT",buttonFrame,"TOPLEFT",0,0)
				buttonFrame.backdrop:SetPoint("BOTTOMRIGHT",buttonFrame,"BOTTOMRIGHT",0,0)

				local buttonBorder = 4 * GetScale()

				buttonFrame.backdrop.backdropInfo =
					{bgFile = GetOption("buttonBackground"),
					edgeFile = GetOption("buttonEdge"),
					tile = true, tileSize = GetOption("buttonTileSize"),
					edgeSize = GetScaledOption("buttonEdgeSize"),
					insets = { left = buttonBorder, right = buttonBorder, top = buttonBorder, bottom = buttonBorder }}
				buttonFrame.backdrop:ApplyBackdrop();

				buttonFrame:SetAttribute("type", "macro")
				buttonFrame:Show()

				if isItem then
					buttonFrame:SetScript(
						"OnEnter",
						function()
							TeleporterShowItemTooltip( spellId, buttonFrame )
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
					teleicon = buttonFrame.backdrop:CreateTexture()
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
				local cooldownbar = TeleporterCreateReusableFrame( "Frame", "TeleporterCB", buttonFrame.backdrop, "BackdropTemplate" )
				--cooldownbar:SetFrameStrata("MEDIUM")
				cooldownbar:SetWidth(64)
				cooldownbar:SetHeight(buttonHeight)
				cooldownbar:SetPoint("TOPLEFT",buttonFrame,"TOPLEFT",0,0)
				local cdOffset = GetOption("cooldownBarInset")
				cooldownbar.backdropInfo = {bgFile = "Interface/Tooltips/UI-Tooltip-Background",insets = { left = cdOffset, right = cdOffset, top = cdOffset - 1, bottom = cdOffset - 1 }}
				cooldownbar:ApplyBackdrop()

				-- Cooldown label
				local cooldownString = TeleporterCreateReusableFontString("TeleporterCL", cooldownbar, "GameFontNormalSmall")
				cooldownString:SetFont(fontFile, fontHeight, fontFlags)
				cooldownString:SetJustifyH("RIGHT")
				cooldownString:SetJustifyV("MIDDLE")
				cooldownString:SetPoint("TOPLEFT",buttonFrame,"TOPRIGHT",-50,-buttonInset - 2)
				cooldownString:SetPoint("BOTTOMRIGHT",buttonFrame,"BOTTOMRIGHT",-buttonInset - 2,6)

				-- Name label
				local nameString = TeleporterCreateReusableFontString("TeleporterSNL", cooldownbar, "GameFontNormalSmall")
				nameString:SetFont(fontFile, fontHeight, fontFlags)
				nameString:SetJustifyH("LEFT")
				nameString:SetJustifyV("MIDDLE")
				nameString:SetPoint("TOPLEFT", teleicon, "TOPRIGHT", 2, 0)
				if CustomizeSpells then
					nameString:SetPoint("BOTTOMRIGHT",cooldownString,"BOTTOMLEFT",-iconW * 4,0)
				else
					nameString:SetPoint("RIGHT",cooldownString,"LEFT",0,0)
					nameString:SetPoint("BOTTOM",teleicon,"BOTTOM",0,0)
				end
				nameString:SetText( displaySpellName )

				-- Count label
				local countString = nil
				if consumable then
					countString = TeleporterCreateReusableFontString("TeleporterCT", cooldownbar, "SystemFont_Outline_Small")
					countString:SetJustifyH("RIGHT")
					countString:SetJustifyV("MIDDLE")
					countString:SetPoint("TOPLEFT",cooldownbar,"TOPLEFT",iconOffsetX,iconOffsetY)
					countString:SetPoint("BOTTOMRIGHT", cooldownbar, "TOPLEFT", iconOffsetX + iconW, iconOffsetY - iconH - 2)
					countString:SetText("")
				end

				if -yoffset > maxyoffset then
					maxyoffset = -yoffset
				end

				RemoveIconOffset = -iconOffsetX - iconW * 3
				ShowIconOffset = -iconOffsetX - iconW * 2
				SortUpIconOffset = -iconOffsetX - iconW
				SortDownIconOffset = -iconOffsetX

				buttonFrame.RemoveIcon = AddCustomizationIcon(buttonFrame.RemoveIcon, buttonFrame, cooldownbar, RemoveIconOffset, iconOffsetY, iconW, iconH, "removeButtonIcon", function() OnClickRemove(spell) end, not spell.isCustom)
				buttonFrame.ShowIcon = AddCustomizationIcon(buttonFrame.ShowIcon, buttonFrame, cooldownbar, ShowIconOffset, iconOffsetY, iconW, iconH, "showButtonIcon", function() OnClickShow(spell) end)
				buttonFrame.SortUpIcon = AddCustomizationIcon(buttonFrame.SortUpIcon, buttonFrame, cooldownbar, SortUpIconOffset, iconOffsetY, iconW, iconH, "sortUpIcon", function() OnClickSortUp(spell) end)
				buttonFrame.SortDownIcon = AddCustomizationIcon(buttonFrame.SortDownIcon, buttonFrame, cooldownbar, SortDownIconOffset, iconOffsetY, iconW, iconH, "sortDownIcon", function() OnClickSortDown(spell) end)

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
				buttonSetting.frame = buttonFrame
				buttonSetting.displaySpellName = displaySpellName
				ButtonSettings[buttonFrame] = buttonSetting
				OrderedButtonSettings[spellIndex] = buttonSetting
				spellIndex = spellIndex + 1
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
	--if IsVisible and UnitAffectingCombat("player") then
	--	print( "Sorry, cannot close " .. AddonTitle .. " while in combat." )
	--else
		if TeleporterParentFrame then
			TeleporterParentFrame:Hide()
			IsVisible = false
		end
		if TeleporterQuickMenuFrame then
			TeleporterQuickMenuFrame:Hide()
		end
	--end
end

local function CacheItems()
	TomeOfTele_DevCache = {}
	for index, spell in ipairs(TeleporterSpells) do
		if spell:IsItem() then
			local item = Item:CreateFromItemID(spell.spellId)
			item:ContinueOnItemLoad(function()
				TomeOfTele_DevCache[spell.spellId] = {GetItemInfo(spell.spellId)}
			end)
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
		TomeOfTele_IconGlobal.hide = false
		icon:Show("TomeTeleGlobal")
	elseif splitArgs[1] == "hideicon" then
		TomeOfTele_IconGlobal.hide = true
		icon:Hide("TomeTeleGlobal")
	elseif splitArgs[1] == "set" then
		SetOption(splitArgs[2], splitArgs[3])
	elseif splitArgs[1] == "setnum" then
		SetOption(splitArgs[2], tonumber(splitArgs[3]))
	elseif splitArgs[1] == "cache" then
		CacheItems()
	elseif splitArgs[1] == "debug" then
		TeleporterDebugMode = 1
	elseif splitArgs[1] == "debugunsupported" then
		DebugUnsupported = 1
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
		for slotIdx = 1, C_Container.GetContainerNumSlots(bagIdx), 1 do
			local itemInBag = C_Container.GetContainerItemID(bagIdx, slotIdx)
			if itemInBag then
				local bagItemName = GetCachedItemInfo(itemInBag)
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
			PutItemInBag(inBag + 30)
		end
	end
end

-- This function exists because of a bug in patch 10.2.6 that has now been fixed.
local function SafeEquipItemByName(item, slot)
	EquipItemByName(item, slot)
end

local function SaveItem(itemSlot, item)
	local OldItem = GetInventoryItemID( "player", itemSlot )
	if OldItem then
		OldItems[ itemSlot ] = OldItem
		RemoveItem[itemSlot] = function(newItem)
			SafeEquipItemByName( newItem, itemSlot )
		end
	else
		PrepareUnequippedSlot(item, itemSlot)
	end
end

function TeleporterEquipSlashCmdFunction( item )
	CastSpell = nil

	if not IsEquippedItem ( item ) then
		if IsEquippableItem( item ) then
			local _, _, _, _, _, _, _, _,itemEquipLoc = GetCachedItemInfo(item)
			local itemSlot = InvTypeToSlot[ itemEquipLoc ]
			if itemSlot == nil then
				print( "Unrecognised equipable item type: " .. itemEquipLoc )
				return
			end
			SaveItem(itemSlot, item)
			if itemEquipLoc == "INVTYPE_2HWEAPON" then
				-- Also need to save offhand
				SaveItem(17, nil)
			end
			SafeEquipItemByName( item, itemSlot )
		end
	end
end

local function DoCast(spell, closeFrame)
	CastSpell = spell
	TeleHideQuickMenu()
	if closeFrame and not GetOption("closeAfterCast") then
		TeleporterClose()
	end
end

function TeleporterUseItemSlashCmdFunction( item )
	local spell = GetItemSpell( item )
	-- Can't close the window immediately for equippable items, as closing unequips.
	local equippable = IsEquippableItem(item)
	DoCast( spell, not equippable )
end

function TeleporterCastSpellSlashCmdFunction( spell, closeFrame )
	DoCast(spell, true)
end

function TeleporterCreateMacroSlashCmdFunction( spell )
	if spell then
		local macro
		local printEquipInfo = false

		if GetCachedItemInfo( spell ) then
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
	if TomeOfTele_IconGlobal == nil then
		TomeOfTele_IconGlobal = {}
	end

	icon:Register("TomeTeleGlobal", dataobj, TomeOfTele_IconGlobal)

	RebuildSpellList()

	for index, spell in ipairs(TeleporterSpells) do
		local spellId = spell.spellId
		local spellType = spell.spellType
		local isItem = spell:IsItem()
		if isItem and C_ToyBox then
			-- Query this early so it will be ready when we need it.
			C_ToyBox.IsToyUsable(spellId)
		end
	end
end

function Teleporter_OnUpdate()
	if IsVisible then
		-- The first time the UI is opened toy ownership may be incorrect. Reopen once it's correct.
		if NeedUpdate then
			-- If it's still wrong then will try again later.
			if GetTime() > OpenTime + 0.5 then
				NeedUpdate = false
				Refresh()
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
	if not IsRefreshing then
		TeleporterRestoreEquipment()
	end
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
end

function TeleporterAddTheme(name, theme)
	Themes[name] = theme
end

function TeleporterIsUnsupportedItem(spell)
	return false
end

function TeleporterCanUseCovenantHearthstone(covenant)
	return function()
		return (C_Covenants and C_Covenants.GetActiveCovenantID() == covenant) or not GetOption("randomHearth")  or GetOption("allCovenants")
	end
end

function TeleporterGetThemes()
	return Themes
end

function TeleporterGetSpells()
	SetupSpells()
	TeleporterSortSpells()
	return TeleporterSpells
end

--------
-- Functions used by tests
function TeleporterTest_GetButtonSettings()
	return OrderedButtonSettings
end

function TeleporterTest_GetButtonSettingsFromFrame(button)
	return ButtonSettings[button]
end

function TeleporterTest_GetButtonSettingsFromId(id, isItem)
	for frame, button in pairs(ButtonSettings) do
		if button.spell:IsItem() == isItem and button.spellId == id then
			return button
		end
	end
end

function TeleporterTest_GetButtonSettingsFromItemId(id)
	return TeleporterTest_GetButtonSettingsFromId(id, true)
end

function TeleporterTest_GetButtonSettingsFromSpellId(id)
	return TeleporterTest_GetButtonSettingsFromId(id, false)
end

function TeleporterTest_Reset()
	TeleporterParentFrame = nil
	CastSpell = nil
	ItemSlot = nil
	OldItems = {}
	RemoveItem = {}
	ButtonSettings = {}
	OrderedButtonSettings = {}
	IsVisible = false
	NeedUpdate = false
	OpenTime = 0
	ShouldNotBeEquiped = {}
	ShouldBeEquiped = {}
	EquipTime = 0
	CustomizeSpells = false
	RemoveIconOffset = 0
	ShowIconOffset = 0
	SortUpIconOffset = 0
	SortDownIconOffset = 0
	AddItemButton = nil
	AddSpellButton = nil
	TeleporterDebugMode = nil
	DebugUnsupported = nil
	ChosenHearth = nil
	IsRefreshing = nil
end
