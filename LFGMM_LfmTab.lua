--[[
	LFG MatchMaker - Addon for World of Warcraft.
	Version: 1.0.2
	URL: https://github.com/AvilanHauxen/LFG_MatchMaker
	Copyright (C) 2019-2020 L.I.R.

	This file is part of 'LFG MatchMaker' addon for World of Warcraft.

    'LFG MatchMaker' is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    'LFG MatchMaker' is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with 'LFG MatchMaker'. If not, see <https://www.gnu.org/licenses/>.
]]--


------------------------------------------------------------------------------------------------------------------------
-- LFM TAB
------------------------------------------------------------------------------------------------------------------------


function LFGMM_LfmTab_Initialize()
	LFGMM_LfmTab_SearchActiveText.StringAnimation = "";

	LFGMM_Utility_InitializeDropDown(LFGMM_LfmTab_DungeonDropDown, 200, LFGMM_LfmTab_DungeonDropDown_OnInitialize);

	LFGMM_LfmTab_StartStopSearchButton:SetScript("OnClick", LFGMM_LfmTab_StartStopSearchButton_OnClick);

	LFGMM_Utility_InitializeCheckbox(LFGMM_LfmTab_MatchLfgCheckBox, "LFG", "Get notifications on LFG messages", true, LFGMM_LfmTab_MatchLfgCheckBox_OnClick);
	LFGMM_Utility_InitializeCheckbox(LFGMM_LfmTab_MatchLfmCheckBox,	"LFM", "Get notifications on LFM messages", LFGMM_DB.SEARCH.LFM.MatchLfm, LFGMM_LfmTab_MatchLfmCheckBox_OnClick);
	LFGMM_Utility_InitializeCheckbox(LFGMM_LfmTab_MatchUnknownCheckBox, "Unknown", "Get notifications when dungeon matches, but LFG/LFM cannot be determined", LFGMM_DB.SEARCH.LFM.MatchUnknown, LFGMM_LfmTab_MatchUnknownCheckBox_OnClick);
	LFGMM_Utility_InitializeCheckbox(LFGMM_LfmTab_EnableBroadcastCheckBox, "Broadcast in LFG channel", "Periodically send LFM messages to LookingForGroup channel", LFGMM_DB.SEARCH.LFM.Broadcast, LFGMM_LfmTab_EnableBroadcastCheckBox_OnClick);

	LFGMM_LfmTab_BroadcastMessageTemplateInputBox:SetScript("OnTextChanged", LFGMM_LfmTab_UpdateBroadcastMessage);
	LFGMM_LfmTab_BroadcastMessageTemplateInputBox:SetText(LFGMM_DB.SEARCH.LFM.BroadcastMessageTemplate);

	LFGMM_Utility_InitializeHiddenSlider(LFGMM_LfmTab_BroadcastMessagePreviewSlider, LFGMM_LfmTab_BroadcastMessagePreview_Refresh);
	LFGMM_LfmTab_BroadcastMessagePreviewSliderLow:SetText("");
	LFGMM_LfmTab_BroadcastMessagePreviewSliderHigh:SetText("");

	LFGMM_LfmTab_BroadcastMessageInfoButton:SetScript("OnClick", LFGMM_LfmTab_BroadcastMessageInfoButton_OnClick);
	
	LFGMM_LfmTab.SearchAnimationLock = false;
end


