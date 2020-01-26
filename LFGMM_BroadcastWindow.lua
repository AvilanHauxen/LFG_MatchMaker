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
-- BROADCAST WINDOW
------------------------------------------------------------------------------------------------------------------------


function LFGMM_BroadcastWindow_Initialize()
	LFGMM_BroadcastWindow:RegisterForDrag("LeftButton");
	LFGMM_BroadcastWindow:SetScript("OnDragStart", LFGMM_BroadcastWindow.StartMoving);
	LFGMM_BroadcastWindow:SetScript("OnDragStop", LFGMM_BroadcastWindow.StopMovingOrSizing);
	LFGMM_BroadcastWindow:SetScript("OnShow", function() PlaySound(SOUNDKIT.GS_LOGIN); end);
	
	LFGMM_BroadcastWindow_BroadcastButton:SetScript("OnClick", LFGMM_BroadcastWindow_BroadcastButton_OnClick);
end


function LFGMM_BroadcastWindow_Show()
	-- Title
	if (LFGMM_DB.SEARCH.LFG.Running) then
		LFGMM_BroadcastWindow_Title:SetText("LFG broadcast available");
	elseif (LFGMM_DB.SEARCH.LFM.Running) then
		LFGMM_BroadcastWindow_Title:SetText("LFM broadcast available");
	end

	-- Show
	LFGMM_BroadcastWindow:Show();
end


function LFGMM_BroadcastWindow_BroadcastButton_OnClick()
	-- Send broadcast
	LFGMM_BroadcastWindow_SendBroadcastMessage();
	
	-- Start re-broadcast window timer
	LFGMM_BroadcastWindow_Timer();

	-- Hide
	LFGMM_BroadcastWindow:Hide();
end


function LFGMM_BroadcastWindow_StartBroadcast()
	-- Ensure lock
	if (LFGMM_GLOBAL.BROADCAST_LOCK) then
		return;
	end

	-- Lock
	LFGMM_GLOBAL.BROADCAST_LOCK = true;

	-- Send broadcast
	LFGMM_BroadcastWindow_SendBroadcastMessage();
	
	-- Start re-broadcast window timer
	LFGMM_BroadcastWindow_Timer();
end


function LFGMM_BroadcastWindow_CancelBroadcast()
	-- Reset lock if window is visible
	if (LFGMM_BroadcastWindow:IsVisible()) then
		LFGMM_GLOBAL.BROADCAST_LOCK = false;
	end

	-- Hide
	LFGMM_BroadcastWindow:Hide();
end


function LFGMM_BroadcastWindow_SendBroadcastMessage()
	-- Get next broadcast time
	local interval = LFGMM_DB.SETTINGS.BroadcastInterval * 60;
	local nextBroadcast = LFGMM_DB.SEARCH.LastBroadcast + interval;

	-- Broadcast message
	if (time() >= nextBroadcast) then
		local channelIndex = GetChannelName(LFGMM_GLOBAL.LFG_CHANNEL_NAME);
		if (channelIndex ~= nil) then
			if (LFGMM_DB.SEARCH.LFG.Running) then
				SendChatMessage(LFGMM_DB.SEARCH.LFG.BroadcastMessage, "CHANNEL", nil, channelIndex);
			elseif (LFGMM_DB.SEARCH.LFM.Running) then
				SendChatMessage(LFGMM_DB.SEARCH.LFM.BroadcastMessage, "CHANNEL", nil, channelIndex);
			end

			LFGMM_DB.SEARCH.LastBroadcast = time();
		end
	end
end


function LFGMM_BroadcastWindow_Timer()
	-- Return if search is stopped
	if (not LFGMM_DB.SEARCH.LFG.Running and not LFGMM_DB.SEARCH.LFM.Running) then
		LFGMM_GLOBAL.BROADCAST_LOCK = false;
		return;
	end

	-- Return if broadcast is disabled
	if (not LFGMM_DB.SEARCH.LFG.Broadcast and not LFGMM_DB.SEARCH.LFM.Broadcast) then
		LFGMM_GLOBAL.BROADCAST_LOCK = false;
		return;
	end

	-- Get next broadcast time
	local interval = LFGMM_DB.SETTINGS.BroadcastInterval * 60;
	local nextBroadcast = LFGMM_DB.SEARCH.LastBroadcast + interval;

	-- Show re-broadcast window
	if (time() >= nextBroadcast) then
		LFGMM_BroadcastWindow_Show();

	-- Wait untill next broadcast
	else
		local timeToNextBroadcast = nextBroadcast - time();
		if (timeToNextBroadcast < 60) then
			C_Timer.After(timeToNextBroadcast, LFGMM_BroadcastWindow_Timer);
		else
			C_Timer.After(60, LFGMM_BroadcastWindow_Timer);
		end
	end
end

