local SettingControls = {}

local ControlWidth = 300
local HideUnknown = false

local MoveButton = nil
local CancelMoveButton = nil
local AboveButton = nil
local BelowButton = nil
local ResetSortButton = nil
local MovingSpell = nil
local SelectedSpell = nil
local SetZoneButton = nil
local NewSpellZoneFrame = nil

SLASH_TELESETTINGS1 = "/telesettings"

local TeleporterSettings = {}

SlashCmdList.TELESETTINGS = function(msg, editBox)
    InterfaceOptionsFrame_OpenToCategory(TeleporterSettings.settingsPanel)
end

local function CreateText(text, optionName, parent, previous)
    local title = parent:CreateFontString(nil, nil, "GameFontNormal")
    title:SetText(text)

    if previous then
        title:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -15)
    else
        title:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -5)
    end

    title:SetWidth(180)
    title:SetJustifyH("LEFT")

    return title
end

local function CreateResetButton(title, optionName, parent, control)
    local resetButton = CreateFrame( "Button", nil, parent, "UIPanelButtonTemplate" )
	resetButton:SetText( "Reset" )
	resetButton:SetPoint( "TOPLEFT", title, "TOPRIGHT", ControlWidth + 4,  4)
    resetButton:SetPoint( "BOTTOMLEFT", title, "BOTTOMRIGHT", ControlWidth + 4,  -4)
	resetButton:SetWidth( 80 )
    resetButton:SetScript( "OnClick",
        function()
            TeleporterSetOption(optionName, nil)
            control.loadValue()
            control.updateResetButton()
        end )

    control.resetButton = resetButton
    control.updateResetButton = function()
        if TeleporterIsOptionModified(optionName) then
            resetButton:Enable()
        else
            resetButton:Disable()
        end
    end

    return resetButton
end

local function AddStringOption(text, optionName, parent, previous)
    local title = CreateText(text, optionName, parent, previous)

    local editFrame = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    editFrame:SetPoint("TOPLEFT", title, "TOPRIGHT", 0, 4)
    editFrame:SetPoint("BOTTOMLEFT", title, "BOTTOMRIGHT", 0, -4)
    editFrame:SetWidth(ControlWidth)
    editFrame:SetAutoFocus(false)
    editFrame:SetMultiLine(false)

    local newControl = {}
    newControl.loadValue = function()
        local optionValue = TeleporterGetOption(optionName)
        if optionValue then
            editFrame:SetText(optionValue)
        else
            editFrame:SetText("")
        end
    end
    tinsert(SettingControls, newControl)

    CreateResetButton(title, optionName, parent, newControl)

    editFrame:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            TeleporterSetOption(optionName, editFrame:GetText())
            newControl.updateResetButton()
        end
    end)

    return title
end

local function AddSliderOption(text, optionName, min, max, delta, parent, previous, isFloat, offset, changeCallback)
    local labelWidth = 50

    if not offset then
        offset = 0
    end

    local title = CreateText(text, optionName, parent, previous)

    local sliderFrame = CreateFrame("Slider", "slider" .. optionName, parent, "OptionsSliderTemplate")
    sliderFrame:SetPoint("TOPLEFT", title, "TOPRIGHT", offset, 4)
    sliderFrame:SetPoint("BOTTOMLEFT", title, "BOTTOMLEFT", offset, -4)
    sliderFrame:SetWidth(ControlWidth - labelWidth - offset)
    sliderFrame:SetMinMaxValues(min, max)
    if delta then
        sliderFrame:SetValueStep(delta)
        sliderFrame:SetObeyStepOnDrag(true)
    end
    sliderFrame:Enable()
    sliderFrame:SetOrientation("HORIZONTAL")

    getglobal(sliderFrame:GetName() .. 'Low'):SetText("")
    getglobal(sliderFrame:GetName() .. 'High'):SetText("")

    local valueFrame = parent:CreateFontString(nil, nil, "GameFontNormal")
    valueFrame:SetPoint("LEFT", sliderFrame, "RIGHT", 0, 0)
    valueFrame:SetPoint("TOP", title, "TOP")
    valueFrame:SetWidth(labelWidth)

    title:SetHeight(sliderFrame:GetHeight())

    local updateDisplay = function()
        if isFloat then
            valueFrame:SetText(string.format("%.2f", TeleporterGetOption(optionName)))
        else
            valueFrame:SetText(TeleporterGetOption(optionName))
        end

        if changeCallback then
            changeCallback.run()
        end
    end

    local newControl = {}
    newControl.loadValue = function()
        updateDisplay()
        sliderFrame:SetValue(TeleporterGetOption(optionName))
    end
    tinsert(SettingControls, newControl)

    CreateResetButton(title, optionName, parent, newControl)

    sliderFrame:SetScript("OnValueChanged", function()
        TeleporterSetOption(optionName, sliderFrame:GetValue())
        updateDisplay()
        newControl.updateResetButton()
    end)

    return title
