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
-- LIST TAB
------------------------------------------------------------------------------------------------------------------------


function LFGMM_ListTab_Initialize()
	LFGMM_Utility_InitializeDropDown(LFGMM_ListTab_DungeonsDropDown, 125, LFGMM_ListTab_DungeonsDropDown_OnInitialize);
	LFGMM_ListTab_DungeonsDropDown_UpdateText();

	LFGMM_Utility_InitializeDropDown(LFGMM_ListTab_MessageTypeDropDown, 135, LFGMM_ListTab_MessageTypeDropDown_OnInitialize);
	LFGMM_ListTab_MessageTypeDropDown_UpdateText();

	LFGMM_ListTab:EnableMouseWheel(true);
	LFGMM_ListTab:SetScript("OnMouseWheel", LFGMM_ListTab_OnMouseWheel);
	LFGMM_Utility_InitializeHiddenSlider(LFGMM_ListTab_ScrollBarSlider, LFGMM_ListTab_ScrollBarSlider_OnValueChanged);

	LFGMM_ListTab_MessageInfoWindow_WhisperButton:SetScript("OnClick", LFGMM_ListTab_MessageInfoWindow_WhisperButton_OnClick);
	LFGMM_ListTab_MessageInfoWindow_WhoButton:SetScript("OnClick", LFGMM_ListTab_MessageInfoWindow_WhoButton_OnClick);
	LFGMM_ListTab_MessageInfoWindow_InviteButton:SetScript("OnClick", LFGMM_ListTab_MessageInfoWindow_InviteButton_OnClick);
	LFGMM_ListTab_MessageInfoWindow_RequestInviteButton:SetScript("OnClick", LFGMM_ListTab_MessageInfoWindow_RequestInviteButton_OnClick);
end


function LFGMM_ListTab_Show()
	PanelTemplates_SetTab(LFGMM_MainWindow, 3);
						
	LFGMM_LfgTab_BroadcastMessageInfoWindow:Hide();
	LFGMM_LfmTab_BroadcastMessageInfoWindow:Hide();
	LFGMM_SettingsTab_RequestInviteMessageInfoWindow:Hide();
	LFGMM_ListTab_MessageInfoWindow_Hide();

	LFGMM_LfgTab:Hide();
	LFGMM_LfmTab:Hide();
	LFGMM_ListTab:Show();
	LFGMM_SettingsTab:Hide();
	
	LFGMM_MainWindowTab1:SetPoint ("CENTER", "LFGMM_MainWindow", "BOTTOMLEFT",    60, -14);
	LFGMM_MainWindowTab2:SetPoint ("CENTER", "LFGMM_MainWindow", "BOTTOMLEFT",   135, -14);
	LFGMM_MainWindowTab3:SetPoint ("CENTER", "LFGMM_MainWindow", "BOTTOMRIGHT", -140, -17);
	LFGMM_MainWindowTab4:SetPoint ("CENTER", "LFGMM_MainWindow", "BOTTOMRIGHT",  -60, -14);
	
	LFGMM_ListTab_Refresh();
end


