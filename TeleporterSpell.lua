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

	if not CustomizeSpells and not spell:IsVisible() then
		haveSpell = false
	end

	return haveSpell
end

function TeleporterSpell:GetZone()
	local zo = TeleporterGetOption("zoneOverrides") or {}
	return zo[self:GetOptionId()] or self.zone
end

function TeleporterSpell:SetZone(zone)
	self.zone = zone
end

function TeleporterSpell:OverrideZoneName(zone)
	local zo = TeleporterGetOption("zoneOverrides") or {}
	if zone == "" then
		zone = nil
	end
	zo[self:GetOptionId()] = zone
	TeleporterSetOption("zoneOverrides", zo)
end


-- dungeonID from: https://wowpedia.fandom.com/wiki/LfgDungeonID#Retail
function TeleporterSpell:IsSeasonDungeon()
	-- Dragonflight Season 4
	return tContains({
		2335,	-- The Azure Vault
		2367,	-- Algeth'ar Academy
		2378,	-- The Nokhud Offensive
		2376,	-- Ruby Life Pools
		2359,	-- Neltharus
		2382,	-- Halls of Infusion
		2380,	-- Brackenhide Hollow
		2355,	-- Uldaman: Legacy of Tyr
		2405,	-- Aberrus
		2388,	-- Vault of the Incarnates
		2502,	-- Amirdrassil
	}, self.dungeonID)
end

-- Spell factories
function TeleporterCreateSpell(id, dest)
	local spell = {}
    setmetatable(spell, {__index=TeleporterSpell})
	spell.spellId = id
	spell.spellType = ST_Spell
	spell.zone = dest
	return spell
end

function TeleporterCreateItem(id, dest)
	local spell = {}
    setmetatable(spell, {__index=TeleporterSpell})
	spell.spellId = id
	spell.spellType = ST_Item
	spell.zone = dest
	return spell
end

-- dungeonID from: https://wowpedia.fandom.com/wiki/LfgDungeonID#Retail
function TeleporterCreateChallengeSpell(id, dungeonID)
	local spell = {}
    setmetatable(spell, {__index=TeleporterSpell})
	spell.spellId = id
	spell.dungeonID = dungeonID
	spell.spellType = ST_Challenge
	spell.dungeon = GetLFGDungeonInfo(dungeonID)
	return spell
end

function TeleporterCreateConditionalItem(id, condition, dest)
	local spell = {}
    setmetatable(spell, {__index=TeleporterSpell})
	spell.spellId = id
	spell.spellType = ST_Item
	spell.condition = condition
	spell.zone = dest
	return spell
end

function TeleporterCreateConditionalSpell(id, condition, dest)
	local spell = {}
    setmetatable(spell, {__index=TeleporterSpell})
	spell.spellId = id
	spell.spellType = ST_Spell
	spell.condition = condition
	spell.zone = dest
	return spell
end

function TeleporterCreateConditionalConsumable(id, condition, dest)
	local spell = {}
    setmetatable(spell, {__index=TeleporterSpell})
	spell.spellId = id
	spell.spellType = ST_Item
	spell.condition = condition
	spell.zone = dest
	spell.consumable = true
	return spell
end

function TeleporterCreateConsumable(id, dest)
	local spell = {}
    setmetatable(spell, {__index=TeleporterSpell})
	spell.spellId = id
	spell.spellType = ST_Item
	spell.zone = dest
	spell.consumable = true
	return spell
end