function LFGMM_LfmTab_Show()
	PanelTemplates_SetTab(LFGMM_MainWindow, 2);

	LFGMM_LfgTab_BroadcastMessageInfoWindow:Hide();
	LFGMM_LfmTab_BroadcastMessageInfoWindow:Hide();
	LFGMM_SettingsTab_RequestInviteMessageInfoWindow:Hide();
	LFGMM_ListTab_MessageInfoWindow_Hide();

	LFGMM_LfgTab:Hide();
	LFGMM_LfmTab:Show();
	LFGMM_ListTab:Hide();
	LFGMM_SettingsTab:Hide();

	LFGMM_MainWindowTab1:SetPoint ("CENTER", "LFGMM_MainWindow", "BOTTOMLEFT",    60, -14);
	LFGMM_MainWindowTab2:SetPoint ("CENTER", "LFGMM_MainWindow", "BOTTOMLEFT",   135, -17);
	LFGMM_MainWindowTab3:SetPoint ("CENTER", "LFGMM_MainWindow", "BOTTOMRIGHT", -140, -14);
	LFGMM_MainWindowTab4:SetPoint ("CENTER", "LFGMM_MainWindow", "BOTTOMRIGHT",  -60, -14);
	
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB);

	LFGMM_LfmTab_Refresh();
end


function LFGMM_LfmTab_Refresh()
	if (not LFGMM_LfmTab:IsVisible()) then
		return;
	end
	
	if (LFGMM_DB.SEARCH.LFM.Broadcast) then
		LFGMM_LfmTab_BroadcastMessageTemplateInputBox:Show();
		LFGMM_LfmTab_BroadcastMessageInfoButton:Show();
		LFGMM_LfmTab_BroadcastMessagePreview:Show();
		LFGMM_LfmTab_BroadcastMessagePreview_Refresh();
	else
		LFGMM_LfmTab_BroadcastMessageTemplateInputBox:Hide();
		LFGMM_LfmTab_BroadcastMessageInfoButton:Hide();
		LFGMM_LfmTab_BroadcastMessagePreview:Hide();
		LFGMM_LfmTab_BroadcastMessagePreviewSlider:Hide();
		LFGMM_LfmTab_BroadcastMessageInfoWindow:Hide();
	end
	
	local groupSize = table.getn(LFGMM_GLOBAL.GROUP_MEMBERS);
	if (LFGMM_DB.SEARCH.LFM.Dungeon ~= nil and groupSize >= LFGMM_GLOBAL.DUNGEONS[LFGMM_DB.SEARCH.LFM.Dungeon].Size) then
		LFGMM_LfmTab_InFullGroupText:Show();

		UIDropDownMenu_EnableDropDown(LFGMM_LfmTab_DungeonDropDown);
		LFGMM_LfmTab_SearchActiveText:Hide();
		LFGMM_LfmTab_StartStopSearchButton:Disable();
		LFGMM_LfmTab_StartStopSearchButton:SetText("Start search");
		LFGMM_LfmTab_MatchOnText:SetFontObject("GameFontNormal");
		LFGMM_LfmTab_BroadcastMessageTemplateInputBox:Enable();
		LFGMM_Utility_ToggleCheckBoxEnabled(LFGMM_LfmTab_MatchLfgCheckBox, true);
		LFGMM_Utility_ToggleCheckBoxEnabled(LFGMM_LfmTab_MatchLfmCheckBox, true);
		LFGMM_Utility_ToggleCheckBoxEnabled(LFGMM_LfmTab_MatchUnknownCheckBox, true);
		LFGMM_Utility_ToggleCheckBoxEnabled(LFGMM_LfmTab_EnableBroadcastCheckBox, true);
	
	else
		LFGMM_LfmTab_InFullGroupText:Hide();
	
		if (LFGMM_DB.SEARCH.LFM.Running) then
			UIDropDownMenu_DisableDropDown(LFGMM_LfmTab_DungeonDropDown);
			LFGMM_LfmTab_SearchActiveText:Show();
			LFGMM_LfmTab_StartStopSearchButton:SetText("Stop searching");
			LFGMM_LfmTab_MatchOnText:SetFontObject("GameFontHighlight");
			LFGMM_LfmTab_BroadcastMessageTemplateInputBox:Disable();
			LFGMM_Utility_ToggleCheckBoxEnabled(LFGMM_LfmTab_MatchLfgCheckBox, false);
			LFGMM_Utility_ToggleCheckBoxEnabled(LFGMM_LfmTab_MatchLfmCheckBox, false);
			LFGMM_Utility_ToggleCheckBoxEnabled(LFGMM_LfmTab_MatchUnknownCheckBox, false);
			LFGMM_Utility_ToggleCheckBoxEnabled(LFGMM_LfmTab_EnableBroadcastCheckBox, false);
			LFGMM_LfmTab_StartAnimateSearchText();

		else
			UIDropDownMenu_EnableDropDown(LFGMM_LfmTab_DungeonDropDown);
			LFGMM_LfmTab_SearchActiveText:Hide();
			LFGMM_LfmTab_StartStopSearchButton:SetText("Start search");
			LFGMM_LfmTab_MatchOnText:SetFontObject("GameFontNormal");
			LFGMM_LfmTab_BroadcastMessageTemplateInputBox:Enable();
			LFGMM_Utility_ToggleCheckBoxEnabled(LFGMM_LfmTab_MatchLfgCheckBox, true);
			LFGMM_Utility_ToggleCheckBoxEnabled(LFGMM_LfmTab_MatchLfmCheckBox, true);
			LFGMM_Utility_ToggleCheckBoxEnabled(LFGMM_LfmTab_MatchUnknownCheckBox, true);
			LFGMM_Utility_ToggleCheckBoxEnabled(LFGMM_LfmTab_EnableBroadcastCheckBox, true);

			if (LFGMM_DB.SEARCH.LFM.Dungeon ~= nil) then
				LFGMM_LfmTab_StartStopSearchButton:Enable();
			else
				LFGMM_LfmTab_StartStopSearchButton:Disable();
			end
		end
	end
