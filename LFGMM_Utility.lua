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
-- UTILITY
------------------------------------------------------------------------------------------------------------------------


function LFGMM_Utility_InitializeDropDown(dropDown, width, onInitialize)
	UIDropDownMenu_SetWidth(dropDown, width);
	UIDropDownMenu_Initialize(dropDown, onInitialize);
end


function LFGMM_Utility_InitializeCheckbox(checkBox, text, tooltip, initialValue, onClick)
	local label = checkBox:GetParent():CreateFontString(checkBox:GetName() .. "_Label", "OVERLAY", "GameFontNormal");
	label:SetText(text);
	label:SetPoint("BOTTOMLEFT", checkBox:GetName(), "BOTTOMRIGHT",  0, 7);

	checkBox.tooltip = tooltip;
	checkBox.label = label;
	checkBox:SetHitRectInsets(0, -label:GetStringWidth(), 0, 0);
	checkBox:SetChecked(initialValue);
	checkBox:SetScript("OnClick", 
		function()
			if (checkBox:GetChecked()) then
				PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
			else
				PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
			end
			onClick();
		end
	);
end


function LFGMM_Utility_InitializeHiddenSlider(scrollBar, onValueChanged)
	scrollBar:SetScript("OnValueChanged", onValueChanged);
	scrollBar:SetMinMaxValues(1, 1);
	scrollBar:SetValue(1);
	scrollBar:SetValueStep(1);
	scrollBar:Hide();
end


function LFGMM_Utility_ToggleCheckBoxEnabled(checkBox, enabled)
	if (enabled) then
		checkBox:Enable();
		checkBox.label:SetFontObject("GameFontNormal")
	else
		checkBox:Disable();
		checkBox.label:SetFontObject("GameFontHighlight")
	end
end


function LFGMM_Utility_CreateDungeonDropdownItem(dungeon)
	local item = UIDropDownMenu_CreateInfo();
	item.arg1 = dungeon.Index;

	if (dungeon.MinLevel == dungeon.MaxLevel) then
		item.text = dungeon.Name .. " [" .. dungeon.MaxLevel .. "]";
	else
		item.text = dungeon.Name .. " [" .. dungeon.MinLevel .. "-" .. dungeon.MaxLevel .. "]";
	end
	
	if (LFGMM_GLOBAL.PLAYER_LEVEL > dungeon.MaxLevel) then
		-- Gray
		item.colorCode = "|c00808080";
	elseif (LFGMM_GLOBAL.PLAYER_LEVEL < dungeon.MinLevel) then
		-- Red
		item.colorCode = "|c00f00000";
	else
		-- Yellow
		item.colorCode = "|c00f0f000";
	end

	return item;
end


function LFGMM_Utility_CreateUniqueDungeonsList()
	return {
		Count = 0,
		List = {},
		Add = function (self, dungeon)
			if (self.List[dungeon.Index] == nil) then
				self.List[dungeon.Index] = dungeon;
				self.Count = self.Count + 1;
			end
		end,
		Remove = function (self, dungeon)
			if (self.List[dungeon.Index] ~= nil) then
				self.List[dungeon.Index] = nil;
				self.Count = self.Count - 1;
			end
		end,
		GetDungeonList = function (self)
			local dungeonList = {};
			for _,v in pairs(self.List) do
				table.insert(dungeonList, v);
			end
			return dungeonList;
		end,
		GetIndexList = function (self)
			local indexList = {};
			for i,_ in pairs(self.List) do
				table.insert(indexList, i);
			end
			return indexList;
		end
	}
end


function LFGMM_Utility_ArrayClear(array)
	for index = 1, table.getn(array) do
		table.remove(array, 1);
	end
end


function LFGMM_Utility_ArrayRemove(array, ...)
	-- Get values to remove
	local removeValues = {};
	for _,argValue in ipairs({...}) do
		if (type(argValue) == "table") then
			for _,tableValue in ipairs(argValue) do
				table.insert(removeValues, tableValue);
			end
		else
			table.insert(removeValues, argValue);
		end
	end

	-- Get indexes to remove
	local removeIndexes = {};
	for index,arrayValue in ipairs(array) do
		for _,removeValue in ipairs(removeValues) do
			if (arrayValue == removeValue) then
				table.insert(removeIndexes, index);
			end
		end
	end
	
	-- Sort indexes in reverse order
	table.sort(removeIndexes, function(a,b) return a > b end);

	-- Remove values
	for _,removeIndex in ipairs(removeIndexes) do
		table.remove(array, removeIndex);
	end
