TomeOfTeleportation = {}

-- Wrappers to support Classic and retail.
function TomeOfTeleportation.TeleporterIsEquippableItem(...)
	if C_Item then
		return C_Item.IsEquippableItem(...)
	else
		return IsEquippableItem(...)
	end
end

function TomeOfTeleportation.GetItemSpell(...)
	if C_Item then
		return C_Item.GetItemSpell(...)
	else
		return GetItemSpell(...)
	end
end

function TomeOfTeleportation.GetItemCount(...)
	if C_Item then
		return C_Item.GetItemCount(...)
	else
		return GetItemCount(...)
	end
end

function TomeOfTeleportation.GetItemInfo(...)
	if C_Item then
		return C_Item.GetItemInfo(...)
	else
		return GetItemInfo(...)
	end
end