end


function LFGMM_LfmTab_DungeonDropDown_OnInitialize(self, level)
	local createSingleDungeonItem = function(dungeon)
		local item = LFGMM_Utility_CreateDungeonDropdownItem(dungeon);
		item.keepShownOnClick = false;
		item.isNotRadio = true;
		item.checked = LFGMM_DB.SEARCH.LFM.Dungeon == dungeon.Index;
		item.func = LFGMM_LfmTab_DungeonDropDown_Item_OnClick;
		UIDropDownMenu_AddButton(item, 1);
	end
	
	local createMultiDungeonItem = function(dungeon)
		-- Get available subdungeons
		local availableSubDungeons = {};
		for _,subDungeonIndex in ipairs(dungeon.SubDungeons) do
			if (LFGMM_Utility_IsDungeonAvailable(LFGMM_GLOBAL.DUNGEONS[subDungeonIndex])) then
				table.insert(availableSubDungeons, subDungeonIndex);
			end
		end

		local item = LFGMM_Utility_CreateDungeonDropdownItem(dungeon);
		item.hasArrow = true;
		item.keepShownOnClick = false;
		item.isNotRadio = not LFGMM_Utility_ArrayContains(availableSubDungeons, LFGMM_DB.SEARCH.LFM.Dungeon)
		item.checked = LFGMM_DB.SEARCH.LFM.Dungeon == dungeon.Index or LFGMM_Utility_ArrayContains(availableSubDungeons, LFGMM_DB.SEARCH.LFM.Dungeon);
		item.value = { DungeonIndexes = availableSubDungeons, ParentDungeonIndex = dungeon.Index };
		item.func = LFGMM_LfmTab_DungeonDropDown_Item_OnClick;
		UIDropDownMenu_AddButton(item, 1);
	end
	
	local createSubDungeonItem = function(dungeonIndex, parentDungeonIndex)
		local dungeon = LFGMM_GLOBAL.DUNGEONS[dungeonIndex];
		local item = LFGMM_Utility_CreateDungeonDropdownItem(dungeon);
		item.keepShownOnClick = false;
		item.isNotRadio = LFGMM_DB.SEARCH.LFM.Dungeon ~= parentDungeonIndex;
		item.checked = LFGMM_DB.SEARCH.LFM.Dungeon == dungeon.Index or LFGMM_DB.SEARCH.LFM.Dungeon == parentDungeonIndex;
		item.func = LFGMM_LfmTab_DungeonDropDown_Item_OnClick;
		UIDropDownMenu_AddButton(item, 2);
	end
	
	if (level == 1) then
		-- Get dungeons and raids to list
		local dungeonsList, raidsList, pvpList = LFGMM_Utility_GetAvailableDungeonsAndRaidsSorted();

		if (table.getn(dungeonsList) > 0 or table.getn(raidsList) > 0) then
			local buttonIndex = 1;
			
			if (table.getn(dungeonsList) > 0) then
				if (table.getn(raidsList) > 0 or table.getn(pvpList) > 0) then
					-- Dungeons header
					local dungeonsHeader = UIDropDownMenu_CreateInfo();
					dungeonsHeader.text = "Dungeon";
					dungeonsHeader.isTitle = true;
					dungeonsHeader.notCheckable = true;
					UIDropDownMenu_AddButton(dungeonsHeader);
					buttonIndex = buttonIndex + 1;
				end
				
				-- Dungeon menu items
				for _,dungeon in ipairs(dungeonsList) do
					if (dungeon.ParentDungeon == nil) then
						if (dungeon.SubDungeons == nil) then
							createSingleDungeonItem(dungeon);
						else
							createMultiDungeonItem(dungeon, buttonIndex);
						end
						buttonIndex = buttonIndex + 1;
					end
				end
			end
				
			if (table.getn(raidsList) > 0) then
				if (table.getn(dungeonsList) > 0 or table.getn(pvpList) > 0) then
					-- Raids header
					local raidsHeader = UIDropDownMenu_CreateInfo();
					raidsHeader.text = "Raid";
					raidsHeader.isTitle = true;
					raidsHeader.notCheckable = true;
					UIDropDownMenu_AddButton(raidsHeader);
					buttonIndex = buttonIndex + 1;
				end

				-- Raid menu items
				for _,raid in ipairs(raidsList) do
					if (raid.SubDungeons == nil) then
						createSingleDungeonItem(raid);
					else
						createMultiDungeonItem(raid, buttonIndex);
					end
					buttonIndex = buttonIndex + 1;
				end
			end
			
			if (table.getn(pvpList) > 0) then
				if (table.getn(dungeonsList) > 0 or table.getn(raidsList) > 0) then
					-- PvP header
					local pvpHeader = UIDropDownMenu_CreateInfo();
					pvpHeader.text = "PvP";
					pvpHeader.isTitle = true;
					pvpHeader.notCheckable = true;
					UIDropDownMenu_AddButton(pvpHeader);
					buttonIndex = buttonIndex + 1;
				end
				
				-- PvP menu items
				for _,pvp in ipairs(pvpList) do
					if (pvp.SubDungeons == nil) then
						createSingleDungeonItem(pvp);
					else
						createMultiDungeonItem(pvp, buttonIndex);
					end
					buttonIndex = buttonIndex + 1;
				end
			end
			
		else
			-- No valid dungeons item
			local noDungeonsItem = UIDropDownMenu_CreateInfo();
			noDungeonsItem.text = "No available dungeons";
			noDungeonsItem.disabled = true;
			noDungeonsItem.notCheckable = true;
			UIDropDownMenu_AddButton(noDungeonsItem);
		end

	elseif (level == 2) then
		local entry = UIDROPDOWNMENU_MENU_VALUE;

		-- Sub dungeon menu items
		for _,dungeonIndex in ipairs(entry.DungeonIndexes) do
			createSubDungeonItem(dungeonIndex, entry.ParentDungeonIndex);
		end
	end
	
	-- Update search selection text
	LFGMM_LfmTab_DungeonDropDown_UpdateText();