end


function LFGMM_Utility_ArrayContains(array, value)
	for _,arrayValue in ipairs(array) do
		if (arrayValue == value) then
			return true;
		end
	end

	return false;
end


function LFGMM_Utility_ArrayContainsAny(array1, array2)
	for _,arrayValue1 in ipairs(array1) do
		for _,arrayValue2 in ipairs(array2) do
			if (arrayValue1 == arrayValue2) then
				return true;
			end
		end
	end

	return false;
end


function LFGMM_Utility_ArrayContainsAll(array1, array2)
	for _,arrayValue2 in ipairs(array2) do
		local valueFound = false;

		for _,arrayValue1 in ipairs(array1) do
			if (arrayValue1 == arrayValue2) then
				valueFound = true;
				break;
			end
		end
		
		if (not valueFound) then
			return false;
		end
	end

	return true;
end


function LFGMM_Utility_GetAvailableDungeonsAndRaidsSorted()
	local dungeonsList = {};
	local raidsList = {};
	local pvpList = {}
	for _,dungeon in ipairs(LFGMM_GLOBAL.DUNGEONS) do
		if (dungeon.ParentDungeon == nil and LFGMM_Utility_IsDungeonAvailable(dungeon)) then
			if (dungeon.Pvp) then
				table.insert(pvpList, dungeon);
			elseif (dungeon.Size <= 10) then
				table.insert(dungeonsList, dungeon);
			else
				table.insert(raidsList, dungeon);
			end
		end
	end

	return dungeonsList, raidsList, pvpList;
end


function LFGMM_Utility_GetAllAvailableDungeonsAndRaids()
	local list = {};
	for _,dungeon in ipairs(LFGMM_GLOBAL.DUNGEONS) do
		if (LFGMM_Utility_IsDungeonAvailable(dungeon)) then
			table.insert(list, dungeon);
		end
	end

	return list;
end


function LFGMM_Utility_GetAllUnavailableDungeonsAndRaids()
	local list = {};
	for _,dungeon in ipairs(LFGMM_GLOBAL.DUNGEONS) do
		if (not LFGMM_Utility_IsDungeonAvailable(dungeon)) then
			table.insert(list, dungeon);
		end
	end

	return list;
end


function LFGMM_Utility_IsDungeonAvailable(dungeon)
	if (LFGMM_DB.SETTINGS.HidePvp and dungeon.Pvp) then
		return false;
	elseif (LFGMM_DB.SETTINGS.HideRaids and dungeon.Size > 10 and not dungeon.Pvp) then
		return false;
	elseif (LFGMM_DB.SETTINGS.HideLowLevel and LFGMM_GLOBAL.PLAYER_LEVEL > dungeon.MaxLevel) then
		return false;
	elseif (LFGMM_DB.SETTINGS.HideHighLevel and LFGMM_GLOBAL.PLAYER_LEVEL < dungeon.MinLevel) then
		return false;
	else
		return true;
	end
end


