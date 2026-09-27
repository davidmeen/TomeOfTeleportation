local TT = TomeOfTeleportation

local HomeTabGuid = "7413962B-DC60-4BAE-9922-B73FE07E42DE"
local FavouritesTabGuid = "A3E7B1C4-5F92-4D8A-B6E1-9C0F2D7A4E58"
local CurrentTab = HomeTabGuid
local Tabs = {}

function TomeOfTeleportation.GetHomeTabGuid()
	return HomeTabGuid
end

function TomeOfTeleportation.GetCurrentTab()
	return CurrentTab
end

function TomeOfTeleportation.SetCurrentTab(guid)
	CurrentTab = guid
end

function TomeOfTeleportation.GetCurrentTabSearchString()
	local tabList = TT.GetOption("tabs")
	if tabList and tabList[CurrentTab] then
		return tabList[CurrentTab].searchString
	end
	return nil
end

local function TabContextMenu_Rename(guid)
	local tabList = TT.GetOption("tabs")
	local currentName = (tabList and tabList[guid]) and tabList[guid].name or ""

	StaticPopupDialogs["TELEPORTER_RENAME_TAB"] = {
		text = "Rename tab",
		button1 = "OK",
		button2 = "Cancel",
		OnAccept = function(dialog)
			local updatedTabList = TT.GetOption("tabs")
			if updatedTabList and updatedTabList[guid] then
				updatedTabList[guid].name = dialog.EditBox:GetText()
				TT.SetOption("tabs", updatedTabList)
				TT.Refresh()
			end
		end,
		OnShow = function(dialog)
			dialog.EditBox:SetText(currentName)
			dialog.EditBox:SetFocus()
		end,
		hideOnEscape = true,
		hasEditBox = true,
		editBoxWidth = 300
	}
	StaticPopup_Show("TELEPORTER_RENAME_TAB")
end

local function TabContextMenu_Edit(guid)
	local tabList = TT.GetOption("tabs")
	local currentSearch = (tabList and tabList[guid]) and (tabList[guid].searchString or "") or ""

	StaticPopupDialogs["TELEPORTER_EDIT_TAB_SEARCH"] = {
		text = "Edit tab search string. See Readme.md for examples.",
		button1 = "OK",
		button2 = "Cancel",
		OnAccept = function(dialog)
			local updatedTabList = TT.GetOption("tabs")
			if updatedTabList and updatedTabList[guid] then
				updatedTabList[guid].searchString = dialog.EditBox:GetText()
				TT.SetOption("tabs", updatedTabList)
				TT.Refresh()
			end
		end,
		OnShow = function(dialog)
			dialog.EditBox:SetText(currentSearch)
			dialog.EditBox:SetFocus()
		end,
		hideOnEscape = true,
		hasEditBox = true,
		editBoxWidth = 300
	}
	StaticPopup_Show("TELEPORTER_EDIT_TAB_SEARCH")
end

