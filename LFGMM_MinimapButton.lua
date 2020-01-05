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
-- MINIMAP BUTTON
------------------------------------------------------------------------------------------------------------------------


function LFGMM_MinimapButton_Initialize()
	LFGMM_MinimapButton_Button:RegisterForDrag("LeftButton");
	LFGMM_MinimapButton_Button:SetScript("OnDragStart", LFGMM_MinimapButton_Frame_OnDragStart);
	LFGMM_MinimapButton_Button:SetScript("OnDragStop", LFGMM_MinimapButton_Frame_OnDragStop);
	
	LFGMM_MinimapButton_SetPosition(LFGMM_DB.SETTINGS.MinimapButtonPosition);
	
	if (LFGMM_DB.SETTINGS.ShowMinimapButton) then
		LFGMM_MinimapButton_Frame:Show();
	end
end


function LFGMM_MinimapButton_Frame_OnDragStart()
	LFGMM_MinimapButton_Frame:StartMoving();
	LFGMM_MinimapButton_Frame:SetScript("OnUpdate", LFGMM_MinimapButton_SetNewPosition);
end


function LFGMM_MinimapButton_Frame_OnDragStop()
	LFGMM_MinimapButton_Frame:StopMovingOrSizing();
	LFGMM_MinimapButton_Frame:SetScript("OnUpdate", nil);
	LFGMM_MinimapButton_SetNewPosition();
end


function LFGMM_MinimapButton_SetNewPosition()
	local cursorXpos, cursorYpos = GetCursorPosition();
	local minX = Minimap:GetLeft();
	local minY = Minimap:GetBottom();
	local targetPosX = minX - cursorXpos / Minimap:GetEffectiveScale() + 70;
	local targetPosY = cursorYpos / Minimap:GetEffectiveScale() - minY - 70;
	local buttonPosition = math.deg(math.atan2(targetPosY, targetPosX));

	LFGMM_DB.SETTINGS.MinimapButtonPosition = buttonPosition;
	LFGMM_MinimapButton_SetPosition(buttonPosition);
end


function LFGMM_MinimapButton_SetPosition(buttonPosition)
	LFGMM_MinimapButton_Frame:ClearAllPoints();
	LFGMM_MinimapButton_Frame:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 52 - (80 * cos(buttonPosition)), (80 * sin(buttonPosition)) - 52);
end