end

local function AddCheckOption(text, optionName, parent, previous)
    local title = CreateText(text, optionName, parent, previous)
    title:SetHeight(20)

    local checkFrame = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkFrame:SetPoint("TOPLEFT", title, "TOPRIGHT", 0, 4)
    checkFrame:SetPoint("BOTTOMLEFT", title, "BOTTOMLEFT", 0, -4)

    local newControl = {}
    newControl.loadValue = function()
        checkFrame:SetChecked(TeleporterGetOption(optionName))
    end
    tinsert(SettingControls, newControl)

    CreateResetButton(title, optionName, parent, newControl)

    checkFrame:SetScript("OnClick", function()
        TeleporterSetOption(optionName, checkFrame:GetChecked())
        newControl.updateResetButton()
    end)

    return title
end

local function AddColourOption(text, optionName, parent, hasAlpha, previous)
    local changeCallback = {}

    local colourPanelWidth = 50
    local p = previous
    p = AddSliderOption(text .. " Red", optionName .. "R", 0, 1, nil, parent, p, true, colourPanelWidth, changeCallback)
    local redTitle = p
    p = AddSliderOption(text .. " Green", optionName .. "G", 0, 1, nil, parent, p, true, colourPanelWidth, changeCallback)
    local greenTitle = p
    p = AddSliderOption(text .. " Blue", optionName .. "B", 0, 1, nil, parent, p, true, colourPanelWidth, changeCallback)
    local blueTitle = p
    if hasAlpha then
        p = AddSliderOption(text .. " Alpha", optionName .. "A", 0, 1, nil, parent, p, true)
    end

    local colourPanel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    colourPanel:SetPoint("TOPLEFT", redTitle, "TOPRIGHT")
    colourPanel:SetPoint("BOTTOMLEFT", blueTitle, "BOTTOMRIGHT")
    colourPanel:SetWidth(colourPanelWidth)
    colourPanel.backdropInfo = {bgFile = "Interface/Buttons/WHITE8X8"}
    colourPanel:ApplyBackdrop()
    colourPanel:SetBackdropColor(1, 1, 1, 1)

    changeCallback.run = function()
        colourPanel:SetBackdropColor(TeleporterGetOption(optionName .. "R"), TeleporterGetOption(optionName .. "G"), TeleporterGetOption(optionName .. "B"), 1)
    end
    return p
end

local function RefreshSettings()
    TeleporterSettings.settingsPanel.scrollChild:SetWidth(TeleporterSettings.settingsPanel:GetWidth() - 18)
    TeleporterSettings.spellsPanel.scrollChild:SetWidth(TeleporterSettings.settingsPanel:GetWidth() - 18)

    for i,c in pairs(SettingControls) do
        c.loadValue()
        c.updateResetButton()
    end

    UIDropDownMenu_SetText(TeleporterThemeFrame, TeleporterGetOption("theme"))
end

local function ResetAll()
    local dialogText = "Do you want to reset all settings to the defaults, including removing custom items? This will reload the UI."

	StaticPopupDialogs["TELEPORTER_CONFIRM_RESETALL"] =
	{
		text = dialogText,
		button1 = "Yes",
		button2 = "No",
		OnAccept = function()
			TomeOfTele_Options = nil
            TomeOfTele_ShareOptions = nil
            TomeOfTele_OptionsGlobal = nil
            TomeOfTele_IconGlobal = nil
            ReloadUI()
		end,
		OnCancel = function() end,
		hideOnEscape = true
	}

	StaticPopup_Show("TELEPORTER_CONFIRM_RESETALL")
