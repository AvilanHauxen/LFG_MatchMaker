--[[
	LFG MatchMaker - Addon for World of Warcraft.
	Version: 1.0.5.1
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
-- POPUP WINDOW
------------------------------------------------------------------------------------------------------------------------


function LFGMM_PopupWindow_Initialize()
	LFGMM_PopupWindow:RegisterForDrag("LeftButton");
	LFGMM_PopupWindow:SetScript("OnDragStart", LFGMM_PopupWindow.StartMoving);
	LFGMM_PopupWindow:SetScript("OnDragStop", LFGMM_PopupWindow.StopMovingOrSizing);
	LFGMM_PopupWindow:SetScript("OnShow", function() PlaySound(SOUNDKIT.IG_PLAYER_INVITE); end);

	LFGMM_PopupWindow_WhisperButton:SetScript("OnClick", LFGMM_PopupWindow_WhisperButton_OnClick);
	LFGMM_PopupWindow_IgnoreButton:SetScript("OnClick", LFGMM_PopupWindow_IgnoreButton_OnClick);
	LFGMM_PopupWindow_WhoButton:SetScript("OnClick", LFGMM_PopupWindow_WhoButton_OnClick);
	LFGMM_PopupWindow_InviteButton:SetScript("OnClick", LFGMM_PopupWindow_InviteButton_OnClick);
	LFGMM_PopupWindow_RequestInviteButton:SetScript("OnClick", LFGMM_PopupWindow_RequestInviteButton_OnClick);
	LFGMM_PopupWindow_SkipWaitButton:SetScript("OnClick", LFGMM_PopupWindow_SkipWaitButton_OnClick);
	
	LFGMM_PopupWindow.UpdateAgeTimerLock = false;
	LFGMM_PopupWindow.UpdateWaitCountdownLock = false;
end


function LFGMM_PopupWindow_ShowForMatch(message)
	if (LFGMM_PopupWindow:IsVisible()) then
		return;
	end

	LFGMM_PopupWindow.Type = "MATCH";
	LFGMM_PopupWindow.Message = message;

	-- Title and buttons
	if (message.Type == "LFG") then
		LFGMM_PopupWindow_Title:SetText("Player found!");
		LFGMM_PopupWindow_RequestInviteButton:Hide();
		LFGMM_PopupWindow_InviteButton:Show();
	elseif (message.Type == "LFM") then
		LFGMM_PopupWindow_Title:SetText("Group found!");
		LFGMM_PopupWindow_RequestInviteButton:Show();
		LFGMM_PopupWindow_InviteButton:Hide();
	else
		LFGMM_PopupWindow_Title:SetText("Possible match found!");
		if (LFGMM_DB.SEARCH.LFM.Running) then
			LFGMM_PopupWindow_RequestInviteButton:Hide();
			LFGMM_PopupWindow_InviteButton:Show();
		else
			LFGMM_PopupWindow_RequestInviteButton:Show();
			LFGMM_PopupWindow_InviteButton:Hide();
		end
	end

	-- Show
	LFGMM_PopupWindow_IgnoreButton:Show();
	LFGMM_PopupWindow_WhoButton:Show();
	LFGMM_PopupWindow_WhisperButton:Show();

	-- Hide
	LFGMM_PopupWindow_WaitText:Hide();
	LFGMM_PopupWindow_WaitCountdownText:Hide();
	LFGMM_PopupWindow_SkipWaitButton:Hide();

	-- Show and refresh
	LFGMM_PopupWindow:Show();
	LFGMM_PopupWindow_Refresh();

	-- Age
	LFGMM_PopupWindow_StartUpdateAge();
end


function LFGMM_PopupWindow_ShowForInviteRequested(message)
	LFGMM_PopupWindow.Type = "REQUEST";
	LFGMM_PopupWindow.Message = message;

	-- Title
	LFGMM_PopupWindow_Title:SetText("Invite requested");

	-- Show
	LFGMM_PopupWindow_WaitText:Show();
	LFGMM_PopupWindow_WaitCountdownText:Show();
	LFGMM_PopupWindow_SkipWaitButton:Show();

	-- Hide
	LFGMM_PopupWindow_IgnoreButton:Hide();
	LFGMM_PopupWindow_WhoButton:Hide();
	LFGMM_PopupWindow_WhisperButton:Hide();
	LFGMM_PopupWindow_RequestInviteButton:Hide();
	LFGMM_PopupWindow_InviteButton:Hide();

	-- Show and refresh
	LFGMM_PopupWindow:Show();
	LFGMM_PopupWindow_Refresh();

	-- Age
	LFGMM_PopupWindow_StartUpdateAge();

	-- Countdown
	LFGMM_PopupWindow_StartWaitCountdown();
end


function LFGMM_PopupWindow_ShowForInvited(message)
	LFGMM_PopupWindow.Type = "INVITE";
	LFGMM_PopupWindow.Message = message;

	-- Title
	LFGMM_PopupWindow_Title:SetText("Invite received!");

	-- Show
	LFGMM_PopupWindow_WhoButton:Show();
	LFGMM_PopupWindow_WhisperButton:Show();

	-- Hide
	LFGMM_PopupWindow_IgnoreButton:Hide();
	LFGMM_PopupWindow_RequestInviteButton:Hide();
	LFGMM_PopupWindow_InviteButton:Hide();
	LFGMM_PopupWindow_WaitText:Hide();
	LFGMM_PopupWindow_WaitCountdownText:Hide();
	LFGMM_PopupWindow_SkipWaitButton:Hide();

	-- Show and refresh
	LFGMM_PopupWindow:Show();
	LFGMM_PopupWindow_Refresh();

	-- Age
	LFGMM_PopupWindow_StartUpdateAge();
end


function LFGMM_PopupWindow_Hide()
	-- Reset popup
	LFGMM_PopupWindow.Type = nil;
	LFGMM_PopupWindow.Message = nil;
	LFGMM_PopupWindow.WaitTimer = 0;

	-- Hide
	LFGMM_PopupWindow:Hide();

	-- Search again
	if (LFGMM_DB.SEARCH.LFG.Running or LFGMM_DB.SEARCH.LFM.Running) then
		C_Timer.After(2, LFGMM_Core_FindSearchMatch);
	end

	-- Release lock
	if (LFGMM_GLOBAL.SEARCH_LOCK) then
		LFGMM_GLOBAL.SEARCH_LOCK = false;
	end

	-- Refresh
	LFGMM_ListTab_MessageInfoWindow_Refresh();
end


function LFGMM_PopupWindow_HideForInvited()
	if (LFGMM_PopupWindow:IsVisible() and LFGMM_PopupWindow.Type == "INVITE") then
		LFGMM_PopupWindow_Hide();
	end
end


function LFGMM_PopupWindow_Refresh()
	-- Return if window has been hidden
	if (not LFGMM_PopupWindow:IsVisible()) then
		return;
	end

	local message = LFGMM_PopupWindow.Message;
	
	-- Class
	LFGMM_PopupWindow_ClassIcon:SetTexCoord(unpack(LFGMM_PopupWindow.Message.PlayerClass.IconCoordinates));
	LFGMM_PopupWindow_ClassText:SetText(message.PlayerClass.Color .. message.PlayerClass.LocalizedName);

	-- Level
	LFGMM_PopupWindow_LevelText:SetText(message.PlayerClass.Color .. (message.PlayerLevel or "?"));
	
	-- Player
	LFGMM_PopupWindow_PlayerText:SetText(message.PlayerClass.Color .. "[" .. message.Player .. "]:");
	
	-- Message
	LFGMM_PopupWindow_MessageText:SetText(LFGMM_PopupWindow.Message.Message);

	-- Window size
	LFGMM_PopupWindow:SetHeight(LFGMM_PopupWindow_MessageText:GetHeight() + 115);

	-- Who button
	if (LFGMM_PopupWindow.Type ~= "REQUEST") then
		if (message.PlayerLevel ~= nil) then
			LFGMM_PopupWindow_WhoButton:Hide();
		else
			LFGMM_PopupWindow_WhoButton:Show();

			if (LFGMM_GLOBAL.WHO_COOLDOWN > 0) then
				LFGMM_PopupWindow_WhoButton:SetText("Who? (" .. LFGMM_GLOBAL.WHO_COOLDOWN .. ")");
				LFGMM_PopupWindow_WhoButton:Disable();
			else
				LFGMM_PopupWindow_WhoButton:SetText("Who?");
				LFGMM_PopupWindow_WhoButton:Enable();
			end
		end
	end
	
	-- Refresh info window
	LFGMM_ListTab_MessageInfoWindow_Refresh();
end


function LFGMM_PopupWindow_WhisperButton_OnClick()
	LFGMM_Core_OpenWhisper(LFGMM_PopupWindow.Message);
end


function LFGMM_PopupWindow_WhoButton_OnClick()
	LFGMM_Core_WhoRequest(LFGMM_PopupWindow.Message);
end


function LFGMM_PopupWindow_IgnoreButton_OnClick()
	LFGMM_Core_Ignore(LFGMM_PopupWindow.Message);
	LFGMM_PopupWindow_Hide();
end


function LFGMM_PopupWindow_InviteButton_OnClick()
	LFGMM_Core_Invite(LFGMM_PopupWindow.Message);
	LFGMM_PopupWindow_Hide();
end


function LFGMM_PopupWindow_RequestInviteButton_OnClick()
	LFGMM_Core_RequestInvite(LFGMM_PopupWindow.Message);
	LFGMM_PopupWindow_ShowForInviteRequested(LFGMM_PopupWindow.Message);
	
	-- Refresh
	LFGMM_ListTab_MessageInfoWindow_Refresh();
end


function LFGMM_PopupWindow_SkipWaitButton_OnClick()
	LFGMM_PopupWindow_Hide();
end


function LFGMM_PopupWindow_StartUpdateAge()
	-- Set age text
	local ageText = LFGMM_Utility_GetAgeText(LFGMM_PopupWindow.Message.Timestamp);
	LFGMM_PopupWindow_TimeText:SetText("Announced " .. ageText);
	
	-- Start timer
	if (not LFGMM_PopupWindow.UpdateAgeTimerLock) then
		LFGMM_PopupWindow.UpdateAgeTimerLock = true;
		LFGMM_PopupWindow_UpdateAge();
	end
end


function LFGMM_PopupWindow_UpdateAge()
	-- Return if hidden
	if (not LFGMM_PopupWindow:IsVisible()) then
		LFGMM_PopupWindow.UpdateAgeTimerLock = false;
		return;
	end
	
	-- Update age text
	local ageText = LFGMM_Utility_GetAgeText(LFGMM_PopupWindow.Message.Timestamp);
	LFGMM_PopupWindow_TimeText:SetText("Announced " .. ageText);
	
	C_Timer.After(1, LFGMM_PopupWindow_UpdateAge);
end


function LFGMM_PopupWindow_StartWaitCountdown()
	-- Set wait countdown
	LFGMM_PopupWindow.WaitTimer = 60;
	LFGMM_PopupWindow_WaitCountdownText:SetText(60);

	-- Start countdown
	if (not LFGMM_PopupWindow.UpdateWaitCountdownLock) then
		LFGMM_PopupWindow.UpdateWaitCountdownLock = true;
		LFGMM_PopupWindow_UpdateWaitCountdown();
	end
end


function LFGMM_PopupWindow_UpdateWaitCountdown()
	-- Return if hidden
	if (not LFGMM_PopupWindow:IsVisible() or not LFGMM_PopupWindow_WaitCountdownText:IsVisible()) then
		LFGMM_PopupWindow.UpdateWaitCountdownLock = false;
		return;
	end

	-- Hide if countdown reached zero
	if (LFGMM_PopupWindow.WaitTimer == 0) then
		LFGMM_PopupWindow.UpdateWaitCountdownLock = false;
		LFGMM_PopupWindow_Hide();
		
	else
		-- Hide if group has been joined
		if (table.getn(LFGMM_GLOBAL.GROUP_MEMBERS) > 1) then
			LFGMM_PopupWindow.UpdateWaitCountdownLock = false;
			LFGMM_PopupWindow_Hide();

		-- Update wait countdown
		else
			LFGMM_PopupWindow_WaitCountdownText:SetText(LFGMM_PopupWindow.WaitTimer);
			LFGMM_PopupWindow.WaitTimer = LFGMM_PopupWindow.WaitTimer - 1;

			C_Timer.After(1, LFGMM_PopupWindow_UpdateWaitCountdown);
		end
	end
end


function LFGMM_PopupWindow_MoveToPartyInviteDialog()
	for index = 1, STATICPOPUP_NUMDIALOGS, 1 do
		local frameName = "StaticPopup" .. index;

		if (_G[frameName].which == "PARTY_INVITE") then
			LFGMM_PopupWindow_SavePosition();
			LFGMM_PopupWindow:ClearAllPoints();
			LFGMM_PopupWindow:SetPoint("TOP", frameName, "BOTTOM", 0, -25);
			break;
		end
	end
end


function LFGMM_PopupWindow_SavePosition()
	local point, relativeTo, relativePoint, x, y = LFGMM_PopupWindow:GetPoint();

	LFGMM_PopupWindow.SavedPosition = {
		Point = point,
		RelativeTo = relativeTo,
		RelativePoint = relativePoint,
		X = x,
		Y = y
	};
end


function LFGMM_PopupWindow_RestorePosition()
	if (LFGMM_PopupWindow.SavedPosition ~= nil) then
		LFGMM_PopupWindow:ClearAllPoints();
		LFGMM_PopupWindow:SetPoint(
			LFGMM_PopupWindow.SavedPosition.Point,
			LFGMM_PopupWindow.SavedPosition.RelativeTo,
			LFGMM_PopupWindow.SavedPosition.RelativePoint,
			LFGMM_PopupWindow.SavedPosition.X,
			LFGMM_PopupWindow.SavedPosition.Y
		);
	end
end

