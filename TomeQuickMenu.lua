local QuickMenuFrame = nil
local QuickMenuButtons = {}
local QuickMenuTextures = {}
local QuickMenuVisible = false

function TeleHideQuickMenu()
	if QuickMenuFrame then
		QuickMenuFrame:Hide()
		QuickMenuVisible = false
	end
end

function TeleQuickMenu_OnHide()
	QuickMenuVisible = false
end

function TeleQuickMenuOnClick(frame,button)
	if button == "RightButton" then
		QuickMenuFrame:Hide()
	end
end

function TeleToggleQuickMenu(favourites, size)
	if not QuickMenuFrame then
		QuickMenuFrame = TeleporterQuickMenuFrame
		QuickMenuFrame:SetFrameStrata("HIGH")
		tinsert(UISpecialFrames,TeleporterQuickMenuFrame:GetName());
	end

	if QuickMenuVisible then
		TeleHideQuickMenu()
	else
		local favCount = 0
		for spellId, isItem in pairs(favourites) do
			favCount = favCount + 1
		end

		local x, y = GetCursorPosition()
		QuickMenuFrame:SetPoint("TOPLEFT", nil, "BOTTOMLEFT", x - size, y)
		QuickMenuFrame:SetPoint("BOTTOMRIGHT", nil, "BOTTOMLEFT", x, y - size * favCount)



		for i = #QuickMenuButtons + 1, favCount do
			QuickMenuButtons[i] = CreateFrame( "Button", "TeleporterQuickMenuFrame"..i, QuickMenuFrame,"SecureActionButtonTemplate")
			QuickMenuButtons[i]:SetWidth(size)
			QuickMenuButtons[i]:SetHeight(size)
			QuickMenuButtons[i]:SetPoint("TOPLEFT",QuickMenuFrame,"TOPLEFT",0,-size*(i-1))
			QuickMenuButtons[i]:SetPoint("BOTTOMRIGHT",QuickMenuFrame,"TOPLEFT",size,-size*i)
			QuickMenuButtons[i]:SetAttribute("type", "macro")

			QuickMenuTextures[i] = QuickMenuButtons[i]:CreateTexture()
			QuickMenuTextures[i]:SetAllPoints(QuickMenuButtons[i])

			QuickMenuButtons[i]:SetScript(
				"OnLeave",
				function()
					GameTooltip:Hide()
				end )
		end

		local index = 1
		for i, spell in pairs(favourites) do
			local button = QuickMenuButtons[index]

			local isItem = spell.isItem
			local spellId = spell.spellId

			local texture
			local name

			if isItem then
				name, _, _, _, _, _, _, _, _, texture = GetItemInfo( spellId )

				if name then
					button:SetScript(
						"OnEnter",
						function()
							TeleporterShowItemTooltip( name, button )
						end )

					if PlayerHasToy(spellId) then
						button:SetAttribute(
							"macrotext",
							"/teleportercastspell " .. GetItemSpell(spellId) .. "\n" ..
							"/cast " .. name .. "\n" )
					else
						button:SetAttribute(
							"macrotext",
							"/teleporteruseitem " .. name .. "\n" ..
							"/use " .. name .. "\n" )
					end
				end
			else
				if C_Spell and C_Spell.GetSpellInfo then
					name = C_Spell.GetSpellInfo(spellId).name
					texture = C_Spell.GetSpellInfo(spellId).iconID
				else
					name,_,texture = GetSpellInfo( spellId )
				end

				button:SetScript(
					"OnEnter",
					function()
						TeleporterShowSpellTooltip( name, button )
					end )

				button:SetAttribute(
					"macrotext",
					"/teleportercastspell " .. name .. "\n" ..
					"/cast " .. name .. "\n" )
			end

			button:RegisterForClicks("AnyUp", "AnyDown")

			if name then
				QuickMenuTextures[index]:SetTexture(texture)

				QuickMenuButtons[index]:Show()

				QuickMenuButtons[index]:SetScript("OnMouseUp", TeleQuickMenuOnClick)

				index = index + 1
			end
		end

		while index <= #QuickMenuButtons do
			QuickMenuButtons[index]:Hide()
			index = index + 1
		end

		QuickMenuFrame:Show()
		QuickMenuVisible = true
	end
end