end

local function CreateSettings(panel)
    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 3, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", -27, 4)

    local scrollChild = CreateFrame("Frame", nil, panel)
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetHeight(1)
    panel.scrollChild = scrollChild

    local p = nil

    p = CreateText("Theme", "theme", scrollChild, p)

    TeleporterThemeFrame = CreateFrame("Frame", nil, scrollChild, "UIDropDownMenuTemplate")
    TeleporterThemeFrame:SetPoint("TOPLEFT", p, "TOPRIGHT", offset, 4)
    UIDropDownMenu_Initialize(TeleporterThemeFrame, function()
        for name, theme in pairs(TeleporterGetThemes()) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = name
            info.func = function()
                UIDropDownMenu_SetText(TeleporterThemeFrame, name)
                TeleporterSetOption("theme", name)
                RefreshSettings()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    p:SetHeight(TeleporterThemeFrame:GetHeight())

    local resetAllButton = CreateFrame( "Button", nil, panel, "UIPanelButtonTemplate" )
    resetAllButton:SetPoint("TOPLEFT", TeleporterThemeFrame, "TOPRIGHT", 180, 0)
    resetAllButton:SetText("Reset All")
    resetAllButton:SetWidth(100)
    resetAllButton:SetHeight(TeleporterThemeFrame:GetHeight())
    resetAllButton:SetScript( "OnClick", function()
        ResetAll()
    end)

    p = AddCheckOption("All Covenant Hearthstones", "allCovenants",         scrollChild, p)
    p = AddCheckOption("Hide Items",                "hideItems",            scrollChild, p)
    p = AddCheckOption("Hide Dungeon Spells",       "hideChallenge",        scrollChild, p)
    p = AddCheckOption("Show Spells",               "hideSpells",           scrollChild, p)
    p = AddCheckOption("Show Dungeon Names",        "showDungeonNames",     scrollChild, p)
    p = AddCheckOption("Current Dungeons Only",     "seasonOnly",           scrollChild, p)
    p = AddCheckOption("Group Dungeons Together",   "groupDungeons",        scrollChild, p)
    p = AddCheckOption("Random Heathstone",         "randomHearth",         scrollChild, p)
    p = AddCheckOption("Show Spells Everywhere",    "showInWrongZone",      scrollChild, p)
    p = AddCheckOption("Close After Cast",          "closeAfterCast",       scrollChild, p)
    p = AddCheckOption("Show Title",                "showTitle",            scrollChild, p)
    p = AddCheckOption("Concise Dungeon Spells",    "conciseDungeonSpells", scrollChild, p)
    p = AddCheckOption("Use Old Customizer",        "oldCustomizer",        scrollChild, p)
    p = AddCheckOption("Show Search Box",           "showSearch",           scrollChild, p)
    p = AddCheckOption("Search Hidden Items",       "searchHidden",         scrollChild, p)

    p = AddSliderOption("Button Width",         "buttonWidth", 20, 400, 1,              scrollChild, p)
    p = AddSliderOption("Button Height",        "buttonHeight", 20, 200, 1,             scrollChild, p)
    p = AddSliderOption("Label Height",         "labelHeight", 10, 50, 1,               scrollChild, p)
    p = AddSliderOption("Maximum Height",       "maximumHeight", 100, 1000, 10,         scrollChild, p)
    p = AddSliderOption("Height Scale",         "heightScalePercent", 100, 300, 50,     scrollChild, p)
    p = AddSliderOption("Font Height",          "fontHeight", 5, 30, 1,                 scrollChild, p)
    p = AddSliderOption("Button Inset",         "buttonInset", 1, 20, 1,                scrollChild, p)
    p = AddSliderOption("Scale",                "scale", 0.6, 2, 0.1,                   scrollChild, p, true)
    p = AddStringOption("Background Texture",   "background",                           scrollChild, p)
    p = AddStringOption("Edge Texture",         "edge",                                 scrollChild, p)
    p = AddSliderOption("Edge Size",            "frameEdgeSize", 0, 50, 1,              scrollChild, p)
    p = AddColourOption("Background",           "background",                           scrollChild, true, p)
    p = AddStringOption("Title Background",     "titleBackground",                      scrollChild, p)
    p = AddStringOption("Title Font",           "titleFont",                            scrollChild, p)
    p = AddSliderOption("Title Width",          "titleWidth", 50, 400, 5,               scrollChild, p)
    p = AddSliderOption("Title Height",         "titleHeight", 10, 100, 5,              scrollChild, p)
    p = AddSliderOption("Title Offset",         "titleOffset", 1, 30, 1,                scrollChild, p)
    --p = AddStringOption("Button Font",          "buttonFont",                         scrollChild, p)
    p = AddStringOption("Button Background",    "buttonBackground",                     scrollChild, p)
    p = AddStringOption("Button Edge",          "buttonEdge",                           scrollChild, p)
    p = AddSliderOption("Button Edge Size",     "buttonEdgeSize", 0, 50, 1,             scrollChild, p)
    p = AddSliderOption("Button Tile Size",     "buttonTileSize", 1, 50, 1,             scrollChild, p)

    p = AddColourOption("Ready Colour",         "readyColour",                          scrollChild, false, p)
    p = AddColourOption("Unequiped Colour",     "unequipedColour",                      scrollChild, false, p)
    p = AddColourOption("Cooldown Colour",      "cooldownColour",                       scrollChild, false, p)
    p = AddColourOption("Disabled Colour",      "disabledColour",                       scrollChild, false, p)

    p = AddSliderOption("Quick Menu Size",      "QuickMenuSize", 20, 100, 1,             scrollChild, p)
end

local ZoneLabels = {}
local SpellFrames = {}

local TextShow = "Show If Known"
local TextHide = "Hide"
local TextAlways = "Always Show"

local function CreateSpellFrame(parent)
    local spellFrame = {}
    spellFrame.mainFrame = CreateFrame("Frame", nil, parent)
    spellFrame.mainFrame:SetWidth(400)
    spellFrame.mainFrame:SetHeight(25)

    spellFrame.spellLabel = spellFrame.mainFrame:CreateFontString(nil, nil, "GameFontNormal")
    spellFrame.spellLabel:SetJustifyH("LEFT")

    spellFrame.dropDown = CreateFrame("Frame", nil, spellFrame.mainFrame, "UIDropDownMenuTemplate")
    spellFrame.dropDown:SetPoint("TOPLEFT", spellFrame.spellLabel, "TOPRIGHT", 4, 4)
    UIDropDownMenu_Initialize(spellFrame.dropDown, function()
        local info = UIDropDownMenu_CreateInfo()

        info.text = TextShow
        info.func = function()
            UIDropDownMenu_SetText(spellFrame.dropDown, TextShow)
            spellFrame.spell : SetVisible()
        end
        UIDropDownMenu_AddButton(info)

        info.text = TextHide
        info.func = function()
            UIDropDownMenu_SetText(spellFrame.dropDown, TextHide)
            spellFrame.spell:SetHidden()
        end
        UIDropDownMenu_AddButton(info)

        info.text = TextAlways
        info.func = function()
            UIDropDownMenu_SetText(spellFrame.dropDown, TextAlways)
            spellFrame.spell:SetAlwaysVisible()
        end
        UIDropDownMenu_AddButton(info)
    end)

    return spellFrame
end

local function RefreshSpellFrame(spellFrame, spell, parent, previous, refreshFunction)
    spellFrame.mainFrame:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -15)
    spellFrame.mainFrame:SetWidth(600)

    spellFrame.spellLabel:SetPoint("TOPLEFT", spellFrame.mainFrame, "TOPLEFT", 0, 0)
    spellFrame.spellLabel:SetPoint("BOTTOMLEFT", spellFrame.mainFrame, "BOTTOMLEFT", 0, 0)
    spellFrame.spellLabel:SetText(spell.spellName)
    spellFrame.spellLabel:SetWidth(200)

    if spell:IsAlwaysVisible() then
        UIDropDownMenu_SetText(spellFrame.dropDown, TextAlways)
    elseif spell:IsVisible() then
        UIDropDownMenu_SetText(spellFrame.dropDown, TextShow)
    else
        UIDropDownMenu_SetText(spellFrame.dropDown, TextHide)
    end

    if spell.isCustom then
        if not spellFrame.deleteButton then
            spellFrame.deleteButton = CreateFrame( "Button", nil, spellFrame.mainFrame, "UIPanelButtonTemplate" )
            spellFrame.deleteButton:SetPoint("TOPLEFT", spellFrame.spellLabel, "TOPRIGHT", 160, 0)
            spellFrame.deleteButton:SetText("Delete")
            spellFrame.deleteButton:SetWidth(100)
        end
        spellFrame.deleteButton:SetScript( "OnClick", function()
            local extraSpellsAndItems = TeleporterGetOption("extraSpellsAndItems")
            for i, spell in ipairs(extraSpellsAndItems) do
                if spell == spellFrame.spell then
                    tremove(extraSpellsAndItems, i)
                end
            end
            TeleporterSetOption("extraSpellsAndItems", extraSpellsAndItems)
            TeleporterRebuildSpellList()
            refreshFunction()
        end)
        spellFrame.deleteButton:Show()
    else
        if spellFrame.deleteButton then
            spellFrame.deleteButton:Hide()
        end
    end

    spellFrame.spell = spell