end


function LFGMM_LfmTab_DungeonDropDown_Item_OnClick(self, dungeonIndex)
	-- Set dungeon
	LFGMM_DB.SEARCH.LFM.Dungeon = dungeonIndex;
	
	-- Update broadcast message
	LFGMM_LfmTab_UpdateBroadcastMessage();
	
	-- Update dungeon dropdown text
	LFGMM_LfmTab_DungeonDropDown_UpdateText();
	
	-- Close drop down menus
	CloseDropDownMenus();
	
	-- Refresh
	LFGMM_LfmTab_Refresh();
end


function LFGMM_LfmTab_DungeonDropDown_UpdateText()
	if (LFGMM_DB.SEARCH.LFM.Dungeon == nil) then
		UIDropDownMenu_SetText(LFGMM_LfmTab_DungeonDropDown, "<Select dungeon>");
	else
		local dungeonName = LFGMM_GLOBAL.DUNGEONS[LFGMM_DB.SEARCH.LFM.Dungeon].Name;
		UIDropDownMenu_SetText(LFGMM_LfmTab_DungeonDropDown, dungeonName);
	end
end


function LFGMM_LfmTab_StartStopSearchButton_OnClick()
	PlaySound(SOUNDKIT.GS_LOGIN);

	-- Close drop down
	CloseDropDownMenus();

	if (LFGMM_DB.SEARCH.LFM.Running) then
		LFGMM_DB.SEARCH.LFM.Running = false;
		LFGMM_PopupWindow_Hide();
		LFGMM_BroadcastWindow_CancelBroadcast();
		LFGMM_MainWindowTab1:Show();
		LFGMM_Core_RemoveUnavailableDungeonsFromSelections();

	else
		LFGMM_DB.SEARCH.LFM.Running = true;
		LFGMM_MainWindowTab1:Hide();

		-- Start broadcast
		if (LFGMM_DB.SEARCH.LFM.Broadcast) then
			LFGMM_BroadcastWindow_StartBroadcast();
		end

		-- Reset ignored messages
		for _,message in pairs(LFGMM_GLOBAL.MESSAGES) do
			message.Ignore = {};
		end

		-- Search for group match after 2 seconds
		C_Timer.After(2, LFGMM_Core_FindSearchMatch);
	end
	
	-- Refresh
	LFGMM_LfmTab_Refresh();