function LFGMM_ListTab_Refresh()
	-- Return if window is hidden
	if (not LFGMM_ListTab:IsVisible()) then
		return;
	end

	-- Filter messages
	local filteredMessages = {};
	for _,message in pairs(LFGMM_GLOBAL.MESSAGES) do
		local skip = false;
		
		-- Determine if message should be skipped
		if ((not LFGMM_DB.LIST.MessageTypes.Unknown and message.Type == "UNKNOWN") or 
			(not LFGMM_DB.LIST.MessageTypes.Lfg and message.Type == "LFG") or
			(not LFGMM_DB.LIST.MessageTypes.Lfm and message.Type == "LFM"))
		then
			skip = true;

		elseif (table.getn(message.Dungeons) == 0 and LFGMM_DB.LIST.ShowUnknownDungeons) then
			skip = false;

		else
			local dungeonFilterMatched = false;
			for _,dungeon in ipairs(message.Dungeons) do
				local subDungeonFound = false;

				-- Do not match on parent dungeon if subdungeon is also matched
				if (dungeon.SubDungeons ~= nil) then
					for _,dungeon2 in ipairs(message.Dungeons) do
						if (LFGMM_Utility_ArrayContains(dungeon.SubDungeons, dungeon2.Index)) then
							subDungeonFound = true;
							break;
						end
					end
				end
				
				if (not subDungeonFound and LFGMM_Utility_ArrayContains(LFGMM_DB.LIST.Dungeons, dungeon.Index)) then
					dungeonFilterMatched = true;
					break;
				end
			end

			if (not dungeonFilterMatched) then
				skip = true;
			end
		end
		
		-- Add message
		if (not skip) then
			table.insert(filteredMessages, message);
		else
			LFGMM_ListTab_MessageInfoWindow_HideForMessage(message);
		end
	end
	
	-- Sort messages
	table.sort(filteredMessages, function(left, right) return left.SortIndex < right.SortIndex;	end);

	-- Get number of messages
	local numMessages = table.getn(filteredMessages);

	-- Set start entry index and show/hide scrollbar
	local startEntryIndex = 1;
	if (numMessages > 7) then
		local maxScrollValue = numMessages - 6;
		LFGMM_ListTab_ScrollBarSlider:SetMinMaxValues(1, maxScrollValue);
		if (LFGMM_ListTab_ScrollBarSlider:GetValue() > maxScrollValue) then
			LFGMM_ListTab_ScrollBarSlider:SetValue(maxScrollValue);
		end
		LFGMM_ListTab_ScrollBarSlider:Show();

		startEntryIndex = math.floor(LFGMM_ListTab_ScrollBarSlider:GetValue());
	else
		LFGMM_ListTab_ScrollBarSlider:SetMinMaxValues(1, 1);
		LFGMM_ListTab_ScrollBarSlider:SetValue(1);
		LFGMM_ListTab_ScrollBarSlider:Hide();
	end

	-- Fill list
	local entryIndex = 1;
	for index=startEntryIndex,startEntryIndex+6 do
		if (filteredMessages[index] ~= nil) then
			local message = filteredMessages[index];
		
			-- Class
			getglobal("LFGMM_ListTab_Entry" .. entryIndex .. "ClassIcon"):SetTexCoord(unpack(message.PlayerClass.IconCoordinates));
		
			-- Player
			getglobal("LFGMM_ListTab_Entry" .. entryIndex .. "PlayerName"):SetText(message.PlayerClass.Color .. message.Player);

			-- Message
			local messageText = message.Message;
			local messageLabel = getglobal("LFGMM_ListTab_Entry" .. entryIndex .. "Message");
			messageLabel:SetText(messageText);
			if (messageLabel:GetStringWidth() > 280) then
				while (messageLabel:GetStringWidth() > 280) do
					messageText = string.sub(messageText, 1, string.len(messageText) - 1);
					messageLabel:SetText(messageText);
				end
				messageText = messageText .. "...";
				messageLabel:SetText(messageText);
			end
		
			-- Dungeons
			local dungeonsLabel = getglobal("LFGMM_ListTab_Entry" .. entryIndex .. "Dungeon");
			if (table.getn(message.Dungeons) == 0) then
				dungeonsLabel:SetText("?");
				dungeonsLabel:SetTextColor(1, 0, 0);
			else
				local _,dungeonsText = LFGMM_Utility_GetDungeonMessageText(message.Dungeons, ", ", ", ", true);
				dungeonsLabel:SetText(dungeonsText);
				dungeonsLabel:SetTextColor(0, 1, 0);
				
				if (dungeonsLabel:GetStringWidth() > 280) then
				while (dungeonsLabel:GetStringWidth() > 280) do
					dungeonsText = string.sub(dungeonsText, 1, string.len(dungeonsText) - 1);
					dungeonsLabel:SetText(dungeonsText);
				end
					dungeonsText = dungeonsText .. "...";
					dungeonsLabel:SetText(dungeonsText);
				end
			end
			
			-- Type
			local typeLabel = getglobal("LFGMM_ListTab_Entry" .. entryIndex .. "Type");
			if (message.Type == "LFG") then
				typeLabel:SetText("LFG");
				typeLabel:SetTextColor(1, 1, 0);
			elseif (message.Type == "LFM") then
				typeLabel:SetText("LFM");
				typeLabel:SetTextColor(0, 1, 1);
			else
				typeLabel:SetText("?  ");
				typeLabel:SetTextColor(1, 0, 0);
			end
		
			-- Info button
			local infoButton = getglobal("LFGMM_ListTab_Entry" .. entryIndex .. "InfoButton");
			infoButton.Message = message;
		
			-- Show
			getglobal("LFGMM_ListTab_Entry" .. entryIndex):Show();
			
			entryIndex = entryIndex + 1;
		end
	end

	-- Hide unfilled entries
	if (entryIndex <= 7) then
		for entryIndex=entryIndex, 7 do
			getglobal("LFGMM_ListTab_Entry" .. entryIndex):Hide();
		end
	end