local function TabContextMenu_Move(guid, direction)
	local tabList = TT.GetOption("tabs")
	if not tabList then return end

	local sortedTabs = {}
	for g, tabDesc in pairs(tabList) do
		tinsert(sortedTabs, {guid = g, tabDesc = tabDesc})
	end
	table.sort(sortedTabs, function(a, b)
		return (a.tabDesc.order or 0) < (b.tabDesc.order or 0)
	end)

	for i = math.max(1 - direction, 1), math.min(#sortedTabs - direction, #sortedTabs) do
		if sortedTabs[i].guid == guid then
			local temp = sortedTabs[i].tabDesc.order
			sortedTabs[i].tabDesc.order = sortedTabs[i + direction].tabDesc.order
			sortedTabs[i + direction].tabDesc.order = temp
			break
		end
	end

	TT.SetOption("tabs", tabList)
	TT.Refresh()
end

local function TabContextMenu_MoveLeft(guid)
	TabContextMenu_Move(guid, -1)
end

local function TabContextMenu_MoveRight(guid)
	TabContextMenu_Move(guid, 1)
end

local function TabContextMenu_Delete(guid, name)
	if guid == HomeTabGuid then
		return
	end

	StaticPopupDialogs["TELEPORTER_DELETE_TAB_CONFIRM"] = {
		text = "Delete the tab " .. (name or "") .. "?",
		button1 = "Yes",
		button2 = "No",
		OnAccept = function()
			local tabList = TT.GetOption("tabs")
			if tabList then
				tabList[guid] = nil
				TT.SetOption("tabs", tabList)
				if CurrentTab == guid then
					CurrentTab = HomeTabGuid
				end
				TT.Refresh()
			end
		end,
		hideOnEscape = true
	}
	StaticPopup_Show("TELEPORTER_DELETE_TAB_CONFIRM")
end

local function TabContextMenu_SetDefault(guid)
	TT.SetOption("defaultTab", guid)
end

local function TabContextMenu_Show(guid, name)
	local InitTabContextMenu = function(frame, level)
		local info = UIDropDownMenu_CreateInfo()
		info.owner = frame
		local isHomeTabGuid = (guid == HomeTabGuid)

		info.text = "Rename"
		info.func = function() TabContextMenu_Rename(guid) end
		info.disabled = isHomeTabGuid
		UIDropDownMenu_AddButton(info, level)

		info.text = "Edit"
		info.func = function() TabContextMenu_Edit(guid) end
		info.disabled = isHomeTabGuid
		UIDropDownMenu_AddButton(info, level)

		info.text = "Move Left"
		info.func = function() TabContextMenu_MoveLeft(guid) end
		info.disabled = false
		UIDropDownMenu_AddButton(info, level)

		info.text = "Move Right"
		info.func = function() TabContextMenu_MoveRight(guid) end
		info.disabled = false
		UIDropDownMenu_AddButton(info, level)

		info.text = "Set Default"
		info.func = function() TabContextMenu_SetDefault(guid) end
		info.disabled = false
		UIDropDownMenu_AddButton(info, level)

		info.text = "Delete Tab"
		info.func = function() TabContextMenu_Delete(guid, name) end
		info.disabled = isHomeTabGuid
		UIDropDownMenu_AddButton(info, level)
	end

	UIDropDownMenu_Initialize(TeleporterTabMenu, InitTabContextMenu, "MENU")
	ToggleDropDownMenu(1, nil, TeleporterTabMenu, "cursor", 0, 0)
end

local function GenerateGuid()
	local template = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
	return string.gsub(template, "x", function()
		return string.format("%x", math.random(0, 15))
	end)
end

local function GetMaxTabOrder()
	local tabList = TT.GetOption("tabs")
	local maxOrder = 0
	if tabList then
		for _, tabDesc in pairs(tabList) do
			if (tabDesc.order or 0) > maxOrder then
				maxOrder = tabDesc.order or 0
			end
		end
	end
	return maxOrder
end

function TomeOfTeleportation.EnsureFavouritesTab()
	local tabList = TT.GetOption("tabs")
	if tabList and tabList[FavouritesTabGuid] then
		return
	end
	if not tabList then
		tabList = {}
	end
	tabList[FavouritesTabGuid] = {
		["guid"] = FavouritesTabGuid,
		["name"] = "Favorites",
		["searchString"] = "type:favourite",
		["order"] = GetMaxTabOrder() + 1
	}
	TT.SetOption("tabs", tabList)
end

local function AddTabFromSearch()
	local searchString = TeleporterSearchBox:GetText()
	StaticPopupDialogs["TELEPORTER_ADD_TAB"] = {
		text = "Enter tab name",
		button1 = "OK",
		button2 = "Cancel",
		OnAccept = function(dialog)
			local name = dialog.EditBox:GetText()
			if name and name ~= "" then
				local guid = GenerateGuid()
				local tabList = TT.GetOption("tabs")
				if not tabList then
					tabList = {}
				end
				tabList[guid] = {
					["guid"] = guid,
					["name"] = name,
					["searchString"] = searchString,
					["order"] = GetMaxTabOrder() + 1
				}
				TT.SetOption("tabs", tabList)
				TeleporterSearchBox:SetText("")
				CurrentTab = guid
				TT.Refresh()
			end
		end,
		hideOnEscape = true,
		hasEditBox = true,
		editBoxWidth = 300
	}
	StaticPopup_Show("TELEPORTER_ADD_TAB")
end

local function SetupTabFrame(tabIndex, parentFrame, xOffset, yPadding, tabHeight, tabMaxWidth, scale, name, isSelected, onClick)
	if #Tabs < tabIndex then
		local newTab = {}
		newTab.frame = TT.CreateReusableFrame("Button","TabFrame",parentFrame, "BackdropTemplate")
		newTab.fontString = TT.CreateReusableFontString("TabText",newTab.frame, "GameFontNormalTiny")
		tinsert(Tabs, newTab)
	end

	local tab = Tabs[tabIndex]
	local button = tab.frame
	local label = tab.fontString

	button:ClearAllPoints()
	button:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMLEFT", xOffset, yPadding)
	button:SetWidth(tabMaxWidth)
	button:SetHeight(tabHeight)
	button:SetBackdrop({
		bgFile = "Interface/Buttons/WHITE8X8",
		edgeFile = "Interface/Buttons/WHITE8X8",
		edgeSize = 1,
		insets = {left = 1, right = 1, top = 1, bottom = 0}
	})

	local fontFile = label:GetFont()
	local tabFontSize = TT.GetOption("tabFontSize")
	label:SetFont(fontFile, tabFontSize * scale)
	label:ClearAllPoints()
	label:SetPoint("CENTER", button, "CENTER", 0, 0)
	label:SetText(name)
	label:SetWidth(tabMaxWidth - 4 * scale)
	label:SetHeight(tabHeight)
	label:SetWordWrap(false)
	label:Show()

	if isSelected then
		button:SetBackdropColor(TT.GetOption("tabSelectedColourR"), TT.GetOption("tabSelectedColourG"), TT.GetOption("tabSelectedColourB"), TT.GetOption("tabSelectedColourA"))
		button:SetBackdropBorderColor(TT.GetOption("tabSelectedBorderR"), TT.GetOption("tabSelectedBorderG"), TT.GetOption("tabSelectedBorderB"), TT.GetOption("tabSelectedBorderA"))
		label:SetTextColor(TT.GetOption("tabSelectedTextR"), TT.GetOption("tabSelectedTextG"), TT.GetOption("tabSelectedTextB"))
	else
		button:SetBackdropColor(TT.GetOption("tabUnselectedColourR"), TT.GetOption("tabUnselectedColourG"), TT.GetOption("tabUnselectedColourB"), TT.GetOption("tabUnselectedColourA"))
		button:SetBackdropBorderColor(TT.GetOption("tabUnselectedBorderR"), TT.GetOption("tabUnselectedBorderG"), TT.GetOption("tabUnselectedBorderB"), TT.GetOption("tabUnselectedBorderA"))
		label:SetTextColor(TT.GetOption("tabUnselectedTextR"), TT.GetOption("tabUnselectedTextG"), TT.GetOption("tabUnselectedTextB"))
	end

	button:EnableMouse(true)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:SetScript("OnClick", function(self, mouseButton)
		onClick(self, mouseButton)
	end)
	button:SetScript("OnEnter", function(self)
		if not isSelected then
			local hoverR = (TT.GetOption("tabSelectedColourR") + TT.GetOption("tabUnselectedColourR")) / 2
			local hoverG = (TT.GetOption("tabSelectedColourG") + TT.GetOption("tabUnselectedColourG")) / 2
			local hoverB = (TT.GetOption("tabSelectedColourB") + TT.GetOption("tabUnselectedColourB")) / 2
			local hoverA = (TT.GetOption("tabSelectedColourA") + TT.GetOption("tabUnselectedColourA")) / 2
			self:SetBackdropColor(hoverR, hoverG, hoverB, hoverA)
			local hoverTextR = (TT.GetOption("tabSelectedTextR") + TT.GetOption("tabUnselectedTextR")) / 2
			local hoverTextG = (TT.GetOption("tabSelectedTextG") + TT.GetOption("tabUnselectedTextG")) / 2
			local hoverTextB = (TT.GetOption("tabSelectedTextB") + TT.GetOption("tabUnselectedTextB")) / 2
			label:SetTextColor(hoverTextR, hoverTextG, hoverTextB)
		end
	end)
	button:SetScript("OnLeave", function(self)
		if not isSelected then
			self:SetBackdropColor(TT.GetOption("tabUnselectedColourR"), TT.GetOption("tabUnselectedColourG"), TT.GetOption("tabUnselectedColourB"), TT.GetOption("tabUnselectedColourA"))
			label:SetTextColor(TT.GetOption("tabUnselectedTextR"), TT.GetOption("tabUnselectedTextG"), TT.GetOption("tabUnselectedTextB"))
		end
	end)
	button:Show()

	return tabMaxWidth
end

local function HideTabsFrom(startIndex)
	for i = startIndex, #Tabs do
		Tabs[i].frame:Hide()
		Tabs[i].fontString:Hide()
	end
end

local function HasSearchText()
	return TeleporterSearchBox and TeleporterSearchBox:GetText() ~= ""
end

function TomeOfTeleportation.CreateTabs(parentFrame)
	Tabs = {}

	if TT.GetOption("showTabs") then
		local scale = TT.GetOption("scale") * UIParent:GetEffectiveScale()
		local tabIndex = 1
		local xOffset = 12 * scale
		local tabHeight = TT.GetOption("tabHeight") * scale
		local yPadding = 12 * scale
		local tabSpacing = 3 * scale

		if HasSearchText() then
			local parentWidth = parentFrame:GetWidth()
			local usableWidth = parentWidth - (xOffset * 2)

			SetupTabFrame(tabIndex, parentFrame, xOffset, yPadding, tabHeight, usableWidth, scale, "Add Tab", false,
				function(self, button)
					if button == "LeftButton" then
						AddTabFromSearch()
					end
				end)
			tabIndex = 2
		else
			local sortedTabs = {}
			for guid, tabDesc in pairs(TT.GetOption("tabs")) do
				tinsert(sortedTabs, {guid = guid, tabDesc = tabDesc})
			end
			table.sort(sortedTabs, function(a, b)
				return (a.tabDesc.order or 0) < (b.tabDesc.order or 0)
			end)

			if #sortedTabs == 1 and sortedTabs[1].guid == HomeTabGuid then
				HideTabsFrom(tabIndex)
				return
			end

			local parentWidth = parentFrame:GetWidth()
			local usableWidth = parentWidth - (xOffset * 2)
			local totalSpacing = tabSpacing * math.max(#sortedTabs - 1, 0)
			local tabMaxWidth = (usableWidth - totalSpacing) / #sortedTabs

			for _, tabEntry in ipairs(sortedTabs) do
				local tabDesc = tabEntry.tabDesc
				local guid = tabDesc.guid
				local name = tabDesc.name

				SetupTabFrame(tabIndex, parentFrame, xOffset, yPadding, tabHeight, tabMaxWidth, scale, name, tabDesc.guid == CurrentTab,
					function(self, button)
						if button == "LeftButton" then
							CurrentTab = guid
							TT.Refresh()
						elseif button == "RightButton" then
							TabContextMenu_Show(guid, name)
						end
					end)

				local tab = Tabs[tabIndex]
				tab.guid = tabDesc.guid
				tab.searchString = tabDesc.searchString

				xOffset = xOffset + tabMaxWidth + tabSpacing
				tabIndex = tabIndex + 1
			end
		end

		HideTabsFrom(tabIndex)
		parentFrame:SetHeight(parentFrame:GetHeight() + tabHeight + yPadding / 2)
	elseif Tabs then
		HideTabsFrom(1)
	end
end