end

local function ShowAboveAndBelowButtons()
    MoveButton:Hide()

    if TeleporterGetOption("sort") == 3 then
        AboveButton:SetEnabled(true)
        BelowButton:SetEnabled(true)
        if SelectedSpell == MovingSpell then
            AboveButton:Hide()
            BelowButton:Hide()
            CancelMoveButton:Show()
        else
            AboveButton:Show()
            BelowButton:Show()
            CancelMoveButton:Hide()
        end
    else
        AboveButton:SetEnabled(false)
        AboveButton:Hide()
        BelowButton:SetEnabled(false)
        AboveButton:Hide()
        CancelMoveButton:Show()
    end
end

local function ShowMoveButton()
    AboveButton:Hide()
    BelowButton:Hide()
    CancelMoveButton:Hide()
    MoveButton:Show()
end

-- Spells aren't loaded by default because creating the frames takes a long time.
local LoadSpells = false

local function RefreshSpells(panel)
    if not LoadSpells then return end

    for i,label in ipairs(ZoneLabels) do
        label:Hide()
    end

    for i,spellFrame in ipairs(SpellFrames) do
        spellFrame.mainFrame:Hide()
    end

    local lastZone
    local p
    local zoneIndex = 1
    local spellIndex = 1

    for index, spell in ipairs(TeleporterGetSpells()) do
        if spell:CanUse() or not HideUnknown then
            local zone = spell:GetZone()
            if zone ~= lastZone then
                if not ZoneLabels[zoneIndex] then
                    ZoneLabels[zoneIndex] = panel:CreateFontString(nil, nil, "GameFontWhite")
                end
                local zoneLabel = ZoneLabels[zoneIndex]
                zoneIndex = zoneIndex + 1

                zoneLabel:SetText(zone)

                if p then
                    zoneLabel:SetPoint("TOPLEFT", p, "BOTTOMLEFT", 0, -15)
                else
                    zoneLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -5)
                end
                zoneLabel:SetWidth(180)
                zoneLabel:SetJustifyH("LEFT")
                zoneLabel:Show()

                p = zoneLabel
            end
            lastZone = zone

            if not SpellFrames[spellIndex] then
                SpellFrames[spellIndex] = CreateSpellFrame(panel)
            end
            RefreshSpellFrame(SpellFrames[spellIndex], spell, panel, p, function() RefreshSpells(panel) end)
            p = SpellFrames[spellIndex].mainFrame
            p:Show()

            p:SetScript("OnEnter", function(frame)
                MoveButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 360, 0)
                AboveButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 360, 0)
                CancelMoveButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 360, 0)
                SetZoneButton:Show()
                SelectedSpell = spell
                if MovingSpell then
                    ShowAboveAndBelowButtons()
                end
                RefreshSpells(panel)  -- Without this the button becomes unclickable
            end)
            spellIndex = spellIndex + 1
        end
    end