end


function LFGMM_ListTab_DungeonsDropDown_OnInitialize(self, level)
	local createSingleDungeonItem = function(dungeon)
		local item = LFGMM_Utility_CreateDungeonDropdownItem(dungeon);
		item.keepShownOnClick = true;
		item.isNotRadio = true;
		item.checked = LFGMM_Utility_ArrayContains(LFGMM_DB.LIST.Dungeons, dungeon.Index);
		item.func = function(self, dungeonIndex)
			if (self.checked) then
				table.insert(LFGMM_DB.LIST.Dungeons, dungeonIndex);
			else
				LFGMM_Utility_ArrayRemove(LFGMM_DB.LIST.Dungeons, dungeonIndex);
			end

			LFGMM_ListTab_DungeonsDropDown_Item_OnClick();
		end
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
		item.keepShownOnClick = true;
		item.isNotRadio = true;
		item.checked = LFGMM_Utility_ArrayContains(LFGMM_DB.LIST.Dungeons, dungeon.Index);
		item.value = { DungeonIndexes = availableSubDungeons };
		item.func = function(self, dungeonIndex)
			if (self.checked) then
				table.insert(LFGMM_DB.LIST.Dungeons, dungeon.Index);
			else
				LFGMM_Utility_ArrayRemove(LFGMM_DB.LIST.Dungeons, dungeon.Index);
			end
			
			LFGMM_ListTab_DungeonsDropDown_Item_OnClick();
		end
		UIDropDownMenu_AddButton(item, 1);
	end
	
	local createSubDungeonItem = function(dungeonIndex)
		-- Create dungeon menu item
		local dungeon = LFGMM_GLOBAL.DUNGEONS[dungeonIndex];
		local item = LFGMM_Utility_CreateDungeonDropdownItem(dungeon);
		item.keepShownOnClick = true;
		item.isNotRadio = true;
		item.checked = LFGMM_Utility_ArrayContains(LFGMM_DB.LIST.Dungeons, dungeonIndex);
		item.func = function(self, dungeonIndex)
			if (self.checked) then
				table.insert(LFGMM_DB.LIST.Dungeons, dungeon.Index);
			else
				LFGMM_Utility_ArrayRemove(LFGMM_DB.LIST.Dungeons, dungeon.Index);
			end

			LFGMM_ListTab_DungeonsDropDown_Item_OnClick();
		end
		UIDropDownMenu_AddButton(item, 2);
	end
	
	if (level == 1) then
		-- Get dungeons and raids to list
		local dungeonsList, raidsList, pvpList = LFGMM_Utility_GetAvailableDungeonsAndRaidsSorted();

		-- Clear selection menu item
		local clearItem = UIDropDownMenu_CreateInfo();
		clearItem.text = "<Clear selection>";
		clearItem.justifyH = "CENTER";
		clearItem.notCheckable = true;
		clearItem.func = LFGMM_ListTab_DungeonsDropDown_ClearSelections_OnClick;
		UIDropDownMenu_AddButton(clearItem);
		
		-- Select all menu item
		local selectAllItem = UIDropDownMenu_CreateInfo();
		selectAllItem.text = "<Select all>";
		selectAllItem.justifyH = "CENTER";
		selectAllItem.notCheckable = true;
		selectAllItem.func = LFGMM_ListTab_DungeonsDropDown_SelectAll_OnClick;
		UIDropDownMenu_AddButton(selectAllItem);
		
		-- Unknown dungeon menu item
		local unknownItem = UIDropDownMenu_CreateInfo();
		unknownItem.text = "Unknown";
		unknownItem.colorCode = "|c00f00000";
		unknownItem.keepShownOnClick = true;
		unknownItem.isNotRadio = true;
		unknownItem.checked = LFGMM_DB.LIST.ShowUnknownDungeons;
		unknownItem.func = function(self)
			LFGMM_DB.LIST.ShowUnknownDungeons = self.checked;
			LFGMM_ListTab_DungeonsDropDown_Item_OnClick();
		end
		unknownItem.arg1 = { Index = 0 };
		UIDropDownMenu_AddButton(unknownItem, 1);

		if (table.getn(dungeonsList) > 0) then
			if (table.getn(raidsList) > 0 or table.getn(pvpList) > 0) then
				-- Dungeons header
				local dungeonsHeader = UIDropDownMenu_CreateInfo();
				dungeonsHeader.text = "Dungeon";
				dungeonsHeader.isTitle = true;
				dungeonsHeader.notCheckable = true;
				UIDropDownMenu_AddButton(dungeonsHeader);
			end

			-- Dungeon menu items
			for _,dungeon in ipairs(dungeonsList) do
				if (dungeon.ParentDungeon == nil) then
					if (dungeon.SubDungeons == nil) then
						createSingleDungeonItem(dungeon);
					else
						createMultiDungeonItem(dungeon);
					end
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
			end
		
			-- Raid menu items
			for _,raid in ipairs(raidsList) do
				if (raid.SubDungeons == nil) then
					createSingleDungeonItem(raid);
				else
					createMultiDungeonItem(raid);
				end
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
			end
			
			-- PvP menu items
			for _,pvp in ipairs(pvpList) do
				if (pvp.SubDungeons == nil) then
					createSingleDungeonItem(pvp);
				else
					createMultiDungeonItem(pvp, buttonIndex);
				end
			end
		end

	elseif (level == 2) then
		local entry = UIDROPDOWNMENU_MENU_VALUE;
		
		-- Sub dungeon menu items
		for _,dungeonIndex in ipairs(entry.DungeonIndexes) do
			createSubDungeonItem(dungeonIndex);
		end
	end
