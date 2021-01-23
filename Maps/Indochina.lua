-- Indochina
-- Author: blkbutterfly74
-- DateCreated: 10/10/2017 9:05:41 PM
-- Creates a tiny map shaped like real-world Indochina
-- based off Scrambled Southeast Asia map script
-- Thanks to Firaxis
-----------------------------------------------------------------------------

include "MapEnums"
include "MapUtilities"
include "MountainsCliffs"
include "RiversLakes"
include "FeatureGenerator"
include "TerrainGenerator"
include "NaturalWonderGenerator"
include "ResourceGenerator"
include "AssignStartingPlots"

local g_iW, g_iH;
local g_iFlags = {};
local g_continentsFrac = nil;
local g_iNumTotalLandTiles = 0; 
local g_CenterX = 16;
local g_CenterY = 27;
local landStrips = {
		{0, 4, 4},
		{0, 7, 9},
		{1, 4, 9},
		{2, 2, 2},
		{2, 4, 9},
		{3, 4, 9},
		{3, 25, 26},
		{4, 5, 7},
		{4, 25, 27},
		{5, 3, 3},
		{5, 5, 6},
		{5, 9, 9},
		{5, 25, 29},
		{6, 5, 6},
		{6, 25, 30},
		{7, 5, 6},
		{7, 25, 30},
		{8, 5, 7},
		{8, 21, 21},
		{8, 23, 32},
		{9, 6, 7},
		{9, 23, 34},
		{10, 6, 7},
		{10, 20, 35},
		{11, 6, 8},
		{11, 19, 37},
		{12, 6, 9},
		{12, 17, 17},
		{12, 19, 37},
		{13, 6, 9},
		{13, 19, 37},
		{14, 6, 9},
		{14, 16, 38},
		{15, 3, 3},
		{15, 6, 9},
		{15, 12, 38},
		{16, 5, 9},
		{16, 12, 38},
		{17, 5, 10},
		{17, 13, 38},
		{18, 4, 38},
		{18, 4, 38},
		{19, 4, 38},
		{20, 4, 37},
		{21, 3, 37},
		{22, 3, 37},
		{23, 3, 36},
		{24, 3, 35},
		{25, 2, 35},
		{26, 2, 34},
		{27, 1, 32},
		{28, 0, 31},
		{29, 0, 30},
		{30, 0, 29},
		{31, 0, 29},
		{32, 0, 28}, 
		{32, 38, 39},
		{33, 0, 27},
		{33, 37, 41},
		{34, 0, 26},
		{34, 36, 42},
		{35, 0, 27},
		{35, 36, 42},
		{36, 0, 26},
		{36, 38, 43},
		{37, 0, 26},
		{37, 39, 43},
		{38, 0, 27},
		{39, 0, 27},
		{39, 40, 42},
		{40, 0, 28},
		{40, 40, 42},
		{41, 0, 33},
		{41, 40, 42},
		{42, 0, 35},
		{42, 37, 44},
		{43, 0, 44},
		{44, 0, 44},
		{45, 0, 44},
		{46, 0, 44},
		{47, 0, 44},
		{48, 0, 44}};


-------------------------------------------------------------------------------
function GenerateMap()
	print("Generating Southeast Asia Map");
	local pPlot;

	-- Set globals
	g_iW, g_iH = Map.GetGridSize();
	g_iFlags = TerrainBuilder.GetFractalFlags();
	local temperature = 0;
	
	plotTypes = GeneratePlotTypes();
	terrainTypes = GenerateTerrainTypesIndochina(plotTypes, g_iW, g_iH, g_iFlags, true);

	for i = 0, (g_iW * g_iH) - 1, 1 do
		pPlot = Map.GetPlotByIndex(i);
		if (plotTypes[i] == g_PLOT_TYPE_HILLS) then
			terrainTypes[i] = terrainTypes[i] + 1;
		end
		TerrainBuilder.SetTerrainType(pPlot, terrainTypes[i]);
	end

	-- Temp
	AreaBuilder.Recalculate();
	local biggest_area = Areas.FindBiggestArea(false);
	print("After Adding Hills: ", biggest_area:GetPlotCount());

	-- Place lakes before rivers so they may act as river sources
	AddLakes();

	-- River generation is affected by plot types, originating from highlands and preferring to traverse lowlands.
	AddRivers();

	AddFeatures();
	
	print("Adding cliffs");
	AddCliffs(plotTypes, terrainTypes);
	
	local args = {
		numberToPlace = GameInfo.Maps[Map.GetMapSize()].NumNaturalWonders,
	};

	local nwGen = NaturalWonderGenerator.Create(args);

	AreaBuilder.Recalculate();
	TerrainBuilder.AnalyzeChokepoints();
	TerrainBuilder.StampContinents();
	
	local resourcesConfig = MapConfiguration.GetValue("resources");
	local startConfig = MapConfiguration.GetValue("start");-- Get the start config
	local args = {
		resources = resourcesConfig,
		iWaterLux = 2,
		START_CONFIG = startConfig,
	}
	local resGen = ResourceGenerator.Create(args);

	print("Creating start plot database.");
	-- START_MIN_Y and START_MAX_Y is the percent of the map ignored for major civs' starting positions.
	local args = {
		MIN_MAJOR_CIV_FERTILITY = 175,
		MIN_MINOR_CIV_FERTILITY = 50, 
		MIN_BARBARIAN_FERTILITY = 1,
		START_MIN_Y = 15,
		START_MAX_Y = 15,
		LAND = true,
		START_CONFIG = startConfig,
	};
	local start_plot_database = AssignStartingPlots.Create(args)

	local GoodyGen = AddGoodies(g_iW, g_iH);
