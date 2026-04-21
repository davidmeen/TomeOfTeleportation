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
	for _, tab in pairs(Tabs) do
		if tab.guid == CurrentTab then
			return tab.searchString
		end
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
		text = "Edit tab search string",
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

function TeleporterCreateTabs(parentFrame)
	if TeleporterGetOption("showTabs") then
		local tabIndex = 1
		local xOffset = 8
		local spacing = 5
		local tabHeight = 15
		local yPadding = 8
		local tabSpacing = 5

		local sortedTabs = {}
		for guid, tabDesc in pairs(TeleporterGetOption("tabs")) do
			tinsert(sortedTabs, {guid = guid, tabDesc = tabDesc})
		end
		table.sort(sortedTabs, function(a, b)
			return (a.tabDesc.order or 0) < (b.tabDesc.order or 0)
		end)

		local parentWidth = parentFrame:GetWidth()
		local usableWidth = parentWidth - (xOffset * 2)
		local tabMaxWidth = (usableWidth / #sortedTabs) - tabSpacing

		for _, tabEntry in ipairs(sortedTabs) do
			local tabDesc = tabEntry.tabDesc
			if #Tabs < tabIndex then
				local newTab = {}
				newTab.frame = TeleporterCreateReusableFrame("Frame","TabFrame",parentFrame, "BackdropTemplate")
				newTab.fontString = TeleporterCreateReusableFontString("TabText",parentFrame, "GameFontNormalSmall")
				tinsert(Tabs, newTab)
			end

			local tab = Tabs[tabIndex]
			tab.fontString:SetPoint("BOTTOMLEFT",parentFrame, "BOTTOMLEFT", xOffset, yPadding)
			tab.fontString:SetText(tabDesc.name)
			tab.fontString:Show()
			tab.fontString:SetWidth(tabMaxWidth)
			local textWidth = tab.fontString:GetStringWidth()
			local frameWidth = math.min(tabMaxWidth, textWidth)
			tab.fontString:SetWidth(frameWidth)
			tab.fontString:SetHeight(tabHeight)

			tab.frame:SetWidth(frameWidth)
			tab.frame:SetHeight(tabHeight)
			tab.frame:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMLEFT", xOffset, yPadding)
			tab.frame:SetBackdrop({bgFile = "Interface/Buttons/WHITE8X8"})

			tab.guid = tabDesc.guid

			if tabDesc.guid == CurrentTab then
				tab.frame:SetBackdropColor(1, 1, 0, 0.5)
			else
				tab.frame:SetBackdropColor(0, 0, 0, 0.1)
			end
			tab.frame:EnableMouse(true)
			local guid = tabDesc.guid
			local name = tabDesc.name
			tab.frame:SetScript("OnMouseDown", function(self, button)
				if button == "LeftButton" then
					CurrentTab = guid
					TeleporterRefresh()
				elseif button == "RightButton" then
					TabContextMenu_Show(guid, name)
				end
			end)
			tab.frame:Show()

			xOffset = xOffset + frameWidth + tabSpacing
			tabIndex = tabIndex + 1

			tab.searchString = tabDesc.searchString
		end
		for i = tabIndex, #Tabs do
			Tabs[i].frame:Hide()
			Tabs[i].fontString:Hide()
		end

		parentFrame:SetHeight(parentFrame:GetHeight() + tabHeight)
	elseif Tabs then
		for i = 1, #Tabs do
			Tabs[i].frame:Hide()
			Tabs[i].fontString:Hide()
		end
	end
end