end


function LFGMM_ListTab_DungeonsDropDown_SelectAll_OnClick()
	-- Clear dungeons
	LFGMM_DB.LIST.Dungeons = {};
	
	-- Add all available dungeons
	local availableDungeons = LFGMM_Utility_GetAllAvailableDungeonsAndRaids();
	for _,dungeon in ipairs(availableDungeons) do
		table.insert(LFGMM_DB.LIST.Dungeons, dungeon.Index);
	end
	
	-- Add unknown dungeons
	LFGMM_DB.LIST.ShowUnknownDungeons = true;

	-- Update text
	LFGMM_ListTab_DungeonsDropDown_UpdateText();

	-- Refresh
	LFGMM_ListTab_Refresh();
end


function LFGMM_ListTab_DungeonsDropDown_ClearSelections_OnClick()
	-- Clear dungeons
	LFGMM_DB.LIST.Dungeons = {};
	LFGMM_DB.LIST.ShowUnknownDungeons = false;
	
	-- Update text
	LFGMM_ListTab_DungeonsDropDown_UpdateText();

	-- Refresh
	LFGMM_ListTab_Refresh();
end


function LFGMM_ListTab_DungeonsDropDown_Item_OnClick()
	-- Update text
	LFGMM_ListTab_DungeonsDropDown_UpdateText();
	
	-- Refresh 
	LFGMM_ListTab_Refresh();
end


function LFGMM_ListTab_DungeonsDropDown_UpdateText()
	local numDungeons = table.getn(LFGMM_Utility_GetAllAvailableDungeonsAndRaids());
	local numSelectedDungeons = table.getn(LFGMM_DB.LIST.Dungeons);
	
	local text = "";
	if (numSelectedDungeons > 0 and numSelectedDungeons >= numDungeons) then
		text = "All";
		
		if (LFGMM_DB.LIST.ShowUnknownDungeons) then
			text = text .. " + Unknown";
		end

	elseif (numSelectedDungeons > 0) then
		text = numSelectedDungeons .. " / " .. numDungeons;
		
		if (LFGMM_DB.LIST.ShowUnknownDungeons) then
			text = text .. " + Unknown";
		end

	elseif (LFGMM_DB.LIST.ShowUnknownDungeons) then
		text = "Unknown";

	else
		text = "None";
	end

	UIDropDownMenu_SetText(LFGMM_ListTab_DungeonsDropDown, text);
end