end


function LFGMM_LfmTab_MatchLfgCheckBox_OnClick()
	LFGMM_LfmTab_MatchLfgCheckBox:SetChecked(true);
end


function LFGMM_LfmTab_MatchLfmCheckBox_OnClick()
	LFGMM_DB.SEARCH.LFM.MatchLfm = LFGMM_LfmTab_MatchLfmCheckBox:GetChecked();
end


function LFGMM_LfmTab_MatchUnknownCheckBox_OnClick()
	LFGMM_DB.SEARCH.LFM.MatchUnknown = LFGMM_LfmTab_MatchUnknownCheckBox:GetChecked();
end


function LFGMM_LfmTab_EnableBroadcastCheckBox_OnClick()
	LFGMM_DB.SEARCH.LFM.Broadcast = LFGMM_LfmTab_EnableBroadcastCheckBox:GetChecked();

	-- Refresh
	LFGMM_LfmTab_Refresh();
end


function LFGMM_LfmTab_UpdateBroadcastMessage()
	local message = LFGMM_LfmTab_BroadcastMessageTemplateInputBox:GetText();

	-- Store template
	LFGMM_DB.SEARCH.LFM.BroadcastMessageTemplate = message;

	local dungeonText = "<dungeon>";
	local abbreviationText = "<dungeon>";
	local lookingForNumberText = "<number>";
	
	-- Get dungeon
	if (LFGMM_DB.SEARCH.LFM.Dungeon ~= nil) then
		local dungeon = LFGMM_GLOBAL.DUNGEONS[LFGMM_DB.SEARCH.LFM.Dungeon];
		dungeonText = dungeon.Name;
		abbreviationText = dungeon.Abbreviation;

		-- Get number of players
		local lookingForNumber = dungeon.Size - table.getn(LFGMM_GLOBAL.GROUP_MEMBERS);
		if (lookingForNumber < 0) then
			lookingForNumber = 0;
		end
		lookingForNumberText = tostring(lookingForNumber);
	end

	-- Generate message
	message = string.gsub(message, "{[Dd]}", dungeonText);
	message = string.gsub(message, "{[Aa]}", abbreviationText);
	message = string.gsub(message, "{[Nn]}", lookingForNumberText);
	message = string.gsub(message, "{.*}", "");
	message = string.sub(message, 1, 255);

	-- Store message
	LFGMM_DB.SEARCH.LFM.BroadcastMessage = message;

	-- Update preview
	LFGMM_LfmTab_BroadcastMessagePreview_Refresh();