function LFGMM_Utility_GetDungeonMessageText(dungeons, separator, lastSeparator, showAllAsAny)
	local dungeonNames = {};
	local dungeonAbbreviations = {}

	local smDungeons = {};
	local maraDungeons = {};
	local brdDungeons = {};
	local stratDungeons = {}
	local dmDungeons = {};
	local otherDungeons1 = {};
	local otherDungeons2 = {};
	local otherDungeons3 = {};
	local otherDungeons4 = {};
	local otherDungeons5 = {};
	local otherDungeons6 = {};

	local allDungeonIndexes = {};
	for _,dungeon in ipairs(dungeons) do
		table.insert(allDungeonIndexes, dungeon.Index);
	end

	local isAnyDungeonsMatch = false;

	if (LFGMM_Utility_ArrayContainsAll(allDungeonIndexes, LFGMM_GLOBAL.DUNGEONS_FALLBACK[3].Dungeons)) then
		table.insert(dungeonNames, "Any dungeon");
		table.insert(dungeonAbbreviations, "Any dungeon");
		isAnyDungeonsMatch = true;
	end

	table.sort(dungeons, function(left, right) return left.Index < right.Index; end);

	-- Sort
	for _,dungeon in ipairs(dungeons) do
		if (isAnyDungeonsMatch and dungeon.Index <= 43) then
			-- Skip
		else
			-- Scarlet Monastery
			if (dungeon.Index == 8 or dungeon.Index == 9 or dungeon.Index == 10 or dungeon.Index == 11) then
				table.insert(smDungeons, dungeon);
			-- Maraudon
			elseif (dungeon.Index == 18 or dungeon.Index == 19 or dungeon.Index == 20) then
				table.insert(maraDungeons, dungeon);
			-- Blackrock depths
			elseif (dungeon.Index == 23 or dungeon.Index == 24 or dungeon.Index == 25 or dungeon.Index == 26 or dungeon.Index == 27 or dungeon.Index == 28 or dungeon.Index == 29 or dungeon.Index == 30 or dungeon.Index == 31 or dungeon.Index == 32) then
				table.insert(brdDungeons, dungeon);
			-- Stratholme
			elseif (dungeon.Index == 37 or dungeon.Index == 38) then
				table.insert(stratDungeons, dungeon);
			-- Dire Maul
			elseif (dungeon.Index == 40 or dungeon.Index == 41 or dungeon.Index == 42 or dungeon.Index == 43) then
				table.insert(dmDungeons, dungeon);
			-- Other dungeons
			elseif (dungeon.Index < 8) then
				table.insert(otherDungeons1, dungeon);
			elseif (dungeon.Index > 11 and dungeon.Index < 18) then
				table.insert(otherDungeons2, dungeon);
			elseif (dungeon.Index > 20 and dungeon.Index < 23) then
				table.insert(otherDungeons3, dungeon);
			elseif (dungeon.Index > 32 and dungeon.Index < 37) then
				table.insert(otherDungeons4, dungeon);
			elseif (dungeon.Index > 38 and dungeon.Index < 40) then
				table.insert(otherDungeons5, dungeon);
			else
				table.insert(otherDungeons6, dungeon);
			end
		end
	end

	local smDungeonsCount = table.getn(smDungeons);
	local maraDungeonsCount = table.getn(maraDungeons);
	local brdDungeonsCount = table.getn(brdDungeons);
	local stratDungeonsCount = table.getn(stratDungeons);
	local dmDungeonsCount = table.getn(dmDungeons);

	local addNames = function(dungeonList, names, abbreviations)
		for _,dungeon in ipairs(dungeonList) do
			-- Skip parents if child present
			if (smDungeonsCount > 0 and dungeon.Index == 7) then
				-- Skip
			elseif (maraDungeonsCount > 0 and dungeon.Index == 17) then
				-- Skip
			elseif (brdDungeonsCount > 0 and dungeon.Index == 22) then
				-- Skip
			elseif (stratDungeonsCount > 0 and dungeon.Index == 36) then
				-- Skip
			elseif (dmDungeonsCount > 0 and dungeon.Index == 39) then
				-- Skip
			else
				table.insert(dungeonNames, dungeon.Name);
				table.insert(dungeonAbbreviations, dungeon.Abbreviation);
			end
		end
	end

	addNames(otherDungeons1, dungeonNames, dungeonAbbreviations);
	
	-- Scarlet Monastery
	if (smDungeonsCount > 0 and smDungeonsCount ~= 4) then
		local smNamesText = "";
		local smAbbreviationsText = "";
		for index,dungeon in ipairs(smDungeons) do
			if (index == 1) then
				smNamesText = "Scarlet Monastery - " .. string.gsub(dungeon.Name, "Scarlet Monastery %- ", "");
				smAbbreviationsText = "SM " .. string.gsub(dungeon.Abbreviation, "SM ", "");
			else
				smNamesText = smNamesText .. "/" .. string.gsub(dungeon.Name, "Scarlet Monastery %- ", "");
				smAbbreviationsText = smAbbreviationsText .. "/" .. string.gsub(dungeon.Abbreviation, "SM ", "");
			end
		end
		
		table.insert(dungeonNames, smNamesText);
		table.insert(dungeonAbbreviations, smAbbreviationsText);
	
	elseif (smDungeonsCount == 4) then
		table.insert(dungeonNames, LFGMM_GLOBAL.DUNGEONS[7].Name);
		table.insert(dungeonAbbreviations, LFGMM_GLOBAL.DUNGEONS[7].Abbreviation);
	end
	
	addNames(otherDungeons2, dungeonNames, dungeonAbbreviations);
	
	-- Maraudon
	if (maraDungeonsCount > 0 and maraDungeonsCount ~= 3) then
		local maraNamesText = "";
		local maraAbbreviationsText = "";
		for index,dungeon in ipairs(maraDungeons) do
			if (index == 1) then
				maraNamesText = "Maraudon - " .. string.gsub(dungeon.Name, "Maraudon %- ", "");
				maraAbbreviationsText = "Mara " .. string.gsub(dungeon.Abbreviation, "Mara ", "");
			else
				maraNamesText = maraNamesText .. "/" .. string.gsub(dungeon.Name, "Maraudon %- ", "");
				maraAbbreviationsText = maraAbbreviationsText .. "/" .. string.gsub(dungeon.Abbreviation, "Mara ", "");
			end
		end
		
		table.insert(dungeonNames, maraNamesText);
		table.insert(dungeonAbbreviations, maraAbbreviationsText);
		
	elseif (maraDungeonsCount == 3) then
		table.insert(dungeonNames, LFGMM_GLOBAL.DUNGEONS[17].Name);
		table.insert(dungeonAbbreviations, LFGMM_GLOBAL.DUNGEONS[17].Abbreviation);
	end
	
	addNames(otherDungeons3, dungeonNames, dungeonAbbreviations);

	-- BRD
	if (brdDungeonsCount > 0 and brdDungeonsCount ~= 10) then
		local brdNamesText = "";
		local brdAbbreviationsText = "";
		for index,dungeon in ipairs(brdDungeons) do
			if (index == 1) then
				brdNamesText = "Blackrock Depths - " .. string.gsub(string.gsub(dungeon.Name, "Blackrock Depths %- ", ""), " Run", "");
				brdAbbreviationsText = "BRD " .. string.gsub(string.gsub(dungeon.Abbreviation, "BRD ", ""), " Run", "");
			else
				brdNamesText = brdNamesText .. "/" .. string.gsub(string.gsub(dungeon.Name, "Blackrock Depths %- ", ""), " Run", "");
				brdAbbreviationsText = brdAbbreviationsText .. "/" .. string.gsub(string.gsub(dungeon.Abbreviation, "BRD ", ""), " Run", "");
			end
		end
		
		table.insert(dungeonNames, brdNamesText .. " Run");
		table.insert(dungeonAbbreviations, brdAbbreviationsText .. " Run");

	elseif (brdDungeonsCount == 10) then
		table.insert(dungeonNames, LFGMM_GLOBAL.DUNGEONS[22].Name);
		table.insert(dungeonAbbreviations, LFGMM_GLOBAL.DUNGEONS[22].Abbreviation);
	end


	addNames(otherDungeons4, dungeonNames, dungeonAbbreviations);
		
	-- Stratholme
	if (stratDungeonsCount > 0 and stratDungeonsCount ~= 2) then
		local stratNamesText = "";
		local stratAbbreviationsText = "";
		for index,dungeon in ipairs(stratDungeons) do
			if (index == 1) then
				stratNamesText = "Stratholme - " .. string.gsub(dungeon.Name, "Stratholme %- ", "");
				stratAbbreviationsText = "Strat " .. string.gsub(dungeon.Abbreviation, "Strat ", "");
			else
				stratNamesText = stratNamesText .. "/" .. string.gsub(dungeon.Name, "Stratholme %- ", "");
				stratAbbreviationsText = stratAbbreviationsText .. "/" .. string.gsub(dungeon.Abbreviation, "Strat ", "");
			end
		end
		
		table.insert(dungeonNames, stratNamesText);
		table.insert(dungeonAbbreviations, stratAbbreviationsText);
		
	elseif (stratDungeonsCount == 2) then
		table.insert(dungeonNames, LFGMM_GLOBAL.DUNGEONS[36].Name);
		table.insert(dungeonAbbreviations, LFGMM_GLOBAL.DUNGEONS[36].Abbreviation);
	end

	addNames(otherDungeons5, dungeonNames, dungeonAbbreviations);
	
	-- Dire Maul
	if (dmDungeonsCount > 0 and dmDungeonsCount ~= 4) then
		local dmNamesText = "";
		local dmAbbreviationsText = "";
		for index,dungeon in ipairs(dmDungeons) do
			if (index == 1) then
				dmNamesText = "Dire Maul - " .. string.gsub(dungeon.Name, "Dire Maul %- ", "");
				dmAbbreviationsText = "DM " .. string.gsub(dungeon.Abbreviation, "DM ", "");
			else
				dmNamesText = dmNamesText .. "/" .. string.gsub(dungeon.Name, "Dire Maul %- ", "");
				dmAbbreviationsText = dmAbbreviationsText .. "/" .. string.gsub(dungeon.Abbreviation, "DM ", "");
			end
		end

		table.insert(dungeonNames, dmNamesText);
		table.insert(dungeonAbbreviations, dmAbbreviationsText);

	elseif (dmDungeonsCount == 4) then
		table.insert(dungeonNames, LFGMM_GLOBAL.DUNGEONS[39].Name);
		table.insert(dungeonAbbreviations, LFGMM_GLOBAL.DUNGEONS[39].Abbreviation);
	end
	
	addNames(otherDungeons6, dungeonNames, dungeonAbbreviations);

	-- Combine all names
	local allNames = "";
	for index,dungeonName in ipairs(dungeonNames) do
		if (index == 1) then
			allNames = dungeonName;
		elseif (index == table.getn(dungeonNames)) then
			allNames = allNames .. lastSeparator .. dungeonName;
		else
			allNames = allNames .. separator .. dungeonName;
		end
	end

	-- Combine all abbreviations
	local allAbbreviations = "";
	for index,dungeonAbbreviation in ipairs(dungeonAbbreviations) do
		if (index == 1) then
			allAbbreviations = dungeonAbbreviation;
		elseif (index == table.getn(dungeonAbbreviations)) then
			allAbbreviations = allAbbreviations .. lastSeparator .. dungeonAbbreviation;
		else
			allAbbreviations = allAbbreviations .. separator .. dungeonAbbreviation;
		end
	end

	return allNames, allAbbreviations;