function LFGMM_ListTab_MessageTypeDropDown_OnInitialize()
	local unknownItem = UIDropDownMenu_CreateInfo();
	unknownItem.text = "Unknown";
	unknownItem.colorCode = "|c00f00000";
	unknownItem.isRadio = false;
	unknownItem.checked = LFGMM_DB.LIST.MessageTypes.Unknown;
	unknownItem.func = LFGMM_ListTab_MessageTypeDropDown_Item_OnClick;
	unknownItem.arg1 = "UNKNOWN";
	unknownItem.keepShownOnClick = true;
	UIDropDownMenu_AddButton(unknownItem);

	local lfgItem = UIDropDownMenu_CreateInfo();
	lfgItem.text = "LFG";
	lfgItem.colorCode = "|c00ffff00";
	lfgItem.isRadio = false;
	lfgItem.checked = LFGMM_DB.LIST.MessageTypes.Lfg;
	lfgItem.func = LFGMM_ListTab_MessageTypeDropDown_Item_OnClick;
	lfgItem.arg1 = "LFG";
	lfgItem.keepShownOnClick = true;
	UIDropDownMenu_AddButton(lfgItem);

	local lfmItem = UIDropDownMenu_CreateInfo();
	lfmItem.text = "LFM";
	lfmItem.colorCode = "|c0000ffff";
	lfmItem.isRadio = false;
	lfmItem.checked = LFGMM_DB.LIST.MessageTypes.Lfm;
	lfmItem.func = LFGMM_ListTab_MessageTypeDropDown_Item_OnClick;
	lfmItem.arg1 = "LFM";
	lfmItem.keepShownOnClick = true;
	UIDropDownMenu_AddButton(lfmItem);
end


function LFGMM_ListTab_MessageTypeDropDown_Item_OnClick(self, groupType)
	if (groupType == "UNKNOWN") then
		LFGMM_DB.LIST.MessageTypes.Unknown = not LFGMM_DB.LIST.MessageTypes.Unknown;
	elseif (groupType == "LFG") then
		LFGMM_DB.LIST.MessageTypes.Lfg = not LFGMM_DB.LIST.MessageTypes.Lfg;
	elseif (groupType == "LFM") then
		LFGMM_DB.LIST.MessageTypes.Lfm = not LFGMM_DB.LIST.MessageTypes.Lfm;
	end
	
	-- Update text
	LFGMM_ListTab_MessageTypeDropDown_UpdateText();
	
	-- Refresh
	LFGMM_ListTab_Refresh();
end


function LFGMM_ListTab_MessageTypeDropDown_UpdateText()
	local unknownChecked = LFGMM_DB.LIST.MessageTypes.Unknown;
	local lfgChecked = LFGMM_DB.LIST.MessageTypes.Lfg;
	local lfmChecked = LFGMM_DB.LIST.MessageTypes.Lfm;

	if (unknownChecked and lfgChecked and lfmChecked) then
		UIDropDownMenu_SetText(LFGMM_ListTab_MessageTypeDropDown, "LFG/LFM + Unknown");
	elseif (lfgChecked and lfmChecked) then
		UIDropDownMenu_SetText(LFGMM_ListTab_MessageTypeDropDown, "LFG/LFM");
	elseif (unknownChecked and lfgChecked) then
		UIDropDownMenu_SetText(LFGMM_ListTab_MessageTypeDropDown, "LFG + Unknown");
	elseif (unknownChecked and lfmChecked) then
		UIDropDownMenu_SetText(LFGMM_ListTab_MessageTypeDropDown, "LFM + Unknown");
	elseif (unknownChecked) then
		UIDropDownMenu_SetText(LFGMM_ListTab_MessageTypeDropDown, "Unknown");
	elseif (lfgChecked) then
		UIDropDownMenu_SetText(LFGMM_ListTab_MessageTypeDropDown, "LFG");
	elseif (lfmChecked) then
		UIDropDownMenu_SetText(LFGMM_ListTab_MessageTypeDropDown, "LFM");
	else
		UIDropDownMenu_SetText(LFGMM_ListTab_MessageTypeDropDown, "None");
	end
end


function LFGMM_ListTab_ScrollBarSlider_OnValueChanged(self, value)
	local newScrollIndex = math.floor(value);
	if (LFGMM_GLOBAL.LIST_SCROLL_INDEX ~= newScrollIndex) then
		-- Store scroll index
		LFGMM_GLOBAL.LIST_SCROLL_INDEX = newScrollIndex;

		-- Refresh
		LFGMM_ListTab_Refresh();
	end
end


function LFGMM_ListTab_OnMouseWheel(self, delta)
	if (delta < 0) then
		LFGMM_ListTab_ScrollBarSlider:SetValue(LFGMM_ListTab_ScrollBarSlider:GetValue() + 1);
	else
		LFGMM_ListTab_ScrollBarSlider:SetValue(LFGMM_ListTab_ScrollBarSlider:GetValue() - 1);
	end
