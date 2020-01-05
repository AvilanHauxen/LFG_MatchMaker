--[[
	LFG MatchMaker - Addon for World of Warcraft.
	Version: 1.0.4
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
-- LFG TAB
------------------------------------------------------------------------------------------------------------------------


function LFGMM_LfgTab_Initialize()
	LFGMM_LfgTab_SearchActiveText.StringAnimation = "";

	LFGMM_Utility_InitializeDropDown(LFGMM_LfgTab_DungeonsDropDown, 200, LFGMM_LfgTab_DungeonsDropDown_OnInitialize);

	LFGMM_LfgTab_StartStopSearchButton:SetScript("OnClick", LFGMM_LfgTab_StartStopSearchButton_OnClick);

	LFGMM_Utility_InitializeCheckbox(LFGMM_LfgTab_MatchLfgCheckBox,	"LFG", "Get notifications on LFG messages",	LFGMM_DB.SEARCH.LFG.MatchLfg, LFGMM_LfgTab_MatchLfgCheckBox_OnClick);
	LFGMM_Utility_InitializeCheckbox(LFGMM_LfgTab_MatchLfmCheckBox,	"LFM", "Get notifications on LFM messages", true, LFGMM_LfgTab_MatchLfmCheckBox_OnClick);
	LFGMM_Utility_InitializeCheckbox(LFGMM_LfgTab_MatchUnknownCheckBox, "Unknown", "Get notifications when dungeon matches, but LFG/LFM cannot be determined", LFGMM_DB.SEARCH.LFG.MatchUnknown, LFGMM_LfgTab_MatchUnknownCheckBox_OnClick);
	LFGMM_Utility_InitializeCheckbox(LFGMM_LfgTab_EnableBroadcastCheckBox, "Broadcast in LFG channel", "Periodically send LFG messages to LookingForGroup channel", LFGMM_DB.SEARCH.LFG.Broadcast, LFGMM_LfgTab_EnableBroadcastCheckBox_OnClick);

	LFGMM_LfgTab_BroadcastMessageTemplateInputBox:SetScript("OnTextChanged", LFGMM_LfgTab_UpdateBroadcastMessage);
	LFGMM_LfgTab_BroadcastMessageTemplateInputBox:SetText(LFGMM_DB.SEARCH.LFG.BroadcastMessageTemplate);

	LFGMM_Utility_InitializeHiddenSlider(LFGMM_LfgTab_BroadcastMessagePreviewSlider, LFGMM_LfgTab_BroadcastMessagePreview_Refresh);
	LFGMM_LfgTab_BroadcastMessagePreviewSliderLow:SetText("");
	LFGMM_LfgTab_BroadcastMessagePreviewSliderHigh:SetText("");

	LFGMM_LfgTab_BroadcastMessageInfoButton:SetScript("OnClick", LFGMM_LfgTab_BroadcastMessageInfoButton_OnClick);
	
	LFGMM_LfgTab.SearchAnimationLock = false;
end


function LFGMM_LfgTab_Show()
	PanelTemplates_SetTab(LFGMM_MainWindow, 1);
	
	LFGMM_LfgTab_BroadcastMessageInfoWindow:Hide();
	LFGMM_LfmTab_BroadcastMessageInfoWindow:Hide();
	LFGMM_SettingsTab_RequestInviteMessageInfoWindow:Hide();
	LFGMM_ListTab_MessageInfoWindow_Hide();

	LFGMM_LfgTab:Show();
	LFGMM_LfmTab:Hide();
	LFGMM_ListTab:Hide();
	LFGMM_SettingsTab:Hide();

	LFGMM_MainWindowTab1:SetPoint ("CENTER", "LFGMM_MainWindow", "BOTTOMLEFT",    60, -17);
	LFGMM_MainWindowTab2:SetPoint ("CENTER", "LFGMM_MainWindow", "BOTTOMLEFT",   135, -14);
	LFGMM_MainWindowTab3:SetPoint ("CENTER", "LFGMM_MainWindow", "BOTTOMRIGHT", -140, -14);
	LFGMM_MainWindowTab4:SetPoint ("CENTER", "LFGMM_MainWindow", "BOTTOMRIGHT",  -60, -14);
	
	LFGMM_LfgTab_Refresh();
end


function LFGMM_LfgTab_Refresh()
	if (not LFGMM_LfgTab:IsVisible()) then
		return;
	end

	if (LFGMM_DB.SEARCH.LFG.Broadcast) then
		LFGMM_LfgTab_BroadcastMessageTemplateInputBox:Show();
		LFGMM_LfgTab_BroadcastMessageInfoButton:Show();
		LFGMM_LfgTab_BroadcastMessagePreview:Show();
		LFGMM_LfgTab_BroadcastMessagePreview_Refresh();
	else
		LFGMM_LfgTab_BroadcastMessageTemplateInputBox:Hide();
		LFGMM_LfgTab_BroadcastMessageInfoButton:Hide();
		LFGMM_LfgTab_BroadcastMessagePreview:Hide();
		LFGMM_LfgTab_BroadcastMessagePreviewSlider:Hide();
		LFGMM_LfgTab_BroadcastMessageInfoWindow:Hide();
	end

	local groupSize = table.getn(LFGMM_GLOBAL.GROUP_MEMBERS);
	if (groupSize > 1) then
		LFGMM_LfgTab_InGroupText:Show();

		UIDropDownMenu_EnableDropDown(LFGMM_LfgTab_DungeonsDropDown);
		LFGMM_LfgTab_SearchActiveText:Hide();
		LFGMM_LfgTab_StartStopSearchButton:Disable();
		LFGMM_LfgTab_StartStopSearchButton:SetText("Start search");
		LFGMM_LfgTab_MatchOnText:SetFontObject("GameFontNormal");
		LFGMM_LfgTab_BroadcastMessageTemplateInputBox:Enable();
		LFGMM_Utility_ToggleCheckBoxEnabled(LFGMM_LfgTab_MatchLfgCheckBox, true);
		LFGMM_Utility_ToggleCheckBoxEnabled(LFGMM_LfgTab_MatchLfmCheckBox, true);
		LFGMM_Utility_ToggleCheckBoxEnabled(LFGMM_LfgTab_MatchUnknownCheckBox, true);
		LFGMM_Utility_ToggleCheckBoxEnabled(LFGMM_LfgTab_EnableBroadcastCheckBox, true);

	else
		LFGMM_LfgTab_InGroupText:Hide();
	
		if (LFGMM_DB.SEARCH.LFG.Running) then
			UIDropDownMenu_DisableDropDown(LFGMM_LfgTab_DungeonsDropDown);
			LFGMM_LfgTab_SearchActiveText:Show();
			LFGMM_LfgTab_StartStopSearchButton:SetText("Stop searching");
			LFGMM_LfgTab_MatchOnText:SetFontObject("GameFontHighlight");
			LFGMM_LfgTab_BroadcastMessageTemplateInputBox:Disable();
			LFGMM_LfgTab_StartAnimateSearchingText();
			LFGMM_Utility_ToggleCheckBoxEnabled(LFGMM_LfgTab_MatchLfgCheckBox, false);
			LFGMM_Utility_ToggleCheckBoxEnabled(LFGMM_LfgTab_MatchLfmCheckBox, false);
			LFGMM_Utility_ToggleCheckBoxEnabled(LFGMM_LfgTab_MatchUnknownCheckBox, false);
			LFGMM_Utility_ToggleCheckBoxEnabled(LFGMM_LfgTab_EnableBroadcastCheckBox, false);
		else
			UIDropDownMenu_EnableDropDown(LFGMM_LfgTab_DungeonsDropDown);
			LFGMM_LfgTab_SearchActiveText:Hide();
			LFGMM_LfgTab_StartStopSearchButton:SetText("Start search");
			LFGMM_LfgTab_MatchOnText:SetFontObject("GameFontNormal");
			LFGMM_LfgTab_BroadcastMessageTemplateInputBox:Enable();
			LFGMM_Utility_ToggleCheckBoxEnabled(LFGMM_LfgTab_MatchLfgCheckBox, true);
			LFGMM_Utility_ToggleCheckBoxEnabled(LFGMM_LfgTab_MatchLfmCheckBox, true);
			LFGMM_Utility_ToggleCheckBoxEnabled(LFGMM_LfgTab_MatchUnknownCheckBox, true);
			LFGMM_Utility_ToggleCheckBoxEnabled(LFGMM_LfgTab_EnableBroadcastCheckBox, true);

			if (table.getn(LFGMM_DB.SEARCH.LFG.Dungeons) > 0) then
				LFGMM_LfgTab_StartStopSearchButton:Enable();
			else
				LFGMM_LfgTab_StartStopSearchButton:Disable();
			end
		end
	end
end


function LFGMM_LfgTab_DungeonsDropDown_OnInitialize(self, level)
	local updateMenuItem = function(menuItem, isChecked, isRadio)
		if (isChecked) then
			_G[menuItem:GetName()].checked = true;
			_G[menuItem:GetName() .. "Check"]:Show();
			_G[menuItem:GetName() .. "UnCheck"]:Hide();
		else
			_G[menuItem:GetName()].checked = false;
			_G[menuItem:GetName() .. "Check"]:Hide();
			_G[menuItem:GetName() .. "UnCheck"]:Show();
		end
		
		if (isRadio) then
			_G[menuItem:GetName()].isNotRadio = false;
			_G[menuItem:GetName() .. "Check"]:SetTexCoord(0.0, 0.5, 0.5, 1.0);
			_G[menuItem:GetName() .. "UnCheck"]:SetTexCoord(0.5, 1.0, 0.5, 1.0);
		else
			_G[menuItem:GetName()].isNotRadio = true;
			_G[menuItem:GetName() .. "Check"]:SetTexCoord(0.0, 0.5, 0.0, 0.5);
			_G[menuItem:GetName() .. "UnCheck"]:SetTexCoord(0.5, 1.0, 0.0, 0.5);
		end
	end
	
	local createSingleDungeonItem = function(dungeon)
		local item = LFGMM_Utility_CreateDungeonDropdownItem(dungeon);
		item.keepShownOnClick = true;
		item.isNotRadio = true;
		item.checked = LFGMM_Utility_ArrayContains(LFGMM_DB.SEARCH.LFG.Dungeons, dungeon.Index);
		item.func = function(self, dungeonIndex)
			if (self.checked) then
				table.insert(LFGMM_DB.SEARCH.LFG.Dungeons, dungeonIndex);
			else
				LFGMM_Utility_ArrayRemove(LFGMM_DB.SEARCH.LFG.Dungeons, dungeonIndex);
			end

			LFGMM_LfgTab_DungeonsDropDown_Item_OnClick();
		end
		UIDropDownMenu_AddButton(item, 1);
	end
	
	local createMultiDungeonItem = function(dungeon, buttonIndex)
		local availableSubDungeons = {};
		for _,subDungeonIndex in ipairs(dungeon.SubDungeons) do
			if (LFGMM_Utility_IsDungeonAvailable(LFGMM_GLOBAL.DUNGEONS[subDungeonIndex])) then
				table.insert(availableSubDungeons, subDungeonIndex);
			end
		end
		
		local hasUnavailableSubDungeons = table.getn(availableSubDungeons) ~= table.getn(dungeon.SubDungeons);
		
		local item = LFGMM_Utility_CreateDungeonDropdownItem(dungeon);
		item.hasArrow = true;
		item.keepShownOnClick = true;
		item.isNotRadio = not LFGMM_Utility_ArrayContainsAny(LFGMM_DB.SEARCH.LFG.Dungeons, availableSubDungeons);
		item.checked = LFGMM_Utility_ArrayContains(LFGMM_DB.SEARCH.LFG.Dungeons, dungeon.Index) or LFGMM_Utility_ArrayContainsAny(LFGMM_DB.SEARCH.LFG.Dungeons, availableSubDungeons);
		item.value = { DungeonIndexes = availableSubDungeons, HasUnavailableSubDungeons = hasUnavailableSubDungeons, ParentDungeonIndex = dungeon.Index, ParentMenuItem = _G["DropDownList1Button" .. buttonIndex] };
		item.func = function(self, dungeonIndex)
			if (self.checked) then
				updateMenuItem(self, true, false);
				for index,_ in ipairs(availableSubDungeons) do
					updateMenuItem(_G["DropDownList2Button" .. index], true, true);
				end

				table.insert(LFGMM_DB.SEARCH.LFG.Dungeons, dungeon.Index);
				LFGMM_Utility_ArrayRemove(LFGMM_DB.SEARCH.LFG.Dungeons, availableSubDungeons);

			else
				updateMenuItem(self, false, false);
				for index,_ in ipairs(availableSubDungeons) do
					updateMenuItem(_G["DropDownList2Button" .. index], false, false);
				end
				
				LFGMM_Utility_ArrayRemove(LFGMM_DB.SEARCH.LFG.Dungeons, dungeon.Index, availableSubDungeons);
			end
			
			LFGMM_LfgTab_DungeonsDropDown_Item_OnClick();
		end
		UIDropDownMenu_AddButton(item, 1);
		
		-- Set initial isNotRadio value
		_G["DropDownList1Button" .. buttonIndex].isNotRadio = item.isNotRadio;
	end
	
	local createSubDungeonItem = function(dungeonIndex, entry)
		local dungeon = LFGMM_GLOBAL.DUNGEONS[dungeonIndex];
		local item = LFGMM_Utility_CreateDungeonDropdownItem(dungeon);
		item.keepShownOnClick = true;
		item.isNotRadio = not LFGMM_Utility_ArrayContains(LFGMM_DB.SEARCH.LFG.Dungeons, entry.ParentDungeonIndex);
		item.checked = LFGMM_Utility_ArrayContains(LFGMM_DB.SEARCH.LFG.Dungeons, entry.ParentDungeonIndex) or LFGMM_Utility_ArrayContains(LFGMM_DB.SEARCH.LFG.Dungeons, dungeonIndex);
		item.func = function(self, dungeonIndex)
			local numDungeonsChecked = 0;
			for _,menuItem in ipairs(entry.MenuItems) do
				if (menuItem.checked) then
					numDungeonsChecked = numDungeonsChecked + 1;
				end
			end
			
			if (self.checked) then
				if (not entry.HasUnavailableSubDungeons and numDungeonsChecked == table.getn(entry.MenuItems)) then
					updateMenuItem(entry.ParentMenuItem, true, false);
					for _,menuItem in ipairs(entry.MenuItems) do
						updateMenuItem(menuItem, true, true);
					end

					table.insert(LFGMM_DB.SEARCH.LFG.Dungeons, entry.ParentDungeonIndex);
					LFGMM_Utility_ArrayRemove(LFGMM_DB.SEARCH.LFG.Dungeons, entry.DungeonIndexes);

				else
					updateMenuItem(entry.ParentMenuItem, true, true);
					updateMenuItem(self, true, false);

					table.insert(LFGMM_DB.SEARCH.LFG.Dungeons, dungeonIndex);
				end
			
			else
				if (numDungeonsChecked == 0) then
					updateMenuItem(entry.ParentMenuItem, false, false);
					updateMenuItem(self, false, false);
					
					LFGMM_Utility_ArrayRemove(LFGMM_DB.SEARCH.LFG.Dungeons, dungeonIndex, entry.ParentDungeonIndex);
				
				elseif (numDungeonsChecked == (table.getn(entry.MenuItems)-1) and entry.ParentMenuItem.checked and entry.ParentMenuItem.isNotRadio) then
					updateMenuItem(entry.ParentMenuItem, true, true);
					for _,menuItem in ipairs(entry.MenuItems) do
						updateMenuItem(menuItem, true, false);
					end
					updateMenuItem(self, false, false);
					
					for _,itemDungeonIndex in ipairs(entry.DungeonIndexes) do
						table.insert(LFGMM_DB.SEARCH.LFG.Dungeons, itemDungeonIndex);
					end
					LFGMM_Utility_ArrayRemove(LFGMM_DB.SEARCH.LFG.Dungeons, dungeonIndex, entry.ParentDungeonIndex);
					
				else
					updateMenuItem(self, false, false);
					
					LFGMM_Utility_ArrayRemove(LFGMM_DB.SEARCH.LFG.Dungeons, dungeonIndex);
				end
			end

			LFGMM_LfgTab_DungeonsDropDown_Item_OnClick();
		end
		UIDropDownMenu_AddButton(item, 2);
	end
	
	if (level == 1) then
		-- Get dungeons and raids to list
		local dungeonsList, raidsList, pvpList = LFGMM_Utility_GetAvailableDungeonsAndRaidsSorted();

		if (table.getn(dungeonsList) > 0 or table.getn(raidsList) > 0) then
			-- Clear selections menu item
			local clearItem = UIDropDownMenu_CreateInfo();
			clearItem.text = "<Clear selection>";
			clearItem.justifyH = "CENTER";
			clearItem.notCheckable = true;
			clearItem.func = LFGMM_LfgTab_DungeonsDropDown_ClearSelections_OnClick;
			UIDropDownMenu_AddButton(clearItem);

			local buttonIndex = 2;

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
			-- No available dungeons item
			local noDungeonsItem = UIDropDownMenu_CreateInfo();
			noDungeonsItem.text = "No available dungeons";
			noDungeonsItem.disabled = true;
			noDungeonsItem.notCheckable = true;
			UIDropDownMenu_AddButton(noDungeonsItem);
		end

	elseif (level == 2) then
		local entry = UIDROPDOWNMENU_MENU_VALUE;
		entry.MenuItems = {};
		
		-- Sub dungeon menu items
		for buttonIndex,dungeonIndex in ipairs(entry.DungeonIndexes) do
			table.insert(entry.MenuItems, _G["DropDownList2Button" .. buttonIndex]);
			createSubDungeonItem(dungeonIndex, entry);
		end
	end
	
	-- Update search selection text
	LFGMM_LfgTab_DungeonsDropDown_UpdateText();
end


function LFGMM_LfgTab_DungeonsDropDown_ClearSelections_OnClick()
	-- Clear dungeons
	LFGMM_DB.SEARCH.LFG.Dungeons = {};
	
	-- Update LFG broadcast preview message
	LFGMM_LfgTab_UpdateBroadcastMessage();

	-- Update search selection text
	LFGMM_LfgTab_DungeonsDropDown_UpdateText();
	
	-- Refresh
	LFGMM_LfgTab_Refresh();
end


function LFGMM_LfgTab_DungeonsDropDown_Item_OnClick()
	-- Update broadcast message
	LFGMM_LfgTab_UpdateBroadcastMessage();
	
	-- Update dungeons dropdown text
	LFGMM_LfgTab_DungeonsDropDown_UpdateText();
	
	-- Refresh
	LFGMM_LfgTab_Refresh();
end


function LFGMM_LfgTab_DungeonsDropDown_UpdateText()
	local numDungeons = table.getn(LFGMM_DB.SEARCH.LFG.Dungeons);
	if (numDungeons == 1) then
		UIDropDownMenu_SetText(LFGMM_LfgTab_DungeonsDropDown, LFGMM_GLOBAL.DUNGEONS[LFGMM_DB.SEARCH.LFG.Dungeons[1]].Name);
	elseif( numDungeons > 1) then
		UIDropDownMenu_SetText(LFGMM_LfgTab_DungeonsDropDown, tostring(numDungeons) .. " dungeons selected");
	else
		UIDropDownMenu_SetText(LFGMM_LfgTab_DungeonsDropDown, "<Select dungeon(s)>");
	end
end


function LFGMM_LfgTab_StartStopSearchButton_OnClick()
	PlaySound(SOUNDKIT.GS_LOGIN);

	-- Close drop down
	CloseDropDownMenus();

	if (LFGMM_DB.SEARCH.LFG.Running) then
		LFGMM_DB.SEARCH.LFG.Running = false;
		LFGMM_PopupWindow_Hide();
		LFGMM_BroadcastWindow_CancelBroadcast();
		LFGMM_MainWindowTab2:Show();
		LFGMM_Core_RemoveUnavailableDungeonsFromSelections();
		
	else
		LFGMM_DB.SEARCH.LFG.Running = true;
		LFGMM_MainWindowTab2:Hide();

		-- Start broadcast
		if (LFGMM_DB.SEARCH.LFG.Broadcast) then
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
	LFGMM_LfgTab_Refresh();
end


function LFGMM_LfgTab_MatchLfgCheckBox_OnClick()
	LFGMM_DB.SEARCH.LFG.MatchLfg = LFGMM_LfgTab_MatchLfgCheckBox:GetChecked();
end


function LFGMM_LfgTab_MatchLfmCheckBox_OnClick()
	LFGMM_LfgTab_MatchLfmCheckBox:SetChecked(true);
end


function LFGMM_LfgTab_MatchUnknownCheckBox_OnClick()
	LFGMM_DB.SEARCH.LFG.MatchUnknown = LFGMM_LfgTab_MatchUnknownCheckBox:GetChecked();
end


function LFGMM_LfgTab_EnableBroadcastCheckBox_OnClick()
	LFGMM_DB.SEARCH.LFG.Broadcast = LFGMM_LfgTab_EnableBroadcastCheckBox:GetChecked();
	
	-- Refresh
	LFGMM_LfgTab_Refresh();
end


function LFGMM_LfgTab_UpdateBroadcastMessage()
	local message = LFGMM_LfgTab_BroadcastMessageTemplateInputBox:GetText();

	-- Store template
	LFGMM_DB.SEARCH.LFG.BroadcastMessageTemplate = message;

	-- Get selected dungeons
	local selectedDungeons = {};
	local dungeonsText = "<dungeon(s)>";
	local abbreviationsText = "<dungeon(s)>";

	-- Get selected dungeons text
	if (table.getn(LFGMM_DB.SEARCH.LFG.Dungeons) > 0) then
		for _,searchDungeonIndex in ipairs(LFGMM_DB.SEARCH.LFG.Dungeons) do
			table.insert(selectedDungeons, LFGMM_GLOBAL.DUNGEONS[searchDungeonIndex]);
		end
		dungeonsText,abbreviationsText = LFGMM_Utility_GetDungeonMessageText(selectedDungeons, ", ", " or ", false)
	end

	-- Generate message
	message = string.gsub(message, "{[Ll]}", LFGMM_GLOBAL.PLAYER_LEVEL);
	message = string.gsub(message, "{[Cc]}", LFGMM_GLOBAL.PLAYER_CLASS.Name);
	message = string.gsub(message, "{[Xx]}", LFGMM_GLOBAL.PLAYER_CLASS.LocalizedName);
	message = string.gsub(message, "{[Dd]}", dungeonsText);
	message = string.gsub(message, "{[Aa]}", abbreviationsText);
	message = string.gsub(message, "{.*}", "");
	message = string.sub(message, 1, 255);

	-- Store broadcast message
	LFGMM_DB.SEARCH.LFG.BroadcastMessage = message;

	-- Update message preview
	LFGMM_LfgTab_BroadcastMessagePreview_Refresh();
end


function LFGMM_LfgTab_BroadcastMessagePreview_Refresh()
	if (not LFGMM_LfgTab_BroadcastMessagePreview:IsVisible()) then
		return;
	end

	local text = LFGMM_DB.SEARCH.LFG.BroadcastMessage;
	local textLength = string.len(text);
	local maxLength = 40;

	if (textLength > maxLength) then
		LFGMM_LfgTab_BroadcastMessagePreviewSlider:SetMinMaxValues(1, textLength - maxLength + 1);
		local sliderPosition = LFGMM_LfgTab_BroadcastMessagePreviewSlider:GetValue();
		text = string.sub(text, sliderPosition, sliderPosition + maxLength - 1);
		LFGMM_LfgTab_BroadcastMessagePreviewSlider:Show();
	else
		LFGMM_LfgTab_BroadcastMessagePreviewSlider:SetValue(1);
		LFGMM_LfgTab_BroadcastMessagePreviewSlider:Hide();
	end
	
	LFGMM_LfgTab_BroadcastMessagePreview:SetText(text);
end


function LFGMM_LfgTab_StartAnimateSearchingText()
	-- Ensure lock
	if (not LFGMM_LfgTab.SearchAnimationLock) then
		LFGMM_LfgTab.SearchAnimationLock = true;

		-- Start animation
		LFGMM_LfgTab_AnimateSearchingText();
	end
end


function LFGMM_LfgTab_AnimateSearchingText()
	-- Release lock if hidden or search is stopped
	if (not LFGMM_MainWindow:IsVisible() or not LFGMM_LfgTab_SearchActiveText:IsVisible() or not LFGMM_DB.SEARCH.LFG.Running) then
		LFGMM_LfgTab.SearchAnimationLock = false;
		return;
	end
	
	-- Get next string value
	LFGMM_LfgTab_SearchActiveText.StringAnimation = LFGMM_LfgTab_SearchActiveText.StringAnimation .. ".";
	if (string.len(LFGMM_LfgTab_SearchActiveText.StringAnimation) > 3) then
		LFGMM_LfgTab_SearchActiveText.StringAnimation = "";
	end

	-- Update text
	LFGMM_LfgTab_SearchActiveText:SetText("Searching" .. LFGMM_LfgTab_SearchActiveText.StringAnimation);

	-- Queue next update
	C_Timer.After(0.5, LFGMM_LfgTab_AnimateSearchingText)
end


function LFGMM_LfgTab_BroadcastMessageInfoButton_OnClick()
	if (LFGMM_LfgTab_BroadcastMessageInfoWindow:IsVisible()) then
		LFGMM_LfgTab_BroadcastMessageInfoWindow:Hide();
	else
		LFGMM_LfgTab_BroadcastMessageInfoWindow:Show();
		LFGMM_LfmTab_BroadcastMessageInfoWindow:Hide();
		LFGMM_SettingsTab_RequestInviteMessageInfoWindow:Hide();
		LFGMM_ListTab_MessageInfoWindow:Hide();
	end
end