end

-- Input a Hash; Export width, height, and wrapX
function GetMapInitData(MapSize)
	local Width = 45;
	local Height = 49;
	local WrapX = false;
	return {Width = Width, Height = Height, WrapX = WrapX,}
end
-------------------------------------------------------------------------------
function GeneratePlotTypes()
	print("Generating Plot Types");
	local plotTypes = {};

	-- Start with it all as water
	for x = 0, g_iW - 1 do
		for y = 0, g_iH - 1 do
			local i = y * g_iW + x;
			local pPlot = Map.GetPlotByIndex(i);
			plotTypes[i] = g_PLOT_TYPE_OCEAN;
			TerrainBuilder.SetTerrainType(pPlot, g_TERRAIN_TYPE_OCEAN);
		end
	end

	-- Each land strip is defined by: Y, X Start, X End
	local xOffset = 0;
	local yOffset = 0;
		
	for i, v in ipairs(landStrips) do
		local y = v[1] + yOffset;
		local xStart = v[2] + xOffset;
		local xEnd = v[3] + xOffset; 
		for x = xStart, xEnd do
			local i = y * g_iW + x;
			local pPlot = Map.GetPlotByIndex(i);
			plotTypes[i] = g_PLOT_TYPE_LAND;
			TerrainBuilder.SetTerrainType(pPlot, g_TERRAIN_TYPE_GRASS);  -- temporary setting so can calculate areas
			g_iNumTotalLandTiles = g_iNumTotalLandTiles + 1;
		end
	end
		
	AreaBuilder.Recalculate();

	--	world_age
	local world_age_new = 5;
	local world_age_normal = 3;
	local world_age_old = 2;

	local world_age = MapConfiguration.GetValue("world_age");
	if (world_age == 1) then
		world_age = world_age_new;
	elseif (world_age == 2) then
		world_age = world_age_normal;
	elseif (world_age == 3) then
		world_age = world_age_old;
	else
		world_age = 2 + TerrainBuilder.GetRandomNumber(4, "Random World Age - Lua");
	end
	
	local args = {};
	args.world_age = world_age;
	args.iW = g_iW;
	args.iH = g_iH
	args.iFlags = g_iFlags;
	args.blendRidge = 10;
	args.blendFract = 1;
	args.extra_mountains = 4;
	plotTypes = ApplyTectonics(args, plotTypes);

	return plotTypes;
end