end


------------------------------------------------------------------------------------------------------------------------
-- LIST TAB INFO WINDOW
------------------------------------------------------------------------------------------------------------------------


function LFGMM_ListTab_MessageInfoWindow_Show(message)
	if (LFGMM_ListTab_MessageInfoWindow.Message ~= nil and LFGMM_ListTab_MessageInfoWindow.Message.Player == message.Player) then
		-- Hide
		LFGMM_ListTab_MessageInfoWindow_Hide();
		
	else
		LFGMM_ListTab_MessageInfoWindow.Message = message;

		-- Hide other windows
		LFGMM_LfgTab_BroadcastMessageInfoWindow:Hide();
		LFGMM_LfmTab_BroadcastMessageInfoWindow:Hide();
		LFGMM_SettingsTab_RequestInviteMessageInfoWindow:Hide();

		-- Show and refresh
		LFGMM_ListTab_MessageInfoWindow:Show();
		LFGMM_ListTab_MessageInfoWindow_Refresh();
		
		-- Age
		LFGMM_ListTab_MessageInfoWindow_StartUpdateAge();
	end
end


function LFGMM_ListTab_MessageInfoWindow_Refresh()
	-- Return if window is hidden
	if (not LFGMM_ListTab_MessageInfoWindow:IsVisible()) then
		return;
	end

	local message = LFGMM_ListTab_MessageInfoWindow.Message;

	-- Player
	LFGMM_ListTab_MessageInfoWindow_PlayerText:SetText(message.PlayerClass.Color .. "[" .. message.Player .. "]:");

	-- Message
	LFGMM_ListTab_MessageInfoWindow_MessageText:SetText(message.Message);

	-- Class
	LFGMM_ListTab_MessageInfoWindow_ClassIcon:SetTexCoord(unpack(message.PlayerClass.IconCoordinates));
	LFGMM_ListTab_MessageInfoWindow_ClassText:SetText(message.PlayerClass.Color .. message.PlayerClass.LocalizedName);
	
	-- Level
	local level = message.PlayerLevel or "?";
	LFGMM_ListTab_MessageInfoWindow_LevelText:SetText(message.PlayerClass.Color .. level);

	-- Window size
	local targetSize = LFGMM_ListTab_MessageInfoWindow_MessageText:GetHeight() + 125;
	if (targetSize < 200) then
		targetSize = 200;
	end
	LFGMM_ListTab_MessageInfoWindow:SetHeight(targetSize);

	-- Who button
	if (message.PlayerLevel ~= nil) then
		LFGMM_ListTab_MessageInfoWindow_WhoButton:Hide();
	else
		LFGMM_ListTab_MessageInfoWindow_WhoButton:Show();
	
		if (LFGMM_GLOBAL.WHO_COOLDOWN > 0) then
			LFGMM_ListTab_MessageInfoWindow_WhoButton:SetText("Who? (" .. LFGMM_GLOBAL.WHO_COOLDOWN .. ")");
			LFGMM_ListTab_MessageInfoWindow_WhoButton:Disable();
		else
			LFGMM_ListTab_MessageInfoWindow_WhoButton:SetText("Who?");
			LFGMM_ListTab_MessageInfoWindow_WhoButton:Enable();
		end
	end

	local isInParty = LFGMM_Utility_ArrayContains(LFGMM_GLOBAL.GROUP_MEMBERS, message.Player);
	
	-- Hide/show buttons
	if (isInParty) then
		-- Hide buttons
		LFGMM_ListTab_MessageInfoWindow_WhisperButton:Hide();
		LFGMM_ListTab_MessageInfoWindow_InviteButton:Hide();
		LFGMM_ListTab_MessageInfoWindow_RequestInviteButton:Hide();
		LFGMM_ListTab_MessageInfoWindow_InPartyText:Show();
	else
		-- Show buttons
		LFGMM_ListTab_MessageInfoWindow_WhisperButton:Show();
		LFGMM_ListTab_MessageInfoWindow_InviteButton:Show();
		LFGMM_ListTab_MessageInfoWindow_RequestInviteButton:Show();
		LFGMM_ListTab_MessageInfoWindow_InPartyText:Hide();

		-- Invite button
		if (message.Invited) then
			LFGMM_ListTab_MessageInfoWindow_InviteButton:SetText("Invite sent");
			LFGMM_ListTab_MessageInfoWindow_InviteButton:Disable();
		else
			LFGMM_ListTab_MessageInfoWindow_InviteButton:SetText("Invite");
			LFGMM_ListTab_MessageInfoWindow_InviteButton:Enable();
		end

		-- Request invite button
		if (table.getn(LFGMM_GLOBAL.GROUP_MEMBERS) > 1) then
			LFGMM_ListTab_MessageInfoWindow_RequestInviteButton:Hide();
		elseif (message.InviteRequested) then
			LFGMM_ListTab_MessageInfoWindow_RequestInviteButton:SetText("Invite requested");
			LFGMM_ListTab_MessageInfoWindow_RequestInviteButton:Disable();
		else
			LFGMM_ListTab_MessageInfoWindow_RequestInviteButton:SetText("Request invite");
			LFGMM_ListTab_MessageInfoWindow_RequestInviteButton:Enable();
		end

		-- Disable buttons if popup is visible
		if (LFGMM_PopupWindow:IsVisible()) then
			LFGMM_ListTab_MessageInfoWindow_InviteButton:Disable();
			LFGMM_ListTab_MessageInfoWindow_RequestInviteButton:Disable();
		end
	end
