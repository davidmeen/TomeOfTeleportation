local AddonName = "TomeOfCustomisation"

-- Change any of these values. If they are nil, then the defaults are used 
-- (see DefaultOptions in TomeOfTeleportation.lua for the defaults).
-- All options must be in {} braces, for example:
-- ["titleHeight"] = {20},
-- You can add multiple themes, just add them in AddCustomisations() below.
local CustomTheme = 
{
	-- Size of each button.
	["buttonHeight"] = nil,
	["buttonWidth"] = nil,
	-- Height of the destination labels.
	["labelHeight"] = nil,
	-- Maximum height of the window. Once it reaches this height a new row will be started.
	["maximumHeight"] = nil,
	-- Height of the font used for all text.
	["fontHeight"] = nil,
	-- Distance between buttons and the edge of the window.
	["buttonInset"] = nil,
	-- If true then show the help text at the bottom of the window.
	["showHelp"] = nil,
	-- Background texture.
	["background"] = nil,
	-- Edge texture.
	["edge"] = nil,
	-- Background tint.
	["backgroundR"] = nil,
	["backgroundG"] = nil,
	["backgroundB"] = nil,
	["backgroundA"] = nil,
	-- Size of the window border.
	["frameEdgeSize"] = nil,
	-- If true show the title bar.
	["showTitle"] = nil,
	-- Texture for the title bar.
	["titleBackground"] = nil,
	-- Tile bar font.
	["titleFont"] = nil,
	-- Title bar size.
	["titleWidth"] = nil,
	["titleHeight"] = nil,
	-- Offset of title bar from the window.
	["titleOffset"] = nil,
	-- Font used by buttons.
	["buttonFont"] = nil,
	-- Button texture.
	["buttonBackground"] = nil,
	-- Button edge texture.
	["buttonEdge"] = nil,
	-- Size of the button edge texture.
	["buttonEdgeSize"] = nil,
	-- Size of the button texture.
	["buttonTileSize"] = nil,
	-- Colour of buttons that are ready to use.
	["readyColourR"] = nil,
	["readyColourG"] = nil,
	["readyColourB"] = nil,
	-- Colour of buttons for unequiped items.
	["unequipedColourR"] = nil,
	["unequipedColourG"] = nil,
	["unequipedColourB"] = nil,
	-- Colour of buttons for spells that are on cooldown.
	["cooldownColourR"] = nil,
	["cooldownColourG"] = nil,
	["cooldownColourB"] = nil
}

local function AddCustomisations()
	TeleporterAddTheme("Custom", CustomTheme)
	
	-- Add lines here for custom items. Use wowhead.com to find spell or item IDs.
	-- Example custom item http://www.wowhead.com/item=131933/critter-hand-cannon
	--TeleporterAddItem(131933, "Black Temple")
	-- Example custom spell  http://www.wowhead.com/spell=164862/flap
	--TeleporterAddSpell(164862, "Slightly above the ground")
end

function Teleporter_OnEvent(self, event, ...)
	if event == "ADDON_LOADED" then
		local loadedAddon = ...
		if string.upper(loadedAddon) == string.upper("TomeOfCustomisation") then
			AddCustomisations()			
		end	
	end
end