end


function LFGMM_LfmTab_BroadcastMessagePreview_Refresh()
	if (not LFGMM_LfmTab_BroadcastMessagePreview:IsVisible()) then
		return;
	end

	local text = LFGMM_DB.SEARCH.LFM.BroadcastMessage;
	local textLength = string.len(text);
	local maxLength = 40;
	
	if (textLength > maxLength) then
		LFGMM_LfmTab_BroadcastMessagePreviewSlider:SetMinMaxValues(1, textLength - maxLength + 1);
		local sliderPosition = LFGMM_LfmTab_BroadcastMessagePreviewSlider:GetValue();
		text = string.sub(text, sliderPosition, sliderPosition + maxLength - 1);
		LFGMM_LfmTab_BroadcastMessagePreviewSlider:Show();
	else
		LFGMM_LfmTab_BroadcastMessagePreviewSlider:SetValue(1);
		LFGMM_LfmTab_BroadcastMessagePreviewSlider:Hide();
	end
	
	LFGMM_LfmTab_BroadcastMessagePreview:SetText(text);
end


function LFGMM_LfmTab_StartAnimateSearchText()
	-- Ensure lock
	if (not LFGMM_LfgTab.SearchAnimationLock) then
		LFGMM_LfgTab.SearchAnimationLock = true;
		
		-- Start animation
		LFGMM_LfmTab_AnimateSearchingText();
	end
end


function LFGMM_LfmTab_AnimateSearchingText()
	-- Release lock if hidden or search is stopped
	if (not LFGMM_DB.SEARCH.LFM.Running or not LFGMM_LfmTab_SearchActiveText:IsVisible() or not LFGMM_MainWindow:IsVisible()) then
		LFGMM_LfgTab.SearchAnimationLock = false;
		return;
	end

	-- Get next string value
	LFGMM_LfmTab_SearchActiveText.StringAnimation = LFGMM_LfmTab_SearchActiveText.StringAnimation .. ".";
	if (string.len(LFGMM_LfmTab_SearchActiveText.StringAnimation) > 3) then
		LFGMM_LfmTab_SearchActiveText.StringAnimation = "";
	end

	-- Update text
	LFGMM_LfmTab_SearchActiveText:SetText("Searching" .. LFGMM_LfmTab_SearchActiveText.StringAnimation);

	-- Queue next update
	C_Timer.After(0.5, LFGMM_LfmTab_AnimateSearchingText)
end


function LFGMM_LfmTab_BroadcastMessageInfoButton_OnClick()
	if (LFGMM_LfmTab_BroadcastMessageInfoWindow:IsVisible()) then
		LFGMM_LfmTab_BroadcastMessageInfoWindow:Hide();
	else
		LFGMM_LfgTab_BroadcastMessageInfoWindow:Hide();
		LFGMM_LfmTab_BroadcastMessageInfoWindow:Show();
		LFGMM_SettingsTab_RequestInviteMessageInfoWindow:Hide();
		LFGMM_ListTab_MessageInfoWindow:Hide();
	end
end