end


function LFGMM_ListTab_MessageInfoWindow_Hide()
	LFGMM_ListTab_MessageInfoWindow.Message = nil;
	LFGMM_ListTab_MessageInfoWindow:Hide();
end


function LFGMM_ListTab_MessageInfoWindow_HideForMessage(message)
	if (not LFGMM_ListTab_MessageInfoWindow:IsVisible()) then
		return;
	end

	if (LFGMM_ListTab_MessageInfoWindow.Message.Player == message.Player) then
		LFGMM_ListTab_MessageInfoWindow_Hide();
	end
end


function LFGMM_ListTab_MessageInfoWindow_WhisperButton_OnClick()
	LFGMM_Core_OpenWhisper(LFGMM_ListTab_MessageInfoWindow.Message);
end


function LFGMM_ListTab_MessageInfoWindow_WhoButton_OnClick()
	LFGMM_Core_WhoRequest(LFGMM_ListTab_MessageInfoWindow.Message);
end


function LFGMM_ListTab_MessageInfoWindow_InviteButton_OnClick()
	-- Return if popup window is open
	if (LFGMM_PopupWindow:IsVisible()) then
		return;
	end

	LFGMM_Core_Invite(LFGMM_ListTab_MessageInfoWindow.Message);

	-- Refresh
	LFGMM_ListTab_MessageInfoWindow_Refresh();
end

function LFGMM_ListTab_MessageInfoWindow_RequestInviteButton_OnClick()
	-- Return if popup window is open
	if (LFGMM_PopupWindow:IsVisible()) then
		return;
	end

	-- Show popup
	LFGMM_PopupWindow_ShowForInviteRequested(LFGMM_ListTab_MessageInfoWindow.Message);

	-- Request invite
	LFGMM_Core_RequestInvite(LFGMM_ListTab_MessageInfoWindow.Message);

	-- Refresh
	LFGMM_ListTab_MessageInfoWindow_Refresh();
end


function LFGMM_ListTab_MessageInfoWindow_StartUpdateAge()
	-- Set age text
	local ageText = LFGMM_Utility_GetAgeText(LFGMM_ListTab_MessageInfoWindow.Message.Timestamp);
	LFGMM_ListTab_MessageInfoWindow_TimeText:SetText("Announced " .. ageText);
	
	if (not LFGMM_ListTab_MessageInfoWindow.UpdageAgeTimerLock) then
		LFGMM_ListTab_MessageInfoWindow.UpdageAgeTimerLock = true;
		LFGMM_ListTab_MessageInfoWindow_UpdateAge();
	end
end


function LFGMM_ListTab_MessageInfoWindow_UpdateAge()
	-- Return if window is hidden
	if (not LFGMM_ListTab_MessageInfoWindow:IsVisible()) then
		LFGMM_ListTab_MessageInfoWindow.UpdageAgeTimerLock = false;
		return;
	end
	
	-- Update age text
	local ageText = LFGMM_Utility_GetAgeText(LFGMM_ListTab_MessageInfoWindow.Message.Timestamp);
	LFGMM_ListTab_MessageInfoWindow_TimeText:SetText("Announced " .. ageText);
	
	C_Timer.After(1, LFGMM_ListTab_MessageInfoWindow_UpdateAge);
end
