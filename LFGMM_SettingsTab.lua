--[[
	LFG MatchMaker - Addon for World of Warcraft.
	Version: 1.0.3
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
-- SETTINGS TAB
------------------------------------------------------------------------------------------------------------------------


function LFGMM_SettingsTab_Initialize()
	LFGMM_Utility_InitializeCheckbox(LFGMM_SettingsTab_ShowMinimapButtonCheckBox, "Show minimap button", "Show button to open window on the minimap", LFGMM_DB.SETTINGS.ShowMinimapButton, LFGMM_SettingsTab_ShowMinimapButtonCheckBox_OnClick);
	LFGMM_Utility_InitializeCheckbox(LFGMM_SettingsTab_ShowQuestLogButtonCheckBox, "Show questlog button", "Show button to open window attached to the questlog window", LFGMM_DB.SETTINGS.ShowQuestLogButton, LFGMM_SettingsTab_ShowQuestLogButtonCheckBox_OnClick);

	LFGMM_Utility_InitializeCheckbox(LFGMM_SettingsTab_HideLowLevelCheckBox, "Hide low-level", "Hide low-level dungeons from dungeon selectors", LFGMM_DB.SETTINGS.HideLowLevel, LFGMM_SettingsTab_HideLowLevelCheckBox_OnClick);
	LFGMM_Utility_InitializeCheckbox(LFGMM_SettingsTab_HideHighLevelCheckBox, "Hide high-level", "Hide high-level dungeons from dungeon selectors", LFGMM_DB.SETTINGS.HideHighLevel, LFGMM_SettingsTab_HideHighLevelCheckBox_OnClick);
	LFGMM_Utility_InitializeCheckbox(LFGMM_SettingsTab_HidePvpCheckBox, "Hide PvP", "Hide PvP from dungeon selectors", LFGMM_DB.SETTINGS.HidePvp, LFGMM_SettingsTab_HidePvpCheckBox_OnClick);
	LFGMM_Utility_InitializeCheckbox(LFGMM_SettingsTab_HideRaidsCheckBox, "Hide raids", "Hide raids from dungeon selectors", LFGMM_DB.SETTINGS.HideRaids, LFGMM_SettingsTab_HideRaidsCheckBox_OnClick);


	LFGMM_SettingsTab_MaxMessageAgeSlider:SetScript("OnValueChanged", LFGMM_SettingsTab_MaxMessageAgeSlider_OnValueChanged);
	LFGMM_SettingsTab_MaxMessageAgeSlider:SetMinMaxValues(5, 30);
	LFGMM_SettingsTab_MaxMessageAgeSlider:SetValue(LFGMM_DB.SETTINGS.MaxMessageAge);
	LFGMM_SettingsTab_MaxMessageAgeSlider:SetValueStep(1);
	LFGMM_SettingsTab_MaxMessageAgeSliderLow:SetText("");
	LFGMM_SettingsTab_MaxMessageAgeSliderHigh:SetText("");

	LFGMM_SettingsTab_BroadcastIntervalSlider:SetScript("OnValueChanged", LFGMM_SettingsTab_BroadcastIntervalSlider_OnValueChanged);
	LFGMM_SettingsTab_BroadcastIntervalSlider:SetMinMaxValues(1, 10);
	LFGMM_SettingsTab_BroadcastIntervalSlider:SetValue(LFGMM_DB.SETTINGS.BroadcastInterval);
	LFGMM_SettingsTab_BroadcastIntervalSlider:SetValueStep(1);
	LFGMM_SettingsTab_BroadcastIntervalSliderLow:SetText("");
	LFGMM_SettingsTab_BroadcastIntervalSliderHigh:SetText("");

	LFGMM_SettingsTab_RequestInviteMessageTemplateInputBox:SetScript("OnTextChanged", LFGMM_SettingsTab_UpdateRequestInviteMessage);
	LFGMM_SettingsTab_RequestInviteMessageTemplateInputBox:SetText(LFGMM_DB.SETTINGS.RequestInviteMessageTemplate);

	LFGMM_SettingsTab_RequestInviteMessageInfoButton:SetScript("OnClick", LFGMM_SettingsTab_RequestInviteMessageInfoButton_OnClick);

	LFGMM_Utility_InitializeHiddenSlider(LFGMM_SettingsTab_RequestInviteMessagePreviewSlider, LFGMM_SettingsTab_RequestInviteMessagePreview_Refresh);
	LFGMM_SettingsTab_RequestInviteMessagePreviewSliderLow:SetText("");
	LFGMM_SettingsTab_RequestInviteMessagePreviewSliderHigh:SetText("");
end


function LFGMM_SettingsTab_Show()
	PanelTemplates_SetTab(LFGMM_MainWindow, 4);

	LFGMM_LfgTab_BroadcastMessageInfoWindow:Hide();
	LFGMM_LfmTab_BroadcastMessageInfoWindow:Hide();
	LFGMM_SettingsTab_RequestInviteMessageInfoWindow:Hide();
	LFGMM_ListTab_MessageInfoWindow_Hide();
	
	LFGMM_LfgTab:Hide();
	LFGMM_LfmTab:Hide();
	LFGMM_ListTab:Hide();
	LFGMM_SettingsTab:Show();

	LFGMM_MainWindowTab1:SetPoint ("CENTER", "LFGMM_MainWindow", "BOTTOMLEFT",    60, -14);
	LFGMM_MainWindowTab2:SetPoint ("CENTER", "LFGMM_MainWindow", "BOTTOMLEFT",   135, -14);
	LFGMM_MainWindowTab3:SetPoint ("CENTER", "LFGMM_MainWindow", "BOTTOMRIGHT", -140, -14);
	LFGMM_MainWindowTab4:SetPoint ("CENTER", "LFGMM_MainWindow", "BOTTOMRIGHT",  -60, -17);
end


function LFGMM_SettingsTab_ShowMinimapButtonCheckBox_OnClick()
	LFGMM_DB.SETTINGS.ShowMinimapButton = LFGMM_SettingsTab_ShowMinimapButtonCheckBox:GetChecked();

	if (LFGMM_DB.SETTINGS.ShowMinimapButton) then
		LFGMM_MinimapButton_Frame:Show();
	else
		LFGMM_MinimapButton_Frame:Hide();
	end
end


function LFGMM_SettingsTab_ShowQuestLogButtonCheckBox_OnClick()
	LFGMM_DB.SETTINGS.ShowQuestLogButton = LFGMM_SettingsTab_ShowQuestLogButtonCheckBox:GetChecked();
	
	if (LFGMM_DB.SETTINGS.ShowQuestLogButton) then
		LFGMM_QuestLog_Button_Frame:Show();
	else
		LFGMM_QuestLog_Button_Frame:Hide();
	end
end


function LFGMM_SettingsTab_HideLowLevelCheckBox_OnClick()
	LFGMM_DB.SETTINGS.HideLowLevel = LFGMM_SettingsTab_HideLowLevelCheckBox:GetChecked();
	LFGMM_Core_RemoveUnavailableDungeonsFromSelections();
end


function LFGMM_SettingsTab_HideHighLevelCheckBox_OnClick()
	LFGMM_DB.SETTINGS.HideHighLevel = LFGMM_SettingsTab_HideHighLevelCheckBox:GetChecked();
	LFGMM_Core_RemoveUnavailableDungeonsFromSelections();
end


function LFGMM_SettingsTab_HidePvpCheckBox_OnClick()
	LFGMM_DB.SETTINGS.HidePvp = LFGMM_SettingsTab_HidePvpCheckBox:GetChecked();
	LFGMM_Core_RemoveUnavailableDungeonsFromSelections();
end


function LFGMM_SettingsTab_HideRaidsCheckBox_OnClick()
	LFGMM_DB.SETTINGS.HideRaids = LFGMM_SettingsTab_HideRaidsCheckBox:GetChecked();
	LFGMM_Core_RemoveUnavailableDungeonsFromSelections();
end


function LFGMM_SettingsTab_MaxMessageAgeSlider_OnValueChanged()
	local value = math.floor(LFGMM_SettingsTab_MaxMessageAgeSlider:GetValue());
	LFGMM_DB.SETTINGS.MaxMessageAge = value;
	LFGMM_SettingsTab_MaxMessageAgeValue:SetText(value .. " minutes");
end


function LFGMM_SettingsTab_BroadcastIntervalSlider_OnValueChanged()
	local value = math.floor(LFGMM_SettingsTab_BroadcastIntervalSlider:GetValue());
	LFGMM_DB.SETTINGS.BroadcastInterval = value;
	
	if (value == 1) then
		LFGMM_SettingsTab_BroadcastIntervalValue:SetText(value .. " minute");
	else
		LFGMM_SettingsTab_BroadcastIntervalValue:SetText(value .. " minutes");
	end
end


function LFGMM_SettingsTab_UpdateRequestInviteMessage()
	local message = LFGMM_SettingsTab_RequestInviteMessageTemplateInputBox:GetText();

	-- Store template
	LFGMM_DB.SETTINGS.RequestInviteMessageTemplate = message;

	-- Generate message
	message = string.gsub(message, "{[Ll]}", LFGMM_GLOBAL.PLAYER_LEVEL);
	message = string.gsub(message, "{[Cc]}", LFGMM_GLOBAL.PLAYER_CLASS.Name);
	message = string.gsub(message, "{[Xx]}", LFGMM_GLOBAL.PLAYER_CLASS.LocalizedName);
	message = string.gsub(message, "{.*}", "");
	message = string.sub(message, 1, 255);

	-- Store message
	LFGMM_DB.SETTINGS.RequestInviteMessage = message;

	-- Update preview
	LFGMM_SettingsTab_RequestInviteMessagePreview_Refresh();
end


function LFGMM_SettingsTab_RequestInviteMessagePreview_Refresh()
	local text = LFGMM_DB.SETTINGS.RequestInviteMessage;
	local textLength = string.len(text);
	local maxLength = 40;

	if (textLength > maxLength) then
		LFGMM_SettingsTab_RequestInviteMessagePreviewSlider:SetMinMaxValues(1, textLength - maxLength + 1);
		local sliderPosition = LFGMM_SettingsTab_RequestInviteMessagePreviewSlider:GetValue();
		text = string.sub(text, sliderPosition, sliderPosition + maxLength - 1);
		LFGMM_SettingsTab_RequestInviteMessagePreviewSlider:Show();
	else
		LFGMM_SettingsTab_RequestInviteMessagePreviewSlider:SetValue(1);
		LFGMM_SettingsTab_RequestInviteMessagePreviewSlider:Hide();
	end
	
	LFGMM_SettingsTab_RequestInviteMessagePreview:SetText(text);
end


function LFGMM_SettingsTab_RequestInviteMessageInfoButton_OnClick()
	if (LFGMM_SettingsTab_RequestInviteMessageInfoWindow:IsVisible()) then
		LFGMM_SettingsTab_RequestInviteMessageInfoWindow:Hide();
	else
		LFGMM_LfgTab_BroadcastMessageInfoWindow:Hide();
		LFGMM_LfmTab_BroadcastMessageInfoWindow:Hide();
		LFGMM_SettingsTab_RequestInviteMessageInfoWindow:Show();
	end
end