end

local TextItem = "Item"
local TextSpell = "Spell"
local TextDungeon = "Dungeon"
local TextConsumable = "Consumable"

local function CreateSpell(spellType, id, zone)
    if id == "" or zone == "" then
        return
    end

    local spell
    if spellType == TextItem then
        spell = TeleporterCreateItem(id, zone)
    elseif spellType == TextSpell then
        spell = TeleporterCreateSpell(id, zone)
    elseif spellType == TextDungeon then
        spell = TeleporterCreateChallengeSpell(id, zone)
        spell:SetZone(zone)
    elseif spellType == TextConsumable then
        spell = TeleporterCreateConsumable(id, zone)
    else
        return
    end

    spell.isCustom = true

    local extraSpellsAndItems = TeleporterGetOption("extraSpellsAndItems")
    if not extraSpellsAndItems then
        extraSpellsAndItems = {}
    end

    tinsert(extraSpellsAndItems, spell)

    TeleporterSetOption("extraSpellsAndItems", extraSpellsAndItems)

    TeleporterRebuildSpellList()
end

local function CreateSpellCustomiser(panel)
    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 3, -80)
    scrollFrame:SetPoint("RIGHT", -27, 4)

    local scrollChild = CreateFrame("Frame", nil, panel)
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetHeight(1)
    panel.scrollChild = scrollChild

    local beginButton = CreateFrame( "Button", nil, panel, "UIPanelButtonTemplate" )
    beginButton:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -4)
    beginButton:SetText("View Spell List")
    beginButton:SetWidth(150)
    beginButton:SetScript( "OnClick", function()
        LoadSpells = true
        beginButton:SetText("Refresh Spell List")
        RefreshSpells(scrollChild)
    end)

    -- Hide unknown
    local hideUnknownLabel = panel:CreateFontString(nil, nil, "GameFontNormal")
    hideUnknownLabel:SetPoint("TOPLEFT", beginButton, "TOPRIGHT", 4, 0)
    hideUnknownLabel:SetWidth(100)
    hideUnknownLabel:SetHeight(30)
    hideUnknownLabel:SetText("Hide Unknown")

    local hideUnknownButton = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    hideUnknownButton:SetPoint("TOPLEFT", hideUnknownLabel, "TOPRIGHT", 4, 0)
    hideUnknownButton:SetWidth(30)
    hideUnknownButton:SetHeight(30)
    hideUnknownButton:SetScript( "OnClick", function()
        HideUnknown = hideUnknownButton:GetChecked()
        RefreshSpells(scrollChild)
    end)

    -- Sorting
    local sortLabel = panel:CreateFontString(nil, nil, "GameFontNormal")
    sortLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -40)
    sortLabel:SetWidth(50)
    sortLabel:SetHeight(20)
    sortLabel:SetText("Sort")

    local sortText = { "By Destination", "By Type", "Custom" }

    local sortFrame = CreateFrame("Frame", nil, panel, "UIDropDownMenuTemplate")
    sortFrame:SetPoint("TOPLEFT", sortLabel, "TOPRIGHT", 0, 4)
    sortFrame:SetWidth(160)
    UIDropDownMenu_Initialize(sortFrame, function()
        for i = 1, #sortText do
            local info = UIDropDownMenu_CreateInfo()
            info.text = sortText[i]
            info.func = function()
                UIDropDownMenu_SetText(sortFrame, sortText[i])
                TeleporterSetOption("sort", i)
                RefreshSpells(scrollChild)
                MoveButton:SetEnabled(i == 3)
                ResetSortButton:SetEnabled(i == 3)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    local sortMode = TeleporterGetOption("sort") or 1
    UIDropDownMenu_SetText(sortFrame, sortText[sortMode])

    MoveButton = CreateFrame( "Button", nil, scrollChild, "UIPanelButtonTemplate" )
    MoveButton:SetText("Move")
    MoveButton:SetWidth(140)
    MoveButton:SetEnabled(sortMode == 3)
    MoveButton:SetScript( "OnClick", function()
        MovingSpell = SelectedSpell
        ShowAboveAndBelowButtons()
        RefreshSpells(scrollChild)  -- Without this the button is unclickable for some reason
    end)

    AboveButton = CreateFrame( "Button", nil, scrollChild, "UIPanelButtonTemplate" )
    AboveButton:SetText("Above")
    AboveButton:SetWidth(70)
    AboveButton:Hide()
    AboveButton:SetScript( "OnClick", function()
        TeleporterMoveSpellBefore(MovingSpell, SelectedSpell)
        MovingSpell = nil
        ShowMoveButton()
        RefreshSpells(scrollChild)  -- Without this the button is unclickable for some reason
    end)

    BelowButton = CreateFrame( "Button", nil, scrollChild, "UIPanelButtonTemplate" )
    BelowButton:SetText("Below")
    BelowButton:SetWidth(70)
    BelowButton:Hide()
    BelowButton:SetPoint("TOPLEFT", AboveButton, "TOPRIGHT")
    BelowButton:SetScript( "OnClick", function()
        TeleporterMoveSpellAfter(MovingSpell, SelectedSpell)
        MovingSpell = nil
        ShowMoveButton()
        RefreshSpells(scrollChild)  -- Without this the button is unclickable for some reason
    end)

    CancelMoveButton = CreateFrame( "Button", nil, scrollChild, "UIPanelButtonTemplate" )
    CancelMoveButton:SetText("Cancel Move")
    CancelMoveButton:SetWidth(140)
    CancelMoveButton:Hide()
    CancelMoveButton:SetPoint("TOPLEFT", AboveButton, "TOPRIGHT")
    CancelMoveButton:SetScript( "OnClick", function()
        MovingSpell = nil
        ShowMoveButton()
        RefreshSpells(scrollChild)  -- Without this the button is unclickable for some reason
    end)

    ResetSortButton = CreateFrame( "Button", nil, panel, "UIPanelButtonTemplate" )
    ResetSortButton:SetText("Reset Sort")
    ResetSortButton:SetWidth(100)
    ResetSortButton:SetPoint("TOPLEFT", sortFrame, "TOPRIGHT", 0, 0)
    ResetSortButton:SetScript( "OnClick", function()
        TeleporterSetOption("sortOrder", {})
        RefreshSpells(scrollChild)
    end)
    ResetSortButton:SetEnabled(sortMode == 3)

    SetZoneButton = CreateFrame( "Button", nil, scrollChild, "UIPanelButtonTemplate" )
    SetZoneButton:SetText("Set Zone")
    SetZoneButton:SetPoint("TOPLEFT", MoveButton, "TOPRIGHT", 2, 0)
    SetZoneButton:SetWidth(120)
    SetZoneButton:Hide()
    SetZoneButton:SetScript( "OnClick", function()
        if NewSpellZoneFrame:GetText() == "" then
            print("Resetting zone name. Use the zone box below to specify a new zone name.")
        end
        SelectedSpell:OverrideZoneName(NewSpellZoneFrame:GetText())
        RefreshSpells(scrollChild)
    end)

    -- New spell
    local newSpellTypeFrame = CreateFrame("Frame", nil, panel, "UIDropDownMenuTemplate")
    newSpellTypeFrame:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 4, 4)
    newSpellTypeFrame:SetWidth(160)
    UIDropDownMenu_Initialize(newSpellTypeFrame, function()
        local info = UIDropDownMenu_CreateInfo()

        info.text = TextItem
        info.func = function()
            UIDropDownMenu_SetText(newSpellTypeFrame, TextItem)
        end
        UIDropDownMenu_AddButton(info)

        info.text = TextSpell
        info.func = function()
            UIDropDownMenu_SetText(newSpellTypeFrame, TextSpell)
        end
        UIDropDownMenu_AddButton(info)

        info.text = TextConsumable
        info.func = function()
            UIDropDownMenu_SetText(newSpellTypeFrame, TextConsumable)
        end
        UIDropDownMenu_AddButton(info)

        info.text = TextDungeon
        info.func = function()
            UIDropDownMenu_SetText(newSpellTypeFrame, TextDungeon)
        end
        UIDropDownMenu_AddButton(info)
    end)

    local idLabel = panel:CreateFontString(nil, nil, "GameFontNormal")
    idLabel:SetPoint("TOPLEFT", newSpellTypeFrame, "TOPRIGHT", 0, 0)
    idLabel:SetHeight(25)
    idLabel:SetWidth(20)
    idLabel:SetText("ID:")

    local newSpellIdFrame = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    newSpellIdFrame:SetPoint("TOPLEFT", idLabel, "TOPRIGHT", 4, 0)
    newSpellIdFrame:SetPoint("BOTTOMLEFT", idLabel, "BOTTOMRIGHT", 4, 0)
    newSpellIdFrame:SetWidth(100)
    newSpellIdFrame:SetAutoFocus(false)
    newSpellIdFrame:SetMultiLine(false)

    local zoneLabel = panel:CreateFontString(nil, nil, "GameFontNormal")
    zoneLabel:SetPoint("TOPLEFT", newSpellIdFrame, "TOPRIGHT", 5, 0)
    zoneLabel:SetHeight(25)
    zoneLabel:SetText("Zone:")

    NewSpellZoneFrame = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    NewSpellZoneFrame:SetPoint("TOPLEFT", zoneLabel, "TOPRIGHT", 4, 0)
    NewSpellZoneFrame:SetPoint("BOTTOMLEFT", zoneLabel, "BOTTOMRIGHT", 4, 0)
    NewSpellZoneFrame:SetWidth(100)
    NewSpellZoneFrame:SetAutoFocus(false)
    NewSpellZoneFrame:SetMultiLine(false)

    local createButton = CreateFrame( "Button", nil, panel, "UIPanelButtonTemplate" )
    createButton:SetPoint("TOPLEFT", NewSpellZoneFrame, "TOPRIGHT", 4, 0)
    createButton:SetPoint("BOTTOMLEFT", NewSpellZoneFrame, "BOTTOMRIGHT", 4, 0)
    createButton:SetText("Create")
    createButton:SetWidth(150)
    createButton:SetScript( "OnClick", function()
        CreateSpell(UIDropDownMenu_GetText(newSpellTypeFrame), newSpellIdFrame:GetText(), NewSpellZoneFrame:GetText())
        RefreshSpells(scrollChild)
    end)

    scrollFrame:SetPoint("BOTTOM", newSpellTypeFrame, "TOP", -27, 10)

    panel.refresh = function()
       RefreshSpells(scrollChild)
    end