function InitFractal(args)

	if(args == nil) then args = {}; end

	local continent_grain = args.continent_grain or 2;
	local rift_grain = args.rift_grain or -1; -- Default no rifts. Set grain to between 1 and 3 to add rifts. - Bob
	local invert_heights = args.invert_heights or false;
	local polar = args.polar or true;
	local ridge_flags = args.ridge_flags or g_iFlags;

	local fracFlags = {};
	
	if(invert_heights) then
		fracFlags.FRAC_INVERT_HEIGHTS = true;
	end
	
	if(polar) then
		fracFlags.FRAC_POLAR = true;
	end
	
	if(rift_grain > 0 and rift_grain < 4) then
		local riftsFrac = Fractal.Create(g_iW, g_iH, rift_grain, {}, 6, 5);
		g_continentsFrac = Fractal.CreateRifts(g_iW, g_iH, continent_grain, fracFlags, riftsFrac, 6, 5);
	else
		g_continentsFrac = Fractal.Create(g_iW, g_iH, continent_grain, fracFlags, 6, 5);	
	end

	-- Use Brian's tectonics method to weave ridgelines in to the continental fractal.
	-- Without fractal variation, the tectonics come out too regular.
	--
	--[[ "The principle of the RidgeBuilder code is a modified Voronoi diagram. I 
	added some minor randomness and the slope might be a little tricky. It was 
	intended as a 'whole world' modifier to the fractal class. You can modify 
	the number of plates, but that is about it." ]]-- Brian Wade - May 23, 2009
	--
	local MapSizeTypes = {};
	for row in GameInfo.Maps() do
		MapSizeTypes[row.MapSizeType] = row.PlateValue;
	end
	local sizekey = Map.GetMapSize();

	local numPlates = MapSizeTypes[sizekey] or 4

	-- Blend a bit of ridge into the fractal.
	-- This will do things like roughen the coastlines and build inland seas. - Brian

	g_continentsFrac:BuildRidges(numPlates, {}, 1, 2);
end

function AddFeatures()
	print("Adding Features");

	-- Get Rainfall setting input by user.
	local rainfall = MapConfiguration.GetValue("rainfall");
	if rainfall == 4 then
		rainfall = 1 + TerrainBuilder.GetRandomNumber(3, "Random Rainfall - Lua");
	end

	local args = {rainfall = rainfall, iJunglePercent = 60, iMarshPercent = 12, iForestPercent = 9, iReefPercent = 15}	-- jungle & marsh max coverage
	local featuregen = FeatureGenerator.Create(args);

	featuregen:AddFeatures();
end
------------------------------------------------------------------------------
function GenerateTerrainTypesIndochina(plotTypes, iW, iH, iFlags, bNoCoastalMountains)
	print("Generating Terrain Types");
	local terrainTypes = {};

	local fracXExp = -1;
	local fracYExp = -1;
	local grain_amount = 3;

	grass = Fractal.Create(iW, iH, 
									grain_amount, iFlags, 
									fracXExp, fracYExp);
									
	iGrassTop = grass:GetHeight(100);
	iGrassBottom = grass:GetHeight(30);

	plains = Fractal.Create(iW, iH, 
									grain_amount, iFlags, 
									fracXExp, fracYExp);
																		
	iPlainsTop = plains:GetHeight(100);
	iPlainsBottom = plains:GetHeight(35);

	for iX = 0, iW - 1 do
		for iY = 0, iH - 1 do
			local index = (iY * iW) + iX;
			if (plotTypes[index] == g_PLOT_TYPE_OCEAN) then
				if (IsAdjacentToLand(plotTypes, iX, iY)) then
					terrainTypes[index] = g_TERRAIN_TYPE_COAST;
				else
					terrainTypes[index] = g_TERRAIN_TYPE_OCEAN;
				end
			end
		end
	end

	if (bNoCoastalMountains == true) then
		plotTypes = RemoveCoastalMountains(plotTypes, terrainTypes);
	end

	for iX = 0, iW - 1 do
		for iY = 0, iH - 1 do
			local index = (iY * iW) + iX;

			local iDistanceFromCenter = Map.GetPlotDistance (iX, iY, g_CenterX, g_CenterY);

			if (plotTypes[index] == g_PLOT_TYPE_MOUNTAIN) then
				terrainTypes[index] = g_TERRAIN_TYPE_DESERT_MOUNTAIN;

				local grassVal = grass:GetHeight(iX, iY);
				local plainsVal = plains:GetHeight(iX, iY);
				if ((grassVal >= iGrassBottom) and (grassVal <= iGrassTop)) then
					terrainTypes[index] = g_TERRAIN_TYPE_GRASS_MOUNTAIN;
				elseif ((plainsVal >= iPlainsBottom) and (plainsVal <= iPlainsTop)) then
					terrainTypes[index] = g_TERRAIN_TYPE_PLAINS_MOUNTAIN;
				end

			elseif (plotTypes[index] ~= g_PLOT_TYPE_OCEAN) then
				terrainTypes[index] = g_TERRAIN_TYPE_DESERT;
		
				local grassVal = grass:GetHeight(iX, iY);
				local plainsVal = plains:GetHeight(iX, iY);
				if ((grassVal >= iGrassBottom) and (grassVal <= iGrassTop)) then
					terrainTypes[index] = g_TERRAIN_TYPE_GRASS;
				elseif ((plainsVal >= iPlainsBottom) and (plainsVal <= iPlainsTop)) then
					terrainTypes[index] = g_TERRAIN_TYPE_PLAINS;
				end
			end
		end
	end

	local bExpandCoasts = true;

	if bExpandCoasts == false then
		return
	end

	print("Expanding coasts");
	for iI = 0, 2 do
		local shallowWaterPlots = {};
		for iX = 0, iW - 1 do
			for iY = 0, iH - 1 do
				local index = (iY * iW) + iX;
				if (terrainTypes[index] == g_TERRAIN_TYPE_OCEAN) then
					-- Chance for each eligible plot to become an expansion is 1 / iExpansionDiceroll.
					-- Default is two passes at 1/4 chance per eligible plot on each pass.
					if (IsAdjacentToShallowWater(terrainTypes, iX, iY) and TerrainBuilder.GetRandomNumber(4, "add shallows") == 0) then
						table.insert(shallowWaterPlots, index);
					end
				end
			end
		end
		for i, index in ipairs(shallowWaterPlots) do
			terrainTypes[index] = g_TERRAIN_TYPE_COAST;
		end
	end
	
	return terrainTypes; 
end
------------------------------------------------------------------------------
function FeatureGenerator:AddIceAtPlot(plot, iX, iY)
	return false;
end

------------------------------------------------------------------------------
function FeatureGenerator:AddReefAtPlot(plot, iX, iY)
	--Reef Check. First see if it can place the feature.
	if(TerrainBuilder.CanHaveFeature(plot, g_FEATURE_REEF)) then
		self.iNumReefablePlots = self.iNumReefablePlots + 1;
		if(math.ceil(self.iReefCount * 100 / self.iNumReefablePlots) <= self.iReefMaxPercent) then
				--Weight based on adjacent plots
				local iScore  = 3 * math.abs(iY - self.iNumEquator);
				local iAdjacent = TerrainBuilder.GetAdjacentFeatureCount(plot, g_FEATURE_REEF);

				if(iAdjacent == 0 ) then
					iScore = iScore + 100;
				elseif(iAdjacent == 1) then
					iScore = iScore + 125;
				elseif (iAdjacent == 2) then
					iScore = iScore  + 150;
				elseif (iAdjacent == 3 or iAdjacent == 4) then
					iScore = iScore + 175;
				else
					iScore = iScore + 10000;
				end

				if(TerrainBuilder.GetRandomNumber(200, "Resource Placement Score Adjust") >= iScore) then
					TerrainBuilder.SetFeatureType(plot, g_FEATURE_REEF);
					self.iReefCount = self.iReefCount + 1;
				end
		end
	end
end

-- override: northern forest bias
function FeatureGenerator:AddForestsAtPlot(plot, iX, iY)
	--Forest Check. First see if it can place the feature.
	
	if(TerrainBuilder.CanHaveFeature(plot, g_FEATURE_FOREST)) then
		if(math.ceil(self.iForestCount * 100 / self.iNumLandPlots) <= self.iForestMaxPercent) then
			--Weight based on adjacent plots if it has more than 3 start subtracting
			local iScore = 300 * (iY + 1);    -- co-ordinate system starts at zero
			local iAdjacent = TerrainBuilder.GetAdjacentFeatureCount(plot, g_FEATURE_FOREST);

			if(iAdjacent == 0 ) then
				iScore = iScore;
			elseif(iAdjacent == 1) then
				iScore = iScore + 50;
			elseif (iAdjacent == 2 or iAdjacent == 3) then
				iScore = iScore + 150;
			elseif (iAdjacent == 4) then
				iScore = iScore - 50;
			else
				iScore = iScore - 200;
			end
				
			if(TerrainBuilder.GetRandomNumber(300, "Resource Placement Score Adjust") <= iScore) then
				TerrainBuilder.SetFeatureType(plot, g_FEATURE_FOREST);
				self.iForestCount = self.iForestCount + 1;
			end
		end
	end
end

-- override: more southern jungle
function FeatureGenerator:AddJunglesAtPlot(plot, iX, iY)
	--Jungle Check. First see if it can place the feature.
	if(TerrainBuilder.CanHaveFeature(plot, g_FEATURE_JUNGLE)) then
		if(math.ceil(self.iJungleCount * 100 / self.iNumLandPlots) <= self.iJungleMaxPercent) then

			--Weight based on adjacent plots if it has more than 3 start subtracting
			local iScore = 350 * (1 - iY/g_iH);
			local iAdjacent = TerrainBuilder.GetAdjacentFeatureCount(plot, g_FEATURE_JUNGLE);

			if(iAdjacent == 0 ) then
				iScore = iScore;
			elseif(iAdjacent == 1) then
				iScore = iScore + 50;
			elseif (iAdjacent == 2 or iAdjacent == 3) then
				iScore = iScore + 150;
			elseif (iAdjacent == 4) then
				iScore = iScore - 50;
			else
				iScore = iScore - 200;
			end

			if(TerrainBuilder.GetRandomNumber(100, "Resource Placement Score Adjust") <= iScore) then
				TerrainBuilder.SetFeatureType(plot, g_FEATURE_JUNGLE);
				local terrainType = plot:GetTerrainType();

				if(terrainType == g_TERRAIN_TYPE_PLAINS_HILLS or terrainType == g_TERRAIN_TYPE_GRASS_HILLS) then
					TerrainBuilder.SetTerrainType(plot, g_TERRAIN_TYPE_PLAINS_HILLS);
				else
					TerrainBuilder.SetTerrainType(plot, g_TERRAIN_TYPE_PLAINS);
				end

				self.iJungleCount = self.iJungleCount + 1;
				return true;
			end

		end
	end

	return false
end