end


function LFGMM_Utility_GetAgeText(timestamp)
	local age = time() - timestamp;
	local ageSeconds = age % 60;
	local ageMinutes = math.floor(age / 60) % 60;

	local ageText;
	if (ageMinutes == 0 and ageSeconds <= 5) then
		return "now";
	elseif (ageMinutes >= 30) then
		return "over 30m ago";
	elseif (ageMinutes > 0) then
		return ageMinutes .. "m " .. ageSeconds .. "s ago";
	else
		if (ageSeconds == 1) then
			return ageSeconds .. " second ago";
		else
			return ageSeconds .. " seconds ago";
		end
	end
end


function LFGMM_Utility_GetPlayerSpec()
	local talentTree = {};
	for tabIndex=1, GetNumTalentTabs() do
		local name, _, pointsSpent = GetTalentTabInfo(tabIndex);
		local talentTab = { Name = name, Points = pointsSpent };
		table.insert(talentTree, talentTab);
	end

	table.sort(talentTree, function(a, b) return a.Points > b.Points; end);

	local spec = "";
	if (talentTree[1] ~= nil and talentTree[1].Points > 0) then
		if (talentTree[1].Points == talentTree[2].Points) then
			spec = talentTree[1].Name .. "/" .. talentTree[2].Name;
		else
			spec = talentTree[1].Name;
		end
	end
	
	return spec;
end


function LFGMM_Utility_GetLfgChannelName()
	local lfgChannelName = "LookingForGroup";
	
	for _,channel in ipairs({ EnumerateServerChannels() }) do
		if (
			channel == "LookingForGroup" or 
			channel == "BuscarGrupo" or
			channel == "ProcurandoGrupo" or
			channel == "SucheNachGruppe" or
			channel == "BuscandoGrupo" or
			channel == "RechercheGroupe"
		) then
			lfgChannelName = channel;
			break;
		end
	end

	return lfgChannelName;
end

