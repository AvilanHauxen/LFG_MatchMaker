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
-- SAVED VARIABLES
------------------------------------------------------------------------------------------------------------------------


function LFGMM_Load()
	LFGMM_DB_VERSION = 1;

	if (LFGMM_DB == nil or LFGMM_DB.VERSION < LFGMM_DB_VERSION) then
		LFGMM_DB = {
			VERSION = LFGMM_DB_VERSION,
			SETTINGS = {
				MessageTimeout = 30,
				MaxMessageAge = 10,
				BroadcastInterval = 2,
				RequestInviteMessage = "",
				RequestInviteMessageTemplate = "Invite for group ({L} {C})",
				ShowQuestLogButton = true,
				ShowMinimapButton = true,
				HideLowLevel = false,
				HideHighLevel = false,
				HidePvp = false,
				HideRaids = false,
				MinimapButtonPosition = -35
			},
			LIST = {
				Dungeons = { },
				ShowUnknownDungeons = false,
				MessageTypes = {
					Unknown = false,
					Lfg = true,
					Lfm = true
				}
			},
			SEARCH = {
				LastBroadcast = time() - 600,
				LFG = {
					Running = false,
					MatchLfg = false,
					MatchUnknown = true,
					Broadcast = false,
					BroadcastMessage = "",
					BroadcastMessageTemplate = "{L} {C} LFG {A}",
					Dungeons = {}
				},
				LFM = {
					Running = false,
					MatchLfm = false,
					MatchUnknown = true,
					Broadcast = false,
					BroadcastMessage = "",
					BroadcastMessageTemplate = "LF{N}M {D}",
					Dungeon = nil
				}
			}
		};
		
		-- Add all dungeons to list selection
		for _,dungeon in ipairs(LFGMM_GLOBAL.DUNGEONS) do
			table.insert(LFGMM_DB.LIST.Dungeons, dungeon.Index);
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
	WHO_COOLDOWN = 0,
	PLAYER_NAME = "",
	PLAYER_LEVEL = 0,
	PLAYER_CLASS = "",
	PLAYER_SPEC = "",
	LFG_CHANNEL_NAME = "LookingForGroup",
	GROUP_MEMBERS = {},
	MESSAGES = {},
	CLASSES = {
		WARRIOR = {
			Name = "Warrior",
			LocalizedName = LOCALIZED_CLASS_NAMES_MALE.WARRIOR,
			IconCoordinates = CLASS_ICON_TCOORDS.WARRIOR,
			Color = "|cFFC79C6E"
		},
		PALADIN = {
			Name = "Paladin",
			LocalizedName = LOCALIZED_CLASS_NAMES_MALE.PALADIN,
			IconCoordinates = CLASS_ICON_TCOORDS.PALADIN,
			Color = "|cFFF58CBA"
		},
		HUNTER = {
			Name = "Hunter",
			LocalizedName = LOCALIZED_CLASS_NAMES_MALE.HUNTER,
			IconCoordinates = CLASS_ICON_TCOORDS.HUNTER,
			Color = "|cFFABD473"
		},
		ROGUE = {
			Name = "Rogue",
			LocalizedName = LOCALIZED_CLASS_NAMES_MALE.ROGUE,
			IconCoordinates = CLASS_ICON_TCOORDS.ROGUE,
			Color = "|cFFFFF569"
		},
		PRIEST = {
			Name = "Priest",
			LocalizedName = LOCALIZED_CLASS_NAMES_MALE.PRIEST,
			IconCoordinates = CLASS_ICON_TCOORDS.PRIEST,
			Color = "|cFFFFFFFF"
		},
		SHAMAN = {
			Name = "Shaman",
			LocalizedName = LOCALIZED_CLASS_NAMES_MALE.SHAMAN,
			IconCoordinates = CLASS_ICON_TCOORDS.SHAMAN,
			Color = "|cFF0070DE"
		},
		MAGE = {
			Name = "Mage",
			LocalizedName = LOCALIZED_CLASS_NAMES_MALE.MAGE,
			IconCoordinates = CLASS_ICON_TCOORDS.MAGE,
			Color = "|cFF69CCF0"
		},
		WARLOCK = {
			Name = "Warlock",
			LocalizedName = LOCALIZED_CLASS_NAMES_MALE.WARLOCK,
			IconCoordinates = CLASS_ICON_TCOORDS.WARLOCK,
			Color = "|cFF9482C9"
		},
		DRUID = {
			Name = "Druid",
			LocalizedName = LOCALIZED_CLASS_NAMES_MALE.DRUID,
			IconCoordinates = CLASS_ICON_TCOORDS.DRUID,
			Color = "|cFFFF7D0A"
		}
	},
	DUNGEONS = {
		{
			Index = 1,
			Name = "Ragefire Chasm",
			Abbreviation = "RFC",
			Identifiers = {
				"rage[%W]*fire[%W]*c[h]?asm",
				"rfc"
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
				"wa[i]?ling[%W]*cavern[s]?",
				"wc"
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
				"de[a]?dmine[s]?",
				"de[a]?thmine[s]?"
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
				"shadow[%W]*fang[%W]*keep",
				"sfk",
				"sk" 
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
				"black[%W]*fat[h]?om[%W]*de[e]?p[t]?[h]?[s]?",
				"bfd"
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
				"stormwind[%W]*stockade[s]?",
				"stockade[s]?",
				"stocks"
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
				"scarlet[%W]*mon[e]?[a]?st[e]?[a]?ry",
				"sm"
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
				"scarlet[%W]*mon[e]?[a]?st[e]?[a]?ry[%W]*g[r]?[a]?[v]?[e]?y[e]?[a]?[r]?[d]?",
				"sm[%W]*g[r]?[a]?[v]?[e]?y[e]?[a]?[r]?[d]?",
				"g[r]?[a]?[v]?[e]?y[e]?[a]?[r]?[d]?[%W]*sm",
		        "lib[r]?[a]?[r]?[y]?[%W]*[o]?[r]?[%W]*g[r]?[a]?[v]?[e]?y[e]?[a]?[r]?[d]?",
	            "arm[o]?[u]?[r]?[y]?[%W]*[o]?[r]?[%W]*g[r]?[a]?[v]?[e]?y[e]?[a]?[r]?[d]?",
				"cat[h]?[e]?[d]?[r]?[a]?[l]?[%W]*[o]?[r]?[%W]*g[r]?[a]?[v]?[e]?y[a]?[r]?[d]?",
				"g[r]?[a]?[v]?[e]?y[e]?[a]?[r]?[d]?[%W]*[o]?[r]?[%W]*lib[r]?[a]?[r]?[y]?",
				"g[r]?[a]?[v]?[e]?y[e]?[a]?[r]?[d]?[%W]*[o]?[r]?[%W]*arm[o]?[u]?[r]?[y]?",
				"g[r]?[a]?[v]?[e]?y[e]?[a]?[r]?[d]?[%W]*[o]?[r]?[%W]*cat[h]?[e]?[d]?[r]?[a]?[l]?"
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
				"scarlet[%W]*mon[e]?[a]?st[e]?[a]?ry[%W]*lib[r]?[a]?[r]?[y]?",
				"sm[%W]*lib[r]?[a]?[r]?[y]?",
				"lib[r]?[a]?[r]?[y]?[%W]*sm",
				"g[r]?[a]?[v]?[e]?y[e]?[a]?[r]?[d]?[%W]*[o]?[r]?[%W]*lib[r]?[a]?[r]?[y]?",
				"arm[o]?[u]?[r]?[y]?[%W]*[o]?[r]?[%W]*lib[r]?[a]?[r]?[y]?",
				"cat[h]?[e]?[d]?[r]?[a]?[l]?[%W]*[o]?[r]?[%W]*lib[r]?[a]?[r]?[y]?",
				"lib[r]?[a]?[r]?[y]?[%W]*[o]?[r]?[%W]*g[r]?[a]?[v]?[e]?y[e]?[a]?[r]?[d]?",
				"lib[r]?[a]?[r]?[y]?[%W]*[o]?[r]?[%W]*arm[o]?[u]?[r]?[y]?",
				"lib[r]?[a]?[r]?[y]?[%W]*[o]?[r]?[%W]*cat[h]?[e]?[d]?[r]?[a]?[l]?",
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
				"scarlet[%W]*mon[e]?[a]?st[e]?[a]?ry[%W]*arm[o]?[u]?[r]?[y]?",
				"sm[%W]*arm[o]?[u]?[r]?[y]?",
				"arm[o]?[u]?[r]?[y]?[%W]*sm",
				"g[r]?[a]?[v]?[e]?y[e]?[a]?[r]?[d]?[%W]*[o]?[r]?[%W]*arm[o]?[u]?[r]?[y]?",
				"lib[r]?[a]?[r]?[y]?[%W]*[o]?[r]?[%W]*arm[o]?[u]?[r]?[y]?",
				"cat[h]?[e]?[d]?[r]?[a]?[l]?[%W]*[o]?[r]?[%W]*arm[o]?[u]?[r]?[y]?",
				"arm[o]?[u]?[r]?[y]?[%W]*[o]?[r]?[%W]*g[r]?[a]?[v]?[e]?y[e]?[a]?[r]?[d]?",
				"arm[o]?[u]?[r]?[y]?[%W]*[o]?[r]?[%W]*lib[r]?[a]?[r]?[y]?",
				"arm[o]?[u]?[r]?[y]?[%W]*[o]?[r]?[%W]*cat[h]?[e]?[d]?[r]?[a]?[l]?",
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
				"scarlet[%W]*mon[e]?[a]?st[e]?[a]?ry[%W]*cat[h]?[e]?[d]?[r]?[a]?[l]?",
				"sm[%W]*cat[h]?[e]?[d]?[r]?[a]?[l]?",
				"cat[h]?[e]?[d]?[r]?[a]?[l]?[%W]*sm",
				"g[r]?[a]?[v]?[e]?y[e]?[a]?[r]?[d]?[%W]*[o]?[r]?[%W]*cat[h]?[e]?[d]?[r]?[a]?[l]?",
				"lib[r]?[a]?[r]?[y]?[%W]*[o]?[r]?[%W]*cat[h]?[e]?[d]?[r]?[a]?[l]?",
				"arm[o]?[u]?[r]?[y]?[%W]*[o]?[r]?[%W]*cat[h]?[e]?[d]?[r]?[a]?[l]?",
				"cat[h]?[e]?[d]?[r]?[a]?[l]?[%W]*[o]?[r]?[%W]*g[r]?[a]?[v]?[e]?y[e]?[a]?[r]?[d]?",
				"cat[h]?[e]?[d]?[r]?[a]?[l]?[%W]*[o]?[r]?[%W]*lib[r]?[a]?[r]?[y]?",
				"cat[h]?[e]?[d]?[r]?[a]?[l]?[%W]*[o]?[r]?[%W]*arm[o]?[u]?[r]?[y]?",
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
				"gnom[e]?[r]?[e]?[a]?g[r]?an",
				"gnomer"
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
				"razo[rn]?[%W]*fen[%W]*kraul",
				"rfk"
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
				"razo[rn]?[%W]*fen[%W]*downs",
				"rfd",
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
				"uldaman",
				"uld[a]?",
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
				"zul[%W]*far[r]?ak[k]?",
				"zfk",
				"zf",
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
				"ma[u]?ra[u]?don",
				"mara",
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
				"ma[u]?ra[u]?don[%W]*orange",
				"mara[%W]*orange",
				"orange[%W]*[o]?[r]?[%W]*purple",
				"orange[%W]*[o]?[r]?[%W]*inner",
				"orange[%W]*[o]?[r]?[%W]*princes[s]?",
				"purple[%W]*[o]?[r]?[%W]*orange",
				"inner[%W]*[o]?[r]?[%W]*orange",
				"princes[s]?[%W]*[o]?[r]?[%W]*orange",
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
				"ma[u]?ra[u]?don[%W]*purple",
				"mara[%W]*purple",
				"purple[%W]*[o]?[r]?[%W]*orange",
				"purple[%W]*[o]?[r]?[%W]*inner",
				"purple[%W]*[o]?[r]?[%W]*princes[s]?",
				"orange[%W]*[o]?[r]?[%W]*purple",
				"inner[%W]*[o]?[r]?[%W]*purple",
				"princes[s]?[%W]*[o]?[r]?[%W]*purple",
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
				"ma[u]?ra[u]?don[%W]*inner",
				"ma[u]?ra[u]?don[%W]*princes[s]?",
				"mara[%W]*inner",
				"mara[%W]*princes[s]?",
				"inner[%W]*ma[u]?ra[u]?don",
				"inner[%W]*mara",
				"earth[%W]*song[%W]*falls",
				"inner[%W]*[o]?[r]?[%W]*orange",
  				"inner[%W]*[o]?[r]?[%W]*purple",
				"princes[s]?[%W]*[o]?[r]?[%W]*orange",
				"princes[s]?[%W]*[o]?[r]?[%W]*purple",
				"orange[%W]*[o]?[r]?[%W]*inner",
  				"orange[%W]*[o]?[r]?[%W]*princes[s]?",
				"purple[%W]*[o]?[r]?[%W]*inner",
				"purple[%W]*[o]?[r]?[%W]*princes[s]?",
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
				"temple[%W]*[o]?[f]?[%W]*atal[%W]*hakkar",
				"sunk[t]?en[%W]*temple",
				"sunken",
				"st",
			},
			NotIdentifiers = {
				"[%d][%d][%W]*[%d][%d][%W]*st"
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
				"black[%W]*rock[%W]*dep[t]?[h]?s",
				"brd",
			},
			SubDungeons = { 23, 24, 25, 26, 27, 28, 29, 30, 31 },
			Size = 5,
			MinLevel = 52,
			MaxLevel = 60
		},
		{
			Index = 23,
			Name = "Blackrock Depths - Quest Run",
			Abbreviation = "BRD Quest Run",
			Identifiers = {
				"black[%W]*rock[%W]*dep[t]?[h]?s[%W]*quest[s]?",
				"brd[%W]*quest[s]?",
				"quest[s]?[%W]*[o]?[r]?[%W]*at[t]?un[e]?ment",
				"quest[s]?[%W]*[o]?[r]?[%W]*arena",
				"quest[s]?[%W]*[o]?[r]?[%W]*anger[f]?[g]?[o]?[r]?[g]?[e]?",
				"quest[s]?[%W]*[o]?[r]?[%W]*prison",
				"quest[s]?[%W]*[o]?[r]?[%W]*vault",
				"quest[s]?[%W]*[o]?[r]?[%W]*lava",
				"quest[s]?[%W]*[o]?[r]?[%W]*emp[r]?eror",
				"quest[s]?[%W]*[o]?[r]?[%W]*princes[s]?",
				"at[t]?un[e]?ment[%W]*[o]?[r]?[%W]*quest[s]?",
				"arena[%W]*[o]?[r]?[%W]*quest[s]?",
				"anger[f]?[g]?[o]?[r]?[g]?[e]?[%W]*[o]?[r]?[%W]*quest[s]?",
				"prison[%W]*[o]?[r]?[%W]*quest[s]?",
				"vault[%W]*[o]?[r]?[%W]*quest[s]?",
				"lava[%W]*[o]?[r]?[%W]*quest[s]?",
				"emp[r]?eror[%W]*[o]?[r]?[%W]*quest[s]?",
				"princes[s]?[%W]*[o]?[r]?[%W]*quest[s]?",
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
				"black[%W]*rock[%W]*dep[t]?[h]?s[%W]*at[t]?un[e]?ment",
				"brd[%W]*at[t]?un[e]?ment",
				"at[t]?un[e]?ment[%W]*run[s]?",
				"at[t]?un[e]?ment[%W]*[o]?[r]?[%W]*quest[s]?",
				"at[t]?un[e]?ment[%W]*[o]?[r]?[%W]*arena",
				"at[t]?un[e]?ment[%W]*[o]?[r]?[%W]*anger[f]?[g]?[o]?[r]?[g]?[e]?",
				"at[t]?un[e]?ment[%W]*[o]?[r]?[%W]*prison",
				"at[t]?un[e]?ment[%W]*[o]?[r]?[%W]*vault",
				"at[t]?un[e]?ment[%W]*[o]?[r]?[%W]*lava",
				"at[t]?un[e]?ment[%W]*[o]?[r]?[%W]*emp[r]?eror",
				"at[t]?un[e]?ment[%W]*[o]?[r]?[%W]*princes[s]?",
				"quest[s]?[%W]*[o]?[r]?[%W]*at[t]?un[e]?ment",
				"arena[%W]*[o]?[r]?[%W]*at[t]?un[e]?ment",
				"anger[f]?[g]?[o]?[r]?[g]?[e]?[%W]*[o]?[r]?[%W]*at[t]?un[e]?ment",
				"prison[%W]*[o]?[r]?[%W]*at[t]?un[e]?ment",
				"vault[%W]*[o]?[r]?[%W]*at[t]?un[e]?ment",
				"lava[%W]*[o]?[r]?[%W]*at[t]?un[e]?ment",
				"emp[r]?eror[%W]*[o]?[r]?[%W]*at[t]?un[e]?ment",
				"princes[s]?[%W]*[o]?[r]?[%W]*at[t]?un[e]?ment",
				"mar[r]?shal[l]?[%W]*win[d]?sor",
				"jail[%W]*br[e]?[a]?k[e]?",
				"attunement[%W]*to[%W]*the[%W]*core",
				"ony[i]?[x]?[i]?[e]?[a]?[%W]*at[t]?un[e]?ment",
				"ony[i]?[x]?[i]?[e]?[a]?[%W]*pre[%W]*q?[u]?[e]?[s]?[t]?[s]?",
				"molten[%W]*core[%W]*at[t]?un[e]?ment",
				"mc[%W]*at[t]?un[e]?ment",
				"molten[%W]*core[%W]*pre[%W]*q?[u]?[e]?[s]?[t]?[s]?",
				"mc[%W]*pre[%W]*q?[u]?[e]?[s]?[t]?[s]?",
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
				"black[%W]*rock[%W]*dep[t]?[h]?s[%W]*arena",
				"brd[%W]*arena",
				"arena[%W]*run[s]?",
				"arena[%W]*[o]?[r]?[%W]*quest[s]?",
				"arena[%W]*[o]?[r]?[%W]*at[t]?un[e]?ment",
				"arena[%W]*[o]?[r]?[%W]*anger[f]?[g]?[o]?[r]?[g]?[e]?",
				"arena[%W]*[o]?[r]?[%W]*prison",
				"arena[%W]*[o]?[r]?[%W]*vault",
				"arena[%W]*[o]?[r]?[%W]*lava",
				"arena[%W]*[o]?[r]?[%W]*emp[r]?eror",
				"arena[%W]*[o]?[r]?[%W]*princes[s]?",
				"quest[s]?[%W]*[o]?[r]?[%W]*arena",
				"at[t]?un[e]?ment[%W]*[o]?[r]?[%W]*arena",
				"anger[f]?[g]?[o]?[r]?[g]?[e]?[%W]*[o]?[r]?[%W]*arena",
				"prison[%W]*[o]?[r]?[%W]*arena",
				"vault[%W]*[o]?[r]?[%W]*arena",
				"lava[%W]*[o]?[r]?[%W]*arena",
				"emp[r]?eror[%W]*[o]?[r]?[%W]*arena",
				"princes[s]?[%W]*[o]?[r]?[%W]*arena",
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
				"black[%W]*rock[%W]*dep[t]?[h]?s[%W]*anger[f]?[g]?[o]?[r]?[g]?[e]?",
				"brd[%W]*anger[f]?[g]?[o]?[r]?[g]?[e]?",
				"anger[f]?[g]?[o]?[r]?[g]?[e]?[%W]*run[s]?",
				"anger[f]?[g]?[o]?[r]?[g]?[e]?[%W]*[o]?[r]?[%W]*quest[s]?",
				"anger[f]?[g]?[o]?[r]?[g]?[e]?[%W]*[o]?[r]?[%W]*at[t]?un[e]?ment",
				"anger[f]?[g]?[o]?[r]?[g]?[e]?[%W]*[o]?[r]?[%W]*arena",
				"anger[f]?[g]?[o]?[r]?[g]?[e]?[%W]*[o]?[r]?[%W]*prison",
				"anger[f]?[g]?[o]?[r]?[g]?[e]?[%W]*[o]?[r]?[%W]*vault",
				"anger[f]?[g]?[o]?[r]?[g]?[e]?[%W]*[o]?[r]?[%W]*lava",
				"anger[f]?[g]?[o]?[r]?[g]?[e]?[%W]*[o]?[r]?[%W]*emp[r]?eror",
				"anger[f]?[g]?[o]?[r]?[g]?[e]?[%W]*[o]?[r]?[%W]*princes[s]?",
				"quest[s]?[%W]*[o]?[r]?[%W]*anger[f]?[g]?[o]?[r]?[g]?[e]?",
				"at[t]?un[e]?ment[%W]*[o]?[r]?[%W]*anger[f]?[g]?[o]?[r]?[g]?[e]?",
				"arena[%W]*[o]?[r]?[%W]*anger[f]?[g]?[o]?[r]?[g]?[e]?",
				"prison[%W]*[o]?[r]?[%W]*anger[f]?[g]?[o]?[r]?[g]?[e]?",
				"vault[%W]*[o]?[r]?[%W]*anger[f]?[g]?[o]?[r]?[g]?[e]?",
				"lava[%W]*[o]?[r]?[%W]*anger[f]?[g]?[o]?[r]?[g]?[e]?",
				"emp[r]?eror[%W]*[o]?[r]?[%W]*anger[f]?[g]?[o]?[r]?[g]?[e]?",
				"princes[s]?[%W]*[o]?[r]?[%W]*anger[f]?[g]?[o]?[r]?[g]?[e]?",
			},
			ParentDungeon = 22,
			Size = 5,
			MinLevel = 52,
			MaxLevel = 60,
		},
		{
			Index = 27,
			Name = "Blackrock Depths - Prison Run",
			Abbreviation = "BRD Prison Run",
			Identifiers = {
				"black[%W]*rock[%W]*dep[t]?[h]?s[%W]*prison",
				"brd[%W]*prison",
				"prison[%W]*run[s]?",
				"prison[%W]*[o]?[r]?[%W]*quest[s]?",
				"prison[%W]*[o]?[r]?[%W]*at[t]?un[e]?ment",
				"prison[%W]*[o]?[r]?[%W]*arena",
				"prison[%W]*[o]?[r]?[%W]*anger[f]?[g]?[o]?[r]?[g]?[e]?",
				"prison[%W]*[o]?[r]?[%W]*vault",
				"prison[%W]*[o]?[r]?[%W]*lava",
				"prison[%W]*[o]?[r]?[%W]*emp[r]?eror",
				"prison[%W]*[o]?[r]?[%W]*princes[s]?",
				"quest[s]?[%W]*[o]?[r]?[%W]*prison",
				"at[t]?un[e]?ment[%W]*[o]?[r]?[%W]*prison",
				"arena[%W]*[o]?[r]?[%W]*prison",
				"anger[f]?[g]?[o]?[r]?[g]?[e]?[%W]*[o]?[r]?[%W]*prison",
				"vault[%W]*[o]?[r]?[%W]*prison",
				"lava[%W]*[o]?[r]?[%W]*prison",
				"emp[r]?eror[%W]*[o]?[r]?[%W]*prison",
				"princes[s]?[%W]*[o]?[r]?[%W]*prison",
			},
			ParentDungeon = 22,
			Size = 5,
			MinLevel = 52,
			MaxLevel = 60,
		},
		{
			Index = 28,
			Name = "Blackrock Depths - Vault Run",
			Abbreviation = "BRD Vault Run",
			Identifiers = {
				"black[%W]*rock[%W]*dep[t]?[h]?s[%W]*vault",
				"brd[%W]*vault",
				"vault[%W]*run[s]?",
				"vault[%W]*[o]?[r]?[%W]*quest[s]?",
				"vault[%W]*[o]?[r]?[%W]*at[t]?un[e]?ment",
				"vault[%W]*[o]?[r]?[%W]*arena",
				"vault[%W]*[o]?[r]?[%W]*anger[f]?[g]?[o]?[r]?[g]?[e]?",
				"vault[%W]*[o]?[r]?[%W]*prison",
				"vault[%W]*[o]?[r]?[%W]*lava",
				"vault[%W]*[o]?[r]?[%W]*emp[r]?eror",
				"vault[%W]*[o]?[r]?[%W]*princes[s]?",
				"quest[s]?[%W]*[o]?[r]?[%W]*vault",
				"at[t]?un[e]?ment[%W]*[o]?[r]?[%W]*vault",
				"arena[%W]*[o]?[r]?[%W]*vault",
				"anger[f]?[g]?[o]?[r]?[g]?[e]?[%W]*[o]?[r]?[%W]*vault",
				"prison[%W]*[o]?[r]?[%W]*vault",
				"lava[%W]*[o]?[r]?[%W]*vault",
				"emp[r]?eror[%W]*[o]?[r]?[%W]*vault",
				"princes[s]?[%W]*[o]?[r]?[%W]*vault",
			},
			ParentDungeon = 22,
			Size = 5,
			MinLevel = 52,
			MaxLevel = 60,
		},
		{
			Index = 29,
			Name = "Blackrock Depths - Lava Run",
			Abbreviation = "BRD Lava Run",
			Identifiers = {
				"black[%W]*rock[%W]*dep[t]?[h]?s[%W]*lava",
				"brd[%W]*lava",
				"lava[%W]*run[s]?",
				"lava[%W]*[o]?[r]?[%W]*quest[s]?",
				"lava[%W]*[o]?[r]?[%W]*at[t]?un[e]?ment",
				"lava[%W]*[o]?[r]?[%W]*arena",
				"lava[%W]*[o]?[r]?[%W]*anger[f]?[g]?[o]?[r]?[g]?[e]?",
				"lava[%W]*[o]?[r]?[%W]*prison",
				"lava[%W]*[o]?[r]?[%W]*vault",
				"lava[%W]*[o]?[r]?[%W]*emp[r]?eror",
				"lava[%W]*[o]?[r]?[%W]*princes[s]?",
				"quest[s]?[%W]*[o]?[r]?[%W]*lava",
				"at[t]?un[e]?ment[%W]*[o]?[r]?[%W]*lava",
				"arena[%W]*[o]?[r]?[%W]*lava",
				"anger[f]?[g]?[o]?[r]?[g]?[e]?[%W]*[o]?[r]?[%W]*lava",
				"prison[%W]*[o]?[r]?[%W]*lava",
				"vault[%W]*[o]?[r]?[%W]*lava",
				"emp[r]?eror[%W]*[o]?[r]?[%W]*lava",
				"princes[s]?[%W]*[o]?[r]?[%W]*lava",
			},
			ParentDungeon = 22,
			Size = 5,
			MinLevel = 52,
			MaxLevel = 60,
		},
		{
			Index = 30,
			Name = "Blackrock Depths - Emperor Run",
			Abbreviation = "BRD Emperor Run",
			Identifiers = {
				"black[%W]*rock[%W]*dep[t]?[h]?s[%W]*emp[r]?eror",
				"brd[%W]*emp[r]?eror",
				"emp[r]?eror[%W]*run[s]?",
				"emp[r]?eror[%W]*[o]?[r]?[%W]*quest[s]?",
				"emp[r]?eror[%W]*[o]?[r]?[%W]*at[t]?un[e]?ment",
				"emp[r]?eror[%W]*[o]?[r]?[%W]*arena",
				"emp[r]?eror[%W]*[o]?[r]?[%W]*anger[f]?[g]?[o]?[r]?[g]?[e]?",
				"emp[r]?eror[%W]*[o]?[r]?[%W]*prison",
				"emp[r]?eror[%W]*[o]?[r]?[%W]*vault",
				"emp[r]?eror[%W]*[o]?[r]?[%W]*lava",
				"emp[r]?eror[%W]*[o]?[r]?[%W]*princes[s]?",
				"quest[s]?[%W]*[o]?[r]?[%W]*emp[r]?eror",
				"at[t]?un[e]?ment[%W]*[o]?[r]?[%W]*emp[r]?eror",
				"arena[%W]*[o]?[r]?[%W]*emp[r]?eror",
				"anger[f]?[g]?[o]?[r]?[g]?[e]?[%W]*[o]?[r]?[%W]*emp[r]?eror",
				"prison[%W]*[o]?[r]?[%W]*emp[r]?eror",
				"vault[%W]*[o]?[r]?[%W]*emp[r]?eror",
				"lava[%W]*[o]?[r]?[%W]*emp[r]?eror",
				"princes[s]?[%W]*[o]?[r]?[%W]*emp[r]?eror",
			},
			ParentDungeon = 22,
			Size = 5,
			MinLevel = 52,
			MaxLevel = 60,
		},
		{
			Index = 31,
			Name = "Blackrock Depths - Princess Run",
			Abbreviation = "BRD Princess Run",
			Identifiers = {
				"black[%W]*rock[%W]*dep[t]?[h]?s[%W]*princes[s]?",
				"brd[%W]*princes[s]?",
				"save[%W]*[t]?[h]?[e]?[%W]*princes[s]?",
				"rescue[%W]*[t]?[h]?[e]?[%W]*princes[s]?",
				"princes[s]?[%W]*[o]?[r]?[%W]*quest[s]?",
				"princes[s]?[%W]*[o]?[r]?[%W]*at[t]?un[e]?ment",
				"princes[s]?[%W]*[o]?[r]?[%W]*arena",
				"princes[s]?[%W]*[o]?[r]?[%W]*anger[f]?[g]?[o]?[r]?[g]?[e]?",
				"princes[s]?[%W]*[o]?[r]?[%W]*prison",
				"princes[s]?[%W]*[o]?[r]?[%W]*vault",
				"princes[s]?[%W]*[o]?[r]?[%W]*lava",
				"princes[s]?[%W]*[o]?[r]?[%W]*emp[r]?eror",
				"quest[s]?[%W]*[o]?[r]?[%W]*princes[s]?",
				"at[t]?un[e]?ment[%W]*[o]?[r]?[%W]*princes[s]?",
				"arena[%W]*[o]?[r]?[%W]*princes[s]?",
				"anger[f]?[g]?[o]?[r]?[g]?[e]?[%W]*[o]?[r]?[%W]*princes[s]?",
				"prison[%W]*[o]?[r]?[%W]*princes[s]?",
				"vault[%W]*[o]?[r]?[%W]*princes[s]?",
				"lava[%W]*[o]?[r]?[%W]*princes[s]?",
				"emp[r]?eror[%W]*[o]?[r]?[%W]*princes[s]?",
			},
			ParentDungeon = 22,
			Size = 5,
			MinLevel = 52,
			MaxLevel = 60,
		},
		{
			Index = 32,
			Name = "Lower Blackrock Spire",
			Abbreviation = "LBRS",
			Identifiers = {
				"lower[%W]*black[%W]*rock[%W]*spire",
				"lower[%W]*brs",
				"lb[r]?s",
			},
			Size = 5,
			MinLevel = 55,
			MaxLevel = 60,
		},
		{
			Index = 33,
			Name = "Upper Blackrock Spire",
			Abbreviation = "UBRS",
			Identifiers = {
				"upper[%W]*black[%W]*rock[%W]*spire",
				"upper[%W]*brs",
				"ub[r]?s",
				"rend[%W]*run[s]?",
				"jed[%W]*rend",
			},
			Size = 10,
			MinLevel = 58,
			MaxLevel = 60,
		},
		{
			Index = 34,
			Name = "Scholomance",
			Abbreviation = "Scholo",
			Identifiers = {
				"s[c]?[h]?ol[o]?[l]?[o]?man[c]?[s]?e",
				"sc[h]?olo",
				"s[c]?holo",
			},
			Size = 5,
			MinLevel = 58,
			MaxLevel = 60,
		},
		{
			Index = 35,
			Name = "Stratholme",
			Abbreviation = "Strat",
			Identifiers = {
				"st[a]?r[a]?t[h]?olme",
				"strat[h]?",
				"starth",
			},
			SubDungeons = { 36, 37 },
			Size = 5,
			MinLevel = 58,
			MaxLevel = 60,
		},
		{
			Index = 36,
			Name = "Stratholme - Living Side",
			Abbreviation = "Strat Living",
			Identifiers = {
				"st[a]?r[a]?t[h]?olme[%W]*[a]?liv[e]?[i]?[n]?[g]?",
				"st[a]?r[a]?t[h]?[%W]*[a]?liv[e]?[i]?[n]?[g]?",
			},
			ParentDungeon = 35,
			Size = 5,
			MinLevel = 58,
			MaxLevel = 60
		},
		{
			Index = 37,
			Name = "Stratholme - Undead Side",
			Abbreviation = "Strat Undead",
			Identifiers = {
				"st[a]?r[a]?t[h]?olme[%W]*ud",
				"st[a]?r[a]?t[h]?[%W]*ud",
				"st[a]?r[a]?t[h]?olme[%W]*[u]?[n]?dead",
				"st[a]?r[a]?t[h]?[%W]*[u]?[n]?dead",
			},
			ParentDungeon = 35,
			Size = 5,
			MinLevel = 58,
			MaxLevel = 60
		},
		{
			Index = 38,
			Name = "Dire Maul",
			Abbreviation = "DM",
			Identifiers = {
				"dire[%W]*maul",
				"dim",
			},
			SubDungeons = { 39, 40, 41, 42 },
			Size = 5,
			MinLevel = 58,
			MaxLevel = 60
		},
		{
			Index = 39,
			Name = "Dire Maul - East",
			Abbreviation = "DM East",
			Identifiers = {
				"d[i]?m[%W]*e",
				"d[i]?m[%W]*east",
				"dire[%W]*maul[%W]*e",
				"dire[%W]*maul[%W]*east",
				"d[i]?m[.]*w[%W]*[o]?[r]?[%W]*e",
				"d[i]?m[.]*n[%W]*[o]?[r]?[%W]*e",
				"d[i]?m[.]*t[%W]*[o]?[r]?[%W]*e",
				"d[i]?m[.]*trib[u]?[t]?[e]?[%W]*[o]?[r]?[%W]*e",
				"d[i]?m[.]*e[%W]*[o]?[r]?[%W]*w",
				"d[i]?m[.]*e[%W]*[o]?[r]?[%W]*n",
				"d[i]?m[.]*e[%W]*[o]?[r]?[%W]*t",
				"d[i]?m[.]*e[%W]*[o]?[r]?[%W]*trib[u]?[t]?[e]?",
				"dire[%W]*maul[.]*w[%W]*[o]?[r]?[%W]*e",
				"dire[%W]*maul[.]*n[%W]*[o]?[r]?[%W]*e",
				"dire[%W]*maul[.]*t[%W]*[o]?[r]?[%W]*e",
				"dire[%W]*maul[.]*trib[u]?[t]?[e]?[%W]*[o]?[r]?[%W]*e",
				"dire[%W]*maul[.]*e[%W]*[o]?[r]?[%W]*w",
				"dire[%W]*maul[.]*e[%W]*[o]?[r]?[%W]*n",
				"dire[%W]*maul[.]*e[%W]*[o]?[r]?[%W]*t",
				"dire[%W]*maul[.]*e[%W]*[o]?[r]?[%W]*trib[u]?[t]?[e]?",
				"west[%W]*[o]?[r]?[%W]*east",
				"north[%W]*[o]?[r]?[%W]*east",
				"trib[u]?[t]?[e]?[%W]*[o]?[r]?[%W]*east",
				"east[%W]*[o]?[r]?[%W]*west",
				"east[%W]*[o]?[r]?[%W]*north",
				"east[%W]*[o]?[r]?[%W]*trib[u]?[t]?[e]?",
			},
			ParentDungeon = 38,
			Size = 5,
			MinLevel = 58,
			MaxLevel = 60
		},
		{
			Index = 40,
			Name = "Dire Maul - West",
			Abbreviation = "DM West",
			Identifiers = {
				"d[i]?m[%W]*w",
				"d[i]?m[%W]*west",
				"dire[%W]*maul[%W]*w",
				"dire[%W]*maul[%W]*west",
				"d[i]?m[.]*e[%W]*[o]?[r]?[%W]*w",
				"d[i]?m[.]*n[%W]*[o]?[r]?[%W]*w",
				"d[i]?m[.]*t[%W]*[o]?[r]?[%W]*w",
				"d[i]?m[.]*trib[u]?[t]?[e]?[%W]*[o]?[r]?[%W]*w",
				"d[i]?m[.]*w[%W]*[o]?[r]?[%W]*e",
				"d[i]?m[.]*w[%W]*[o]?[r]?[%W]*n",
				"d[i]?m[.]*w[%W]*[o]?[r]?[%W]*t",
				"d[i]?m[.]*w[%W]*[o]?[r]?[%W]*trib[u]?[t]?[e]?",
				"dire[%W]*maul[.]*e[%W]*[o]?[r]?[%W]*w",
				"dire[%W]*maul[.]*n[%W]*[o]?[r]?[%W]*w",
				"dire[%W]*maul[.]*t[%W]*[o]?[r]?[%W]*w",
				"dire[%W]*maul[.]*trib[u]?[t]?[e]?[%W]*[o]?[r]?[%W]*w",
				"dire[%W]*maul[.]*w[%W]*[o]?[r]?[%W]*e",
				"dire[%W]*maul[.]*w[%W]*[o]?[r]?[%W]*n",
				"dire[%W]*maul[.]*w[%W]*[o]?[r]?[%W]*t",
				"dire[%W]*maul[.]*w[%W]*[o]?[r]?[%W]*trib[u]?[t]?[e]?",
				"east[%W]*[o]?[r]?[%W]*west",
				"north[%W]*[o]?[r]?[%W]*west",
				"trib[u]?[t]?[e]?[%W]*[o]?[r]?[%W]*west",
				"west[%W]*[o]?[r]?[%W]*east",
				"west[%W]*[o]?[r]?[%W]*north",
				"west[%W]*[o]?[r]?[%W]*trib[u]?[t]?[e]?",
			},
			ParentDungeon = 38,
			Size = 5,
			MinLevel = 58,
			MaxLevel = 60
		},
		{
			Index = 41,
			Name = "Dire Maul - North",
			Abbreviation = "DM North",
			Identifiers = {
				"d[i]?m[%W]*n",
				"d[i]?m[%W]*north",
				"dire[%W]*maul[%W]*n",
				"dire[%W]*maul[%W]*north",
				"d[i]?m[.]*e[%W]*[o]?[r]?[%W]*n",
				"d[i]?m[.]*w[%W]*[o]?[r]?[%W]*n",
				"d[i]?m[.]*t[%W]*[o]?[r]?[%W]*n",
				"d[i]?m[.]*trib[u]?[t]?[e]?[%W]*[o]?[r]?[%W]*n",
				"d[i]?m[.]*n[%W]*[o]?[r]?[%W]*e",
				"d[i]?m[.]*n[%W]*[o]?[r]?[%W]*w",
				"d[i]?m[.]*n[%W]*[o]?[r]?[%W]*t",
				"d[i]?m[.]*n[%W]*[o]?[r]?[%W]*trib[u]?[t]?[e]?",
				"dire[%W]*maul[.]*e[%W]*[o]?[r]?[%W]*n",
				"dire[%W]*maul[.]*w[%W]*[o]?[r]?[%W]*n",
				"dire[%W]*maul[.]*t[%W]*[o]?[r]?[%W]*n",
				"dire[%W]*maul[.]*trib[u]?[t]?[e]?[%W]*[o]?[r]?[%W]*n",
				"dire[%W]*maul[.]*n[%W]*[o]?[r]?[%W]*e",
				"dire[%W]*maul[.]*n[%W]*[o]?[r]?[%W]*w",
				"dire[%W]*maul[.]*n[%W]*[o]?[r]?[%W]*t",
				"dire[%W]*maul[.]*n[%W]*[o]?[r]?[%W]*trib[u]?[t]?[e]?",
				"east[%W]*[o]?[r]?[%W]*north",
				"west[%W]*[o]?[r]?[%W]*north",
				"trib[u]?[t]?[e]?[%W]*[o]?[r]?[%W]*north",
				"north[%W]*[o]?[r]?[%W]*east",
				"north[%W]*[o]?[r]?[%W]*west",
				"north[%W]*[o]?[r]?[%W]*trib[u]?[t]?[e]?",
			},
			ParentDungeon = 38,
			Size = 5,
			MinLevel = 58,
			MaxLevel = 60
		},
		{
			Index = 42,
			Name = "Dire Maul - Tribute Run",
			Abbreviation = "DM Tribute Run",
			Identifiers = {
				"d[i]?m[%W]*t",
				"d[i]?m[%W]*trib[u]?[t]?[e]?",
				"dire[%W]*maul[%W]*t",
				"dire[%W]*maul[%W]*trib[u]?[t]?[e]?",
				"tribute[%W]*run",
				"d[i]?m[.]*e[%W]*[o]?[r]?[%W]*t",
				"d[i]?m[.]*w[%W]*[o]?[r]?[%W]*t",
				"d[i]?m[.]*n[%W]*[o]?[r]?[%W]*t",
				"d[i]?m[.]*t[%W]*[o]?[r]?[%W]*e",
				"d[i]?m[.]*t[%W]*[o]?[r]?[%W]*w",
				"d[i]?m[.]*t[%W]*[o]?[r]?[%W]*n",
				"d[i]?m[.]*e[%W]*[o]?[r]?[%W]*trib[u]?[t]?[e]?",
				"d[i]?m[.]*w[%W]*[o]?[r]?[%W]*trib[u]?[t]?[e]?",
				"d[i]?m[.]*n[%W]*[o]?[r]?[%W]*trib[u]?[t]?[e]?",
				"d[i]?m[.]*trib[u]?[t]?[e]?[%W]*[o]?[r]?[%W]*e",
				"d[i]?m[.]*trib[u]?[t]?[e]?[%W]*[o]?[r]?[%W]*w",
				"d[i]?m[.]*trib[u]?[t]?[e]?[%W]*[o]?[r]?[%W]*n",
				"dire[%W]*maul[.]*e[%W]*[o]?[r]?[%W]*t",
				"dire[%W]*maul[.]*w[%W]*[o]?[r]?[%W]*t",
				"dire[%W]*maul[.]*n[%W]*[o]?[r]?[%W]*t",
				"dire[%W]*maul[.]*t[%W]*[o]?[r]?[%W]*e",
				"dire[%W]*maul[.]*t[%W]*[o]?[r]?[%W]*w",
				"dire[%W]*maul[.]*t[%W]*[o]?[r]?[%W]*n",
				"dire[%W]*maul[.]*e[%W]*[o]?[r]?[%W]*trib[u]?[t]?[e]?",
				"dire[%W]*maul[.]*w[%W]*[o]?[r]?[%W]*trib[u]?[t]?[e]?",
				"dire[%W]*maul[.]*n[%W]*[o]?[r]?[%W]*trib[u]?[t]?[e]?",
				"dire[%W]*maul[.]*trib[u]?[t]?[e]?[%W]*[o]?[r]?[%W]*e",
				"dire[%W]*maul[.]*trib[u]?[t]?[e]?[%W]*[o]?[r]?[%W]*w",
				"dire[%W]*maul[.]*trib[u]?[t]?[e]?[%W]*[o]?[r]?[%W]*n",
				"east[%W]*[o]?[r]?[%W]*trib[u]?[t]?[e]?",
				"west[%W]*[o]?[r]?[%W]*trib[u]?[t]?[e]?",
				"north[%W]*[o]?[r]?[%W]*trib[u]?[t]?[e]?",
				"trib[u]?[t]?[e]?[%W]*[o]?[r]?[%W]*east",
				"trib[u]?[t]?[e]?[%W]*[o]?[r]?[%W]*west",
				"trib[u]?[t]?[e]?[%W]*[o]?[r]?[%W]*north",
			},
			ParentDungeon = 38,
			Size = 5,
			MinLevel = 58,
			MaxLevel = 60
		},
		{
			Index = 43,
			Name = "Molten Core",
			Abbreviation = "MC",
			Identifiers = {
				"molten[%W]*core",
				"mc",
				"mc[%W]*[%d]*[%W]*[%d]*[%W]*",
			},
			NotIdentifiers = {
				"molten[%W]*core[%W]*at[t]?un[e]?ment",
				"mc[%W]*at[t]?un[e]?ment",
				"molten[%W]*core[%W]*pre[%W]*q?[u]?[e]?[s]?[t]?[s]?",
				"mc[%W]*pre[%W]*q?[u]?[e]?[s]?[t]?[s]?",
			},
			Size = 40,
			MinLevel = 60,
			MaxLevel = 60,
		},
		{
			Index = 44,
			Name = "Onyxia's Lair",
			Abbreviation = "Onyxia",
			Identifiers = {
				"ony[i]?x[i]?[e]?[a]?",
				"ony[x]?"
			},
			NotIdentifiers = {
				"ony[i]?[x]?[i]?[e]?[a]?[%W]*at[t]?un[e]?ment",
				"ony[i]?[x]?[i]?[e]?[a]?[%W]*pre[%W]*q?[u]?[e]?[s]?[t]?[s]?",
			},
			Size = 40,
			MinLevel = 60,
			MaxLevel = 60,
		},
		{
			Index = 45,
			Name = "Warsong Gulch",
			Abbreviation = "WSG",
			Identifiers = {
				"war[%W]*song[%W]*gulch",
				"wsg",
			},
			Size = 10,
			MinLevel = 10,
			MaxLevel = 60,
			Pvp = true
		},
		{
			Index = 46,
			Name = "Alterac Valley",
			Abbreviation = "AV",
			Identifiers = {
				"alterac[%W]*val[l]?ey",
				"av",
			},
			Size = 40,
			MinLevel = 51,
			MaxLevel = 60,
			Pvp = true
		},
		-- {
			-- Index = 47,
			-- Name = "Arathi Basin",
			-- Abbreviation = "AB",
			-- Identifiers = {
				-- "arat[h]?i[%W]*basin",
				-- "ab"
			-- },
			-- Size = 15,
			-- MinLevel = 20,
			-- MaxLevel = 60,
			-- Pvp = true
		-- },
		-- {
			-- Index = 45,
			-- Name = "Blackwing Lair",
			-- Abbreviation = "BWL",
			-- Identifiers = {
				-- "blackwing[%W]*lair",
				-- "bwl"
			-- },
			-- Size = 40,
			-- MinLevel = 60,
			-- MaxLevel = 60,
			-- Hide = true,
		-- },
		-- {
			-- Index = 46,
			-- Name = "Zul'Gurub",
			-- Abbreviation = "ZG",
			-- Identifiers = {
				-- "zul[%W]*g[u]?rub",
				-- "zg"
			-- },
			-- Size = 20,
			-- MinLevel = 60,
			-- MaxLevel = 60,
			-- Hide = true,
		-- },
		-- {
			-- Index = 47,
			-- Name = "Ruins of Ahn'Qiraj",
			-- Abbreviation = "AQ20",
			-- Identifiers = {
				-- "ruin[s]?[%W]*[o]?[f]?[%W]*ahn[%W]*qiraj",
				-- "ahn[%W]*qiraj[%W]*ruin[s]?",
				-- "aq[%W]*ruin[s]?",
				-- "aq[%W]*20",
				-- "raq"
			-- },
			-- Size = 20,
			-- MinLevel = 60,
			-- MaxLevel = 60,
			-- Hide = true,
		-- },
		-- {
			-- Index = 48,
			-- Name = "Temple of Ahn'Qiraj",
			-- Abbreviation = "AQ40",
			-- Identifiers = {
				-- "temple[%W]*[o]?[f]?[%W]*ahn[%W]*qiraj",
				-- "ahn[%W]*qiraj[%W]*temple",
				-- "aq[%W]*temple",
				-- "aq[%W]*40",
				-- "taq"
			-- },
			-- Size = 40,
			-- MinLevel = 60,
			-- MaxLevel = 60,
			-- Hide = true,
		-- },
		-- {
			-- Index = 49,
			-- Name = "Naxxramas",
			-- Abbreviation = "Naxx",
			-- Identifiers = {
				-- "naxx[a]?ramas",
				-- "naxx"
			-- },
			-- Size = 40,
			-- MinLevel = 60,
			-- MaxLevel = 60,
			-- Hide = true,
		-- }
	},
	DUNGEONS_FALLBACK = {
		{
			Dungeons = { 3, 38 },
			Identifiers = { 
				"dm",
			}
		},
		{
			Dungeons = { 20, 31 },
			Identifiers = {
				"princes[s]?[%W]*run[s]?",
			}
		},
		-- {
			-- Dungeons = { 47, 48 },
			-- Identifiers = {
				-- "aq"
			-- }
		-- },
		{
			Dungeons = { 43, 44 },
			Identifiers = {
				"any[%W]*raid[s]?",
			}
		},
		{
			Dungeons = {},
			Identifiers = {
				"any[%W]*dungeon[s]?",
			}
		},
		{
			Dungeons = { 45, 46 },
			Identifiers = {
				"pvp",
				"premade",
			}
		}
	}
}


-- Add all dungeons to 'Any dungeon' fallback
for _,dungeon in ipairs(LFGMM_GLOBAL.DUNGEONS) do
	table.insert(LFGMM_GLOBAL.DUNGEONS_FALLBACK[4].Dungeons, dungeon.Index);
end

