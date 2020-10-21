--[[
	LFG MatchMaker - Addon for World of Warcraft.
	Version: 1.0.9
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
-- SAVED VARIABLES
------------------------------------------------------------------------------------------------------------------------


function LFGMM_Load()
	LFGMM_DB_VERSION = 4;
	
	-- Get locale language
	local locale = GetLocale();
	if (locale == "deDE") then
		locale = "DE";
	elseif (locale == "frFR") then
		locale = "FR";
	elseif (locale == "esES" or locale == "esMX") then
		locale = "ES";
	else
		locale = nil;
	end

	-- Database
	if (LFGMM_DB == nil) then
		LFGMM_DB = {
			VERSION = LFGMM_DB_VERSION,
			SETTINGS = {
				MessageTimeout = 30,
				MaxMessageAge = 10,
				BroadcastInterval = 2,
				InfoWindowLocation = "right",
				RequestInviteMessage = "",
				RequestInviteMessageTemplate = "Invite for group ({L} {C})",
				ShowQuestLogButton = true,
				ShowMinimapButton = true,
				HideLowLevel = false,
				HideHighLevel = false,
				HidePvp = false,
				HideRaids = false,
				MinimapLibDBSettings = {},
				IdentifierLanguages = { "EN" },
				UseTradeChannel = false,
				UseGeneralChannel = false,
			},
			LIST = {
				Dungeons = {},
				ShowUnknownDungeons = false,
				MessageTypes = {
					Unknown = false,
					Lfg = true,
					Lfm = true,
				}
			},
			SEARCH = {
				LastBroadcast = time() - 600,
				LFG = {
					Running = false,
					MatchLfg = false,
					MatchUnknown = true,
					AutoStop = true,
					Broadcast = false,
					BroadcastMessage = "",
					BroadcastMessageTemplate = "{L} {C} LFG {A}",
					Dungeons = {},
				},
				LFM = {
					Running = false,
					MatchLfm = false,
					MatchUnknown = true,
					AutoStop = true,
					Broadcast = false,
					BroadcastMessage = "",
					BroadcastMessageTemplate = "LF{N}M {D}",
					Dungeon = nil,
				}
			}
		};
		
		-- Add locale identifier language
		if (locale ~= nil) then
			table.insert(LFGMM_DB.SETTINGS.IdentifierLanguages, locale);
		end

		-- Add all dungeons to list selection
		for _,dungeon in ipairs(LFGMM_GLOBAL.DUNGEONS) do
			table.insert(LFGMM_DB.LIST.Dungeons, dungeon.Index);
		end

	else
		if (LFGMM_DB.VERSION <= 1) then
			LFGMM_DB.SETTINGS.IdentifierLanguages = { "EN" };

			-- Add locale identifier language
			if (locale ~= nil) then
				table.insert(LFGMM_DB.SETTINGS.IdentifierLanguages, locale);
			end
		end
		
		if (LFGMM_DB.VERSION <= 2) then
			LFGMM_DB.SEARCH.LFG.AutoStop = true;
			LFGMM_DB.SEARCH.LFM.AutoStop = true;
		end
		
		if (LFGMM_DB.VERSION <= 3) then
			LFGMM_DB.SETTINGS.MinimapLibDBSettings = {};
			LFGMM_DB.SETTINGS.InfoWindowLocation = "right";
			LFGMM_DB.SETTINGS.UseTradeChannel = false;
			LFGMM_DB.SETTINGS.UseGeneralChannel = false;
		end
		
		if (LFGMM_DB.VERSION < LFGMM_DB_VERSION) then
			LFGMM_DB.VERSION = LFGMM_DB_VERSION;
		end
	end
	
	-- OnLoad search = off
	LFGMM_DB.SEARCH.LFG.Running = false;
	LFGMM_DB.SEARCH.LFM.Running = false;
end


------------------------------------------------------------------------------------------------------------------------
-- GLOBAL VARIABLES
------------------------------------------------------------------------------------------------------------------------


LFGMM_GLOBAL = {
	READY = false,
	LIST_SCROLL_INDEX = 1,
	SEARCH_LOCK = false,
	BROADCAST_LOCK = false,
	AUTOSTOP_AVAILABLE = true,
	WHO_COOLDOWN = 0,
	PLAYER_NAME = "",
	PLAYER_LEVEL = 0,
	PLAYER_CLASS = "",
	LFG_CHANNEL_NAME = "LookingForGroup",
	GENERAL_CHANNEL_NAME = "General",
	TRADE_CHANNEL_NAME = "Trade",
	TRADE_CHANNEL_AVAILABLE = false,
	GROUP_MEMBERS = {},
	MESSAGES = {},
	LANGUAGES = {
		{ 
			Code = "EN",
			Name = "English",
		},
		{ 
			Code = "DE",
			Name = "German",
		},
		{ 
			Code = "FR",
			Name = "French",
		},
		{ 
			Code = "ES",
			Name = "Spanish",
		},
		-- { 
			-- Code = "RU",
			-- Name = "Russian",
		-- },
	},
	CLASSES = {
		WARRIOR = {
			Name = "Warrior",
			LocalizedName = LOCALIZED_CLASS_NAMES_MALE.WARRIOR,
			IconCoordinates = CLASS_ICON_TCOORDS.WARRIOR,
			Color = "|cFFC79C6E",
		},
		PALADIN = {
			Name = "Paladin",
			LocalizedName = LOCALIZED_CLASS_NAMES_MALE.PALADIN,
			IconCoordinates = CLASS_ICON_TCOORDS.PALADIN,
			Color = "|cFFF58CBA",
		},
		HUNTER = {
			Name = "Hunter",
			LocalizedName = LOCALIZED_CLASS_NAMES_MALE.HUNTER,
			IconCoordinates = CLASS_ICON_TCOORDS.HUNTER,
			Color = "|cFFABD473",
		},
		ROGUE = {
			Name = "Rogue",
			LocalizedName = LOCALIZED_CLASS_NAMES_MALE.ROGUE,
			IconCoordinates = CLASS_ICON_TCOORDS.ROGUE,
			Color = "|cFFFFF569",
		},
		PRIEST = {
			Name = "Priest",
			LocalizedName = LOCALIZED_CLASS_NAMES_MALE.PRIEST,
			IconCoordinates = CLASS_ICON_TCOORDS.PRIEST,
			Color = "|cFFFFFFFF",
		},
		SHAMAN = {
			Name = "Shaman",
			LocalizedName = LOCALIZED_CLASS_NAMES_MALE.SHAMAN,
			IconCoordinates = CLASS_ICON_TCOORDS.SHAMAN,
			Color = "|cFF0070DE",
		},
		MAGE = {
			Name = "Mage",
			LocalizedName = LOCALIZED_CLASS_NAMES_MALE.MAGE,
			IconCoordinates = CLASS_ICON_TCOORDS.MAGE,
			Color = "|cFF69CCF0",
		},
		WARLOCK = {
			Name = "Warlock",
			LocalizedName = LOCALIZED_CLASS_NAMES_MALE.WARLOCK,
			IconCoordinates = CLASS_ICON_TCOORDS.WARLOCK,
			Color = "|cFF9482C9",
		},
		DRUID = {
			Name = "Druid",
			LocalizedName = LOCALIZED_CLASS_NAMES_MALE.DRUID,
			IconCoordinates = CLASS_ICON_TCOORDS.DRUID,
			Color = "|cFFFF7D0A",
		},
	},
	MESSAGETYPE_IDENTIFIERS = {
		EN = {
			{
				Type = "LFG",
				Identifiers = {
					"lfg",
					"lf[%W]*group",
					"looking[%W]*for[%W]*group",
					"dps[%W]*lf",
					"tank[%W]*lf",
					"heal[e]?[r]?[%W]*lf",
					"dps[%W]*looking[%W]*for",
					"tank[%W]*looking[%W]*for",
					"heal[e]?[r]?[%W]*looking[%W]*for",
					"pri[e]?st[%W]*lf",
					"warr[i]?[o]?[r]?[%W]*lf",
					"mage[%W]*lf",
					"[w]?[a]?[r]?lock[%W]*lf",
					"shaman[%W]*lf",
					"pala[d]?[i]?[n]?[%W]*lf",
					"hunt[e]?[r]?[%W]*lf",
					"ro[u]?g[u]?e[%W]*lf",
					"druid[%W]*lf",
					"pri[e]?st[%W]*looking[%W]*for",
					"warr[i]?[o]?[r]?[%W]*looking[%W]*for",
					"mage[%W]*looking[%W]*for",
					"[w]?[a]?[r]?lock[%W]*looking[%W]*for",
					"shaman[%W]*looking[%W]*for",
					"pala[d]?[i]?[n]?[%W]*looking[%W]*for",
					"hunt[e]?[r]?[%W]*looking[%W]*for",
					"ro[u]?g[u]?e[%W]*looking[%W]*for",
					"druid[%W]*looking[%W]*for",
				}
			},
			{
				Type = "LFM",
				Identifiers = {
					"lf[%W]*[%d]+",
					"lf[%W]*[%d]*[%W]*m",
					"lf[%W]*[%d]*[ax]?[%W]*dps",
					"lf[%W]*[%d]*[ax]?[%W]*tank",
					"lf[%W]*[%d]*[ax]?[%W]*heal",
					"lf[%W]*[%d]*[ax]?[%W]*dd",
					"lf[%W]*[%d]*[ax]?[%W]*caster",
					"lf[%W]*[%d]*[ax]?[%W]*mele",
					"lf[%W]*[%d]*[ax]?[%W]*range",
					"looking[%W]*for[%W]*[%d]*[ax]?[%W]*dps",
					"looking[%W]*for[%W]*[%d]*[ax]?[%W]*tank",
					"looking[%W]*for[%W]*[%d]*[ax]?[%W]*heal",
					"looking[%W]*for[%W]*[%d]*[ax]?[%W]*dd",
					"looking[%W]*for[%W]*[%d]*[ax]?[%W]*caster",
					"looking[%W]*for[%W]*[%d]*[ax]?[%W]*mele",
					"looking[%W]*for[%W]*[%d]*[ax]?[%W]*range",
					"lf[%W]*[%d]*[ax]?[%W]*pri[e]?st",
					"lf[%W]*[%d]*[ax]?[%W]*warr",
					"lf[%W]*[%d]*[ax]?[%W]*mage",
					"lf[%W]*[%d]*[ax]?[%W]*[w]?[a]?[r]?lock",
					"lf[%W]*[%d]*[ax]?[%W]*shaman",
					"lf[%W]*[%d]*[ax]?[%W]*pala",
					"lf[%W]*[%d]*[ax]?[%W]*hunt",
					"lf[%W]*[%d]*[ax]?[%W]*ro[u]?g[u]?e",
					"lf[%W]*[%d]*[ax]?[%W]*druid",
					"looking[%W]*for[%W]*[%d]*[ax]?[%W]*pri[e]?st",
					"looking[%W]*for[%W]*[%d]*[ax]?[%W]*warr",
					"looking[%W]*for[%W]*[%d]*[ax]?[%W]*mage",
					"looking[%W]*for[%W]*[%d]*[ax]?[%W]*[w]?[a]?[r]?lock",
					"looking[%W]*for[%W]*[%d]*[ax]?[%W]*shaman",
					"looking[%W]*for[%W]*[%d]*[ax]?[%W]*pala",
					"looking[%W]*for[%W]*[%d]*[ax]?[%W]*hunt",
					"looking[%W]*for[%W]*[%d]*[ax]?[%W]*ro[u]?g[u]?e",
					"looking[%W]*for[%W]*[%d]*[ax]?[%W]*druid",
					"need[%W]*one[%W]*more",
					"need[%W]*[%d]+[%W]*more",
					"need[%W]*[%d]*[%W]*dps",
					"need[%W]*[%d]*[%W]*tank",
					"need[%W]*[%d]*[%W]*heal",
					"need[%W]*[%d]*[%W]*dd",
					"need[%W]*[%d]*[%W]*caster",
					"need[%W]*[%d]*[%W]*mele",
					"need[%W]*[%d]*[%W]*range",
					"seek[%W]*one[%W]*more",
					"seek[%W]*[%d]+[%W]*more",
					"seek[%W]*[%d]+[%W]*more",
					"seek[%W]*[%d]*[%W]*dps",
					"seek[%W]*[%d]*[%W]*tank",
					"seek[%W]*[%d]*[%W]*heal",
					"seek[%W]*[%d]*[%W]*dd",
					"seek[%W]*[%d]*[%W]*caster",
					"seek[%W]*[%d]*[%W]*mele",
					"seek[%W]*[%d]*[%W]*range",
					"last[%W]*dps",
					"last[%W]*tank",
					"last[%W]*heal",
					"last[%W]*spot",
					"any[%W]*dps[%W]*for",
					"any[%W]*tank[%W]*for",
					"any[%W]*heal[e]?[r]?[%W]*for",
				}
			}
		},
		-- DE = {},
		FR = {
			{
				Type = "LFG",
				Identifiers = {
					"[%d][%d][%W]*dispo[n]?[i]?[b]?[l]?[e]?",
					"[%d][%d][%W]*cherch[e]?[o]?[n]?[s]?",
					"[%d][%d][%W]*up[%W]*pour",
					"[%d][%d][%W]*dps[%W]*pour",
					"[%d][%d][%W]*tank[%W]*pour",
					"[%d][%d][%W]*heal[e]?[r]?[%W]*pour",
					"[%d][%d][%W]*soigneur[%W]*pour",
					"cherch[e]?[o]?[n]?[s]?[%W]*[d]?[%W]*[u]?[n]?[%d]*[%W]*g[r]?oupe",
					"cherch[e]?[o]?[n]?[s]?[%W]*[d]?[%W]*[u]?[n]?[%d]*[%W]*grp",
				}
			},
			{
				Type = "LFM",
				Identifiers = {
					"un[%W]*dps[%W]*[d]?[e]?[%W]*dispo[n]?[i]?[b]?[l]?[e]?[%W]*pour",
					"un[%W]*tank[%W]*[d]?[e]?[%W]*dispo[n]?[i]?[b]?[l]?[e]?[%W]*pour",
					"un[%W]*heal[e]?[r]?[%W]*[d]?[e]?[%W]*dispo[n]?[i]?[b]?[l]?[e]?[%W]*pour",
					"un[%W]*soigneur[%W]*[d]?[e]?[%W]*dispo[n]?[i]?[b]?[l]?[e]?[%W]*pour",
					"un[%W]*dps[%W]*up[%W]*pour",
					"un[%W]*tank[%W]*up[%W]*pour",
					"un[%W]*heal[e]?[r]?[%W]*up[%W]*pour",
					"un[%W]*soigneur[%W]*up[%W]*pour",
					"un[%W]*dps[%W]*pour",
					"un[%W]*tank[%W]*pour",
					"un[%W]*heal[e]?[r]?[%W]*pour",
					"un[%W]*soigneur[%W]*pour",
					"un[%W]*dps[%W]*et",
					"un[%W]*tank[%W]*et",
					"un[%W]*heal[e]?[r]?[%W]*et",
					"un[%W]*soigneur[%W]*et",
					"un[%W]*dps[%W]*ou",
					"un[%W]*tank[%W]*ou",
					"un[%W]*heal[e]?[r]?[%W]*ou",
					"un[%W]*soigneur[%W]*ou",
					"un[%W]*dps[%W]*un",
					"un[%W]*tank[%W]*un",
					"un[%W]*heal[e]?[r]?[%W]*un",
					"un[%W]*soigneur[%W]*un",
					"un[%W]*petit[%W]*dps",
					"un[%W]*petit[%W]*tank",
					"un[%W]*petit[%W]*heal",
					"un[%W]*petit[%W]*soigneur",
					"deux[%W]*dps[%W]*pour",
					"deux[%W]*dps[%W]*et",
					"deux[%W]*dps[%W]*ou",
					"deux[%W]*petit[%W]*dps",
					"[%d][%W]*petit[%W]*dps",
					"[%d][%W]*petit[%W]*tank",
					"[%d][%W]*petit[%W]*heal",
					"[%d][%W]*petit[%W]*soigneur",
					"[%d][%W]*dps[%W]*pour",
					"[%d][%W]*tank[%W]*pour",
					"[%d][%W]*heal[e]?[r]?[%W]*pour",
					"[%d][%W]*soigneur[%W]*pour",
					"[%d][%W]*dps[%W]*et",
					"[%d][%W]*tank[%W]*et",
					"[%d][%W]*heal[e]?[r]?[%W]*et",
					"[%d][%W]*soigneur[%W]*et",
					"[%d][%W]*dps[%W]*ou",
					"[%d][%W]*tank[%W]*ou",
					"[%d][%W]*heal[e]?[r]?[%W]*ou",
					"[%d][%W]*soigneur[%W]*ou",
					"besoin[%W]*[d]?[%W]*[u]?[n]?[%d]*[%W]*dps",
					"besoin[%W]*[d]?[%W]*[u]?[n]?[%d]*[%W]*tank",
					"besoin[%W]*[d]?[%W]*[u]?[n]?[%d]*[%W]*heal",
					"besoin[%W]*[d]?[%W]*[u]?[n]?[%d]*[%W]*soigneur",
					"cherch[e]?[o]?[n]?[s]?[%W]*[d]?[%W]*[u]?[n]?[%d]*[%W]*dps",
					"cherch[e]?[o]?[n]?[s]?[%W]*[d]?[%W]*[u]?[n]?[%d]*[%W]*tank",
					"cherch[e]?[o]?[n]?[s]?[%W]*[d]?[%W]*[u]?[n]?[%d]*[%W]*heal",
					"cherch[e]?[o]?[n]?[s]?[%W]*[d]?[%W]*[u]?[n]?[%d]*[%W]*soigneur",
					"encore[%W]*un[%W]*dps",
					"encore[%W]*un[%W]*tank",
					"encore[%W]*un[%W]*heal",
					"encore[%W]*un[%W]*soigneur",
					"encore[%W]*un[%W]*place",
					"dernier[e]?[%W]*dps",
					"dernier[e]?[%W]*tank",
					"dernier[e]?[%W]*heal",
					"dernier[e]?[%W]*soigneur",
					"dernier[e]?[%W]*place",
					"dernier[e]?[%W]*person",
					"manque[%W]*[u]?[n]?[%d]*[%W]*dps",
					"manque[%W]*[u]?[n]?[%d]*[%W]*tank",
					"manque[%W]*[u]?[n]?[%d]*[%W]*heal",
					"manque[%W]*[u]?[n]?[%d]*[%W]*soigneur",
					"manque[%W]*[u]?[n]?[%d]*[%W]*person",
					"dps[%W]*demande",
					"tank[%W]*demande",
					"heal[%W]*demande",
					"soigneur[%W]*demande",
					"reste[%W]*[%d]+[%W]*place[s]?[%W]*pour",
					"de[%W]*tout[%W]*pour",
					"last[%W]*pour",
					"recrute[%W]*pour",
					"monte[%W]*g[r]?oupe",
					"monte[%W]*grp",
					"[%W]+et[t]?[%W]*go[%W]+",
					"[%W]+et[t]?[%W]*go$",
				}
			},
			{
				Type = "LFG",
				Identifiers = {
					"dps[%W]*up[%W]*pour",
					"tank[%W]*up[%W]*pour",
					"heal[e]?[r]?[%W]*up[%W]*pour",
					"soigneur[%W]*up[%W]*pour",
					"dispo[n]?[i]?[b]?[l]?[e]?[%W]+",
					"dispo[n]?[i]?[b]?[l]?[e]?$",
				}
			},
		},
		-- ES = {},
		-- RU = {},
	},
	DUNGEONS = {
		{
			Index = 1,
			Name = "Ragefire Chasm",
			Abbreviation = "RFC",
			Identifiers = {
				EN = {
					"rage[%W]*fire[%W]*c[h]?asm",
					"rage[%W]*fire",
					"rfc",
				},
				DE = {
					-- Der Flammenschlund / Ragefireabgrund
					"rage[%W]*fire[%W]*abgrund",
					"flammen[%W]*schlund",
					"rfa",
					"rf",
				},
				FR = {
					-- Gouffre de Ragefeu
					"gouf[f]?re[%W]*[d]?[e]?[%W]*ragefeu",
					"ragefeu",
					"rf",
				},
				ES = {
					-- Sima Ígnea
					"sima[%W]*ignea",
					"sima",
				},
				RU = {},
			},
			Size = 5,
			MinLevel = 13,
			MaxLevel = 18,
		},
		{
			Index = 2,
			Name = "Wailing Caverns",
			Abbreviation = "WC",
			Identifiers = {
				EN = { 
					"wa[i]?ling[%W]*cavern[s]?",
					"wc",
				},
				DE = {
					-- Die Höhlen des Wehklagens
					"ho[e]?hlen[%W]*[d]?[e]?[s]?[%W]*we[h]?klagen[s]?",
					"hdw",
				},
				FR = {
					-- Cavernes des lamentations
					"lamentation[s]?",
					"lam[s]?",
				},
				ES = {
					-- Cuevas de los Lamentos
					"cueva[s]?[%W]*[d]?[e]?[%W]*[l]?[o]?[s]?[%W]*lamento[s]?",
				},
				RU = {},
			},
			Size = 5,
			MinLevel = 15,
			MaxLevel = 25,
		},
		{
			Index = 3,
			Name = "The Deadmines",
			Abbreviation = "Deadmines",
			Identifiers = {
				EN = {
					"deadm",
					"de[a]?d[%W]*mine[s]?",
					"de[a]?th[%W]*mine[s]?",
					"vc",
					"van[%W]*cle[e]?f",
				},
				DE = {
					-- Die Todesminen
					"tode[s]?[%W]*mine[n]?",
				},
				FR = {
					-- Les Mortemines
					"morte[%W]*mine[s]?",
					"mm",
				},
				ES = {
					-- Las Minas de la Muerte
					"mina[s]?[%W]*[d]?[e]?[%W]*[l]?[a]?[%W]*muerte",
					"minas",
				},
				RU = {},
			},
			Size = 5,
			MinLevel = 18,
			MaxLevel = 23,
		},
		{
			Index = 4,
			Name = "Shadowfang Keep",
			Abbreviation = "SFK",
			Identifiers = {
				EN = { 
					"shadow[%W]*fang[%W]*ke[e]?p",
					"shadow[%W]*fang",
					"sfk",
					"sk",
				},
				DE = {
					-- Burg Schattenfang / Burg Shadowfang
					"burg[%W]*schat[t]?en[%W]*fang",
					"burg[%W]*shadow[%W]*fang",
					"schat[t]?en[%W]*fang",
					"bsf",
				},
				FR = {
					-- Donjon d'Ombrecroc
					"donjon[%W]*[d]?[%W]*ombrecroc",
					"ombrecroc",
				},
				ES = {
					-- Castillo de colmillo oscuro
					"castil[l]?o[%W]*[d]?[e]?[%W]*colmil[l]?o[%W]*oscuro",
					"colmil[l]?o[%W]*oscuro",
				},
				RU = {},
			},
			Size = 5,
			MinLevel = 22,
			MaxLevel = 30,
		},
		{
			Index = 5,
			Name = "Blackfathom Deeps",
			Abbreviation = "BFD",
			Identifiers = {
				EN = { 
					"black[%W]*fat[h]?om[%W]*de[e]?p[t]?[h]?[s]?",
					"black[%W]*fat[h]?om",
					"bfd",
				},
				DE = {
					-- Tiefschwarze Grotte / Die Blackfathomtiefen
					"tiefschwarze[%W]*grot[t]?e",
					"blackfathom[%W]*tiefe[n]?",
					"bft[d]?",
				},
				FR = {
					-- Profondeurs de Brassenoire
					"profondeurs[%W]*[d]?[e]?[%W]*bras[s]?[e]?noir[e]?",
					"bras[s]?[e]?noir[e]?"
				},
				ES = {
					-- Cavernas de Brazanegra
					"caverna[s]?[%W]*[d]?[e]?[%W]*brazanegra",
					"brazanegra",
				},
				RU = {},
			},
			Size = 5,
			MinLevel = 24,
			MaxLevel = 32,
		},
		{
			Index = 6,
			Name = "Stormwind Stockade",
			Abbreviation = "Stockades",
			Identifiers = {
				EN = { 
					"stockade[s]?",
					"stock[s]?",
				},
				DE = {
					-- Das Verlies
					"verl[e]?i[e]?s",
				},
				FR = {
					-- La Prison
					"prison[s]?",
				},
				ES = {
					-- Las Mazmorras
					"mazmor[r]?as",
				},
				RU = {},
			},
			Size = 5,
			MinLevel = 22,
			MaxLevel = 30,
		},
		{
			Index = 7,
			Name = "Scarlet Monastery",
			Abbreviation = "SM",
			Identifiers = {
				EN = {
					"scarlet[%W]*mon[e]?[a]?st[e]?[a]?ry",
					"sm",
				},
				DE = {
					-- Das Scharlachrote Kloster
					"kloster",
				},
				FR = {
					-- Monastère Écarlate
					"monastere[%W*]ecarlate",
					"mona[s]?[t]?[e]?[r]?[e]?",
				},
				ES = {
					-- Monasterio Escarlata
					"monasterio[%W]*escarlata",
					"monasterio",
					"escarlata",
				},
				RU = {},
			},
			NotIdentifiers = {
				DE = {
					"st[a]?rat[h]?[o]?[l]?[m]?[e]?.-[%W]+kloster[%W]*[t]?[e]?[i]?[l]?",
					"sta[r]?th[o]?[l]?[m]?[e]?.-[%W]+kloster[%W]*[t]?[e]?[i]?[l]?",
					"straht[h]?[o]?[l]?[m]?[e]?.-[%W]+kloster[%W]*[t]?[e]?[i]?[l]?",
					"sta[r]?t[%W]*kloster[%W]*[t]?[e]?[i]?[l]?",
					"stra[%W]*kloster[%W]*[t]?[e]?[i]?[l]?",
				},
			},
			SubDungeons = { 8, 9, 10, 11 },
			Size = 5,
			MinLevel = 28,
			MaxLevel = 45
		},
		{
			Index = 8,
			Name = "Scarlet Monastery - Graveyard",
			Abbreviation = "SM GY",
			Identifiers = {
				EN = {
					"smg[r]?[a]?[v]?[e]?y[e]?[a]?[r]?[d]?",
					"g[r]?[a]?[v]?[e]?y[e]?[a]?[r]?[d]?",
				},
				DE = {
					-- Friedhof
					"smf[r]?[i]?[e]?[d]?h[o]?[f]?",
					"klosterf[r]?[i]?[e]?[d]?h[o]?[f]?",
					"f[r]?[i]?[e]?[d]?h[o]?[f]?",
				},
				FR = {
					-- Cimetière
					"smcim[e]?[t]?[i]?[e]?[r]?[e]?",
					"mona[s]?[t]?[e]?[r]?[e]?cim[e]?[t]?[i]?[e]?[r]?[e]?",
					"cim[e]?[t]?[i]?[e]?[r]?[e]?",
				},
				ES = {
					-- Cementerio
					"smcementerio",
					"monasteriocementerio",
					"escarlatacementerio",
					"cementerio",
				},
				RU = {},
			},
			NotIdentifiers = {
				EN = {
					"zul[l]?g[r]?[a]?[v]?[e]?y[e]?[a]?[r]?[d]?",
					"zfkg[r]?[a]?[v]?[e]?y[e]?[a]?[r]?[d]?",
					"zfg[r]?[a]?[v]?[e]?y[e]?[a]?[r]?[d]?",
					"zul.-[%W]+g[r]?[a]?[v]?[e]?y[e]?[a]?[r]?[d]?",
					"zfk.-[%W]+g[r]?[a]?[v]?[e]?y[e]?[a]?[r]?[d]?",
					"zf.-[%W]+g[r]?[a]?[v]?[e]?y[e]?[a]?[r]?[d]?",
				},
				DE = {
					"zul[l]?f[r]?[i]?[e]?[d]?h[o]?[f]?",
					"zfkf[r]?[i]?[e]?[d]?h[o]?[f]?",
					"zff[r]?[i]?[e]?[d]?h[o]?[f]?",
					"zul.-[%W]+f[r]?[i]?[e]?[d]?h[o]?[f]?",
					"zfk.-[%W]+f[r]?[i]?[e]?[d]?h[o]?[f]?",
					"zf.-[%W]+f[r]?[i]?[e]?[d]?h[o]?[f]?",
				},
				FR = {
					"zul[l]?cim[e]?[t]?[i]?[e]?[r]?[e]?",
					"zfkcim[e]?[t]?[i]?[e]?[r]?[e]?",
					"zfcim[e]?[t]?[i]?[e]?[r]?[e]?",
					"zul.-[%W]+cim[e]?[t]?[i]?[e]?[r]?[e]?",
					"zfk.-[%W]+cim[e]?[t]?[i]?[e]?[r]?[e]?",
					"zf.-[%W]+cim[e]?[t]?[i]?[e]?[r]?[e]?",
				},
				ES = {
					"zul[l]?cementerio",
					"zfkcementerio",
					"zfcementerio",
					"zul.-[%W]+cementerio",
					"zfk.-[%W]+cementerio",
					"zf.-[%W]+cementerio",
				},
			},
			ParentDungeon = 7,
			Size = 5,
			MinLevel = 28,
			MaxLevel = 38
		},
		{
			Index = 9,
			Name = "Scarlet Monastery - Library",
			Abbreviation = "SM LIB",
			Identifiers = {
				EN = { 
					"smlib[r]?[a]?[r]?[y]?",
					"lib[r]?[a]?[r]?[y]?",
				},
				DE = {
					-- Bibliothek
					"smbib[li]?[i]?[o]?[t]?[h]?[e]?[k]?",
					"klosterbib[li]?[i]?[o]?[t]?[h]?[e]?[k]?",
					"bib[li]?[i]?[o]?[t]?[h]?[e]?[k]?",
				},
				FR = {
					-- Bibliothèque
					"smb[l]?ibli[o]?[t]?[h]?[e]?[q]?[u]?[e]?",
					"mona[s]?[t]?[e]?[r]?[e]?b[l]?ibli[o]?[t]?[h]?[e]?[q]?[u]?[e]?",
					"b[l]?ibli[o]?[t]?[h]?[e]?[q]?[u]?[e]?",
				},
				ES = {
					-- Biblioteca / Libreria
					"smb[l]?ibli[o]?[t]?[e]?[c]?[a]?",
					"smlib[r]?[e]?[r]?[i]?[a]?",
					"monasteriob[l]?ibli[o]?[t]?[e]?[c]?[a]?",
					"monasteriolib[r]?[e]?[r]?[i]?[a]?",
					"escarlatab[l]?ibli[o]?[t]?[e]?[c]?[a]?",
					"escarlatalib[r]?[e]?[r]?[i]?[a]?",
					"b[l]?ibli[o]?[t]?[e]?[c]?[a]?",
					"lib[r]?[e]?[r]?[i]?[a]?",
				},
				RU = {},
			},
			ParentDungeon = 7,
			Size = 5,
			MinLevel = 29,
			MaxLevel = 39
		},
		{
			Index = 10,
			Name = "Scarlet Monastery - Armory",
			Abbreviation = "SM ARM",
			Identifiers = {
				EN = {
					"smarmo[u]?ry",
					"smarm[o]?ury",
					"smarm[s]?",
					"armo[u]?ry",
					"arm[o]?ury",
					"arm[s]?",
				},
				DE = {
					-- Waffenkammer
					"smw[a]?[f]?[f]?[e]?[n]?k[a]?[m]?[m]?[e]?[r]?",
					"klosterw[a]?[f]?[f]?[e]?[n]?k[a]?[m]?[m]?[e]?[r]?",
					"w[a]?[f]?[f]?[e]?[n]?k[a]?[m]?[m]?[e]?[r]?",
				},
				FR = {
					-- Armurerie
					"smarmu[r]?[e]?[r]?[i]?[e]?",
					"mona[s]?[t]?[e]?[r]?[e]?armu[r]?[e]?[r]?[i]?[e]?",
					"armu[r]?[e]?[r]?[i]?[e]?",
				},
				ES = {
					-- Arsenal / Armeria
					"smarsenal",
					"smarmeria",
					"monasterioarsenal",
					"monasterioarmeria",
					"escarlataarsenal",
					"escarlataarmeria",
					"arsenal",
					"armeria",
				},
				RU = {},
			},
			ParentDungeon = 7,
			Size = 5,
			MinLevel = 32,
			MaxLevel = 42
		},
		{
			Index = 11,
			Name = "Scarlet Monastery - Cathedral",
			Abbreviation = "SM CATH",
			Identifiers = {
				EN = {
					"smcat[h]?[e]?[d]?[r]?[a]?[l]?",
					"sm.-[%W]+cat[h]?[e]?[d]?[r]?[a]?[l]?",
					"cath[e]?[d]?[r]?[a]?[l]?",
				},
				DE = {
					-- Kathedrale
					"smkathe[d]?[r]?[a]?[l]?[e]?",
					"klosterkathe[d]?[r]?[a]?[l]?[e]?",
					"kathe[d]?[r]?[a]?[l]?[e]?",
				},
				FR = {
					-- Cathédrale
					"smcathe[d]?[r]?[a]?[l]?[e]?",
					"mona[s]?[t]?[e]?[r]?[e]?cathe[d]?[r]?[a]?[l]?[e]?",
					"cathe[d]?[r]?[a]?[l]?[e]?",
				},
				ES = {
					-- Catedral
					"smcatedral",
					"monasteriocatedral",
					"escarlatacatedral",
					"catedral",
				},
				RU = {},
			},
			ParentDungeon = 7,
			Size = 5,
			MinLevel = 35,
			MaxLevel = 45
		},
		{
			Index = 12,
			Name = "Gnomeregan",
			Abbreviation = "Gnomeregan",
			Identifiers = {
				EN = {
					"g[e]?no[r]?m[e]?[r]?[e]?[a]?g[e]?[r]?an",
					"g[e]?nome[r]?",
				},
				DE = {},
				FR = {},
				ES = {},
				RU = {},
			},
			Size = 5,
			MinLevel = 29,
			MaxLevel = 38,
		},
		{
			Index = 13,
			Name = "Razorfen Kraul",
			Abbreviation = "RFK",
			Identifiers = {
				EN = {
					"razo[rn]?[%W]*fen[%W]*kraul",
					"rfk",
				},
				DE = {
					-- Kral der Klingenhauer / Der Kral von Razorfen
					"kra[a]?l",
				},
				FR = {
					-- Kraal de Tranchebauge
					"kra[a]?[lk]",
					"krall",
				},
				ES = {
					-- Horado Rajacieno
					"horado",
				},
				RU = {},
			},
			Size = 5,
			MinLevel = 30,
			MaxLevel = 40,
		},
		{
			Index = 14,
			Name = "Razorfen Downs",
			Abbreviation = "RFD",
			Identifiers = {
				EN = {
					"razo[rn]?[%W]*fen[%W]*down[s]?",
					"rfd",
				},
				DE = {
					-- Hügel der Klingenhauer / Die Hügel von Razorfen
					"hu[e]?gel",
				},
				FR = {
					-- Souilles de Tranchebauge
					"souil[l]?e[s]?",
				},
				ES = {
					-- Zahúrda Rojocieno
					"zahurda",
					"rfsd",
				},
				RU = {},
			},
			Size = 5,
			MinLevel = 40,
			MaxLevel = 50,
		},
		{
			Index = 15,
			Name = "Uldaman",
			Abbreviation = "Uldaman",
			Identifiers = {
				EN = {
					"uldaman",
					"uld[ua]?",
				},
				DE = {},
				FR = {},
				ES = {},
				RU = {},
			},
			Size = 5,
			MinLevel = 42,
			MaxLevel = 52,
		},
		{
			Index = 16,
			Name = "Zul'Farrak",
			Abbreviation = "ZF",
			Identifiers = {
				EN = {
					"zul[l]?[%W]*far[r]?ak[k]?",
					"zul[l]?",
					"zfk",
					"zf",
				},
				DE = {},
				FR = {},
				ES = {},
				RU = {},
			},
			NotIdentifiers = {
				EN = {
					"zul[l]?[%W]*g[u]?rub",
				}
			},
			Size = 5,
			MinLevel = 44,
			MaxLevel = 54,
		},
		{
			Index = 17,
			Name = "Maraudon",
			Abbreviation = "Mara",
			Identifiers = {
				EN = {
					"ma[r]?[u]?ra[u]?[d]?[ou]?[ou]?[n]?",
				},
				DE = {},
				FR = {},
				ES = {},
				RU = {},
			},
			SubDungeons = { 18, 19, 20 },
			Size = 5,
			MinLevel = 45,
			MaxLevel = 57
		},
		{
			Index = 18,
			Name = "Maraudon - Orange",
			Abbreviation = "Mara Orange",
			Identifiers = {
				EN = {
					"ma[r]?[u]?ra[u]?[d]?[ou]?[ou]?[n]?.-[%W]+orange",
				},
				DE = {
					-- Orangene
					"ma[r]?[u]?ra[u]?[d]?[ou]?[ou]?[n]?.-[%W]+orangene",
				},
				FR = {
					-- Oranges
					"ma[r]?[u]?ra[u]?[d]?[ou]?[ou]?[n]?.-[%W]+oranges",
				},
				ES = {
					-- Naranja
					"ma[r]?[u]?ra[u]?[d]?[ou]?[ou]?[n]?.-[%W]+naranja",
				},
				RU = {},
			},
			ParentDungeon = 17,
			Size = 5,
			MinLevel = 45,
			MaxLevel = 54
		},
		{
			Index = 19,
			Name = "Maraudon - Purple",
			Abbreviation = "Mara Purple",
			Identifiers = {
				EN = {
					"ma[r]?[u]?ra[u]?[d]?[ou]?[ou]?[n]?.-[%W]+purple",
				},
				DE = {
					-- Violette
					"ma[r]?[u]?ra[u]?[d]?[ou]?[ou]?[n]?.-[%W]+violet[t]?e",
				},
				FR = {
					-- Violet
					"ma[r]?[u]?ra[u]?[d]?[ou]?[ou]?[n]?.-[%W]+violet",
				},
				ES = {
					-- Púrpura
					"ma[r]?[u]?ra[u]?[d]?[ou]?[ou]?[n]?.-[%W]+purpura",
				},
				RU = {},
			},
			ParentDungeon = 17,
			Size = 5,
			MinLevel = 45,
			MaxLevel = 53
		},
		{
			Index = 20,
			Name = "Maraudon - Inner",
			Abbreviation = "Mara Inner",
			Identifiers = {
				EN = {
					"ma[r]?[u]?ra[u]?[d]?[ou]?[ou]?[n]?.-[%W]+inner",
					"ma[r]?[u]?ra[u]?[d]?[ou]?[ou]?[n]?.-[%W]+princes[s]?",
					"earth[%W]*song[%W]*fal[l]?s",
				},
				DE = {
					-- Prinzessinnen / ?
					"ma[r]?[u]?ra[u]?[d]?[ou]?[ou]?[n]?.-[%W]+prin[cz]es[s]?[i]?[n]?[n]?[e]?[n]?",
				},
				FR = {
					-- Princesse / Chutes de Chanteterre
					"ma[r]?[u]?ra[u]?[d]?[ou]?[ou]?[n]?.-[%W]+princes[s]?[e]?",
					"chutes[%W]*[d]?[e]?[%W]*chanteter[r]?e",
				},
				ES = {
					-- Princesa / ?
					"ma[r]?[u]?ra[u]?[d]?[ou]?[ou]?[n]?.-[%W]+princes[s]?[a]?",
				},
				RU = {},
			},
			NotIdentifiers = {
				EN = {
					"ma[r]?[u]?ra[u]?[d]?[ou]?[ou]?[n]?.-[%W]+black[%W]*rock[%W]*dep[t]?[h]?s.-[%W]+princes[s]?",
					"ma[r]?[u]?ra[u]?[d]?[ou]?[ou]?[n]?.-[%W]+brd.-[%W]+princes[s]?",
				}
			},
			ParentDungeon = 17,
			Size = 5,
			MinLevel = 48,
			MaxLevel = 57
		},
		{
			Index = 21,
			Name = "Temple of Atal'Hakkar",
			Abbreviation = "ST",
			Identifiers = {
				EN = {
					"atal[%W]*hak[k]?ar",
					"sunk[t]?[e]?[n]?[%W]*temp[l]?e[l]?",
					"sunk[t]?en",
					"tempel",
					"temple",
					"st",
				},
				DE = {
					-- Der Tempel von Atal'Hakkar / Der versunkene Tempel
					"[v]?[e]?[r]?sunken[e]?",
				},
				FR = {
					-- Le Temple'd Atal'Hakkar / Le Temple englouti
					"englouti",
					"templs",
				},
				ES = {
					-- El Templo de Atal'hakkar / Templo sumergido
					"sumergido",
					"templo",
				},
				RU = {},
			},
			NotIdentifiers = {
				EN = {
					"[%d][%d][%W]*[%d][%d][%W]*st",
					"am[%W]*st",
					"pm[%W]*st",
					"temple[%W]*[o]?[f]?[%W]*ahn[%W]*qiraj",
					"ahn[%W]*qiraj[%W]*temple",
					"aq[%W]*temple",
				},
			},
			Size = 5,
			MinLevel = 50,
			MaxLevel = 60,
		},
		{
			Index = 22,
			Name = "Blackrock Depths",
			Abbreviation = "BRD",
			Identifiers = {
				EN = {
					"black[%W]*rock[%W]*dep[t]?[h]?s",
					"brd",
				},
				DE = {
					-- Blackrocktiefen / Schwarzfelstiefen
					"schwarz[%W]*fels[%W]*tiefe[n]?",
					"black[%W]*rock[%W]*tiefe[n]?",
					"brt",
				},
				FR = {
					-- Profondeurs de Blackrock
					"profondeurs[%W]*[d]?[e]?[%W]*blackrock",
					"brd[x]?[%d]",
				},
				ES = {
					-- Profundidades de Roca Negra
					"profundidades[%W]*[d]?[e]?[%W]*roca[%W]*negra",
				},
				RU = {},
			},
			SubDungeons = { 23, 24, 25, 26, 27, 28, 29, 30, 31, 32 },
			Size = 5,
			MinLevel = 52,
			MaxLevel = 60
		},
		{
			Index = 23,
			Name = "Blackrock Depths - Quest Run",
			Abbreviation = "BRD Quest Run",
			Identifiers = {
				EN = {
					"black[%W]*rock[%W]*dep[t]?[h]?s.-[%W]+quest[s]?",
					"black[%W]*rock[%W]*dep[t]?[h]?s.-[%W]+questrun[s]?",
					"brd.-[%W]+quest[s]?",
					"brd.-[%W]+questrun[s]?",
					"quest[s]?.-at[t]?un[e]?ment",
					"quest[s]?.-arena",
					"quest[s]?.-anger[f]?[g]?[o]?[r]?[g]?[e]?",
					"quest[s]?.-golem",
					"quest[s]?.-prison",
					"quest[s]?.-vault",
					"quest[s]?.-lava",
					"quest[s]?.-emp[r]?[e]?[r]?[o]?[r]?",
					"at[t]?un[e]?ment.-quest[s]?",
					"arena.-quest[s]?",
					"anger[f]?[g]?[o]?[r]?[g]?[e]?.-quest[s]?",
					"golem.-quest[s]?",
					"prison.-quest[s]?",
					"vault.-quest[s]?",
					"lava.-quest[s]?",
					"emp[r]?[e]?[r]?[o]?[r]?.-quest[s]?",
				},
				DE = {
					"schwarz[%W]*fels[%W]*tiefe[n]?.-[%W]+quest[s]?",
					"black[%W]*rock[%W]*tiefe[n]?.-[%W]+quest[s]?",
					"brt.-[%W]+quest[s]?",
				},
				FR = {},
				ES = {},
				RU = {},
			},
			ParentDungeon = 22,
			Size = 5,
			MinLevel = 52,
			MaxLevel = 60,
		},
		{
			Index = 24,
			Name = "Blackrock Depths - Attunement Run",
			Abbreviation = "BRD Attunement Run",
			Identifiers = {
				EN = {
					"black[%W]*rock[%W]*dep[t]?[h]?s.-[%W]+at[t]?un[e]?ment",
					"brd.-[%W]+at[t]?un[e]?ment",
					"brd.-[%W]+win[d]?sor",
					"at[t]?un[e]?ment.-quest[s]?",
					"at[t]?un[e]?ment.-arena",
					"at[t]?un[e]?ment.-anger[f]?[g]?[o]?[r]?[g]?[e]?",
					"at[t]?un[e]?ment.-golem",
					"at[t]?un[e]?ment.-prison",
					"at[t]?un[e]?ment.-vault",
					"at[t]?un[e]?ment.-lava",
					"at[t]?un[e]?ment.-emp[r]?[e]?[r]?[o]?[r]?",
					"at[t]?un[e]?ment.-princes[s]?",
					"quest[s]?.-at[t]?un[e]?ment",
					"arena.-at[t]?un[e]?ment",
					"anger[f]?[g]?[o]?[r]?[g]?[e]?.-at[t]?un[e]?ment",
					"golem.-at[t]?un[e]?ment",
					"prison.-at[t]?un[e]?ment",
					"vault.-at[t]?un[e]?ment",
					"lava.-at[t]?un[e]?ment",
					"emp[r]?[e]?[r]?[o]?[r]?.-at[t]?un[e]?ment",
					"princes[s]?.-at[t]?un[e]?ment",
					"mar[r]?shal[l]?[%W]*win[d]?sor",
					"jail[%W]*br[e]?[a]?k[e]?",
					"at[t]?unement[%W]*to[%W]*the[%W]*core",
					"ony[i]?[x]?[iy]?[e]?[a]?[%W]*at[t]?un[e]?ment",
					"ony[i]?[x]?[iy]?[e]?[a]?[%W]*q[u]?[e]?[s]?[t]?[s]?",
					"ony[i]?[x]?[iy]?[e]?[a]?[%W]*pre[%W]*[q]?[u]?[e]?[s]?[t]?[s]?",
					"onix[iy][e]?[a]?[%W]*at[t]?un[e]?ment",
					"onix[iy][e]?[a]?[%W]*q[u]?[e]?[s]?[t]?[s]?",
					"onix[iy][e]?[a]?[%W]*pre[%W]*[q]?[u]?[e]?[s]?[t]?[s]?",
					"molten[%W]*core[%W]*at[t]?un[e]?ment",
					"mc[%W]*at[t]?un[e]?ment",
					"molten[%W]*core[%W]*pre[%W]*[q]?[u]?[e]?[s]?[t]?[s]?",
					"mc[%W]*pre[%W]*[q]?[u]?[e]?[s]?[t]?[s]?",
				},
				DE = {
					"schwarz[%W]*fels[%W]*tiefe[n]?.-[%W]+at[t]?un[e]?ment",
					"black[%W]*rock[%W]*tiefe[n]?.-[%W]+at[t]?un[e]?ment",
					"brt.-[%W]+at[t]?un[e]?ment",
				},
				FR = {},
				ES = {},
				RU = {},
			},
			ParentDungeon = 22,
			Size = 5,
			MinLevel = 52,
			MaxLevel = 60,
		},
		{
			Index = 25,
			Name = "Blackrock Depths - Arena Run",
			Abbreviation = "BRD Arena Run",
			Identifiers = {
				EN = {
					"black[%W]*rock[%W]*dep[t]?[h]?s.-[%W]+arena",
					"brd.-[%W]+arena",
					"arena[%W]*run[s]?",
					"arena[%W]*farm",
					"farm[%W]*arena",
					"arena.-quest[s]?",
					"arena.-at[t]?un[e]?ment",
					"arena.-anger[f]?[g]?[o]?[r]?[g]?[e]?",
					"arena.-golem",
					"arena.-prison",
					"arena.-vault",
					"arena.-lava",
					"arena.-emp[r]?[e]?[r]?[o]?[r]?",
					"arena.-princes[s]?",
					"quest[s]?.-arena",
					"at[t]?un[e]?ment.-arena",
					"anger[f]?[g]?[o]?[r]?[g]?[e]?.-arena",
					"golem.-arena",
					"prison.-arena",
					"vault.-arena",
					"lava.-arena",
					"emp[r]?[e]?[r]?[o]?[r]?.-arena",
					"princes[s]?.-arena",
				},
				DE = {
					"schwarz[%W]*fels[%W]*tiefe[n]?.-[%W]+arena",
					"black[%W]*rock[%W]*tiefe[n]?.-[%W]+arena",
					"brt.-[%W]+arena",
				},
				FR = {
					-- Arène
					"black[%W]*rock[%W]*dep[t]?[h]?s.-[%W]+arene",
					"brd.-[%W]+arene",
					"arene.-[%W]+brd[x]?[%d]?",
				},
				ES = {
					-- Arenas
					"black[%W]*rock[%W]*dep[t]?[h]?s.-[%W]+arenas",
					"brd.-[%W]+arenas",
					"arena[s]?.-[%W]+brd",
				},
				RU = {},
			},
			ParentDungeon = 22,
			Size = 5,
			MinLevel = 52,
			MaxLevel = 60,
		},
		{
			Index = 26,
			Name = "Blackrock Depths - Angerforge Run",
			Abbreviation = "BRD Angerforge Run",
			Identifiers = {
				EN = {
					"black[%W]*rock[%W]*dep[t]?[h]?s.-[%W]+anger[f]?[g]?[o]?[r]?[g]?[e]?",
					"brd.-[%W]+anger[f]?[g]?[o]?[r]?[g]?[e]?",
					"anger[f]?[g]?[o]?[r]?[g]?[e]?[%W]*run[s]?",
					"anger[f]?[g]?[o]?[r]?[g]?[e]?.-quest[s]?",
					"anger[f]?[g]?[o]?[r]?[g]?[e]?.-at[t]?un[e]?ment",
					"anger[f]?[g]?[o]?[r]?[g]?[e]?.-arena",
					"anger[f]?[g]?[o]?[r]?[g]?[e]?.-golem",
					"anger[f]?[g]?[o]?[r]?[g]?[e]?.-prison",
					"anger[f]?[g]?[o]?[r]?[g]?[e]?.-vault",
					"anger[f]?[g]?[o]?[r]?[g]?[e]?.-lava",
					"anger[f]?[g]?[o]?[r]?[g]?[e]?.-emp[r]?[e]?[r]?[o]?[r]?",
					"anger[f]?[g]?[o]?[r]?[g]?[e]?.-princes[s]?",
					"quest[s]?.-anger[f]?[g]?[o]?[r]?[g]?[e]?",
					"at[t]?un[e]?ment.-anger[f]?[g]?[o]?[r]?[g]?[e]?",
					"arena.-anger[f]?[g]?[o]?[r]?[g]?[e]?",
					"golem.-anger[f]?[g]?[o]?[r]?[g]?[e]?",
					"prison.-anger[f]?[g]?[o]?[r]?[g]?[e]?",
					"vault.-anger[f]?[g]?[o]?[r]?[g]?[e]?",
					"lava.-anger[f]?[g]?[o]?[r]?[g]?[e]?",
					"emp[r]?[e]?[r]?[o]?[r]?.-anger[f]?[g]?[o]?[r]?[g]?[e]?",
					"princes[s]?.-anger[f]?[g]?[o]?[r]?[g]?[e]?",
				},
				DE = {
					-- General
					"black[%W]*rock[%W]*dep[t]?[h]?s.-[%W]+general",
					"brd.-[%W]+general",
					"schwarz[%W]*fels[%W]*tiefe[n]?.-[%W]+anger[f]?[g]?[o]?[r]?[g]?[e]?",
					"black[%W]*rock[%W]*tiefe[n]?.-[%W]+anger[f]?[g]?[o]?[r]?[g]?[e]?",
					"brt.-[%W]+anger[f]?[g]?[o]?[r]?[g]?[e]?",
					"schwarz[%W]*fels[%W]*tiefe[n]?.-[%W]+general",
					"black[%W]*rock[%W]*tiefe[n]?.-[%W]+general",
					"brt.-[%W]+general",
				},
				FR = {
					-- Forgehargne / General
					"black[%W]*rock[%W]*dep[t]?[h]?s.-[%W]+forge[h]?[a]?[r]?[g]?[n]?[e]?",
					"black[%W]*rock[%W]*dep[t]?[h]?s.-[%W]+general",
					"brd.-[%W]+forge[h]?[a]?[r]?[g]?[n]?[e]?",
					"brd.-[%W]*general",
					"forge[h]?[a]?[r]?[g]?[n]?[e]?.-[%W]+brd",
					"general.-[%W]+brd",
				},
				ES = {
					-- General
					"black[%W]*rock[%W]*dep[t]?[h]?s.-[%W]+general",
					"brd.-[%W]*general",
					"general.-[%W]*brd",
				},
				RU = {},
			},
			ParentDungeon = 22,
			Size = 5,
			MinLevel = 52,
			MaxLevel = 60,
		},
		{
			Index = 27,
			Name = "Blackrock Depths - Golem Run",
			Abbreviation = "BRD Golem Run",
			Identifiers = {
				EN = {
					"black[%W]*rock[%W]*dep[t]?[h]?s.-[%W]+golem[l]?[o]?[r]?[d]?",
					"brd.-[%W]+golem[l]?[o]?[r]?[d]?",
					"golem[l]?[o]?[r]?[d]?[%W]*run[s]?",
					"golem[l]?[o]?[r]?[d]?.-quest[s]?",
					"golem[l]?[o]?[r]?[d]?.-at[t]?un[e]?ment",
					"golem[l]?[o]?[r]?[d]?.-anger[f]?[g]?[o]?[r]?[g]?[e]?",
					"golem[l]?[o]?[r]?[d]?.-arena",
					"golem[l]?[o]?[r]?[d]?.-prison",
					"golem[l]?[o]?[r]?[d]?.-vault",
					"golem[l]?[o]?[r]?[d]?.-lava",
					"golem[l]?[o]?[r]?[d]?.-emp[r]?[e]?[r]?[o]?[r]?",
					"golem[l]?[o]?[r]?[d]?.-princes[s]?",
					"quest[s]?.-golem[l]?[o]?[r]?[d]?",
					"at[t]?un[e]?ment.-golem[l]?[o]?[r]?[d]?",
					"arena.-golem[l]?[o]?[r]?[d]?",
					"anger[f]?[g]?[o]?[r]?[g]?[e]?.-golem[l]?[o]?[r]?[d]?",
					"prison.-golem[l]?[o]?[r]?[d]?",
					"vault.-golem[l]?[o]?[r]?[d]?",
					"lava.-golem[l]?[o]?[r]?[d]?",
					"emp[r]?[e]?[r]?[o]?[r]?.-golem[l]?[o]?[r]?[d]?",
					"princes[s]?.-golem[l]?[o]?[r]?[d]?",
				},
				DE = {
					-- Golemlord
					"schwarz[%W]*fels[%W]*tiefe[n]?.-[%W]+golem[l]?[o]?[r]?[d]?",
					"black[%W]*rock[%W]*tiefe[n]?.-[%W]+golem[l]?[o]?[r]?[d]?",
					"brt.-[%W]+golem[l]?[o]?[r]?[d]?",
				},
				FR = {},
				ES = {},
				RU = {},
			},
			ParentDungeon = 22,
			Size = 5,
			MinLevel = 52,
			MaxLevel = 60,
		},
		{
			Index = 28,
			Name = "Blackrock Depths - Prison Run",
			Abbreviation = "BRD Prison Run",
			Identifiers = {
				EN = {
					"black[%W]*rock[%W]*dep[t]?[h]?s.-[%W]+prison",
					"brd.-[%W]+prison",
					"prison[%W]*run[s]?",
					"prison.-quest[s]?",
					"prison.-at[t]?un[e]?ment",
					"prison.-arena",
					"prison.-anger[f]?[g]?[o]?[r]?[g]?[e]?",
					"prison.-golem",
					"prison.-vault",
					"prison.-lava",
					"prison.-emp[r]?[e]?[r]?[o]?[r]?",
					"prison.-princes[s]?",
					"quest[s]?.-prison",
					"at[t]?un[e]?ment.-prison",
					"arena.-prison",
					"anger[f]?[g]?[o]?[r]?[g]?[e]?.-prison",
					"golem.-prison",
					"vault.-prison",
					"lava.-prison",
					"emp[r]?[e]?[r]?[o]?[r]?.-prison",
					"princes[s]?.-prison",
				},
				DE = {
					"schwarz[%W]*fels[%W]*tiefe[n]?.-[%W]+prison",
					"black[%W]*rock[%W]*tiefe[n]?.-[%W]+prison",
					"brt.-[%W]+prison",
				},
				FR = {},
				ES = {},
				RU = {},
			},
			ParentDungeon = 22,
			Size = 5,
			MinLevel = 52,
			MaxLevel = 60,
		},
		{
			Index = 29,
			Name = "Blackrock Depths - Vault Run",
			Abbreviation = "BRD Vault Run",
			Identifiers = {
				EN = {
					"black[%W]*rock[%W]*dep[t]?[h]?s.-[%W]+vault",
					"brd.-[%W]+vault",
					"vault[%W]*run[s]?",
					"vault.-quest[s]?",
					"vault.-at[t]?un[e]?ment",
					"vault.-arena",
					"vault.-anger[f]?[g]?[o]?[r]?[g]?[e]?",
					"vault.-golem",
					"vault.-prison",
					"vault.-lava",
					"vault.-emp[r]?[e]?[r]?[o]?[r]?",
					"vault.-princes[s]?",
					"quest[s]?.-vault",
					"at[t]?un[e]?ment.-vault",
					"arena.-vault",
					"anger[f]?[g]?[o]?[r]?[g]?[e]?.-vault",
					"golem.-vault",
					"prison.-vault",
					"lava.-vault",
					"emp[r]?[e]?[r]?[o]?[r]?.-vault",
					"princes[s]?.-vault",
				},
				DE = {
					"schwarz[%W]*fels[%W]*tiefe[n]?.-[%W]+vault",
					"black[%W]*rock[%W]*tiefe[n]?.-[%W]+vault",
					"brt.-[%W]+vault",
				},
				FR = {},
				ES = {},
				RU = {},
			},
			ParentDungeon = 22,
			Size = 5,
			MinLevel = 52,
			MaxLevel = 60,
		},
		{
			Index = 30,
			Name = "Blackrock Depths - Lava Run",
			Abbreviation = "BRD Lava Run",
			Identifiers = {
				EN = {
					"black[%W]*rock[%W]*dep[t]?[h]?s.-[%W]+lava",
					"brd.-[%W]+lava",
					"lava[%W]*run[s]?",
					"lava.-quest[s]?",
					"lava.-at[t]?un[e]?ment",
					"lava.-arena",
					"lava.-anger[f]?[g]?[o]?[r]?[g]?[e]?",
					"lava.-golem",
					"lava.-prison",
					"lava.-vault",
					"lava.-emp[r]?[e]?[r]?[o]?[r]?",
					"lava.-princes[s]?",
					"quest[s]?.-lava",
					"at[t]?un[e]?ment.-lava",
					"arena.-lava",
					"anger[f]?[g]?[o]?[r]?[g]?[e]?.-lava",
					"golem.-lava",
					"prison.-lava",
					"vault.-lava",
					"emp[r]?[e]?[r]?[o]?[r]?.-lava",
					"princes[s]?.-lava",
				},
				DE = {
					"schwarz[%W]*fels[%W]*tiefe[n]?.-[%W]+lava",
					"black[%W]*rock[%W]*tiefe[n]?.-[%W]+lava",
					"brt.-[%W]+lava",
				},
				FR = {},
				ES = {},
				RU = {},
			},
			ParentDungeon = 22,
			Size = 5,
			MinLevel = 52,
			MaxLevel = 60,
		},
		{
			Index = 31,
			Name = "Blackrock Depths - Emperor Run",
			Abbreviation = "BRD Emperor Run",
			Identifiers = {
				EN = {
					"black[%W]*rock[%W]*dep[t]?[h]?s.-[%W]+emp[r]?[e]?[r]?[o]?[r]?",
					"brd.-[%W]+emp[r]?[e]?[r]?[o]?[r]?",
					"kill[i]?[n]?[g]?[%W]*[t]?[h]?[e]?[%W]*princes[s]?",
					"emp[r]?[e]?[r]?[o]?[r]?[%W]*run[s]?",
					"emp[r]?[e]?[r]?[o]?[r]?.-quest[s]?",
					"emp[r]?[e]?[r]?[o]?[r]?.-at[t]?un[e]?ment",
					"emp[r]?[e]?[r]?[o]?[r]?.-arena",
					"emp[r]?[e]?[r]?[o]?[r]?.-anger[f]?[g]?[o]?[r]?[g]?[e]?",
					"emp[r]?[e]?[r]?[o]?[r]?.-golem",
					"emp[r]?[e]?[r]?[o]?[r]?.-prison",
					"emp[r]?[e]?[r]?[o]?[r]?.-vault",
					"emp[r]?[e]?[r]?[o]?[r]?.-lava",
					"emp[r]?[e]?[r]?[o]?[r]?.-princes[s]?",
					"quest[s]?.-emp[r]?[e]?[r]?[o]?[r]?",
					"at[t]?un[e]?ment.-emp[r]?[e]?[r]?[o]?[r]?",
					"arena.-emp[r]?[e]?[r]?[o]?[r]?",
					"anger[f]?[g]?[o]?[r]?[g]?[e]?.-emp[r]?[e]?[r]?[o]?[r]?",
					"golem.-emp[r]?[e]?[r]?[o]?[r]?",
					"prison.-emp[r]?[e]?[r]?[o]?[r]?",
					"vault.-emp[r]?[e]?[r]?[o]?[r]?",
					"lava.-emp[r]?[e]?[r]?[o]?[r]?",
					"princes[s]?.-emp[r]?[e]?[r]?[o]?[r]?",
				},
				DE = {
					-- Imperator
					"black[%W]*rock[%W]*dep[t]?[h]?s.-[%W]+[ie]mp[e]?[r]?[a]?[t]?[o]?[r]?",
					"brd.-[%W]+[ie]mp[e]?[r]?[a]?[t]?[o]?[r]?",
					"schwarz[%W]*fels[%W]*tiefe[n]?.-[%W]+[ie]mp[e]?[r]?[a]?[t]?[o]?[r]?",
					"black[%W]*rock[%W]*tiefe[n]?.-[%W]+[ie]mp[e]?[r]?[a]?[t]?[o]?[r]?",
					"brt.-[%W]+[ie]mp[e]?[r]?[a]?[t]?[o]?[r]?",
					"[ie]mp[e]?[r]?[a]?[t]?[o]?[r]?[%W]*run[s]?",
					"kill[i]?[n]?[g]?[%W]*[d]?[a]?[s]?[%W]*prin[cz]es[s]?[i]?[n]?[n]?[e]?[n]?",
				},
				FR = {
					-- Empereur
					"black[%W]*rock[%W]*dep[t]?[h]?s.-[%W]+emp[e]?[r]?[e]?[u]?[r]?",
					"brd.-[%W]+emp[e]?[r]?[e]?[u]?[r]?",
					"emp[e]?[r]?[e]?[u]?[r]?[%W]*run[s]?",
					"kill[i]?[n]?[g]?[%W]*[l]?[a]?[%W]*princes[s]?e",
				},
				ES = {
					-- Emperador
					"black[%W]*rock[%W]*dep[t]?[h]?s.-[%W]+emp[e]?[r]?[a]?[d]?[o]?[r]?",
					"brd.-[%W]+emp[e]?[r]?[a]?[d]?[o]?[r]?",
					"emp[e]?[r]?[a]?[d]?[o]?[r]?.-[%W]+brd",
					"emp[e]?[r]?[a]?[d]?[o]?[r]?[%W]*run[s]?",
					"kill[i]?[n]?[g]?[%W]*[l]?[a]?[%W]*princes[s]?[a]?",
					"matar[%W]*[l]?[a]?[%W]*princes[s]?[a]?",
				},
				RU = {},
			},
			ParentDungeon = 22,
			Size = 5,
			MinLevel = 52,
			MaxLevel = 60,
		},
		{
			Index = 32,
			Name = "Blackrock Depths - Princess Run",
			Abbreviation = "BRD Princess Run",
			Identifiers = {
				EN = {
					"black[%W]*rock[%W]*dep[t]?[h]?s.-[%W]+princes[s]?",
					"brd.-[%W]+princes[s]?",
					"sav[e]?[i]?[n]?[g]?[%W]*[t]?[h]?[e]?[%W]*princes[s]?",
					"rescu[e]?[i]?[n]?[g]?[%W]*[t]?[h]?[e]?[%W]*princes[s]?",
					"princes[s]?.-at[t]?un[e]?ment",
					"princes[s]?.-arena",
					"princes[s]?.-anger[f]?[g]?[o]?[r]?[g]?[e]?",
					"princes[s]?.-golem",
					"princes[s]?.-prison",
					"princes[s]?.-vault",
					"princes[s]?.-lava",
					"princes[s]?.-emp[r]?[e]?[r]?[o]?[r]?",
					"at[t]?un[e]?ment.-princes[s]?",
					"arena.-princes[s]?",
					"anger[f]?[g]?[o]?[r]?[g]?[e]?.-princes[s]?",
					"golem.-princes[s]?",
					"prison.-princes[s]?",
					"vault.-princes[s]?",
					"lava.-princes[s]?",
					"emp[r]?[e]?[r]?[o]?[r]?.-princes[s]?",
				},
				DE = {
					-- Prinzessinnen
					"black[%W]*rock[%W]*dep[t]?[h]?s.-[%W]+prin[cz]es[s]?[i]?[n]?[n]?[e]?[n]?",
					"brd.-[%W]+prin[cz]es[s]?[i]?[n]?[n]?[e]?[n]?",
					"schwarz[%W]*fels[%W]*tiefe[n]?.-[%W]+prin[cz]es[s]?[i]?[n]?[n]?[e]?[n]?",
					"black[%W]*rock[%W]*tiefe[n]?.-[%W]+prin[cz]es[s]?[i]?[n]?[n]?[e]?[n]?",
					"brt.-prin[cz]es[s]?[i]?[n]?[n]?[e]?[n]?",
				},
				FR = {
					-- Princesse
					"black[%W]*rock[%W]*dep[t]?[h]?s.-[%W]+princes[s]?[e]?",
					"brd.-[%W]+princes[s]?[e]?",
					"princes[s]?[e]?.-[%W]+brd",
				},
				ES = {
					-- Princesa
					"black[%W]*rock[%W]*dep[t]?[h]?s.-[%W]+princes[s]?[a]?",
					"brd.-[%W]+princes[s]?[a]?",
					"princes[s]?[a]?.-[%W]+brd",
				},
				RU = {},
			},
			NotIdentifiers = {
				EN = {
					"kill[i]?[n]?[g]?[%W]*[t]?[h]?[e]?[%W]*princes[s]?",
					"black[%W]*rock[%W]*dep[t]?[h]?s.-[%W]+ma[r]?[u]?ra[u]?[d]?[ou]?[ou]?[n]?.-[%W]+princes[s]?",
					"brd.-[%W]+ma[r]?[u]?ra[u]?[d]?[ou]?[ou]?[n]?.-[%W]+princes[s]?",
				},
				DE = {
					"kill[i]?[n]?[g]?[%W]*[d]?[a]?[s]?[%W]*prin[cz]es[s]?[i]?[n]?[n]?[e]?[n]?",
				},
				FR = {
					"kill[i]?[n]?[g]?[%W]*[l]?[a]?[%W]*princes[s]?e",
				},
				ES = {
					"kill[i]?[n]?[g]?[%W]*[l]?[a]?[%W]*princes[s]?[a]?",
					"matar[%W]*[l]?[a]?[%W]*princes[s]?[a]?",
				},
			},
			ParentDungeon = 22,
			Size = 5,
			MinLevel = 52,
			MaxLevel = 60,
		},
		{
			Index = 33,
			Name = "Lower Blackrock Spire",
			Abbreviation = "LBRS",
			Identifiers = {
				EN = {
					"lower[%W]*black[%W]*rock[%W]*spire",
					"lower[%W]*brs",
					"lb[r]?s",
					"lrbs",
				},
				DE = {
					-- Untere Schwarzfelsspitze / Untere Blackrockspitze
					"untere[%W]*schwarzfel[s]?[%W]*spitze",
					"untere[%W]*black[%W]*rock[%W]*spitze",
					"untere[%W]*brs",
				},
				FR = {
					-- Bas du Pic de Rochenoire
					"bas[%W]*[d]?[u]?[%W]*pic[%W]*rochenoire",
				},
				ES = {
					-- Cumbres de Roca Negra inferior
					"cumbre[s]?[%W]*[d]?[e]?[%W]*roca[%W]*negra[%W]*inferior",
					"montando[%W]*lower",
					"lbrd",
				},
				RU = {},
			},
			Size = 5,
			MinLevel = 55,
			MaxLevel = 60,
		},
		{
			Index = 34,
			Name = "Upper Blackrock Spire",
			Abbreviation = "UBRS",
			Identifiers = {
				EN = {
					"up[p]?er[%W]*black[%W]*rock[%W]*spire",
					"up[p]?er[%W]*brs",
					"ub[r]?s",
					"urbs",
					"rend[%W]*run[s]?",
					"jed[%W]*run[s]?",
					"jed[%W]*rend",
					"rend[%W]*jed",
				},
				DE = {
					-- Obere Schwarzfelsspitze / Obere Blackrockspitze
					"obere[%W]*schwarzfel[s]?[%W]*spitze",
					"obere[%W]*black[%W]*rock[%W]*spitze",
					"obere[%W]*brs",
					"obrs",
				},
				FR = {
					-- Sommet du Pic de Rochenoire
					"sommet[%W]*[d]?[u]?[%W]*pic[%W]*rochenoire",
				},
				ES = {
					-- Cumbres de Roca Negra superior
					"cumbre[s]?[%W]*[d]?[e]?[%W]*roca[%W]*negra[%W]*superior",
					"montando[%W]*up[p]?er",
					"ubrd",
				},
				RU = {},
			},
			Size = 10,
			MinLevel = 58,
			MaxLevel = 60,
		},
		{
			Index = 35,
			Name = "Scholomance",
			Abbreviation = "Scholo",
			Identifiers = {
				EN = {
					"s[c]?[h]?ol[o]?[l]?[o]?man[c]?[s]?e",
					"sc[h]?olo",
					"s[c]?holo",
					"scho",
				},
				DE = {},
				FR = {},
				ES = {},
				RU = {},
			},
			Size = 5,
			MinLevel = 58,
			MaxLevel = 60,
		},
		{
			Index = 36,
			Name = "Stratholme",
			Abbreviation = "Strat",
			Identifiers = {
				EN = {
					"st[a]?rat[h]?[o]?[l]?[m]?[e]?",
					"sta[r]?th[o]?[l]?[m]?[e]?",
					"straht[h]?[o]?[l]?[m]?[e]?",
				},
				DE = {},
				FR = {},
				ES = {},
				RU = {},
			},
			SubDungeons = { 37, 38 },
			Size = 5,
			MinLevel = 58,
			MaxLevel = 60,
		},
		{
			Index = 37,
			Name = "Stratholme - Living Side",
			Abbreviation = "Strat Living",
			Identifiers = {
				EN = {
					"st[a]?rat[h]?[o]?[l]?[m]?[e]?[a]?liv[ei]?[n]?[g]?",
					"sta[r]?th[o]?[l]?[m]?[e]?[a]?liv[ei]?[n]?[g]?",
					"straht[h]?[o]?[l]?[m]?[e]?[a]?liv[ei]?[n]?[g]?",
					"st[a]?rat[h]?[o]?[l]?[m]?[e]?.-[%W]+[a]?liv[ei]?[n]?[g]?",
					"sta[r]?th[o]?[l]?[m]?[e]?.-[%W]+[a]?liv[ei]?[n]?[g]?",
					"straht[h]?[o]?[l]?[m]?[e]?.-[%W]+[a]?liv[ei]?[n]?[g]?",
					"sta[r]?t[%W]*[a]?liv[ei]?[n]?[g]?",
					"stra[%W]*[a]?liv[ei]?[n]?[g]?",
				},
				DE = {
					-- Klosterteil
					"st[a]?rat[h]?[o]?[l]?[m]?[e]?.-[%W]+kloster[%W]*[t]?[e]?[i]?[l]?",
					"sta[r]?th[o]?[l]?[m]?[e]?.-[%W]+kloster[%W]*[t]?[e]?[i]?[l]?",
					"straht[h]?[o]?[l]?[m]?[e]?.-[%W]+kloster[%W]*[t]?[e]?[i]?[l]?",
					"sta[r]?t[%W]*kloster[%W]*[t]?[e]?[i]?[l]?",
					"stra[%W]*kloster[%W]*[t]?[e]?[i]?[l]?",
				},
				FR = {
					-- Écarlate / Croisés
					"st[a]?rat[h]?[o]?[l]?[m]?[e]?.-[%W]+eca[r]?[l]?[a]?[t]?[e]?",
					"st[a]?rat[h]?[o]?[l]?[m]?[e]?.-[%W]+croise[s]?",
					"sta[r]?th[o]?[l]?[m]?[e]?.-[%W]+eca[r]?[l]?[a]?[t]?[e]?",
					"sta[r]?th[o]?[l]?[m]?[e]?.-[%W]+croise[s]?",
					"straht[h]?[o]?[l]?[m]?[e]?.-[%W]+eca[r]?[l]?[a]?[t]?[e]?",
					"straht[h]?[o]?[l]?[m]?[e]?.-[%W]+croise[s]?",
					"sta[r]?t[%W]*eca[r]?[l]?[a]?[t]?[e]?",
					"sta[r]?t[%W]*croise[s]?",
					"stra[%W]*eca[r]?[l]?[a]?[t]?[e]?",
					"stra[%W]*croise[s]?",
				},
				ES = {
					-- Viva
					"st[a]?rat[h]?[o]?[l]?[m]?[e]?.-[%W]+viva",
					"sta[r]?th[o]?[l]?[m]?[e]?.-[%W]+viva",
					"straht[h]?[o]?[l]?[m]?[e]?.-[%W]+viva",
					"sta[r]?t[%W]*viva",
					"stra[%W]*viva",
				},
				RU = {},
			},
			ParentDungeon = 36,
			Size = 5,
			MinLevel = 58,
			MaxLevel = 60
		},
		{
			Index = 38,
			Name = "Stratholme - Undead Side",
			Abbreviation = "Strat Undead",
			Identifiers = {
				EN = {
					"st[a]?rat[h]?[o]?[l]?[m]?[e]?u[n]?d[e]?[a]?[d]?",
					"st[a]?rat[h]?[o]?[l]?[m]?[e]?dead",
					"st[a]?rat[h]?[o]?[l]?[m]?[e]?bar[r]?on",
					"sta[r]?th[o]?[l]?[m]?[e]?u[n]?d[e]?[a]?[d]?",
					"sta[r]?th[o]?[l]?[m]?[e]?dead",
					"sta[r]?th[o]?[l]?[m]?[e]?bar[r]?on",
					"straht[h]?[o]?[l]?[m]?[e]?u[n]?d[e]?[a]?[d]?",
					"straht[h]?[o]?[l]?[m]?[e]?dead",
					"straht[h]?[o]?[l]?[m]?[e]?bar[r]?on",
					"st[a]?rat[h]?[o]?[l]?[m]?[e]?.-[%W]+u[n]?d[e]?[a]?[d]?",
					"st[a]?rat[h]?[o]?[l]?[m]?[e]?.-[%W]+dead",
					"st[a]?rat[h]?[o]?[l]?[m]?[e]?.-[%W]+bar[r]?on",
					"sta[r]?th[o]?[l]?[m]?[e]?.-[%W]+u[n]?d[e]?[a]?[d]?",
					"sta[r]?th[o]?[l]?[m]?[e]?.-[%W]+dead",
					"sta[r]?th[o]?[l]?[m]?[e]?.-[%W]+bar[r]?on",
					"straht[h]?[o]?[l]?[m]?[e]?.-[%W]+u[n]?d[e]?[a]?[d]?",
					"straht[h]?[o]?[l]?[m]?[e]?.-[%W]+dead",
					"straht[h]?[o]?[l]?[m]?[e]?.-[%W]+bar[r]?on",
					"sta[r]?t[%W]*u[n]?d[e]?[a]?[d]?",
					"sta[r]?t[%W]*dead",
					"sta[r]?t[%W]*bar[r]?on",
					"stra[%W]*u[n]?d[e]?[a]?[d]?",
					"stra[%W]*dead",
					"stra[%W]*bar[r]?on",
				},
				DE = {
					-- Untotenteil
					"st[a]?rat[h]?[o]?[l]?[m]?[e]?.-[%W]+untot[e]?[n]?[%W]*[t]?[e]?[i]?[l]?",
					"sta[r]?th[o]?[l]?[m]?[e]?.-[%W]+untot[e]?[n]?[%W]*[t]?[e]?[i]?[l]?",
					"straht[h]?[o]?[l]?[m]?[e]?.-[%W]+untot[e]?[n]?[%W]*[t]?[e]?[i]?[l]?",
					"sta[r]?t[%W]*untot[e]?[n]?[%W]*[t]?[e]?[i]?[l]?",
					"stra[%W]*untot[e]?[n]?[%W]*[t]?[e]?[i]?[l]?",
				},
				FR = {
					-- Fléau
					"st[a]?rat[h]?[o]?[l]?[m]?[e]?.-[%W]+fleau",
					"sta[r]?th[o]?[l]?[m]?[e]?.-[%W]+fleau",
					"straht[h]?[o]?[l]?[m]?[e]?.-[%W]+fleau",
					"sta[r]?t[%W]*fleau",
					"stra[%W]*fleau",
				},
				ES = {
					-- Muerta
					"st[a]?rat[h]?[o]?[l]?[m]?[e]?.-[%W]+muerta",
					"sta[r]?th[o]?[l]?[m]?[e]?.-[%W]+muerta",
					"straht[h]?[o]?[l]?[m]?[e]?.-[%W]+muerta",
					"sta[r]?t[%W]*muerta",
					"stra[%W]*muerta",
				},
				RU = {},
			},
			ParentDungeon = 36,
			Size = 5,
			MinLevel = 58,
			MaxLevel = 60
		},
		{
			Index = 39,
			Name = "Dire Maul",
			Abbreviation = "DM",
			Identifiers = {
				EN = {
					"dire[%W]*maul",
					"dim",
				},
				DE = {
					-- Düsterbruch
					"du[e]?sterbruch",
					"db",
				},
				FR = {
					-- Hache Tripes
					"hache[%W]*tripe[s]?",
					"ht",
				},
				ES = {
					-- La Masacre
					"masacre",
				},
				RU = {},
			},
			SubDungeons = { 40, 41, 42, 43 },
			Size = 5,
			MinLevel = 58,
			MaxLevel = 60
		},
		{
			Index = 40,
			Name = "Dire Maul - East",
			Abbreviation = "DM East",
			Identifiers = {
				EN = {
					"d[i]?me",
					"d[i]?meast",
					"d[i]?m.-[%W]+e",
					"d[i]?m.-[%W]+east",
					"dire[%W]*maul.-[%W]+e",
					"dire[%W]*maul.-[%W]+east",
					"jump[%W]*run[s]?",
				},
				DE = {
					-- Ost
					"dbo",
					"dbe",
					"dbost",
					"dbeast",
					"db.-[%W]+o",
					"db.-[%W]+e",
					"db.-[%W]+ost",
					"db.-[%W]+east",
					"du[e]?sterbruch.-[%W]+o",
					"du[e]?sterbruch.-[%W]+e",
					"du[e]?sterbruch.-[%W]+ost",
					"du[e]?sterbruch.-[%W]+east",
					"d[i]?mo",
					"d[i]?most",
					"d[i]?m.-[%W]+o",
					"d[i]?m.-[%W]+ost",
					"dire[%W]*maul.-[%W]+o",
					"dire[%W]*maul.-[%W]+ost",
				},
				FR = {
					-- Est
					"hte",
					"hteast",
					"ht.-[%W]+e",
					"ht.-[%W]+est",
					"ht.-[%W]+east",
					"hache[%W]*tripe[s]?.-[%W]+e",
					"hache[%W]*tripe[s]?.-[%W]+est",
					"hache[%W]*tripe[s]?.-[%W]+east",
					"d[i]?m.-[%W]+est",
					"dire[%W]*maul.-[%W]+est",
				},
				ES = {
					-- Este
					"masacre.-[%W]+e",
					"masacre.-[%W]+este",
					"masacre.-[%W]+east",
					"d[i]?m.-[%W]+este",
					"dire[%W]*maul.-[%W]+este",
				},
				RU = {},
			},
			ParentDungeon = 39,
			Size = 5,
			MinLevel = 58,
			MaxLevel = 60
		},
		{
			Index = 41,
			Name = "Dire Maul - West",
			Abbreviation = "DM West",
			Identifiers = {
				EN = {
					"d[i]?mw",
					"d[i]?mwest",
					"d[i]?m.-[%W]+w",
					"d[i]?m.-[%W]+west",
					"dire[%W]*maul.-[%W]+w",
					"dire[%W]*maul.-[%W]+west",
				},
				DE = {
					-- West
					"dbw",
					"dbwest",
					"db.-[%W]+w",
					"db.-[%W]+west",
					"du[e]?sterbruch.-[%W]+w",
					"du[e]?sterbruch.-[%W]+west",
				},
				FR = {
					-- Ouest
					"hto",
					"htw",
					"htouest",
					"htwest",
					"ht.-[%W]+o",
					"ht.-[%W]+w",
					"ht.-[%W]+ouest",
					"ht.-[%W]+west",
					"hache[%W]*tripe[s]?.-[%W]+o",
					"hache[%W]*tripe[s]?.-[%W]+w",
					"hache[%W]*tripe[s]?.-[%W]+ouest",
					"hache[%W]*tripe[s]?.-[%W]+west",
					"d[i]?mo",
					"d[i]?mouest",
					"d[i]?m.-[%W]+o",
					"d[i]?m.-[%W]+ouest",
					"dire[%W]*maul.-[%W]+ouest",
				},
				ES = {
					-- Oeste
					-- ( "o" = "or" )
					"masacre.-[%W]+w",
					"masacre.-[%W]+oeste",
					"masacre.-[%W]+west",
					"d[i]?mo",
					"d[i]?moeste",
					"d[i]?m.-[%W]+oeste",
					"dire[%W]*maul.-[%W]+oeste",
				},
				RU = {},
			},
			ParentDungeon = 39,
			Size = 5,
			MinLevel = 58,
			MaxLevel = 60
		},
		{
			Index = 42,
			Name = "Dire Maul - North",
			Abbreviation = "DM North",
			Identifiers = {
				EN = {
					"d[i]?mn",
					"d[i]?mnort[h]?",
					"d[i]?m.-[%W]+n",
					"d[i]?m.-[%W]+nort[h]?",
					"dire[%W]*maul.-[%W]+n",
					"dire[%W]*maul.-[%W]+nort[h]?",
				},
				DE = {
					-- Nord
					"d[i]?mnord",
					"d[i]?m.-[%W]+nord",
					"dire[%W]*maul.-[%W]+nord",
					"dbn",
					"dbnord",
					"db.-[%W]+n",
					"db.-[%W]+nord",
					"db.-[%W]+nort[h]?",
					"du[e]?sterbruch.-[%W]+n",
					"du[e]?sterbruch.-[%W]+nord",
					"du[e]?sterbruch.-[%W]+nort[h]?",
				},
				FR = {
					-- Nord
					"d[i]?mnord",
					"d[i]?m.-[%W]+nord",
					"dire[%W]*maul.-[%W]+nord",
					"htn",
					"htnord",
					"htnort[h]?",
					"ht.-[%W]+n",
					"ht.-[%W]+nord",
					"ht.-[%W]+nort[h]?",
					"hache[%W]*tripe[s]?.-[%W]+n",
					"hache[%W]*tripe[s]?.-[%W]+nord",
					"hache[%W]*tripe[s]?.-[%W]+nort[h]?",
				},
				ES = {
					-- Norte
					"d[i]?mnorte",
					"d[i]?m.-[%W]+norte",
					"dire[%W]*maul.-[%W]+norte",
					"masacre.-[%W]+n",
					"masacre.-[%W]+norte",
					"masacre.-[%W]+nort[h]?",
				},
				RU = {},
			},
			ParentDungeon = 39,
			Size = 5,
			MinLevel = 58,
			MaxLevel = 60
		},
		{
			Index = 43,
			Name = "Dire Maul - Tribute Run",
			Abbreviation = "DM Tribute Run",
			Identifiers = {
				EN = {
					"d[i]?mt",
					"d[i]?mtrib[u]?[t]?[e]?[r]?[u]?[n]?",
					"d[i]?m.-[%W]+t",
					"d[i]?m.-[%W]+trib[u]?[t]?[e]?[r]?[u]?[n]?",
					"dire[%W]*maul.-[%W]+t",
					"dire[%W]*maul.-[%W]+trib[u]?[t]?[e]?[r]?[u]?[n]?",
					"tribute[r]?[u]?[n]?",
				},
				DE = {
					"dbt",
					"dbtrib[u]?[t]?[e]?[r]?[u]?[n]?",
					"db.-[%W]+t",
					"db.-[%W]+trib[u]?[t]?[e]?[r]?[u]?[n]?",
					"du[e]?sterbruch.-[%W]+t",
					"du[e]?sterbruch.-[%W]+trib[u]?[t]?[e]?[r]?[u]?[n]?",
					"tribut[e]?[r]?[u]?[n]?",
				},
				FR = {
					"htt",
					"httrib[u]?[t]?[e]?[r]?[u]?[n]?",
					"ht.-[%W]+t",
					"ht.-[%W]+trib[u]?[t]?[e]?[r]?[u]?[n]?",
					"hache[%W]*tripe[s]?.-[%W]+t",
					"hache[%W]*tripe[s]?.-[%W]+trib[u]?[t]?[e]?[r]?[u]?[n]?",
					"tribut[e]?[r]?[u]?[n]?",
				},
				ES = {
					"masacre.-[%W]+t",
					"masacre.-[%W]+trib[u]?[t]?[oe]?[r]?[u]?[n]?",
					"tribut[oe]?[r]?[u]?[n]?",
				},
				RU = {},
			},
			NotIdentifiers = {
				EN = {
					"not[%W]*trib[u]?[t]?[e]?[r]?[u]?[n]?",
				},
				DE = {
					"kein[%W]*trib[u]?[t]?[e]?[r]?[u]?[n]?",
				},
				FR = {
					"pas[%W]*trib[u]?[t]?[e]?[r]?[u]?[n]?",
				},
				ES = {
					"no[%W]*trib[u]?[t]?[eo]?[r]?[u]?[n]?",
				}
			},
			ParentDungeon = 39,
			Size = 5,
			MinLevel = 58,
			MaxLevel = 60
		},
		{
			Index = 44,
			Name = "Molten Core",
			Abbreviation = "MC",
			Identifiers = {
				EN = {
					"molten[%W]*core",
					"mc",
					"mc[%d]*",
				},
				DE = {
					-- Geschmolzener Kern
					"geschmolzener[%W]*kern",
				},
				FR = {
					-- Cœur du Magma
					"coeur[%W]*[d]?[u]?[%W]*magma",
				},
				ES = {
					-- Núcleo de magma
					"nucleo[%W]*[d]?[e]?[%W]*magma",
				},
				RU = {},
			},
			NotIdentifiers = {
				EN = {
					"molten[%W]*core[%W]*at[t]?un[e]?ment",
					"mc[%W]*at[t]?un[e]?ment",
					"molten[%W]*core[%W]*pre[%W]*[q]?[u]?[e]?[s]?[t]?[s]?",
					"mc[%W]*pre[%W]*[q]?[u]?[e]?[s]?[t]?[s]?",
					"mc[%W]*geared",
				},
			},
			Size = 40,
			MinLevel = 60,
			MaxLevel = 60,
		},
		{
			Index = 45,
			Name = "Onyxia's Lair",
			Abbreviation = "Onyxia",
			Identifiers = {
				EN = {
					"ony[i]?[x]?[iy]?[e]?[a]?",
					"onix[iy][e]?[a]?",
				},
				DE = {},
				FR = {},
				ES = {},
				RU = {},
			},
			NotIdentifiers = {
				EN = {
					"ony[i]?[x]?[iy]?[e]?[a]?[%W]*at[t]?un[e]?ment",
					"ony[i]?[x]?[iy]?[e]?[a]?[%W]*at[t]?une",
					"ony[i]?[x]?[iy]?[e]?[a]?[%W]*q[u]?[e]?[s]?[t]?[s]?",
					"ony[i]?[x]?[iy]?[e]?[a]?[%W]*pre[%W]*[q]?[u]?[e]?[s]?[t]?[s]?",
					"onix[iy][e]?[a]?[%W]*at[t]?un[e]?ment",
					"onix[iy][e]?[a]?[%W]*at[t]?une",
					"onix[iy][e]?[a]?[%W]*q[u]?[e]?[s]?[t]?[s]?",
					"onix[iy][e]?[a]?[%W]*pre[%W]*[q]?[u]?[e]?[s]?[t]?[s]?",
				},
				FR = {
					"quete[%W]*ony[i]?[x]?[iy]?[e]?[a]?",
					"quete[%W]*onix[iy][e]?[a]?",
				},
				ES = {
					"pre[%W]*quest[%W]*[d]?[e]?[%W]*ony[i]?[x]?[iy]?[e]?[a]?",
					"pre[%W]*quest[%W]*[d]?[e]?[%W]*onix[iy][e]?[a]?",
					"pre[%W]*[d]?[e]?[%W]*ony[i]?[x]?[iy]?[e]?[a]?",
					"pre[%W]*[d]?[e]?[%W]*onix[iy][e]?[a]?",
				},
			},
			Size = 40,
			MinLevel = 60,
			MaxLevel = 60,
		},
		{
			Index = 46,
			Name = "Blackwing Lair",
			Abbreviation = "BWL",
			Identifiers = {
				EN = {
					"blackwing[%W]*lair",
					"bwl",
				},
				DE = {},
				FR = {},
				ES = {},
				RU = {},
			},
			NotIdentifiers = {
				EN = {
					"bwl[%W]*at[t]?un[e]?ment",
					"bwl[%W]*pre[%W]*[q]?[u]?[e]?[s]?[t]?[s]?",
				},
			},
			Size = 40,
			MinLevel = 60,
			MaxLevel = 60,
		},
		{
			Index = 47,
			Name = "Zul'Gurub",
			Abbreviation = "ZG",
			Identifiers = {
				EN = {
					"zul[l]?[%W]*g[u]?rub",
					"zg",
				},
				DE = {},
				FR = {},
				ES = {},
				RU = {},
			},
			Size = 20,
			MinLevel = 60,
			MaxLevel = 60,
		},
		{
			Index = 48,
			Name = "Ruins of Ahn'Qiraj",
			Abbreviation = "AQ20",
			Identifiers = {
				EN = {
					"ruin[s]?[%W]*[o]?[f]?[%W]*ahn[%W]*qiraj",
					"ahn[%W]*qiraj[%W]*ruin[s]?",
					"aq[%W]*ruin[s]?",
					"aq[%W]*20",
					"raq",
				},
				DE = {},
				FR = {},
				ES = {},
				RU = {},
			},
			Size = 20,
			MinLevel = 60,
			MaxLevel = 60,
		},
		{
			Index = 49,
			Name = "Temple of Ahn'Qiraj",
			Abbreviation = "AQ40",
			Identifiers = {
				EN = {
					"temple[%W]*[o]?[f]?[%W]*ahn[%W]*qiraj",
					"ahn[%W]*qiraj[%W]*temple",
					"aq[%W]*temple",
					"aq[%W]*40",
					"taq",
				},
				DE = {},
				FR = {},
				ES = {},
				RU = {},
			},
			Size = 40,
			MinLevel = 60,
			MaxLevel = 60,
		},
		{
			Index = 50,
			Name = "Naxxramas",
			Abbreviation = "Naxx",
			Identifiers = {
				EN = {
					"naxx[a]?ramas",
					"naxx",
				},
				DE = {},
				FR = {},
				ES = {},
				RU = {},
			},
			Size = 40,
			MinLevel = 60,
			MaxLevel = 60,
		},
		{
			Index = 51,
			Name = "Warsong Gulch",
			Abbreviation = "WSG",
			Identifiers = {
				EN = {
					"war[%W]*song[%W]*gulch",
					"war[%W]*song[%W]*premade",
					"wsg",
				},
				DE = {
					-- Warsongschlucht
					"warsong[%W]*schlucht",
				},
				FR = {
					-- Goulet des Warsong
					"goulet[%W]*[d]?[e]?[s]?[%W]*warsong",
				},
				ES = {
					-- Garganta Grito de Guerra
					"garganta[%W]*grito[%W]*[d]?[e]?[%W]*guer[r]?a",
				},
				RU = {},
			},
			Size = 10,
			MinLevel = 10,
			MaxLevel = 60,
			Pvp = true
		},
		{
			Index = 52,
			Name = "Alterac Valley",
			Abbreviation = "AV",
			Identifiers = {
				EN = {
					"alterac[%W]*val[l]?ey",
					"alterac[%W]*premade",
					"av",
				},
				DE = {
					-- Alteractal
					"alterac[%W]*tal",
				},
				FR = {
					-- Vallée d'Alterac
					"val[l]?e[e]?[%W]*[d]?[%W]*alterac",
				},
				ES = {
					-- Valle de Alterac
					"val[l]?e[%W]*[d]?[e]?[%W]*alterac",
				},
				RU = {},
			},
			Size = 40,
			MinLevel = 51,
			MaxLevel = 60,
			Pvp = true
		},
		{
			Index = 53,
			Name = "Arathi Basin",
			Abbreviation = "AB",
			Identifiers = {
				EN = {
					"arat[h]?i[%W]*basin",
					"ab",
				},
				DE = {},
				FR = {},
				ES = {},
				RU = {},
			},
			Size = 15,
			MinLevel = 20,
			MaxLevel = 60,
			Pvp = true
		},
	},
	DUNGEONS_FALLBACK = {
		{
			Dungeons = { 3, 39 },
			Identifiers = {
				EN = { 
					"dm",
				},
				DE = {},
				FR = {},
				ES = {},
				RU = {},
			},
		},
		{
			Dungeons = { 20, 31 },
			Identifiers = {
				EN = {
					"princes[s]?[%W]*run[s]?",
				},
				DE = {
					-- Prinzessinen
					"prin[cz]es[s]?[i]?[n]?[n]?[e]?[n]?[%W]*run[s]?"
				},
				FR = {
					-- Princesse
					"princes[s]?[e]?[%W]*run[s]?"
				},
				ES = {
					-- Princesa
					"princes[s]?[a]?[%W]*run[s]?"
				},
				RU = {},
			},
		},
		{
			Dungeons = { 48, 49 },
			Identifiers = {
				EN = {
					"aq",
				},
				DE = {},
				FR = {},
				ES = {},
				RU = {},
			}
		},
		{
			Dungeons = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43 },
			Identifiers = {
				EN = {
					"any[%W]*dungeon[s]?",
					"any[%W]*raid[s]?.-dungeon[s]?",
					"lfg[%W]*dungeon[s]?",
				},
				DE = {},
				FR = {
					"dispo[n]?[i]?[b]?[l]?[e]?[%W]*dj",
					"dispo[n]?[i]?[b]?[l]?[e]?[%W]*donjon[s]?",
					"dispo[n]?[i]?[b]?[l]?[e]?[%W]*instance[s]?",
					"dispo[n]?[i]?[b]?[l]?[e]?[%W]*pour[%W]*dj",
					"dispo[n]?[i]?[b]?[l]?[e]?[%W]*pour[%W]*donjon[s]?",
					"dispo[n]?[i]?[b]?[l]?[e]?[%W]*pour[%W]*instance[s]?",
				},
				ES = {},
				RU = {},
			},
		},
		{
			Dungeons = { 44, 45, 46, 47, 48, 49, 50 },
			Identifiers = {
				EN = {
					"any[%W]*raid[s]?",
					"any[%W]*dungeon[s]?.-raid[s]?",
					"lfg[%W]*raid[s]?",
				},
				DE = {},
				FR = {},
				ES = {},
				RU = {},
			},
		},
		{
			Dungeons = { 51, 52, 53 },
			Identifiers = {
				EN = {
					"pvp",
					"premade",
				},
				DE = {},
				FR = {},
				ES = {},
				RU = {},
			},
		}
	}
}
