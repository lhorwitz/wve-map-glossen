------------------------------------------------------------------------------
--	FILE:	 West_vs_East.lua
--	AUTHOR:  Bob Thomas
--	PURPOSE: Regional map script - Designed to pit two teams against each other
--	         with a strip of water dividing the map east from west.
------------------------------------------------------------------------------
--	Copyright (c) 2010 Firaxis Games, Inc. All rights reserved.
------------------------------------------------------------------------------

include("DEFMapGeneratorW8");
include("DEFMultilayeredFractalW");
include("DEFFeatureGeneratorW");
include("DEFTerrainGeneratorW");

print("WvE Map (dev) script loaded");

local weeveeDbgHandle = nil;
local WEEVEE_DBG_PATHS = {
	"C:\\Users\\lucas\\OneDrive\\Documents\\My Games\\Sid Meier's Civilization 5\\Logs\\weevee_dbg.log",
	"C:\\Users\\bbruno\\Documents\\My Games\\Sid Meier's Civilization 5\\Logs\\weevee_dbg.log",
	"weevee_dbg.log",
};
function WeeveeDbgOpen(mode)
	if weeveeDbgHandle ~= nil then
		weeveeDbgHandle:close();
		weeveeDbgHandle = nil;
	end
	if io == nil or io.open == nil then
		return
	end
	local i = 1;
	while i <= #WEEVEE_DBG_PATHS do
		local f = io.open(WEEVEE_DBG_PATHS[i], mode);
		if f ~= nil then
			weeveeDbgHandle = f;
			return
		end
		i = i + 1;
	end
end
function WeeveeDbg(msg)
	local line = tostring(msg);
	if weeveeDbgHandle == nil then
		WeeveeDbgOpen("a");
	end
	if weeveeDbgHandle ~= nil then
		weeveeDbgHandle:write(line);
		weeveeDbgHandle:write("\n");
		weeveeDbgHandle:flush();
	end
end
function WeeveeDbgReset()
	WeeveeDbgOpen("w");
	WeeveeDbg("weevee dbg start");
end
function WeeveeDbgCall(name, fn, a1, a2, a3, a4, a5)
	WeeveeDbg("enter " .. name);
	local ok, err = pcall(fn, a1, a2, a3, a4, a5);
	if ok then
		WeeveeDbg("exit " .. name);
	else
		WeeveeDbg("ERR " .. name .. " " .. tostring(err));
	end
end
WeeveeDbg("script loaded (dev)");

local OPT_CENTER_SPLIT = 1;
local OPT_SNOW_BARRIER = 2;
local OPT_WRAP = 3;
local OPT_FRONT_MOUNTAIN = 4;
local OPT_CANVAS_SHRINK = 5;
local OPT_EXPLO_BALANCE = 6;
local OPT_LAKES = 7;
local CANVAS_SHRINK_NO = 1;
local CANVAS_SHRINK_YES = 2;
local EXPLO_BALANCE_NO = 1;
local EXPLO_BALANCE_YES = 2;
local LAKES_LOW = 1;
local LAKES_MEDIUM = 2;
local LAKES_HIGH = 3;
local SPLIT_SNOW = 1;
local SPLIT_SNOW_V2 = 2;
local SPLIT_WETLAND = 3;
local SPLIT_DESERT = 4;
local SPLIT_WASTELAND = 5;
local SPLIT_PEAKS = 6;
local SPLIT_FROSTY = 7;
local SPLIT_SHORES = 8;
local SPLIT_RANDOM = 9;
local WRAP_NO = 1;
local WRAP_YES = 2;
local WRAP_RANDOM = 3;
local DEF_WORLD_AGE = 2;
local DEF_TEMPERATURE = 2;
local DEF_RAINFALL = 2;
local DEF_RESOURCES = 4;
local DEF_TEAM = 1;
local DEF_FRONTLINE = 7;
local DEF_BACK = 7;
local DEF_MIRRORED = 1;
local DEF_TOPBOTTOM = 7;
local DEF_NATURAL_WONDERS = 16;
local mireBand = {};
local peakDist = {};
local peakNX = {};
local peakNY = {};
local peakMassif = {};
local peakHillStyle = {};
local peakHillT1 = {};
local peakHillT2 = {};
local peakHillT3 = {};
local peakForestStyle = {};
local nPeakMassifs = 0;
local riverEdgeList = {};

------------------------------------------------------------------------------
function GetResourceSetting()
	return DEF_RESOURCES;
end
------------------------------------------------------------------------------
function GetMapScriptInfo()
	return {
		Name = "[COLOR_HIGHLIGHT_TEXT] WvE Map (dev) [ENDCOLOR]",
		Description = "",
		SupportsMultiplayer = true,
		IconIndex = 18,
		CustomOptions = {
			{
				Name = "[COLOR_HIGHLIGHT_TEXT]Climate[ENDCOLOR]",
				Values = {
					"[COLOR_HIGHLIGHT_TEXT]Snow (Legacy)[ENDCOLOR]",
					"[COLOR_HIGHLIGHT_TEXT]Standard[ENDCOLOR]",
					"[COLOR_HIGHLIGHT_TEXT]Murky[ENDCOLOR]",
					"[COLOR_HIGHLIGHT_TEXT]Oasis[ENDCOLOR]",
					"[COLOR_HIGHLIGHT_TEXT]Wasteland[ENDCOLOR]",
					"[COLOR_HIGHLIGHT_TEXT]Peaky[ENDCOLOR]",
					"[COLOR_HIGHLIGHT_TEXT]Frosty[ENDCOLOR]",
					"[COLOR_HIGHLIGHT_TEXT]Shores[ENDCOLOR]",
					"[COLOR_HIGHLIGHT_TEXT][ICON_CAPITAL] Random (sans Snow)[ENDCOLOR]"
				},
				DefaultValue = 9,
				SortPriority = -99,
			},
			{
				Name = "[COLOR_HIGHLIGHT_TEXT]Barrier Width[ENDCOLOR]",
				Values = {
					"[COLOR_HIGHLIGHT_TEXT]0[ENDCOLOR]",
					"[COLOR_HIGHLIGHT_TEXT]2[ENDCOLOR]",
					"[COLOR_HIGHLIGHT_TEXT][ICON_CAPITAL] 4[ENDCOLOR]",
					"[COLOR_HIGHLIGHT_TEXT]6[ENDCOLOR]",
					"[COLOR_HIGHLIGHT_TEXT]Random (2-6)[ENDCOLOR]",
				},
				DefaultValue = 3,
				SortPriority = -98,
			},
			{
				Name = "[COLOR_HIGHLIGHT_TEXT]World Wrap[ENDCOLOR]",
				Values = {
					"[COLOR_HIGHLIGHT_TEXT]No wrap[ENDCOLOR]",
					"[COLOR_HIGHLIGHT_TEXT][ICON_CAPITAL] Wrap[ENDCOLOR]",
					"[COLOR_HIGHLIGHT_TEXT]Random[ENDCOLOR]",
				},
				DefaultValue = 2,
				SortPriority = -97,
			},
			{
				Name = "[COLOR_HIGHLIGHT_TEXT]Front Mountain %[ENDCOLOR]",
				Values = {
					"[COLOR_HIGHLIGHT_TEXT]20%[ENDCOLOR]",
					"[COLOR_HIGHLIGHT_TEXT][ICON_CAPITAL] 25%[ENDCOLOR]",
					"[COLOR_HIGHLIGHT_TEXT]30%[ENDCOLOR]",
					"[COLOR_HIGHLIGHT_TEXT]35%[ENDCOLOR]",
					"[COLOR_HIGHLIGHT_TEXT]40%[ENDCOLOR]",
					"[COLOR_HIGHLIGHT_TEXT]45%[ENDCOLOR]",
					"[COLOR_HIGHLIGHT_TEXT]50%[ENDCOLOR]",
				},
				DefaultValue = 2,
				SortPriority = -96,
			},
			{
				Name = "[COLOR_HIGHLIGHT_TEXT]Canvas Shrink[ENDCOLOR]",
				Values = {
					"[COLOR_HIGHLIGHT_TEXT][ICON_CAPITAL] No[ENDCOLOR]",
					"[COLOR_HIGHLIGHT_TEXT]Yes[ENDCOLOR]",
				},
				DefaultValue = 1,
				SortPriority = -95,
			},
			{
				Name = "[COLOR_HIGHLIGHT_TEXT]Explo Balance[ENDCOLOR]",
				Values = {
					"[COLOR_HIGHLIGHT_TEXT][ICON_CAPITAL] No[ENDCOLOR]",
					"[COLOR_HIGHLIGHT_TEXT]Yes[ENDCOLOR]",
				},
				DefaultValue = 1,
				SortPriority = -94,
			},
			{
				Name = "[COLOR_HIGHLIGHT_TEXT]Lakes[ENDCOLOR]",
				Values = {
					"[COLOR_HIGHLIGHT_TEXT]Low[ENDCOLOR]",
					"[COLOR_HIGHLIGHT_TEXT][ICON_CAPITAL] Medium[ENDCOLOR]",
					"[COLOR_HIGHLIGHT_TEXT]High[ENDCOLOR]",
				},
				DefaultValue = 2,
				SortPriority = -93,
			},
		},
	}
end
------------------------------------------------------------------------------
------------------------------------------------------------------------------
local barrierSplitResolved = false;
local barrierSplit = SPLIT_SNOW;
function ResolveBarrierSplit()
	if barrierSplitResolved then
		return barrierSplit;
	end
	barrierSplitResolved = true;
	local ops = Map.GetCustomOption(OPT_CENTER_SPLIT);
	if ops == SPLIT_RANDOM then
		-- Explicit list: the roll no longer depends on these constants staying
		-- adjacent, and Shores is deliberately excluded - it is a different
		-- shape of map rather than a climate reskin.
		local pool = { SPLIT_SNOW_V2, SPLIT_WETLAND, SPLIT_DESERT, SPLIT_WASTELAND, SPLIT_PEAKS, SPLIT_FROSTY };
		barrierSplit = pool[1 + Map.Rand(#pool, "Barrier Terrain Random")];
		print("Barrier Terrain random:", barrierSplit);
	else
		barrierSplit = ops;
	end
	return barrierSplit;
end
------------------------------------------------------------------------------
local barrierWrapResolved = false;
local barrierWrap = false;
function ResolveWrap()
	if barrierWrapResolved then
		return barrierWrap;
	end
	barrierWrapResolved = true;
	if ResolveBarrierSplit() == SPLIT_SNOW then
		barrierWrap = false;
		print("Barrier wrap: ignored (legacy snow)");
		return barrierWrap;
	end
	if ResolveBarrierSplit() == SPLIT_SHORES then
		-- A wrap seam would put a second barrier where Shores needs open ocean.
		barrierWrap = false;
		print("Barrier wrap: ignored (shores)");
		return barrierWrap;
	end
	local ops = Map.GetCustomOption(OPT_WRAP);
	if ops == WRAP_RANDOM then
		barrierWrap = (Map.Rand(2, "Barrier Wrap Random") == 1);
		print("Barrier wrap random:", barrierWrap);
	else
		barrierWrap = (ops == WRAP_YES);
	end
	return barrierWrap;
end
------------------------------------------------------------------------------
function GetBarrierConfig()
	local ops = ResolveBarrierSplit();
	local wrap = ResolveWrap();
	if ops == SPLIT_SNOW_V2 then
		return {
			kind = "snow",
			wrap = wrap,
			mountainPct = 2,
			hillPct = 19,
			iceLakePermille = 2,
			forestPct = 10,
			oasisPctOfFlat = 0,
			chaoticMountains = false,
		};
	end
	if ops == SPLIT_DESERT then
		return {
			kind = "desert",
			wrap = wrap,
			mountainPct = 5,
			hillPct = 20,
			iceLakePermille = 0,
			forestPct = 2,
			oasisPctOfFlat = 5,
			chaoticMountains = true,
		};
	end
	if ops == SPLIT_WASTELAND then
		return {
			kind = "wasteland",
			wrap = wrap,
			mountainPct = 8,
			hillPct = 20,
			iceLakePermille = 0,
			forestPct = 0,
			oasisPctOfFlat = 0,
			chaoticMountains = true,
			falloutBarrierPct = 30,
			falloutPlayableNearPct = 6,
			falloutPlayableFarPct = 18,
		};
	end
	if ops == SPLIT_WETLAND then
		return {
			kind = "wetland",
			wrap = wrap,
			mountainPct = 8,
			hillPct = 20,
			iceLakePermille = 0,
			forestPct = 0,
			oasisPctOfFlat = 0,
			chaoticMountains = true,
			marshBarrierPct = 28,
			jungleBarrierPct = 0,
			forestBarrierPct = 22,
		};
	end
	if ops == SPLIT_PEAKS then
		return {
			kind = "peaks",
			wrap = wrap,
			mountainPct = 8,
			hillPct = 20,
			iceLakePermille = 0,
			forestPct = 0,
			oasisPctOfFlat = 0,
			chaoticMountains = false,
		};
	end
	if ops == SPLIT_FROSTY then
		return {
			kind = "frosty",
			wrap = wrap,
			mountainPct = 2,
			hillPct = 19,
			iceLakePermille = 0,
			forestPct = 10,
			oasisPctOfFlat = 0,
			chaoticMountains = true,
		};
	end
	if ops == SPLIT_SHORES then
		return {
			kind = "shores",
			wrap = false,
			mountainPct = 2,
			hillPct = 19,
			iceLakePermille = 0,
			forestPct = 10,
			oasisPctOfFlat = 0,
			chaoticMountains = false,
			bandWidth = 5,
			dryMargin = 2,
			islandSizeMin = 14,
			islandSizeMax = 22,
			islandStartMin = 14,
			islandGapMax = 4,
			coreMin = 3,
			coreMax = 6,
			armLenMin = 2,
			armLenMax = 3,
			islandHillPct = 34,
			lakeAtollPct = 35,
			lakeMaxPerIsland = 1,
			luxWaterDist = 3,
			isletStrategicPct = 60,
			islandResourcePct = 48,
		};
	end
	return nil;
end
------------------------------------------------------------------------------
function BarrierTerrainType(cfg)
	if cfg.kind == "desert" then
		return TerrainTypes.TERRAIN_DESERT;
	end
	if cfg.kind == "wasteland" then
		return TerrainTypes.TERRAIN_TUNDRA;
	end
	if cfg.kind == "wetland" then
		return TerrainTypes.TERRAIN_GRASS;
	end
	if cfg.kind == "peaks" then
		return TerrainTypes.TERRAIN_PLAINS;
	end
	if cfg.kind == "frosty" then
		return TerrainTypes.TERRAIN_TUNDRA;
	end
	return TerrainTypes.TERRAIN_SNOW;
end
------------------------------------------------------------------------------
function BarrierTransitionType(cfg)
	if cfg.kind == "wasteland" then
		return TerrainTypes.TERRAIN_DESERT;
	end
	if cfg.kind == "wetland" then
		return TerrainTypes.TERRAIN_DESERT;
	end
	if cfg.kind == "frosty" then
		return TerrainTypes.TERRAIN_DESERT;
	end
	return TerrainTypes.TERRAIN_TUNDRA;
end
------------------------------------------------------------------------------
function IsSnowWrapX()
	local cfg = GetBarrierConfig();
	return cfg ~= nil and cfg.wrap == true;
end
------------------------------------------------------------------------------
function IsSnowNoWrap()
	local cfg = GetBarrierConfig();
	return cfg ~= nil and cfg.wrap == false;
end
------------------------------------------------------------------------------
function IsExploBalance()
	if Map.GetCustomOption(OPT_EXPLO_BALANCE) ~= EXPLO_BALANCE_YES then
		return false
	end
	if IsShores() then
		-- Shores sets its own coastline; the explo reshape would fight it.
		return false
	end
	return IsSnowNoWrap();
end
------------------------------------------------------------------------------
function UsesExploCoastShape()
	if IsExploBalance() then
		return true
	end
	local cfg = GetBarrierConfig();
	return cfg ~= nil and cfg.kind == "frosty" and IsSnowNoWrap();
end
------------------------------------------------------------------------------
local exploPlanResolved = false;
local exploCutPct = 0;
local exploInlandSeas = 0;
function ResolveExploBackCoastPlan()
	if exploPlanResolved then
		return exploCutPct, exploInlandSeas;
	end
	exploPlanResolved = true;
	if UsesExploCoastShape() == false then
		return exploCutPct, exploInlandSeas;
	end
	if Map.Rand(2, "Explo back coast plan") == 0 then
		exploCutPct = 50;
		exploInlandSeas = 2;
	else
		exploCutPct = 25;
		exploInlandSeas = 1;
	end
	print("Explo plan: cut", exploCutPct, "% back coast, inland seas", exploInlandSeas);
	return exploCutPct, exploInlandSeas;
end
------------------------------------------------------------------------------
local lakeRandResolved = false;
local lakeRand = 80;
function ResolveLakeRand()
	if lakeRandResolved then
		return lakeRand;
	end
	lakeRandResolved = true;
	local ops = Map.GetCustomOption(OPT_LAKES);
	if ops == LAKES_LOW then
		lakeRand = 90;
	elseif ops == LAKES_HIGH then
		lakeRand = 68;
	else
		lakeRand = 80;
	end
	print("Lake chance: 1 in", lakeRand, "per eligible tile");
	return lakeRand;
end
------------------------------------------------------------------------------
function IsOldSnow()
	return ResolveBarrierSplit() == SPLIT_SNOW;
end
------------------------------------------------------------------------------
function IsShores()
	return ResolveBarrierSplit() == SPLIT_SHORES;
end
------------------------------------------------------------------------------
function IsSnowBarrier()
	return GetBarrierConfig() ~= nil;
end
------------------------------------------------------------------------------
function GetSungodLuxuryIDs(asp)
	local ids = {};
	if asp.citrus_ID ~= nil then
		table.insert(ids, asp.citrus_ID);
	end
	if asp.cocoa_ID ~= nil then
		table.insert(ids, asp.cocoa_ID);
	end
	if asp.olives_ID ~= nil then
		table.insert(ids, asp.olives_ID);
	end
	local coconutID = GameInfoTypes["RESOURCE_COCONUT"];
	if coconutID ~= nil then
		table.insert(ids, coconutID);
	end
	return ids;
end
------------------------------------------------------------------------------
function IsSungodLuxuryID(asp, resID)
	if resID == nil then
		return false
	end
	local ids = GetSungodLuxuryIDs(asp);
	local i = 1;
	while i <= #ids do
		if ids[i] == resID then
			return true
		end
		i = i + 1;
	end
	return false
end
------------------------------------------------------------------------------
function WestHasSungodRegional(asp)
	local iW = Map.GetGridSize();
	local mid = iW * 0.5;
	local r = 1;
	while r <= asp.iNumCivs do
		local res = asp.region_luxury_assignment[r];
		if IsSungodLuxuryID(asp, res) then
			local start = asp.startingPlots[r];
			if start ~= nil and start[1] < mid then
				return true
			end
		end
		r = r + 1;
	end
	return false
end
------------------------------------------------------------------------------
function ApplyWastelandLuxuryWeights(self)
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "wasteland" then
		return
	end
	local tundra = {};
	local function add(id, w)
		if id ~= nil then
			table.insert(tundra, {id, w});
		end
	end
	add(self.fur_ID, 40);
	add(self.silver_ID, 40);
	add(self.amber_ID, 40);
	add(self.salt_ID, 40);
	add(self.gold_ID, 40);
	add(self.copper_ID, 40);
	add(self.gems_ID, 40);
	add(self.jade_ID, 40);
	add(self.lapis_ID, 40);
	add(self.whale_ID, 16);
	add(self.crab_ID, 16);
	self.luxury_region_weights[1] = tundra;
	local t = 2;
	while t <= 8 do
		local list = self.luxury_region_weights[t];
		if list ~= nil then
			if self.whale_ID ~= nil then
				table.insert(list, {self.whale_ID, 16});
			end
			if self.crab_ID ~= nil then
				table.insert(list, {self.crab_ID, 16});
			end
		end
		t = t + 1;
	end
end
------------------------------------------------------------------------------
function FrostyBannedLuxuryID(asp, id)
	if id == nil then
		return false
	end
	if id == asp.fur_ID then
		return true
	end
	if id == asp.olives_ID or id == asp.citrus_ID or id == asp.cocoa_ID then
		return true
	end
	if id == asp.truffles_ID or id == asp.ivory_ID then
		return true
	end
	local coconutID = GameInfoTypes["RESOURCE_COCONUT"];
	if coconutID ~= nil and id == coconutID then
		return true
	end
	return false
end
------------------------------------------------------------------------------
function ApplyFrostyLuxuryWeights(self)
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "frosty" then
		return
	end
	local t = 1;
	while t <= 8 do
		local src = self.luxury_region_weights[t];
		if src ~= nil then
			local out = {};
			local i = 1;
			while i <= #src do
				if FrostyBannedLuxuryID(self, src[i][1]) == false then
					table.insert(out, src[i]);
				end
				i = i + 1;
			end
			self.luxury_region_weights[t] = out;
		end
		t = t + 1;
	end
	local tundra = {};
	local function add(id, w)
		if id ~= nil then
			table.insert(tundra, {id, w});
		end
	end
	add(self.silver_ID, 40);
	add(self.amber_ID, 40);
	add(self.salt_ID, 40);
	add(self.gold_ID, 25);
	add(self.copper_ID, 25);
	add(self.gems_ID, 20);
	add(self.jade_ID, 20);
	add(self.lapis_ID, 20);
	add(self.whale_ID, 16);
	add(self.crab_ID, 16);
	self.luxury_region_weights[1] = tundra;
	print("Frosty luxury weights: fur reserved for snow");
end
------------------------------------------------------------------------------
local InitLuxuryWeightsVanilla = AssignStartingPlots.__InitLuxuryWeights;
function AssignStartingPlots:__InitLuxuryWeights()
	InitLuxuryWeightsVanilla(self);
	ApplyWastelandLuxuryWeights(self);
	ApplyFrostyLuxuryWeights(self);
end
------------------------------------------------------------------------------
local AssignLuxuryToRegionVanilla = AssignStartingPlots.AssignLuxuryToRegion;
function AssignStartingPlots:AssignLuxuryToRegion(region_number)
	local cfg = GetBarrierConfig();
	local savedCoast = nil;
	if cfg ~= nil and cfg.kind == "wasteland" then
		if self.startLocationConditions[region_number] ~= nil and self.startLocationConditions[region_number][1] == true then
			if self.regionTerrainCounts[region_number] ~= nil then
				savedCoast = self.regionTerrainCounts[region_number][8];
				if savedCoast == nil or savedCoast < 90 then
					self.regionTerrainCounts[region_number][8] = 90;
				else
					savedCoast = nil;
				end
			end
		end
	end
	local use_this_ID;
	if cfg == nil or ((cfg.kind ~= "desert" or WestHasSungodRegional(self) == false) and cfg.kind ~= "frosty") then
		use_this_ID = AssignLuxuryToRegionVanilla(self, region_number);
	else
		local sungod = GetSungodLuxuryIDs(self);
		local saved = {};
		local i = 1;
		while i <= #sungod do
			local id = sungod[i];
			saved[id] = self.luxury_assignment_count[id];
			if saved[id] == nil then
				saved[id] = 0;
			end
			self.luxury_assignment_count[id] = 3;
			i = i + 1;
		end
		use_this_ID = AssignLuxuryToRegionVanilla(self, region_number);
		i = 1;
		while i <= #sungod do
			local id = sungod[i];
			self.luxury_assignment_count[id] = saved[id];
			i = i + 1;
		end
		print("Sungod regional cap: blocked extra citrus/cocoa/olives/coconut for region", region_number);
	end
	if savedCoast ~= nil then
		self.regionTerrainCounts[region_number][8] = savedCoast;
	end
	return use_this_ID;
end
------------------------------------------------------------------------------
local GetIndicesForLuxuryTypeVanilla = AssignStartingPlots.GetIndicesForLuxuryType;
function AssignStartingPlots:GetIndicesForLuxuryType(resource_ID)
	local p, s, t, q = GetIndicesForLuxuryTypeVanilla(self, resource_ID);
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "wasteland" then
		return p, s, t, q;
	end
	if resource_ID == self.gems_ID then
		return 7, 4, 14, 5;
	end
	if resource_ID == self.gold_ID
		or resource_ID == self.jade_ID
		or resource_ID == self.lapis_ID
		or resource_ID == self.amber_ID
		or resource_ID == self.copper_ID then
		if p ~= 14 and s ~= 14 and t ~= 14 and q ~= 14 then
			if q == nil or q < 1 then
				q = 14;
			elseif t == nil or t < 1 then
				t = 14;
			else
				q = 14;
			end
		end
	end
	return p, s, t, q;
end
------------------------------------------------------------------------------
local GetRegionLuxuryTargetNumbersVanilla = AssignStartingPlots.GetRegionLuxuryTargetNumbers;
function AssignStartingPlots:GetRegionLuxuryTargetNumbers()
	local src = GetRegionLuxuryTargetNumbersVanilla(self);
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "wasteland" then
		return src;
	end
	local out = {};
	local i = 1;
	while i <= #src do
		local v = src[i];
		if v ~= nil and v > 0 then
			v = v + 1;
		end
		out[i] = v;
		i = i + 1;
	end
	return out;
end
------------------------------------------------------------------------------
function WastelandCoastalLuxuryIDs(asp)
	local ids = {};
	if asp.whale_ID ~= nil then
		table.insert(ids, asp.whale_ID);
	end
	if asp.pearls_ID ~= nil then
		table.insert(ids, asp.pearls_ID);
	end
	if asp.crab_ID ~= nil then
		table.insert(ids, asp.crab_ID);
	end
	if asp.coral_ID ~= nil then
		table.insert(ids, asp.coral_ID);
	end
	return ids;
end
------------------------------------------------------------------------------
function TableRemoveValue(t, id)
	local i = 1;
	while i <= #t do
		if t[i] == id then
			table.remove(t, i);
			return true
		end
		i = i + 1;
	end
	return false
end
------------------------------------------------------------------------------
function WastelandForceCoastalLuxuryRoles(asp)
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "wasteland" then
		return
	end
	local coastal = WastelandCoastalLuxuryIDs(asp);
	if #coastal < 1 then
		return
	end
	local shuffled = GetShuffledCopyOfTable(coastal);
	local need = 2 + Map.Rand(3, "Wasteland coastal lux types");
	if need > #shuffled then
		need = #shuffled;
	end
	local picked = {};
	local i = 1;
	while i <= #shuffled do
		local id = shuffled[i];
		if TestMembership(asp.resourceIDs_assigned_to_regions, id) or TestMembership(asp.resourceIDs_assigned_to_cs, id) then
			table.insert(picked, id);
		end
		i = i + 1;
	end
	i = 1;
	while i <= #shuffled and #picked < need do
		local id = shuffled[i];
		if TestMembership(picked, id) == false then
			table.insert(picked, id);
			if TestMembership(asp.resourceIDs_assigned_to_random, id) == false then
				TableRemoveValue(asp.resourceIDs_not_being_used, id);
				table.insert(asp.resourceIDs_assigned_to_random, id);
				asp.iNumTypesRandom = asp.iNumTypesRandom + 1;
				if asp.iNumTypesDisabled > 0 then
					asp.iNumTypesDisabled = asp.iNumTypesDisabled - 1;
				end
			end
		end
		i = i + 1;
	end
	i = 1;
	while i <= #shuffled do
		local id = shuffled[i];
		if TestMembership(picked, id) == false
			and TestMembership(asp.resourceIDs_assigned_to_regions, id) == false
			and TestMembership(asp.resourceIDs_assigned_to_cs, id) == false then
			if TableRemoveValue(asp.resourceIDs_assigned_to_random, id) then
				table.insert(asp.resourceIDs_not_being_used, id);
				if asp.iNumTypesRandom > 0 then
					asp.iNumTypesRandom = asp.iNumTypesRandom - 1;
				end
				asp.iNumTypesDisabled = asp.iNumTypesDisabled + 1;
			end
		end
		i = i + 1;
	end
	asp.wastelandForcedCoastalLux = picked;
	print("Wasteland forced coastal lux types:", #picked);
end
------------------------------------------------------------------------------
local AssignLuxuryRolesVanilla = AssignStartingPlots.AssignLuxuryRoles;
function AssignStartingPlots:AssignLuxuryRoles()
	AssignLuxuryRolesVanilla(self);
	WastelandForceCoastalLuxuryRoles(self);
end
------------------------------------------------------------------------------
local ProcessResourceListVanilla = AssignStartingPlots.ProcessResourceList;
function AssignStartingPlots:ProcessResourceList(frequency, impact_table_number, plot_list, resources_to_place)
	local cfg = GetBarrierConfig();
	if cfg ~= nil and resources_to_place ~= nil then
		if cfg.kind == "desert" then
			local i = 1;
			while resources_to_place[i] ~= nil do
				if resources_to_place[i][1] == self.banana_ID then
					frequency = frequency * 1.25;
					break
				end
				i = i + 1;
			end
		elseif cfg.kind == "wasteland" then
			local i = 1;
			local isDeer = false;
			while resources_to_place[i] ~= nil do
				if resources_to_place[i][1] == self.deer_ID then
					isDeer = true;
					break
				end
				i = i + 1;
			end
			if isDeer then
				local hillShare = 0.25;
				if plot_list == self.extra_deer_list then
					local nHill = table.maxn(plot_list);
					local nFlat = table.maxn(self.tundra_flat_no_feature);
					if nHill < 1 or nFlat < 1 then
						frequency = 99999;
					else
						local bonus = frequency / 10;
						if bonus < 0.1 then
							bonus = 1;
						end
						local totalWant = math.ceil(nFlat / (12 * bonus * 1.311));
						local hillWant = math.floor(totalWant * hillShare + 0.5);
						if hillWant < 1 then
							hillWant = 1;
						end
						frequency = nHill / hillWant;
						print("Wasteland deer quota: total", totalWant, " hills", hillWant, " flats list", nFlat);
					end
				elseif plot_list == self.tundra_flat_no_feature then
					if table.maxn(self.extra_deer_list) > 0 then
						frequency = frequency * 1.311 / (1 - hillShare);
					else
						frequency = frequency * 1.311;
					end
				else
					frequency = frequency * 1.311;
				end
			end
		elseif cfg.kind == "peaks" then
			local i = 1;
			while resources_to_place[i] ~= nil do
				if resources_to_place[i][1] == self.horse_ID then
					frequency = frequency * 1.176;
				end
				i = i + 1;
			end
		elseif cfg.kind == "wetland" then
			local i = 1;
			while resources_to_place[i] ~= nil do
				if resources_to_place[i][1] == self.deer_ID then
					frequency = frequency * 1.111;
					if plot_list == self.extra_deer_list then
						frequency = frequency * 1.8;
					elseif plot_list == self.tundra_flat_no_feature then
						frequency = frequency * 1.55;
					end
					break
				elseif resources_to_place[i][1] == self.stone_ID then
					if plot_list == self.tundra_flat_no_feature then
						frequency = frequency * 0.68;
					end
					break
				elseif resources_to_place[i][1] == self.iron_ID then
					frequency = frequency * 0.8;
					break
				end
				i = i + 1;
			end
		elseif cfg.kind == "frosty" then
			local i = 1;
			while resources_to_place[i] ~= nil do
				if resources_to_place[i][1] == self.deer_ID then
					if plot_list == self.extra_deer_list then
						frequency = frequency * 0.55;
					end
					break
				elseif resources_to_place[i][1] == self.sheep_ID then
					frequency = frequency * 1.15;
					break
				end
				i = i + 1;
			end
		end
	end
	return ProcessResourceListVanilla(self, frequency, impact_table_number, plot_list, resources_to_place);
end
------------------------------------------------------------------------------
local AddStrategicBalanceResourcesVanilla = AssignStartingPlots.AddStrategicBalanceResources;
function AssignStartingPlots:AddStrategicBalanceResources(region_number)
	AddStrategicBalanceResourcesVanilla(self, region_number);
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "peaks" then
		return
	end
	local start_point_data = self.startingPlots[region_number];
	if start_point_data == nil then
		return
	end
	local sx = start_point_data[1];
	local sy = start_point_data[2];
	local iW, iH = Map.GetGridSize();
	local _, _, _, iron_amt = self:GetMajorStrategicResourceQuantityValues();
	if iron_amt == nil or iron_amt < 4 then
		iron_amt = 6;
	end
	local hills = {};
	local flats = {};
	local y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			local d = Map.PlotDistance(sx, sy, x, y);
			if d >= 1 and d <= 2 then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil and plot:IsWater() == false and plot:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN then
					if plot:GetResourceType(-1) == self.iron_ID then
						if plot:GetNumResource() >= 4 then
							return
						end
					end
					if plot:GetResourceType(-1) == -1 then
						if plot:GetPlotType() == PlotTypes.PLOT_HILLS then
							table.insert(hills, plot);
						elseif plot:GetPlotType() == PlotTypes.PLOT_LAND then
							table.insert(flats, plot);
						end
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	local pick = nil;
	if #hills > 0 then
		hills = GetShuffledCopyOfTable(hills);
		pick = hills[1];
	elseif #flats > 0 then
		flats = GetShuffledCopyOfTable(flats);
		pick = flats[1];
		pick:SetPlotType(PlotTypes.PLOT_HILLS, false, false);
	end
	if pick ~= nil then
		pick:SetResourceType(self.iron_ID, iron_amt);
		self.amounts_of_resources_placed[self.iron_ID + 1] = self.amounts_of_resources_placed[self.iron_ID + 1] + iron_amt;
		print("Peaks start iron at", pick:GetX(), pick:GetY(), " region", region_number);
	end
end
------------------------------------------------------------------------------
function PeakEnsureStartHills(asp)
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "peaks" then
		return
	end
	if asp == nil or asp.startingPlots == nil then
		return
	end
	local iW, iH = Map.GetGridSize();
	local r = 1;
	while asp.startingPlots[r] ~= nil do
		local sp = asp.startingPlots[r];
		local sx = sp[1];
		local sy = sp[2];
		local nHill = 0;
		local flats = {};
		local y = 0;
		while y < iH do
			local x = 0;
			while x < iW do
				local d = Map.PlotDistance(sx, sy, x, y);
				if d >= 1 and d <= 2 then
					local plot = Map.GetPlot(x, y);
					if plot ~= nil and plot:IsWater() == false and plot:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN then
						if plot:GetPlotType() == PlotTypes.PLOT_HILLS then
							nHill = nHill + 1;
						elseif plot:GetPlotType() == PlotTypes.PLOT_LAND then
							table.insert(flats, plot);
						end
					end
				end
				x = x + 1;
			end
			y = y + 1;
		end
		if nHill < 2 then
			flats = GetShuffledCopyOfTable(flats);
			local need = 2 - nHill;
			local i = 1;
			local made = 0;
			while made < need and i <= #flats do
				flats[i]:SetPlotType(PlotTypes.PLOT_HILLS, false, false);
				made = made + 1;
				i = i + 1;
			end
			print("Peaks start hills region", r, " had", nHill, " added", made);
		end
		r = r + 1;
	end
end
------------------------------------------------------------------------------
function FrostyTileOnSnow(plot)
	return plot ~= nil and plot:GetTerrainType() == TerrainTypes.TERRAIN_SNOW;
end
------------------------------------------------------------------------------
function FrostyTileNearSnow(plot)
	if plot == nil or plot:IsWater() or FrostyTileOnSnow(plot) then
		return false
	end
	if plot:GetTerrainType() == TerrainTypes.TERRAIN_TUNDRA then
		local iW, iH = Map.GetGridSize();
		local yNorm = 0;
		if iH > 1 then
			yNorm = plot:GetY() / (iH - 1);
		end
		if yNorm >= 0.40 then
			return true
		end
	end
	local d = 0;
	while d < DirectionTypes.NUM_DIRECTION_TYPES do
		local adj = PlotDirNoXWrap(plot:GetX(), plot:GetY(), d);
		if adj ~= nil and adj:GetTerrainType() == TerrainTypes.TERRAIN_SNOW then
			return true
		end
		d = d + 1;
	end
	return false
end
------------------------------------------------------------------------------
function FrostyStartLandOk(plot, skip)
	if plot == nil or plot:IsWater() then
		return false
	end
	if plot:GetPlotType() == PlotTypes.PLOT_MOUNTAIN then
		return false
	end
	if FrostyTileOnSnow(plot) then
		return false
	end
	local iW, iH = Map.GetGridSize();
	if StartYAllowed(plot:GetY(), iH) == false then
		return false
	end
	local x = plot:GetX();
	if skip[x] == true then
		return false
	end
	return true
end
------------------------------------------------------------------------------
function FrostyStartMinDist(x, y, starts, skipIndex)
	local best = 9999;
	local i = 1;
	while i <= #starts do
		if i ~= skipIndex then
			local ox = starts[i][1];
			local oy = starts[i][2];
			if ox ~= nil and oy ~= nil then
				local d = Map.PlotDistance(x, y, ox, oy);
				if d < best then
					best = d;
				end
			end
		end
		i = i + 1;
	end
	return best
end
------------------------------------------------------------------------------
function FrostyFindStartPlot(iW, iH, mid, skip, starts, skipIndex, preferX, preferY, requireNear, forbidNear)
	local bestX = nil;
	local bestY = nil;
	local bestD = 9999;
	preferX = math.floor(preferX);
	preferY = math.floor(preferY);
	local y = 0;
	while y < iH do
		local x = 0;
		while x < mid do
			local plot = Map.GetPlot(x, y);
			if FrostyStartLandOk(plot, skip) then
				local allow = true;
				if requireNear or forbidNear then
					local near = FrostyTileNearSnow(plot);
					if requireNear and near == false then
						allow = false;
					end
					if forbidNear and near then
						allow = false;
					end
				end
				if allow then
					local dMin = FrostyStartMinDist(x, y, starts, skipIndex);
					if dMin >= 6 then
						local d = Map.PlotDistance(preferX, preferY, x, y);
						if d < bestD then
							bestD = d;
							bestX = x;
							bestY = y;
						end
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	return bestX, bestY;
end
------------------------------------------------------------------------------
function FrostyApplyStart(asp, westIdx, starts, i, x, y)
	starts[i][1] = x;
	starts[i][2] = y;
	asp.startingPlots[westIdx[i]] = {x, y, 1};
end
------------------------------------------------------------------------------
function FrostyAdjustStarts(asp)
	WeeveeDbg("FrostyAdjustStarts body");
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "frosty" then
		WeeveeDbg("FrostyAdjustStarts skip");
		return
	end
	if asp == nil or asp.startingPlots == nil then
		return
	end
	local iW, iH = Map.GetGridSize();
	local mid = math.floor(iW / 2);
	local skip = FillMireSkip(iW);
	local westIdx = {};
	local starts = {};
	local r = 1;
	while asp.startingPlots[r] ~= nil do
		local sp = asp.startingPlots[r];
		if sp[1] ~= nil and sp[2] ~= nil and sp[1] < mid then
			table.insert(westIdx, r);
			table.insert(starts, {math.floor(sp[1]), math.floor(sp[2])});
		end
		r = r + 1;
	end
	if #westIdx < 1 then
		return
	end
	local si = 1;
	while si <= #starts do
		local plot = Map.GetPlot(starts[si][1], starts[si][2]);
		if FrostyStartLandOk(plot, skip) == false or FrostyStartMinDist(starts[si][1], starts[si][2], starts, si) < 6 then
			local nx, ny = FrostyFindStartPlot(iW, iH, mid, skip, starts, si, starts[si][1], starts[si][2], false, false);
			if nx ~= nil then
				FrostyApplyStart(asp, westIdx, starts, si, nx, ny);
				print("Frosty start relocated region", westIdx[si], "to", nx, ny);
			end
		end
		si = si + 1;
	end
	local pass = 1;
	while pass <= 16 do
		local worstA = 0;
		local worstB = 0;
		local worstD = 9999;
		local a = 1;
		while a <= #starts do
			local b = a + 1;
			while b <= #starts do
				local d = Map.PlotDistance(starts[a][1], starts[a][2], starts[b][1], starts[b][2]);
				if d < worstD then
					worstD = d;
					worstA = a;
					worstB = b;
				end
				b = b + 1;
			end
			a = a + 1;
		end
		if worstD >= 6 then
			break
		end
		local moveI = worstB;
		if starts[worstA][2] > starts[worstB][2] then
			moveI = worstA;
		end
		local nx, ny = FrostyFindStartPlot(iW, iH, mid, skip, starts, moveI, starts[moveI][1], starts[moveI][2], false, false);
		if nx == nil then
			break
		end
		FrostyApplyStart(asp, westIdx, starts, moveI, nx, ny);
		print("Frosty start unclumped region", westIdx[moveI], "to", nx, ny, "wasDist", worstD);
		pass = pass + 1;
	end
	local wantNear = 1;
	if #starts >= 4 then
		wantNear = 2;
	end
	local nearList = {};
	local farList = {};
	si = 1;
	while si <= #starts do
		local plot = Map.GetPlot(starts[si][1], starts[si][2]);
		if FrostyTileNearSnow(plot) then
			table.insert(nearList, si);
		else
			table.insert(farList, si);
		end
		si = si + 1;
	end
	while #nearList > wantNear do
		local moveIdx = 1;
		local k = 2;
		while k <= #nearList do
			if starts[nearList[k]][2] < starts[nearList[moveIdx]][2] then
				moveIdx = k;
			end
			k = k + 1;
		end
		local moveI = nearList[moveIdx];
		local nx, ny = FrostyFindStartPlot(iW, iH, mid, skip, starts, moveI, starts[moveI][1], 0, false, true);
		if nx == nil then
			break
		end
		FrostyApplyStart(asp, westIdx, starts, moveI, nx, ny);
		table.remove(nearList, moveIdx);
		print("Frosty start pushed south region", westIdx[moveI], "to", nx, ny);
	end
	while #nearList < wantNear and #farList > 0 do
		local bestI = farList[1];
		local fi = 2;
		while fi <= #farList do
			if starts[farList[fi]][2] > starts[bestI][2] then
				bestI = farList[fi];
			end
			fi = fi + 1;
		end
		local nx, ny = FrostyFindStartPlot(iW, iH, mid, skip, starts, bestI, starts[bestI][1], iH - 1, true, false);
		if nx == nil then
			break
		end
		FrostyApplyStart(asp, westIdx, starts, bestI, nx, ny);
		table.insert(nearList, bestI);
		local drop = 1;
		while drop <= #farList do
			if farList[drop] == bestI then
				table.remove(farList, drop);
				break
			end
			drop = drop + 1;
		end
		print("Frosty start nudged to snow region", westIdx[bestI], "to", nx, ny);
	end
	WeeveeDbg("FrostyAdjustStarts nWest=" .. tostring(#starts));
end
------------------------------------------------------------------------------
function FrostyFixSnowStarts()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "frosty" then
		return
	end
	local iW, iH = Map.GetGridSize();
	local mid = math.floor(iW / 2);
	local skip = FillMireSkip(iW);
	local nMaj = 22;
	if GameDefines ~= nil and GameDefines.MAX_MAJOR_CIVS ~= nil then
		nMaj = GameDefines.MAX_MAJOR_CIVS;
	end
	local i = 0;
	while i < nMaj do
		local player = Players[i];
		if player ~= nil and player:IsAlive() and player:GetStartingPlot() ~= nil then
			local plot = player:GetStartingPlot();
			if FrostyTileOnSnow(plot) then
				local px = plot:GetX();
				local py = plot:GetY();
				local x0 = 0;
				local x1 = mid - 1;
				if px >= mid then
					x0 = mid;
					x1 = iW - 1;
				end
				local bestX = nil;
				local bestY = nil;
				local bestD = 9999;
				local y = 0;
				while y < iH do
					local x = x0;
					while x <= x1 do
						local p = Map.GetPlot(x, y);
						if FrostyStartLandOk(p, skip) then
							local d = Map.PlotDistance(px, py, x, y);
							if d < bestD then
								bestD = d;
								bestX = x;
								bestY = y;
							end
						end
						x = x + 1;
					end
					y = y + 1;
				end
				if bestX ~= nil then
					player:SetStartingPlot(Map.GetPlot(bestX, bestY));
					print("Frosty post-mirror snow start moved", px, py, "to", bestX, bestY);
				end
			end
		end
		i = i + 1;
	end
end
------------------------------------------------------------------------------
function FrostyThawStartResources()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "frosty" then
		return
	end
	local iW, iH = Map.GetGridSize();
	local nMaj = 22;
	if GameDefines ~= nil and GameDefines.MAX_MAJOR_CIVS ~= nil then
		nMaj = GameDefines.MAX_MAJOR_CIVS;
	end
	local n = 0;
	local i = 0;
	while i < nMaj do
		local player = Players[i];
		if player ~= nil and player:IsAlive() and player:GetStartingPlot() ~= nil then
			local sp = player:GetStartingPlot();
			local sx = sp:GetX();
			local sy = sp:GetY();
			local y = 0;
			while y < iH do
				local x = 0;
				while x < iW do
					local dx = x - sx;
					if dx < 0 then
						dx = 0 - dx;
					end
					if dx <= 3 and Map.PlotDistance(sx, sy, x, y) <= 3 then
						local plot = Map.GetPlot(x, y);
						if plot ~= nil and plot:IsWater() == false then
							local t = plot:GetTerrainType();
							if t == TerrainTypes.TERRAIN_SNOW then
								local nGrass = CountAdjacentTerrain(plot, TerrainTypes.TERRAIN_GRASS);
								local nPlains = CountAdjacentTerrain(plot, TerrainTypes.TERRAIN_PLAINS);
								local nSnow = CountAdjacentTerrain(plot, TerrainTypes.TERRAIN_SNOW);
								if nSnow >= 1 and (nGrass + nPlains) < 4 then
									local res = plot:GetResourceType(-1);
									if res ~= nil and res ~= -1 then
										local usage = Game.GetResourceUsageType(res);
										local thaw = false;
										if usage == ResourceUsageTypes.RESOURCEUSAGE_LUXURY or usage == ResourceUsageTypes.RESOURCEUSAGE_STRATEGIC then
											thaw = true;
										elseif usage == ResourceUsageTypes.RESOURCEUSAGE_BONUS then
											if plot:GetFeatureType() ~= FeatureTypes.FEATURE_FOREST then
												thaw = true;
											end
										end
										if thaw then
											plot:SetTerrainType(TerrainTypes.TERRAIN_TUNDRA, false, false);
											n = n + 1;
										end
									end
								end
							end
						end
					end
					x = x + 1;
				end
				y = y + 1;
			end
		end
		i = i + 1;
	end
	print("Frosty thawed start snow resources:", n);
end
------------------------------------------------------------------------------
local START_TILE_RESOURCE_CHANCE = 8;
function MaybePlaceStartTileResource(asp)
	if asp == nil or asp.startingPlots == nil then
		return
	end
	local iW, iH = Map.GetGridSize();
	local r = 1;
	while asp.startingPlots[r] ~= nil do
		local sp = asp.startingPlots[r];
		local sx = sp[1];
		local sy = sp[2];
		local skipMirrorDest = (DEF_MIRRORED == 1 and sx >= iW / 2);
		if not skipMirrorDest and Map.Rand(100, "Start tile resource - Lua") < START_TILE_RESOURCE_CHANCE then
			local startPlot = Map.GetPlot(sx, sy);
			if startPlot ~= nil and startPlot:GetResourceType(-1) == -1 then
				local candidates = {};
				local y = 0;
				while y < iH do
					local x = 0;
					while x < iW do
						local d = Map.PlotDistance(sx, sy, x, y);
						if d >= 1 and d <= 3 then
							local plot = Map.GetPlot(x, y);
							if plot ~= nil then
								local resID = plot:GetResourceType(-1);
								if resID ~= -1 then
									local usage = Game.GetResourceUsageType(resID);
									if usage == ResourceUsageTypes.RESOURCEUSAGE_BONUS or usage == ResourceUsageTypes.RESOURCEUSAGE_LUXURY then
										if startPlot:CanHaveResource(resID) then
											table.insert(candidates, plot);
										end
									end
								end
							end
						end
						x = x + 1;
					end
					y = y + 1;
				end
				local n = #candidates;
				if n > 0 then
					local src = candidates[1 + Map.Rand(n, "Start tile resource pick - Lua")];
					local resID = src:GetResourceType(-1);
					local num = src:GetNumResource();
					src:SetResourceType(-1);
					startPlot:SetResourceType(resID, num);
					print("Start tile resource region", r, " moved", resID, "qty", num);
				end
			end
		end
		r = r + 1;
	end
end
------------------------------------------------------------------------------
local MIN_START_LANDMASS = 6;
local START_EDGE_MIN = 4;
function StartYAllowed(y, iH)
	if y == nil or iH == nil then
		return false
	end
	if iH <= START_EDGE_MIN * 2 then
		return y > 0 and y < iH - 1;
	end
	return y >= START_EDGE_MIN and y < iH - START_EDGE_MIN;
end
------------------------------------------------------------------------------
function FindNearestStartOffEdge(sx, sy)
	local iW, iH = Map.GetGridSize();
	local mid = math.floor(iW / 2);
	local x0 = 0;
	local x1 = iW - 1;
	if DEF_MIRRORED == 1 then
		if sx < mid then
			x1 = mid - 1;
		else
			x0 = mid;
		end
	end
	local cfg = GetBarrierConfig();
	local bestX = nil;
	local bestY = nil;
	local bestD = 9999;
	local y = 0;
	while y < iH do
		if StartYAllowed(y, iH) then
			local x = x0;
			while x <= x1 do
				local plot = Map.GetPlot(x, y);
				if plot ~= nil and plot:IsWater() == false and plot:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN then
					local ok = true;
					if cfg ~= nil and cfg.kind == "frosty" and plot:GetTerrainType() == TerrainTypes.TERRAIN_SNOW then
						ok = false;
					end
					if ok then
						local d = Map.PlotDistance(sx, sy, x, y);
						if d < bestD then
							bestD = d;
							bestX = x;
							bestY = y;
						end
					end
				end
				x = x + 1;
			end
		end
		y = y + 1;
	end
	return bestX, bestY;
end
------------------------------------------------------------------------------
function ClampAspStartsOffEdges(asp)
	if asp == nil or asp.startingPlots == nil then
		return
	end
	local iW, iH = Map.GetGridSize();
	local r = 1;
	while asp.startingPlots[r] ~= nil do
		local sp = asp.startingPlots[r];
		local sx = sp[1];
		local sy = sp[2];
		if sx ~= nil and sy ~= nil and StartYAllowed(sy, iH) == false then
			local nx, ny = FindNearestStartOffEdge(sx, sy);
			if nx ~= nil then
				asp.startingPlots[r] = {nx, ny, 1};
				print("Start moved off N/S edge region", r, "from", sx, sy, "to", nx, ny);
			end
		end
		r = r + 1;
	end
end
------------------------------------------------------------------------------
function ClampPlayerStartsOffEdges()
	local iW, iH = Map.GetGridSize();
	local nMaj = 22;
	if GameDefines ~= nil and GameDefines.MAX_MAJOR_CIVS ~= nil then
		nMaj = GameDefines.MAX_MAJOR_CIVS;
	end
	local i = 0;
	while i < nMaj do
		local player = Players[i];
		if player ~= nil and player:IsAlive() and player:GetStartingPlot() ~= nil then
			local plot = player:GetStartingPlot();
			local sx = plot:GetX();
			local sy = plot:GetY();
			if StartYAllowed(sy, iH) == false then
				local nx, ny = FindNearestStartOffEdge(sx, sy);
				if nx ~= nil then
					player:SetStartingPlot(Map.GetPlot(nx, ny));
					print("Player start moved off N/S edge", i, "from", sx, sy, "to", nx, ny);
				end
			end
		end
		i = i + 1;
	end
end
------------------------------------------------------------------------------
local EvaluateCandidatePlotVanilla = AssignStartingPlots.EvaluateCandidatePlot;
function AssignStartingPlots:EvaluateCandidatePlot(plotIndex, region_type)
	local iW, iH = Map.GetGridSize();
	local x = (plotIndex - 1) % iW;
	local y = (plotIndex - x - 1) / iW;
	if StartYAllowed(y, iH) == false then
		return -200, false;
	end
	local plot = Map.GetPlot(x, y);
	if plot ~= nil and not plot:IsWater() then
		local area = plot:Area();
		if area ~= nil and area:GetNumTiles() < ShoresMinStartLandmass() then
			return -200, false;
		end
		local cfg = GetBarrierConfig();
		if cfg ~= nil and cfg.kind == "frosty" and plot:GetTerrainType() == TerrainTypes.TERRAIN_SNOW then
			return -200, false;
		end
		if cfg ~= nil and cfg.kind == "shores" and ShoresPlotIsStartLegal(x, y) == false then
			return -200, false;
		end
	end
	return EvaluateCandidatePlotVanilla(self, plotIndex, region_type);
end
local FindStartVanilla = AssignStartingPlots.FindStart;
function AssignStartingPlots:FindStart(region_number)
	local ok, forced = FindStartVanilla(self, region_number);
	if ok and self.startingPlots[region_number] ~= nil then
		local sx = self.startingPlots[region_number][1];
		local sy = self.startingPlots[region_number][2];
		local plot = Map.GetPlot(sx, sy);
		if plot ~= nil then
			local area = plot:Area();
			if area ~= nil and area:GetNumTiles() < ShoresMinStartLandmass() then
				print("Start on tiny island at", sx, sy, "- relocating");
				local iW, iH = Map.GetGridSize();
				local bestDist = 9999;
				local bestX, bestY;
				local shores = IsShores();
				for ry = 0, iH - 1 do
					for rx = 0, iW - 1 do
						local p = Map.GetPlot(rx, ry);
						if p ~= nil and not p:IsWater() and p:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN and StartYAllowed(ry, iH) then
							local a = p:Area();
							local okHere = (a ~= nil and a:GetNumTiles() >= ShoresMinStartLandmass());
							if shores then
								okHere = ShoresPlotIsStartLegal(rx, ry);
							end
							if okHere then
								local d = Map.PlotDistance(sx, sy, rx, ry);
								if d < bestDist then
									bestDist = d;
									bestX = rx;
									bestY = ry;
								end
							end
						end
					end
				end
				if bestX ~= nil then
					self.startingPlots[region_number] = {bestX, bestY, 1};
					print("Relocated start to", bestX, bestY);
				end
			end
		end
	end
	return ok, forced;
end
------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function GetMapInitData(worldSize)
	WeeveeDbgReset();
	WeeveeDbg("GetMapInitData");
	ResolveBarrierSplit();
	ResolveWrap();
	local cfg = GetBarrierConfig();
	local kind = "nil";
	if cfg ~= nil then
		kind = tostring(cfg.kind);
	end
	WeeveeDbg("split wrap kind=" .. kind .. " wrapX=" .. tostring(IsSnowWrapX()));
	-- This function can reset map grid sizes or world wrap settings.
	--
	-- East vs West is an extremely compact multiplayer map type.
	local worldsizes = {
		[GameInfo.Worlds.WORLDSIZE_DUEL.ID] = {34, 14},
		[GameInfo.Worlds.WORLDSIZE_TINY.ID] = {40, 22},
		[GameInfo.Worlds.WORLDSIZE_SMALL.ID] = {44, 26},
		[GameInfo.Worlds.WORLDSIZE_STANDARD.ID] = {50, 30},
		[GameInfo.Worlds.WORLDSIZE_LARGE.ID] = {52, 32},
		[GameInfo.Worlds.WORLDSIZE_HUGE.ID] = {64, 40}
		}
	local grid_size = worldsizes[worldSize];
	--
	local world = GameInfo.Worlds[worldSize];
	if(world ~= nil) then
		if grid_size == nil then
			print("Weevee GetMapInitData: unknown worldSize", worldSize);
			return
		end
		local w = grid_size[1];
		local h = grid_size[2];
		if IsExploBalance() then
			w = w - 4;
		end
		if Map.GetCustomOption(OPT_CANVAS_SHRINK) == CANVAS_SHRINK_YES then
			w = w - 2 * Map.Rand(4, "Map Width Variance");
			h = h - 2 * Map.Rand(4, "Map Height Variance");
		end
		print("Map canvas:", w, "x", h, "(base", grid_size[1], "x", grid_size[2], ")");
		WeeveeDbg("canvas " .. tostring(w) .. "x" .. tostring(h) .. " wrapX=" .. tostring(IsSnowWrapX()));
		return {
			Width = w,
			Height = h,
			WrapX = IsSnowWrapX(),
		};
	end
end
-------------------------------------------------------------------------------
local snowWrapWidthResolved = false;
local snowWrapBackWidth = 0;
local snowWrapCenterWidth = 0;
function ResolveSnowWrapWidths()
	if snowWrapWidthResolved then
		return snowWrapBackWidth, snowWrapCenterWidth;
	end
	snowWrapWidthResolved = true;
	local ops = Map.GetCustomOption(OPT_SNOW_BARRIER);
	if IsSnowWrapX() == false then
		snowWrapBackWidth = 0;
		if ops == 5 then
			snowWrapCenterWidth = 2 * (Map.Rand(2, "Snow Wrap Center Width") + 1);
		else
			snowWrapCenterWidth = (ops - 1) * 2;
		end
		if IsShores() and snowWrapCenterWidth < 2 then
			-- Width 0 would delete the barrier and the tundra line, which the
			-- whole Shores layout is measured from.
			snowWrapCenterWidth = 2;
			print("Shores: barrier width clamped to 2");
		end
		print("Snow Barrier widths (no wrap): wrap=0 center=", snowWrapCenterWidth);
		return snowWrapBackWidth, snowWrapCenterWidth;
	end
	if ops == 5 then
		repeat
			snowWrapBackWidth = 2 * (Map.Rand(3, "Snow Wrap Back Width") + 1);
			snowWrapCenterWidth = 2 * (Map.Rand(3, "Snow Wrap Center Width") + 1);
		until snowWrapBackWidth < 6 or snowWrapCenterWidth < 6;
		print("Snow Wrap widths (random): wrap=", snowWrapBackWidth, " center=", snowWrapCenterWidth);
	else
		local n = (ops - 1) * 2;
		snowWrapBackWidth = n;
		snowWrapCenterWidth = n;
	end
	return snowWrapBackWidth, snowWrapCenterWidth;
end
------------------------------------------------------------------------------
local climateScaleResolved = false;
local climateScale = 0.8;
local climateVariation = nil;
function ResolveClimateScale()
	if climateScaleResolved then
		return climateScale, climateVariation;
	end
	climateScaleResolved = true;
	local iW, iH = Map.GetGridSize();
	local oneRow = 0.8 / (iH / 2);
	climateScale = 0.8 + (Map.Rand(3, "Climate Scale") - 1) * oneRow;
	if climateScale > 0.95 then
		climateScale = 0.95;
	end
	climateVariation = Fractal.Create(iW, iH, 3, Map.GetFractalFlags(), -1, -1);
	print("Climate scale:", climateScale);
	return climateScale, climateVariation;
end
------------------------------------------------------------------------------
function GetClimateLatitudeAtPlot(iX, iY)
	local scale, variation = ResolveClimateScale();
	local iW, iH = Map.GetGridSize();
	local lat = math.abs((iH / 2) - iY) / (iH / 2);
	lat = lat + (128 - variation:GetHeight(iX, iY)) / (255.0 * 5.0);
	lat = scale * (math.clamp(lat, 0, 1));
	return lat;
end
------------------------------------------------------------------------------
function GetSnowWrapWaterBounds(iW)
	local wrapN, centerN = ResolveSnowWrapWidths();
	local wrapHalf = wrapN / 2;
	local centerHalf = centerN / 2;
	local mid = math.floor(iW / 2);
	local minX = wrapHalf + 4;
	local maxX = mid - centerHalf - 5;
	return minX, maxX;
end
------------------------------------------------------------------------------
function GetDesertWaterStrip(iW)
	local minX, maxX = GetSnowWrapWaterBounds(iW);
	if minX > maxX then
		return minX, maxX;
	end
	local playW = maxX - minX;
	local lakeW = math.floor(playW * 0.32);
	if lakeW < 2 then
		lakeW = 2;
	end
	local lakeMaxX = minX + lakeW;
	if lakeMaxX > maxX - 3 then
		lakeMaxX = maxX - 3;
	end
	if lakeMaxX < minX then
		lakeMaxX = maxX;
	end
	return minX, lakeMaxX;
end
------------------------------------------------------------------------------
function WaterAllowedAtX(x)
	local iW = Map.GetGridSize();
	local wrapN, centerN = ResolveSnowWrapWidths();
	local wrapHalf = wrapN / 2;
	local centerHalf = centerN / 2;
	local mid = math.floor(iW / 2);
	if wrapHalf > 0 then
		if x <= (wrapHalf + 3) then
			return false
		end
		if x >= (iW - wrapHalf - 4) then
			return false
		end
	end
	if centerHalf > 0 then
		local pad = 4;
		if IsShores() then
			-- Shores keeps its own dry margin (cfg.dryMargin) next to the
			-- tundra line; the generic pad would forbid water the band wants.
			pad = 3;
		end
		if x >= (mid - centerHalf - pad) and x <= (mid + centerHalf - 1 + pad) then
			return false
		end
	end
	return true
end
------------------------------------------------------------------------------
function ScrubWaterNearSnow()
	if IsSnowBarrier() == false then
		return
	end
	local iW, iH = Map.GetGridSize();
	local y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			if WaterAllowedAtX(x) == false then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil and plot:GetPlotType() == PlotTypes.PLOT_OCEAN then
					plot:SetPlotType(PlotTypes.PLOT_LAND, false, false);
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
end
------------------------------------------------------------------------------
function GetSnowWrapColumns(iW)
	local cols = {};
	local wrapN, centerN = ResolveSnowWrapWidths();
	if wrapN > 0 then
		local half = wrapN / 2;
		for x = 0, half - 1 do
			table.insert(cols, x);
		end
		for x = iW - half, iW - 1 do
			table.insert(cols, x);
		end
	end
	if centerN > 0 then
		local half = centerN / 2;
		local mid = math.floor(iW / 2);
		for x = mid - half, mid + half - 1 do
			table.insert(cols, x);
		end
	end
	return cols;
end
------------------------------------------------------------------------------
function GetSnowWrapTundraColumns(iW)
	local cols = {};
	local wrapN, centerN = ResolveSnowWrapWidths();
	local mid = math.floor(iW / 2);
	if wrapN > 0 then
		local half = wrapN / 2;
		table.insert(cols, half);
		table.insert(cols, iW - half - 1);
	end
	if centerN > 0 then
		local half = centerN / 2;
		table.insert(cols, mid - half - 1);
		table.insert(cols, mid + half);
	end
	return cols;
end
------------------------------------------------------------------------------
function GetSnowWrapLandMountainXs(iW)
	local wrapN = ResolveSnowWrapWidths();
	local wrapHalf = wrapN / 2;
	local firstLand = wrapHalf + 1;
	local xWest = 3;
	if xWest < firstLand then
		xWest = firstLand;
	end
	return xWest, iW - 1 - xWest;
end
------------------------------------------------------------------------------
-- Shores geometry. Everything is measured from the west tundra transition
-- column, never from the hard-coded iW/2 - 4 the front-mountain code uses -
-- that literal only equals xT - 1 at barrier width 4.
function ShoresWestTundraX(iW)
	local wrapN, centerN = ResolveSnowWrapWidths();
	local centerHalf = centerN / 2;
	local mid = math.floor(iW / 2);
	return mid - centerHalf - 1;
end
------------------------------------------------------------------------------
function ShoresBandLoX(iW)
	local cfg = GetBarrierConfig();
	local w = 5;
	if cfg ~= nil and cfg.bandWidth ~= nil then
		w = cfg.bandWidth;
	end
	local lo = ShoresWestTundraX(iW) - w;
	if lo < 1 then
		lo = 1;
	end
	return lo;
end
------------------------------------------------------------------------------
function ShoresSeaHiX(iW)
	return ShoresBandLoX(iW) - 1;
end
------------------------------------------------------------------------------
function ShoresDryLoX(iW)
	-- First column of the always-dry margin next to the tundra line.
	local cfg = GetBarrierConfig();
	local m = 2;
	if cfg ~= nil and cfg.dryMargin ~= nil then
		m = cfg.dryMargin;
	end
	return ShoresWestTundraX(iW) - m;
end
------------------------------------------------------------------------------
function PlaceMirroredMountain(plotTypes, iW, iH, x, y)
	if x < 0 or x >= iW or y < 0 or y >= iH then
		return false
	end
	local idx = y * iW + x + 1;
	if plotTypes[idx] == PlotTypes.PLOT_MOUNTAIN then
		return false
	end
	plotTypes[idx] = PlotTypes.PLOT_MOUNTAIN;
	local mx = iW - x - 1;
	local my = iH - y - 1;
	plotTypes[my * iW + mx + 1] = PlotTypes.PLOT_MOUNTAIN;
	return true
end
------------------------------------------------------------------------------
function PlaceChaoticFrontRidge(plotTypes, iW, iH, xCenter, density)
	local xMin = xCenter - 2;
	local xMax = xCenter + 2;
	if xMin < 0 then
		xMin = 0;
	end
	local mid = math.floor(iW / 2);
	if xMax >= mid then
		xMax = mid - 1;
	end
	local target = math.floor(iH * density);
	if target < 1 then
		target = 1;
	end
	local x = xCenter;
	local y = Map.Rand(iH, "Chaotic Ridge StartY");
	local placed = 0;
	local steps = 0;
	local maxSteps = iH * 10;
	if maxSteps < 40 then
		maxSteps = 40;
	end
	while placed < target and steps < maxSteps do
		steps = steps + 1;
		if PlaceMirroredMountain(plotTypes, iW, iH, x, y) then
			placed = placed + 1;
		end
		if placed < target and Map.Rand(10, "Chaotic Spur") < 5 then
			local sx = x + (Map.Rand(3, "Chaotic SpurX") - 1);
			local sy = y + (Map.Rand(3, "Chaotic SpurY") - 1);
			if sx < xMin then
				sx = xMin;
			end
			if sx > xMax then
				sx = xMax;
			end
			if sy < 0 then
				sy = 0;
			end
			if sy >= iH then
				sy = iH - 1;
			end
			if PlaceMirroredMountain(plotTypes, iW, iH, sx, sy) then
				placed = placed + 1;
			end
		end
		local dy = Map.Rand(3, "Chaotic WalkY") - 1;
		if dy == 0 then
			if Map.Rand(2, "Chaotic WalkY2") == 0 then
				dy = 1;
			else
				dy = -1;
			end
		end
		if Map.Rand(4, "Chaotic Skip") == 0 then
			dy = dy + dy;
		end
		y = y + dy;
		if y < 0 then
			y = 0;
		end
		if y >= iH then
			y = iH - 1;
		end
		x = x + (Map.Rand(3, "Chaotic WalkX") - 1);
		if x < xMin then
			x = xMin;
		end
		if x > xMax then
			x = xMax;
		end
	end
end
------------------------------------------------------------------------------
function PlacePeaksFrontClusters(plotTypes, iW, iH, xCenter, density)
	local xMin = xCenter - 1;
	local xMax = xCenter + 1;
	if xMin < 0 then
		xMin = 0;
	end
	local mid = math.floor(iW / 2);
	if xMax >= mid then
		xMax = mid - 1;
	end
	local nClusters = 2 + math.floor((density - 0.20) * 8);
	if nClusters < 2 then
		nClusters = 2;
	end
	if nClusters > 4 then
		nClusters = 4;
	end
	local yLo = 2;
	local yHi = iH - 3;
	if yHi < yLo then
		yHi = yLo;
	end
	local span = yHi - yLo + 1;
	local seeds = {};
	local c = 1;
	while c <= nClusters do
		local slot = yLo + math.floor(((c - 0.5) * span) / nClusters);
		local sy = slot + Map.Rand(5, "Peaks Front Jitter") - 2;
		if sy < yLo then
			sy = yLo;
		end
		if sy > yHi then
			sy = yHi;
		end
		table.insert(seeds, sy);
		c = c + 1;
	end
	local evenN = {{0, 1}, {1, 0}, {0, -1}, {-1, -1}, {-1, 0}, {-1, 1}};
	local oddN = {{1, 1}, {1, 0}, {1, -1}, {0, -1}, {-1, 0}, {0, 1}};
	local si = 1;
	while si <= #seeds do
		local sy = seeds[si];
		local sx = xMax;
		if xCenter < mid * 0.5 then
			sx = xMin;
		end
		if sx < xMin then
			sx = xMin;
		end
		if sx > xMax then
			sx = xMax;
		end
		local target = 2 + Map.Rand(2, "Peaks Front Cluster");
		PlaceMirroredMountain(plotTypes, iW, iH, sx, sy);
		local qx = {sx};
		local qy = {sy};
		local grown = 1;
		local qi = 1;
		while qi <= #qx and grown < target do
			local cx = qx[qi];
			local cy = qy[qi];
			qi = qi + 1;
			local dirs = evenN;
			if cy % 2 == 1 then
				dirs = oddN;
			end
			local d = 1;
			while d <= 6 and grown < target do
				local ax = cx + dirs[d][1];
				local ay = cy + dirs[d][2];
				if ax >= xMin and ax <= xMax and ay >= 1 and ay < iH - 1 then
					if Map.Rand(100, "Peaks Front Grow") < 85 then
						if PlaceMirroredMountain(plotTypes, iW, iH, ax, ay) then
							grown = grown + 1;
							table.insert(qx, ax);
							table.insert(qy, ay);
						end
					end
				end
				d = d + 1;
			end
		end
		si = si + 1;
	end
end
------------------------------------------------------------------------------
function ShapeNoWrapBackstrip(plotTypes, iW, iH)
	local evenN = {{0, 1}, {1, 0}, {0, -1}, {-1, -1}, {-1, 0}, {-1, 1}};
	local oddN = {{1, 1}, {1, 0}, {1, -1}, {0, -1}, {-1, 0}, {0, 1}};
	local minD = 2;
	local maxD = 3;
	local depth = 2;
	local nIslands = 3 + Map.Rand(3, "NoWrap Back Islands");
	if UsesExploCoastShape() then
		minD = 1;
		maxD = 2;
		depth = 1;
		nIslands = 1 + Map.Rand(2, "NoWrap Back Islands");
	end
	local y = 0;
	while y < iH do
		local step = Map.Rand(3, "NoWrap Coast Walk") - 1;
		depth = depth + step;
		if depth < minD then
			depth = minD;
		end
		if depth > maxD then
			depth = maxD;
		end
		local x = 0;
		while x <= 2 do
			local i = y * iW + x + 1;
			if x < depth then
				plotTypes[i] = PlotTypes.PLOT_OCEAN;
			elseif x <= 1 then
				plotTypes[i] = PlotTypes.PLOT_LAND;
			end
			x = x + 1;
		end
		y = y + 1;
	end
	local cutPct = ResolveExploBackCoastPlan();
	local winY0 = 0;
	local winY1 = iH;
	local frostyCfg = GetBarrierConfig();
	if frostyCfg ~= nil and frostyCfg.kind == "frosty" then
		local keepH = math.floor(iH * 0.45);
		if keepH < 5 then
			keepH = 5;
		end
		if keepH > iH then
			keepH = iH;
		end
		winY0 = iH - keepH;
		winY1 = iH;
	elseif cutPct > 0 then
		local keepH = math.floor(iH * (100 - cutPct) / 100);
		if keepH < 4 then
			keepH = 4;
		end
		if keepH > iH then
			keepH = iH;
		end
		if iH > keepH then
			winY0 = Map.Rand(iH - keepH + 1, "Explo back coast window");
		end
		winY1 = winY0 + keepH;
	end
	if winY0 > 0 or winY1 < iH then
		y = 0;
		while y < iH do
			if y < winY0 or y >= winY1 then
				local x = 0;
				while x <= 2 do
					plotTypes[y * iW + x + 1] = PlotTypes.PLOT_LAND;
					x = x + 1;
				end
			end
			y = y + 1;
		end
	end
	local placed = 0;
	local attempts = 0;
	while placed < nIslands and attempts < 90 do
		attempts = attempts + 1;
		local ySpan = iH - 2;
		if ySpan < 1 then
			ySpan = 1;
		end
		local iy = 1 + Map.Rand(ySpan, "NoWrap Island Y");
		local ix = 1;
		local i = iy * iW + ix + 1;
		if plotTypes[i] == PlotTypes.PLOT_OCEAN then
			local adjMainland = false;
			local dirs = evenN;
			if iy % 2 == 1 then
				dirs = oddN;
			end
			local d = 1;
			while d <= 6 do
				local nx = ix + dirs[d][1];
				local ny = iy + dirs[d][2];
				if ny >= 0 and ny < iH and nx >= 0 and nx < iW then
					if plotTypes[ny * iW + nx + 1] ~= PlotTypes.PLOT_OCEAN then
						if nx >= 2 then
							adjMainland = true;
						end
					end
				end
				d = d + 1;
			end
			if adjMainland == false then
				if Map.Rand(3, "NoWrap Island Hills") == 0 then
					plotTypes[i] = PlotTypes.PLOT_HILLS;
				else
					plotTypes[i] = PlotTypes.PLOT_LAND;
				end
				placed = placed + 1;
				if Map.Rand(2, "NoWrap Island Pair") == 0 then
					local pd = 1 + Map.Rand(6, "NoWrap Island PairDir");
					local px = ix + dirs[pd][1];
					local py = iy + dirs[pd][2];
					if py >= 1 and py < iH - 1 and px == 1 then
						local pi = py * iW + px + 1;
						if plotTypes[pi] == PlotTypes.PLOT_OCEAN then
							local pairMainland = false;
							local pdirs = evenN;
							if py % 2 == 1 then
								pdirs = oddN;
							end
							local e = 1;
							while e <= 6 do
								local ex = px + pdirs[e][1];
								local ey = py + pdirs[e][2];
								if ey >= 0 and ey < iH and ex >= 0 and ex < iW then
									if plotTypes[ey * iW + ex + 1] ~= PlotTypes.PLOT_OCEAN then
										if ex >= 2 then
											pairMainland = true;
										end
									end
								end
								e = e + 1;
							end
							if pairMainland == false then
								plotTypes[pi] = plotTypes[i];
							end
						end
					end
				end
			end
		end
	end
	y = 0;
	while y < iH do
		if y >= winY0 and y < winY1 then
			plotTypes[y * iW + 1] = PlotTypes.PLOT_OCEAN;
		end
		y = y + 1;
	end
	y = 0;
	while y < iH do
		local x = 0;
		while x <= 3 do
			local mx = iW - x - 1;
			local my = iH - y - 1;
			plotTypes[my * iW + mx + 1] = plotTypes[y * iW + x + 1];
			x = x + 1;
		end
		y = y + 1;
	end
end
-------------------------------------------------------------------------------
function FrostyInjectSnowForestResourceLists(self)
	local iW, iH = Map.GetGridSize();
	local skip = FillMireSkip(iW);
	local y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			local i = y * iW + x + 1;
			if skip[x] ~= true and self.playerCollisionData[i] ~= true then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil
					and plot:GetResourceType(-1) == -1
					and plot:GetTerrainType() == TerrainTypes.TERRAIN_SNOW then
					local pt = plot:GetPlotType();
					local feat = plot:GetFeatureType();
					if pt == PlotTypes.PLOT_LAND and feat == FeatureTypes.FEATURE_FOREST then
						table.insert(self.tundra_flat_including_forests, i);
						table.insert(self.extra_deer_list, i);
					elseif pt == PlotTypes.PLOT_HILLS then
						table.insert(self.hills_list, i);
						if feat == FeatureTypes.FEATURE_FOREST then
							table.insert(self.extra_deer_list, i);
							table.insert(self.hills_forest_list, i);
							table.insert(self.hills_covered_list, i);
						elseif feat == FeatureTypes.NO_FEATURE then
							table.insert(self.hills_open_list, i);
							table.insert(self.marble_list, i);
						end
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	local k = #self.forest_flat_that_are_not_tundra;
	while k >= 1 do
		local i = self.forest_flat_that_are_not_tundra[k];
		local px = (i - 1) % iW;
		local py = math.floor((i - 1) / iW);
		local plot = Map.GetPlot(px, py);
		if plot ~= nil and plot:GetTerrainType() == TerrainTypes.TERRAIN_SNOW then
			table.remove(self.forest_flat_that_are_not_tundra, k);
		end
		k = k - 1;
	end
	self.extra_deer_list = GetShuffledCopyOfTable(self.extra_deer_list);
	self.hills_list = GetShuffledCopyOfTable(self.hills_list);
	self.marble_list = GetShuffledCopyOfTable(self.marble_list);
end
------------------------------------------------------------------------------
function FrostyAugmentLuxuryLists(lists, acceptXY)
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "frosty" or lists == nil then
		return lists
	end
	if lists[4] == nil or lists[5] == nil or lists[7] == nil or lists[14] == nil or lists[15] == nil then
		return lists
	end
	local iW, iH = Map.GetGridSize();
	local skip = FillMireSkip(iW);
	local y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			if skip[x] ~= true and acceptXY(x, y) then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil and plot:GetTerrainType() == TerrainTypes.TERRAIN_SNOW then
					local i = y * iW + x + 1;
					local pt = plot:GetPlotType();
					local feat = plot:GetFeatureType();
					if pt == PlotTypes.PLOT_LAND and feat == FeatureTypes.FEATURE_FOREST then
						table.insert(lists[14], i);
					elseif pt == PlotTypes.PLOT_HILLS then
						if feat == FeatureTypes.FEATURE_FOREST then
							table.insert(lists[7], i);
							table.insert(lists[5], i);
						elseif feat == FeatureTypes.NO_FEATURE then
							table.insert(lists[4], i);
						end
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	local kept = {};
	local k = 1;
	while k <= #lists[15] do
		local i = lists[15][k];
		local px = (i - 1) % iW;
		local py = math.floor((i - 1) / iW);
		local plot = Map.GetPlot(px, py);
		if plot == nil or plot:GetTerrainType() ~= TerrainTypes.TERRAIN_SNOW then
			table.insert(kept, i);
		end
		k = k + 1;
	end
	lists[15] = kept;
	return lists
end
------------------------------------------------------------------------------
local ASP_GenerateLuxuryPlotListsAtCitySite = AssignStartingPlots.GenerateLuxuryPlotListsAtCitySite;
function AssignStartingPlots:GenerateLuxuryPlotListsAtCitySite(x, y, radius, bRemoveFeatureIce)
	local lists = ASP_GenerateLuxuryPlotListsAtCitySite(self, x, y, radius, bRemoveFeatureIce);
	if bRemoveFeatureIce == true then
		return lists
	end
	return FrostyAugmentLuxuryLists(lists, function(px, py)
		return Map.PlotDistance(x, y, px, py) <= radius;
	end);
end
------------------------------------------------------------------------------
local ASP_GenerateLuxuryPlotListsInRegion = AssignStartingPlots.GenerateLuxuryPlotListsInRegion;
function AssignStartingPlots:GenerateLuxuryPlotListsInRegion(region_number)
	local lists = ASP_GenerateLuxuryPlotListsInRegion(self, region_number);
	local region_data_table = self.regionData[region_number];
	if region_data_table == nil then
		return lists
	end
	local iW, iH = Map.GetGridSize();
	local iWestX = region_data_table[1];
	local iSouthY = region_data_table[2];
	local iWidth = region_data_table[3];
	local iHeight = region_data_table[4];
	return FrostyAugmentLuxuryLists(lists, function(px, py)
		local rx = (px - iWestX) % iW;
		local ry = (py - iSouthY) % iH;
		return rx < iWidth and ry < iHeight;
	end);
end
------------------------------------------------------------------------------
local ASP_GenerateGlobalResourcePlotLists = AssignStartingPlots.GenerateGlobalResourcePlotLists;
function AssignStartingPlots:GenerateGlobalResourcePlotLists()
	ASP_GenerateGlobalResourcePlotLists(self);
	local cfg = GetBarrierConfig();
	if cfg ~= nil and cfg.kind == "wasteland" then
		local iW, iH = Map.GetGridSize();
		local skip = {};
		local cols = GetSnowWrapColumns(iW);
		local ci = 1;
		while ci <= #cols do
			skip[cols[ci]] = true;
			ci = ci + 1;
		end
		cols = GetSnowWrapTundraColumns(iW);
		ci = 1;
		while ci <= #cols do
			skip[cols[ci]] = true;
			ci = ci + 1;
		end
		local extraHills = {};
		local y = 0;
		while y < iH do
			local x = 0;
			while x < iW do
				local i = y * iW + x + 1;
				if skip[x] ~= true and self.playerCollisionData[i] ~= true then
					local plot = Map.GetPlot(x, y);
					if plot ~= nil
						and plot:GetPlotType() == PlotTypes.PLOT_HILLS
						and plot:GetTerrainType() == TerrainTypes.TERRAIN_TUNDRA
						and plot:GetFeatureType() == FeatureTypes.NO_FEATURE then
						table.insert(extraHills, i);
					end
				end
				x = x + 1;
			end
			y = y + 1;
		end
		local hi = 1;
		while hi <= #extraHills do
			table.insert(self.extra_deer_list, extraHills[hi]);
			hi = hi + 1;
		end
		self.extra_deer_list = GetShuffledCopyOfTable(self.extra_deer_list);
	end
	if cfg ~= nil and cfg.kind == "frosty" then
		FrostyInjectSnowForestResourceLists(self);
	end
	if IsSnowBarrier() == false then
		return
	end
	local iW, iH = Map.GetGridSize();
	for y = 0, iH - 1 do
		for x = 0, iW - 1 do
			local i = y * iW + x + 1;
			if self.playerCollisionData[i] ~= true then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil
					and plot:GetPlotType() == PlotTypes.PLOT_OCEAN
					and plot:GetResourceType(-1) == -1
					and plot:GetFeatureType() ~= FeatureTypes.FEATURE_ICE
					and plot:GetFeatureType() ~= self.feature_atoll
					and plot:GetTerrainType() == TerrainTypes.TERRAIN_COAST
					and plot:IsLake() then
					table.insert(self.coast_list, i);
					if plot:IsAdjacentToLand() and isMiddle(x) then
						table.insert(self.front_coast_list, i);
					end
				end
			end
		end
	end
	if cfg ~= nil and cfg.kind == "shores" then
		-- DEF drops lakes from the coast list, so island lakes would get
		-- nothing at all. Feed back the ones that did not take an atoll, so a
		-- lake ends up with either fish or an atoll.
		local lakes = ShoresOpenLakePlotIndices();
		local li = 1;
		while li <= #lakes do
			table.insert(self.coast_list, lakes[li]);
			li = li + 1;
		end
		-- Marble is written straight from marble_list and never passes through
		-- PlaceSpecificNumberOfResources, so filter it here instead.
		if self.marble_list ~= nil then
			local iWm, iHm = Map.GetGridSize();
			local keep = {};
			local mi = 1;
			while mi <= #self.marble_list do
				local idx = self.marble_list[mi];
				local mx = (idx - 1) % iWm;
				local my = (idx - mx - 1) / iWm;
				if ShoresLuxPlotOk(Map.GetPlot(mx, my)) then
					table.insert(keep, idx);
				end
				mi = mi + 1;
			end
			if #keep > 0 then
				self.marble_list = keep;
			end
		end
		print("Shores: lake fish sites", #lakes);
	end
	self.coast_list = GetShuffledCopyOfTable(self.coast_list);
	self.front_coast_list = GetShuffledCopyOfTable(self.front_coast_list);
	self.coast_next_to_land_list = GetShuffledCopyOfTable(self.coast_next_to_land_list);
end
------------------------------------------------------------------------------
local ASP_ExaminePlotForNaturalWondersEligibility = AssignStartingPlots.ExaminePlotForNaturalWondersEligibility;
function AssignStartingPlots:ExaminePlotForNaturalWondersEligibility(x, y)
	if ASP_ExaminePlotForNaturalWondersEligibility(self, x, y) == false then
		return false
	end
	if IsSnowBarrier() then
		local iW = Map.GetGridSize();
		local snowCols = GetSnowWrapColumns(iW);
		local tundraCols = GetSnowWrapTundraColumns(iW);
		local i = 1;
		while snowCols[i] ~= nil do
			if x == snowCols[i] then
				return false
			end
			i = i + 1;
		end
		i = 1;
		while tundraCols[i] ~= nil do
			if x == tundraCols[i] then
				return false
			end
			i = i + 1;
		end
	end
	return true
end
------------------------------------------------------------------------------
function GetMajorStartPlots()
	local starts = {};
	local nMaj = 22;
	if GameDefines ~= nil and GameDefines.MAX_MAJOR_CIVS ~= nil then
		nMaj = GameDefines.MAX_MAJOR_CIVS;
	end
	local i = 0;
	while i < nMaj do
		local player = Players[i];
		if player ~= nil and player:IsAlive() and player:GetStartingPlot() ~= nil then
			table.insert(starts, player:GetStartingPlot());
		end
		i = i + 1;
	end
	return starts;
end
------------------------------------------------------------------------------
function WonderTooCloseToCapital(x, y)
	local starts = GetMajorStartPlots();
	local i = 1;
	while i <= #starts do
		if Map.PlotDistance(x, y, starts[i]:GetX(), starts[i]:GetY()) <= 2 then
			return true
		end
		i = i + 1;
	end
	return false
end
------------------------------------------------------------------------------
local ASP_ExamineCandidatePlotForNaturalWondersEligibility = AssignStartingPlots.ExamineCandidatePlotForNaturalWondersEligibility;
function AssignStartingPlots:ExamineCandidatePlotForNaturalWondersEligibility(x, y)
	if WonderTooCloseToCapital(x, y) then
		return false
	end
	return ASP_ExamineCandidatePlotForNaturalWondersEligibility(self, x, y);
end
------------------------------------------------------------------------------
local ASP_AttemptToPlaceNaturalWonder = AssignStartingPlots.AttemptToPlaceNaturalWonder;
function AssignStartingPlots:AttemptToPlaceNaturalWonder(wonder_number, row_number)
	local orig = self.eligibility_lists[wonder_number];
	if orig == nil then
		return false
	end
	local iW = Map.GetGridSize();
	local kept = {};
	local i = 1;
	while orig[i] ~= nil do
		local plotIndex = orig[i];
		local x = (plotIndex - 1) % iW;
		local y = (plotIndex - x - 1) / iW;
		if WonderTooCloseToCapital(x, y) == false then
			table.insert(kept, plotIndex);
		end
		i = i + 1;
	end
	self.eligibility_lists[wonder_number] = kept;
	local ok = false;
	if #kept > 0 then
		ok = ASP_AttemptToPlaceNaturalWonder(self, wonder_number, row_number);
	end
	self.eligibility_lists[wonder_number] = orig;
	return ok;
end
------------------------------------------------------------------------------
function PurgeNearStartLakeFish()
	if IsSnowBarrier() == false then
		return
	end
	local fishID = GameInfoTypes["RESOURCE_FISH"];
	if fishID == nil then
		return
	end
	local iW, iH = Map.GetGridSize();
	local starts = {};
	for i = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
		local player = Players[i];
		if player ~= nil and player:IsAlive() and player:GetStartingPlot() ~= nil then
			table.insert(starts, player:GetStartingPlot());
		end
	end
	for y = 0, iH - 1 do
		for x = 0, iW - 1 do
			local plot = Map.GetPlot(x, y);
			if plot:GetResourceType(-1) == fishID and plot:IsWater() then
				local area = plot:Area();
				if area ~= nil and area:GetNumTiles() <= 6 then
					for _, startPlot in ipairs(starts) do
						if Map.PlotDistance(x, y, startPlot:GetX(), startPlot:GetY()) <= 4 then
							plot:SetResourceType(-1);
							break
						end
					end
				end
			end
		end
	end
end
------------------------------------------------------------------------------
function IsCappedSeaResource(res)
	if res == nil or res == -1 then
		return false
	end
	if res == GameInfoTypes["RESOURCE_FISH"] then
		return true
	end
	if res == GameInfoTypes["RESOURCE_PEARLS"] then
		return true
	end
	if res == GameInfoTypes["RESOURCE_WHALE"] then
		return true
	end
	if res == GameInfoTypes["RESOURCE_CORAL"] then
		return true
	end
	if res == GameInfoTypes["RESOURCE_CRAB"] then
		return true
	end
	return false
end
------------------------------------------------------------------------------
function GetWastelandSaltCoastPlotIndices(asp)
	local iW, iH = Map.GetGridSize();
	local skip = {};
	local cols = GetSnowWrapColumns(iW);
	local ci = 1;
	while ci <= #cols do
		skip[cols[ci]] = true;
		ci = ci + 1;
	end
	cols = GetSnowWrapTundraColumns(iW);
	ci = 1;
	while ci <= #cols do
		skip[cols[ci]] = true;
		ci = ci + 1;
	end
	local maxX = iW - 1;
	if DEF_MIRRORED == 1 then
		maxX = math.floor(iW * 0.5);
	end
	local list = {};
	local y = 0;
	while y < iH do
		local x = 0;
		while x <= maxX do
			if skip[x] ~= true then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil
					and plot:GetPlotType() == PlotTypes.PLOT_OCEAN
					and plot:GetTerrainType() == TerrainTypes.TERRAIN_COAST
					and plot:IsLake() == false
					and plot:IsAdjacentToLand()
					and plot:GetResourceType(-1) == -1 then
					local feat = plot:GetFeatureType();
					if feat ~= FeatureTypes.FEATURE_ICE and (asp == nil or asp.feature_atoll == nil or feat ~= asp.feature_atoll) then
						table.insert(list, y * iW + x + 1);
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	return list;
end
------------------------------------------------------------------------------
function CountWastelandResource(resID)
	local n = 0;
	if resID == nil then
		return 0
	end
	local iW, iH = Map.GetGridSize();
	local maxX = iW - 1;
	if DEF_MIRRORED == 1 then
		maxX = math.floor(iW * 0.5);
	end
	local y = 0;
	while y < iH do
		local x = 0;
		while x <= maxX do
			local plot = Map.GetPlot(x, y);
			if plot ~= nil and plot:GetResourceType(-1) == resID then
				n = n + 1;
			end
			x = x + 1;
		end
		y = y + 1;
	end
	return n
end
------------------------------------------------------------------------------
function ForceWastelandCoastalLuxuries(asp)
	if IsExploBalance() then
		return
	end
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "wasteland" then
		return
	end
	if asp == nil then
		return
	end
	local picked = asp.wastelandForcedCoastalLux;
	if picked == nil or #picked < 1 then
		return
	end
	local want = 5;
	local i = 1;
	while i <= #picked do
		local id = picked[i];
		local have = CountWastelandResource(id);
		if have < want then
			local plots = GetShuffledCopyOfTable(GetWastelandSaltCoastPlotIndices(asp));
			local left = asp:PlaceSpecificNumberOfResources(id, 1, want - have, 1, 2, 1, 2, plots);
			print("Wasteland coastal lux force id", id, "had", have, "left", left);
		end
		i = i + 1;
	end
end
------------------------------------------------------------------------------
function IsFrostySnowAreaWater(plot)
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "frosty" then
		return false
	end
	if plot == nil or plot:IsWater() == false then
		return false
	end
	local iW, iH = Map.GetGridSize();
	local yNorm = 0;
	if iH > 1 then
		yNorm = plot:GetY() / (iH - 1);
	end
	if yNorm >= 0.55 then
		return true
	end
	if CountAdjacentTerrain(plot, TerrainTypes.TERRAIN_SNOW) > 0 then
		return true
	end
	return false
end
------------------------------------------------------------------------------
function CapSeaResources()
	local cap = 17;
	if IsExploBalance() then
		cap = 14;
	end
	local iW, iH = Map.GetGridSize();
	local maxX = iW;
	if DEF_MIRRORED == 1 then
		maxX = iW * 0.5;
	end
	local fishID = GameInfoTypes["RESOURCE_FISH"];
	local protectCoastalLux = false;
	local cfg = GetBarrierConfig();
	if cfg ~= nil and cfg.kind == "wasteland" and IsExploBalance() == false then
		protectCoastalLux = true;
	end
	local snowFishPlots = {};
	local fishPlots = {};
	local otherPlots = {};
	local y = 0;
	while y < iH do
		local x = 0;
		while x <= maxX do
			local plot = Map.GetPlot(x, y);
			if plot ~= nil and plot:IsWater() then
				local res = plot:GetResourceType(-1);
				if IsCappedSeaResource(res) then
					if res == fishID then
						if IsFrostySnowAreaWater(plot) then
							table.insert(snowFishPlots, plot);
						else
							table.insert(fishPlots, plot);
						end
					elseif protectCoastalLux == false then
						table.insert(otherPlots, plot);
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	local nFish = #fishPlots;
	local nSnowFish = #snowFishPlots;
	local n = nFish + nSnowFish + #otherPlots;
	if n <= cap then
		print("Sea resources (pre-mirror):", n, "fish=", nFish, "snowFish=", nSnowFish);
		return
	end
	local excess = n - cap;
	local removedFish = 0;
	local fishShuffled = GetShuffledCopyOfTable(fishPlots);
	local i = 1;
	while i <= nFish and removedFish < excess do
		fishShuffled[i]:SetResourceType(-1);
		removedFish = removedFish + 1;
		i = i + 1;
	end
	local stillNeed = excess - removedFish;
	if stillNeed > 0 then
		local otherShuffled = GetShuffledCopyOfTable(otherPlots);
		local j = 1;
		while j <= stillNeed and j <= #otherShuffled do
			otherShuffled[j]:SetResourceType(-1);
			j = j + 1;
		end
		stillNeed = stillNeed - (j - 1);
	end
	if stillNeed > 0 then
		local snowShuffled = GetShuffledCopyOfTable(snowFishPlots);
		local k = 1;
		while k <= stillNeed and k <= #snowShuffled do
			snowShuffled[k]:SetResourceType(-1);
			removedFish = removedFish + 1;
			k = k + 1;
		end
	end
	print("Sea resources (pre-mirror) capped:", n, "->", cap, "removed fish=", removedFish, "kept snowFish");
end
-------------------------------------------------------------------------------
function MultilayeredFractal:GeneratePlotsByRegion()
	-- Sirian's MultilayeredFractal controlling function.
	-- You -MUST- customize this function for each script using MultilayeredFractal.
	--
	-- This implementation is specific to West vs East.
	local iW, iH = Map.GetGridSize();
	local fracFlags = {};
	local SplitOps = Map.GetCustomOption(OPT_CENTER_SPLIT);

	-- Fill all rows with land plots.
	self.wholeworldPlotTypes = table.fill(PlotTypes.PLOT_LAND, iW * iH);

	if false then -- Ocean Strip
	
		-- Add strip of ocean to middle of map --- Always start with this for civ placements
		for y = 0, iH - 1 do
			for x = math.floor(iW / 2) - 2, math.floor(iW / 2) + 1 do
				local plotIndex = y * iW + x + 1;
				--if y >= math.floor(iH / 2) - 2 and y <= math.floor(iH / 2) + 1 then
					--if x == math.floor(iW / 2) or x == math.floor(iW / 2) - 1 then
						--self.wholeworldPlotTypes[plotIndex] = PlotTypes.PLOT_OCEAN;
					--end
				--else
					self.wholeworldPlotTypes[plotIndex] = PlotTypes.PLOT_OCEAN;
				--end
			end
		end
	elseif false then -- Landbridges
		
		-- Add strip of ocean to middle of map --- Always start with this for civ placements
		for y = 4, iH - 5 do
			for x = math.floor(iW / 2) - 2, math.floor(iW / 2) + 1 do
				local plotIndex = y * iW + x + 1;
				if y >= math.floor(iH / 2) - 2 and y <= math.floor(iH / 2) + 1 then
					if x == math.floor(iW / 2) or x == math.floor(iW / 2) - 1 then
						--self.wholeworldPlotTypes[plotIndex] = PlotTypes.PLOT_OCEAN;
					end
				else
					self.wholeworldPlotTypes[plotIndex] = PlotTypes.PLOT_OCEAN;
				end
			end
		end
	end
	if false then -- Barrier Islands
		
		-- Add strip of ocean to middle of map --- Always start with this for civ placements
		for y = 0, iH - 1 do
			for x = math.floor(iW / 2) - 2, math.floor(iW / 2) + 1 do
				local plotIndex = y * iW + x + 1;
					self.wholeworldPlotTypes[plotIndex] = PlotTypes.PLOT_OCEAN;
			end
		end
		local x_middle = math.floor(iW / 2) - 5;
		for y = 0, iH do
			local plotIndex = y * iW + x_middle + 1;
			self.wholeworldPlotTypes[plotIndex] = PlotTypes.PLOT_OCEAN;
		end
		local outer_half = {};
		for loop = 1, iH - 2 do
			table.insert(outer_half, loop);
		end
		local outer_shuffled = GetShuffledCopyOfTable(outer_half)
		local iNumOuterPerColumn = math.floor(iH * 0.67);
		local x_outer = math.floor((iW / 2) - 4);
		for loop = 1, iNumOuterPerColumn do
			local y_outer = outer_shuffled[loop];
			local i_outer_plot = y_outer * iW + x_outer + 1;
			self.wholeworldPlotTypes[i_outer_plot] = PlotTypes.PLOT_OCEAN;
		end
		local x_outerst = math.floor((iW / 2) - 3);
		local iNumOuterstPerColumn = math.floor(iH * 0.33);
		for loop = 1, iNumOuterstPerColumn do
			local y_outerst = outer_shuffled[loop];
			local i_outerst_plot = y_outerst * iW + x_outerst + 1;
			self.wholeworldPlotTypes[i_outerst_plot] = PlotTypes.PLOT_OCEAN;
		end
		local inner_half = {};
		for loop = 1, iH - 2 do
			table.insert(inner_half, loop);
		end
		local inner_shuffled = GetShuffledCopyOfTable(inner_half)
		local iNumInnerPerColumn = math.max(math.floor(iH * 0.33), math.floor((iH / 3) - 1));
		local x_inner = math.floor((iW / 2) - 6);	
		for loop = 1, iNumInnerPerColumn do
			local y_inner = inner_shuffled[loop];
			local i_inner_plot = y_inner * iW + x_inner + 1;
			self.wholeworldPlotTypes[i_inner_plot] = PlotTypes.PLOT_OCEAN;
		end
		local x_innerst = math.floor((iW / 2) - 7);
		local iNumInnerstPerColumn = math.floor(iH * 0.17);
		for loop = 1, iNumInnerstPerColumn do
			local y_innerst = inner_shuffled[loop];
			local i_innerst_plot = y_innerst * iW + x_innerst + 1;
			self.wholeworldPlotTypes[i_innerst_plot] = PlotTypes.PLOT_OCEAN;
		end
	end
	if not IsSnowWrapX() and not IsShores() then
		for x = 0, 0 do
			for y = 1, iH - 2 do
				local i = y * iW + x + 1;
				self.wholeworldPlotTypes[i] = PlotTypes.PLOT_HILLS;
			end
		end
		

		for x = 0, 0 do
			local i = x + 1;
			self.wholeworldPlotTypes[i] = PlotTypes.PLOT_MOUNTAIN;
			local i = (iH - 1) * iW + x + 1;
			self.wholeworldPlotTypes[i] = PlotTypes.PLOT_MOUNTAIN;
		end
		local west_half = {};
		for loop = 1, iH - 2 do
			table.insert(west_half, loop);
		end
		local west_shuffled = GetShuffledCopyOfTable(west_half)
		local iNumMountainsPerColumn = math.max(math.floor(iH * 0.33), math.floor((iH / 3) - 1));
		local x_west = 3;
		if IsSnowNoWrap() then
			x_west = 2;
		end
		for loop = 1, iNumMountainsPerColumn do
			local y_west = west_shuffled[loop];
			local i_west_plot = y_west * iW + x_west + 1;
			self.wholeworldPlotTypes[i_west_plot] = PlotTypes.PLOT_OCEAN;
		end
		-- Add strips of ocean to the world borders.
		local rimW = 2;
		if IsSnowNoWrap() then
			rimW = 1;
		end
		for y = 0, iH do
			for x = 0, rimW do
				local plotIndex = y * iW + x + 1;
				self.wholeworldPlotTypes[plotIndex] = PlotTypes.PLOT_OCEAN;
			end
		end
		for y = 0, iH do
			for x = iW - 1 - rimW, iW do
				local plotIndex = y * iW + x + 1;
				self.wholeworldPlotTypes[plotIndex] = PlotTypes.PLOT_OCEAN;
			end
		end
	end

	-- Add lakes.
	local lakesFrac = Fractal.Create(iW, iH, lake_grain, fracFlags, 6, 6);
	local iLakesThreshold = lakesFrac:GetHeight(92);
	for y = 0, iH - 1 do
		for x = 0, iW - 1 do
			local i = y * iW + x + 1; -- add one because Lua arrays start at 1
			local lakeVal = lakesFrac:GetHeight(x, y);
			if lakeVal >= iLakesThreshold then
				--self.wholeworldPlotTypes[i] = PlotTypes.PLOT_OCEAN;
			end
		end
	end


	-- Land and water are set. Now apply hills and mountains.
	local world_age = DEF_WORLD_AGE;
	if world_age == 4 then
		world_age = 1 + Map.Rand(3, "Random World Age - Lua");
	end
	local args = {world_age = world_age};
	if IsShores() then
		-- Build land and water first so ApplyTectonics gives the islands their
		-- hills and mountains; it skips PLOT_OCEAN, so the sea is untouched.
		ShoresBuildPlotTypes(self.wholeworldPlotTypes, iW, iH);
	end
	self:ApplyTectonics(args)
	if IsShores() then
		ShoresMirrorField(self.wholeworldPlotTypes, iW, iH);
	end
	
	if false then -- Skirmish
		for x = iW / 2 - 2, iW / 2 + 1 do
			for y = 1, iH - 2 do
				local i = y * iW + x + 1;
				self.wholeworldPlotTypes[i] = PlotTypes.PLOT_LAND;
			end
		end
		for x = iW / 2 - 2, iW / 2 + 1 do
			local i = x + 1;
			self.wholeworldPlotTypes[i] = PlotTypes.PLOT_MOUNTAIN;
			local i = (iH - 1) * iW + x + 1;
			self.wholeworldPlotTypes[i] = PlotTypes.PLOT_MOUNTAIN;
		end
		local west_half, east_half = {}, {};
		for loop = 1, iH - 2 do
			table.insert(west_half, loop);
			table.insert(east_half, loop);
		end
		local west_shuffled = GetShuffledCopyOfTable(west_half)
		local east_shuffled = GetShuffledCopyOfTable(east_half)
		local iNumMountainsPerColumn = math.max(math.floor(iH * 0.225), math.floor((iH / 4) - 1));
		local x_west, x_east = iW / 2 - 1, iW / 2;
		for loop = 1, iNumMountainsPerColumn do
			local y_west, y_east = west_shuffled[loop], iH - 1- west_shuffled[loop];
			local i_west_plot = y_west * iW + x_west + 1;
			local i_east_plot = y_east * iW + x_east + 1;
			self.wholeworldPlotTypes[i_west_plot] = PlotTypes.PLOT_MOUNTAIN;
			self.wholeworldPlotTypes[i_east_plot] = PlotTypes.PLOT_MOUNTAIN;
		end
	end
	if IsOldSnow() then
		for x = iW / 2 - 4, iW / 2 + 3 do
			for y = 0, iH - 1 do
				local i = y * iW + x + 1;
				self.wholeworldPlotTypes[i] = PlotTypes.PLOT_LAND;
			end
		end
		local west_half, east_half = {}, {};
		for loop = 1, iH - 2 do
			table.insert(west_half, loop);
			table.insert(east_half, loop);
		end
		local west_shuffled = GetShuffledCopyOfTable(west_half)
		local east_shuffled = GetShuffledCopyOfTable(east_half)

		local mountainOps = Map.GetCustomOption(OPT_FRONT_MOUNTAIN)
		local mountainDensity = .20 + .05 * mountainOps

		local iNumMountainsPerColumn = math.floor(iH * mountainDensity);
		local x_west, x_east = iW / 2 - 4, iW / 2 + 3;
		for loop = 1, iNumMountainsPerColumn do
			local y_west, y_east = west_shuffled[loop], iH - 1- west_shuffled[loop];
			local i_west_plot = y_west * iW + x_west + 1;
			local i_east_plot = y_east * iW + x_east + 1;
			self.wholeworldPlotTypes[i_west_plot] = PlotTypes.PLOT_MOUNTAIN;
			self.wholeworldPlotTypes[i_east_plot] = PlotTypes.PLOT_MOUNTAIN;
		end
	end
	if IsSnowBarrier() and not IsShores() then
		local cfg = GetBarrierConfig();
		local mountainOps = Map.GetCustomOption(OPT_FRONT_MOUNTAIN)
		local mountainDensity = .20 + .05 * mountainOps
		if cfg.kind == "peaks" then
			PlacePeaksFrontClusters(self.wholeworldPlotTypes, iW, iH, iW / 2 - 4, mountainDensity);
			if IsSnowWrapX() then
				local x_wrap_west = GetSnowWrapLandMountainXs(iW);
				PlacePeaksFrontClusters(self.wholeworldPlotTypes, iW, iH, x_wrap_west, mountainDensity);
			end
		elseif cfg.chaoticMountains then
			PlaceChaoticFrontRidge(self.wholeworldPlotTypes, iW, iH, iW / 2 - 4, mountainDensity);
			if IsSnowWrapX() then
				local x_wrap_west = GetSnowWrapLandMountainXs(iW);
				PlaceChaoticFrontRidge(self.wholeworldPlotTypes, iW, iH, x_wrap_west, mountainDensity);
			end
		else
			local west_half = {};
			for loop = 1, iH - 2 do
				table.insert(west_half, loop);
			end
			local iNumMountainsPerColumn = math.floor(iH * mountainDensity);

			local front_shuffled = GetShuffledCopyOfTable(west_half)
			local x_west, x_east = iW / 2 - 4, iW / 2 + 3;
			for loop = 1, iNumMountainsPerColumn do
				local y_west, y_east = front_shuffled[loop], iH - 1 - front_shuffled[loop];
				self.wholeworldPlotTypes[y_west * iW + x_west + 1] = PlotTypes.PLOT_MOUNTAIN;
				self.wholeworldPlotTypes[y_east * iW + x_east + 1] = PlotTypes.PLOT_MOUNTAIN;
			end

			if IsSnowWrapX() then
				local wrap_shuffled = GetShuffledCopyOfTable(west_half)
				local x_wrap_west, x_wrap_east = GetSnowWrapLandMountainXs(iW);
				for loop = 1, iNumMountainsPerColumn do
					local y_west, y_east = wrap_shuffled[loop], iH - 1 - wrap_shuffled[loop];
					self.wholeworldPlotTypes[y_west * iW + x_wrap_west + 1] = PlotTypes.PLOT_MOUNTAIN;
					self.wholeworldPlotTypes[y_east * iW + x_wrap_east + 1] = PlotTypes.PLOT_MOUNTAIN;
				end
			end
		end

		-- Interior lakes + polar water. At least 3 columns from both snow seams.
		local minX, maxX = GetSnowWrapWaterBounds(iW);
		local lakeMinX = minX;
		local lakeMaxX = maxX;
		if cfg.kind == "desert" then
			lakeMinX, lakeMaxX = GetDesertWaterStrip(iW);
		end
		local polarMinX = minX;
		local polarMaxX = maxX;
		if cfg.kind == "desert" then
			polarMinX = lakeMinX;
			polarMaxX = lakeMaxX;
		end
		local function hexNeighbors(x, y)
			if y % 2 == 0 then
				return {{0, 1}, {1, 0}, {0, -1}, {-1, -1}, {-1, 0}, {-1, 1}};
			end
			return {{1, 1}, {1, 0}, {1, -1}, {0, -1}, {-1, 0}, {0, 1}};
		end
		local polarIslandPlots = {};
		local polarRadius = 0;
		local polarCap = 0;
		local polarInland = 0;
		if polarMinX <= polarMaxX then
			local polarX = math.floor((polarMinX + polarMaxX) / 2);
			if cfg.kind == "desert" then
				polarCap = 1 + Map.Rand(2, "Snow Wrap Polar Cap");
			else
				polarCap = Map.Rand(3, "Snow Wrap Polar Cap");
			end
			if IsExploBalance() or cfg.kind == "frosty" then
				polarCap = 0;
			end
			if polarCap == 0 then
				polarCap = 0;
			else
				polarRadius = 3 + Map.Rand(3, "Snow Wrap Polar Inland");
				local maxIn = math.floor(iH / 4);
				if polarRadius > maxIn then
					polarRadius = maxIn;
				end
				if polarRadius < 3 then
					polarRadius = 3;
				end
				local polarY = 0;
				local yLo = 0;
				local yHi = polarRadius;
				if polarCap == 2 then
					polarY = iH - 1;
					yLo = iH - 1 - polarRadius;
					yHi = iH - 1;
				end
				local maxHalfW = math.min(polarX - polarMinX, polarMaxX - polarX);
				if maxHalfW < 1 then
					polarCap = 0;
				else
					local style = Map.Rand(3, "Snow Wrap Polar Shape");
					local halfW = 1;
					local inland = polarRadius;
					if style == 0 then
						halfW = 1 + Map.Rand(2, "Snow Wrap Polar SharpW");
						if halfW > maxHalfW then
							halfW = maxHalfW;
						end
					elseif style == 2 then
						halfW = maxHalfW;
						inland = 2 + Map.Rand(2, "Snow Wrap Polar WideIn");
						if polarCap == 1 then
							yHi = inland;
						else
							yLo = iH - 1 - inland;
						end
					else
						halfW = math.max(2, math.floor(maxHalfW / 2));
					end
					local seedX = polarX;
					if seedX < polarMinX then
						seedX = polarMinX;
					end
					if seedX > polarMaxX then
						seedX = polarMaxX;
					end
					local blob = {};
					table.insert(blob, {seedX, polarY});
					self.wholeworldPlotTypes[polarY * iW + seedX + 1] = PlotTypes.PLOT_OCEAN;
					local nBlob = 1;
					local target = 12 + Map.Rand(9, "Snow Wrap Polar Target");
					local step = 0;
					while nBlob < target do
						step = step + 1;
						if step > 80 then
							break
						end
						local candidates = {};
						local pIndex = 1;
						while pIndex <= nBlob do
							local p = blob[pIndex];
							local dirs = hexNeighbors(p[1], p[2]);
							local dIndex = 1;
							while dIndex <= 6 do
								local d = dirs[dIndex];
								local nx = p[1] + d[1];
								local ny = p[2] + d[2];
								local dx = nx - seedX;
								if dx < 0 then
									dx = 0 - dx;
								end
								if nx >= polarMinX and nx <= polarMaxX and ny >= yLo and ny <= yHi and dx <= halfW then
									local idx = ny * iW + nx + 1;
									if self.wholeworldPlotTypes[idx] ~= PlotTypes.PLOT_OCEAN then
										table.insert(candidates, {nx, ny, idx});
									end
								end
								dIndex = dIndex + 1;
							end
							pIndex = pIndex + 1;
						end
						local nCands = table.maxn(candidates);
						if nCands < 1 then
							break
						end
						local pick = candidates[Map.Rand(nCands, "Snow Wrap Polar Grow") + 1];
						self.wholeworldPlotTypes[pick[3]] = PlotTypes.PLOT_OCEAN;
						table.insert(blob, {pick[1], pick[2]});
						nBlob = nBlob + 1;
					end
					if nBlob >= 6 then
						local iIsland = 2;
						while iIsland <= nBlob do
							local t = blob[iIsland];
							local surrounded = true;
							local dirs = hexNeighbors(t[1], t[2]);
							local dIndex = 1;
							while dIndex <= 6 do
								local d = dirs[dIndex];
								local nx = t[1] + d[1];
								local ny = t[2] + d[2];
								if nx >= 0 and nx < iW and ny >= 0 and ny < iH then
									if self.wholeworldPlotTypes[ny * iW + nx + 1] ~= PlotTypes.PLOT_OCEAN then
										surrounded = false;
									end
								end
								dIndex = dIndex + 1;
							end
							if surrounded == true then
								self.wholeworldPlotTypes[t[2] * iW + t[1] + 1] = PlotTypes.PLOT_HILLS;
								table.insert(polarIslandPlots, {t[1], t[2]});
								break
							end
							iIsland = iIsland + 1;
						end
					end
					polarInland = inland;
					print("Snow Wrap polar cap=" .. tostring(polarCap) .. " tiles=" .. tostring(nBlob));
				end
			end
		end
		-- Keep interior lakes off the polar cap that exists.
		local minY = 3;
		local maxY = iH - 4;
		if polarCap == 1 and polarInland > 0 then
			minY = polarInland + 2;
		elseif polarCap == 2 and polarInland > 0 then
			maxY = iH - 1 - (polarInland + 2);
		end
		local function inLakeRect(x, y)
			return x >= minX and x <= maxX and y >= minY and y <= maxY;
		end
		local function neighborsFit(x, y)
			for _, d in ipairs(hexNeighbors(x, y)) do
				if not inLakeRect(x + d[1], y + d[2]) then
					return false
				end
			end
			return true
		end
		if minX <= maxX and minY <= maxY then
			local nBodies = Map.Rand(4, "Snow Wrap Lake Count");
			if cfg.kind == "desert" then
				minX = lakeMinX;
				maxX = lakeMaxX;
				nBodies = 2 + Map.Rand(2, "Snow Wrap Lake Count");
			end
			if UsesExploCoastShape() then
				local cutIgnored, seas = ResolveExploBackCoastPlan();
				nBodies = seas;
			elseif cfg.kind == "frosty" then
				nBodies = 1 + Map.Rand(2, "Frosty Inland Seas");
			end
			if minX > maxX then
				nBodies = 0;
			end
			for n = 1, nBodies do
				local lakeSize = 3 + Map.Rand(8, "Snow Wrap Lake Size");
				local circular = (Map.Rand(2, "Snow Wrap Lake Shape") == 0);
				if cfg.kind == "desert" then
					lakeSize = 5 + Map.Rand(8, "Snow Wrap Lake Size");
					circular = (Map.Rand(4, "Snow Wrap Lake Shape") == 0);
				elseif cfg.kind == "wetland" then
					lakeSize = 2 + Map.Rand(5, "Snow Wrap Lake Size");
				end
				local wantIsland = circular and lakeSize >= 6 and (Map.Rand(2, "Snow Wrap Lake Island") == 0);
				local seedX, seedY;
				for attempt = 1, 40 do
					local tx = minX + Map.Rand(maxX - minX + 1, "Snow Wrap Lake SeedX");
					local ty = minY + Map.Rand(maxY - minY + 1, "Snow Wrap Lake SeedY");
					local tidx = ty * iW + tx + 1;
					if self.wholeworldPlotTypes[tidx] ~= PlotTypes.PLOT_OCEAN then
						if (not wantIsland) or neighborsFit(tx, ty) then
							seedX, seedY = tx, ty;
							break
						end
					end
				end
				if seedX == nil and wantIsland then
					wantIsland = false;
					for attempt = 1, 40 do
						local tx = minX + Map.Rand(maxX - minX + 1, "Snow Wrap Lake SeedX");
						local ty = minY + Map.Rand(maxY - minY + 1, "Snow Wrap Lake SeedY");
						local tidx = ty * iW + tx + 1;
						if self.wholeworldPlotTypes[tidx] ~= PlotTypes.PLOT_OCEAN then
							seedX, seedY = tx, ty;
							break
						end
					end
				end
				if seedX ~= nil then
					if circular then
						local visited = {};
						local queue = {{seedX, seedY}};
						visited[seedY * iW + seedX] = true;
						local qi = 1;
						local painted = 0;
						while qi <= #queue and painted < lakeSize do
							local cx = queue[qi][1];
							local cy = queue[qi][2];
							qi = qi + 1;
							local skipSeed = wantIsland and cx == seedX and cy == seedY;
							if inLakeRect(cx, cy) then
								local idx = cy * iW + cx + 1;
								if (not skipSeed) and self.wholeworldPlotTypes[idx] ~= PlotTypes.PLOT_OCEAN then
									self.wholeworldPlotTypes[idx] = PlotTypes.PLOT_OCEAN;
									painted = painted + 1;
								end
								for _, d in ipairs(hexNeighbors(cx, cy)) do
									local nx = cx + d[1];
									local ny = cy + d[2];
									local nkey = ny * iW + nx;
									if inLakeRect(nx, ny) and visited[nkey] == nil then
										visited[nkey] = true;
										table.insert(queue, {nx, ny});
									end
								end
							end
						end
					else
						local blob = {{seedX, seedY}};
						self.wholeworldPlotTypes[seedY * iW + seedX + 1] = PlotTypes.PLOT_OCEAN;
						while #blob < lakeSize do
							local candidates = {};
							for _, p in ipairs(blob) do
								for _, d in ipairs(hexNeighbors(p[1], p[2])) do
									local nx = p[1] + d[1];
									local ny = p[2] + d[2];
									if inLakeRect(nx, ny) then
										local idx = ny * iW + nx + 1;
										if self.wholeworldPlotTypes[idx] ~= PlotTypes.PLOT_OCEAN then
											table.insert(candidates, {nx, ny, idx});
										end
									end
								end
							end
							if #candidates == 0 then
								break
							end
							local pick = candidates[Map.Rand(#candidates, "Snow Wrap Lake") + 1];
							self.wholeworldPlotTypes[pick[3]] = PlotTypes.PLOT_OCEAN;
							table.insert(blob, {pick[1], pick[2]});
						end
					end
				end
			end
		end
		for y = 0, iH - 1 do
			for x = 0, math.floor(iW / 2) - 1 do
				if self.wholeworldPlotTypes[y * iW + x + 1] == PlotTypes.PLOT_OCEAN then
					local mx = iW - x - 1;
					local my = iH - y - 1;
					self.wholeworldPlotTypes[my * iW + mx + 1] = PlotTypes.PLOT_OCEAN;
				end
			end
		end
		for _, p in ipairs(polarIslandPlots) do
			local mx = iW - p[1] - 1;
			local my = iH - p[2] - 1;
			self.wholeworldPlotTypes[my * iW + mx + 1] = self.wholeworldPlotTypes[p[2] * iW + p[1] + 1];
		end
	end
	if IsSnowNoWrap() and not IsShores() then
		ShapeNoWrapBackstrip(self.wholeworldPlotTypes, iW, iH);
	end
	FrostyApplySaltWater(self.wholeworldPlotTypes, iW, iH);
	-- Plot Type generation completed. Return global plot array.
	return self.wholeworldPlotTypes
end
------------------------------------------------------------------------------
function GeneratePlotTypes()
	print("Setting Plot Types (Lua West vs East) ...");
	WeeveeDbg("GeneratePlotTypes");

	local layered_world = MultilayeredFractal.Create();
	WeeveeDbg("GeneratePlotsByRegion");
	local plot_list = layered_world:GeneratePlotsByRegion();
	WeeveeDbg("GeneratePlotsByRegion done");
	local SplitOps = Map.GetCustomOption(OPT_CENTER_SPLIT);

	SetPlotTypes(plot_list);
	WeeveeDbg("SetPlotTypes done");

	if IsOldSnow() then
		local plot_list = layered_world:GeneratePlotsByRegion();
		local iW, iH = Map.GetGridSize();
		local firstRingYIsEven = {{0, 1}, {1, 0}, {0, -1}, {-1, -1}, {-1, 0}, {-1, 1}};
		local firstRingYIsOdd = {{1, 1}, {1, 0}, {1, -1}, {0, -1}, {-1, 0}, {0, 1}};
		for x = iW / 2 - 5, iW / 2 + 4 do
			for y = 1, iH - 2 do
				local plot = Map.GetPlot(x, y)
				if plot:IsFlatlands() then -- Check for adjacent Mountain plot; if found, change this plot to Hills.
					local isEvenY, search_table = true, {};
					if y / 2 > math.floor(y / 2) then
					isEvenY = false;
					end
					if isEvenY then
						search_table = firstRingYIsEven;
					else
						search_table = firstRingYIsOdd;
					end

					for loop, plot_adjustments in ipairs(search_table) do
						local searchX, searchY;
						searchX = x + plot_adjustments[1];
						searchY = y + plot_adjustments[2];
						local searchPlot = Map.GetPlot(searchX, searchY)
						local plotType = searchPlot:GetPlotType()
						if plotType == PlotTypes.PLOT_MOUNTAIN then
							plot:SetPlotType(PlotTypes.PLOT_HILLS, false, false)
							break
						end
					end
				end
			end
		end
	end
	if false then -- Skirmish foothills
		local iW, iH = Map.GetGridSize();
		local firstRingYIsEven = {{0, 1}, {1, 0}, {0, -1}, {-1, -1}, {-1, 0}, {-1, 1}};
		local firstRingYIsOdd = {{1, 1}, {1, 0}, {1, -1}, {0, -1}, {-1, 0}, {0, 1}};
		for x = iW / 2 - 2, iW / 2 + 1 do
			for y = 1, iH - 2 do
				local plot = Map.GetPlot(x, y)
				if plot:IsFlatlands() then -- Check for adjacent Mountain plot; if found, change this plot to Hills.
					local isEvenY, search_table = true, {};
					if y / 2 > math.floor(y / 2) then
					isEvenY = false;
					end
					if isEvenY then
						search_table = firstRingYIsEven;
					else
						search_table = firstRingYIsOdd;
					end

					for loop, plot_adjustments in ipairs(search_table) do
						local searchX, searchY;
						searchX = x + plot_adjustments[1];
						searchY = y + plot_adjustments[2];
						local searchPlot = Map.GetPlot(searchX, searchY)
						local plotType = searchPlot:GetPlotType()
						if plotType == PlotTypes.PLOT_MOUNTAIN then
							plot:SetPlotType(PlotTypes.PLOT_HILLS, false, false)
							break
						end
					end
				end
			end
		end
	end
	if IsSnowBarrier() then
		local iW, iH = Map.GetGridSize();
		local firstRingYIsEven = {{0, 1}, {1, 0}, {0, -1}, {-1, -1}, {-1, 0}, {-1, 1}};
		local firstRingYIsOdd = {{1, 1}, {1, 0}, {1, -1}, {0, -1}, {-1, 0}, {0, 1}};
		local function applyFoothills(xStart, xEnd, chance)
			if chance == nil then
				chance = 100;
			end
			for x = xStart, xEnd do
				for y = 1, iH - 2 do
					local plot = Map.GetPlot(x, y)
					if plot ~= nil and plot:IsFlatlands() then
						local isEvenY, search_table = true, {};
						if y / 2 > math.floor(y / 2) then
							isEvenY = false;
						end
						if isEvenY then
							search_table = firstRingYIsEven;
						else
							search_table = firstRingYIsOdd;
						end
						local nearMtn = false;
						for loop, plot_adjustments in ipairs(search_table) do
							local searchX = x + plot_adjustments[1];
							local searchY = y + plot_adjustments[2];
							local searchPlot = Map.GetPlot(searchX, searchY)
							if searchPlot ~= nil and searchPlot:GetPlotType() == PlotTypes.PLOT_MOUNTAIN then
								nearMtn = true;
								break
							end
						end
						if nearMtn then
							if chance >= 100 or Map.Rand(100, "Front Foothill") < chance then
								plot:SetPlotType(PlotTypes.PLOT_HILLS, false, false)
							end
						end
					end
				end
			end
		end
		local fLo = iW / 2 - 5;
		local fHi = iW / 2 + 4;
		local cfg = GetBarrierConfig();
		local foothillChance = 100;
		if cfg ~= nil and cfg.kind == "peaks" then
			fLo = iW / 2 - 6;
			fHi = iW / 2 + 5;
			foothillChance = 50;
		elseif cfg ~= nil and cfg.chaoticMountains then
			fLo = iW / 2 - 7;
			fHi = iW / 2 + 6;
		end
		applyFoothills(fLo, fHi, foothillChance)
		if IsSnowWrapX() then
			local x_wrap_west, x_wrap_east = GetSnowWrapLandMountainXs(iW);
			local wPad = 1;
			if cfg ~= nil and (cfg.chaoticMountains or cfg.kind == "peaks") then
				wPad = 2;
			end
			applyFoothills(x_wrap_west - wPad, x_wrap_west + wPad, foothillChance)
			applyFoothills(x_wrap_east - wPad, x_wrap_east + wPad, foothillChance)
		end
	end

	local args = {bExpandCoasts = false};
	GenerateCoasts(args);
	WeeveeDbg("GeneratePlotTypes done");
end
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
function TerrainGenerator:GetLatitudeAtPlot(iX, iY)
	return GetClimateLatitudeAtPlot(iX, iY);
end
----------------------------------------------------------------------------------
function GenerateTerrain()
	print("Generating Terrain (Lua West vs East) ...");
	WeeveeDbg("GenerateTerrain");
	
	-- Get Temperature setting input by user.
	local temp = DEF_TEMPERATURE;
	if temp == 4 then
		temp = 1 + Map.Rand(3, "Random Temperature - Lua");
	end

	local args = {temperature = temp};
	local cfg = GetBarrierConfig();
	if cfg ~= nil and cfg.kind == "desert" then
		args.fSnowLatitude = 1.1;
		args.fTundraLatitude = 1.1;
		args.iDesertPercent = 70;
		args.iPlainsPercent = 36;
		args.fGrassLatitude = 0.26;
		args.fDesertBottomLatitude = 0.66;
		args.fDesertTopLatitude = 1.05;
	elseif cfg ~= nil and cfg.kind == "wasteland" then
		args.fSnowLatitude = 1.1;
		args.fTundraLatitude = 0.0;
		args.iDesertPercent = 0;
		args.iPlainsPercent = 0;
		args.fGrassLatitude = 0.0;
		args.fDesertBottomLatitude = 1.1;
		args.fDesertTopLatitude = 1.1;
	elseif cfg ~= nil and cfg.kind == "wetland" then
		args.fSnowLatitude = 1.1;
		args.fTundraLatitude = 1.1;
		args.iDesertPercent = 0;
		args.iPlainsPercent = 28;
		args.fGrassLatitude = 0.5;
		args.fDesertBottomLatitude = 1.1;
		args.fDesertTopLatitude = 1.1;
	elseif cfg ~= nil and cfg.kind == "peaks" then
		args.fSnowLatitude = 1.1;
		args.fTundraLatitude = 1.1;
		args.iDesertPercent = 0;
		args.iPlainsPercent = 62;
		args.fGrassLatitude = 0.42;
		args.fDesertBottomLatitude = 1.1;
		args.fDesertTopLatitude = 1.1;
	elseif cfg ~= nil and cfg.kind == "frosty" then
		args.fSnowLatitude = 1.1;
		args.fTundraLatitude = 1.1;
		args.iDesertPercent = 0;
		args.iPlainsPercent = 40;
		args.fGrassLatitude = 0.38;
		args.fDesertBottomLatitude = 1.1;
		args.fDesertTopLatitude = 1.1;
	elseif cfg ~= nil and cfg.kind == "shores" then
		-- Islands get their terrain from AddShoresLayout's latitude regions;
		-- this pass only needs to keep tundra and snow off the west field so
		-- they stay exclusive to the barrier.
		args.fSnowLatitude = 1.1;
		args.fTundraLatitude = 1.1;
		args.iDesertPercent = 0;
		args.iPlainsPercent = 34;
		args.fGrassLatitude = 0.44;
		args.fDesertBottomLatitude = 1.1;
		args.fDesertTopLatitude = 1.1;
	end
	local terraingen = TerrainGenerator.Create(args);

	terrainTypes = terraingen:GenerateTerrain();
	
	SetTerrainTypes(terrainTypes);
	WeeveeDbg("SetTerrainTypes done");
	AddMireBands();
	AddPeaksLayout();
	AddFrostyLayout();
	AddShoresLayout();
	WeeveeDbg("GenerateTerrain done");
end
------------------------------------------------------------------------------



------------------------------------------------------------------------------
function FeatureGenerator:GetLatitudeAtPlot(iX, iY)
	return GetClimateLatitudeAtPlot(iX, iY);
end
------------------------------------------------------------------------------
function FeatureGenerator:AddIceAtPlot(plot, iX, iY, lat)
	return
end
------------------------------------------------------------------------------
function FeatureGenerator:AddJunglesAtPlot(plot, iX, iY, lat)
	local cfg = GetBarrierConfig();
	if cfg ~= nil and (cfg.kind == "wetland" or cfg.kind == "peaks" or cfg.kind == "frosty") then
		return
	end
	local jungle_height = self.jungles:GetHeight(iX, iY);
	if jungle_height <= self.iJungleTop and jungle_height >= self.iJungleBottom + (self.iJungleRange * lat) then
		if plot:CanHaveFeature(self.featureJungle) then
			plot:SetFeatureType(self.featureJungle, -1);
		end
	end
end
------------------------------------------------------------------------------
function FeatureGenerator:AddMarshAtPlot(plot, iX, iY, lat)
	local cfg = GetBarrierConfig();
	if cfg ~= nil and (cfg.kind == "wetland" or cfg.kind == "peaks" or cfg.kind == "frosty") then
		return
	end
	local marsh_height = self.marsh:GetHeight(iX, iY)
	if marsh_height >= self.iMarshLevel then
		if plot:CanHaveFeature(self.featureMarsh) then
			plot:SetFeatureType(self.featureMarsh, -1)
		end
	end
end
------------------------------------------------------------------------------
function FeatureGenerator:AddForestsAtPlot(plot, iX, iY, lat)
	local cfg = GetBarrierConfig();
	if cfg ~= nil and cfg.kind == "wetland" then
		return
	end
	if cfg ~= nil and cfg.kind == "frosty" then
		local t = plot:GetTerrainType();
		if t == TerrainTypes.TERRAIN_SNOW or t == TerrainTypes.TERRAIN_TUNDRA then
			return
		end
	end
	if cfg ~= nil and cfg.kind == "peaks" then
		local iW = Map.GetGridSize();
		local di = iY * iW + iX + 1;
		local d = peakDist[di];
		local mid = peakMassif[di];
		local fs = 2;
		if mid ~= nil and peakForestStyle[mid] ~= nil then
			fs = peakForestStyle[mid];
		end
		if fs == 3 then
			return
		end
		if d == nil or d < 1 then
			return
		end
		if plot:GetPlotType() ~= PlotTypes.PLOT_HILLS then
			return
		end
		if plot:GetFeatureType() ~= FeatureTypes.NO_FEATURE then
			return
		end
		local hit = (self.forests:GetHeight(iX, iY) >= self.iForestLevel) or (self.forestclumps:GetHeight(iX, iY) >= self.iClumpLevel);
		if fs == 1 then
			if d ~= 1 then
				return
			end
			if hit == false then
				return
			end
			if Map.Rand(100, "Peaks Forest Spec") >= 34 then
				return
			end
		else
			if d > 3 then
				return
			end
			if hit == false then
				return
			end
		end
		plot:SetFeatureType(self.featureForest, -1)
		return
	end
	if cfg == nil or cfg.kind ~= "wasteland" then
		if (self.forests:GetHeight(iX, iY) >= self.iForestLevel) or (self.forestclumps:GetHeight(iX, iY) >= self.iClumpLevel) then
			if plot:CanHaveFeature(self.featureForest) then
				plot:SetFeatureType(self.featureForest, -1)
			end
		end
		return
	end
	if (self.forests:GetHeight(iX, iY) >= self.iForestLevel) or (self.forestclumps:GetHeight(iX, iY) >= self.iClumpLevel) then
		local t = plot:GetTerrainType();
		if t ~= TerrainTypes.TERRAIN_GRASS and t ~= TerrainTypes.TERRAIN_PLAINS then
			return
		end
		if plot:IsWater() then
			return
		end
		if plot:GetPlotType() == PlotTypes.PLOT_MOUNTAIN then
			return
		end
		if plot:GetFeatureType() ~= FeatureTypes.NO_FEATURE then
			return
		end
		plot:SetFeatureType(self.featureForest, -1)
	end
end
------------------------------------------------------------------------------
function FeatureGenerator:AdjustTerrainTypes()
	local cfg = GetBarrierConfig();
	local softenArctic = true;
	if cfg ~= nil and (cfg.kind == "wasteland" or cfg.kind == "wetland" or cfg.kind == "peaks" or cfg.kind == "frosty") then
		softenArctic = false;
	end
	local width = self.iGridW - 1;
	local height = self.iGridH - 1;
	local y = 0;
	while y <= height do
		local x = 0;
		while x <= width do
			local plot = Map.GetPlot(x, y);
			if plot:GetFeatureType() == self.featureJungle then
				plot:SetTerrainType(self.terrainPlains, false, true)
			elseif softenArctic and plot:IsRiver() then
				local terrainType = plot:GetTerrainType();
				if terrainType == self.terrainTundra then
					plot:SetTerrainType(self.terrainPlains, false, true)
				elseif terrainType == self.terrainIce then
					plot:SetTerrainType(self.terrainTundra, false, true)
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
end
------------------------------------------------------------------------------
function MireLakeClusterSize(plot, iW, limit)
	-- Size of the water body this plot would join if it became a lake, counting
	-- the plot itself. Stops at limit so open ocean does not walk the map.
	local seen = {};
	local q = {};
	table.insert(q, plot);
	seen[plot:GetY() * iW + plot:GetX()] = true;
	local n = 0;
	local qi = 1;
	while qi <= #q do
		local p = q[qi];
		qi = qi + 1;
		n = n + 1;
		if n >= limit then
			return n;
		end
		local d = 0;
		while d < DirectionTypes.NUM_DIRECTION_TYPES do
			local adj = PlotDirNoXWrap(p:GetX(), p:GetY(), d);
			if adj ~= nil and adj:IsWater() then
				local k = adj:GetY() * iW + adj:GetX();
				if seen[k] == nil then
					seen[k] = true;
					table.insert(q, adj);
				end
			end
			d = d + 1;
		end
	end
	return n;
end
------------------------------------------------------------------------------
function AddLakes()
	print("Map Generation - Adding Lakes");
	WeeveeDbg("AddLakes");
	local numLakesAdded = 0;
	local iW = Map.GetGridSize();
	local lakePlotRand = ResolveLakeRand();
	for i, plot in Plots() do
		if not plot:IsWater() then
			if not plot:IsCoastalLand() then
				if not plot:IsRiver() then
					local bandRand = lakePlotRand;
					local bi = plot:GetY() * iW + plot:GetX() + 1;
					if mireBand[bi] == 3 then
						bandRand = 32;
					end
					local r = Map.Rand(bandRand, "MapGenerator AddLakes");
					if r == 0 then
						local allow = true;
						if IsSnowBarrier() then
							if WaterAllowedAtX(plot:GetX()) == false then
								allow = false;
							end
						end
						if allow and mireBand[bi] == 3 and MireLakeClusterSize(plot, iW, 4) >= 4 then
							allow = false;
						end
						if allow == true then
							plot:SetArea(-1);
							plot:SetPlotType(PlotTypes.PLOT_OCEAN);
							numLakesAdded = numLakesAdded + 1;
						end
					end
				end
			end
		end
	end
	ScrubWaterNearSnow();
	WeeveeDbg("AddLakes scrub done n=" .. tostring(numLakesAdded));
	if numLakesAdded > 0 then
		print(tostring(numLakesAdded).." lakes added")
		Map.CalculateAreas();
	elseif IsSnowBarrier() then
		Map.CalculateAreas();
	end
end
------------------------------------------------------------------------------
------------------------------------------------------------------------------
function AddDesertJungleBlob()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "desert" then
		return
	end
	local iW, iH = Map.GetGridSize();
	local y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			local plot = Map.GetPlot(x, y);
			if plot ~= nil and plot:GetFeatureType() == FeatureTypes.FEATURE_JUNGLE then
				plot:SetFeatureType(FeatureTypes.NO_FEATURE, -1);
			end
			x = x + 1;
		end
		y = y + 1;
	end
	local skip = {};
	local cols = GetSnowWrapColumns(iW);
	local ci = 1;
	while ci <= #cols do
		skip[cols[ci]] = true;
		ci = ci + 1;
	end
	cols = GetSnowWrapTundraColumns(iW);
	ci = 1;
	while ci <= #cols do
		skip[cols[ci]] = true;
		ci = ci + 1;
	end
	local mid = math.floor(iW / 2);
	local minX, maxX = GetSnowWrapWaterBounds(iW);
	if minX > maxX then
		minX = 1;
		maxX = mid - 2;
	end
	if maxX > mid - 1 then
		maxX = mid - 1;
	end
	if minX > maxX then
		return
	end
	local _, centerN = ResolveSnowWrapWidths();
	local frontX = mid - centerN / 2 - 2;
	if frontX > mid - 1 then
		frontX = mid - 1;
	end
	if frontX < maxX then
		frontX = maxX;
	end
	local rx = (maxX - minX) * 0.42;
	local ry = iH * 0.26;
	if rx < 2 then
		rx = 2;
	end
	if ry < 2 then
		ry = 2;
	end
	local cx = frontX - rx * 0.88;
	local cy = (iH - 1) / 2;
	local maxDy = math.floor(iH * 0.35);
	local yLo = cy - maxDy;
	local yHi = cy + maxDy;
	if yLo < 0 then
		yLo = 0;
	end
	if yHi > iH - 1 then
		yHi = iH - 1;
	end
	local placed = {};
	y = yLo;
	while y <= yHi do
		local yNorm = (y - cy) / maxDy;
		if yNorm < 0 then
			yNorm = 0 - yNorm;
		end
		local xTaper = 1.0 - 0.55 * yNorm;
		local x = minX;
		while x <= frontX do
			if skip[x] ~= true then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil then
					local plotType = plot:GetPlotType();
					if plotType == PlotTypes.PLOT_LAND or plotType == PlotTypes.PLOT_HILLS then
						local feat = plot:GetFeatureType();
						if feat ~= FeatureTypes.FEATURE_FLOOD_PLAINS and feat ~= FeatureTypes.FEATURE_ICE and feat ~= FeatureTypes.FEATURE_OASIS then
							local nx = (x - cx) / rx;
							if nx < 0 then
								nx = 0 - nx;
							end
							local ny = (y - cy) / ry;
							local d2 = (nx / xTaper) * (nx / xTaper) + ny * ny;
							local jitter = (Map.Rand(21, "Jungle Oval") - 8) / 100;
							local hole = 62;
							if d2 < 0.38 then
								hole = 50;
							end
							if d2 < (1.0 + jitter) and Map.Rand(100, "Jungle Hole") < hole then
								plot:SetTerrainType(TerrainTypes.TERRAIN_PLAINS, false, false);
								plot:SetFeatureType(FeatureTypes.FEATURE_JUNGLE, -1);
								table.insert(placed, {x, y});
							end
						end
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	local pass = 1;
	while pass <= 2 do
		local chance = 24 - pass * 8;
		local nPlaced = #placed;
		local i = 1;
		while i <= nPlaced do
			local px = placed[i][1];
			local py = placed[i][2];
			local yNorm = (py - cy) / maxDy;
			if yNorm < 0 then
				yNorm = 0 - yNorm;
			end
			local taperChance = chance;
			if yNorm > 0.5 then
				taperChance = math.floor(chance * 0.4);
			end
			local d = 0;
			while d < DirectionTypes.NUM_DIRECTION_TYPES do
				local adj = PlotDirNoXWrap(px, py, d);
				if adj ~= nil then
					local ax = adj:GetX();
					local ay = adj:GetY();
					if ax >= minX and ax <= frontX and ay >= yLo and ay <= yHi and skip[ax] ~= true then
						local plotType = adj:GetPlotType();
						if (plotType == PlotTypes.PLOT_LAND or plotType == PlotTypes.PLOT_HILLS)
							and adj:GetFeatureType() ~= FeatureTypes.FEATURE_JUNGLE
							and adj:GetFeatureType() ~= FeatureTypes.FEATURE_FLOOD_PLAINS
							and adj:GetFeatureType() ~= FeatureTypes.FEATURE_ICE
							and adj:GetFeatureType() ~= FeatureTypes.FEATURE_OASIS then
							if Map.Rand(100, "Jungle Sprawl") < taperChance then
								adj:SetTerrainType(TerrainTypes.TERRAIN_PLAINS, false, false);
								adj:SetFeatureType(FeatureTypes.FEATURE_JUNGLE, -1);
								table.insert(placed, {ax, ay});
							end
						end
					end
				end
				d = d + 1;
			end
			i = i + 1;
		end
		pass = pass + 1;
	end
	local nPlaced = #placed;
	local i = 1;
	while i <= nPlaced do
		local px = placed[i][1];
		local py = placed[i][2];
		local tnx = (px - cx) / rx;
		if tnx < 0 then
			tnx = 0 - tnx;
		end
		local tny = (py - cy) / ry;
		if tny < 0 then
			tny = 0 - tny;
		end
		local thin = 14;
		if tnx * tnx + tny * tny < 0.38 then
			thin = 24;
		end
		if Map.Rand(100, "Jungle Thin") < thin then
			local plot = Map.GetPlot(px, py);
			if plot ~= nil and plot:GetFeatureType() == FeatureTypes.FEATURE_JUNGLE then
				plot:SetFeatureType(FeatureTypes.NO_FEATURE, -1);
				if Map.Rand(100, "Jungle Gap Grass") < 40 then
					plot:SetTerrainType(TerrainTypes.TERRAIN_GRASS, false, false);
				end
			end
		end
		i = i + 1;
	end
	local rxFrame = (maxX - minX) * 0.58;
	local ryFrame = iH * 0.38;
	if rxFrame < 2 then
		rxFrame = 2;
	end
	if ryFrame < 2 then
		ryFrame = 2;
	end
	local landMinX = 0;
	local landMaxX = mid - 1;
	y = 0;
	while y < iH do
		local yNorm = (y - cy) / maxDy;
		if yNorm < 0 then
			yNorm = 0 - yNorm;
		end
		local xTaper = 1.0 - 0.62 * yNorm;
		if xTaper < 0.35 then
			xTaper = 0.35;
		end
		local x = landMinX;
		while x <= landMaxX do
			if skip[x] ~= true then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil then
					local plotType = plot:GetPlotType();
					local feat = plot:GetFeatureType();
					if plotType ~= PlotTypes.PLOT_MOUNTAIN
						and plotType ~= PlotTypes.PLOT_OCEAN
						and feat ~= FeatureTypes.FEATURE_JUNGLE
						and feat ~= FeatureTypes.FEATURE_FLOOD_PLAINS
						and feat ~= FeatureTypes.FEATURE_ICE
						and feat ~= FeatureTypes.FEATURE_OASIS then
						local nx = (x - cx) / rxFrame;
						if nx < 0 then
							nx = 0 - nx;
						end
						local ny = (y - cy) / ryFrame;
						local d2 = (nx / xTaper) * (nx / xTaper) + ny * ny;
						local jitter = (Map.Rand(17, "Desert Frame") - 6) / 100;
						local yEdge = (y == 0 or y == iH - 1);
						if yEdge or d2 > (1.0 + jitter) then
							if feat == FeatureTypes.FEATURE_FOREST then
								plot:SetFeatureType(FeatureTypes.NO_FEATURE, -1);
							end
							plot:SetTerrainType(TerrainTypes.TERRAIN_DESERT, false, false);
						elseif plot:GetTerrainType() == TerrainTypes.TERRAIN_DESERT then
							if Map.Rand(100, "Jungle Zone Grass") < 45 then
								plot:SetTerrainType(TerrainTypes.TERRAIN_GRASS, false, false);
							else
								plot:SetTerrainType(TerrainTypes.TERRAIN_PLAINS, false, false);
							end
						end
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	i = 1;
	local rim = {};
	while i <= nPlaced do
		local plot = Map.GetPlot(placed[i][1], placed[i][2]);
		if plot ~= nil and plot:GetFeatureType() == FeatureTypes.FEATURE_JUNGLE then
			local d = 0;
			while d < DirectionTypes.NUM_DIRECTION_TYPES do
				local adj = PlotDirNoXWrap(placed[i][1], placed[i][2], d);
				if adj ~= nil then
					local ax = adj:GetX();
					local plotType = adj:GetPlotType();
					if skip[ax] ~= true and ax >= minX and ax <= frontX
						and (plotType == PlotTypes.PLOT_LAND or plotType == PlotTypes.PLOT_HILLS)
						and adj:GetFeatureType() ~= FeatureTypes.FEATURE_JUNGLE
						and adj:GetFeatureType() ~= FeatureTypes.FEATURE_FLOOD_PLAINS
						and adj:GetFeatureType() ~= FeatureTypes.FEATURE_ICE
						and adj:GetFeatureType() ~= FeatureTypes.FEATURE_OASIS
						and adj:GetTerrainType() == TerrainTypes.TERRAIN_DESERT then
						if Map.Rand(100, "Jungle Rim") < 80 then
							if Map.Rand(100, "Jungle Rim Grass") < 32 then
								adj:SetTerrainType(TerrainTypes.TERRAIN_GRASS, false, false);
							else
								adj:SetTerrainType(TerrainTypes.TERRAIN_PLAINS, false, false);
							end
							table.insert(rim, {ax, adj:GetY()});
						end
					end
				end
				d = d + 1;
			end
		end
		i = i + 1;
	end
	i = 1;
	while i <= #rim do
		local d = 0;
		while d < DirectionTypes.NUM_DIRECTION_TYPES do
			local adj = PlotDirNoXWrap(rim[i][1], rim[i][2], d);
			if adj ~= nil then
				local ax = adj:GetX();
				local plotType = adj:GetPlotType();
				if skip[ax] ~= true and ax >= minX and ax <= frontX
					and (plotType == PlotTypes.PLOT_LAND or plotType == PlotTypes.PLOT_HILLS)
					and adj:GetFeatureType() ~= FeatureTypes.FEATURE_JUNGLE
					and adj:GetFeatureType() ~= FeatureTypes.FEATURE_FLOOD_PLAINS
					and adj:GetFeatureType() ~= FeatureTypes.FEATURE_ICE
					and adj:GetFeatureType() ~= FeatureTypes.FEATURE_OASIS
					and adj:GetTerrainType() == TerrainTypes.TERRAIN_DESERT then
					if Map.Rand(100, "Jungle Rim2") < 42 then
						if Map.Rand(100, "Jungle Rim2 Grass") < 22 then
							adj:SetTerrainType(TerrainTypes.TERRAIN_GRASS, false, false);
						else
							adj:SetTerrainType(TerrainTypes.TERRAIN_PLAINS, false, false);
						end
					end
				end
			end
			d = d + 1;
		end
		i = i + 1;
	end
	print("Desert jungle blob:", #placed);
	local fp = 0;
	y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			if skip[x] ~= true then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil and plot:CanHaveFeature(FeatureTypes.FEATURE_FLOOD_PLAINS) then
					plot:SetFeatureType(FeatureTypes.FEATURE_FLOOD_PLAINS, -1);
					fp = fp + 1;
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	print("Desert late floodplains:", fp);
end
------------------------------------------------------------------------------
function AddWetlandRiverDesert()
	do return end
	local pct = cfg.riverDesertPct;
	if pct == nil or pct < 1 then
		return
	end
	local iW, iH = Map.GetGridSize();
	local skip = {};
	local cols = GetSnowWrapColumns(iW);
	local ci = 1;
	while ci <= #cols do
		skip[cols[ci]] = true;
		ci = ci + 1;
	end
	cols = GetSnowWrapTundraColumns(iW);
	ci = 1;
	while ci <= #cols do
		skip[cols[ci]] = true;
		ci = ci + 1;
	end
	local mirrored = (DEF_MIRRORED == 1);
	local remaining = {};
	local y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			if skip[x] ~= true and ((not mirrored) or (x <= iW * 0.5)) then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil
					and plot:GetPlotType() == PlotTypes.PLOT_LAND
					and plot:IsRiver()
					and plot:GetTerrainType() ~= TerrainTypes.TERRAIN_DESERT then
					table.insert(remaining, plot);
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	local n = #remaining;
	local target = math.floor(n * (pct / 100) + 0.5);
	local placed = 0;
	while placed < target and #remaining > 0 do
		local totalWeight = 0;
		local i = 1;
		while i <= #remaining do
			local neigh = 0;
			local d = 0;
			while d < DirectionTypes.NUM_DIRECTION_TYPES do
				local adj = PlotDirNoXWrap(remaining[i]:GetX(), remaining[i]:GetY(), d);
				if adj ~= nil and adj:IsWater() == false and adj:GetTerrainType() == TerrainTypes.TERRAIN_DESERT then
					neigh = neigh + 1;
				end
				d = d + 1;
			end
			local w = 1;
			if neigh == 1 then
				w = 6;
			elseif neigh >= 2 then
				w = 10;
			end
			totalWeight = totalWeight + w;
			i = i + 1;
		end
		if totalWeight < 1 then
			break
		end
		local roll = Map.Rand(totalWeight, "Wetland River Desert");
		i = 1;
		local picked = false;
		while i <= #remaining do
			local neigh = 0;
			local d = 0;
			while d < DirectionTypes.NUM_DIRECTION_TYPES do
				local adj = PlotDirNoXWrap(remaining[i]:GetX(), remaining[i]:GetY(), d);
				if adj ~= nil and adj:IsWater() == false and adj:GetTerrainType() == TerrainTypes.TERRAIN_DESERT then
					neigh = neigh + 1;
				end
				d = d + 1;
			end
			local w = 1;
			if neigh == 1 then
				w = 6;
			elseif neigh >= 2 then
				w = 10;
			end
			if roll < w then
				remaining[i]:SetTerrainType(TerrainTypes.TERRAIN_DESERT, false, false);
				table.remove(remaining, i);
				placed = placed + 1;
				picked = true;
				break
			end
			roll = roll - w;
			i = i + 1;
		end
		if picked == false then
			remaining[#remaining]:SetTerrainType(TerrainTypes.TERRAIN_DESERT, false, false);
			table.remove(remaining, #remaining);
			placed = placed + 1;
		end
	end
	print("Wetland river desert:", placed, "/", n);
end
------------------------------------------------------------------------------
function AddFeatures()
	print("Adding Features (Lua West vs East) ...");

	-- Get Rainfall setting input by user.
	local rain = DEF_RAINFALL;
	if rain == 4 then
		rain = 1 + Map.Rand(3, "Random Rainfall - Lua");
	end
	
	local args = {rainfall = rain}
	local cfg = GetBarrierConfig();
	if cfg ~= nil and cfg.kind == "desert" then
		args.iJunglePercent = 0;
		args.iJungleFactor = 5;
		args.iForestPercent = 10;
		args.fMarshPercent = 2;
		args.iOasisPercent = 12;
	elseif cfg ~= nil and cfg.kind == "wasteland" then
		args.iJunglePercent = 0;
		args.iJungleFactor = 5;
		args.iForestPercent = 52;
		args.fMarshPercent = 1;
		args.iOasisPercent = 0;
	elseif cfg ~= nil and cfg.kind == "wetland" then
		args.iJunglePercent = 0;
		args.iJungleFactor = 5;
		args.iForestPercent = 0;
		args.fMarshPercent = 0;
		args.iOasisPercent = 0;
	elseif cfg ~= nil and cfg.kind == "peaks" then
		args.iJunglePercent = 0;
		args.iJungleFactor = 5;
		args.iForestPercent = 36;
		args.fMarshPercent = 0;
		args.iOasisPercent = 0;
	elseif cfg ~= nil and cfg.kind == "frosty" then
		args.iJunglePercent = 0;
		args.iJungleFactor = 5;
		args.iForestPercent = 28;
		args.fMarshPercent = 0;
		args.iOasisPercent = 0;
	elseif cfg ~= nil and cfg.kind == "shores" then
		args.iJunglePercent = 0;
		args.iJungleFactor = 5;
		args.iForestPercent = 26;
		args.fMarshPercent = 1;
		args.iOasisPercent = 0;
	end
	local featuregen = FeatureGenerator.Create(args);

	AddWastelandWaterLayout();
	featuregen:AddFeatures(true);
	AddDesertJungleBlob();
	AddMireFeatures();
	AddNorthIceArms();
	AddPeaksMassifForests();
	AddPeaksMeadows();
	AddPeaksBackCoastForest();
	AddFrostyForests();
	AddFrostyIce();
	AddShoresIslandFeatures();
	AddShoresLakeFeatures();
end
------------------------------------------------------------------------------
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function PlotDirNoXWrap(x, y, direction)
	local p = Map.PlotDirection(x, y, direction);
	if p == nil then
		return nil
	end
	if math.abs(p:GetX() - x) > 1 then
		return nil
	end
	return p;
end
------------------------------------------------------------------------------
function GetRiverValueAtPlot(plot)
	-- Custom method to force rivers to flow away from the map center.
	local iW, iH = Map.GetGridSize()
	local x = plot:GetX()
	local y = plot:GetY()
	local random_factor = Map.Rand(3, "River direction random factor - Skirmish LUA");
	local direction_influence_value = 0;--(math.abs(iW - (x - (iW / 2))) + ((math.abs(y - (iH / 2))) / 3)) * random_factor;

	local numPlots = PlotTypes.NUM_PLOT_TYPES;
	local sum = ((numPlots - plot:GetPlotType()) * 20) + direction_influence_value;

	local numDirections = DirectionTypes.NUM_DIRECTION_TYPES;
	for direction = 0, numDirections - 1 do
		local adjacentPlot = PlotDirNoXWrap(plot:GetX(), plot:GetY(), direction);
		if (adjacentPlot ~= nil) then
			sum = sum + (numPlots - adjacentPlot:GetPlotType());
		else
			sum = sum + (numPlots * 10);
		end
	end
	sum = sum + Map.Rand(10, "River Rand");

	return sum;
end
------------------------------------------------------------------------------
function DoRiver(startPlot, thisFlowDirection, originalFlowDirection, riverID)
	-- Customizing to handle problems in top row of the map. Only this aspect has been altered.

	local iW, iH = Map.GetGridSize()
	thisFlowDirection = thisFlowDirection or FlowDirectionTypes.NO_FLOWDIRECTION;
	originalFlowDirection = originalFlowDirection or FlowDirectionTypes.NO_FLOWDIRECTION;

	-- pStartPlot = the plot at whose SE corner the river is starting
	if (riverID == nil) then
		riverID = nextRiverID;
		nextRiverID = nextRiverID + 1;
	end

	local otherRiverID = _rivers[startPlot]
	if (otherRiverID ~= nil and otherRiverID ~= riverID and originalFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION) then
		return; -- Another river already exists here; can't branch off of an existing river!
	end

	local riverPlot;
	
	local bestFlowDirection = FlowDirectionTypes.NO_FLOWDIRECTION;
	if (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTH) then
	
		riverPlot = startPlot;
		local adjacentPlot = PlotDirNoXWrap(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_EAST);
		if ( adjacentPlot == nil or riverPlot:IsWOfRiver() or riverPlot:IsWater() or adjacentPlot:IsWater() ) then
			return;
		end

		_rivers[riverPlot] = riverID;
		riverPlot:SetWOfRiver(true, thisFlowDirection);
		RecordRiverEdge(riverPlot, "W", riverID);
		riverPlot = PlotDirNoXWrap(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_NORTHEAST);
		
	elseif (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTHEAST) then
	
		riverPlot = startPlot;
		local adjacentPlot = PlotDirNoXWrap(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_SOUTHEAST);
		if ( adjacentPlot == nil or riverPlot:IsNWOfRiver() or riverPlot:IsWater() or adjacentPlot:IsWater() ) then
			return;
		end

		_rivers[riverPlot] = riverID;
		riverPlot:SetNWOfRiver(true, thisFlowDirection);
		RecordRiverEdge(riverPlot, "NW", riverID);
		-- riverPlot does not change
	
	elseif (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST) then
	
		riverPlot = PlotDirNoXWrap(startPlot:GetX(), startPlot:GetY(), DirectionTypes.DIRECTION_EAST);
		if (riverPlot == nil) then
			return;
		end
		
		local adjacentPlot = PlotDirNoXWrap(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_SOUTHWEST);
		if (adjacentPlot == nil or riverPlot:IsNEOfRiver() or riverPlot:IsWater() or adjacentPlot:IsWater()) then
			return;
		end

		_rivers[riverPlot] = riverID;
		riverPlot:SetNEOfRiver(true, thisFlowDirection);
		RecordRiverEdge(riverPlot, "NE", riverID);
		-- riverPlot does not change
	
	elseif (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_SOUTH) then
	
		riverPlot = PlotDirNoXWrap(startPlot:GetX(), startPlot:GetY(), DirectionTypes.DIRECTION_SOUTHWEST);
		if (riverPlot == nil) then
			return;
		end
		
		local adjacentPlot = PlotDirNoXWrap(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_EAST);
		if (adjacentPlot == nil or riverPlot:IsWOfRiver() or riverPlot:IsWater() or adjacentPlot:IsWater()) then
			return;
		end
		
		_rivers[riverPlot] = riverID;
		riverPlot:SetWOfRiver(true, thisFlowDirection);
		RecordRiverEdge(riverPlot, "W", riverID);
		-- riverPlot does not change
	
	elseif (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST) then

		riverPlot = startPlot;
		local adjacentPlot = PlotDirNoXWrap(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_SOUTHEAST);
		if (adjacentPlot == nil or riverPlot:IsNWOfRiver() or riverPlot:IsWater() or adjacentPlot:IsWater()) then
			return;
		end
		
		_rivers[riverPlot] = riverID;
		riverPlot:SetNWOfRiver(true, thisFlowDirection);
		RecordRiverEdge(riverPlot, "NW", riverID);
		-- riverPlot does not change

	elseif (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTHWEST) then
		
		riverPlot = startPlot;
		local adjacentPlot = PlotDirNoXWrap(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_SOUTHWEST);
		
		if ( adjacentPlot == nil or riverPlot:IsNEOfRiver() or riverPlot:IsWater() or adjacentPlot:IsWater()) then
			return;
		end

		_rivers[riverPlot] = riverID;
		riverPlot:SetNEOfRiver(true, thisFlowDirection);
		RecordRiverEdge(riverPlot, "NE", riverID);
		riverPlot = PlotDirNoXWrap(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_WEST);

	else
		-- River is starting here, set the direction in the next step
		riverPlot = startPlot;		
	end

	if (riverPlot == nil or riverPlot:IsWater()) then
		-- The river has flowed off the edge of the map or into the ocean. All is well.
		return; 
	end

	-- Storing X,Y positions as locals to prevent redundant function calls.
	local riverPlotX = riverPlot:GetX();
	local riverPlotY = riverPlot:GetY();
	
	-- Table of methods used to determine the adjacent plot.
	local adjacentPlotFunctions = {
		[FlowDirectionTypes.FLOWDIRECTION_NORTH] = function() 
			return PlotDirNoXWrap(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_NORTHWEST); 
		end,
		
		[FlowDirectionTypes.FLOWDIRECTION_NORTHEAST] = function() 
			return PlotDirNoXWrap(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_NORTHEAST);
		end,
		
		[FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST] = function() 
			return PlotDirNoXWrap(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_EAST);
		end,
		
		[FlowDirectionTypes.FLOWDIRECTION_SOUTH] = function() 
			return PlotDirNoXWrap(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_SOUTHWEST);
		end,
		
		[FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST] = function() 
			return PlotDirNoXWrap(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_WEST);
		end,
		
		[FlowDirectionTypes.FLOWDIRECTION_NORTHWEST] = function() 
			return PlotDirNoXWrap(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_NORTHWEST);
		end	
	}
	
	if(bestFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION) then

		-- Attempt to calculate the best flow direction.
		local bestValue = math.huge;
		for flowDirection, getAdjacentPlot in pairs(adjacentPlotFunctions) do
			
			if (GetOppositeFlowDirection(flowDirection) ~= originalFlowDirection) then
				
				if (thisFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION or
					flowDirection == TurnRightFlowDirections[thisFlowDirection] or 
					flowDirection == TurnLeftFlowDirections[thisFlowDirection]) then
				
					local adjacentPlot = getAdjacentPlot();
					
					if (adjacentPlot ~= nil) then
					
						local value = GetRiverValueAtPlot(adjacentPlot);
						if (flowDirection == originalFlowDirection) then
							value = (value * 3) / 4;
						end
						
						if (value < bestValue) then
							bestValue = value;
							bestFlowDirection = flowDirection;
						end

					-- Custom addition for Highlands, to fix river problems in top row of the map. Any other all-land map may need similar special casing.
					elseif adjacentPlot == nil and riverPlotY == iH - 1 then -- Top row of map, needs special handling
						if flowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTH or
						   flowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTHWEST or
						   flowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTHEAST then
							
							local value = Map.Rand(5, "River Rand");
							if (flowDirection == originalFlowDirection) then
								value = (value * 3) / 4;
							end
							if (value < bestValue) then
								bestValue = value;
								bestFlowDirection = flowDirection;
							end
						end

					-- Custom addition for Highlands, to fix river problems in left column of the map. Any other all-land map may need similar special casing.
					elseif adjacentPlot == nil and riverPlotX == 0 then -- Left column of map, needs special handling
						if flowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTH or
						   flowDirection == FlowDirectionTypes.FLOWDIRECTION_SOUTH or
						   flowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTHWEST or
						   flowDirection == FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST then
							
							local value = Map.Rand(5, "River Rand");
							if (flowDirection == originalFlowDirection) then
								value = (value * 3) / 4;
							end
							if (value < bestValue) then
								bestValue = value;
								bestFlowDirection = flowDirection;
							end
						end
					end
				end
			end
		end
		
		-- Try a second pass allowing the river to "flow backwards".
		if(bestFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION) then
		
			local bestValue = math.huge;
			for flowDirection, getAdjacentPlot in pairs(adjacentPlotFunctions) do
			
				if (thisFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION or
					flowDirection == TurnRightFlowDirections[thisFlowDirection] or 
					flowDirection == TurnLeftFlowDirections[thisFlowDirection]) then
				
					local adjacentPlot = getAdjacentPlot();
					
					if (adjacentPlot ~= nil) then
						
						local value = GetRiverValueAtPlot(adjacentPlot);
						if (value < bestValue) then
							bestValue = value;
							bestFlowDirection = flowDirection;
						end
					end	
				end
			end
		end
	end
	
	--Recursively generate river.
	if (bestFlowDirection ~= FlowDirectionTypes.NO_FLOWDIRECTION) then
		if  (originalFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION) then
			originalFlowDirection = bestFlowDirection;
		end
		
		DoRiver(riverPlot, bestFlowDirection, originalFlowDirection, riverID);
	end
end
------------------------------------------------------------------------------
function RecordRiverEdge(plot, kind, riverID)
	if plot == nil or riverID == nil then
		return
	end
	if riverEdgeList[riverID] == nil then
		riverEdgeList[riverID] = {};
	end
	table.insert(riverEdgeList[riverID], {plot:GetX(), plot:GetY(), kind});
end
------------------------------------------------------------------------------
function RiverEdgeStillSet(plot, kind)
	if plot == nil then
		return false
	end
	if kind == "W" then
		return plot:IsWOfRiver();
	end
	if kind == "NW" then
		return plot:IsNWOfRiver();
	end
	if kind == "NE" then
		return plot:IsNEOfRiver();
	end
	return false;
end
------------------------------------------------------------------------------
function ClearRiverEdge(plot, kind)
	if plot == nil then
		return
	end
	if kind == "W" then
		plot:SetWOfRiver(false, FlowDirectionTypes.NO_FLOWDIRECTION);
	elseif kind == "NW" then
		plot:SetNWOfRiver(false, FlowDirectionTypes.NO_FLOWDIRECTION);
	elseif kind == "NE" then
		plot:SetNEOfRiver(false, FlowDirectionTypes.NO_FLOWDIRECTION);
	end
end
------------------------------------------------------------------------------
function RiverEdgesTouchWater(edges)
	local i = 1;
	while i <= #edges do
		local e = edges[i];
		local plot = Map.GetPlot(e[1], e[2]);
		if RiverEdgeStillSet(plot, e[3]) then
			if plot:IsWater() then
				return true
			end
			local d = 0;
			while d < DirectionTypes.NUM_DIRECTION_TYPES do
				local adj = PlotDirNoXWrap(plot:GetX(), plot:GetY(), d);
				if adj ~= nil and adj:IsWater() then
					return true
				end
				d = d + 1;
			end
		end
		i = i + 1;
	end
	return false;
end
------------------------------------------------------------------------------
function CullShortRivers()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "peaks" then
		return
	end
	local nDrop = 0;
	local rid, edges;
	for rid, edges in pairs(riverEdgeList) do
		local n = 0;
		local i = 1;
		while i <= #edges do
			local e = edges[i];
			if RiverEdgeStillSet(Map.GetPlot(e[1], e[2]), e[3]) then
				n = n + 1;
			end
			i = i + 1;
		end
		if n > 0 and n < 4 and RiverEdgesTouchWater(edges) == false then
			i = 1;
			while i <= #edges do
				local e = edges[i];
				ClearRiverEdge(Map.GetPlot(e[1], e[2]), e[3]);
				i = i + 1;
			end
			nDrop = nDrop + 1;
		end
	end
	print("Peaks short rivers dropped:", nDrop);
end
------------------------------------------------------------------------------
function AddRivers()

	-- Customization for Skirmish, to keep river starts away from buffer zone in middle columns of map, and set river "original flow direction".
	local iW, iH = Map.GetGridSize()
	print("Skirmish - Adding Rivers");
	riverEdgeList = {};
	local SplitOps = Map.GetCustomOption(OPT_CENTER_SPLIT)
	local snowRiverSkip = {};
	if IsOldSnow() or IsSnowBarrier() then
		local snowCols = GetSnowWrapColumns(iW);
		local tundraCols = GetSnowWrapTundraColumns(iW);
		local si = 1;
		local cfgRiversSkip = GetBarrierConfig();
		local peaksRiversSkip = (cfgRiversSkip ~= nil and cfgRiversSkip.kind == "peaks");
		while si <= #snowCols do
			if peaksRiversSkip == false then
				snowRiverSkip[snowCols[si]] = true;
			end
			si = si + 1;
		end
		if IsShores() then
			local sx = 0;
			local shoresHi = ShoresSeaHiX(iW);
			while sx <= shoresHi do
				snowRiverSkip[sx] = true;
				snowRiverSkip[iW - sx - 1] = true;
				sx = sx + 1;
			end
		end
		si = 1;
		while si <= #tundraCols do
			snowRiverSkip[tundraCols[si]] = true;
			si = si + 1;
		end
	end
	local passConditions = {
		function(plot)
			return plot:IsHills() or plot:IsMountain();
		end,
		
		function(plot)
			return (not plot:IsCoastalLand()) and (Map.Rand(8, "HBTMapGenerator AddRivers") == 0);
		end,
		
		function(plot)
			local area = plot:Area();
			local plotsPerRiverEdge = GameDefines["PLOTS_PER_RIVER_EDGE"];
			return (plot:IsHills() or plot:IsMountain()) and (area:GetNumRiverEdges() <	((area:GetNumTiles() / plotsPerRiverEdge) + 1));
		end,
		
		function(plot)
			local area = plot:Area();
			local plotsPerRiverEdge = GameDefines["PLOTS_PER_RIVER_EDGE"];
			return (area:GetNumRiverEdges() < (area:GetNumTiles() / plotsPerRiverEdge) + 1);
		end,

		function(plot)
			local bi = plot:GetY() * iW + plot:GetX() + 1;
			return mireBand[bi] == 3 and (not plot:IsCoastalLand()) and (Map.Rand(5, "Mire Fen River") == 0);
		end
	}
	local cfgRivers = GetBarrierConfig();
	local peaksRivers = (cfgRivers ~= nil and cfgRivers.kind == "peaks");
	for iPass, passCondition in ipairs(passConditions) do
		local usePass = true;
		if peaksRivers then
			if iPass == 2 or iPass == 4 or iPass == 5 then
				usePass = false;
			end
		end
		if usePass then
		local riverSourceRange;
		local seaWaterRange;
		if (iPass <= 2) then
			riverSourceRange = GameDefines["RIVER_SOURCE_MIN_RIVER_RANGE"];
			seaWaterRange = GameDefines["RIVER_SOURCE_MIN_SEAWATER_RANGE"];
		else
			riverSourceRange = (GameDefines["RIVER_SOURCE_MIN_RIVER_RANGE"] / 2);
			seaWaterRange = (GameDefines["RIVER_SOURCE_MIN_SEAWATER_RANGE"] / 2);
		end
		if peaksRivers and iPass == 1 then
			riverSourceRange = 2;
		end
		for i, plot in Plots() do
			local current_x = plot:GetX()
			local current_y = plot:GetY()
			if current_y < 2 or current_y >= iH - 1 then
				-- Plot too close to north/south edge, ignore it.
			elseif DEF_MIRRORED == 1 and current_x >= iW / 2 then
				-- East is filled by the 180° copy; don't generate a second set.
			elseif IsSnowNoWrap() and (current_x < 2 or current_x >= iW - 2) then
				-- Plot too close to east/west 2-col ocean rims, ignore it.
			elseif IsSnowWrapX() == false and (current_x < 1 or current_x >= iW - 2) then
				-- Plot too close to east/west ocean rims, ignore it.
			elseif IsSnowWrapX() and (current_x < 4 or current_x >= iW - 4) then
				-- Plot in wrap-front buffer, ignore it.
			elseif snowRiverSkip[current_x] then
				-- Plot in buffer zone, ignore it.
			elseif (not plot:IsWater()) then
				local peaksOk = true;
				if peaksRivers then
					local di = current_y * iW + current_x + 1;
					local dPeak = peakDist[di];
					if dPeak == nil or dPeak < 1 or dPeak > 3 then
						peaksOk = false;
					end
				end
				if peaksOk and passCondition(plot) then
					if (not Map.FindWater(plot, riverSourceRange, true)) then
						if (not Map.FindWater(plot, seaWaterRange, false)) then
							local inlandCorner = plot:GetInlandCorner();
							if(inlandCorner) then
								local start_x = inlandCorner:GetX()
								local start_y = inlandCorner:GetY()
								local orig_direction;
								local cfgR = GetBarrierConfig();
								if cfgR ~= nil and cfgR.kind == "peaks" then
									local pi = start_y * iW + start_x + 1;
									local px = peakNX[pi];
									local py = peakNY[pi];
									if px == nil then
										px = start_x;
										py = start_y;
									end
									local dx = start_x - px;
									local dy = start_y - py;
									if dx < 0 then
										dx = 0 - dx;
									end
									if dy < 0 then
										dy = 0 - dy;
									end
									local east = start_x >= px;
									local north = start_y >= py;
									if dx >= dy then
										if east then
											if north then
												orig_direction = FlowDirectionTypes.FLOWDIRECTION_NORTHEAST;
											else
												orig_direction = FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST;
											end
										else
											if north then
												orig_direction = FlowDirectionTypes.FLOWDIRECTION_NORTHWEST;
											else
												orig_direction = FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST;
											end
										end
									else
										if north then
											if east then
												orig_direction = FlowDirectionTypes.FLOWDIRECTION_NORTHEAST;
											else
												orig_direction = FlowDirectionTypes.FLOWDIRECTION_NORTHWEST;
											end
										else
											if east then
												orig_direction = FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST;
											else
												orig_direction = FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST;
											end
										end
									end
								elseif IsSnowBarrier() then
									local lakeX = iW / 4;
									if start_x >= iW / 2 then
										lakeX = iW * 0.75;
									end
									if start_y < iH / 2 then
										if start_x < lakeX then
											orig_direction = FlowDirectionTypes.FLOWDIRECTION_NORTHEAST;
										else
											orig_direction = FlowDirectionTypes.FLOWDIRECTION_NORTHWEST;
										end
									else
										if start_x < lakeX then
											orig_direction = FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST;
										else
											orig_direction = FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST;
										end
									end
								elseif start_y < iH / 2 then -- South half of map
									if start_x < iW / 2 then -- West half of map
										orig_direction = FlowDirectionTypes.FLOWDIRECTION_NORTHWEST;
									else -- East half
										orig_direction = FlowDirectionTypes.FLOWDIRECTION_NORTHEAST;
									end
								else -- North half of map
									if start_x < iW / 2 then -- West half of map
										orig_direction = FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST;
									else -- NE corner
										orig_direction = FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST;
									end
								end
								DoRiver(inlandCorner, nil, orig_direction, nil);
							end
						end
					end
				end			
			end
		end
		end
	end		
end
------------------------------------------------------------------------------------------------------------------------------------------------------------
function AssignStartingPlots:GenerateRegions(args)
	print("Map Generation - Dividing the map in to Regions");
	-- This is a customized version for West vs East.
	-- This version is tailored for handling two-teams play.
	local args = args or {};
	local iW, iH = Map.GetGridSize();
	local res = DEF_RESOURCES;
	if res == 9 then
		res = 1 + Map.Rand(3, "Random Resources Option - Lua");
	end

	local setback = DEF_FRONTLINE-1;

	local setforward = DEF_BACK-1;

	local setrange = setforward + setback;

	print("Moveback: ", setback);

	local setmiddle = DEF_TOPBOTTOM-1;

	self.resource_setting = res; -- Each map script has to pass in parameter for Resource setting chosen by user.
	self.method = 3; -- Flag the map as using a Rectangular division method.

	-- Determine number of civilizations and city states present in this game.
	self.iNumCivs, self.iNumCityStates, self.player_ID_list, self.bTeamGame, self.teams_with_major_civs, self.number_civs_per_team = GetPlayerAndTeamInfo()
	self.iNumCityStatesUnassigned = self.iNumCityStates;
	print("-"); print("Civs:", self.iNumCivs); print("City States:", self.iNumCityStates);

	-- Determine number of teams (of Major Civs only, not City States) present in this game.
	iNumTeams = table.maxn(self.teams_with_major_civs);				-- GLOBAL
	print("-"); print("Teams:", iNumTeams);

	-- Fetch team setting.
	local team_setting = DEF_TEAM

	-- If two teams are present, use team-oriented handling of start points, one team west, one east.
	if iNumTeams == 2 and team_setting == 1 then
		print("-"); print("Number of Teams present is two! Using custom team start placement for West vs East."); print("-");
		
		-- ToDo: Correctly identify team IDs and how many Civs are on each team.
		-- Also need to shuffle the teams so its random who starts on which half.
		local shuffled_team_list = GetShuffledCopyOfTable(self.teams_with_major_civs)
		teamWestID = self.teams_with_major_civs[1];							-- GLOBAL
		teamEastID = self.teams_with_major_civs[2]; 						-- GLOBAL
		iNumCivsInWest = self.number_civs_per_team[teamWestID];		-- GLOBAL
		iNumCivsInEast = self.number_civs_per_team[teamEastID];		-- GLOBAL

		-- Process the team in the west.
		self.inhabited_WestX = 0 + setforward;
		self.inhabited_SouthY = 0 + setmiddle;
		self.inhabited_Width = (math.floor(iW / 2)) - setrange;
		self.inhabited_Height = iH - 2 * setmiddle;
		if IsSnowBarrier() then
			local wrapN, centerN = ResolveSnowWrapWidths();
			local wrapHalf = wrapN / 2;
			local centerHalf = centerN / 2;
			local mid = math.floor(iW / 2);
			local backPad = wrapHalf - 1;
			if backPad < 0 then
				backPad = 0;
			end
			self.inhabited_WestX = setforward + backPad;
			self.inhabited_Width = (mid - centerHalf) - setback - 1 - self.inhabited_WestX + 1;
			local cfgR = GetBarrierConfig();
			if cfgR ~= nil and cfgR.kind == "frosty" then
				local snowY0 = math.floor((iH - 1) * 0.58);
				if snowY0 > self.inhabited_SouthY + 6 then
					self.inhabited_Height = snowY0 - self.inhabited_SouthY;
				end
			end
			if cfgR ~= nil and cfgR.kind == "shores" then
				-- Capitals live on the islands, so the rectangle has to reach
				-- the western edge of the field rather than stopping short.
				self.inhabited_WestX = 1;
				self.inhabited_Width = ShoresSeaHiX(iW);
			end
		end
		-- Obtain "Start Placement Fertility" inside the rectangle.
		-- Data returned is: fertility table, sum of all fertility, plot count.
		local fert_table, fertCount, plotCount = self:MeasureStartPlacementFertilityInRectangle(self.inhabited_WestX, 
		                                         self.inhabited_SouthY, self.inhabited_Width, self.inhabited_Height)
		-- Assemble the Rectangle data table:
		local rect_table = {self.inhabited_WestX, self.inhabited_SouthY, self.inhabited_Width, 
		                    self.inhabited_Height, -1, fertCount, plotCount}; -- AreaID -1 means ignore area IDs.
		-- Divide the rectangle.
		self:DivideIntoRegions(iNumCivsInWest, fert_table, rect_table)

		-- Process the team in the east.
		self.inhabited_WestX = (math.floor(iW / 2)) + setback;
		self.inhabited_SouthY = 0 + setmiddle;
		self.inhabited_Width = math.floor(iW / 2) - setrange;
		self.inhabited_Height = iH - 2 * setmiddle;
		if IsSnowBarrier() then
			local wrapN, centerN = ResolveSnowWrapWidths();
			local wrapHalf = wrapN / 2;
			local centerHalf = centerN / 2;
			local mid = math.floor(iW / 2);
			self.inhabited_WestX = (mid + centerHalf) + setback;
			local lastEast = iW - setforward - 1;
			if wrapHalf > 1 then
				lastEast = iW - setforward - wrapHalf;
			end
			self.inhabited_Width = lastEast - self.inhabited_WestX + 1;
		end
		-- Obtain "Start Placement Fertility" inside the rectangle.
		-- Data returned is: fertility table, sum of all fertility, plot count.
		local fert_table, fertCount, plotCount = self:MeasureStartPlacementFertilityInRectangle(self.inhabited_WestX, 
		                                         self.inhabited_SouthY, self.inhabited_Width, self.inhabited_Height)
		-- Assemble the Rectangle data table:
		local rect_table = {self.inhabited_WestX, self.inhabited_SouthY, self.inhabited_Width, 
		                    self.inhabited_Height, -1, fertCount, plotCount}; -- AreaID -1 means ignore area IDs.
		-- Divide the rectangle.
		self:DivideIntoRegions(iNumCivsInEast, fert_table, rect_table)
		-- The regions have been defined.

	-- If number of teams is any number other than two, use standard One Landmass division.
	else	
		print("-"); print("Dividing the map at random."); print("-");
		self.method = 2;	
		local best_areas = {};
		local globalFertilityOfLands = {};

		-- Obtain info on all landmasses for comparision purposes.
		local iGlobalFertilityOfLands = 0;
		local iNumLandPlots = 0;
		local iNumLandAreas = 0;
		local land_area_IDs = {};
		local land_area_plots = {};
		local land_area_fert = {};
		-- Cycle through all plots in the world, checking their Start Placement Fertility and AreaID.
		for x = 0, iW - 1 do
			for y = 0, iH - 1 do
				local i = y * iW + x + 1;
				local plot = Map.GetPlot(x, y);
				if not plot:IsWater() then -- Land plot, process it.
					iNumLandPlots = iNumLandPlots + 1;
					local iArea = plot:GetArea();
					local plotFertility = self:MeasureStartPlacementFertilityOfPlot(x, y, true); -- Check for coastal land is enabled.
					iGlobalFertilityOfLands = iGlobalFertilityOfLands + plotFertility;
					--
					if TestMembership(land_area_IDs, iArea) == false then -- This plot is the first detected in its AreaID.
						iNumLandAreas = iNumLandAreas + 1;
						table.insert(land_area_IDs, iArea);
						land_area_plots[iArea] = 1;
						land_area_fert[iArea] = plotFertility;
					else -- This AreaID already known.
						land_area_plots[iArea] = land_area_plots[iArea] + 1;
						land_area_fert[iArea] = land_area_fert[iArea] + plotFertility;
					end
				end
			end
		end
		
		-- Sort areas, achieving a list of AreaIDs with best areas first.
		--
		-- Fertility data in land_area_fert is stored with areaID index keys.
		-- Need to generate a version of this table with indices of 1 to n, where n is number of land areas.
		local interim_table = {};
		for loop_index, data_entry in pairs(land_area_fert) do
			table.insert(interim_table, data_entry);
		end
		-- Sort the fertility values stored in the interim table. Sort order in Lua is lowest to highest.
		table.sort(interim_table);
		-- If less players than landmasses, we will ignore the extra landmasses.
		local iNumRelevantLandAreas = math.min(iNumLandAreas, self.iNumCivs);
		-- Now re-match the AreaID numbers with their corresponding fertility values
		-- by comparing the original fertility table with the sorted interim table.
		-- During this comparison, best_areas will be constructed from sorted AreaIDs, richest stored first.
		local best_areas = {};
		-- Currently, the best yields are at the end of the interim table. We need to step backward from there.
		local end_of_interim_table = table.maxn(interim_table);
		-- We may not need all entries in the table. Process only iNumRelevantLandAreas worth of table entries.
		for areaTestLoop = end_of_interim_table, (end_of_interim_table - iNumRelevantLandAreas + 1), -1 do
			for loop_index, AreaID in ipairs(land_area_IDs) do
				if interim_table[areaTestLoop] == land_area_fert[land_area_IDs[loop_index]] then
					table.insert(best_areas, AreaID);
					table.remove(land_area_IDs, landLoop);
					break
				end
			end
		end

		-- Assign continents to receive start plots. Record number of civs assigned to each landmass.
		local inhabitedAreaIDs = {};
		local numberOfCivsPerArea = table.fill(0, iNumRelevantLandAreas); -- Indexed in synch with best_areas. Use same index to match values from each table.
		for civToAssign = 1, self.iNumCivs do
			local bestRemainingArea;
			local bestRemainingFertility = 0;
			local bestAreaTableIndex;
			-- Loop through areas, find the one with the best remaining fertility (civs added 
			-- to a landmass reduces its fertility rating for subsequent civs).
			for area_loop, AreaID in ipairs(best_areas) do
				local thisLandmassCurrentFertility = land_area_fert[AreaID] / (1 + numberOfCivsPerArea[area_loop]);
				if thisLandmassCurrentFertility > bestRemainingFertility then
					bestRemainingArea = AreaID;
					bestRemainingFertility = thisLandmassCurrentFertility;
					bestAreaTableIndex = area_loop;
				end
			end
			-- Record results for this pass. (A landmass has been assigned to receive one more start point than it previously had).
			numberOfCivsPerArea[bestAreaTableIndex] = numberOfCivsPerArea[bestAreaTableIndex] + 1;
			if TestMembership(inhabitedAreaIDs, bestRemainingArea) == false then
				table.insert(inhabitedAreaIDs, bestRemainingArea);
			end
		end
				
		-- Loop through the list of inhabited landmasses, dividing each landmass in to regions.
		-- Note that it is OK to divide a continent with one civ on it: this will assign the whole
		-- of the landmass to a single region, and is the easiest method of recording such a region.
		local iNumInhabitedLandmasses = table.maxn(inhabitedAreaIDs);
		for loop, currentLandmassID in ipairs(inhabitedAreaIDs) do
			-- Obtain the boundaries of and data for this landmass.
			local landmass_data = ObtainLandmassBoundaries(currentLandmassID);
			local iWestX = landmass_data[1];
			local iSouthY = landmass_data[2];
			local iEastX = landmass_data[3];
			local iNorthY = landmass_data[4];
			local iWidth = landmass_data[5];
			local iHeight = landmass_data[6];
			local wrapsX = landmass_data[7];
			local wrapsY = landmass_data[8];
			-- Obtain "Start Placement Fertility" of the current landmass. (Necessary to do this
			-- again because the fert_table can't be built prior to finding boundaries, and we had
			-- to ID the proper landmasses via fertility to be able to figure out their boundaries.
			local fert_table, fertCount, plotCount = self:MeasureStartPlacementFertilityOfLandmass(currentLandmassID, 
		  	                                         iWestX, iEastX, iSouthY, iNorthY, wrapsX, wrapsY);
			-- Assemble the rectangle data for this landmass.
			local rect_table = {iWestX, iSouthY, iWidth, iHeight, currentLandmassID, fertCount, plotCount};
			-- Divide this landmass in to number of regions equal to civs assigned here.
			iNumCivsOnThisLandmass = numberOfCivsPerArea[loop];
			if iNumCivsOnThisLandmass > 0 and iNumCivsOnThisLandmass <= 22 then -- valid number of civs.
				self:DivideIntoRegions(iNumCivsOnThisLandmass, fert_table, rect_table)
			else
				print("Invalid number of civs assigned to a landmass: ", iNumCivsOnThisLandmass);
			end
		end
	end
end
------------------------------------------------------------------------------
function AssignStartingPlots:BalanceAndAssign()
	-- This function determines what level of Bonus Resource support a location
	-- may need, identifies compatibility with civ-specific biases, and places starts.

	-- Normalize each start plot location.
	local iNumStarts = table.maxn(self.startingPlots);
	for region_number = 1, iNumStarts do
		print("Normalize Region: ", region_number);
		self:NormalizeStartLocation(region_number)
	end

	-- Assign Civs to start plots.
	local team_setting = DEF_TEAM
	if iNumTeams == 2 and team_setting == 1 then
		-- Two teams, place one in the west half, other in east -- even if team membership totals are uneven.
		print("-"); print("This is a team game with two teams! Place one team in West, other in East."); print("-");
		local playerList, westList, eastList = {}, {}, {};
		for loop = 1, self.iNumCivs do
			local player_ID = self.player_ID_list[loop];
			table.insert(playerList, player_ID);
			local player = Players[player_ID];
			local team_ID = player:GetTeam()
			if team_ID == teamWestID then
				print("Player #", player_ID, "belongs to Team #", team_ID, "and will be placed in the North.");
				table.insert(westList, player_ID);
			elseif team_ID == teamEastID then
				print("Player #", player_ID, "belongs to Team #", team_ID, "and will be placed in the South.");
				table.insert(eastList, player_ID);
			else
				print("* ERROR * - Player #", player_ID, "belongs to Team #", team_ID, "which is neither West nor East!");
			end
		end
		
		-- Debug
		if table.maxn(westList) ~= iNumCivsInWest then
			print("-"); print("*** ERROR! *** . . . Mismatch between number of Civs on West team and number of civs assigned to west locations.");
		end
		if table.maxn(eastList) ~= iNumCivsInEast then
			print("-"); print("*** ERROR! *** . . . Mismatch between number of Civs on East team and number of civs assigned to east locations.");
		end
		
		local westListShuffled = GetShuffledCopyOfTable(westList)
		local eastListShuffled = GetShuffledCopyOfTable(eastList)
		for region_number, player_ID in ipairs(westListShuffled) do
			local x = self.startingPlots[region_number][1];
			local y = self.startingPlots[region_number][2];
			local start_plot = Map.GetPlot(x, y)
			local player = Players[player_ID]
			player:SetStartingPlot(start_plot)
		end
		for loop, player_ID in ipairs(eastListShuffled) do
			local x = self.startingPlots[loop + iNumCivsInWest][1];
			local y = self.startingPlots[loop + iNumCivsInWest][2];
			local start_plot = Map.GetPlot(x, y)
			local player = Players[player_ID]
			player:SetStartingPlot(start_plot)
		end
	else
		print("-"); print("This game does not have specific start zone assignments."); print("-");
		local playerList = {};
		for loop = 1, self.iNumCivs do
			local player_ID = self.player_ID_list[loop];
			table.insert(playerList, player_ID);
		end
		local playerListShuffled = GetShuffledCopyOfTable(playerList)
		for region_number, player_ID in ipairs(playerListShuffled) do
			local x = self.startingPlots[region_number][1];
			local y = self.startingPlots[region_number][2];
			local start_plot = Map.GetPlot(x, y)
			local player = Players[player_ID]
			player:SetStartingPlot(start_plot)
		end
		-- If this is a team game (any team has more than one Civ in it) then make 
		-- sure team members start near each other if possible. (This may scramble 
		-- Civ biases in some cases, but there is no cure).
		if self.bTeamGame == true and team_setting ~= 2 then
			print("However, this IS a team game, so we will try to group team members together."); print("-");
			self:NormalizeTeamLocations()
		end
	end
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function AssignStartingPlots:CanPlaceCityStateAt(x, y, area_ID, force_it, ignore_collisions)
	-- Overriding default city state placement to prevent city states from being placed too close to map edges.
	
	--disable city states
	if 1<2 then
		return false
	end

	local iW, iH = Map.GetGridSize();
	local plot = Map.GetPlot(x, y)
	local area = plot:GetArea()
	
	-- Adding this check for West vs East.
	if x < 1 or x >= iW - 1 or y < 1 or y >= iH - 1 then
		return false
	end
	--
	
	if area ~= area_ID and area_ID ~= -1 then
		return false
	end
	local plotType = plot:GetPlotType()
	if plotType == PlotTypes.PLOT_OCEAN or plotType == PlotTypes.PLOT_MOUNTAIN then
		return false
	end
	local terrainType = plot:GetTerrainType()
	if terrainType == TerrainTypes.TERRAIN_SNOW then
		return false
	end
	local plotIndex = y * iW + x + 1;
	if self.cityStateData[plotIndex] > 0 and force_it == false then
		return false
	end
	local plotIndex = y * iW + x + 1;
	if self.playerCollisionData[plotIndex] == true and ignore_collisions == false then
		--print("-"); print("City State candidate plot rejected: collided with already-placed civ or City State at", x, y);
		return false
	end
	return true
end
------------------------------------------------------------------------------------------------------------------------------------------------------------
function SetDivide()

	local SplitOps = Map.GetCustomOption(OPT_CENTER_SPLIT);
	local iW, iH = Map.GetGridSize();

	if false then -- Landbridges
		-- check landbridges have no lakes or moutains

		--check bottom land bridge
		for y = 0, 2 do
			for x = math.floor(iW / 2) - 4, math.floor(iW / 2) + 3 do
				local plot = Map.GetPlot(x, y)
				
				--check for mountain or lake
				if plot:GetPlotType() == PlotTypes.PLOT_MOUNTAIN then
					plot:SetPlotType(PlotTypes.PLOT_HILLS, false, false);
				elseif plot:IsLake() then
					plot:SetPlotType(PlotTypes.PLOT_LAND, false, false);
				end
			end
		end

		--check the top landbridge
		for y = (iH-3), (iH-1) do
			for x = math.floor(iW / 2) - 4, math.floor(iW / 2) + 3 do
				local plot = Map.GetPlot(x, y)
				
				--check for mountain or lake
				if plot:GetPlotType() == PlotTypes.PLOT_MOUNTAIN then
					plot:SetPlotType(PlotTypes.PLOT_HILLS, false, false);
				elseif plot:IsLake() then
					plot:SetPlotType(PlotTypes.PLOT_LAND, false, false);
				end
			end
		end

		--check the middle landbridge
		for y = math.floor(iH / 2) - 1, math.floor(iH / 2) + 1 do
			for x = math.floor(iW / 2) - 4, math.floor(iW / 2) + 3 do
				local plot = Map.GetPlot(x, y)
				
				--check for mountain or lake
				if plot:GetPlotType() == PlotTypes.PLOT_MOUNTAIN then
					plot:SetPlotType(PlotTypes.PLOT_HILLS, false, false);
				elseif plot:IsLake() then
					plot:SetPlotType(PlotTypes.PLOT_LAND, false, false);
				end
			end
		end
	elseif false then -- Marsh
		--Marsh
		
		-- Add strip of marsh to middle of map
		for y = 0, iH - 1 do
			for x = math.floor(iW / 2) - 2, math.floor(iW / 2) + 1 do
				local plot = Map.GetPlot(x, y)
				plot:SetPlotType(PlotTypes.PLOT_LAND, false, false);
				plot:SetTerrainType(TerrainTypes.TERRAIN_GRASS, false, false);
				plot:SetFeatureType(FeatureTypes.FEATURE_MARSH, -1);
			end
		end
	elseif IsOldSnow() then
		local tundraCols = GetSnowWrapTundraColumns(iW);
		local snowCols = GetSnowWrapColumns(iW);
		for y = 0, iH - 1 do
			for _, x in ipairs(tundraCols) do
				local plot = Map.GetPlot(x, y)
				plot:SetFeatureType(FeatureTypes.NO_FEATURE, -1);
				plot:SetTerrainType(TerrainTypes.TERRAIN_TUNDRA, false, false);
			end
			for _, x in ipairs(snowCols) do
				local plot = Map.GetPlot(x, y)
				if plot:GetPlotType() == PlotTypes.PLOT_MOUNTAIN then
					plot:SetPlotType(PlotTypes.PLOT_HILLS, false, false);
				elseif plot:IsLake() then
					plot:SetPlotType(PlotTypes.PLOT_LAND, false, false);
				end
				plot:SetFeatureType(FeatureTypes.NO_FEATURE, -1);
				plot:SetTerrainType(TerrainTypes.TERRAIN_SNOW, false, false);
			end
		end
	elseif IsSnowBarrier() then
		local cfg = GetBarrierConfig();
		local barrierTerrain = BarrierTerrainType(cfg);
		local transTerrain = BarrierTransitionType(cfg);
		local tundraCols = GetSnowWrapTundraColumns(iW);
		local snowCols = GetSnowWrapColumns(iW);
		local mirrored = (DEF_MIRRORED == 1);
		local hillTop = cfg.mountainPct + cfg.hillPct;
		for y = 0, iH - 1 do
			for _, x in ipairs(tundraCols) do
				local plot = Map.GetPlot(x, y)
				plot:SetFeatureType(FeatureTypes.NO_FEATURE, -1);
				plot:SetTerrainType(transTerrain, false, false);
			end
			for _, x in ipairs(snowCols) do
				local plot = Map.GetPlot(x, y)
				if plot:IsWater() then
					plot:SetPlotType(PlotTypes.PLOT_LAND, false, false);
				end
				plot:SetFeatureType(FeatureTypes.NO_FEATURE, -1);
				plot:SetTerrainType(barrierTerrain, false, false);
				if (not mirrored) or (x <= iW * 0.5) then
					if cfg.iceLakePermille > 0 and Map.Rand(1000, "Barrier Ice Lake") < cfg.iceLakePermille then
						plot:SetPlotType(PlotTypes.PLOT_OCEAN, false, false);
						plot:SetTerrainType(TerrainTypes.TERRAIN_COAST, false, false);
						plot:SetFeatureType(FeatureTypes.FEATURE_ICE, -1);
					else
						local pt = Map.Rand(100, "Barrier Plot Type");
						if pt < cfg.mountainPct then
							plot:SetPlotType(PlotTypes.PLOT_MOUNTAIN, false, false);
						elseif pt < hillTop then
							plot:SetPlotType(PlotTypes.PLOT_HILLS, false, false);
						else
							plot:SetPlotType(PlotTypes.PLOT_LAND, false, false);
						end
						if cfg.kind == "wetland" then
							if Map.Rand(100, "Wetland Barrier Terrain") < 20 then
								plot:SetTerrainType(TerrainTypes.TERRAIN_PLAINS, false, false);
							else
								plot:SetTerrainType(TerrainTypes.TERRAIN_GRASS, false, false);
							end
						end
					end
				end
			end
		end
	end
	CapBarrierMountains();
end

------------------------------------------------------------------------------
function CapBarrierMountains()
	if IsOldSnow() == false and IsSnowBarrier() == false then
		return
	end
	local iW, iH = Map.GetGridSize();
	local tundra = {};
	local tc = GetSnowWrapTundraColumns(iW);
	local ti = 1;
	while ti <= #tc do
		tundra[tc[ti]] = true;
		ti = ti + 1;
	end
	local snowCols = GetSnowWrapColumns(iW);
	local mirrored = (DEF_MIRRORED == 1);
	local mtns = {};
	local ci = 1;
	while ci <= #snowCols do
		local x = snowCols[ci];
		if tundra[x] ~= true and ((not mirrored) or (x <= iW * 0.5)) then
			local y = 0;
			while y < iH do
				local plot = Map.GetPlot(x, y);
				if plot ~= nil and plot:GetPlotType() == PlotTypes.PLOT_MOUNTAIN then
					table.insert(mtns, plot);
				end
				y = y + 1;
			end
		end
		ci = ci + 1;
	end
	local n = #mtns;
	if n <= 4 then
		print("Barrier mountains:", n);
		return
	end
	mtns = GetShuffledCopyOfTable(mtns);
	local k = 5;
	while k <= n do
		mtns[k]:SetPlotType(PlotTypes.PLOT_HILLS, false, false);
		k = k + 1;
	end
	print("Barrier mountains capped:", n, "-> 4");
end
------------------------------------------------------------------------------
function CountSnowForestNeighbors(plot)
	local n = 0;
	local d = 0;
	while d < DirectionTypes.NUM_DIRECTION_TYPES do
		local adj = PlotDirNoXWrap(plot:GetX(), plot:GetY(), d);
		if adj ~= nil and adj:GetFeatureType() == FeatureTypes.FEATURE_FOREST then
			n = n + 1;
		end
		d = d + 1;
	end
	return n;
end
------------------------------------------------------------------------------
function AddSnowForests()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.forestPct < 1 then
		return
	end
	local barrierTerrain = BarrierTerrainType(cfg);
	local iW, iH = Map.GetGridSize();
	local snowCols = GetSnowWrapColumns(iW);
	local mirrored = (DEF_MIRRORED == 1);
	local remaining = {};
	local y = 0;
	while y < iH do
		local ci = 1;
		while ci <= #snowCols do
			local x = snowCols[ci];
			if (not mirrored) or (x <= iW * 0.5) then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil then
					local plotType = plot:GetPlotType();
					if plot:GetTerrainType() == barrierTerrain
						and (plotType == PlotTypes.PLOT_LAND or plotType == PlotTypes.PLOT_HILLS)
						and plot:GetFeatureType() == FeatureTypes.NO_FEATURE
						and plot:GetResourceType(-1) == -1 then
						table.insert(remaining, plot);
					end
				end
			end
			ci = ci + 1;
		end
		y = y + 1;
	end
	local n = #remaining;
	local target = math.floor(n * (cfg.forestPct / 100) + 0.5);
	local placed = 0;
	while placed < target and #remaining > 0 do
		local totalWeight = 0;
		local i = 1;
		while i <= #remaining do
			local neigh = CountSnowForestNeighbors(remaining[i]);
			local w = 1;
			if neigh == 1 then
				w = 6;
			elseif neigh >= 2 then
				w = 10;
			end
			totalWeight = totalWeight + w;
			i = i + 1;
		end
		if totalWeight < 1 then
			break
		end
		local roll = Map.Rand(totalWeight, "Barrier Forest Cluster");
		i = 1;
		local picked = false;
		while i <= #remaining do
			local neigh = CountSnowForestNeighbors(remaining[i]);
			local w = 1;
			if neigh == 1 then
				w = 6;
			elseif neigh >= 2 then
				w = 10;
			end
			if roll < w then
				remaining[i]:SetFeatureType(FeatureTypes.FEATURE_FOREST, -1);
				table.remove(remaining, i);
				placed = placed + 1;
				picked = true;
				break
			end
			roll = roll - w;
			i = i + 1;
		end
		if picked == false then
			remaining[#remaining]:SetFeatureType(FeatureTypes.FEATURE_FOREST, -1);
			table.remove(remaining, #remaining);
			placed = placed + 1;
		end
	end
	print("Barrier forests:", placed, "/", n);
end
------------------------------------------------------------------------------
function AddBarrierOases()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.oasisPctOfFlat < 1 then
		return
	end
	local barrierTerrain = BarrierTerrainType(cfg);
	local iW, iH = Map.GetGridSize();
	local snowCols = GetSnowWrapColumns(iW);
	local mirrored = (DEF_MIRRORED == 1);
	local remaining = {};
	local y = 0;
	while y < iH do
		local ci = 1;
		while ci <= #snowCols do
			local x = snowCols[ci];
			if (not mirrored) or (x <= iW * 0.5) then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil
					and plot:GetTerrainType() == barrierTerrain
					and plot:GetPlotType() == PlotTypes.PLOT_LAND
					and plot:GetFeatureType() == FeatureTypes.NO_FEATURE
					and plot:GetResourceType(-1) == -1 then
					table.insert(remaining, plot);
				end
			end
			ci = ci + 1;
		end
		y = y + 1;
	end
	local shuffled = GetShuffledCopyOfTable(remaining);
	local n = #shuffled;
	local target = math.floor(n * (cfg.oasisPctOfFlat / 100) + 0.5);
	local placed = 0;
	local i = 1;
	while i <= n and placed < target do
		local plot = shuffled[i];
		if plot:GetFeatureType() == FeatureTypes.NO_FEATURE then
			if plot:CanHaveFeature(FeatureTypes.FEATURE_OASIS) then
				plot:SetFeatureType(FeatureTypes.FEATURE_OASIS, -1);
				placed = placed + 1;
			end
		end
		i = i + 1;
	end
	i = 1;
	while i <= n and placed < target do
		local plot = shuffled[i];
		if plot:GetFeatureType() == FeatureTypes.NO_FEATURE then
			plot:SetFeatureType(FeatureTypes.FEATURE_OASIS, -1);
			placed = placed + 1;
		end
		i = i + 1;
	end
	print("Barrier oases:", placed, "/", n);
end
------------------------------------------------------------------------------
function FillMireSkip(iW)
	local skip = {};
	local cols = GetSnowWrapColumns(iW);
	local ci = 1;
	while ci <= #cols do
		skip[cols[ci]] = true;
		ci = ci + 1;
	end
	cols = GetSnowWrapTundraColumns(iW);
	ci = 1;
	while ci <= #cols do
		skip[cols[ci]] = true;
		ci = ci + 1;
	end
	return skip;
end
------------------------------------------------------------------------------
function FrostyHexNeighbors(x, y)
	if y % 2 == 0 then
		return {{0, 1}, {1, 0}, {0, -1}, {-1, -1}, {-1, 0}, {-1, 1}};
	end
	return {{1, 1}, {1, 0}, {1, -1}, {0, -1}, {-1, 0}, {0, 1}};
end
------------------------------------------------------------------------------
function FrostyPlayableX(x, skip, iW)
	if skip[x] == true then
		return false
	end
	if WaterAllowedAtX(x) == false then
		return false
	end
	if x < 0 or x >= iW then
		return false
	end
	if DEF_MIRRORED == 1 and x > iW * 0.5 then
		return false
	end
	return true
end
------------------------------------------------------------------------------
function FrostyCopyOceanWestToEast(plotTypes, iW, iH)
	local mid = math.floor(iW / 2);
	local y = 0;
	while y < iH do
		local x = 0;
		while x < mid do
			if plotTypes[y * iW + x + 1] == PlotTypes.PLOT_OCEAN then
				local mx = iW - x - 1;
				local my = iH - y - 1;
				plotTypes[my * iW + mx + 1] = PlotTypes.PLOT_OCEAN;
			end
			x = x + 1;
		end
		y = y + 1;
	end
end
------------------------------------------------------------------------------
function FrostyCollectSaltIndices(plotTypes, iW, iH, skip)
	local mid = math.floor(iW / 2);
	local seen = {};
	local salt = {};
	local y = 0;
	while y < iH do
		local x = 0;
		while x < mid do
			local i = y * iW + x + 1;
			if seen[i] ~= true and plotTypes[i] == PlotTypes.PLOT_OCEAN and skip[x] ~= true then
				local qx = {x};
				local qy = {y};
				local qi = 1;
				local body = {i};
				seen[i] = true;
				local edge = false;
				while qi <= #qx do
					local cx = qx[qi];
					local cy = qy[qi];
					if cx == 0 or cy == 0 or cy == iH - 1 then
						edge = true;
					end
					local dirs = FrostyHexNeighbors(cx, cy);
					local d = 1;
					while d <= 6 do
						local nx = cx + dirs[d][1];
						local ny = cy + dirs[d][2];
						if ny >= 0 and ny < iH and nx >= 0 and nx < mid then
							local ni = ny * iW + nx + 1;
							if seen[ni] ~= true and plotTypes[ni] == PlotTypes.PLOT_OCEAN and skip[nx] ~= true then
								seen[ni] = true;
								table.insert(qx, nx);
								table.insert(qy, ny);
								table.insert(body, ni);
							end
						end
						d = d + 1;
					end
					qi = qi + 1;
				end
				if edge then
					local b = 1;
					while b <= #body do
						table.insert(salt, body[b]);
						b = b + 1;
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	return salt;
end
------------------------------------------------------------------------------
function FrostyGrowOcean(plotTypes, iW, iH, skip, seedX, seedY, target, preferDx, preferDy)
	local body = {};
	if FrostyPlayableX(seedX, skip, iW) == false then
		return body
	end
	if seedY < 0 or seedY >= iH then
		return body
	end
	local idx = seedY * iW + seedX + 1;
	if plotTypes[idx] == PlotTypes.PLOT_MOUNTAIN then
		return body
	end
	plotTypes[idx] = PlotTypes.PLOT_OCEAN;
	table.insert(body, {seedX, seedY});
	local guard = 0;
	while #body < target and guard < 80 do
		guard = guard + 1;
		local candidates = {};
		local bi = 1;
		while bi <= #body do
			local p = body[bi];
			local dirs = FrostyHexNeighbors(p[1], p[2]);
			local d = 1;
			while d <= 6 do
				local nx = p[1] + dirs[d][1];
				local ny = p[2] + dirs[d][2];
				if ny >= 0 and ny < iH and FrostyPlayableX(nx, skip, iW) then
					local ni = ny * iW + nx + 1;
					if plotTypes[ni] ~= PlotTypes.PLOT_OCEAN and plotTypes[ni] ~= PlotTypes.PLOT_MOUNTAIN then
						local w = 1;
						if preferDx ~= 0 and dirs[d][1] == preferDx then
							w = w + 10;
						end
						if preferDy ~= 0 and dirs[d][2] == preferDy then
							w = w + 10;
						end
						if preferDx ~= 0 and dirs[d][1] == (0 - preferDx) then
							w = 0;
						end
						if preferDy ~= 0 and dirs[d][2] == (0 - preferDy) then
							w = 0;
						end
						local c = 1;
						while c <= w do
							table.insert(candidates, {nx, ny, ni});
							c = c + 1;
						end
					end
				end
				d = d + 1;
			end
			bi = bi + 1;
		end
		if #candidates < 1 then
			break
		end
		local pick = candidates[Map.Rand(#candidates, "Frosty Fjord Grow") + 1];
		plotTypes[pick[3]] = PlotTypes.PLOT_OCEAN;
		table.insert(body, {pick[1], pick[2]});
	end
	return body;
end
------------------------------------------------------------------------------
function FrostyApplySaltWater(plotTypes, iW, iH)
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "frosty" then
		return
	end
	WeeveeDbg("FrostyApplySaltWater");
	local skip = FillMireSkip(iW);
	if Map.Rand(100, "Frosty Fjord") < 45 then
		local playMin, playMax = GetSnowWrapWaterBounds(iW);
		if playMax < playMin then
			playMax = playMin;
		end
		local innerLo = playMin + math.floor((playMax - playMin) * 0.28);
		local innerHi = playMin + math.floor((playMax - playMin) * 0.72);
		if innerHi < innerLo then
			innerHi = innerLo;
		end
		local span = innerHi - innerLo + 1;
		if span < 1 then
			span = 1;
		end
		local sx = innerLo + Map.Rand(span, "Frosty Fjord X");
		local sy = iH - 1;
		local tries = 0;
		while FrostyPlayableX(sx, skip, iW) == false and tries < 12 do
			sx = innerLo + Map.Rand(span, "Frosty Fjord X Retry");
			tries = tries + 1;
		end
		while sy > 1 and plotTypes[sy * iW + sx + 1] == PlotTypes.PLOT_OCEAN do
			sy = sy - 1;
		end
		local nWant = math.floor(iH * 0.28) + Map.Rand(5, "Frosty Fjord Size");
		if nWant < 10 then
			nWant = 10;
		end
		local body = FrostyGrowOcean(plotTypes, iW, iH, skip, sx, sy, nWant, 0, -1);
		print("Frosty fjord tiles:", #body);
	end
	FrostyCopyOceanWestToEast(plotTypes, iW, iH);
end
------------------------------------------------------------------------------
function AddFrostyLayout()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "frosty" then
		return
	end
	WeeveeDbg("AddFrostyLayout");
	local iW, iH = Map.GetGridSize();
	local skip = FillMireSkip(iW);
	local mirrored = (DEF_MIRRORED == 1);
	FrostyPaintClimateBands(iW, iH, skip, mirrored);
	WeeveeDbgCall("FrostyBleedTerrain", FrostyBleedTerrain, iW, iH, skip, mirrored);
	WeeveeDbgCall("FrostyFillSnowHoles", FrostyFillSnowHoles, iW, iH, skip, mirrored);
	FrostyFlattenSnowMountains(iW, iH, skip, mirrored);
	FrostyAddSouthMountains(iW, iH, skip, mirrored);
	WeeveeDbgCall("FrostyEnsureFrontMountains", FrostyEnsureFrontMountains, iW, iH, skip, mirrored);
	WeeveeDbg("AddFrostyLayout done");
end
------------------------------------------------------------------------------
function FrostyClimateId(plot)
	if plot == nil or plot:IsWater() then
		return 0
	end
	local t = plot:GetTerrainType();
	if t == TerrainTypes.TERRAIN_SNOW then
		return 1
	end
	if t == TerrainTypes.TERRAIN_TUNDRA then
		return 2
	end
	return 3
end
------------------------------------------------------------------------------
function FrostyClimatePlayable(plot, skip, mirrored, iW)
	if plot == nil or plot:IsWater() then
		return false
	end
	local x = plot:GetX();
	if skip[x] == true then
		return false
	end
	if mirrored and x > iW * 0.5 then
		return false
	end
	return true
end
------------------------------------------------------------------------------
function FrostySetClimate(plot, id)
	if id == 1 then
		plot:SetTerrainType(TerrainTypes.TERRAIN_SNOW, false, false);
	elseif id == 2 then
		plot:SetTerrainType(TerrainTypes.TERRAIN_TUNDRA, false, false);
	else
		local t = plot:GetTerrainType();
		if t == TerrainTypes.TERRAIN_SNOW or t == TerrainTypes.TERRAIN_TUNDRA then
			plot:SetTerrainType(TerrainTypes.TERRAIN_PLAINS, false, false);
		end
	end
end
------------------------------------------------------------------------------
function FrostyCountClimateNeighbors(plot, skip, mirrored, iW)
	local nS = 0;
	local nT = 0;
	local nW = 0;
	local d = 0;
	while d < DirectionTypes.NUM_DIRECTION_TYPES do
		local adj = PlotDirNoXWrap(plot:GetX(), plot:GetY(), d);
		if FrostyClimatePlayable(adj, skip, mirrored, iW) then
			local id = FrostyClimateId(adj);
			if id == 1 then
				nS = nS + 1;
			elseif id == 2 then
				nT = nT + 1;
			else
				nW = nW + 1;
			end
		end
		d = d + 1;
	end
	return nS, nT, nW;
end
------------------------------------------------------------------------------
function FrostyMajorityClimate(nS, nT, nW, y, iH)
	if nS >= nT and nS >= nW and nS > 0 then
		return 1
	end
	if nT >= nS and nT >= nW and nT > 0 then
		return 2
	end
	if nW > 0 then
		return 3
	end
	local yNorm = 0;
	if iH > 1 then
		yNorm = y / (iH - 1);
	end
	if yNorm >= 0.58 then
		return 1
	end
	if yNorm >= 0.36 then
		return 2
	end
	return 3
end
------------------------------------------------------------------------------
function FrostyPaintClimateBands(iW, iH, skip, mirrored)
	local maxX = iW - 1;
	if mirrored then
		maxX = math.floor(iW * 0.5);
	end
	local xs = {};
	local x = 0;
	while x <= maxX do
		if skip[x] ~= true then
			table.insert(xs, x);
		end
		x = x + 1;
	end
	if #xs < 1 then
		return
	end
	local frac = Fractal.Create(iW, iH, 3, Map.GetFractalFlags(), -1, -1);
	local snowAmp = math.floor(iH * 0.11);
	if snowAmp < 2 then
		snowAmp = 2;
	end
	local tunAmp = math.floor(iH * 0.13);
	if tunAmp < 2 then
		tunAmp = 2;
	end
	local snowBase = math.floor((iH - 1) * 0.60);
	local tunBase = math.floor((iH - 1) * 0.36);
	local snowY = {};
	local tunY = {};
	local i = 1;
	while i <= #xs do
		local px = xs[i];
		local n1 = (frac:GetHeight(px, snowBase) / 255.0) - 0.5;
		local n2 = (frac:GetHeight(px, tunBase) / 255.0) - 0.5;
		local sy = snowBase + math.floor(n1 * 2 * snowAmp + 0.5);
		local ty = tunBase + math.floor(n2 * 2 * tunAmp + 0.5);
		if sy > iH - 2 then
			sy = iH - 2;
		end
		if sy < 4 then
			sy = 4;
		end
		if ty < 2 then
			ty = 2;
		end
		if sy < ty + 2 then
			sy = ty + 2;
		end
		if sy > iH - 1 then
			sy = iH - 1;
		end
		snowY[px] = sy;
		tunY[px] = ty;
		i = i + 1;
	end
	local function limitStep(arr, maxStep)
		local k = 2;
		while k <= #xs do
			local a = arr[xs[k - 1]];
			local b = arr[xs[k]];
			if b > a + maxStep then
				arr[xs[k]] = a + maxStep;
			elseif b < a - maxStep then
				arr[xs[k]] = a - maxStep;
			end
			k = k + 1;
		end
		k = #xs - 1;
		while k >= 1 do
			local a = arr[xs[k + 1]];
			local b = arr[xs[k]];
			if b > a + maxStep then
				arr[xs[k]] = a + maxStep;
			elseif b < a - maxStep then
				arr[xs[k]] = a - maxStep;
			end
			k = k - 1;
		end
	end
	limitStep(snowY, 2);
	limitStep(tunY, 2);
	i = 1;
	while i <= #xs do
		local px = xs[i];
		if snowY[px] < tunY[px] + 2 then
			snowY[px] = tunY[px] + 2;
		end
		if snowY[px] > iH - 1 then
			snowY[px] = iH - 1;
		end
		i = i + 1;
	end
	local y = 0;
	while y < iH do
		i = 1;
		while i <= #xs do
			local px = xs[i];
			local plot = Map.GetPlot(px, y);
			if plot ~= nil and plot:IsWater() == false then
				if y >= snowY[px] then
					FrostySetClimate(plot, 1);
				elseif y >= tunY[px] then
					FrostySetClimate(plot, 2);
				else
					FrostySetClimate(plot, 3);
				end
			end
			i = i + 1;
		end
		y = y + 1;
	end
end
------------------------------------------------------------------------------
function FrostyBleedTerrain(iW, iH, skip, mirrored)
	local maxX = iW - 1;
	if mirrored then
		maxX = math.floor(iW * 0.5);
	end
	local cands = {};
	local y = 0;
	while y < iH do
		local x = 0;
		while x <= maxX do
			local plot = Map.GetPlot(x, y);
			if FrostyClimatePlayable(plot, skip, mirrored, iW) then
				local id = FrostyClimateId(plot);
				local nS, nT, nWrm = FrostyCountClimateNeighbors(plot, skip, mirrored, iW);
				if id == 1 and nT >= 1 and nS >= 3 then
					table.insert(cands, {plot, 2});
				elseif id == 2 and nS >= 1 and nT >= 3 then
					table.insert(cands, {plot, 1});
				elseif id == 2 and nWrm >= 1 and nT >= 3 then
					table.insert(cands, {plot, 3});
				elseif id == 3 and nT >= 1 and nWrm >= 3 then
					table.insert(cands, {plot, 2});
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	cands = GetShuffledCopyOfTable(cands);
	local i = 1;
	while i <= #cands do
		if Map.Rand(100, "Frosty Climate Weave") < 28 then
			FrostySetClimate(cands[i][1], cands[i][2]);
		end
		i = i + 1;
	end
end
------------------------------------------------------------------------------
function FrostyFillSnowHoles(iW, iH, skip, mirrored)
	local maxX = iW - 1;
	if mirrored then
		maxX = math.floor(iW * 0.5);
	end
	local pass = 1;
	while pass <= 3 do
		local y = 0;
		while y < iH do
			local x = 0;
			while x <= maxX do
				local plot = Map.GetPlot(x, y);
				if FrostyClimatePlayable(plot, skip, mirrored, iW) then
					local id = FrostyClimateId(plot);
					local nS, nT, nWrm = FrostyCountClimateNeighbors(plot, skip, mirrored, iW);
					local same = nWrm;
					if id == 1 then
						same = nS;
					elseif id == 2 then
						same = nT;
					end
					if same == 0 or nS >= 4 or nT >= 4 or nWrm >= 4 then
						local nxt = FrostyMajorityClimate(nS, nT, nWrm, y, iH);
						if nxt ~= id then
							FrostySetClimate(plot, nxt);
						end
					end
				end
				x = x + 1;
			end
			y = y + 1;
		end
		pass = pass + 1;
	end
	FrostyKeepLargestClimate(1, iW, iH, skip, mirrored, maxX);
	FrostyKeepLargestClimate(2, iW, iH, skip, mirrored, maxX);
	FrostyKeepLargestClimate(3, iW, iH, skip, mirrored, maxX);
end
------------------------------------------------------------------------------
function FrostyKeepLargestClimate(want, iW, iH, skip, mirrored, maxX)
	local seen = {};
	local best = {};
	local y = 0;
	while y < iH do
		local x = 0;
		while x <= maxX do
			local plot = Map.GetPlot(x, y);
			local i = y * iW + x + 1;
			if seen[i] ~= true and FrostyClimatePlayable(plot, skip, mirrored, iW) and FrostyClimateId(plot) == want then
				local q = {plot};
				local body = {plot};
				seen[i] = true;
				local qi = 1;
				while qi <= #q do
					local cur = q[qi];
					local d = 0;
					while d < DirectionTypes.NUM_DIRECTION_TYPES do
						local adj = PlotDirNoXWrap(cur:GetX(), cur:GetY(), d);
						if FrostyClimatePlayable(adj, skip, mirrored, iW) and FrostyClimateId(adj) == want then
							local ai = adj:GetY() * iW + adj:GetX() + 1;
							if seen[ai] ~= true then
								seen[ai] = true;
								table.insert(q, adj);
								table.insert(body, adj);
							end
						end
						d = d + 1;
					end
					qi = qi + 1;
				end
				if #body > #best then
					local k = 1;
					while k <= #best do
						local nS, nT, nWrm = FrostyCountClimateNeighbors(best[k], skip, mirrored, iW);
						if want == 1 then
							nS = 0;
						elseif want == 2 then
							nT = 0;
						else
							nWrm = 0;
						end
						FrostySetClimate(best[k], FrostyMajorityClimate(nS, nT, nWrm, best[k]:GetY(), iH));
						k = k + 1;
					end
					best = body;
				else
					local k = 1;
					while k <= #body do
						local nS, nT, nWrm = FrostyCountClimateNeighbors(body[k], skip, mirrored, iW);
						if want == 1 then
							nS = 0;
						elseif want == 2 then
							nT = 0;
						else
							nWrm = 0;
						end
						FrostySetClimate(body[k], FrostyMajorityClimate(nS, nT, nWrm, body[k]:GetY(), iH));
						k = k + 1;
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
end
------------------------------------------------------------------------------
function FrostyIsFrontProtect(x, iW)
	local fx = math.floor(iW / 2) - 4;
	if x >= fx - 2 and x <= fx + 2 then
		return true
	end
	if IsSnowWrapX() then
		local xw = GetSnowWrapLandMountainXs(iW);
		if x >= xw - 2 and x <= xw + 2 then
			return true
		end
	end
	return false
end
------------------------------------------------------------------------------
function FrostyFlattenSnowMountains(iW, iH, skip, mirrored)
	local n = 0;
	local y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			if skip[x] ~= true and FrostyIsFrontProtect(x, iW) == false and ((not mirrored) or (x <= iW * 0.5)) then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil
					and plot:GetPlotType() == PlotTypes.PLOT_MOUNTAIN
					and plot:GetTerrainType() == TerrainTypes.TERRAIN_SNOW then
					plot:SetPlotType(PlotTypes.PLOT_HILLS, false, false);
					n = n + 1;
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	print("Frosty snow mountains flattened:", n);
end
------------------------------------------------------------------------------
function FrostyAddSouthMountains(iW, iH, skip, mirrored)
	local n = 0;
	local y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			if skip[x] ~= true and FrostyIsFrontProtect(x, iW) == false and ((not mirrored) or (x <= iW * 0.5)) then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil
					and plot:IsWater() == false
					and plot:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN
					and plot:GetTerrainType() ~= TerrainTypes.TERRAIN_SNOW then
					local yNorm = 0;
					if iH > 1 then
						yNorm = y / (iH - 1);
					end
					if yNorm < 0.50 and Map.Rand(100, "Frosty South Peak") < 3 then
						plot:SetPlotType(PlotTypes.PLOT_MOUNTAIN, false, false);
						n = n + 1;
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			if skip[x] ~= true and FrostyIsFrontProtect(x, iW) == false and ((not mirrored) or (x <= iW * 0.5)) then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil
					and plot:IsWater() == false
					and plot:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN
					and plot:GetTerrainType() ~= TerrainTypes.TERRAIN_SNOW then
					local yNorm = 0;
					if iH > 1 then
						yNorm = y / (iH - 1);
					end
					if yNorm < 0.50 and CountMireMountainNeighbors(plot) == 1 and Map.Rand(100, "Frosty South Peak Pair") < 12 then
						plot:SetPlotType(PlotTypes.PLOT_MOUNTAIN, false, false);
						n = n + 1;
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	print("Frosty extra south mountains:", n);
end
------------------------------------------------------------------------------
function FrostyEnsureFrontMountains(iW, iH, skip, mirrored)
	local wrapN, centerN = ResolveSnowWrapWidths();
	if centerN < 1 then
		return
	end
	local mid = math.floor(iW / 2);
	local tundraX = mid - centerN / 2 - 1;
	local xLo = tundraX - 2;
	local xHi = tundraX;
	if xLo < 0 then
		xLo = 0;
	end
	local nAdd = 0;
	local y0 = 0;
	while y0 < iH do
		local y1 = y0 + 5;
		if y1 >= iH then
			y1 = iH - 1;
		end
		local nMtn = 0;
		local cands = {};
		local y = y0;
		while y <= y1 do
			local x = xLo;
			while x <= xHi do
				if ((not mirrored) or (x <= iW * 0.5)) then
					local plot = Map.GetPlot(x, y);
					if plot ~= nil and plot:IsWater() == false then
						if plot:GetPlotType() == PlotTypes.PLOT_MOUNTAIN then
							nMtn = nMtn + 1;
						else
							table.insert(cands, plot);
						end
					end
				end
				x = x + 1;
			end
			y = y + 1;
		end
		if nMtn < 1 and #cands > 0 then
			local pick = cands[Map.Rand(#cands, "Frosty Front Gap") + 1];
			pick:SetPlotType(PlotTypes.PLOT_MOUNTAIN, false, false);
			nAdd = nAdd + 1;
		end
		y0 = y0 + 3;
	end
	print("Frosty front gap mountains:", nAdd);
end
------------------------------------------------------------------------------
function AddFrostyForests()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "frosty" then
		return
	end
	local iW, iH = Map.GetGridSize();
	local skip = FillMireSkip(iW);
	local mirrored = (DEF_MIRRORED == 1);
	local snowPlots = {};
	local tundraPlots = {};
	local y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			if skip[x] ~= true and ((not mirrored) or (x <= iW * 0.5)) then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil
					and plot:IsWater() == false
					and plot:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN
					and plot:GetFeatureType() == FeatureTypes.NO_FEATURE then
					local t = plot:GetTerrainType();
					if t == TerrainTypes.TERRAIN_SNOW then
						table.insert(snowPlots, plot);
					elseif t == TerrainTypes.TERRAIN_TUNDRA then
						table.insert(tundraPlots, plot);
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	PlaceClusteredFeature(snowPlots, FeatureTypes.FEATURE_FOREST, 22, "Frosty Snow Forest");
	PlaceClusteredFeature(tundraPlots, FeatureTypes.FEATURE_FOREST, 62, "Frosty Tundra Forest");
end
------------------------------------------------------------------------------
function AddFrostyIce()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "frosty" then
		return
	end
	local iW, iH = Map.GetGridSize();
	local skip = FillMireSkip(iW);
	local mirrored = (DEF_MIRRORED == 1);
	local n = 0;
	local y = 0;
	while y < iH do
		local distN = iH - 1 - y;
		local x = 0;
		while x < iW do
			if skip[x] ~= true and ((not mirrored) or (x <= iW * 0.5)) then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil and plot:IsWater() and plot:GetFeatureType() == FeatureTypes.NO_FEATURE then
					if distN > 4 then
						-- ice only on the north 5 rows
					else
					local hug = plot:IsAdjacentToLand();
					local chance = 0;
					if hug then
						chance = 72;
					else
						chance = 28;
					end
					if plot:IsLake() then
						chance = chance + 12;
					end
					if chance > 0 and Map.Rand(100, "Frosty Ice") < chance then
						plot:SetFeatureType(FeatureTypes.FEATURE_ICE, -1);
						n = n + 1;
					end
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	print("Frosty ice:", n);
end
------------------------------------------------------------------------------
function CountAdjacentTerrain(plot, terrainType)
	local n = 0;
	local d = 0;
	while d < DirectionTypes.NUM_DIRECTION_TYPES do
		local adj = PlotDirNoXWrap(plot:GetX(), plot:GetY(), d);
		if adj ~= nil and adj:GetTerrainType() == terrainType then
			n = n + 1;
		end
		d = d + 1;
	end
	return n;
end
------------------------------------------------------------------------------
function MurkIceColumnOk(x, skip, iW, mirrored)
	if mirrored and x > iW * 0.5 then
		return false
	end
	if skip[x] == true and x > 2 and x < iW - 3 then
		return false
	end
	return true
end
------------------------------------------------------------------------------
function GrowMurkIceArm(plot, iH, skip, iW, mirrored)
	local steps = 0;
	while plot ~= nil and steps < 2 do
		local best = nil;
		local bestY = plot:GetY();
		local d = 0;
		while d < DirectionTypes.NUM_DIRECTION_TYPES do
			local adj = PlotDirNoXWrap(plot:GetX(), plot:GetY(), d);
			if adj ~= nil and adj:IsWater() and adj:GetFeatureType() ~= FeatureTypes.FEATURE_ICE then
				local ax = adj:GetX();
				local ay = adj:GetY();
				if ay < plot:GetY() and ay >= iH - 3 and MurkIceColumnOk(ax, skip, iW, mirrored) then
					if best == nil or ay < bestY or (ay == bestY and Map.Rand(2, "Mire Ice Arm Tie") == 0) then
						best = adj;
						bestY = ay;
					end
				end
			end
			d = d + 1;
		end
		if best == nil then
			break
		end
		best:SetFeatureType(FeatureTypes.FEATURE_ICE, -1);
		if Map.Rand(100, "Mire Ice Arm Width") < 18 then
			local sd = 0;
			while sd < DirectionTypes.NUM_DIRECTION_TYPES do
				local side = PlotDirNoXWrap(best:GetX(), best:GetY(), sd);
				if side ~= nil and side:IsWater() and side:GetY() == best:GetY() and side:GetFeatureType() ~= FeatureTypes.FEATURE_ICE then
					if MurkIceColumnOk(side:GetX(), skip, iW, mirrored) then
						side:SetFeatureType(FeatureTypes.FEATURE_ICE, -1);
						break
					end
				end
				sd = sd + 1;
			end
		end
		plot = best;
		steps = steps + 1;
	end
end
------------------------------------------------------------------------------
function AddNorthIceArms()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "wetland" then
		return
	end
	local iW, iH = Map.GetGridSize();
	local skip = FillMireSkip(iW);
	local mirrored = (DEF_MIRRORED == 1);
	local iceFrac = Fractal.Create(iW, iH, 4, Map.GetFractalFlags(), -1, -1);
	local iceCut = iceFrac:GetHeight(62);
	local northY = iH - 1;
	local iceSeeds = {};
	local x = 0;
	while x < iW do
		if MurkIceColumnOk(x, skip, iW, mirrored) then
			local plot = Map.GetPlot(x, northY);
			if plot ~= nil and plot:IsWater() and iceFrac:GetHeight(x, northY) >= iceCut then
				plot:SetFeatureType(FeatureTypes.FEATURE_ICE, -1);
				table.insert(iceSeeds, plot);
			end
		end
		x = x + 1;
	end
	local si = 1;
	while si <= #iceSeeds do
		GrowMurkIceArm(iceSeeds[si], iH, skip, iW, mirrored);
		si = si + 1;
	end
end
------------------------------------------------------------------------------
function CountMireMountainNeighbors(plot)
	local n = 0;
	local d = 0;
	while d < DirectionTypes.NUM_DIRECTION_TYPES do
		local adj = PlotDirNoXWrap(plot:GetX(), plot:GetY(), d);
		if adj ~= nil and adj:GetPlotType() == PlotTypes.PLOT_MOUNTAIN then
			n = n + 1;
		end
		d = d + 1;
	end
	return n;
end
------------------------------------------------------------------------------
function CarveMireCorridorPlot(plot)
	if plot == nil or plot:IsWater() then
		return
	end
	if plot:GetPlotType() ~= PlotTypes.PLOT_LAND then
		plot:SetPlotType(PlotTypes.PLOT_LAND, false, false);
	end
	plot:SetFeatureType(FeatureTypes.NO_FEATURE, -1);
end
------------------------------------------------------------------------------
function StepMireCorridor(x, y, tx, ty, skip, wantBand, iW)
	local best = nil;
	local bestScore = -99999;
	local d = 0;
	while d < DirectionTypes.NUM_DIRECTION_TYPES do
		local adj = PlotDirNoXWrap(x, y, d);
		if adj ~= nil then
			local ax = adj:GetX();
			local ay = adj:GetY();
			if skip[ax] ~= true and adj:IsWater() == false then
				local dist = Map.PlotDistance(ax, ay, tx, ty);
				local score = 0 - dist;
				local bi = ay * iW + ax + 1;
				if mireBand[bi] == wantBand then
					score = score + 4;
				end
				if adj:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN then
					score = score + 1;
				end
				if score > bestScore or (score == bestScore and Map.Rand(2, "Mire Corridor Tie") == 0) then
					bestScore = score;
					best = adj;
				end
			end
		end
		d = d + 1;
	end
	return best;
end
------------------------------------------------------------------------------
function WalkMireCorridor(sx, sy, tx, ty, skip, wantBand, iW, maxSteps)
	local plot = Map.GetPlot(sx, sy);
	local seen = {};
	local steps = 0;
	while plot ~= nil and steps < maxSteps do
		local idx = plot:GetY() * iW + plot:GetX() + 1;
		if seen[idx] == true then
			break
		end
		seen[idx] = true;
		CarveMireCorridorPlot(plot);
		if plot:GetX() == tx and plot:GetY() == ty then
			break
		end
		local nxt = StepMireCorridor(plot:GetX(), plot:GetY(), tx, ty, skip, wantBand, iW);
		if nxt == nil then
			break
		end
		plot = nxt;
		steps = steps + 1;
	end
end
------------------------------------------------------------------------------
function PickMirePlotNear(plots, tx, ty, maxDist)
	local best = nil;
	local bestD = 9999;
	local i = 1;
	while i <= #plots do
		local p = plots[i];
		local d = Map.PlotDistance(p:GetX(), p:GetY(), tx, ty);
		if d < bestD or (d == bestD and Map.Rand(2, "Mire Pick Near") == 0) then
			bestD = d;
			best = p;
		end
		i = i + 1;
	end
	if best ~= nil and maxDist ~= nil and bestD > maxDist then
		return nil
	end
	return best;
end
------------------------------------------------------------------------------
function MireApplyBandTerrain(plot, band)
	if plot == nil or plot:IsWater() then
		return
	end
	if band == 1 then
		if plot:GetPlotType() == PlotTypes.PLOT_MOUNTAIN then
			plot:SetPlotType(PlotTypes.PLOT_LAND, false, false);
		end
		plot:SetTerrainType(TerrainTypes.TERRAIN_TUNDRA, false, false);
	elseif band == 2 then
		if plot:GetPlotType() == PlotTypes.PLOT_MOUNTAIN then
			plot:SetPlotType(PlotTypes.PLOT_LAND, false, false);
		end
		if Map.Rand(100, "Mire Wood Plains") < 28 then
			plot:SetTerrainType(TerrainTypes.TERRAIN_PLAINS, false, false);
		else
			plot:SetTerrainType(TerrainTypes.TERRAIN_GRASS, false, false);
		end
	else
		if plot:GetPlotType() == PlotTypes.PLOT_MOUNTAIN then
			plot:SetPlotType(PlotTypes.PLOT_HILLS, false, false);
		end
		if plot:GetPlotType() == PlotTypes.PLOT_HILLS and Map.Rand(100, "Mire Fen Hill Keep") >= 12 then
			plot:SetPlotType(PlotTypes.PLOT_LAND, false, false);
		end
		plot:SetTerrainType(TerrainTypes.TERRAIN_GRASS, false, false);
	end
end
------------------------------------------------------------------------------
function MireBleedFenWood(iW, iH, skip, mirrored)
	local pass = 1;
	while pass <= 1 do
		local toWood = {};
		local toFen = {};
		local y = 0;
		while y < iH do
			local x = 0;
			while x < iW do
				if skip[x] ~= true and ((not mirrored) or (x <= iW * 0.5)) then
					local i = y * iW + x + 1;
					local band = mireBand[i];
					if band == 2 or band == 3 then
						local d = 0;
						while d < DirectionTypes.NUM_DIRECTION_TYPES do
							local adj = PlotDirNoXWrap(x, y, d);
							if adj ~= nil and adj:IsWater() == false then
								local ax = adj:GetX();
								local ay = adj:GetY();
								if skip[ax] ~= true and ((not mirrored) or (ax <= iW * 0.5)) then
									local ai = ay * iW + ax + 1;
									local ab = mireBand[ai];
									if band == 2 and ab == 3 and ay <= y then
										if Map.Rand(100, "Mire Wood South") < 34 then
											toWood[ai] = adj;
										end
									elseif band == 3 and ab == 2 and ay >= y then
										if Map.Rand(100, "Mire Fen North") < 22 then
											toFen[ai] = adj;
										end
									end
								end
							end
							d = d + 1;
						end
					end
				end
				x = x + 1;
			end
			y = y + 1;
		end
		local i, plot;
		for i, plot in pairs(toWood) do
			if toFen[i] == nil and mireBand[i] == 3 then
				mireBand[i] = 2;
				MireApplyBandTerrain(plot, 2);
			end
		end
		for i, plot in pairs(toFen) do
			if toWood[i] == nil and mireBand[i] == 2 then
				mireBand[i] = 3;
				MireApplyBandTerrain(plot, 3);
			end
		end
		pass = pass + 1;
	end
end
------------------------------------------------------------------------------
function AddMireBands()
	mireBand = {};
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "wetland" then
		return
	end
	local iW, iH = Map.GetGridSize();
	local skip = FillMireSkip(iW);
	local mirrored = (DEF_MIRRORED == 1);
	local frac = Fractal.Create(iW, iH, 5, Map.GetFractalFlags(), -1, -1);
	local fracFen = Fractal.Create(iW, iH, 4, Map.GetFractalFlags(), -1, -1);
	local hLo = frac:GetHeight(10);
	local hHi = frac:GetHeight(90);
	local fLo = fracFen:GetHeight(8);
	local fHi = fracFen:GetHeight(92);
	local nSpike = 0;
	local nWood = 0;
	local nFen = 0;
	local y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			local i = y * iW + x + 1;
			mireBand[i] = 0;
			if skip[x] ~= true and ((not mirrored) or (x <= iW * 0.5)) then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil and plot:IsWater() == false then
					local yNorm = 0;
					if iH > 1 then
						yNorm = y / (iH - 1);
					end
					local jitter = 0;
					if hHi > hLo then
						jitter = ((frac:GetHeight(x, y) - hLo) / (hHi - hLo) - 0.5) * 0.24;
					end
					local fenJitter = 0;
					if fHi > fLo then
						fenJitter = ((fracFen:GetHeight(x, y) - fLo) / (fHi - fLo) - 0.5) * 0.38;
					end
					local band = 1;
					if yNorm + jitter < 0.67 then
						if yNorm + fenJitter < 0.32 then
							band = 3;
						else
							band = 2;
						end
					end
					mireBand[i] = band;
					MireApplyBandTerrain(plot, band);
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	MireBleedFenWood(iW, iH, skip, mirrored);
	local woodLand = {};
	y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			local i = y * iW + x + 1;
			local band = mireBand[i];
			if band == 1 then
				nSpike = nSpike + 1;
			elseif band == 2 then
				nWood = nWood + 1;
				local plot = Map.GetPlot(x, y);
				if plot ~= nil and plot:IsWater() == false then
					table.insert(woodLand, plot);
				end
			elseif band == 3 then
				nFen = nFen + 1;
			end
			x = x + 1;
		end
		y = y + 1;
	end
	y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			local i = y * iW + x + 1;
			if mireBand[i] == 1 then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil and plot:IsWater() == false and plot:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN then
					if Map.Rand(100, "Mire Spike Peak") < 10 then
						plot:SetPlotType(PlotTypes.PLOT_MOUNTAIN, false, false);
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			local i = y * iW + x + 1;
			if mireBand[i] == 1 then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil and plot:IsWater() == false and plot:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN then
					if CountMireMountainNeighbors(plot) == 1 and Map.Rand(100, "Mire Spike Pair") < 22 then
						plot:SetPlotType(PlotTypes.PLOT_MOUNTAIN, false, false);
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	local nBlobs = 2;
	if iH >= 28 then
		nBlobs = 3;
	end
	if iH >= 44 then
		nBlobs = 4;
	end
	nBlobs = nBlobs * 2;
	local b = 0;
	local blobTries = 0;
	local maxBlobTries = nBlobs * 8;
	while b < nBlobs and blobTries < maxBlobTries and #woodLand > 8 do
		blobTries = blobTries + 1;
		local seed = woodLand[1 + Map.Rand(#woodLand, "Mire Wood Blob Seed")];
		if seed:IsWater() == false and seed:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN and CountMireMountainNeighbors(seed) == 0 then
			local q = {};
			table.insert(q, seed);
			local qi = 1;
			seed:SetPlotType(PlotTypes.PLOT_MOUNTAIN, false, false);
			local grown = 1;
			local target = 1 + Map.Rand(3, "Mire Wood Blob Size");
			while qi <= #q and grown < target do
				local p = q[qi];
				qi = qi + 1;
				local d = 0;
				while d < DirectionTypes.NUM_DIRECTION_TYPES do
					local adj = PlotDirNoXWrap(p:GetX(), p:GetY(), d);
					if adj ~= nil and grown < target then
						local ax = adj:GetX();
						local ai = adj:GetY() * iW + ax + 1;
						if skip[ax] ~= true and mireBand[ai] == 2 and adj:IsWater() == false and adj:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN then
							if Map.Rand(100, "Mire Wood Blob Grow") < 70 then
								adj:SetPlotType(PlotTypes.PLOT_MOUNTAIN, false, false);
								table.insert(q, adj);
								grown = grown + 1;
							end
						end
					end
					d = d + 1;
				end
			end
			b = b + 1;
		end
	end
	local snowFrac = Fractal.Create(iW, iH, 4, Map.GetFractalFlags(), -1, -1);
	local snowCut = {};
	snowCut[0] = snowFrac:GetHeight(64);
	snowCut[1] = snowFrac:GetHeight(78);
	snowCut[2] = snowFrac:GetHeight(88);
	snowCut[3] = snowFrac:GetHeight(96);
	local snowY = iH - 4;
	if snowY < 0 then
		snowY = 0;
	end
	while snowY < iH do
		local fromNorth = iH - 1 - snowY;
		local cut = snowCut[fromNorth];
		if cut == nil then
			cut = snowCut[3];
		end
		local x = 0;
		while x < iW do
			if skip[x] ~= true and ((not mirrored) or (x <= iW * 0.5)) then
				local plot = Map.GetPlot(x, snowY);
				if plot ~= nil and plot:IsWater() == false and snowFrac:GetHeight(x, snowY) >= cut then
					plot:SetTerrainType(TerrainTypes.TERRAIN_SNOW, false, false);
				end
			end
			x = x + 1;
		end
		snowY = snowY + 1;
	end
	snowY = iH - 4;
	if snowY < 0 then
		snowY = 0;
	end
	while snowY < iH do
		local fromNorth = iH - 1 - snowY;
		local growChance = 58 - fromNorth * 14;
		if growChance < 12 then
			growChance = 12;
		end
		local x = 0;
		while x < iW do
			if skip[x] ~= true and ((not mirrored) or (x <= iW * 0.5)) then
				local plot = Map.GetPlot(x, snowY);
				if plot ~= nil and plot:IsWater() == false and plot:GetTerrainType() ~= TerrainTypes.TERRAIN_SNOW then
					if CountAdjacentTerrain(plot, TerrainTypes.TERRAIN_SNOW) >= 1 and Map.Rand(100, "Mire Snow Grow") < growChance then
						plot:SetTerrainType(TerrainTypes.TERRAIN_SNOW, false, false);
					end
				end
			end
			x = x + 1;
		end
		snowY = snowY + 1;
	end
	local hillFrac = Fractal.Create(iW, iH, 5, Map.GetFractalFlags(), -1, -1);
	local hillCut = {};
	hillCut[0] = hillFrac:GetHeight(82);
	hillCut[1] = hillFrac:GetHeight(92);
	hillCut[2] = hillFrac:GetHeight(97);
	local hillY = 0;
	while hillY <= 2 and hillY < iH do
		local cut = hillCut[hillY];
		local x = 0;
		while x < iW do
			if skip[x] ~= true and ((not mirrored) or (x <= iW * 0.5)) then
				local plot = Map.GetPlot(x, hillY);
				if plot ~= nil and plot:IsWater() == false and plot:GetPlotType() == PlotTypes.PLOT_LAND and hillFrac:GetHeight(x, hillY) >= cut then
					plot:SetPlotType(PlotTypes.PLOT_HILLS, false, false);
				end
			end
			x = x + 1;
		end
		hillY = hillY + 1;
	end
	hillY = 0;
	while hillY <= 2 and hillY < iH do
		local growChance = 48 - hillY * 16;
		if growChance < 10 then
			growChance = 10;
		end
		local x = 0;
		while x < iW do
			if skip[x] ~= true and ((not mirrored) or (x <= iW * 0.5)) then
				local plot = Map.GetPlot(x, hillY);
				if plot ~= nil and plot:IsWater() == false and plot:GetPlotType() == PlotTypes.PLOT_LAND then
					local hn = 0;
					local d = 0;
					while d < DirectionTypes.NUM_DIRECTION_TYPES do
						local adj = PlotDirNoXWrap(x, hillY, d);
						if adj ~= nil and adj:GetPlotType() == PlotTypes.PLOT_HILLS then
							hn = hn + 1;
						end
						d = d + 1;
					end
					if hn >= 1 and Map.Rand(100, "Mire South Hill Grow") < growChance then
						plot:SetPlotType(PlotTypes.PLOT_HILLS, false, false);
					end
				end
			end
			x = x + 1;
		end
		hillY = hillY + 1;
	end
	print("Mire bands spike:", nSpike, " wood:", nWood, " fen:", nFen);
end
------------------------------------------------------------------------------
function AddMireFeatures()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "wetland" then
		return
	end
	local iW, iH = Map.GetGridSize();
	local skip = FillMireSkip(iW);
	local mirrored = (DEF_MIRRORED == 1);
	local spikePlots = {};
	local fenMarsh = {};
	local fenForest = {};
	local fenLake = {};
	local woodWest = {};
	local woodEast = {};
	local woodSouth = {};
	local woodNorth = {};
	local minX, maxX = GetSnowWrapWaterBounds(iW);
	if minX > maxX then
		minX = 2;
		maxX = math.floor(iW / 2) - 2;
	end
	local y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			local i = y * iW + x + 1;
			local band = mireBand[i];
			if band ~= nil and band > 0 and skip[x] ~= true and ((not mirrored) or (x <= iW * 0.5)) then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil and plot:IsWater() == false then
					local feat = plot:GetFeatureType();
					if feat == FeatureTypes.FEATURE_JUNGLE or feat == FeatureTypes.FEATURE_MARSH or feat == FeatureTypes.FEATURE_FLOOD_PLAINS or feat == FeatureTypes.FEATURE_OASIS then
						plot:SetFeatureType(FeatureTypes.NO_FEATURE, -1);
					end
					if plot:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN then
						if band == 1 then
							table.insert(spikePlots, plot);
							if y >= iH - 3 and WaterAllowedAtX(x) and plot:IsCoastalLand() == false and Map.Rand(95, "Mire Ice Pond") == 0 then
								plot:SetPlotType(PlotTypes.PLOT_OCEAN, false, false);
								plot:SetTerrainType(TerrainTypes.TERRAIN_COAST, false, false);
								plot:SetFeatureType(FeatureTypes.FEATURE_ICE, -1);
							end
						elseif band == 2 then
							if plot:GetPlotType() ~= PlotTypes.PLOT_OCEAN then
								if Map.Rand(100, "Mire Wood Forest") < 92 then
									plot:SetFeatureType(FeatureTypes.FEATURE_FOREST, -1);
								end
								if x >= minX and x <= maxX then
									if x <= minX + 2 then
										table.insert(woodWest, plot);
									end
									if x >= maxX - 2 then
										table.insert(woodEast, plot);
									end
									if y < iH * 0.45 then
										table.insert(woodSouth, plot);
									end
									if y > iH * 0.55 then
										table.insert(woodNorth, plot);
									end
								end
							end
						else
							if plot:GetPlotType() == PlotTypes.PLOT_LAND and plot:GetTerrainType() == TerrainTypes.TERRAIN_GRASS then
								table.insert(fenMarsh, plot);
							end
							if plot:IsCoastalLand() == false and WaterAllowedAtX(x) then
								table.insert(fenLake, plot);
							end
							table.insert(fenForest, plot);
						end
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	local pinePlots = {};
	local pi = 1;
	while pi <= #spikePlots do
		if spikePlots[pi]:IsWater() == false and spikePlots[pi]:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN and spikePlots[pi]:GetFeatureType() == FeatureTypes.NO_FEATURE and spikePlots[pi]:GetTerrainType() ~= TerrainTypes.TERRAIN_SNOW then
			table.insert(pinePlots, spikePlots[pi]);
		end
		pi = pi + 1;
	end
	local pineN, pineT = PlaceClusteredFeature(pinePlots, FeatureTypes.FEATURE_FOREST, 20, "Mire Spike Pine");
	local nEW = 2;
	if iH >= 36 then
		nEW = 3;
	end
	local ei = 0;
	while ei < nEW do
		if #woodWest > 0 and #woodEast > 0 then
			local a = woodWest[1 + Map.Rand(#woodWest, "Mire EW West")];
			local b = woodEast[1 + Map.Rand(#woodEast, "Mire EW East")];
			WalkMireCorridor(a:GetX(), a:GetY(), b:GetX(), b:GetY(), skip, 2, iW, iW + iH);
		end
		ei = ei + 1;
	end
	local nNS = 2;
	if iW >= 56 then
		nNS = 3;
	end
	local ni = 0;
	while ni < nNS do
		local tx = minX + math.floor((maxX - minX) * (ni + 1) / (nNS + 1));
		local south = PickMirePlotNear(woodSouth, tx, math.floor(iH * 0.38), nil);
		local north = PickMirePlotNear(woodNorth, tx, math.floor(iH * 0.62), nil);
		if south ~= nil and north ~= nil then
			WalkMireCorridor(south:GetX(), south:GetY(), north:GetX(), north:GetY(), skip, 2, iW, iW + iH);
		end
		ni = ni + 1;
	end
	if mirrored == false then
		local emin = iW - 1 - maxX;
		local emax = iW - 1 - minX;
		if emin > emax then
			local tmp = emin;
			emin = emax;
			emax = tmp;
		end
		local eWest = {};
		local eEast = {};
		local eSouth = {};
		local eNorth = {};
		y = 0;
		while y < iH do
			local x = emin;
			while x <= emax do
				local i = y * iW + x + 1;
				if mireBand[i] == 2 then
					local plot = Map.GetPlot(x, y);
					if plot ~= nil and plot:IsWater() == false and plot:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN then
						if x <= emin + 2 then
							table.insert(eWest, plot);
						end
						if x >= emax - 2 then
							table.insert(eEast, plot);
						end
						if y < iH * 0.45 then
							table.insert(eSouth, plot);
						end
						if y > iH * 0.55 then
							table.insert(eNorth, plot);
						end
					end
				end
				x = x + 1;
			end
			y = y + 1;
		end
		ei = 0;
		while ei < nEW do
			if #eWest > 0 and #eEast > 0 then
				local a = eWest[1 + Map.Rand(#eWest, "Mire EEW West")];
				local b = eEast[1 + Map.Rand(#eEast, "Mire EEW East")];
				WalkMireCorridor(a:GetX(), a:GetY(), b:GetX(), b:GetY(), skip, 2, iW, iW + iH);
			end
			ei = ei + 1;
		end
		ni = 0;
		while ni < nNS do
			local tx = emin + math.floor((emax - emin) * (ni + 1) / (nNS + 1));
			local south = PickMirePlotNear(eSouth, tx, math.floor(iH * 0.38), nil);
			local north = PickMirePlotNear(eNorth, tx, math.floor(iH * 0.62), nil);
			if south ~= nil and north ~= nil then
				WalkMireCorridor(south:GetX(), south:GetY(), north:GetX(), north:GetY(), skip, 2, iW, iW + iH);
			end
			ni = ni + 1;
		end
	end
	local lakeWant = 4;
	if iH >= 32 then
		lakeWant = 6;
	end
	local lakes = 0;
	while lakes < lakeWant and #fenLake > 0 do
		local idx = 1 + Map.Rand(#fenLake, "Mire Fen Lake");
		local plot = fenLake[idx];
		table.remove(fenLake, idx);
		if plot:IsWater() == false and plot:IsCoastalLand() == false and plot:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN then
			plot:SetPlotType(PlotTypes.PLOT_OCEAN, false, false);
			plot:SetTerrainType(TerrainTypes.TERRAIN_COAST, false, false);
			plot:SetFeatureType(FeatureTypes.NO_FEATURE, -1);
			lakes = lakes + 1;
			if Map.Rand(100, "Mire Fen Lake Grow") < 40 then
				local d = Map.Rand(DirectionTypes.NUM_DIRECTION_TYPES, "Mire Fen Lake Dir");
				local adj = PlotDirNoXWrap(plot:GetX(), plot:GetY(), d);
				if adj ~= nil then
					local ai = adj:GetY() * iW + adj:GetX() + 1;
					if mireBand[ai] == 3 and adj:IsWater() == false and adj:IsCoastalLand() == false and adj:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN and skip[adj:GetX()] ~= true then
						adj:SetPlotType(PlotTypes.PLOT_OCEAN, false, false);
						adj:SetTerrainType(TerrainTypes.TERRAIN_COAST, false, false);
						adj:SetFeatureType(FeatureTypes.NO_FEATURE, -1);
					end
				end
			end
		end
	end
	local marshLeft = {};
	local mi = 1;
	while mi <= #fenMarsh do
		if fenMarsh[mi]:IsWater() == false and fenMarsh[mi]:GetPlotType() == PlotTypes.PLOT_LAND and fenMarsh[mi]:GetTerrainType() == TerrainTypes.TERRAIN_GRASS and fenMarsh[mi]:GetFeatureType() == FeatureTypes.NO_FEATURE then
			table.insert(marshLeft, fenMarsh[mi]);
		end
		mi = mi + 1;
	end
	local marshN, marshT = PlaceClusteredFeature(marshLeft, FeatureTypes.FEATURE_MARSH, 42, "Mire Fen Marsh");
	local forestLeft = {};
	local fi = 1;
	while fi <= #fenForest do
		if fenForest[fi]:IsWater() == false and fenForest[fi]:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN and fenForest[fi]:GetFeatureType() == FeatureTypes.NO_FEATURE then
			table.insert(forestLeft, fenForest[fi]);
		end
		fi = fi + 1;
	end
	local fenForN, fenForT = PlaceClusteredFeature(forestLeft, FeatureTypes.FEATURE_FOREST, 15, "Mire Fen Forest");
	print("Mire pines:", pineN, "/", pineT, " marsh:", marshN, "/", marshT, " fen forest:", fenForN, "/", fenForT, " lakes:", lakes);
end
------------------------------------------------------------------------------
local wastelandWaterDist = {};
function AddWastelandWaterLayout()
	wastelandWaterDist = {};
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "wasteland" then
		return
	end
	local iW, iH = Map.GetGridSize();
	local skip = {};
	local cols = GetSnowWrapColumns(iW);
	local ci = 1;
	while ci <= #cols do
		skip[cols[ci]] = true;
		ci = ci + 1;
	end
	local tundraCols = GetSnowWrapTundraColumns(iW);
	ci = 1;
	while ci <= #tundraCols do
		skip[tundraCols[ci]] = true;
		ci = ci + 1;
	end
	local mirrored = (DEF_MIRRORED == 1);
	local INF = 99;
	local dist = {};
	local qx = {};
	local qy = {};
	local qn = 0;
	local y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			local i = y * iW + x + 1;
			dist[i] = INF;
			if ((not mirrored) or (x <= iW * 0.5)) then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil and PlotIsWastelandWaterSource(plot) then
					dist[i] = 0;
					qn = qn + 1;
					qx[qn] = x;
					qy[qn] = y;
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	local qi = 1;
	while qi <= qn do
		local cx = qx[qi];
		local cy = qy[qi];
		local cd = dist[cy * iW + cx + 1];
		qi = qi + 1;
		local ddir = 0;
		while ddir < DirectionTypes.NUM_DIRECTION_TYPES do
			local adj = PlotDirNoXWrap(cx, cy, ddir);
			if adj ~= nil then
				local ax = adj:GetX();
				local ay = adj:GetY();
				if ((not mirrored) or (ax <= iW * 0.5)) then
					local ai = ay * iW + ax + 1;
					if dist[ai] > cd + 1 then
						dist[ai] = cd + 1;
						qn = qn + 1;
						qx[qn] = ax;
						qy[qn] = ay;
					end
				end
			end
			ddir = ddir + 1;
		end
	end
	local maxDist = 0;
	y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			if skip[x] ~= true and ((not mirrored) or (x <= iW * 0.5)) then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil and plot:IsWater() == false and plot:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN then
					local i = y * iW + x + 1;
					if dist[i] < INF and dist[i] > maxDist then
						maxDist = dist[i];
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	local desertCut = maxDist - 3;
	if desertCut < 5 then
		desertCut = 5;
	end
	local rimFrac = Fractal.Create(iW, iH, 5, Map.GetFractalFlags(), -1, -1);
	local rimH3 = rimFrac:GetHeight(95);
	local rimH1 = rimFrac:GetHeight(80);
	local nFertile = 0;
	local nDesert = 0;
	local nwFeat = {};
	for row in GameInfo.Features() do
		if row.NaturalWonder then
			nwFeat[row.ID] = true;
		end
	end
	y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			local i = y * iW + x + 1;
			wastelandWaterDist[i] = dist[i];
			if skip[x] ~= true and ((not mirrored) or (x <= iW * 0.5)) then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil and plot:IsWater() == false and plot:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN then
					local d = dist[i];
					local feat = plot:GetFeatureType();
					if nwFeat[feat] ~= true then
					local rh = rimFrac:GetHeight(x, y);
					local rimW = 2;
					if rh >= rimH3 then
						rimW = 3;
					elseif rh >= rimH1 then
						rimW = 1;
					end
					if d <= rimW then
						if d <= 1 then
							plot:SetTerrainType(TerrainTypes.TERRAIN_GRASS, false, false);
						elseif Map.Rand(100, "Wasteland Rim Plains") < 35 then
							plot:SetTerrainType(TerrainTypes.TERRAIN_PLAINS, false, false);
						else
							plot:SetTerrainType(TerrainTypes.TERRAIN_GRASS, false, false);
						end
						nFertile = nFertile + 1;
					elseif maxDist >= 5 and d >= desertCut then
						local nearSep = false;
						local si = 1;
						while si <= #tundraCols do
							local dx = x - tundraCols[si];
							if dx < 0 then
								dx = 0 - dx;
							end
							if dx < 3 then
								nearSep = true;
								break
							end
							si = si + 1;
						end
						if nearSep then
							plot:SetTerrainType(TerrainTypes.TERRAIN_TUNDRA, false, false);
						else
							plot:SetTerrainType(TerrainTypes.TERRAIN_DESERT, false, false);
							nDesert = nDesert + 1;
						end
					else
						plot:SetTerrainType(TerrainTypes.TERRAIN_TUNDRA, false, false);
					end
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	JagWastelandBigDeserts(iW, iH, skip, mirrored);
	BufferWastelandDesertFromLush(iW, iH, skip, mirrored);
	CullWastelandDesertSpeckles(iW, iH, skip, mirrored);
	print("Wasteland water layout fertile:", nFertile, " desert:", nDesert, " maxDist:", maxDist);
end
------------------------------------------------------------------------------
function BufferWastelandDesertFromLush(iW, iH, skip, mirrored)
	local hit = {};
	local y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			if skip[x] ~= true and ((not mirrored) or (x <= iW * 0.5)) then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil and plot:GetTerrainType() == TerrainTypes.TERRAIN_DESERT then
					local lush = false;
					local d = 0;
					while d < DirectionTypes.NUM_DIRECTION_TYPES do
						local adj = PlotDirNoXWrap(x, y, d);
						if adj ~= nil then
							local t = adj:GetTerrainType();
							if t == TerrainTypes.TERRAIN_GRASS or t == TerrainTypes.TERRAIN_PLAINS then
								lush = true;
								break
							end
						end
						d = d + 1;
					end
					if lush then
						table.insert(hit, plot);
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	local i = 1;
	while i <= #hit do
		hit[i]:SetTerrainType(TerrainTypes.TERRAIN_TUNDRA, false, false);
		i = i + 1;
	end
end
------------------------------------------------------------------------------
function CullWastelandDesertSpeckles(iW, iH, skip, mirrored)
	local seen = {};
	local y0 = 0;
	while y0 < iH do
		local x0 = 0;
		while x0 < iW do
			local i0 = y0 * iW + x0 + 1;
			if seen[i0] ~= true and skip[x0] ~= true and ((not mirrored) or (x0 <= iW * 0.5)) then
				local seed = Map.GetPlot(x0, y0);
				if seed ~= nil and seed:GetTerrainType() == TerrainTypes.TERRAIN_DESERT then
					local comp = {};
					local qx = {x0};
					local qy = {y0};
					seen[i0] = true;
					table.insert(comp, seed);
					local qi = 1;
					while qi <= #qx do
						local cx = qx[qi];
						local cy = qy[qi];
						qi = qi + 1;
						local ddir = 0;
						while ddir < DirectionTypes.NUM_DIRECTION_TYPES do
							local adj = PlotDirNoXWrap(cx, cy, ddir);
							if adj ~= nil then
								local ax = adj:GetX();
								local ay = adj:GetY();
								local ai = ay * iW + ax + 1;
								if seen[ai] ~= true and skip[ax] ~= true and ((not mirrored) or (ax <= iW * 0.5)) then
									if adj:GetTerrainType() == TerrainTypes.TERRAIN_DESERT then
										seen[ai] = true;
										table.insert(comp, adj);
										table.insert(qx, ax);
										table.insert(qy, ay);
									end
								end
							end
							ddir = ddir + 1;
						end
					end
					if #comp < 5 then
						local ci = 1;
						while ci <= #comp do
							comp[ci]:SetTerrainType(TerrainTypes.TERRAIN_TUNDRA, false, false);
							ci = ci + 1;
						end
					end
				end
			end
			x0 = x0 + 1;
		end
		y0 = y0 + 1;
	end
end
------------------------------------------------------------------------------
function JagWastelandBigDeserts(iW, iH, skip, mirrored)
	local seen = {};
	local frac = Fractal.Create(iW, iH, 4, Map.GetFractalFlags(), -1, -1);
	local edgeCut = frac:GetHeight(56);
	local y0 = 0;
	while y0 < iH do
		local x0 = 0;
		while x0 < iW do
			local i0 = y0 * iW + x0 + 1;
			if seen[i0] ~= true and skip[x0] ~= true and ((not mirrored) or (x0 <= iW * 0.5)) then
				local seed = Map.GetPlot(x0, y0);
				if seed ~= nil and seed:GetTerrainType() == TerrainTypes.TERRAIN_DESERT then
					local comp = {};
					local qx = {x0};
					local qy = {y0};
					seen[i0] = true;
					table.insert(comp, seed);
					local qi = 1;
					while qi <= #qx do
						local cx = qx[qi];
						local cy = qy[qi];
						qi = qi + 1;
						local ddir = 0;
						while ddir < DirectionTypes.NUM_DIRECTION_TYPES do
							local adj = PlotDirNoXWrap(cx, cy, ddir);
							if adj ~= nil then
								local ax = adj:GetX();
								local ay = adj:GetY();
								local ai = ay * iW + ax + 1;
								if seen[ai] ~= true and skip[ax] ~= true and ((not mirrored) or (ax <= iW * 0.5)) then
									if adj:GetTerrainType() == TerrainTypes.TERRAIN_DESERT then
										seen[ai] = true;
										table.insert(comp, adj);
										table.insert(qx, ax);
										table.insert(qy, ay);
									end
								end
							end
							ddir = ddir + 1;
						end
					end
					local n = #comp;
					if n > 8 then
						local target = 8 + math.floor((n - 8) * 0.30);
						if target < 8 then
							target = 8;
						end
						local pass = 0;
						while #comp > target and pass < 24 do
							pass = pass + 1;
							local left = {};
							local ci = 1;
							while ci <= #comp do
								local p = comp[ci];
								if p:GetTerrainType() == TerrainTypes.TERRAIN_DESERT then
									local nDes = 0;
									local d = 0;
									while d < DirectionTypes.NUM_DIRECTION_TYPES do
										local adj = PlotDirNoXWrap(p:GetX(), p:GetY(), d);
										if adj ~= nil and adj:GetTerrainType() == TerrainTypes.TERRAIN_DESERT then
											nDes = nDes + 1;
										end
										d = d + 1;
									end
									local hh = frac:GetHeight(p:GetX(), p:GetY());
									local eat = false;
									if nDes <= 4 and hh < edgeCut then
										eat = true;
									end
									if eat then
										p:SetTerrainType(TerrainTypes.TERRAIN_TUNDRA, false, false);
									else
										table.insert(left, p);
									end
								end
								ci = ci + 1;
							end
							if #left >= #comp then
								left = GetShuffledCopyOfTable(left);
								local need = #left - target;
								local k = 1;
								while k <= need and k <= #left do
									left[k]:SetTerrainType(TerrainTypes.TERRAIN_TUNDRA, false, false);
									k = k + 1;
								end
								local kept = {};
								k = need + 1;
								while k <= #left do
									table.insert(kept, left[k]);
									k = k + 1;
								end
								comp = kept;
							else
								comp = left;
							end
						end
					end
				end
			end
			x0 = x0 + 1;
		end
		y0 = y0 + 1;
	end
end
------------------------------------------------------------------------------
local lakeVictoriaFeatureID = nil;
local lakeVictoriaResolved = false;
function GetLakeVictoriaFeatureID()
	if lakeVictoriaResolved then
		return lakeVictoriaFeatureID;
	end
	lakeVictoriaResolved = true;
	local id = GameInfoTypes["FEATURE_LAKE_VICTORIA"];
	if id ~= nil then
		lakeVictoriaFeatureID = id;
		return lakeVictoriaFeatureID;
	end
	for row in GameInfo.Features() do
		if row.NaturalWonder then
			local t = string.upper(tostring(row.Type));
			if string.find(t, "VICTORIA", 1, true) then
				lakeVictoriaFeatureID = row.ID;
				return lakeVictoriaFeatureID;
			end
		end
	end
	return nil;
end
------------------------------------------------------------------------------
function PlotIsWastelandWaterSource(plot)
	if plot == nil then
		return false
	end
	if plot:IsWater() then
		return true
	end
	local vid = GetLakeVictoriaFeatureID();
	if vid ~= nil and plot:GetFeatureType() == vid then
		return true
	end
	return false;
end
------------------------------------------------------------------------------
function FixWastelandFloodPlains()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "wasteland" then
		return
	end
	local iW, iH = Map.GetGridSize();
	local skip = {};
	local cols = GetSnowWrapColumns(iW);
	local ci = 1;
	while ci <= #cols do
		skip[cols[ci]] = true;
		ci = ci + 1;
	end
	cols = GetSnowWrapTundraColumns(iW);
	ci = 1;
	while ci <= #cols do
		skip[cols[ci]] = true;
		ci = ci + 1;
	end
	local mirrored = (DEF_MIRRORED == 1);
	local nStrip = 0;
	local nAdd = 0;
	local y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			if skip[x] ~= true and ((not mirrored) or (x <= iW * 0.5)) then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil and plot:IsWater() == false then
					local feat = plot:GetFeatureType();
					local ter = plot:GetTerrainType();
					if ter ~= TerrainTypes.TERRAIN_DESERT then
						if feat == FeatureTypes.FEATURE_FLOOD_PLAINS or feat == FeatureTypes.FEATURE_OASIS then
							plot:SetFeatureType(FeatureTypes.NO_FEATURE, -1);
							nStrip = nStrip + 1;
						end
					elseif feat == FeatureTypes.NO_FEATURE and plot:CanHaveFeature(FeatureTypes.FEATURE_FLOOD_PLAINS) then
						plot:SetFeatureType(FeatureTypes.FEATURE_FLOOD_PLAINS, -1);
						nAdd = nAdd + 1;
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	print("Wasteland floodplains strip:", nStrip, " add:", nAdd);
end
------------------------------------------------------------------------------
function PeakMassifClear(px, py, minD, iW, iH, skip, mirrored)
	local y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			if skip[x] ~= true and ((not mirrored) or (x <= iW * 0.5)) then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil and plot:GetPlotType() == PlotTypes.PLOT_MOUNTAIN then
					if Map.PlotDistance(px, py, x, y) < minD then
						return false
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	return true;
end
------------------------------------------------------------------------------
function PeakTouchesForeignMountain(adj, q)
	local d = 0;
	while d < DirectionTypes.NUM_DIRECTION_TYPES do
		local n = PlotDirNoXWrap(adj:GetX(), adj:GetY(), d);
		if n ~= nil and n:GetPlotType() == PlotTypes.PLOT_MOUNTAIN then
			local found = false;
			local qi = 1;
			while qi <= #q do
				if q[qi]:GetX() == n:GetX() and q[qi]:GetY() == n:GetY() then
					found = true;
					break
				end
				qi = qi + 1;
			end
			if found == false then
				return true
			end
		end
		d = d + 1;
	end
	return false;
end
------------------------------------------------------------------------------
function PeakPlotUsable(plot, skip, mirrored, iW, frontBand)
	if plot == nil then
		return false
	end
	local ax = plot:GetX();
	if skip[ax] == true then
		return false
	end
	if WaterAllowedAtX(ax) == false then
		return false
	end
	if frontBand ~= nil and frontBand[ax] == true then
		return false
	end
	if mirrored and ax > iW * 0.5 then
		return false
	end
	if plot:IsWater() then
		return false
	end
	if plot:GetPlotType() == PlotTypes.PLOT_MOUNTAIN then
		return false
	end
	return true;
end
------------------------------------------------------------------------------
function PeakBlobTargetSize()
	local r = Map.Rand(100, "Peaks Blob Size");
	if r < 20 then
		return 2 + Map.Rand(2, "Peaks Blob Tiny");
	end
	if r < 85 then
		return 5 + Map.Rand(2, "Peaks Blob Mid");
	end
	return 7 + Map.Rand(2, "Peaks Blob Big");
end
------------------------------------------------------------------------------
function PeakCountBlobNeighbors(plot, q)
	local n = 0;
	local d = 0;
	while d < DirectionTypes.NUM_DIRECTION_TYPES do
		local adj = PlotDirNoXWrap(plot:GetX(), plot:GetY(), d);
		if adj ~= nil then
			local qi = 1;
			while qi <= #q do
				if q[qi]:GetX() == adj:GetX() and q[qi]:GetY() == adj:GetY() then
					n = n + 1;
					break
				end
				qi = qi + 1;
			end
		end
		d = d + 1;
	end
	return n;
end
------------------------------------------------------------------------------
function PeakGrowFromSeed(seed, target, skip, mirrored, iW, frontBand)
	local q = {};
	table.insert(q, seed);
	seed:SetPlotType(PlotTypes.PLOT_MOUNTAIN, false, false);
	seed:SetTerrainType(TerrainTypes.TERRAIN_PLAINS, false, false);
	local qi = 1;
	local grown = 1;
	while qi <= #q and grown < target do
		local p = q[qi];
		qi = qi + 1;
		local d0 = Map.Rand(DirectionTypes.NUM_DIRECTION_TYPES, "Peaks Blob Dir");
		local k = 0;
		while k < DirectionTypes.NUM_DIRECTION_TYPES and grown < target do
			local d = d0 + k;
			if d >= DirectionTypes.NUM_DIRECTION_TYPES then
				d = d - DirectionTypes.NUM_DIRECTION_TYPES;
			end
			local adj = PlotDirNoXWrap(p:GetX(), p:GetY(), d);
			if adj ~= nil then
				local cand = adj;
				if Map.Rand(100, "Peaks Blob Skip") < 26 then
					local far = PlotDirNoXWrap(adj:GetX(), adj:GetY(), d);
					if far ~= nil then
						cand = far;
					end
				end
				if PeakPlotUsable(cand, skip, mirrored, iW, frontBand) then
					if PeakTouchesForeignMountain(cand, q) == false then
						local packed = PeakCountBlobNeighbors(cand, q);
						local allow = true;
						if packed >= 3 and Map.Rand(100, "Peaks Blob Pack") >= 20 then
							allow = false;
						end
						if allow and Map.Rand(100, "Peaks Blob Grow") < 76 then
							cand:SetPlotType(PlotTypes.PLOT_MOUNTAIN, false, false);
							cand:SetTerrainType(TerrainTypes.TERRAIN_PLAINS, false, false);
							table.insert(q, cand);
							grown = grown + 1;
						end
					end
				end
			end
			k = k + 1;
		end
	end
	return q;
end
------------------------------------------------------------------------------
function PeakTouchesForeignWater(adj, q)
	local d = 0;
	while d < DirectionTypes.NUM_DIRECTION_TYPES do
		local n = PlotDirNoXWrap(adj:GetX(), adj:GetY(), d);
		if n ~= nil and n:IsWater() then
			local found = false;
			local qi = 1;
			while qi <= #q do
				if q[qi]:GetX() == n:GetX() and q[qi]:GetY() == n:GetY() then
					found = true;
					break
				end
				qi = qi + 1;
			end
			if found == false then
				return true
			end
		end
		d = d + 1;
	end
	return false;
end
------------------------------------------------------------------------------
function PeakGrowWaterFromSeed(seed, target, skip, mirrored, iW, iH, frontBand)
	local q = {};
	table.insert(q, seed);
	seed:SetPlotType(PlotTypes.PLOT_OCEAN, false, false);
	seed:SetTerrainType(TerrainTypes.TERRAIN_COAST, false, false);
	seed:SetFeatureType(FeatureTypes.NO_FEATURE, -1);
	local qi = 1;
	local grown = 1;
	while qi <= #q and grown < target do
		local p = q[qi];
		qi = qi + 1;
		local d = 0;
		while d < DirectionTypes.NUM_DIRECTION_TYPES do
			local adj = PlotDirNoXWrap(p:GetX(), p:GetY(), d);
			if adj ~= nil and grown < target then
				local ay = adj:GetY();
				if ay >= 2 and ay < iH - 2 then
					if PeakPlotUsable(adj, skip, mirrored, iW, frontBand) then
						if PeakTouchesForeignWater(adj, q) == false then
							if Map.Rand(100, "Peaks Pond Grow") < 80 then
								adj:SetPlotType(PlotTypes.PLOT_OCEAN, false, false);
								adj:SetTerrainType(TerrainTypes.TERRAIN_COAST, false, false);
								adj:SetFeatureType(FeatureTypes.NO_FEATURE, -1);
								table.insert(q, adj);
								grown = grown + 1;
							end
						end
					end
				end
			end
			d = d + 1;
		end
	end
	return q;
end
------------------------------------------------------------------------------
function PeakRevertWater(q)
	local i = 1;
	while i <= #q do
		q[i]:SetPlotType(PlotTypes.PLOT_LAND, false, false);
		q[i]:SetTerrainType(TerrainTypes.TERRAIN_PLAINS, false, false);
		q[i]:SetFeatureType(FeatureTypes.NO_FEATURE, -1);
		i = i + 1;
	end
end
------------------------------------------------------------------------------
function PeakPondTwinSeed(water, mountains, skip, mirrored, iW, frontBand)
	if #water < 1 or #mountains < 1 then
		return nil
	end
	local cx = 0;
	local cy = 0;
	local mi = 1;
	while mi <= #mountains do
		cx = cx + mountains[mi]:GetX();
		cy = cy + mountains[mi]:GetY();
		mi = mi + 1;
	end
	cx = math.floor(cx / #mountains + 0.5);
	cy = math.floor(cy / #mountains + 0.5);
	local best = nil;
	local bestD = -1;
	local wi = 1;
	while wi <= #water do
		local ddir = 0;
		while ddir < DirectionTypes.NUM_DIRECTION_TYPES do
			local adj = PlotDirNoXWrap(water[wi]:GetX(), water[wi]:GetY(), ddir);
			if PeakPlotUsable(adj, skip, mirrored, iW, frontBand) then
				if PeakTouchesForeignMountain(adj, {}) == false then
					local d = Map.PlotDistance(adj:GetX(), adj:GetY(), cx, cy);
					if d > bestD then
						bestD = d;
						best = adj;
					end
				end
			end
			ddir = ddir + 1;
		end
		wi = wi + 1;
	end
	return best;
end
------------------------------------------------------------------------------
function PeakTryDoublePeak(q, skip, mirrored, iW, iH, frontBand)
	local nWater = 4 + Map.Rand(3, "Peaks Pond Size");
	local starts = GetShuffledCopyOfTable(q);
	local si = 1;
	while si <= #starts do
		local d0 = Map.Rand(DirectionTypes.NUM_DIRECTION_TYPES, "Peaks Pond Dir");
		local k = 0;
		while k < DirectionTypes.NUM_DIRECTION_TYPES do
			local dir = d0 + k;
			if dir >= DirectionTypes.NUM_DIRECTION_TYPES then
				dir = dir - DirectionTypes.NUM_DIRECTION_TYPES;
			end
			local seed = PlotDirNoXWrap(starts[si]:GetX(), starts[si]:GetY(), dir);
			local sy = -1;
			if seed ~= nil then
				sy = seed:GetY();
			end
			if sy >= 2 and sy < iH - 2 and PeakPlotUsable(seed, skip, mirrored, iW, frontBand) then
				if Map.FindWater(seed, 2, false) == false then
					local water = PeakGrowWaterFromSeed(seed, nWater, skip, mirrored, iW, iH, frontBand);
					if #water >= 3 then
						local twin = PeakPondTwinSeed(water, q, skip, mirrored, iW, frontBand);
						if twin ~= nil then
							return PeakGrowFromSeed(twin, PeakBlobTargetSize(), skip, mirrored, iW, frontBand)
						end
					end
					PeakRevertWater(water);
				end
			end
			k = k + 1;
		end
		si = si + 1;
	end
	return nil;
end
------------------------------------------------------------------------------
function PeakRollMassifKnobs()
	nPeakMassifs = nPeakMassifs + 1;
	local id = nPeakMassifs;
	if Map.Rand(2, "Peaks Hill Style") == 0 then
		peakHillStyle[id] = 1;
		peakHillT1[id] = 0;
		peakHillT2[id] = 22 + Map.Rand(18, "Peaks Thick T2");
		peakHillT3[id] = 88 + Map.Rand(10, "Peaks Thick T3");
	else
		peakHillStyle[id] = 2;
		peakHillT1[id] = 26 + Map.Rand(24, "Peaks Spike T1");
		peakHillT2[id] = 40 + Map.Rand(20, "Peaks Spike T2");
		peakHillT3[id] = 55 + Map.Rand(22, "Peaks Spike T3");
	end
	local fr = Map.Rand(100, "Peaks Forest Style");
	if fr < 38 then
		peakForestStyle[id] = 1;
	elseif fr < 72 then
		peakForestStyle[id] = 2;
	else
		peakForestStyle[id] = 3;
	end
	return id;
end
------------------------------------------------------------------------------
function PeakRollFrontKnobs()
	nPeakMassifs = nPeakMassifs + 1;
	local id = nPeakMassifs;
	peakHillStyle[id] = 2;
	peakHillT1[id] = 50 + Map.Rand(20, "Peaks Front T1");
	peakHillT2[id] = 70 + Map.Rand(15, "Peaks Front T2");
	peakHillT3[id] = 88 + Map.Rand(10, "Peaks Front T3");
	peakForestStyle[id] = 1;
	return id;
end
------------------------------------------------------------------------------
function PeakStampMassif(q, id)
	local iW = Map.GetGridSize();
	local i = 1;
	while i <= #q do
		local p = q[i];
		peakMassif[p:GetY() * iW + p:GetX() + 1] = id;
		i = i + 1;
	end
end
------------------------------------------------------------------------------
function PeakStampConnectedMountains(sx, sy, id, iW, iH, skip, mirrored)
	local qx = {sx};
	local qy = {sy};
	peakMassif[sy * iW + sx + 1] = id;
	local qi = 1;
	while qi <= #qx do
		local cx = qx[qi];
		local cy = qy[qi];
		qi = qi + 1;
		local ddir = 0;
		while ddir < DirectionTypes.NUM_DIRECTION_TYPES do
			local adj = PlotDirNoXWrap(cx, cy, ddir);
			if adj ~= nil then
				local ax = adj:GetX();
				local ay = adj:GetY();
				local ai = ay * iW + ax + 1;
				if skip[ax] ~= true and ((not mirrored) or (ax <= iW * 0.5)) then
					if adj:GetPlotType() == PlotTypes.PLOT_MOUNTAIN and peakMassif[ai] == nil then
						peakMassif[ai] = id;
						qx[#qx + 1] = ax;
						qy[#qy + 1] = ay;
					end
				end
			end
			ddir = ddir + 1;
		end
	end
end
------------------------------------------------------------------------------
function PeakAssignUntaggedMassifs(iW, iH, skip, mirrored)
	local y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			if skip[x] ~= true and ((not mirrored) or (x <= iW * 0.5)) then
				local i = y * iW + x + 1;
				if peakMassif[i] == nil then
					local plot = Map.GetPlot(x, y);
					if plot ~= nil and plot:GetPlotType() == PlotTypes.PLOT_MOUNTAIN then
						PeakStampConnectedMountains(x, y, PeakRollFrontKnobs(), iW, iH, skip, mirrored);
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
end
------------------------------------------------------------------------------
function AddPeaksLayout()
	peakDist = {};
	peakNX = {};
	peakNY = {};
	peakMassif = {};
	peakHillStyle = {};
	peakHillT1 = {};
	peakHillT2 = {};
	peakHillT3 = {};
	peakForestStyle = {};
	nPeakMassifs = 0;
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "peaks" then
		return
	end
	local iW, iH = Map.GetGridSize();
	local skip = FillMireSkip(iW);
	local mid = math.floor(iW / 2);
	local frontBand = {};
	frontBand[mid - 5] = true;
	frontBand[mid - 4] = true;
	frontBand[mid - 3] = true;
	frontBand[mid + 2] = true;
	frontBand[mid + 3] = true;
	frontBand[mid + 4] = true;
	if IsSnowWrapX() then
		local xWest, xEast = GetSnowWrapLandMountainXs(iW);
		frontBand[xWest - 1] = true;
		frontBand[xWest] = true;
		frontBand[xWest + 1] = true;
		frontBand[xEast - 1] = true;
		frontBand[xEast] = true;
		frontBand[xEast + 1] = true;
	end
	local noBlob = {};
	local bx = 0;
	while bx < iW do
		if frontBand[bx] == true then
			noBlob[bx] = true;
		end
		bx = bx + 1;
	end
	local sc = GetSnowWrapColumns(iW);
	local sci = 1;
	while sci <= #sc do
		noBlob[sc[sci]] = true;
		sci = sci + 1;
	end
	local mirrored = (DEF_MIRRORED == 1);
	local land = {};
	local y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			if skip[x] ~= true and ((not mirrored) or (x <= iW * 0.5)) then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil and plot:IsWater() == false then
					local keepFront = (frontBand[x] == true and plot:GetPlotType() == PlotTypes.PLOT_MOUNTAIN);
					if keepFront == false then
						if plot:GetPlotType() ~= PlotTypes.PLOT_LAND then
							plot:SetPlotType(PlotTypes.PLOT_LAND, false, false);
						end
					end
					if keepFront == false and noBlob[x] ~= true and y >= 2 and y < iH - 2 then
						table.insert(land, plot);
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	land = GetShuffledCopyOfTable(land);
	local nBlobs = 5 + Map.Rand(4, "Peaks Massif Count");
	local blobN = 0;
	local nPlaced = 0;
	local nDouble = 0;
	local pass = 1;
	local minClear = 6;
	while pass <= 2 and nPlaced < nBlobs do
		if pass == 2 then
			minClear = 4;
			land = GetShuffledCopyOfTable(land);
		end
		local li = 1;
		while nPlaced < nBlobs and li <= #land do
			local seed = land[li];
			li = li + 1;
			if seed:IsWater() == false and seed:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN then
				local px = seed:GetX();
				local py = seed:GetY();
				if PeakMassifClear(px, py, minClear, iW, iH, skip, mirrored) then
					local q = PeakGrowFromSeed(seed, PeakBlobTargetSize(), skip, mirrored, iW, noBlob);
					blobN = blobN + #q;
					nPlaced = nPlaced + 1;
					PeakStampMassif(q, PeakRollMassifKnobs());
					local didDouble = false;
					if nDouble < 1 and nPlaced == 1 and Map.Rand(100, "Peaks Double") < 18 then
						local q2 = PeakTryDoublePeak(q, skip, mirrored, iW, iH, noBlob);
						if q2 ~= nil then
							blobN = blobN + #q2;
							nPlaced = nPlaced + 1;
							nDouble = nDouble + 1;
							didDouble = true;
							PeakStampMassif(q2, PeakRollMassifKnobs());
						end
					end
					if didDouble == false and #q >= 8 then
						local west = q[1];
						local east = q[1];
						local wi = 1;
						while wi <= #q do
							if q[wi]:GetX() < west:GetX() then
								west = q[wi];
							end
							if q[wi]:GetX() > east:GetX() then
								east = q[wi];
							end
							wi = wi + 1;
						end
						WalkMireCorridor(west:GetX(), west:GetY(), east:GetX(), east:GetY(), skip, 0, iW, 20);
						west:SetPlotType(PlotTypes.PLOT_LAND, false, false);
						east:SetPlotType(PlotTypes.PLOT_LAND, false, false);
					end
				end
			end
		end
		pass = pass + 1;
	end
	PeakAssignUntaggedMassifs(iW, iH, skip, mirrored);
	local INF = 99;
	local dist = {};
	local nx = {};
	local ny = {};
	local mz = {};
	local qx = {};
	local qy = {};
	local qn = 0;
	y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			local i = y * iW + x + 1;
			dist[i] = INF;
			if skip[x] ~= true and ((not mirrored) or (x <= iW * 0.5)) then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil and plot:GetPlotType() == PlotTypes.PLOT_MOUNTAIN then
					dist[i] = 0;
					nx[i] = x;
					ny[i] = y;
					mz[i] = peakMassif[i];
					qn = qn + 1;
					qx[qn] = x;
					qy[qn] = y;
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	local qi = 1;
	while qi <= qn do
		local cx = qx[qi];
		local cy = qy[qi];
		local ci = cy * iW + cx + 1;
		local cd = dist[ci];
		qi = qi + 1;
		local ddir = 0;
		while ddir < DirectionTypes.NUM_DIRECTION_TYPES do
			local adj = PlotDirNoXWrap(cx, cy, ddir);
			if adj ~= nil then
				local ax = adj:GetX();
				local ay = adj:GetY();
				if skip[ax] ~= true and ((not mirrored) or (ax <= iW * 0.5)) then
					local ai = ay * iW + ax + 1;
					if dist[ai] > cd + 1 then
						dist[ai] = cd + 1;
						nx[ai] = nx[ci];
						ny[ai] = ny[ci];
						mz[ai] = mz[ci];
						qn = qn + 1;
						qx[qn] = ax;
						qy[qn] = ay;
					end
				end
			end
			ddir = ddir + 1;
		end
	end
	local hillFrac = Fractal.Create(iW, iH, 5, Map.GetFractalFlags(), -1, -1);
	local nHill = 0;
	y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			local i = y * iW + x + 1;
			peakDist[i] = dist[i];
			peakNX[i] = nx[i];
			peakNY[i] = ny[i];
			if mz[i] ~= nil then
				peakMassif[i] = mz[i];
			end
			if skip[x] ~= true and ((not mirrored) or (x <= iW * 0.5)) then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil and plot:IsWater() == false then
					if plot:GetPlotType() == PlotTypes.PLOT_MOUNTAIN then
						plot:SetTerrainType(TerrainTypes.TERRAIN_PLAINS, false, false);
					else
						local d = dist[i];
						local makeHill = false;
						if d < INF then
							local id = mz[i];
							local st = 1;
							local p1 = 0;
							local p2 = 32;
							local p3 = 92;
							if id ~= nil and peakHillStyle[id] ~= nil then
								st = peakHillStyle[id];
								p1 = peakHillT1[id];
								p2 = peakHillT2[id];
								p3 = peakHillT3[id];
							end
							local hh = hillFrac:GetHeight(x, y);
							if st == 1 then
								if d == 1 then
									makeHill = true;
								elseif d == 2 and hh >= hillFrac:GetHeight(p2) then
									makeHill = true;
								elseif d == 3 and hh >= hillFrac:GetHeight(p3) then
									makeHill = true;
								end
							else
								if d == 1 and hh >= hillFrac:GetHeight(p1) then
									makeHill = true;
								elseif d == 2 and hh >= hillFrac:GetHeight(p2) then
									makeHill = true;
								elseif d == 3 and hh >= hillFrac:GetHeight(p3) then
									makeHill = true;
								end
							end
						end
						if makeHill == false and d >= 6 and d < INF and Map.Rand(100, "Peaks Far Hill") < 8 then
							makeHill = true;
						end
						if makeHill then
							plot:SetPlotType(PlotTypes.PLOT_HILLS, false, false);
							plot:SetTerrainType(TerrainTypes.TERRAIN_PLAINS, false, false);
							nHill = nHill + 1;
						else
							plot:SetPlotType(PlotTypes.PLOT_LAND, false, false);
							plot:SetTerrainType(TerrainTypes.TERRAIN_PLAINS, false, false);
						end
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	print("Peaks blobs mountains:", blobN, " hill collar:", nHill, " massifs:", nPlaced, " rolled:", nBlobs, " doubles:", nDouble, " styles:", nPeakMassifs);
	PeakFlattenFrontTundraHills();
	PeakScatterFrontRelief();
end
------------------------------------------------------------------------------
function PeakTouchesMountain(plot)
	local d = 0;
	while d < DirectionTypes.NUM_DIRECTION_TYPES do
		local adj = PlotDirNoXWrap(plot:GetX(), plot:GetY(), d);
		if adj ~= nil and adj:GetPlotType() == PlotTypes.PLOT_MOUNTAIN then
			return true
		end
		d = d + 1;
	end
	return false;
end
------------------------------------------------------------------------------
function PeakFlattenFrontTundraHills()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "peaks" then
		return
	end
	local iW, iH = Map.GetGridSize();
	local cols = GetSnowWrapTundraColumns(iW);
	local n = 0;
	local ci = 1;
	while ci <= #cols do
		local x = cols[ci];
		if x >= 0 and x < iW and ((DEF_MIRRORED ~= 1) or (x <= iW * 0.5)) then
			local y = 0;
			while y < iH do
				local plot = Map.GetPlot(x, y);
				if plot ~= nil and plot:IsWater() == false and plot:GetPlotType() == PlotTypes.PLOT_HILLS then
					if PeakTouchesMountain(plot) == false then
						if Map.Rand(100, "Peaks Tundra Flatten") < 85 then
							plot:SetPlotType(PlotTypes.PLOT_LAND, false, false);
							n = n + 1;
						end
					end
				end
				y = y + 1;
			end
		end
		ci = ci + 1;
	end
	print("Peaks front tundra flatten:", n);
end
------------------------------------------------------------------------------
function PeakScatterFrontRelief()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "peaks" then
		return
	end
	local iW, iH = Map.GetGridSize();
	local cols = GetSnowWrapTundraColumns(iW);
	local nHill = 0;
	local nMtn = 0;
	local ci = 1;
	while ci <= #cols do
		local x = cols[ci];
		if x >= 0 and x < iW and ((DEF_MIRRORED ~= 1) or (x <= iW * 0.5)) then
			local y = 0;
			while y < iH do
				local plot = Map.GetPlot(x, y);
				if plot ~= nil and plot:IsWater() == false and plot:GetPlotType() == PlotTypes.PLOT_LAND then
					local pt = Map.Rand(100, "Peaks Tundra Scatter");
					if pt < 3 then
						plot:SetPlotType(PlotTypes.PLOT_MOUNTAIN, false, false);
						nMtn = nMtn + 1;
					elseif pt < 17 then
						plot:SetPlotType(PlotTypes.PLOT_HILLS, false, false);
						nHill = nHill + 1;
					end
				end
				y = y + 1;
			end
		end
		ci = ci + 1;
	end
	print("Peaks front tundra scatter hills:", nHill, " peaks:", nMtn);
end
------------------------------------------------------------------------------
function PeakAdjGrass(plot)
	local d = 0;
	while d < DirectionTypes.NUM_DIRECTION_TYPES do
		local adj = PlotDirNoXWrap(plot:GetX(), plot:GetY(), d);
		if adj ~= nil and adj:IsWater() == false and adj:GetTerrainType() == TerrainTypes.TERRAIN_GRASS then
			return true
		end
		d = d + 1;
	end
	return false;
end
------------------------------------------------------------------------------
function PeakAdjForest(plot)
	local d = 0;
	while d < DirectionTypes.NUM_DIRECTION_TYPES do
		local adj = PlotDirNoXWrap(plot:GetX(), plot:GetY(), d);
		if adj ~= nil and adj:GetFeatureType() == FeatureTypes.FEATURE_FOREST then
			return true
		end
		d = d + 1;
	end
	return false;
end
------------------------------------------------------------------------------
function PeakMeadowEligible(plot, skip, mirrored, iW)
	if plot == nil then
		return false
	end
	local ax = plot:GetX();
	if skip[ax] == true then
		return false
	end
	if mirrored and ax > iW * 0.5 then
		return false
	end
	if plot:IsWater() then
		return false
	end
	if plot:GetPlotType() ~= PlotTypes.PLOT_LAND then
		return false
	end
	if plot:GetTerrainType() ~= TerrainTypes.TERRAIN_PLAINS then
		return false
	end
	return true;
end
------------------------------------------------------------------------------
function PeakAdjRiver(plot)
	local d = 0;
	while d < DirectionTypes.NUM_DIRECTION_TYPES do
		local adj = PlotDirNoXWrap(plot:GetX(), plot:GetY(), d);
		if adj ~= nil and adj:IsWater() == false and adj:IsRiver() then
			return true
		end
		d = d + 1;
	end
	return false;
end
------------------------------------------------------------------------------
function PeakGrowMeadow(seed, target, skip, mirrored, iW)
	local q = {};
	table.insert(q, seed);
	seed:SetTerrainType(TerrainTypes.TERRAIN_GRASS, false, false);
	local grown = 1;
	local qi = 1;
	while qi <= #q and grown < target do
		local p = q[qi];
		qi = qi + 1;
		local d = 0;
		while d < DirectionTypes.NUM_DIRECTION_TYPES do
			local adj = PlotDirNoXWrap(p:GetX(), p:GetY(), d);
			if adj ~= nil and grown < target then
				if PeakMeadowEligible(adj, skip, mirrored, iW) then
					local take = false;
					if adj:IsRiver() then
						if Map.Rand(100, "Peaks Meadow River") < 90 then
							take = true;
						end
					elseif PeakAdjGrass(adj) then
						if PeakAdjRiver(adj) then
							if Map.Rand(100, "Peaks Meadow Bleed") < 72 then
								take = true;
							end
						elseif PeakAdjForest(adj) then
							if Map.Rand(100, "Peaks Meadow Forest") < 30 then
								take = true;
							end
						end
					end
					if take then
						adj:SetTerrainType(TerrainTypes.TERRAIN_GRASS, false, false);
						table.insert(q, adj);
						grown = grown + 1;
					end
				end
			end
			d = d + 1;
		end
	end
	return grown;
end
------------------------------------------------------------------------------
function PeakForestCollarEligible(plot, skip, mirrored, iW, massifId)
	if plot == nil then
		return false
	end
	local ax = plot:GetX();
	local ay = plot:GetY();
	if skip[ax] == true then
		return false
	end
	if mirrored and ax > iW * 0.5 then
		return false
	end
	if plot:IsWater() then
		return false
	end
	if plot:GetPlotType() == PlotTypes.PLOT_MOUNTAIN then
		return false
	end
	if plot:GetFeatureType() ~= FeatureTypes.NO_FEATURE then
		return false
	end
	local di = ay * iW + ax + 1;
	if peakMassif[di] ~= massifId then
		return false
	end
	local d = peakDist[di];
	if d == nil or d < 1 or d > 3 then
		return false
	end
	return true;
end
------------------------------------------------------------------------------
function PeakGrowForest(seed, target, skip, mirrored, iW, massifId)
	local q = {};
	table.insert(q, seed);
	seed:SetFeatureType(FeatureTypes.FEATURE_FOREST, -1);
	local grown = 1;
	local qi = 1;
	while qi <= #q and grown < target do
		local p = q[qi];
		qi = qi + 1;
		local d = 0;
		while d < DirectionTypes.NUM_DIRECTION_TYPES do
			local adj = PlotDirNoXWrap(p:GetX(), p:GetY(), d);
			if adj ~= nil and grown < target then
				if PeakForestCollarEligible(adj, skip, mirrored, iW, massifId) then
					if Map.Rand(100, "Peaks Forest Blob Grow") < 70 then
						adj:SetFeatureType(FeatureTypes.FEATURE_FOREST, -1);
						table.insert(q, adj);
						grown = grown + 1;
					end
				end
			end
			d = d + 1;
		end
	end
	return grown;
end
------------------------------------------------------------------------------
function AddPeaksMassifForests()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "peaks" then
		return
	end
	local iW, iH = Map.GetGridSize();
	local skip = FillMireSkip(iW);
	local mirrored = (DEF_MIRRORED == 1);
	local nBlob = 0;
	local nTiles = 0;
	local id = 1;
	while id <= nPeakMassifs do
		if peakForestStyle[id] == 3 then
			local seeds = {};
			local y = 0;
			while y < iH do
				local x = 0;
				while x < iW do
					local plot = Map.GetPlot(x, y);
					if PeakForestCollarEligible(plot, skip, mirrored, iW, id) then
						table.insert(seeds, plot);
					end
					x = x + 1;
				end
				y = y + 1;
			end
			if #seeds > 0 then
				seeds = GetShuffledCopyOfTable(seeds);
				local nWant = 1;
				if Map.Rand(100, "Peaks Forest Blob Extra") < 22 then
					nWant = 2;
				end
				local b = 0;
				local si = 1;
				while b < nWant and si <= #seeds do
					local seed = seeds[si];
					si = si + 1;
					if seed:GetFeatureType() == FeatureTypes.NO_FEATURE then
						local sz = 7 + Map.Rand(5, "Peaks Forest Blob Size");
						if b > 0 then
							sz = 5 + Map.Rand(3, "Peaks Forest Blob Small");
						end
						nTiles = nTiles + PeakGrowForest(seed, sz, skip, mirrored, iW, id);
						nBlob = nBlob + 1;
						b = b + 1;
					end
				end
			end
		end
		id = id + 1;
	end
	print("Peaks forest blobs:", nBlob, " tiles:", nTiles);
end
------------------------------------------------------------------------------
function AddPeaksBackCoastForest()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "peaks" then
		return
	end
	local iW, iH = Map.GetGridSize();
	local skip = FillMireSkip(iW);
	local mirrored = (DEF_MIRRORED == 1);
	local wrapN = ResolveSnowWrapWidths();
	local wrapHalf = wrapN / 2;
	local mid = math.floor(iW / 2);
	local backMax = math.floor(mid * 0.42);
	if wrapHalf > 0 then
		if backMax < wrapHalf + 8 then
			backMax = wrapHalf + 8;
		end
	elseif backMax < 8 then
		backMax = 8;
	end
	local INF = 99;
	local wdist = {};
	local qx = {};
	local qy = {};
	local qn = 0;
	local y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			local i = y * iW + x + 1;
			wdist[i] = INF;
			if x <= backMax and ((not mirrored) or (x <= iW * 0.5)) then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil and plot:IsWater() then
					wdist[i] = 0;
					qn = qn + 1;
					qx[qn] = x;
					qy[qn] = y;
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	local qi = 1;
	while qi <= qn do
		local cx = qx[qi];
		local cy = qy[qi];
		local cd = wdist[cy * iW + cx + 1];
		qi = qi + 1;
		if cd < 2 then
			local ddir = 0;
			while ddir < DirectionTypes.NUM_DIRECTION_TYPES do
				local adj = PlotDirNoXWrap(cx, cy, ddir);
				if adj ~= nil then
					local ax = adj:GetX();
					local ay = adj:GetY();
					if ax <= backMax and skip[ax] ~= true and ((not mirrored) or (ax <= iW * 0.5)) then
						local ai = ay * iW + ax + 1;
						if wdist[ai] > cd + 1 then
							wdist[ai] = cd + 1;
							qn = qn + 1;
							qx[qn] = ax;
							qy[qn] = ay;
						end
					end
				end
				ddir = ddir + 1;
			end
		end
	end
	local eligible = {};
	y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			local i = y * iW + x + 1;
			local wd = wdist[i];
			if wd ~= nil and wd >= 1 and wd <= 2 and skip[x] ~= true and ((not mirrored) or (x <= iW * 0.5)) then
				local dPeak = peakDist[i];
				if dPeak ~= nil and dPeak >= 5 then
					local plot = Map.GetPlot(x, y);
					if plot ~= nil and plot:IsWater() == false and plot:GetPlotType() == PlotTypes.PLOT_LAND then
						if plot:GetFeatureType() == FeatureTypes.NO_FEATURE then
							table.insert(eligible, plot);
						end
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	if #eligible < 1 then
		print("Peaks back-coast forest: 0");
		return
	end
	eligible = GetShuffledCopyOfTable(eligible);
	local n = 0;
	local ei = 1;
	while ei <= #eligible do
		local plot = eligible[ei];
		if plot:GetFeatureType() == FeatureTypes.NO_FEATURE then
			if Map.Rand(100, "Peaks Back Coast Seed") < 28 then
				plot:SetFeatureType(FeatureTypes.FEATURE_FOREST, -1);
				n = n + 1;
			end
		end
		ei = ei + 1;
	end
	local growPass = 0;
	while growPass < 2 do
		ei = 1;
		while ei <= #eligible do
			local plot = eligible[ei];
			if plot:GetFeatureType() == FeatureTypes.NO_FEATURE and PeakAdjForest(plot) then
				if Map.Rand(100, "Peaks Back Coast Grow") < 62 then
					plot:SetFeatureType(FeatureTypes.FEATURE_FOREST, -1);
					n = n + 1;
				end
			end
			ei = ei + 1;
		end
		growPass = growPass + 1;
	end
	print("Peaks back-coast forest:", n, "/", #eligible);
end
------------------------------------------------------------------------------
function AddPeaksMeadows()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "peaks" then
		return
	end
	local iW, iH = Map.GetGridSize();
	local skip = FillMireSkip(iW);
	local mirrored = (DEF_MIRRORED == 1);
	local riverSeeds = {};
	local forestSeeds = {};
	local y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			local plot = Map.GetPlot(x, y);
			if PeakMeadowEligible(plot, skip, mirrored, iW) then
				if plot:IsRiver() then
					table.insert(riverSeeds, plot);
				elseif PeakAdjForest(plot) then
					table.insert(forestSeeds, plot);
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	riverSeeds = GetShuffledCopyOfTable(riverSeeds);
	forestSeeds = GetShuffledCopyOfTable(forestSeeds);
	local nMeadows = 5 + Map.Rand(4, "Peaks Meadow Count");
	local nGrass = 0;
	local nDone = 0;
	local mi = 1;
	while nDone < nMeadows and mi <= #riverSeeds do
		local seed = riverSeeds[mi];
		mi = mi + 1;
		if seed:GetTerrainType() == TerrainTypes.TERRAIN_PLAINS then
			nGrass = nGrass + PeakGrowMeadow(seed, 8 + Map.Rand(9, "Peaks Meadow Size"), skip, mirrored, iW);
			nDone = nDone + 1;
		end
	end
	local nForest = 0;
	local fi = 1;
	while nForest < 2 and fi <= #forestSeeds do
		local seed = forestSeeds[fi];
		fi = fi + 1;
		if seed:GetTerrainType() == TerrainTypes.TERRAIN_PLAINS then
			if Map.Rand(100, "Peaks Meadow Forest Seed") < 40 then
				nGrass = nGrass + PeakGrowMeadow(seed, 3 + Map.Rand(4, "Peaks Meadow Forest Size"), skip, mirrored, iW);
				nForest = nForest + 1;
			end
		end
	end
	print("Peaks meadows:", nDone, " forest fringes:", nForest, " grass tiles:", nGrass);
end
------------------------------------------------------------------------------
function CountFeatureNeighbors(plot, featureType)
	local n = 0;
	local d = 0;
	while d < DirectionTypes.NUM_DIRECTION_TYPES do
		local adj = PlotDirNoXWrap(plot:GetX(), plot:GetY(), d);
		if adj ~= nil and adj:GetFeatureType() == featureType then
			n = n + 1;
		end
		d = d + 1;
	end
	return n;
end
------------------------------------------------------------------------------
function PlaceClusteredFeature(remaining, featureType, pct, randName)
	local n = #remaining;
	if n < 1 or pct < 1 then
		return 0, n
	end
	local target = math.floor(n * (pct / 100) + 0.5);
	local placed = 0;
	while placed < target and #remaining > 0 do
		local totalWeight = 0;
		local i = 1;
		while i <= #remaining do
			local neigh = CountFeatureNeighbors(remaining[i], featureType);
			local w = 1;
			if neigh == 1 then
				w = 6;
			elseif neigh >= 2 then
				w = 10;
			end
			totalWeight = totalWeight + w;
			i = i + 1;
		end
		if totalWeight < 1 then
			break
		end
		local roll = Map.Rand(totalWeight, randName);
		i = 1;
		local picked = false;
		while i <= #remaining do
			local neigh = CountFeatureNeighbors(remaining[i], featureType);
			local w = 1;
			if neigh == 1 then
				w = 6;
			elseif neigh >= 2 then
				w = 10;
			end
			if roll < w then
				remaining[i]:SetFeatureType(featureType, -1);
				table.remove(remaining, i);
				placed = placed + 1;
				picked = true;
				break
			end
			roll = roll - w;
			i = i + 1;
		end
		if picked == false then
			remaining[#remaining]:SetFeatureType(featureType, -1);
			table.remove(remaining, #remaining);
			placed = placed + 1;
		end
	end
	return placed, n
end
------------------------------------------------------------------------------
function IsNearAnyStart(x, y, starts, dist)
	local i = 1;
	while i <= #starts do
		if Map.PlotDistance(x, y, starts[i]:GetX(), starts[i]:GetY()) <= dist then
			return true
		end
		i = i + 1;
	end
	return false
end
------------------------------------------------------------------------------
function AddWastelandTundraForests()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "wasteland" then
		return
	end
	local iW, iH = Map.GetGridSize();
	local skip = {};
	local cols = GetSnowWrapColumns(iW);
	local ci = 1;
	while ci <= #cols do
		skip[cols[ci]] = true;
		ci = ci + 1;
	end
	cols = GetSnowWrapTundraColumns(iW);
	ci = 1;
	while ci <= #cols do
		skip[cols[ci]] = true;
		ci = ci + 1;
	end
	local mirrored = (DEF_MIRRORED == 1);
	local plots = {};
	local y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			if skip[x] ~= true and ((not mirrored) or (x <= iW * 0.5)) then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil
					and plot:IsWater() == false
					and plot:GetPlotType() == PlotTypes.PLOT_LAND
					and plot:GetTerrainType() == TerrainTypes.TERRAIN_TUNDRA
					and plot:GetFeatureType() == FeatureTypes.NO_FEATURE then
					table.insert(plots, plot);
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	local placed, n = PlaceClusteredFeature(plots, FeatureTypes.FEATURE_FOREST, 8, "Wasteland Tundra Forest");
	print("Wasteland tundra forests:", placed, "/", n);
end
------------------------------------------------------------------------------
function WastelandMiningLuxFlatTundraToHill()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "wasteland" then
		return
	end
	local mineLux = {};
	local nIds = 0;
	if GameInfo.Improvement_ResourceTypes ~= nil then
		for row in GameInfo.Improvement_ResourceTypes() do
			if row.ImprovementType == "IMPROVEMENT_MINE" then
				local resInfo = GameInfo.Resources[row.ResourceType];
				if resInfo ~= nil and resInfo.ResourceClassType == "RESOURCECLASS_LUXURY" then
					mineLux[resInfo.ID] = true;
					nIds = nIds + 1;
				end
			end
		end
	end
	if nIds < 1 then
		local names = {
			"RESOURCE_GOLD", "RESOURCE_SILVER", "RESOURCE_GEMS", "RESOURCE_COPPER",
			"RESOURCE_JADE", "RESOURCE_LAPIS", "RESOURCE_AMBER", "RESOURCE_OBSIDIAN"
		};
		local i = 1;
		while names[i] ~= nil do
			local id = GameInfoTypes[names[i]];
			if id ~= nil then
				mineLux[id] = true;
			end
			i = i + 1;
		end
	end
	local iW, iH = Map.GetGridSize();
	local mirrored = (DEF_MIRRORED == 1);
	local raised = 0;
	local y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			if (not mirrored) or (x <= iW * 0.5) then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil
					and plot:GetPlotType() == PlotTypes.PLOT_LAND
					and plot:GetTerrainType() == TerrainTypes.TERRAIN_TUNDRA
					and mineLux[plot:GetResourceType(-1)] == true then
					if Map.Rand(100, "Wasteland mine lux hill") < 90 then
						plot:SetPlotType(PlotTypes.PLOT_HILLS, false, false);
						raised = raised + 1;
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	print("Wasteland mining lux flat tundra to hill:", raised);
end
------------------------------------------------------------------------------
function WastelandTundraStartHillForest(asp)
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "wasteland" then
		return
	end
	if asp == nil or asp.startingPlots == nil then
		return
	end
	local ironID = GameInfoTypes["RESOURCE_IRON"];
	local deerID = GameInfoTypes["RESOURCE_DEER"];
	local woodID = GameInfoTypes["RESOURCE_HARDWOOD"];
	local iW, iH = Map.GetGridSize();
	local r = 1;
	while asp.startingPlots[r] ~= nil do
		local sp = asp.startingPlots[r];
		local sx = sp[1];
		local sy = sp[2];
		if not (DEF_MIRRORED == 1 and sx > iW * 0.5) then
			local nTundra = 0;
			local nLush = 0;
			local hillForest = 0;
			local ironHills = {};
			local deerFlats = {};
			local blankHills = {};
			local blankFlats = {};
			local y = 0;
			while y < iH do
				local x = 0;
				while x < iW do
					local d = Map.PlotDistance(sx, sy, x, y);
					if d >= 1 and d <= 2 then
						local plot = Map.GetPlot(x, y);
						if plot ~= nil and plot:IsWater() == false and plot:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN then
							local ter = plot:GetTerrainType();
							if ter == TerrainTypes.TERRAIN_GRASS or ter == TerrainTypes.TERRAIN_PLAINS then
								nLush = nLush + 1;
							elseif ter == TerrainTypes.TERRAIN_TUNDRA then
								nTundra = nTundra + 1;
							end
							local isHill = (plot:GetPlotType() == PlotTypes.PLOT_HILLS);
							local isForest = (plot:GetFeatureType() == FeatureTypes.FEATURE_FOREST);
							if isHill and isForest then
								hillForest = hillForest + 1;
							end
							local res = plot:GetResourceType(-1);
							if isHill and ironID ~= nil and res == ironID and plot:GetNumResource() >= 4 and isForest == false then
								table.insert(ironHills, plot);
							end
							if isHill == false and isForest and deerID ~= nil and res == deerID then
								table.insert(deerFlats, plot);
							end
							if isHill and res == -1 and plot:GetFeatureType() == FeatureTypes.NO_FEATURE then
								table.insert(blankHills, plot);
							end
							if isHill == false and plot:GetPlotType() == PlotTypes.PLOT_LAND and res == -1 and plot:GetFeatureType() == FeatureTypes.NO_FEATURE and ter == TerrainTypes.TERRAIN_TUNDRA then
								table.insert(blankFlats, plot);
							end
						end
					end
					x = x + 1;
				end
				y = y + 1;
			end
			if nTundra >= nLush then
				if #ironHills > 0 and Map.Rand(100, "Wasteland Start Iron Forest") < 55 then
					ironHills = GetShuffledCopyOfTable(ironHills);
					ironHills[1]:SetFeatureType(FeatureTypes.FEATURE_FOREST, -1);
					hillForest = hillForest + 1;
				end
				if hillForest < 1 and #deerFlats > 0 and Map.Rand(100, "Wasteland Start Deer Hill") < 40 then
					deerFlats = GetShuffledCopyOfTable(deerFlats);
					deerFlats[1]:SetPlotType(PlotTypes.PLOT_HILLS, false, false);
					hillForest = hillForest + 1;
				end
				if hillForest < 1 and Map.Rand(100, "Wasteland Start Hardwood") < 18 then
					local target = nil;
					if #blankHills > 0 then
						blankHills = GetShuffledCopyOfTable(blankHills);
						target = blankHills[1];
					elseif #blankFlats > 0 then
						blankFlats = GetShuffledCopyOfTable(blankFlats);
						target = blankFlats[1];
						target:SetPlotType(PlotTypes.PLOT_HILLS, false, false);
					end
					if target ~= nil then
						target:SetFeatureType(FeatureTypes.FEATURE_FOREST, -1);
						if woodID ~= nil then
							target:SetResourceType(woodID, 1);
						end
						hillForest = hillForest + 1;
					end
				end
			end
		end
		r = r + 1;
	end
end
------------------------------------------------------------------------------
function AddWastelandFallout()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "wasteland" then
		return
	end
	local falloutType = FeatureTypes.FEATURE_FALLOUT;
	if falloutType == nil then
		falloutType = GameInfoTypes["FEATURE_FALLOUT"];
	end
	if falloutType == nil then
		print("Wasteland fallout: FEATURE_FALLOUT missing");
		return
	end
	local iW, iH = Map.GetGridSize();
	local skip = {};
	local barrierCol = {};
	local cols = GetSnowWrapColumns(iW);
	local ci = 1;
	while ci <= #cols do
		skip[cols[ci]] = true;
		barrierCol[cols[ci]] = true;
		ci = ci + 1;
	end
	cols = GetSnowWrapTundraColumns(iW);
	ci = 1;
	while ci <= #cols do
		skip[cols[ci]] = true;
		ci = ci + 1;
	end
	local mirrored = (DEF_MIRRORED == 1);
	local starts = {};
	local pi = 0;
	while pi < GameDefines.MAX_MAJOR_CIVS do
		local player = Players[pi];
		if player ~= nil and player:IsAlive() and player:GetStartingPlot() ~= nil then
			table.insert(starts, player:GetStartingPlot());
		end
		pi = pi + 1;
	end
	local barrierPlots = {};
	local nearPlots = {};
	local farPlots = {};
	local y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			if (not mirrored) or (x <= iW * 0.5) then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil
					and plot:IsWater() == false
					and plot:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN
					and plot:GetTerrainType() == TerrainTypes.TERRAIN_TUNDRA
					and plot:GetFeatureType() == FeatureTypes.NO_FEATURE then
					if barrierCol[x] == true then
						table.insert(barrierPlots, plot);
					elseif skip[x] ~= true and IsNearAnyStart(x, y, starts, 3) == false then
						local d = wastelandWaterDist[y * iW + x + 1];
						if d ~= nil and d <= 2 then
							table.insert(nearPlots, plot);
						else
							table.insert(farPlots, plot);
						end
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	local bPlaced, bN = PlaceClusteredFeature(barrierPlots, falloutType, cfg.falloutBarrierPct, "Wasteland Barrier Fallout");
	local nPlaced, nN = PlaceClusteredFeature(nearPlots, falloutType, cfg.falloutPlayableNearPct, "Wasteland Near Fallout");
	local fPlaced, fN = PlaceClusteredFeature(farPlots, falloutType, cfg.falloutPlayableFarPct, "Wasteland Far Fallout");
	print("Wasteland fallout barrier:", bPlaced, "/", bN, " near:", nPlaced, "/", nN, " far:", fPlaced, "/", fN);
end
------------------------------------------------------------------------------
function AddWetlandBarrierFeatures()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "wetland" then
		return
	end
	local iW, iH = Map.GetGridSize();
	local barrierCol = {};
	local cols = GetSnowWrapColumns(iW);
	local ci = 1;
	while ci <= #cols do
		barrierCol[cols[ci]] = true;
		ci = ci + 1;
	end
	local mirrored = (DEF_MIRRORED == 1);
	local marshPlots = {};
	local coverPlots = {};
	local y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			if barrierCol[x] == true and ((not mirrored) or (x <= iW * 0.5)) then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil
					and plot:IsWater() == false
					and plot:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN
					and plot:GetFeatureType() == FeatureTypes.NO_FEATURE
					and plot:GetResourceType(-1) == -1 then
					if plot:GetPlotType() == PlotTypes.PLOT_LAND then
						table.insert(marshPlots, plot);
					end
					table.insert(coverPlots, plot);
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	local mPlaced, mN = PlaceClusteredFeature(marshPlots, FeatureTypes.FEATURE_MARSH, cfg.marshBarrierPct, "Wetland Barrier Marsh");
	local junglePlots = {};
	local i = 1;
	while i <= #coverPlots do
		if coverPlots[i]:GetFeatureType() == FeatureTypes.NO_FEATURE then
			table.insert(junglePlots, coverPlots[i]);
		end
		i = i + 1;
	end
	local jPlaced, jN = PlaceClusteredFeature(junglePlots, FeatureTypes.FEATURE_JUNGLE, cfg.jungleBarrierPct, "Wetland Barrier Jungle");
	local ji = 1;
	while ji <= #coverPlots do
		if coverPlots[ji]:GetFeatureType() == FeatureTypes.FEATURE_JUNGLE then
			coverPlots[ji]:SetTerrainType(TerrainTypes.TERRAIN_PLAINS, false, false);
		end
		ji = ji + 1;
	end
	local forestPlots = {};
	i = 1;
	while i <= #coverPlots do
		if coverPlots[i]:GetFeatureType() == FeatureTypes.NO_FEATURE then
			table.insert(forestPlots, coverPlots[i]);
		end
		i = i + 1;
	end
	local fPlaced, fN = PlaceClusteredFeature(forestPlots, FeatureTypes.FEATURE_FOREST, cfg.forestBarrierPct, "Wetland Barrier Forest");
	print("Wetland barrier marsh:", mPlaced, "/", mN, " jungle:", jPlaced, "/", jN, " forest:", fPlaced, "/", fN);
end
------------------------------------------------------------------------------
function StripBarrierResources()
	local cfg = GetBarrierConfig();
	if cfg == nil then
		return
	end
	local oilID = GameInfoTypes["RESOURCE_OIL"];
	local alumID = GameInfoTypes["RESOURCE_ALUMINUM"];
	local uranID = GameInfoTypes["RESOURCE_URANIUM"];
	local horseID = GameInfoTypes["RESOURCE_HORSE"];
	local ironID = GameInfoTypes["RESOURCE_IRON"];
	local iW, iH = Map.GetGridSize();
	local cols = GetSnowWrapColumns(iW);
	local n = 0;
	local ci = 1;
	while ci <= #cols do
		local x = cols[ci];
		local y = 0;
		while y < iH do
			local plot = Map.GetPlot(x, y);
			if plot ~= nil then
				local res = plot:GetResourceType(-1);
				if res ~= -1 then
					local strip = true;
					if cfg.kind == "peaks" then
						strip = false;
						local info = GameInfo.Resources[res];
						if info ~= nil then
							if info.ResourceClassType == "RESOURCECLASS_BONUS" or info.ResourceClassType == "RESOURCECLASS_LUXURY" then
								strip = true;
							end
						end
						if res == horseID or res == ironID then
							strip = true;
						end
					elseif res == oilID or res == alumID or res == uranID then
						strip = false;
					end
					if strip then
						plot:SetResourceType(-1);
						n = n + 1;
					end
				end
			end
			y = y + 1;
		end
		ci = ci + 1;
	end
	print("Barrier resources stripped:", n);
end
------------------------------------------------------------------------------
function GetWestTundraFrontBands(iW)
	local bands = {};
	local wrapN, centerN = ResolveSnowWrapWidths();
	local mid = math.floor(iW / 2);
	local blocked = {};
	local snow = GetSnowWrapColumns(iW);
	local i = 1;
	while i <= #snow do
		blocked[snow[i]] = true;
		i = i + 1;
	end
	local tundra = GetSnowWrapTundraColumns(iW);
	i = 1;
	while i <= #tundra do
		blocked[tundra[i]] = true;
		i = i + 1;
	end
	if centerN > 0 then
		local tundraX = mid - centerN / 2 - 1;
		local cols = {};
		local c1 = tundraX - 1;
		local c2 = tundraX - 2;
		if c1 ~= nil and blocked[c1] ~= true and c1 >= 0 and c1 < iW then
			table.insert(cols, c1);
		end
		if c2 ~= nil and blocked[c2] ~= true and c2 >= 0 and c2 < iW then
			table.insert(cols, c2);
		end
		if #cols > 0 then
			table.insert(bands, cols);
		end
	end
	if wrapN > 0 then
		local tundraX = wrapN / 2;
		local cols = {};
		local c1 = tundraX + 1;
		local c2 = tundraX + 2;
		if c1 ~= nil and blocked[c1] ~= true and c1 >= 0 and c1 < iW then
			table.insert(cols, c1);
		end
		if c2 ~= nil and blocked[c2] ~= true and c2 >= 0 and c2 < iW then
			table.insert(cols, c2);
		end
		if #cols > 0 then
			table.insert(bands, cols);
		end
	end
	return bands;
end
------------------------------------------------------------------------------
function CollectTundraFrontPlots(cols, iW, iH)
	local plots = {};
	local mirrored = (DEF_MIRRORED == 1);
	local y = 0;
	while y < iH do
		local ci = 1;
		while ci <= #cols do
			local x = cols[ci];
			if x >= 0 and x < iW and ((not mirrored) or (x <= iW * 0.5)) then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil
					and plot:IsWater() == false
					and plot:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN
					and plot:GetResourceType(-1) == -1 then
					table.insert(plots, plot);
				end
			end
			ci = ci + 1;
		end
		y = y + 1;
	end
	return plots;
end
------------------------------------------------------------------------------
function PlaceDesertTundraFrontResources()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind == "peaks" then
		return
	end
	local iW, iH = Map.GetGridSize();
	local bands = GetWestTundraFrontBands(iW);
	if #bands < 1 then
		return
	end
	local mirrored = (DEF_MIRRORED == 1);
	local unusedLux = {};
	local allPlots = {};
	local bi = 1;
	while bi <= #bands do
		local plots = CollectTundraFrontPlots(bands[bi], iW, iH);
		local p = 1;
		while p <= #plots do
			table.insert(allPlots, plots[p]);
			p = p + 1;
		end
		bi = bi + 1;
	end
	if cfg.kind == "desert" then
		local placedLux = {};
		local y = 0;
		while y < iH do
			local x = 0;
			local maxX = iW - 1;
			if mirrored then
				maxX = math.floor(iW / 2);
			end
			while x <= maxX do
				local plot = Map.GetPlot(x, y);
				if plot ~= nil then
					local res = plot:GetResourceType(-1);
					if res ~= nil and res ~= -1 then
						placedLux[res] = true;
					end
				end
				x = x + 1;
			end
			y = y + 1;
		end
		for res in GameInfo.Resources() do
			if res.Happiness ~= nil and res.Happiness > 0 and placedLux[res.ID] ~= true then
				table.insert(unusedLux, res.ID);
			end
		end
		unusedLux = GetShuffledCopyOfTable(unusedLux);
	end
	local nLuxWant = 0;
	local luxPlaced = 0;
	if cfg.kind == "desert" then
		nLuxWant = Map.Rand(3, "Desert Front Unique Lux Count");
		local shuffledPlots = GetShuffledCopyOfTable(allPlots);
		local luxI = 1;
		while luxI <= #unusedLux and luxPlaced < nLuxWant do
			local luxID = unusedLux[luxI];
			local p = 1;
			while p <= #shuffledPlots do
				local plot = shuffledPlots[p];
				if plot:GetResourceType(-1) == -1 and plot:CanHaveResource(luxID) then
					plot:SetResourceType(luxID, 1);
					luxPlaced = luxPlaced + 1;
					break
				end
				p = p + 1;
			end
			luxI = luxI + 1;
		end
	end
	local bonusIDs = {};
	for res in GameInfo.Resources() do
		local class = res.ResourceClassType;
		if class == "RESOURCECLASS_BONUS" or class == "RESOURCECLASS_RUSH" or class == "RESOURCECLASS_MODERN" then
			if res.Type ~= "RESOURCE_FISH" then
				table.insert(bonusIDs, res.ID);
			end
		end
	end
	local ironID = GameInfoTypes["RESOURCE_IRON"];
	local horseID = GameInfoTypes["RESOURCE_HORSE"];
	local oilID = GameInfoTypes["RESOURCE_OIL"];
	local coalID = GameInfoTypes["RESOURCE_COAL"];
	local alumID = GameInfoTypes["RESOURCE_ALUMINUM"];
	local uranID = GameInfoTypes["RESOURCE_URANIUM"];
	local bonusPlaced = 0;
	bi = 1;
	while bi <= #bands do
		local plots = CollectTundraFrontPlots(bands[bi], iW, iH);
		plots = GetShuffledCopyOfTable(plots);
		local nWant = 8 + Map.Rand(5, "Front Bonus Count");
		local placed = 0;
		local p = 1;
		while p <= #plots and placed < nWant do
			local plot = plots[p];
			local nFit = 0;
			local fit = {};
			local k = 1;
			while k <= #bonusIDs do
				if bonusIDs[k] ~= nil and plot:CanHaveResource(bonusIDs[k]) then
					nFit = nFit + 1;
					fit[nFit] = bonusIDs[k];
				end
				k = k + 1;
			end
			if nFit > 0 then
				local pick = fit[Map.Rand(nFit, "Front Bonus Pick") + 1];
				local amt = 1;
				if pick == ironID or pick == horseID or pick == oilID or pick == coalID or pick == alumID or pick == uranID then
					amt = 2;
				end
				plot:SetResourceType(pick, amt);
				placed = placed + 1;
				bonusPlaced = bonusPlaced + 1;
			end
			p = p + 1;
		end
		bi = bi + 1;
	end
	print("Front band resources: lux=", luxPlaced, "/", nLuxWant, " bonus=", bonusPlaced, " bands=", #bands);
end
------------------------------------------------------------------------------
function FrostySnowResourceAllowed(res)
	if res == nil or res == -1 then
		return true
	end
	local usage = Game.GetResourceUsageType(res);
	if usage == ResourceUsageTypes.RESOURCEUSAGE_STRATEGIC then
		return true
	end
	if usage == ResourceUsageTypes.RESOURCEUSAGE_BONUS then
		if res == GameInfoTypes["RESOURCE_SHEEP"] then
			return false
		end
		return true
	end
	local ok = {};
	ok[GameInfoTypes["RESOURCE_FUR"] or -2] = true;
	ok[GameInfoTypes["RESOURCE_SILVER"] or -2] = true;
	ok[GameInfoTypes["RESOURCE_GOLD"] or -2] = true;
	ok[GameInfoTypes["RESOURCE_COPPER"] or -2] = true;
	ok[GameInfoTypes["RESOURCE_GEMS"] or -2] = true;
	ok[GameInfoTypes["RESOURCE_JADE"] or -2] = true;
	ok[GameInfoTypes["RESOURCE_LAPIS"] or -2] = true;
	ok[GameInfoTypes["RESOURCE_AMBER"] or -2] = true;
	ok[GameInfoTypes["RESOURCE_SALT"] or -2] = true;
	ok[GameInfoTypes["RESOURCE_MARBLE"] or -2] = true;
	if ok[res] then
		return true
	end
	return false
end
------------------------------------------------------------------------------
function PlaceFrostySnowResources()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "frosty" then
		return
	end
	local furID = GameInfoTypes["RESOURCE_FUR"];
	local ironID = GameInfoTypes["RESOURCE_IRON"];
	local stoneID = GameInfoTypes["RESOURCE_STONE"];
	local iW, iH = Map.GetGridSize();
	local skip = FillMireSkip(iW);
	local mirrored = (DEF_MIRRORED == 1);
	local snowForest = {};
	local snowHill = {};
	local snowFlat = {};
	local furToMove = {};
	local snowFurPlots = {};
	local nFurSnow = 0;
	local nLuxStrip = 0;
	local y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			if skip[x] ~= true and ((not mirrored) or (x <= iW * 0.5)) then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil and plot:IsWater() == false and plot:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN then
					local t = plot:GetTerrainType();
					local res = plot:GetResourceType(-1);
					if t == TerrainTypes.TERRAIN_SNOW then
						if FrostySnowResourceAllowed(res) == false then
							plot:SetResourceType(-1);
							nLuxStrip = nLuxStrip + 1;
							res = -1;
						end
						if furID ~= nil and res == furID then
							nFurSnow = nFurSnow + 1;
							table.insert(snowFurPlots, plot);
						elseif res == -1 then
							local feat = plot:GetFeatureType();
							local pt = plot:GetPlotType();
							if feat == FeatureTypes.FEATURE_FOREST then
								table.insert(snowForest, plot);
							elseif pt == PlotTypes.PLOT_HILLS then
								table.insert(snowHill, plot);
							elseif feat == FeatureTypes.NO_FEATURE then
								table.insert(snowFlat, plot);
							end
						end
					elseif furID ~= nil and res == furID then
						table.insert(furToMove, plot);
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	snowForest = GetShuffledCopyOfTable(snowForest);
	snowHill = GetShuffledCopyOfTable(snowHill);
	snowFlat = GetShuffledCopyOfTable(snowFlat);
	snowFurPlots = GetShuffledCopyOfTable(snowFurPlots);
	local wantFur = 4;
	local mi = 1;
	while nFurSnow < wantFur and mi <= #furToMove do
		if #snowForest < 1 then
			break
		end
		furToMove[mi]:SetResourceType(-1);
		snowForest[1]:SetResourceType(furID, 1);
		table.insert(snowFurPlots, snowForest[1]);
		table.remove(snowForest, 1);
		nFurSnow = nFurSnow + 1;
		mi = mi + 1;
	end
	local fi = 1;
	if furID ~= nil then
		while nFurSnow < wantFur and fi <= #snowForest do
			snowForest[fi]:SetResourceType(furID, 1);
			table.insert(snowFurPlots, snowForest[fi]);
			nFurSnow = nFurSnow + 1;
			fi = fi + 1;
		end
	end
	while nFurSnow > wantFur and #snowFurPlots > 0 do
		local drop = snowFurPlots[#snowFurPlots];
		drop:SetResourceType(-1);
		table.remove(snowFurPlots, #snowFurPlots);
		nFurSnow = nFurSnow - 1;
		if drop:GetFeatureType() == FeatureTypes.FEATURE_FOREST then
			table.insert(snowForest, drop);
		end
	end
	local nIron = 0;
	local wantIron = 5;
	if ironID ~= nil then
		local hi = 1;
		while nIron < wantIron and hi <= #snowHill do
			snowHill[hi]:SetResourceType(ironID, 2);
			nIron = nIron + 1;
			hi = hi + 1;
		end
		while nIron < wantIron and fi <= #snowForest do
			if snowForest[fi]:GetResourceType(-1) == -1 then
				snowForest[fi]:SetPlotType(PlotTypes.PLOT_HILLS, false, false);
				snowForest[fi]:SetResourceType(ironID, 2);
				nIron = nIron + 1;
			end
			fi = fi + 1;
		end
	end
	local nStone = 0;
	local wantStone = 6;
	if stoneID ~= nil then
		local si = 1;
		while nStone < wantStone and si <= #snowFlat do
			snowFlat[si]:SetResourceType(stoneID, 1);
			nStone = nStone + 1;
			si = si + 1;
		end
	end
	print("Frosty snow fur:", nFurSnow, " iron:", nIron, " stone:", nStone, " misfit stripped:", nLuxStrip);
end
------------------------------------------------------------------------------
function FrostySnowLuxNeedsPad(res)
	if res == nil or res == -1 then
		return false
	end
	if res == GameInfoTypes["RESOURCE_FUR"] then
		return false
	end
	return Game.GetResourceUsageType(res) == ResourceUsageTypes.RESOURCEUSAGE_LUXURY;
end
------------------------------------------------------------------------------
function FrostyCountForestFishInRadius(sx, sy, iW, iH, fishID)
	local n = 0;
	local y = sy - 3;
	if y < 0 then
		y = 0;
	end
	local yMax = sy + 3;
	if yMax > iH - 1 then
		yMax = iH - 1;
	end
	while y <= yMax do
		local x = sx - 3;
		if x < 0 then
			x = 0;
		end
		local xMax = sx + 3;
		if xMax > iW - 1 then
			xMax = iW - 1;
		end
		while x <= xMax do
			local dx = x - sx;
			if dx < 0 then
				dx = 0 - dx;
			end
			if dx <= 3 and Map.PlotDistance(sx, sy, x, y) <= 3 then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil then
					if plot:GetFeatureType() == FeatureTypes.FEATURE_FOREST then
						n = n + 1;
					elseif fishID ~= nil and plot:GetResourceType(-1) == fishID then
						n = n + 1;
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	return n;
end
------------------------------------------------------------------------------
function FrostyPadSnowLuxuryYields()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "frosty" then
		return
	end
	local fishID = GameInfoTypes["RESOURCE_FISH"];
	local iW, iH = Map.GetGridSize();
	local skip = FillMireSkip(iW);
	local mirrored = (DEF_MIRRORED == 1);
	local maxX = iW - 1;
	if mirrored then
		maxX = math.floor(iW * 0.5);
	end
	local nPad = 0;
	local nLux = 0;
	local y = 0;
	while y < iH do
		local x = 0;
		while x <= maxX do
			if skip[x] ~= true then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil and plot:IsWater() == false and plot:GetTerrainType() == TerrainTypes.TERRAIN_SNOW then
					if FrostySnowLuxNeedsPad(plot:GetResourceType(-1)) then
						nLux = nLux + 1;
						local have = FrostyCountForestFishInRadius(x, y, iW, iH, fishID);
						if have < 5 then
							local forestCands = {};
							local fishCands = {};
							local ry = y - 3;
							if ry < 0 then
								ry = 0;
							end
							local ryMax = y + 3;
							if ryMax > iH - 1 then
								ryMax = iH - 1;
							end
							while ry <= ryMax do
								local rx = x - 3;
								if rx < 0 then
									rx = 0;
								end
								local rxMax = x + 3;
								if rxMax > iW - 1 then
									rxMax = iW - 1;
								end
								while rx <= rxMax do
									local dx = rx - x;
									if dx < 0 then
										dx = 0 - dx;
									end
									if dx <= 3 and Map.PlotDistance(x, y, rx, ry) <= 3 then
										local p = Map.GetPlot(rx, ry);
										if p ~= nil and (rx ~= x or ry ~= y) and skip[rx] ~= true then
											if p:IsWater() then
												if fishID ~= nil and IsFrostySnowAreaWater(p) and WaterAllowedAtX(rx) and p:GetFeatureType() ~= FeatureTypes.FEATURE_ICE and p:GetResourceType(-1) == -1 then
													if p:CanHaveResource(fishID) then
														table.insert(fishCands, p);
													end
												end
											elseif p:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN and p:GetFeatureType() == FeatureTypes.NO_FEATURE then
												table.insert(forestCands, p);
											end
										end
									end
									rx = rx + 1;
								end
								ry = ry + 1;
							end
							forestCands = GetShuffledCopyOfTable(forestCands);
							fishCands = GetShuffledCopyOfTable(fishCands);
							local need = 5 - have;
							local i = 1;
							while need > 0 and i <= #forestCands do
								forestCands[i]:SetFeatureType(FeatureTypes.FEATURE_FOREST, -1);
								need = need - 1;
								nPad = nPad + 1;
								i = i + 1;
							end
							i = 1;
							while need > 0 and i <= #fishCands do
								fishCands[i]:SetResourceType(fishID, 1);
								need = need - 1;
								nPad = nPad + 1;
								i = i + 1;
							end
						end
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	print("Frosty snow lux pad: lux=", nLux, " added=", nPad);
end
------------------------------------------------------------------------------
function PlaceFrostySnowFish()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "frosty" then
		return
	end
	local fishID = GameInfoTypes["RESOURCE_FISH"];
	if fishID == nil then
		return
	end
	local iW, iH = Map.GetGridSize();
	local maxX = iW - 1;
	if DEF_MIRRORED == 1 then
		maxX = math.floor(iW * 0.5);
	end
	local water = {};
	local nHave = 0;
	local y = 0;
	while y < iH do
		local x = 0;
		while x <= maxX do
			local plot = Map.GetPlot(x, y);
			if plot ~= nil and IsFrostySnowAreaWater(plot) and WaterAllowedAtX(x) then
				if plot:GetFeatureType() ~= FeatureTypes.FEATURE_ICE then
					local res = plot:GetResourceType(-1);
					if res == fishID then
						nHave = nHave + 1;
					elseif res == -1 and plot:CanHaveResource(fishID) then
						table.insert(water, plot);
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	local nTiles = nHave + #water;
	local want = math.floor(nTiles * 0.30 + 0.5);
	water = GetShuffledCopyOfTable(water);
	local placed = 0;
	local i = 1;
	while nHave < want and i <= #water do
		water[i]:SetResourceType(fishID, 1);
		nHave = nHave + 1;
		placed = placed + 1;
		i = i + 1;
	end
	print("Frosty snow fish:", nHave, "/", nTiles, " added", placed);
end
------------------------------------------------------------------------------
function PlaceMurkTundraSheepStone()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "wetland" then
		return
	end
	local sheepID = GameInfoTypes["RESOURCE_SHEEP"];
	local stoneID = GameInfoTypes["RESOURCE_STONE"];
	local horseID = GameInfoTypes["RESOURCE_HORSE"];
	if sheepID == nil or stoneID == nil then
		return
	end
	local iW, iH = Map.GetGridSize();
	local skip = FillMireSkip(iW);
	local mirrored = (DEF_MIRRORED == 1);
	local hillPlots = {};
	local flatPlots = {};
	local y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			local i = y * iW + x + 1;
			if mireBand[i] == 1 and skip[x] ~= true and ((not mirrored) or (x <= iW * 0.5)) then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil
					and plot:IsWater() == false
					and plot:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN
					and plot:GetResourceType(-1) == -1
					and plot:GetFeatureType() == FeatureTypes.NO_FEATURE
					and plot:GetTerrainType() ~= TerrainTypes.TERRAIN_SNOW then
					if plot:GetPlotType() == PlotTypes.PLOT_HILLS then
						table.insert(hillPlots, plot);
					elseif plot:GetPlotType() == PlotTypes.PLOT_LAND then
						table.insert(flatPlots, plot);
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	hillPlots = GetShuffledCopyOfTable(hillPlots);
	flatPlots = GetShuffledCopyOfTable(flatPlots);
	local horseN = 0;
	if horseID ~= nil then
		local nHorse = math.floor(#flatPlots * 0.04 + 0.5);
		if nHorse < 2 then
			nHorse = 2;
		end
		if nHorse > 5 then
			nHorse = 5;
		end
		local hp = 1;
		while horseN < nHorse and hp <= #flatPlots do
			local plot = flatPlots[hp];
			if plot:GetResourceType(-1) == -1 and plot:GetPlotType() == PlotTypes.PLOT_LAND then
				plot:SetResourceType(horseID, 2);
				horseN = horseN + 1;
			end
			hp = hp + 1;
		end
	end
	local nSheep = math.floor(#hillPlots * 0.22 + 0.5);
	if nSheep < 2 then
		nSheep = 2;
	end
	local sheepN = 0;
	local hi = 1;
	while sheepN < nSheep and hi <= #hillPlots do
		if hillPlots[hi]:CanHaveResource(sheepID) then
			hillPlots[hi]:SetResourceType(sheepID, 1);
			sheepN = sheepN + 1;
		end
		hi = hi + 1;
	end
	local fi = 1;
	while sheepN < nSheep and fi <= #flatPlots do
		local plot = flatPlots[fi];
		if plot:GetResourceType(-1) == -1 then
			plot:SetPlotType(PlotTypes.PLOT_HILLS, false, false);
			if plot:CanHaveResource(sheepID) then
				plot:SetResourceType(sheepID, 1);
				sheepN = sheepN + 1;
			else
				plot:SetPlotType(PlotTypes.PLOT_LAND, false, false);
			end
		end
		fi = fi + 1;
	end
	local nStone = math.floor(#flatPlots * 0.05 + 0.5);
	local stoneN = 0;
	fi = 1;
	while stoneN < nStone and fi <= #flatPlots do
		local plot = flatPlots[fi];
		if plot:GetResourceType(-1) == -1 and plot:GetPlotType() == PlotTypes.PLOT_LAND and plot:CanHaveResource(stoneID) then
			plot:SetResourceType(stoneID, 1);
			stoneN = stoneN + 1;
		end
		fi = fi + 1;
	end
	print("Murk tundra extras sheep:", sheepN, " stone:", stoneN, " horse:", horseN);
end
------------------------------------------------------------------------------
function PlaceMurkWheatAndMarshStone()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "wetland" then
		return
	end
	local wheatID = GameInfoTypes["RESOURCE_WHEAT"];
	local stoneID = GameInfoTypes["RESOURCE_STONE"];
	local iW, iH = Map.GetGridSize();
	local skip = FillMireSkip(iW);
	local mirrored = (DEF_MIRRORED == 1);
	local nWheat = 0;
	local nStone = 0;
	local y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			if skip[x] ~= true and ((not mirrored) or (x <= iW * 0.5)) then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil
					and plot:IsWater() == false
					and plot:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN
					and plot:GetResourceType(-1) == -1 then
					if stoneID ~= nil and plot:GetFeatureType() == FeatureTypes.FEATURE_MARSH then
						if Map.Rand(100, "Murk Marsh Stone") < 12 then
							plot:SetResourceType(stoneID, 1);
							nStone = nStone + 1;
						end
					elseif wheatID ~= nil
						and plot:GetPlotType() == PlotTypes.PLOT_LAND
						and plot:GetTerrainType() == TerrainTypes.TERRAIN_TUNDRA
						and plot:IsRiver()
						and plot:GetFeatureType() ~= FeatureTypes.FEATURE_MARSH then
						if Map.Rand(100, "Murk Tundra Wheat") < 8 then
							plot:SetResourceType(wheatID, 1);
							nWheat = nWheat + 1;
						end
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	print("Murk tundra wheat:", nWheat, " marsh stone:", nStone);
end
------------------------------------------------------------------------------
function PlaceMurkSnowStoneIron()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "wetland" then
		return
	end
	local stoneID = GameInfoTypes["RESOURCE_STONE"];
	local ironID = GameInfoTypes["RESOURCE_IRON"];
	if stoneID == nil and ironID == nil then
		return
	end
	local iW, iH = Map.GetGridSize();
	local skip = FillMireSkip(iW);
	local mirrored = (DEF_MIRRORED == 1);
	local nStone = 0;
	local nIron = 0;
	local y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			if skip[x] ~= true and ((not mirrored) or (x <= iW * 0.5)) then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil
					and plot:IsWater() == false
					and plot:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN
					and plot:GetTerrainType() == TerrainTypes.TERRAIN_SNOW
					and plot:GetResourceType(-1) == -1 then
					local pt = Map.Rand(100, "Murk Snow Res");
					if stoneID ~= nil and pt < 5 then
						plot:SetResourceType(stoneID, 1);
						nStone = nStone + 1;
					elseif ironID ~= nil and pt < 9 then
						plot:SetResourceType(ironID, 2);
						nIron = nIron + 1;
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	print("Murk snow stone:", nStone, " iron:", nIron);
end
------------------------------------------------------------------------------
function PlacePeaksPlainsCattle()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "peaks" then
		return
	end
	local cowID = GameInfoTypes["RESOURCE_COW"];
	local horseID = GameInfoTypes["RESOURCE_HORSE"];
	if cowID == nil then
		return
	end
	local iW, iH = Map.GetGridSize();
	local skip = FillMireSkip(iW);
	local snowCols = GetSnowWrapColumns(iW);
	local sci = 1;
	while sci <= #snowCols do
		skip[snowCols[sci]] = true;
		sci = sci + 1;
	end
	local mirrored = (DEF_MIRRORED == 1);
	local nHorse = 0;
	local plains = {};
	local y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			if skip[x] ~= true and ((not mirrored) or (x <= iW * 0.5)) then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil and plot:IsWater() == false then
					if horseID ~= nil and plot:GetResourceType(-1) == horseID then
						nHorse = nHorse + 1;
					end
					if plot:GetPlotType() == PlotTypes.PLOT_LAND
						and plot:GetTerrainType() == TerrainTypes.TERRAIN_PLAINS
						and plot:GetFeatureType() == FeatureTypes.NO_FEATURE
						and plot:GetResourceType(-1) == -1 then
						table.insert(plains, plot);
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	local nWant = math.floor(nHorse * 0.15 / 0.85 + 0.5);
	if nWant < 1 or #plains < 1 then
		print("Peaks plains cattle:", 0, " horses:", nHorse);
		return
	end
	plains = GetShuffledCopyOfTable(plains);
	local n = 0;
	local i = 1;
	while n < nWant and i <= #plains do
		if plains[i]:GetResourceType(-1) == -1 then
			plains[i]:SetResourceType(cowID, 1);
			n = n + 1;
		end
		i = i + 1;
	end
	print("Peaks plains cattle:", n, "/", nWant, " horses:", nHorse);
end
------------------------------------------------------------------------------
function PlaceWastelandTundraWheatSheep()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "wasteland" then
		return
	end
	local wheatID = GameInfoTypes["RESOURCE_WHEAT"];
	local sheepID = GameInfoTypes["RESOURCE_SHEEP"];
	local iW, iH = Map.GetGridSize();
	local skip = {};
	local cols = GetSnowWrapColumns(iW);
	local ci = 1;
	while ci <= #cols do
		skip[cols[ci]] = true;
		ci = ci + 1;
	end
	cols = GetSnowWrapTundraColumns(iW);
	ci = 1;
	while ci <= #cols do
		skip[cols[ci]] = true;
		ci = ci + 1;
	end
	local mirrored = (DEF_MIRRORED == 1);
	local nWheat = 0;
	local nSheep = 0;
	local y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			if skip[x] ~= true and ((not mirrored) or (x <= iW * 0.5)) then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil
					and plot:IsWater() == false
					and plot:GetPlotType() == PlotTypes.PLOT_LAND
					and plot:GetTerrainType() == TerrainTypes.TERRAIN_TUNDRA
					and plot:GetResourceType(-1) == -1 then
					local placed = false;
					if wheatID ~= nil and plot:IsRiver() then
						if Map.Rand(100, "Wasteland Tundra Wheat") < 10 then
							plot:SetResourceType(wheatID, 1);
							nWheat = nWheat + 1;
							placed = true;
						end
					end
					if placed == false and sheepID ~= nil then
						if Map.Rand(100, "Wasteland Tundra Sheep") < 4 then
							plot:SetResourceType(sheepID, 1);
							nSheep = nSheep + 1;
						end
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	print("Wasteland tundra wheat:", nWheat, " sheep:", nSheep);
end
------------------------------------------------------------------------------
function PlaceDesertMainlandResourceBoost()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "desert" then
		return
	end
	local ids = {
		GameInfoTypes["RESOURCE_BANANA"],
		GameInfoTypes["RESOURCE_WHEAT"],
		GameInfoTypes["RESOURCE_COW"],
		GameInfoTypes["RESOURCE_SHEEP"],
		GameInfoTypes["RESOURCE_DEER"],
		GameInfoTypes["RESOURCE_STONE"],
		GameInfoTypes["RESOURCE_HORSE"],
		GameInfoTypes["RESOURCE_IRON"],
		GameInfoTypes["RESOURCE_INCENSE"],
		GameInfoTypes["RESOURCE_OIL"],
	};
	local iW, iH = Map.GetGridSize();
	local skip = {};
	local cols = GetSnowWrapColumns(iW);
	local ci = 1;
	while ci <= #cols do
		skip[cols[ci]] = true;
		ci = ci + 1;
	end
	cols = GetSnowWrapTundraColumns(iW);
	ci = 1;
	while ci <= #cols do
		skip[cols[ci]] = true;
		ci = ci + 1;
	end
	local mirrored = (DEF_MIRRORED == 1);
	local eligible = {};
	local y = 0;
	while y < iH do
		local x = 0;
		while x < iW do
			if skip[x] ~= true and ((not mirrored) or (x <= iW * 0.5)) then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil
					and plot:IsWater() == false
					and plot:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN
					and plot:GetResourceType(-1) == -1 then
					table.insert(eligible, plot);
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	local shuffled = GetShuffledCopyOfTable(eligible);
	local n = #shuffled;
	local target = math.floor(n * 0.09 + 0.5);
	local placed = 0;
	local i = 1;
	local ironID = GameInfoTypes["RESOURCE_IRON"];
	local horseID = GameInfoTypes["RESOURCE_HORSE"];
	local oilID = GameInfoTypes["RESOURCE_OIL"];
	while i <= n and placed < target do
		local plot = shuffled[i];
		local nFit = 0;
		local fit = {};
		local k = 1;
		while k <= #ids do
			if ids[k] ~= nil and plot:CanHaveResource(ids[k]) then
				nFit = nFit + 1;
				fit[nFit] = ids[k];
			end
			k = k + 1;
		end
		if nFit > 0 then
			local pick = fit[Map.Rand(nFit, "Desert Resource Boost") + 1];
			local amt = 1;
			if pick == ironID or pick == horseID or pick == oilID then
				amt = 2;
			end
			plot:SetResourceType(pick, amt);
			placed = placed + 1;
		end
		i = i + 1;
	end
	print("Desert mainland resource boost:", placed, "/", n);
end
------------------------------------------------------------------------------
function FixNorthUniqueLuxuries()
	local iW, iH = Map.GetGridSize();
	local maxX = iW - 1;
	if DEF_MIRRORED == 1 then
		maxX = math.floor(iW * 0.5);
	end
	local northY = iH - 5;
	if northY < 0 then
		northY = 0;
	end
	local function isLux(res)
		if res == nil or res == -1 then
			return false
		end
		return Game.GetResourceUsageType(res) == ResourceUsageTypes.RESOURCEUSAGE_LUXURY;
	end
	local function gather()
		local counts = {};
		local plots = {};
		local y = 0;
		while y < iH do
			local x = 0;
			while x <= maxX do
				local plot = Map.GetPlot(x, y);
				if plot ~= nil then
					local res = plot:GetResourceType(-1);
					if isLux(res) then
						if counts[res] == nil then
							counts[res] = 0;
							plots[res] = {};
						end
						counts[res] = counts[res] + 1;
						table.insert(plots[res], plot);
					end
				end
				x = x + 1;
			end
			y = y + 1;
		end
		return counts, plots;
	end
	local nFix = 0;
	local y = northY;
	while y < iH do
		local x = 0;
		while x <= maxX do
			local plot = Map.GetPlot(x, y);
			if plot ~= nil then
				local u = plot:GetResourceType(-1);
				if isLux(u) then
					local counts, plots = gather();
					if counts[u] == 1 then
						local uWater = plot:IsWater();
						local done = false;
						local resID, list;
						for resID, list in pairs(plots) do
							if done == false and resID ~= u and counts[resID] ~= nil and counts[resID] >= 2 then
								local pi = 1;
								while pi <= #list do
									local p = list[pi];
									if p:GetY() < northY and p:IsWater() == uWater and p:CanHaveResource(u) then
										p:SetResourceType(u, 1);
										done = true;
										break
									end
									pi = pi + 1;
								end
							end
						end
						if done == false then
							for resID, list in pairs(plots) do
								if done == false and resID ~= u and counts[resID] ~= nil and counts[resID] >= 1 then
									local sameDomain = false;
									local pi = 1;
									while pi <= #list do
										if list[pi]:IsWater() == uWater then
											sameDomain = true;
											break
										end
										pi = pi + 1;
									end
									if sameDomain and plot:CanHaveResource(resID) then
										plot:SetResourceType(resID, 1);
										done = true;
									end
								end
							end
						end
						if done then
							nFix = nFix + 1;
						end
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	print("North unique lux fixes:", nFix);
end
------------------------------------------------------------------------------
function getMirroredPlot(plot)
	local iW, iH = Map.GetGridSize();
	local x = iW - plot:GetX() - 1;
	local y = iH - plot:GetY() - 1;
	local mirrorPlot = Map.GetPlot(x, y);
	return mirrorPlot;
end
------------------------------------------------------------------------------
function isValidPlayer(pPlayer)
	return  pPlayer ~= nil and pPlayer:GetStartingPlot() ~= nil and pPlayer:IsAlive();
end
------------------------------------------------------------------------------
function StartPlotSystem()
	WeeveeDbg("StartPlotSystem");
	local res = DEF_RESOURCES;
	if res == 9 then
		res = 1 + Map.Rand(3, "Random Resources Option - Lua");
	end

	WeeveeDbg("Create start db");
	local start_plot_database = AssignStartingPlots.Create()
	WeeveeDbg("GenerateRegions");
	start_plot_database:GenerateRegions()
	WeeveeDbg("SetDivide");
	SetDivide()
	WeeveeDbg("ChooseLocations");
	start_plot_database:ChooseLocations()
	WeeveeDbg("ChooseLocations done");
	PeakEnsureStartHills(start_plot_database);
	WeeveeDbgCall("FrostyAdjustStarts", FrostyAdjustStarts, start_plot_database);
	WeeveeDbgCall("ShoresFixStarts", ShoresFixStarts, start_plot_database);
	ClampAspStartsOffEdges(start_plot_database);
	WeeveeDbg("BalanceAndAssign");
	start_plot_database:BalanceAndAssign()
	WeeveeDbg("BalanceAndAssign done");

	--print("Placing Natural Wonders.");
	--start_plot_database:PlaceNaturalWonders()

	print("Placing Natural Wonders.");
	local wonders = DEF_NATURAL_WONDERS
	if wonders == 16 then
		wonders = 2 + Map.Rand(4, "Number of Wonders 2-5 - Lua");
	elseif wonders == 14 then
		wonders = Map.Rand(13, "Number of Wonders To Spawn - Lua");
	else
		wonders = wonders - 1;
	end

	print("########## Wonders ##########");
	print("Natural Wonders To Place: ", wonders);

	local wonderargs = {
		wonderamt = wonders,
	};

	WeeveeDbg("PlaceNaturalWonders");
	start_plot_database:PlaceNaturalWonders(wonderargs)
	WeeveeDbg("PlaceResources");
	AddWastelandWaterLayout();
	FixWastelandFloodPlains();
	AddWastelandTundraForests();
	start_plot_database:PlaceResourcesAndCityStates();
	WeeveeDbg("PlaceResources done");
	MaybePlaceStartTileResource(start_plot_database);

	PlaceDesertTundraFrontResources();
	PlaceDesertMainlandResourceBoost();
	PlaceMurkTundraSheepStone();
	PlaceMurkWheatAndMarshStone();
	PlaceMurkSnowStoneIron();
	PlacePeaksPlainsCattle();
	PlaceWastelandTundraWheatSheep();
	WeeveeDbgCall("PlaceFrostySnowResources", PlaceFrostySnowResources);
	StripBarrierResources();
	WastelandMiningLuxFlatTundraToHill();
	start_plot_database:AddForestToResource();
	WastelandTundraStartHillForest(start_plot_database);
	AddSnowForests();
	AddBarrierOases();
	AddWastelandFallout();
	AddWetlandBarrierFeatures();
	
	if IsOldSnow() or IsSnowBarrier() then
		local iW, iH = Map.GetGridSize()
		local snowCols = GetSnowWrapColumns(iW);
		for _, x in ipairs(snowCols) do
			for y = 0, iH - 1 do
				local plot = Map.GetPlot(x, y)
				if plot ~= nil then
					plot:SetWOfRiver(false,FlowDirectionTypes.NO_FLOWDIRECTION)
					plot:SetNWOfRiver(false,FlowDirectionTypes.NO_FLOWDIRECTION)
					plot:SetNEOfRiver(false,FlowDirectionTypes.NO_FLOWDIRECTION)
				end
			end
		end
	end
	CullShortRivers();
	PurgeNearStartLakeFish();
	WeeveeDbgCall("PlaceFrostySnowFish", PlaceFrostySnowFish);
	WeeveeDbgCall("CapSeaResources", CapSeaResources);
	WeeveeDbgCall("FrostyPadSnowLuxuryYields", FrostyPadSnowLuxuryYields);
	ForceWastelandCoastalLuxuries(start_plot_database);
	FixNorthUniqueLuxuries();
	WeeveeDbgCall("ShoresSweepFarLuxuries", ShoresSweepFarLuxuries);
	WeeveeDbgCall("ShoresBoostIslandResources", ShoresBoostIslandResources);
	WeeveeDbgCall("ShoresPlantIslets", ShoresPlantIslets);
	WeeveeDbg("before mirror");
	if DEF_MIRRORED == 1 then
	------------------------------------------------------------------------------
	----------------------- INCLUDE getMirroredPlot()-----------------------------
	----------------- Copyright 2010  (c)  Leszek Deska --------------------------
	------------------------------------------------------------------------------
	-- mirrorize plot types, terrain, resource, natural wonders, ruins (ruins doesn't work)
	local iW, iH = Map.GetGridSize()
	print("iW/iH=",iW, iH)
	for x = 0, iW * 0.5 do
		for y = 0, iH - 1 do
			if( iW-x-y%2 ~= x ) then
				print("x/y=",x,y);
				local plot = Map.GetPlot(x, y);
				local mirrorPlot = getMirroredPlot(plot);
				local plotType = plot:GetPlotType();
				local terrainType = plot:GetTerrainType();
				local featureType = plot:GetFeatureType();
				local improvementType = plot:GetImprovementType();
				local resourceType = plot:GetResourceType(-1)
				mirrorPlot:SetPlotType(plotType,false,false)
				mirrorPlot:SetTerrainType(terrainType,false,false)
				mirrorPlot:SetFeatureType(featureType)
				mirrorPlot:SetResourceType(resourceType,plot:GetNumResource())
				mirrorPlot:SetImprovementType(improvementType)
			end
		end
	end
	-- rivers
	-- mirrorize rivers
	--rivers
	for x = math.floor(iW / 2)+1, iW - 1 do
		for y = 0, iH - 1 do
			local plot = Map.GetPlot(x, y)
			plot:SetWOfRiver(false,FlowDirectionTypes.NO_FLOWDIRECTION)
			plot:SetNWOfRiver(false,FlowDirectionTypes.NO_FLOWDIRECTION)
			plot:SetNEOfRiver(false,FlowDirectionTypes.NO_FLOWDIRECTION)
		end
	end
	for y = 0, iH - 1 do
		for x = 0, iW * 0.5 do
		    if ( x < (iW/2 + 1) ) then
            	local plot = Map.GetPlot(x, y);
				if ( plot:IsWOfRiver() ) then
					local mirrorPlot = getMirroredPlot(plot);
					mirrorPlot = PlotDirNoXWrap(mirrorPlot:GetX(), mirrorPlot:GetY(), DirectionTypes.DIRECTION_WEST);
					if mirrorPlot ~= nil then
						local dir = FlowDirectionTypes.FLOWDIRECTION_NORTH;
						if( plot:GetRiverEFlowDirection() == FlowDirectionTypes.FLOWDIRECTION_NORTH ) then
							dir = FlowDirectionTypes.FLOWDIRECTION_SOUTH;
						end
						mirrorPlot:SetWOfRiver(true, dir);
					end
				end
				if ( plot:IsNWOfRiver() ) then
					local mirrorPlot = getMirroredPlot(plot);
					mirrorPlot = PlotDirNoXWrap(mirrorPlot:GetX(), mirrorPlot:GetY(), DirectionTypes.DIRECTION_NORTHWEST);
					if mirrorPlot ~= nil then
						local dir = FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST;
						if( plot:GetRiverSEFlowDirection() == FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST) then
							dir = FlowDirectionTypes.FLOWDIRECTION_NORTHEAST;
						end;
						mirrorPlot:SetNWOfRiver(true, dir);
					end
				end
				if ( plot:IsNEOfRiver() ) then
					local mirrorPlot = getMirroredPlot(plot);
					mirrorPlot = PlotDirNoXWrap(mirrorPlot:GetX(), mirrorPlot:GetY(), DirectionTypes.DIRECTION_NORTHEAST);
					if mirrorPlot ~= nil then
						local dir = FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST;
						if( plot:GetRiverSWFlowDirection() == FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST) then
							dir = FlowDirectionTypes.FLOWDIRECTION_NORTHWEST;
						end;
						mirrorPlot:SetNEOfRiver(true, dir);
					end
				end
			end
		end
	end
	-- mirrorize starting positions
	local playerStartPlot;
	local searchMode = 0;
	for i = 0, GameDefines.MAX_MAJOR_CIVS + GameDefines.MAX_MINOR_CIVS - 1 do
		local player = Players[i];
		if (isValidPlayer(player)) then
			if player:IsEverAlive() then
				if( searchMode == 0 ) then
					searchMode = 1;
					player = Players[i];
					playerStartPlot = player:GetStartingPlot();
				else
					searchMode = 0;
					player = Players[i];
					player:SetStartingPlot(getMirroredPlot(playerStartPlot));
				end
			end
		end
	end
		Map:RecalculateAreas();
		Game.SetOption(1, true);
	
	end
	WeeveeDbgCall("FrostyFixSnowStarts", FrostyFixSnowStarts);
	WeeveeDbgCall("ShoresFixPlayerStarts", ShoresFixPlayerStarts);
	ClampPlayerStartsOffEdges();
	WeeveeDbgCall("FrostyThawStartResources", FrostyThawStartResources);
	WeeveeDbg("StartPlotSystem done");
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
------------------------------- SHORES CLIMATE -------------------------------
-- A narrow mainland band nobody starts on, and an archipelago field to the
-- west where every capital begins. The barrier and its tundra transition are
-- untouched - they come from the generic SetDivide path.
--
-- shoresIslandId is the authority on what is an island. Areas get recalculated
-- three times downstream (AddLakes, PlaceResourcesAndCityStates, the mirror),
-- so plot:Area() goes stale; this grid does not.
------------------------------------------------------------------------------
local shoresIslandId = {};
local shoresIslandSize = {};
local shoresPlotTypes = nil;
local shoresIslandBiome = {};
local shoresLakePlots = {};
------------------------------------------------------------------------------
function ShoresIslandIdAt(x, y, iW)
	local v = shoresIslandId[y * iW + x + 1];
	if v == nil then
		return 0;
	end
	return v;
end
------------------------------------------------------------------------------
function ShoresInField(x, y, iW, iH)
	return x >= 0 and x <= ShoresSeaHiX(iW) and y >= 1 and y < iH - 1;
end
------------------------------------------------------------------------------
-- True when (x,y) can join island ownId without touching a foreign island OR
-- the mainland. Accepting only tiles that pass this leaves at least one water
-- tile between any two islands, and between every island and the coast - the
-- field's east edge sits directly against the band, so without the land test
-- islands would fuse with the mainland.
function ShoresTileFreeForIsland(x, y, iW, iH, ownId)
	if ShoresInField(x, y, iW, iH) == false then
		return false
	end
	if ShoresIslandIdAt(x, y, iW) ~= 0 then
		return false
	end
	local n = FrostyHexNeighbors(x, y);
	local i = 1;
	while i <= #n do
		local nx = x + n[i][1];
		local ny = y + n[i][2];
		if nx >= 0 and nx < iW and ny >= 0 and ny < iH then
			local other = ShoresIslandIdAt(nx, ny, iW);
			if other ~= 0 and other ~= ownId then
				return false
			end
			if other == 0 and shoresPlotTypes ~= nil then
				if shoresPlotTypes[ny * iW + nx + 1] ~= PlotTypes.PLOT_OCEAN then
					return false
				end
			end
		end
		i = i + 1;
	end
	return true
end
------------------------------------------------------------------------------
function ShoresPaintBand(plotTypes, iW, iH)
	local xT = ShoresWestTundraX(iW);
	local xDry = ShoresDryLoX(iW);
	local xLo = ShoresBandLoX(iW);

	-- Everything from the band's west edge to the tundra line starts as land.
	local y = 0;
	while y < iH do
		local x = xLo;
		while x <= xT do
			local idx = y * iW + x + 1;
			if plotTypes[idx] == PlotTypes.PLOT_OCEAN then
				plotTypes[idx] = PlotTypes.PLOT_LAND;
			end
			x = x + 1;
		end
		y = y + 1;
	end

	-- The dry margin must stay walkable, so no mountains there. Hills are fine.
	y = 0;
	while y < iH do
		local x = xDry;
		while x <= xT - 1 do
			local idx = y * iW + x + 1;
			if plotTypes[idx] == PlotTypes.PLOT_MOUNTAIN then
				plotTypes[idx] = PlotTypes.PLOT_HILLS;
			end
			x = x + 1;
		end
		y = y + 1;
	end

	-- The tundra line itself: relief against the barrier.
	y = 0;
	while y < iH do
		local roll = Map.Rand(100, "Shores Tundra Line");
		local idx = y * iW + xT + 1;
		if roll < 35 then
			plotTypes[idx] = PlotTypes.PLOT_MOUNTAIN;
		elseif roll < 80 then
			plotTypes[idx] = PlotTypes.PLOT_HILLS;
		else
			plotTypes[idx] = PlotTypes.PLOT_LAND;
		end
		y = y + 1;
	end
end
------------------------------------------------------------------------------
-- Sea bites into the outer band columns only. The dry margin is off limits,
-- which is what keeps the band walkable north to south.
function ShoresCarveBandBites(plotTypes, iW, iH)
	local xLo = ShoresBandLoX(iW);
	local xHi = ShoresDryLoX(iW) - 1;
	if xHi < xLo then
		return
	end
	local span = xHi - xLo + 1;
	local nBites = 2 + Map.Rand(math.max(1, math.floor(iH / 6)), "Shores Band Bites");
	local b = 0;
	while b < nBites do
		local sx = xLo + Map.Rand(span, "Shores Bite X");
		local sy = 1 + Map.Rand(math.max(1, iH - 2), "Shores Bite Y");
		local target = 2 + Map.Rand(5, "Shores Bite Size");
		local q = {};
		table.insert(q, {sx, sy});
		local grown = 0;
		local qi = 1;
		local guard = 0;
		while qi <= #q and grown < target and guard < 60 do
			guard = guard + 1;
			local px = q[qi][1];
			local py = q[qi][2];
			qi = qi + 1;
			local idx = py * iW + px + 1;
			if px >= xLo and px <= xHi and py >= 1 and py < iH - 1
				and plotTypes[idx] ~= PlotTypes.PLOT_OCEAN
				and plotTypes[idx] ~= PlotTypes.PLOT_MOUNTAIN then
				plotTypes[idx] = PlotTypes.PLOT_OCEAN;
				grown = grown + 1;
				local n = FrostyHexNeighbors(px, py);
				local i = 1;
				while i <= #n do
					if Map.Rand(100, "Shores Bite Grow") < 55 then
						table.insert(q, {px + n[i][1], py + n[i][2]});
					end
					i = i + 1;
				end
			end
		end
		b = b + 1;
	end
end
------------------------------------------------------------------------------
-- Grow one island: a small compact core, then 1-wide arms that curl away from
-- it. Arms are what give the islands their shape - a core of cfg.coreMin..
-- cfg.coreMax tiles is deliberately small so most of the island is arm.
-- Returns the tile list, or nil if it came out under islandSizeMin with
-- nothing committed.
function ShoresGrowIsland(plotTypes, iW, iH, sx, sy, id, cfg)
	local targetTotal = cfg.islandSizeMin
		+ Map.Rand(cfg.islandSizeMax - cfg.islandSizeMin + 1, "Shores Island Size");
	local coreTarget = cfg.coreMin
		+ Map.Rand(cfg.coreMax - cfg.coreMin + 1, "Shores Core Size");

	local tiles = {};
	local function claim(x, y)
		shoresIslandId[y * iW + x + 1] = id;
		table.insert(tiles, {x, y});
	end
	local function release()
		local i = 1;
		while i <= #tiles do
			shoresIslandId[tiles[i][2] * iW + tiles[i][1] + 1] = 0;
			i = i + 1;
		end
	end

	if ShoresTileFreeForIsland(sx, sy, iW, iH, id) == false then
		return nil
	end
	claim(sx, sy);

	-- Compact core.
	local q = {};
	table.insert(q, {sx, sy});
	local qi = 1;
	local guard = 0;
	while qi <= #q and #tiles < coreTarget and guard < 200 do
		guard = guard + 1;
		local px = q[qi][1];
		local py = q[qi][2];
		qi = qi + 1;
		local order = GetShuffledCopyOfTable(FrostyHexNeighbors(px, py));
		local i = 1;
		while i <= #order and #tiles < coreTarget do
			local nx = px + order[i][1];
			local ny = py + order[i][2];
			if ShoresTileFreeForIsland(nx, ny, iW, iH, id) then
				claim(nx, ny);
				table.insert(q, {nx, ny});
			end
			i = i + 1;
		end
	end

	-- Arms. Each one walks 1 tile wide and turns the same way every step or
	-- two, which is what makes it curl instead of running straight.
	local armTries = 0;
	local maxArmTries = 40;
	while #tiles < targetTotal and armTries < maxArmTries do
		armTries = armTries + 1;
		local root = tiles[1 + Map.Rand(#tiles, "Shores Arm Root")];
		local dir = Map.Rand(6, "Shores Arm Dir");
		local curl = 1;
		if Map.Rand(2, "Shores Arm Curl") == 0 then
			curl = 5;
		end
		local len = cfg.armLenMin
			+ Map.Rand(cfg.armLenMax - cfg.armLenMin + 1, "Shores Arm Len");
		local cx = root[1];
		local cy = root[2];
		local step = 0;
		while step < len and #tiles < targetTotal do
			local n = FrostyHexNeighbors(cx, cy);
			local nx = cx + n[dir + 1][1];
			local ny = cy + n[dir + 1][2];
			if ShoresTileFreeForIsland(nx, ny, iW, iH, id) == false then
				break
			end
			claim(nx, ny);
			cx = nx;
			cy = ny;
			step = step + 1;
			if Map.Rand(3, "Shores Arm Turn") > 0 then
				dir = (dir + curl) % 6;
			end
		end
	end

	if #tiles < cfg.islandSizeMin then
		release();
		return nil
	end

	local i = 1;
	while i <= #tiles do
		plotTypes[tiles[i][2] * iW + tiles[i][1] + 1] = PlotTypes.PLOT_LAND;
		i = i + 1;
	end
	return tiles;
end
------------------------------------------------------------------------------
-- Absorb every water tile that is not doing a job. A field tile touching
-- exactly one island gets handed to it; a tile touching two stays water,
-- because that is the channel between them. Tiles touching the mainland band
-- are never absorbed - islands must not fuse with the coast. Run to a fixed
-- point, so what is left is channels and nothing else.
function ShoresFillPockets(plotTypes, iW, iH)
	local seaHi = ShoresSeaHiX(iW);
	local rounds = 0;
	local absorbed = 0;
	local changed = true;
	while changed and rounds < 12 do
		rounds = rounds + 1;
		changed = false;
		local y = 1;
		while y < iH - 1 do
			local x = 0;
			while x <= seaHi do
				local idx = y * iW + x + 1;
				if plotTypes[idx] == PlotTypes.PLOT_OCEAN then
					local n = FrostyHexNeighbors(x, y);
					local found = 0;
					local nearBand = false;
					local i = 1;
					while i <= #n do
						local nx = x + n[i][1];
						local ny = y + n[i][2];
						if nx >= 0 and nx < iW and ny >= 0 and ny < iH then
							local nid = ShoresIslandIdAt(nx, ny, iW);
							if nid ~= 0 then
								if found == 0 then
									found = nid;
								elseif found ~= nid then
									found = -1;
								end
							elseif plotTypes[ny * iW + nx + 1] ~= PlotTypes.PLOT_OCEAN then
								-- band or barrier land
								nearBand = true;
							end
						end
						i = i + 1;
					end
					if found > 0 and nearBand == false then
						-- Re-check against live state: two neighbouring pockets
						-- claimed by different islands would otherwise fuse them.
						if ShoresTileFreeForIsland(x, y, iW, iH, found) then
							plotTypes[idx] = PlotTypes.PLOT_LAND;
							shoresIslandId[idx] = found;
							shoresIslandSize[found] = (shoresIslandSize[found] or 0) + 1;
							absorbed = absorbed + 1;
							changed = true;
						end
					end
				end
				x = x + 1;
			end
			y = y + 1;
		end
	end
	print("Shores pocket fill: absorbed", absorbed, "water tiles in", rounds, "rounds");
	return absorbed;
end
------------------------------------------------------------------------------
-- Carve a lake wherever an island has a full 7-tile hex of its own land.
function ShoresCarveIslandLakes(plotTypes, iW, iH)
	shoresLakePlots = {};
	local y = 1;
	while y < iH - 1 do
		local x = 0;
		while x <= ShoresSeaHiX(iW) do
			local id = ShoresIslandIdAt(x, y, iW);
			if id ~= 0 then
				local n = FrostyHexNeighbors(x, y);
				local full = true;
				local i = 1;
				while i <= #n do
					if ShoresIslandIdAt(x + n[i][1], y + n[i][2], iW) ~= id then
						full = false;
						break
					end
					i = i + 1;
				end
				if full then
					plotTypes[y * iW + x + 1] = PlotTypes.PLOT_OCEAN;
					shoresIslandId[y * iW + x + 1] = 0;
					if shoresIslandSize[id] ~= nil then
						shoresIslandSize[id] = shoresIslandSize[id] - 1;
					end
					table.insert(shoresLakePlots, {x, y});
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	return #shoresLakePlots;
end
------------------------------------------------------------------------------
-- How many islands must be big enough to host a capital.
function ShoresRequiredIslands()
	local nCivs = 2;
	local ok, a, b, c, d, e, f = pcall(GetPlayerAndTeamInfo);
	if ok and a ~= nil then
		nCivs = a;
	end
	local perSide = math.ceil(nCivs / 2);
	if perSide < 1 then
		perSide = 1;
	end
	return perSide, perSide + 2;
end
------------------------------------------------------------------------------
function ShoresCountQualifying(iW, iH, minSize)
	local seen = {};
	local n = 0;
	local y = 1;
	while y < iH - 1 do
		local x = 0;
		while x <= ShoresSeaHiX(iW) do
			local id = ShoresIslandIdAt(x, y, iW);
			if id ~= 0 and seen[id] == nil and StartYAllowed(y, iH) then
				if (shoresIslandSize[id] or 0) >= minSize then
					seen[id] = true;
					n = n + 1;
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	return n;
end
------------------------------------------------------------------------------
function ShoresBuildPlotTypes(plotTypes, iW, iH)
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "shores" then
		return
	end
	WeeveeDbg("ShoresBuildPlotTypes");
	shoresIslandId = {};
	shoresIslandSize = {};
	shoresIslandBiome = {};
	shoresPlotTypes = plotTypes;

	local seaHi = ShoresSeaHiX(iW);

	-- 1. Clear the western field to open ocean.
	local y = 0;
	while y < iH do
		local x = 0;
		while x <= seaHi do
			plotTypes[y * iW + x + 1] = PlotTypes.PLOT_OCEAN;
			x = x + 1;
		end
		y = y + 1;
	end

	-- 2. The mainland band.
	ShoresPaintBand(plotTypes, iW, iH);
	ShoresCarveBandBites(plotTypes, iW, iH);

	-- 3. Islands. Sweep every field tile in random order and grow wherever one
	--    fits. The separation guard already keeps a water tile between
	--    neighbours, so sweeping to exhaustion packs the field about as tight
	--    as the gap rule allows. Seeds are not restricted to start-legal rows:
	--    islands run right down to y = 1, only capitals need StartYAllowed.
	local perSide, wantIslands = ShoresRequiredIslands();
	local seeds = {};
	local sy2 = 1;
	while sy2 < iH - 1 do
		local sx2 = 0;
		while sx2 <= seaHi do
			table.insert(seeds, {sx2, sy2});
			sx2 = sx2 + 1;
		end
		sy2 = sy2 + 1;
	end
	seeds = GetShuffledCopyOfTable(seeds);

	local nextId = 1;
	local placed = 0;
	local si = 1;
	while si <= #seeds do
		local sx = seeds[si][1];
		local sy = seeds[si][2];
		si = si + 1;
		if ShoresIslandIdAt(sx, sy, iW) == 0
			and ShoresTileFreeForIsland(sx, sy, iW, iH, nextId) then
			local tiles = ShoresGrowIsland(plotTypes, iW, iH, sx, sy, nextId, cfg);
			if tiles ~= nil then
				shoresIslandSize[nextId] = #tiles;
				nextId = nextId + 1;
				placed = placed + 1;
			end
		end
	end

	-- 3b. Soak up leftover water so the field reads as an archipelago rather
	--     than islands adrift in open sea.
	ShoresFillPockets(plotTypes, iW, iH);

	-- 4. Lakes, before the qualifying count - a carve can drop a 10 to a 9.
	local nLakes = ShoresCarveIslandLakes(plotTypes, iW, iH);

	-- 5. Make sure enough islands can host a capital. Bounded repair only.
	local qualify = ShoresCountQualifying(iW, iH, cfg.islandStartMin);
	local repair = 0;
	while qualify < perSide and repair < 6 do
		repair = repair + 1;
		local grew = false;
		local id = 1;
		while id < nextId do
			local sz = shoresIslandSize[id] or 0;
			if sz > 0 and sz < cfg.islandStartMin then
				local yy = 1;
				while yy < iH - 1 and (shoresIslandSize[id] or 0) < cfg.islandStartMin do
					local xx = 0;
					while xx <= seaHi and (shoresIslandSize[id] or 0) < cfg.islandStartMin do
						if ShoresIslandIdAt(xx, yy, iW) == id then
							local n = FrostyHexNeighbors(xx, yy);
							local i = 1;
							while i <= #n do
								local nx = xx + n[i][1];
								local ny = yy + n[i][2];
								if ShoresTileFreeForIsland(nx, ny, iW, iH, id) then
									shoresIslandId[ny * iW + nx + 1] = id;
									plotTypes[ny * iW + nx + 1] = PlotTypes.PLOT_LAND;
									shoresIslandSize[id] = (shoresIslandSize[id] or 0) + 1;
									grew = true;
								end
								i = i + 1;
							end
						end
						xx = xx + 1;
					end
					yy = yy + 1;
				end
			end
			id = id + 1;
		end
		qualify = ShoresCountQualifying(iW, iH, cfg.islandStartMin);
		if grew == false then
			break
		end
	end
	if qualify < perSide then
		print("Shores WARNING: only", qualify, "islands can host a capital, need", perSide);
	end

	print("Shores: islands", placed, " lakes", nLakes, " capital-capable", qualify, "/", perSide);
	WeeveeDbg("ShoresBuildPlotTypes done islands=" .. tostring(placed));
end
------------------------------------------------------------------------------
-- Runs after ApplyTectonics, so the relief the engine gave the west half is
-- what gets copied. Mirroring before tectonics would let the two halves grow
-- different hills. FrostyCopyOceanWestToEast only moves ocean; we need full
-- plot types plus the island grid.
function ShoresMirrorField(plotTypes, iW, iH)
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "shores" then
		return
	end
	local y = 0;
	while y < iH do
		local x = 0;
		while x <= math.floor(iW / 2) do
			local mx = iW - x - 1;
			local my = iH - y - 1;
			if mx >= 0 and mx < iW and my >= 0 and my < iH then
				local src = y * iW + x + 1;
				local dst = my * iW + mx + 1;
				plotTypes[dst] = plotTypes[src];
				shoresIslandId[dst] = shoresIslandId[src];
			end
			x = x + 1;
		end
		y = y + 1;
	end
	WeeveeDbg("ShoresMirrorField done");
end
------------------------------------------------------------------------------
-- Islands take their biome from where they sit north to south, so each island
-- reads as one place rather than a latitude smear across four tiles.
-- 1 tropical, 2 temperate, 3 plains, 4 arid, 5 tundra.
function ShoresBiomeForY(y, iH, jitter)
	local yNorm = 0;
	if iH > 1 then
		yNorm = y / (iH - 1);
	end
	yNorm = yNorm + jitter;
	if yNorm < 0.22 then
		return 1;
	elseif yNorm < 0.42 then
		return 2;
	elseif yNorm < 0.60 then
		return 3;
	elseif yNorm < 0.78 then
		return 4;
	end
	return 5;
end
------------------------------------------------------------------------------
function ShoresBiomeTerrain(biome)
	if biome == 1 then
		if Map.Rand(100, "Shores Tropical Terrain") < 70 then
			return TerrainTypes.TERRAIN_GRASS;
		end
		return TerrainTypes.TERRAIN_PLAINS;
	elseif biome == 2 then
		if Map.Rand(100, "Shores Temperate Terrain") < 72 then
			return TerrainTypes.TERRAIN_GRASS;
		end
		return TerrainTypes.TERRAIN_PLAINS;
	elseif biome == 3 then
		if Map.Rand(100, "Shores Plains Terrain") < 74 then
			return TerrainTypes.TERRAIN_PLAINS;
		end
		return TerrainTypes.TERRAIN_GRASS;
	elseif biome == 4 then
		if Map.Rand(100, "Shores Arid Terrain") < 45 then
			return TerrainTypes.TERRAIN_DESERT;
		end
		return TerrainTypes.TERRAIN_PLAINS;
	end
	if Map.Rand(100, "Shores Tundra Terrain") < 80 then
		return TerrainTypes.TERRAIN_TUNDRA;
	end
	return TerrainTypes.TERRAIN_PLAINS;
end
------------------------------------------------------------------------------
function AddShoresLayout()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "shores" then
		return
	end
	WeeveeDbg("AddShoresLayout");
	local iW, iH = Map.GetGridSize();
	local seaHi = ShoresSeaHiX(iW);
	local xLo = ShoresBandLoX(iW);
	local xDry = ShoresDryLoX(iW);
	local xT = ShoresWestTundraX(iW);

	-- Pick one biome per island, from the island's own centre of mass.
	local sumY = {};
	local cnt = {};
	local y = 0;
	while y < iH do
		local x = 0;
		while x <= seaHi do
			local id = ShoresIslandIdAt(x, y, iW);
			if id ~= 0 then
				sumY[id] = (sumY[id] or 0) + y;
				cnt[id] = (cnt[id] or 0) + 1;
			end
			x = x + 1;
		end
		y = y + 1;
	end
	shoresIslandBiome = {};
	for id, n in pairs(cnt) do
		local midY = sumY[id] / n;
		local jitter = (Map.Rand(3, "Shores Biome Jitter") - 1) * 0.06;
		shoresIslandBiome[id] = ShoresBiomeForY(midY, iH, jitter);
	end

	-- Paint island terrain.
	y = 0;
	while y < iH do
		local x = 0;
		while x <= seaHi do
			local id = ShoresIslandIdAt(x, y, iW);
			if id ~= 0 then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil and plot:IsWater() == false then
					plot:SetTerrainType(ShoresBiomeTerrain(shoresIslandBiome[id] or 3), false, false);
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end

	-- Band terrain: temperate, never desert, never tundra.
	y = 0;
	while y < iH do
		local x = xLo;
		while x <= xT - 1 do
			local plot = Map.GetPlot(x, y);
			if plot ~= nil and plot:IsWater() == false then
				local t = plot:GetTerrainType();
				if t == TerrainTypes.TERRAIN_DESERT or t == TerrainTypes.TERRAIN_TUNDRA
					or t == TerrainTypes.TERRAIN_SNOW then
					if Map.Rand(100, "Shores Band Terrain") < 62 then
						plot:SetTerrainType(TerrainTypes.TERRAIN_GRASS, false, false);
					else
						plot:SetTerrainType(TerrainTypes.TERRAIN_PLAINS, false, false);
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end

	-- Tectonics is generous with mountains and an island is small. Cap each
	-- one at a fifth of its tiles so a 14-tile island cannot come out
	-- unworkable - or unstartable, since starts reject mountains.
	local mtn = {};
	local total = {};
	y = 0;
	while y < iH do
		local x = 0;
		while x <= seaHi do
			local id = ShoresIslandIdAt(x, y, iW);
			if id ~= 0 then
				total[id] = (total[id] or 0) + 1;
				local plot = Map.GetPlot(x, y);
				if plot ~= nil and plot:GetPlotType() == PlotTypes.PLOT_MOUNTAIN then
					if mtn[id] == nil then
						mtn[id] = {};
					end
					table.insert(mtn[id], {x, y});
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	local flattened = 0;
	for id, list in pairs(mtn) do
		local cap = math.floor((total[id] or 0) * 0.20);
		local shuffled = GetShuffledCopyOfTable(list);
		local i = cap + 1;
		while i <= #shuffled do
			local plot = Map.GetPlot(shuffled[i][1], shuffled[i][2]);
			if plot ~= nil then
				plot:SetPlotType(PlotTypes.PLOT_HILLS, false, false);
				flattened = flattened + 1;
			end
			i = i + 1;
		end
	end
	if flattened > 0 then
		print("Shores: capped", flattened, "island mountains to hills");
	end

	-- Re-assert walkability: no mountains in the dry margin.
	y = 0;
	while y < iH do
		local x = xDry;
		while x <= xT - 1 do
			local plot = Map.GetPlot(x, y);
			if plot ~= nil and plot:GetPlotType() == PlotTypes.PLOT_MOUNTAIN then
				plot:SetPlotType(PlotTypes.PLOT_HILLS, false, false);
			end
			x = x + 1;
		end
		y = y + 1;
	end
	WeeveeDbg("AddShoresLayout done");
end
------------------------------------------------------------------------------
function ShoresBiomeFeature(biome)
	if biome == 1 then
		local r = Map.Rand(100, "Shores Tropical Feature");
		if r < 46 then
			return FeatureTypes.FEATURE_JUNGLE;
		elseif r < 56 then
			return FeatureTypes.FEATURE_MARSH;
		end
		return FeatureTypes.NO_FEATURE;
	elseif biome == 2 then
		if Map.Rand(100, "Shores Temperate Feature") < 38 then
			return FeatureTypes.FEATURE_FOREST;
		end
		return FeatureTypes.NO_FEATURE;
	elseif biome == 3 then
		if Map.Rand(100, "Shores Plains Feature") < 22 then
			return FeatureTypes.FEATURE_FOREST;
		end
		return FeatureTypes.NO_FEATURE;
	elseif biome == 4 then
		if Map.Rand(100, "Shores Arid Feature") < 8 then
			return FeatureTypes.FEATURE_FOREST;
		end
		return FeatureTypes.NO_FEATURE;
	end
	if Map.Rand(100, "Shores Tundra Feature") < 30 then
		return FeatureTypes.FEATURE_FOREST;
	end
	return FeatureTypes.NO_FEATURE;
end
------------------------------------------------------------------------------
function AddShoresIslandFeatures()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "shores" then
		return
	end
	local iW, iH = Map.GetGridSize();
	local seaHi = ShoresSeaHiX(iW);
	local n = 0;
	local y = 0;
	while y < iH do
		local x = 0;
		while x <= seaHi do
			local id = ShoresIslandIdAt(x, y, iW);
			if id ~= 0 then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil and plot:IsWater() == false
					and plot:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN
					and plot:GetFeatureType() == FeatureTypes.NO_FEATURE then
					local feat = ShoresBiomeFeature(shoresIslandBiome[id] or 3);
					if feat ~= FeatureTypes.NO_FEATURE and plot:CanHaveFeature(feat) then
						plot:SetFeatureType(feat, -1);
						n = n + 1;
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	print("Shores island features:", n);
end
------------------------------------------------------------------------------
local shoresAtollID = nil;
local shoresAtollLooked = false;
function GetShoresAtollFeatureID()
	if shoresAtollLooked then
		return shoresAtollID;
	end
	shoresAtollLooked = true;
	for row in GameInfo.Features() do
		if row.Type == "FEATURE_ATOLL" then
			shoresAtollID = row.ID;
			break
		end
	end
	return shoresAtollID;
end
------------------------------------------------------------------------------
-- Island lakes get an atoll or nothing. The ones left alone stay eligible for
-- fish, which GenerateGlobalResourcePlotLists injects for us.
function AddShoresLakeFeatures()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "shores" then
		return
	end
	local atollID = GetShoresAtollFeatureID();
	if atollID == nil then
		return
	end
	local iW, iH = Map.GetGridSize();
	local n = 0;
	local i = 1;
	while i <= #shoresLakePlots do
		local x = shoresLakePlots[i][1];
		local y = shoresLakePlots[i][2];
		local plot = Map.GetPlot(x, y);
		if plot ~= nil and plot:IsWater() and plot:IsLake() then
			if Map.Rand(100, "Shores Lake Atoll") < cfg.lakeAtollPct then
				if plot:CanHaveFeature(atollID) then
					plot:SetFeatureType(atollID, -1);
					n = n + 1;
				end
			end
		end
		i = i + 1;
	end
	print("Shores lake atolls:", n, "of", #shoresLakePlots);
end
------------------------------------------------------------------------------
-- Lake plots that did not take an atoll, so they can host fish.
function ShoresOpenLakePlotIndices()
	local out = {};
	local iW, iH = Map.GetGridSize();
	local i = 1;
	while i <= #shoresLakePlots do
		local x = shoresLakePlots[i][1];
		local y = shoresLakePlots[i][2];
		local plot = Map.GetPlot(x, y);
		if plot ~= nil and plot:IsWater() and plot:IsLake()
			and plot:GetFeatureType() == FeatureTypes.NO_FEATURE
			and plot:GetResourceType(-1) == -1 then
			table.insert(out, y * iW + x + 1);
		end
		i = i + 1;
	end
	return out;
end
------------------------------------------------------------------------------
function ShoresMinStartLandmass()
	local cfg = GetBarrierConfig();
	if cfg ~= nil and cfg.kind == "shores" then
		return cfg.islandStartMin;
	end
	return MIN_START_LANDMASS;
end
------------------------------------------------------------------------------
-- The mainland test is simply "has no island id" - band and barrier tiles are
-- never assigned one. That is O(1) and survives area recalculation, which a
-- column test or plot:Area() would not.
function ShoresPlotIsStartLegal(x, y)
	local iW, iH = Map.GetGridSize();
	if x == nil or y == nil then
		return false
	end
	if StartYAllowed(y, iH) == false then
		return false
	end
	local plot = Map.GetPlot(x, y);
	if plot == nil or plot:IsWater() then
		return false
	end
	if plot:GetPlotType() == PlotTypes.PLOT_MOUNTAIN then
		return false
	end
	local id = ShoresIslandIdAt(x, y, iW);
	if id == 0 then
		return false
	end
	if (shoresIslandSize[id] or 0) < ShoresMinStartLandmass() then
		return false
	end
	return true
end
------------------------------------------------------------------------------
function ShoresIslandIsTaken(id, taken)
	return taken[id] == true;
end
------------------------------------------------------------------------------
-- Best free tile on an unclaimed qualifying island, preferring distance from
-- the starts already placed.
function ShoresBestFreeIslandPlot(taken, starts, skipIndex)
	local iW, iH = Map.GetGridSize();
	local bestX, bestY, bestId;
	local bestScore = -1;
	local y = 1;
	while y < iH - 1 do
		local x = 0;
		while x <= ShoresSeaHiX(iW) do
			local id = ShoresIslandIdAt(x, y, iW);
			if id ~= 0 and ShoresIslandIsTaken(id, taken) == false and ShoresPlotIsStartLegal(x, y) then
				local d = FrostyStartMinDist(x, y, starts, skipIndex);
				local score = d * 100 + (shoresIslandSize[id] or 0);
				if score > bestScore then
					bestScore = score;
					bestX = x;
					bestY = y;
					bestId = id;
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	return bestX, bestY, bestId;
end
------------------------------------------------------------------------------
-- Runs after ChooseLocations. Moves any capital that is on the band, on water,
-- or on an island too small onto a free qualifying island.
function ShoresFixStarts(asp)
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "shores" then
		return
	end
	if asp == nil or asp.startingPlots == nil then
		return
	end
	WeeveeDbg("ShoresFixStarts");
	local iW, iH = Map.GetGridSize();
	local taken = {};
	local moved = 0;

	-- Claim the islands already legally occupied so we do not double up.
	local i = 1;
	while i <= asp.iNumCivs do
		local sp = asp.startingPlots[i];
		if sp ~= nil and ShoresPlotIsStartLegal(sp[1], sp[2]) then
			local id = ShoresIslandIdAt(sp[1], sp[2], iW);
			if taken[id] == true then
				-- two capitals on one island: the second one moves
				asp.startingPlots[i] = nil;
			else
				taken[id] = true;
			end
		end
		i = i + 1;
	end

	i = 1;
	while i <= asp.iNumCivs do
		local sp = asp.startingPlots[i];
		local needsMove = true;
		if sp ~= nil and ShoresPlotIsStartLegal(sp[1], sp[2]) then
			needsMove = false;
		end
		if needsMove then
			local bx, by, bid = ShoresBestFreeIslandPlot(taken, asp.startingPlots, i);
			if bx ~= nil then
				asp.startingPlots[i] = {bx, by, 1};
				taken[bid] = true;
				moved = moved + 1;
			else
				print("Shores: no free qualifying island for civ", i);
			end
		end
		i = i + 1;
	end
	print("Shores starts relocated:", moved);
	WeeveeDbg("ShoresFixStarts done moved=" .. tostring(moved));
end
------------------------------------------------------------------------------
-- After the mirror. This is the only pass that sees the final board, since
-- BalanceAndAssign and the mirror both run after ShoresFixStarts.
function ShoresFixPlayerStarts()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "shores" then
		return
	end
	local iW, iH = Map.GetGridSize();
	local moved = 0;
	local i = 0;
	while i < GameDefines.MAX_MAJOR_CIVS do
		local player = Players[i];
		if isValidPlayer(player) and player:IsEverAlive() then
			local sp = player:GetStartingPlot();
			if sp ~= nil then
				local sx = sp:GetX();
				local sy = sp:GetY();
				local legal = ShoresPlotIsStartLegal(sx, sy);
				if legal == false then
					-- Mirror the test onto the west half: an east start is the
					-- 180 rotation of a legal west tile.
					local mx = iW - sx - 1;
					local my = iH - sy - 1;
					legal = ShoresPlotIsStartLegal(mx, my);
				end
				if legal == false then
					-- Prefer a real Shores island; fall back to the generic
					-- off-edge search only if none is free. FindNearestStartOffEdge
					-- returns two coordinates, not a plot.
					local nx, ny = ShoresNearestLegalPlot(sx, sy);
					if nx == nil then
						nx, ny = FindNearestStartOffEdge(sx, sy);
					end
					if nx ~= nil and ny ~= nil then
						local dest = Map.GetPlot(nx, ny);
						if dest ~= nil and dest:IsWater() == false then
							player:SetStartingPlot(dest);
							moved = moved + 1;
						end
					end
				end
			end
		end
		i = i + 1;
	end
	if moved > 0 then
		print("Shores post-mirror start fixes:", moved);
	end
end
------------------------------------------------------------------------------
function ShoresLuxDist()
	local cfg = GetBarrierConfig();
	if cfg ~= nil and cfg.luxWaterDist ~= nil then
		return cfg.luxWaterDist;
	end
	return 3;
end
------------------------------------------------------------------------------
function ShoresLuxPlotOk(plot)
	if plot == nil then
		return false
	end
	return Map.FindWater(plot, ShoresLuxDist(), false);
end
------------------------------------------------------------------------------
-- Every luxury has to be reachable from a coastal city, so drop candidate
-- plots further than cfg.luxWaterDist from water. The ratio is scaled back up
-- by the same factor, otherwise trimming the list quietly halves the number of
-- luxuries the vanilla count formula asks for.
local ASP_PlaceSpecificNumberOfResources = AssignStartingPlots.PlaceSpecificNumberOfResources;
function AssignStartingPlots:PlaceSpecificNumberOfResources(resource_ID, quantity, amount, ratio,
		impact_table_number, min_radius, max_radius, plot_list)
	if IsShores() and plot_list ~= nil and resource_ID ~= nil then
		if Game.GetResourceUsageType(resource_ID) == ResourceUsageTypes.RESOURCEUSAGE_LUXURY then
			local iW, iH = Map.GetGridSize();
			local kept = {};
			local i = 1;
			while i <= #plot_list do
				local idx = plot_list[i];
				local x = (idx - 1) % iW;
				local y = (idx - x - 1) / iW;
				local plot = Map.GetPlot(x, y);
				if ShoresLuxPlotOk(plot) then
					table.insert(kept, idx);
				end
				i = i + 1;
			end
			if #kept > 0 then
				if ratio ~= nil and ratio > 0 then
					local scale = #plot_list / #kept;
					ratio = ratio * scale;
					if ratio > 1 then
						ratio = 1;
					end
				end
				plot_list = kept;
			end
		end
	end
	return ASP_PlaceSpecificNumberOfResources(self, resource_ID, quantity, amount, ratio,
		impact_table_number, min_radius, max_radius, plot_list);
end
------------------------------------------------------------------------------
-- Backstop for the paths that never touch PlaceSpecificNumberOfResources.
function ShoresSweepFarLuxuries()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "shores" then
		return
	end
	local iW, iH = Map.GetGridSize();
	local maxX = math.floor(iW * 0.5);
	local cleared = 0;
	local y = 0;
	while y < iH do
		local x = 0;
		while x <= maxX do
			local plot = Map.GetPlot(x, y);
			if plot ~= nil then
				local res = plot:GetResourceType(-1);
				if res ~= -1 and Game.GetResourceUsageType(res) == ResourceUsageTypes.RESOURCEUSAGE_LUXURY then
					if ShoresLuxPlotOk(plot) == false then
						plot:SetResourceType(-1, 0);
						cleared = cleared + 1;
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	if cleared > 0 then
		print("Shores: cleared", cleared, "luxuries too far from water");
	end
end
------------------------------------------------------------------------------
-- Six strategics at 10% each, then bonuses for the rest. Rolling the resource
-- before choosing terrain matters: CanHaveResource is terrain-sensitive, so
-- picking terrain first would reject most of the strategics.
function ShoresBonusResourceIDs()
	local out = {};
	for row in GameInfo.Resources() do
		if row.ResourceClassType == "RESOURCECLASS_BONUS" and row.Type ~= "RESOURCE_FISH" then
			local id = GameInfoTypes[row.Type];
			if id ~= nil then
				table.insert(out, id);
			end
		end
	end
	return out;
end
------------------------------------------------------------------------------
function ShoresRollResource(bonusPool)
	local names = { "RESOURCE_HORSE", "RESOURCE_IRON", "RESOURCE_COAL",
		"RESOURCE_ALUMINUM", "RESOURCE_OIL", "RESOURCE_URANIUM" };
	local r = Map.Rand(100, "Shores Resource Roll");
	local slot = math.floor(r / 10) + 1;
	if r < 60 and names[slot] ~= nil then
		local id = GameInfoTypes[names[slot]];
		if id ~= nil then
			return id, 2;
		end
	end
	if #bonusPool > 0 then
		return bonusPool[1 + Map.Rand(#bonusPool, "Shores Bonus Pick")], 1;
	end
	return nil, 0;
end
------------------------------------------------------------------------------
function ShoresPlaceRolledResource(plot, bonusPool)
	if plot == nil or plot:GetResourceType(-1) ~= -1 then
		return false
	end
	local tries = 0;
	while tries < 8 do
		tries = tries + 1;
		local id, amt = ShoresRollResource(bonusPool);
		if id ~= nil and plot:CanHaveResource(id) then
			plot:SetResourceType(id, amt);
			return true
		end
	end
	return false
end
------------------------------------------------------------------------------
-- Islands should out-produce the band. Runs after luxuries so it can only fill
-- genuinely empty tiles and can never crowd a luxury out.
function ShoresBoostIslandResources()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "shores" then
		return
	end
	local iW, iH = Map.GetGridSize();
	local seaHi = ShoresSeaHiX(iW);
	local pool = ShoresBonusResourceIDs();
	local n = 0;
	local y = 0;
	while y < iH do
		local x = 0;
		while x <= seaHi do
			if ShoresIslandIdAt(x, y, iW) ~= 0 then
				local plot = Map.GetPlot(x, y);
				if plot ~= nil and plot:IsWater() == false
					and plot:GetPlotType() ~= PlotTypes.PLOT_MOUNTAIN
					and plot:GetResourceType(-1) == -1 then
					if Map.Rand(100, "Shores Island Resource") < cfg.islandResourcePct then
						if ShoresPlaceRolledResource(plot, pool) then
							n = n + 1;
						end
					end
				end
			end
			x = x + 1;
		end
		y = y + 1;
	end
	print("Shores island resources added:", n);
end
------------------------------------------------------------------------------
-- Islets: single or paired tiles dropped into open channels, each one carrying
-- a resource. A candidate must have six water neighbours, which is exactly the
-- "touches no landmass" rule and is cheaper than reasoning about areas.
function ShoresPlantIslets()
	local cfg = GetBarrierConfig();
	if cfg == nil or cfg.kind ~= "shores" then
		return
	end
	WeeveeDbg("ShoresPlantIslets");
	local iW, iH = Map.GetGridSize();
	local seaHi = ShoresSeaHiX(iW);
	local pool = ShoresBonusResourceIDs();
	local consumed = {};

	local function allWaterNeighbors(x, y)
		local n = FrostyHexNeighbors(x, y);
		local i = 1;
		while i <= #n do
			local nx = x + n[i][1];
			local ny = y + n[i][2];
			if nx < 0 or nx >= iW or ny < 0 or ny >= iH then
				return false
			end
			local p = Map.GetPlot(nx, ny);
			if p == nil or p:IsWater() == false then
				return false
			end
			if consumed[ny * iW + nx + 1] == true then
				return false
			end
			i = i + 1;
		end
		return true
	end

	local function landWithin(x, y, d)
		local n = 0;
		local ry = y - d;
		while ry <= y + d do
			local rx = x - d;
			while rx <= x + d do
				if rx >= 0 and rx < iW and ry >= 0 and ry < iH then
					if Map.PlotDistance(x, y, rx, ry) <= d then
						local p = Map.GetPlot(rx, ry);
						if p ~= nil and p:IsWater() == false then
							n = n + 1;
						end
					end
				end
				rx = rx + 1;
			end
			ry = ry + 1;
		end
		return n;
	end

	local function markConsumed(x, y)
		consumed[y * iW + x + 1] = true;
		local n = FrostyHexNeighbors(x, y);
		local i = 1;
		while i <= #n do
			local nx = x + n[i][1];
			local ny = y + n[i][2];
			if nx >= 0 and nx < iW and ny >= 0 and ny < iH then
				consumed[ny * iW + nx + 1] = true;
			end
			i = i + 1;
		end
	end

	local function makeIslet(x, y)
		local plot = Map.GetPlot(x, y);
		if plot == nil then
			return false
		end
		plot:SetPlotType(PlotTypes.PLOT_LAND, false, false);
		plot:SetTerrainType(TerrainTypes.TERRAIN_PLAINS, false, false);
		plot:SetFeatureType(FeatureTypes.NO_FEATURE, -1);
		if ShoresPlaceRolledResource(plot, pool) == false then
			-- Never leave a bare islet; revert rather than ship an empty rock.
			plot:SetPlotType(PlotTypes.PLOT_OCEAN, false, false);
			plot:SetTerrainType(TerrainTypes.TERRAIN_COAST, false, false);
			return false
		end
		-- Deep ocean beside new land looks wrong; GenerateCoasts ran long ago.
		local n = FrostyHexNeighbors(x, y);
		local i = 1;
		while i <= #n do
			local nx = x + n[i][1];
			local ny = y + n[i][2];
			if nx >= 0 and nx < iW and ny >= 0 and ny < iH then
				local p = Map.GetPlot(nx, ny);
				if p ~= nil and p:IsWater() and p:GetTerrainType() == TerrainTypes.TERRAIN_OCEAN then
					p:SetTerrainType(TerrainTypes.TERRAIN_COAST, false, false);
				end
			end
			i = i + 1;
		end
		markConsumed(x, y);
		return true
	end

	local nWant = 3 + Map.Rand(4, "Shores Islet Count");
	local placed = 0;
	local tries = 0;
	local maxTries = nWant * 25 + 40;
	while placed < nWant and tries < maxTries do
		tries = tries + 1;
		local x = 1 + Map.Rand(math.max(1, seaHi), "Shores Islet X");
		local y = 1 + Map.Rand(math.max(1, iH - 2), "Shores Islet Y");
		local plot = Map.GetPlot(x, y);
		if plot ~= nil and plot:IsWater() and consumed[y * iW + x + 1] ~= true
			and allWaterNeighbors(x, y) and landWithin(x, y, 3) > 0 then
			if makeIslet(x, y) then
				placed = placed + 1;
				-- A paired islet only if the partner is also fully surrounded.
				if Map.Rand(100, "Shores Islet Pair") < 45 then
					local n = FrostyHexNeighbors(x, y);
					local order = GetShuffledCopyOfTable(n);
					local i = 1;
					while i <= #order do
						local nx = x + order[i][1];
						local ny = y + order[i][2];
						local q = Map.GetPlot(nx, ny);
						if q ~= nil and q:IsWater() and nx >= 1 and nx <= seaHi
							and ny >= 1 and ny < iH - 1 then
							local ok = true;
							local m = FrostyHexNeighbors(nx, ny);
							local k = 1;
							while k <= #m do
								local mx = nx + m[k][1];
								local my = ny + m[k][2];
								if not (mx == x and my == y) then
									if mx < 0 or mx >= iW or my < 0 or my >= iH then
										ok = false;
										break
									end
									local mp = Map.GetPlot(mx, my);
									if mp == nil or mp:IsWater() == false then
										ok = false;
										break
									end
								end
								k = k + 1;
							end
							if ok and makeIslet(nx, ny) then
								break
							end
						end
						i = i + 1;
					end
				end
			end
		end
	end
	print("Shores islets planted:", placed, "of", nWant, "wanted");
	WeeveeDbg("ShoresPlantIslets done placed=" .. tostring(placed));
end
