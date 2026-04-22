local HomeTabGuid = "7413962B-DC60-4BAE-9922-B73FE07E42DE"
local CurrentTab = HomeTabGuid
local Tabs = {}

function TeleporterGetHomeTabGuid()
	return HomeTabGuid
end

function TeleporterGetCurrentTab()
	return CurrentTab
end

function TeleporterSetCurrentTab(guid)
	CurrentTab = guid
end

function TeleporterGetCurrentTabSearchString()
	local tabList = TeleporterGetOption("tabs")
	if tabList and tabList[CurrentTab] then
		return tabList[CurrentTab].searchString
	end
	return nil
end

local function TabContextMenu_Rename(guid)
	local tabList = TeleporterGetOption("tabs")
	local currentName = (tabList and tabList[guid]) and tabList[guid].name or ""

	StaticPopupDialogs["TELEPORTER_RENAME_TAB"] = {
		text = "Rename tab",
		button1 = "OK",
		button2 = "Cancel",
		OnAccept = function(dialog)
			local updatedTabList = TeleporterGetOption("tabs")
			if updatedTabList and updatedTabList[guid] then
				updatedTabList[guid].name = dialog.EditBox:GetText()
				TeleporterSetOption("tabs", updatedTabList)
				TeleporterRefresh()
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
	local tabList = TeleporterGetOption("tabs")
	local currentSearch = (tabList and tabList[guid]) and (tabList[guid].searchString or "") or ""

	StaticPopupDialogs["TELEPORTER_EDIT_TAB_SEARCH"] = {
		text = "Edit tab search string. See Readme.txt for examples.",
		button1 = "OK",
		button2 = "Cancel",
		OnAccept = function(dialog)
			local updatedTabList = TeleporterGetOption("tabs")
			if updatedTabList and updatedTabList[guid] then
				updatedTabList[guid].searchString = dialog.EditBox:GetText()
				TeleporterSetOption("tabs", updatedTabList)
				TeleporterRefresh()
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
	local tabList = TeleporterGetOption("tabs")
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

	TeleporterSetOption("tabs", tabList)
	TeleporterRefresh()
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
			local tabList = TeleporterGetOption("tabs")
			if tabList then
				tabList[guid] = nil
				TeleporterSetOption("tabs", tabList)
				if CurrentTab == guid then
					CurrentTab = HomeTabGuid
				end
				TeleporterRefresh()
			end
		end,
		hideOnEscape = true
	}
	StaticPopup_Show("TELEPORTER_DELETE_TAB_CONFIRM")
end

local function TabContextMenu_SetDefault(guid)
	TeleporterSetOption("defaultTab", guid)
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
	local tabList = TeleporterGetOption("tabs")
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
				local tabList = TeleporterGetOption("tabs")
				if not tabList then
					tabList = {}
				end
				tabList[guid] = {
					["guid"] = guid,
					["name"] = name,
					["searchString"] = searchString,
					["order"] = GetMaxTabOrder() + 1
				}
				TeleporterSetOption("tabs", tabList)
				TeleporterSearchBox:SetText("")
				CurrentTab = guid
				TeleporterRefresh()
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
		newTab.frame = TeleporterCreateReusableFrame("Button","TabFrame",parentFrame, "BackdropTemplate")
		newTab.fontString = TeleporterCreateReusableFontString("TabText",newTab.frame, "GameFontNormalTiny")
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
	local tabFontSize = TeleporterGetOption("tabFontSize")
	label:SetFont(fontFile, tabFontSize * scale)
	label:ClearAllPoints()
	label:SetPoint("CENTER", button, "CENTER", 0, 0)
	label:SetText(name)
	label:SetWidth(tabMaxWidth - 4 * scale)
	label:SetHeight(tabHeight)
	label:SetWordWrap(false)
	label:Show()

	if isSelected then
		button:SetBackdropColor(TeleporterGetOption("tabSelectedColourR"), TeleporterGetOption("tabSelectedColourG"), TeleporterGetOption("tabSelectedColourB"), TeleporterGetOption("tabSelectedColourA"))
		button:SetBackdropBorderColor(TeleporterGetOption("tabSelectedBorderR"), TeleporterGetOption("tabSelectedBorderG"), TeleporterGetOption("tabSelectedBorderB"), TeleporterGetOption("tabSelectedBorderA"))
		label:SetTextColor(TeleporterGetOption("tabSelectedTextR"), TeleporterGetOption("tabSelectedTextG"), TeleporterGetOption("tabSelectedTextB"))
	else
		button:SetBackdropColor(TeleporterGetOption("tabUnselectedColourR"), TeleporterGetOption("tabUnselectedColourG"), TeleporterGetOption("tabUnselectedColourB"), TeleporterGetOption("tabUnselectedColourA"))
		button:SetBackdropBorderColor(TeleporterGetOption("tabUnselectedBorderR"), TeleporterGetOption("tabUnselectedBorderG"), TeleporterGetOption("tabUnselectedBorderB"), TeleporterGetOption("tabUnselectedBorderA"))
		label:SetTextColor(TeleporterGetOption("tabUnselectedTextR"), TeleporterGetOption("tabUnselectedTextG"), TeleporterGetOption("tabUnselectedTextB"))
	end

	button:EnableMouse(true)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:SetScript("OnClick", function(self, mouseButton)
		onClick(self, mouseButton)
	end)
	button:SetScript("OnEnter", function(self)
		if not isSelected then
			local hoverR = (TeleporterGetOption("tabSelectedColourR") + TeleporterGetOption("tabUnselectedColourR")) / 2
			local hoverG = (TeleporterGetOption("tabSelectedColourG") + TeleporterGetOption("tabUnselectedColourG")) / 2
			local hoverB = (TeleporterGetOption("tabSelectedColourB") + TeleporterGetOption("tabUnselectedColourB")) / 2
			local hoverA = (TeleporterGetOption("tabSelectedColourA") + TeleporterGetOption("tabUnselectedColourA")) / 2
			self:SetBackdropColor(hoverR, hoverG, hoverB, hoverA)
			local hoverTextR = (TeleporterGetOption("tabSelectedTextR") + TeleporterGetOption("tabUnselectedTextR")) / 2
			local hoverTextG = (TeleporterGetOption("tabSelectedTextG") + TeleporterGetOption("tabUnselectedTextG")) / 2
			local hoverTextB = (TeleporterGetOption("tabSelectedTextB") + TeleporterGetOption("tabUnselectedTextB")) / 2
			label:SetTextColor(hoverTextR, hoverTextG, hoverTextB)
		end
	end)
	button:SetScript("OnLeave", function(self)
		if not isSelected then
			self:SetBackdropColor(TeleporterGetOption("tabUnselectedColourR"), TeleporterGetOption("tabUnselectedColourG"), TeleporterGetOption("tabUnselectedColourB"), TeleporterGetOption("tabUnselectedColourA"))
			label:SetTextColor(TeleporterGetOption("tabUnselectedTextR"), TeleporterGetOption("tabUnselectedTextG"), TeleporterGetOption("tabUnselectedTextB"))
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

function TeleporterCreateTabs(parentFrame)
	Tabs = {}

	if TeleporterGetOption("showTabs") then
		local scale = TeleporterGetOption("scale") * UIParent:GetEffectiveScale()
		local tabIndex = 1
		local xOffset = 12 * scale
		local tabHeight = TeleporterGetOption("tabHeight") * scale
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
			for guid, tabDesc in pairs(TeleporterGetOption("tabs")) do
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
							TeleporterRefresh()
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