end

function TeleporterSettings_OnLoad()
    TeleporterSettings.settingsPanel = CreateFrame("Frame")
	TeleporterSettings.settingsPanel.name = "Tome of Teleportation"
    TeleporterSettings.settingsPanel.refresh = RefreshSettings
    TeleporterSettings.settingsPanel.OnCommit = TeleporterSettings.settingsPanel.okay;
	TeleporterSettings.settingsPanel.OnDefault = TeleporterSettings.settingsPanel.default;
	TeleporterSettings.settingsPanel.OnRefresh = TeleporterSettings.settingsPanel.refresh;
    CreateSettings(TeleporterSettings.settingsPanel)

    local category = Settings.RegisterCanvasLayoutCategory(TeleporterSettings.settingsPanel, TeleporterSettings.settingsPanel.name, TeleporterSettings.settingsPanel.name);
    category.ID = TeleporterSettings.settingsPanel.name;
    Settings.RegisterAddOnCategory(category);

    TeleporterSettings.spellsPanel = CreateFrame("Frame")
	TeleporterSettings.spellsPanel.name = "Customize Teleporters"
    TeleporterSettings.spellsPanel.parent = TeleporterSettings.settingsPanel.name
    TeleporterSettings.spellsPanel.OnCommit = TeleporterSettings.spellsPanel.okay;
	TeleporterSettings.spellsPanel.OnDefault = TeleporterSettings.spellsPanel.default;
	TeleporterSettings.spellsPanel.OnRefresh = TeleporterSettings.spellsPanel.refresh;
    CreateSpellCustomiser(TeleporterSettings.spellsPanel)

    local customizeName = "Customize Teleporters"
    local subcategory = Settings.RegisterCanvasLayoutSubcategory(category, TeleporterSettings.spellsPanel, TeleporterSettings.spellsPanel.name, TeleporterSettings.spellsPanel.name);
	subcategory.ID = TeleporterSettings.spellsPanel.name;
end

function TeleporterOpenSettings()
    Settings.OpenToCategory(TeleporterSettings.settingsPanel.name);
end