local ST_Item = 1
local ST_Spell = 2
local ST_Challenge = 3


-- I'm not going to attempt any prefixes with different character sets. I may have missed some variations.
-- Some of these are odd - inconsistent translations in-game?
local RedundantStrings =
{
	-- German
	"Pfad der ",
	"Pfad des ",
	-- English
	"Path of the ",
	"Path of ",
	-- Spanish
	"Camino de los  ",
	"Senda de las ",
	"Senda de los ",
	"Senda del ",
	"Senda de ",
	-- French
	"Chemin du ",
	"Voie de ",
	"Voie des ",
	"Voie du ",
	-- Italian
	"Sentiero del ",
	"Via degli ",
	"Via dei ",
	"Via del ",
	"Via dell'",
	-- Brazilian Portugese
	"Caminho da ",
	"Caminho do ",
	"Caminho dos ",
	-- Simplified Chinese
	"之路",
	-- Traditional Chinese
	"之路",
	"之道",
	"之徑",
	-- Korean
	" 길",
}

local TeleporterSpell = {}

function TeleporterSpell:IsItem()
    return self.spellType == ST_Item
end

function TeleporterSpell:IsSpell()
    return self.spellType == ST_Spell
end

function TeleporterSpell:IsDungeonSpell()
    return self.spellType == ST_Challenge
end

function TeleporterSpell:CleanupName()
	local hide = TeleporterGetOption("conciseDungeonSpells")
    local name = self.spellName
	if hide and hide ~= "0" and self:IsDungeonSpell() then
		for index, str in pairs(RedundantStrings) do
			name = name: gsub(str, "")
		end
	end
	return name
end

function TeleporterSpell:GetOptionId()
	-- Must use the original zone name here.
	return self.spellId .. "." .. self.zone
end


function TeleporterSpell:IsVisible()
	local showSpells = TeleporterGetOption("showSpells")
	local visible = showSpells[self:GetOptionId()]
	if visible ~= nil then
		return visible
	else
		return true
	end
end

function TeleporterSpell:IsAlwaysVisible()
	local showSpells = TeleporterGetOption("alwaysShowSpells")
	if not showSpells then
		return false
	end
	local visible = showSpells[self:GetOptionId()]
	if visible ~= nil then
		return visible
	else
		return false
	end
end


 function TeleporterSpell:SetVisible()
	local showSpells = TeleporterGetOption("showSpells")
	local alwaysShowSpells = TeleporterGetOption("alwaysShowSpells")

	if not showSpells then showSpells = {} end
	if not alwaysShowSpells then alwaysShowSpells = {} end

	showSpells[self:GetOptionId()] = true
	alwaysShowSpells[self:GetOptionId()] = false

	TeleporterSetOption("showSpells", showSpells)
	TeleporterSetOption("alwaysShowSpells", alwaysShowSpells)
end

 function TeleporterSpell:SetAlwaysVisible()
	local showSpells = TeleporterGetOption("showSpells")
	local alwaysShowSpells = TeleporterGetOption("alwaysShowSpells")

	if not showSpells then showSpells = {} end
	if not alwaysShowSpells then alwaysShowSpells = {} end

	showSpells[self:GetOptionId()] = true
	alwaysShowSpells[self:GetOptionId()] = true

	TeleporterSetOption("showSpells", showSpells)
	TeleporterSetOption("alwaysShowSpells", alwaysShowSpells)
end

 function TeleporterSpell:SetHidden()
	local showSpells = TeleporterGetOption("showSpells")
	local alwaysShowSpells = TeleporterGetOption("alwaysShowSpells")

	if not showSpells then showSpells = {} end
	if not alwaysShowSpells then alwaysShowSpells = {} end

	showSpells[self:GetOptionId()] = false
	alwaysShowSpells[self:GetOptionId()] = false

	TeleporterSetOption("showSpells", showSpells)
	TeleporterSetOption("alwaysShowSpells", alwaysShowSpells)
end

function TeleporterSpell:CanUse()
    local spell = self
	local spellId = spell.spellId
	local spellType = spell.spellType
	local isItem = spell:IsItem()
	local condition = spell.condition
	local consumable = spell.consumable
	local itemTexture = nil

	if spell:IsAlwaysVisible() then
		return true
	end

	local haveSpell = false
	local haveToy = false
	local toyUsable =  false
	if C_ToyBox then
		toyUsable = C_ToyBox.IsToyUsable(spellId)
	end
	-- C_ToyBox.IsToyUsable returns nil if the toy hasn't been loaded yet.
	if toyUsable == nil then
		toyUsable = true
	end
	if isItem then
		if toyUsable then
			haveToy = PlayerHasToy(spellId) and toyUsable
		end
		haveSpell = GetItemCount( spellId ) > 0 or haveToy
	else
		haveSpell = IsSpellKnown( spellId )
	end

	if condition and not CustomizeSpells then
		if not condition() then
			haveSpell = false
		end
	end

	if TeleporterDebugMode then
		haveSpell = true
	end

	if not TeleporterGetSearchString() or not TeleporterGetOption("searchHidden") then

		if TeleporterGetOption("hideItems") and isItem then
			haveSpell = false
		end

		if TeleporterGetOption("hideConsumable") and consumable then
			haveSpell = false
		end

		if TeleporterGetOption("hideSpells") and spell:IsSpell() then
			haveSpell = false
		end

		if TeleporterGetOption("hideChallenge") and spell:IsDungeonSpell() then
			haveSpell = false
		end

		if TeleporterGetOption("seasonOnly") and spell:IsDungeonSpell() and not self:IsSeasonDungeon() then
			haveSpell = false
		end
	end

	if not CustomizeSpells and not spell:IsVisible() then
		haveSpell = false
	end

	return haveSpell
end

function TeleporterSpell:GetZone()
	local zo = TeleporterGetOption("zoneOverrides") or {}
	return zo[self:GetOptionId()] or self.zone
end

function TeleporterSpell:AddZoneAndParents(mapID)
	if not self.parentZones then
		self.parentZones = {}
	end

	while mapID ~= 0 do
		local mapInfo = C_Map.GetMapInfo(mapID)
		if mapInfo then
			tinsert(self.parentZones, string.lower(mapInfo.name))
			mapID = mapInfo.parentMapID
		else
			mapID = 0
		end
	end
end

function TeleporterSpell:SetZone(zone, mapID)
	self.zone = zone
	if mapID then
		local mapInfo = C_Map.GetMapInfo(mapID)
		if mapInfo then
			local parentMapID = mapInfo.parentMapID
			self:AddZoneAndParents(parentMapID)
		end
	end
end

function TeleporterSpell:OverrideZoneName(zone)
	local zo = TeleporterGetOption("zoneOverrides") or {}
	if zone == "" then
		zone = nil
	end
	zo[self:GetOptionId()] = zone
	TeleporterSetOption("zoneOverrides", zo)
end

function TeleporterSpell:Equals(other)
	return ""..self.spellId == ""..other.spellId and self.spellType == other.spellType
end

function TeleporterSpell:MatchesSearch(searchString)
	local searchLower = string.lower(searchString)

	if self.dungeon then
		if string.find(string.lower(self.dungeon), searchLower) then
			return true
		end
	end

	if self.parentZones then
		for i, parentZone in ipairs(self.parentZones) do
			if string.find(parentZone, searchLower) then
				return true
			end
		end
	end

	return string.find(string.lower(self.spellName), searchLower) or string.find(string.lower(self.zone), searchLower)
end

-- dungeonID from: https://warcraft.wiki.gg/wiki/LfgDungeonID, or using GetLFGDungeonInfo().
function TeleporterSpell:IsSeasonDungeon()
	-- Dragonflight Season 4
	return tContains({
		2654,	-- Ara-Kara, City of Echoes
		2652,	-- City of Threads
		2693,	-- The Stonevault
		2719,	-- The Dawnbreaker
		2120,	-- Mists of Tirna Scithe
		2123,	-- The Necrotic Wake
		1700,	-- Siege of Boralus
		304,	-- Grim Batol
	}, self.dungeonID)
end

-- Spell factories
function TeleporterCreateSpell(id, dest)
	local spell = {}
    TeleporterInitSpell(spell)
	spell.spellId = id
	spell.spellType = ST_Spell
	spell.zone = dest
	return spell
end

function TeleporterCreateItem(id, dest)
	local spell = {}
    TeleporterInitSpell(spell)
	spell.spellId = id
	spell.spellType = ST_Item
	spell.zone = dest
	return spell
end

-- dungeonID from: https://warcraft.wiki.gg/wiki/LfgDungeonID
function TeleporterCreateChallengeSpell(id, dungeonID, mapID)
	local spell = {}
	TeleporterInitSpell(spell)
	spell.spellId = id
	spell.dungeonID = dungeonID
	spell.spellType = ST_Challenge
	spell.dungeon = GetLFGDungeonInfo(dungeonID)

	if mapID then
		spell:AddZoneAndParents(mapID)
	else
		print("Missing mapID for " .. spell.dungeon)
		for i = 1,3000 do
			--local name, description, bgImage, buttonImage1, loreImage, buttonImage2, dungeonAreaMapID, link, shouldDisplayDifficulty, mapID = EJ_GetInstanceInfo(i)
			local mapInfo = C_Map.GetMapInfo(i)
			if mapInfo and mapInfo.name == spell.dungeon then
				while mapInfo.parentMapID ~= 0 do
					print(mapInfo.mapID, mapInfo.name)
					mapInfo = C_Map.GetMapInfo(mapInfo.parentMapID)
				end
			end
		end
		print("----")
	end

	return spell
end

function TeleporterCreateConditionalItem(id, condition, dest)
	local spell = {}
    TeleporterInitSpell(spell)
	spell.spellId = id
	spell.spellType = ST_Item
	spell.condition = condition
	spell.zone = dest
	return spell
end

function TeleporterCreateConditionalSpell(id, condition, dest)
	local spell = {}
    TeleporterInitSpell(spell)
	spell.spellId = id
	spell.spellType = ST_Spell
	spell.condition = condition
	spell.zone = dest
	return spell
end

function TeleporterCreateConditionalConsumable(id, condition, dest)
	local spell = {}
    TeleporterInitSpell(spell)
	spell.spellId = id
	spell.spellType = ST_Item
	spell.condition = condition
	spell.zone = dest
	spell.consumable = true
	return spell
end

function TeleporterCreateConsumable(id, dest)
	local spell = {}
    TeleporterInitSpell(spell)
	spell.spellId = id
	spell.spellType = ST_Item
	spell.zone = dest
	spell.consumable = true
	return spell
end

function TeleporterInitSpell(spell)
	setmetatable(spell, {__index=TeleporterSpell})
end
