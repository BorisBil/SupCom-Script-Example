-- ****************************************************************************
-- **
-- **  File     : /maps/faf_coop_defense_of_capella/faf_coop_defense_of_capella_script.lua
-- **  Author(s): Gently
-- **
-- **  Summary  : Main mission flow script for Defense of Capella
-- **
-- ****************************************************************************

local Objectives = import('/lua/ScenarioFramework.lua').Objectives
local ScenarioFramework = import('/lua/ScenarioFramework.lua')
local ScenarioPlatoonAI = import('/lua/ScenarioPlatoonAI.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local Utilities = import('/lua/utilities.lua')
local Cinematics = import('/lua/cinematics.lua')
local M2SeraAI = import('/maps/faf_coop_defense_of_capella/faf_coop_defense_of_capella_m2seraai.lua')
local M3SeraAI = import('/maps/faf_coop_defense_of_capella/faf_coop_defense_of_capella_m3seraai.lua')
local M3UEFAI = import('/maps/faf_coop_defense_of_capella/faf_coop_defense_of_capella_m3uefai.lua')

----------
-- Globals
----------

ScenarioInfo.Player1 = 1
ScenarioInfo.Seraphim = 2
ScenarioInfo.UEFCivilian = 3
ScenarioInfo.UEFAlly = 4
ScenarioInfo.Player2 = 5

----------
-- Locals
----------

local Player1 = ScenarioInfo.Player1
local Seraphim = ScenarioInfo.Seraphim
local UEFAlly = ScenarioInfo.UEFAlly
local UEFCivilian = ScenarioInfo.UEFCivilian
local Player2 = ScenarioInfo.Player2

local AssignedObjectives = {}
local Difficulty = ScenarioInfo.Options.Difficulty
local ExpansionTimer = ScenarioInfo.Options.Expansion

-- How long should we wait at the beginning of the NIS to allow slower machines to catch up?
local NIS1InitialDelay = 3

--------------
-- Debug only!
--------------
local Debug = false
local SkipNIS1 = false
local SkipIntro2 = false
local SkipIntro3 = false

----------
-- Startup
----------

function OnPopulate()
    ScenarioUtils.InitializeScenarioArmies()
	
	-- Sets Army Colors
	ScenarioFramework.SetUEFPlayerColor(Player1)
	ScenarioFramework.SetSeraphimColor(Seraphim)
	ScenarioFramework.SetUEFAlly1Color(UEFAlly)
	ScenarioFramework.SetUEFAlly2Color(UEFCivilian)
	
	-- Coop Colours
    local colors = {
        ['Player2'] = {71, 114, 148},
	}
	local tblArmy = ListArmies()
    for army, color in colors do
        if tblArmy[ScenarioInfo[army]] then
            SetArmyColor(ScenarioInfo[army], unpack(color))
        end
    end
	
	-- Unit Cap
    ScenarioFramework.SetSharedUnitCap(600)
	
	-- Disable friendly AI sharing resources to players
    GetArmyBrain(UEFAlly):SetResourceSharing(false)
	GetArmyBrain(UEFCivilian):SetResourceSharing(false)
end
   
function OnStart()
	--------------------
    -- Build Restrictions
    --------------------
	for _, player in ScenarioInfo.HumanPlayers do
        ScenarioFramework.AddRestriction(player,
            categories.xeb2306 + -- UEF Heavy Point Defense
            categories.xel0305 + -- UEF Percival
            categories.xel0306 + -- UEF Mobile Missile Platform
			categories.xeb0104 + -- UEF Engineering Station 1
            categories.xeb0204 + -- UEF Engineering Station 2
            categories.xea0306 + -- UEF Heavy Air Transport
			categories.SUBCOMMANDER +
			categories.EXPERIMENTAL +
			categories.GATE
		)
	end
	
	-- Initialize camera
    if not SkipNIS1 then
		ForkThread (NIS1)
    end
	if SkipNIS1 then
		ForkThread (Mission1)
	end	
end

------------
-- NIS1 Scene
------------
function NIS1()
	if not SkipNIS1 then
	
	
		-- Set NIS area
		ScenarioFramework.SetPlayableArea('nis1', false)
		
		local platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', 'stage1_air', 'NoFormation')
		for _, unit in platoon:GetPlatoonUnits() do
		ScenarioFramework.GroupPatrolChain({unit}, 'stage1_air_chain_player')
		maxHealth = unit:GetMaxHealth()
        newHealth = maxHealth * (Random(1, 100) / 100)
        unit:SetHealth(unit, newHealth)
	end
	local platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', 'stage1_land', 'NoFormation')
		for _, unit in platoon:GetPlatoonUnits() do
		ScenarioFramework.GroupPatrolChain({unit}, 'stage1_land_chain_player')
		maxHealth = unit:GetMaxHealth()
        newHealth = maxHealth * (Random(1, 100) / 100)
        unit:SetHealth(unit, newHealth)
	end
	local platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEFCivilian', 'stage1_air', 'NoFormation')
		for _, unit in platoon:GetPlatoonUnits() do
		ScenarioFramework.GroupPatrolChain({unit}, 'stage1_air_chain_civilian')
	end
	local platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEFCivilian', 'stage1_land', 'NoFormation')
		for _, unit in platoon:GetPlatoonUnits() do
		ScenarioFramework.GroupPatrolChain({unit}, 'stage1_land_chain_civilian')
	end
	dBuildings = ScenarioUtils.CreateArmyGroup('Player1', 'stage1_damagedbuildings')
	for _, unit in dBuildings do
		maxHealth = unit:GetMaxHealth()
        newHealth = maxHealth * (Random(1, 100) / 100)
        unit:SetHealth(unit, newHealth)
	end
	ScenarioInfo.Gate = ScenarioUtils.CreateArmyUnit( 'UEFCivilian', 'Gate')
	ScenarioUtils.CreateArmyGroup('Player1', 'stage1_buildings')
	ScenarioUtils.CreateArmyGroup('UEFCivilian', 'stage1_buildingsmilitary')
	ScenarioInfo.Civ1 = ScenarioUtils.CreateArmyGroup('UEFCivilian', 'stage1_buildingscivilian')
	ScenarioUtils.CreateArmyGroup('Player1', 'stage1_wrecks', true)
        Cinematics.EnterNISMode()
		
		-- Vision for NIS location
        local nis1_vismark1 = ScenarioFramework.CreateVisibleAreaLocation(30, 'nis1_vismark1', 10, ArmyBrains[Player1])
        local nis1_vismark2 = ScenarioFramework.CreateVisibleAreaLocation(30, 'nis1_vismark2', 10, ArmyBrains[Player1])
		
		-- Spawn units
		ForkThread(NIS1Units)
		
		Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('nis1cam1'))
		WaitSeconds(5)
		Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('nis1cam2'), 3)
		WaitSeconds(5)
		Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('nis1cam3'), 3)
		WaitSeconds(5)
		Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('playercam'), 1)
		ForkThread(
			function()
				WaitSeconds(2)
				nis1_vismark1:Destroy()
				nis1_vismark2:Destroy()
				WaitSeconds(2)
				ScenarioFramework.ClearIntel(ScenarioUtils.MarkerToPosition('nis1_vismark1'), 40)
				ScenarioFramework.ClearIntel(ScenarioUtils.MarkerToPosition('nis1_vismark2'), 40)
			end
		)
		Cinematics.ExitNISMode()
	end
	Mission1()
end

function Mission1()

	-- Set mission 1 area
    ScenarioFramework.SetPlayableArea('stage1', false)

	ForkThread(
		function()
		ScenarioInfo.CoopCDR = {}
		local tblArmy = ListArmies()
		coop = 1
		for iArmy, strArmy in pairs(tblArmy) do
			if iArmy >= ScenarioInfo.Coop1 then
				ScenarioInfo.CoopCDR[coop] = ScenarioFramework.SpawnCommander(strArmy, 'Commander', 'Warp', true, true, PlayerDeath)
				table.insert(ScenarioInfo.CoopCDR, ScenarioInfo.CoopCDR[coop])
				IssueMove({ScenarioInfo.CoopCDR[coop]}, ScenarioUtils.MarkerToPosition('stage1_player_acu_walk'))
				coop = coop + 1
				WaitSeconds(5)
				end
			end
		end
	)
	
	--Primary Objectives
	ScenarioInfo.M1P1 = Objectives.Protect(
    'primary',                      -- type
    'incomplete',                   -- complete
    'Protect UEF Civilians',    -- title
    'This UEF town is under seige by the Seraphim, defend them from the aliens.',  -- description
    {
        Units = ScenarioInfo.Civ1,              -- target
        MarkUnits = true,
		ShowProgress = false,
		NumRequired = '15',
	}
	)
	ScenarioInfo.M1P1:AddResultCallback(
		function(result)
			if not result then
				ForkThread(Mission_Failed)
			end
		end
	)
	table.insert(AssignedObjectives, ScenarioInfo.M1P1)
	ScenarioInfo.M1P2 = Objectives.Protect(
		'primary',
		'incomplete',
		'Protect the Gate',
		'This gate is one of our last ties to Capella, protect it at any cost',
		{
			MarkUnits = true,
			Units = {ScenarioInfo.Gate},
		}
	)
	ScenarioInfo.M1P2:AddResultCallback(
        function(result)
            if not result then
				ForkThread(Mission_Failed)
			end
		end
	)
	table.insert(AssignedObjectives, ScenarioInfo.M1P2)
	
	--Kill off NIS units
	ForkThread(NIS1KillUnits)
	
	--Spawn Mission 1 attack waves
	WaitSeconds(30 / Difficulty)
	local saa1 = ScenarioUtils.CreateArmyGroup('Seraphim', 'stage1_aa1')
	for k, v in saa1 do
        IssueAggressiveMove({v}, ScenarioUtils.MarkerToPosition('s2a1d'))
    end
	WaitSeconds(30 / Difficulty)
	local s1a1 = ScenarioUtils.CreateArmyGroup('Seraphim', 'stage1_al1')
	for k, v in s1a1 do
        IssueAggressiveMove({v}, ScenarioUtils.MarkerToPosition('s2a2d'))
    end
	WaitSeconds(100 / Difficulty)
	local s1a2 = ScenarioUtils.CreateArmyGroup('Seraphim', 'stage1_al2')
	for k, v in s1a2 do
        IssueAggressiveMove({v}, ScenarioUtils.MarkerToPosition('s2a2d'))
    end
	WaitSeconds(10 / Difficulty)
	local saa2 = ScenarioUtils.CreateArmyGroup('Seraphim', 'stage1_aa2')
	for k, v in saa2 do
        IssueAggressiveMove({v}, ScenarioUtils.MarkerToPosition('s2a3c'))
    end
	WaitSeconds(100 / Difficulty)
	local s1a3 = ScenarioUtils.CreateArmyGroup('Seraphim', 'stage1_al3')
	for k, v in s1a3 do
        IssueAggressiveMove({v}, ScenarioUtils.MarkerToPosition('s2a4d'))
	end
	WaitSeconds(20 / Difficulty)
	
	--Objective is to kill the last wave
	ScenarioInfo.M1P3 = Objectives.Kill(
		'primary',
		'incomplete',
		'Destroy the Units',
		'This is the last wave of Seraphim units, destroy them.',
		{
			Units = s1a3,
			MarkUnits = true,
		}
	)
	for k, v in s1a3 do
        IssueAggressiveMove({v}, ScenarioUtils.MarkerToPosition('s2a2d'))
	end
	ScenarioInfo.M1P3:AddResultCallback(
        function(result)
            if result then
				ForkThread(FinishMission1)
			end
		end
	)
	table.insert(AssignedObjectives, ScenarioInfo.M1P3)
end

function IntroMission2()
	if not SkipIntro2 then
		Cinematics.EnterNISMode()

		--Visible areas for intro to mission 2
		local stage2_vismarker1 = ScenarioFramework.CreateVisibleAreaLocation(30, 'stage2_vismarker1', 10, ArmyBrains[Player1])
        local stage2_vismarker2 = ScenarioFramework.CreateVisibleAreaLocation(30, 'stage2_vismarker2', 10, ArmyBrains[Player1])
		
		Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('introstage2a'))
		WaitSeconds(5)
		Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('introstage2b'), 3)
		WaitSeconds(5)
		ForkThread(
			function()
				WaitSeconds(2)
				stage2_vismarker1:Destroy()
				stage2_vismarker2:Destroy()
				WaitSeconds(2)
				if (Difficulty == 3) then
					ScenarioFramework.ClearIntel(ScenarioUtils.MarkerToPosition('stage2_vismarker1'), 40)
					ScenarioFramework.ClearIntel(ScenarioUtils.MarkerToPosition('stage2_vismarker2'), 40)
				end
			end
		)
		Cinematics.ExitNISMode()
	end
end

function Mission2()
	
	--Set up area and base before the player gets sent into NIS mode
	ScenarioFramework.SetPlayableArea('stage2', true)
	ScenarioUtils.CreateArmyGroup('Seraphim', 'stage2_engies')
	local platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'stage2_lg1', 'NoFormation')
		for _, unit in platoon:GetPlatoonUnits() do
		ScenarioFramework.GroupPatrolChain({unit}, 'stage2_patrol1')
	end
	local platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'stage2_lg2', 'NoFormation')
		for _, unit in platoon:GetPlatoonUnits() do
		ScenarioFramework.GroupPatrolChain({unit}, 'stage2_patrol2')
	end
	
	--Base AI
	M2SeraAI.SeraphimM2BaseAI()
	
	--Cinematics
	ForkThread(IntroMission2)
	
	--Objectives
	ScenarioInfo.M2P1 = Objectives.CategoriesInArea(
    'primary',                      -- type
    'incomplete',                   -- complete
    'Destroy the Seraphim forward base',    -- title
    'The Seraphim are attempting to build a proxy base near the gate and artillery your position, destroy them.',  -- description
    'kill',                         -- action
    {                               -- target
        MarkUnits = true,
        Requirements = {
            {   
                Area = 'serabasestage2',
                Category = categories.FACTORY,
                CompareOp = '<=',
                Value = 0,
                ArmyIndex = Seraphim,
            },
        },
    }
	)
	ScenarioInfo.M2P1:AddResultCallback(
    function(result)
        if result then
            ForkThread(FinishMission2)
			for k, v in AssignedObjectives do
            if(v and v.Active) then
                v:ManualResult(true)
            end
        end
        end
    end
	)
end

function IntroMission3()
	
	ScenarioInfo.M3P1 = Objectives.Protect(
		'primary',
		'incomplete',
		'Protect the Gate',
		'This gate is one of our last ties to Capella, protect it at any cost',
		{
			MarkUnits = true,
			Units = {ScenarioInfo.Gate},
		}
	)
	ScenarioInfo.M3P1:AddResultCallback(
        function(result)
            if not result then
				ForkThread(Mission_Failed)
			end
		end
	)
	table.insert(AssignedObjectives, ScenarioInfo.M3P1)
	
	if not SkipIntro2 then
		Cinematics.EnterNISMode()

		--Visible areas for intro to mission 3
		local M3_vismarker1 = ScenarioFramework.CreateVisibleAreaLocation(50, 'M3_vismarker1', 21, ArmyBrains[Player1])
        local M3_vismarker2 = ScenarioFramework.CreateVisibleAreaLocation(50, 'M3_vismarker2', 21, ArmyBrains[Player1])
		local M3_vismarker3 = ScenarioFramework.CreateVisibleAreaLocation(50, 'M3_vismarker3', 21, ArmyBrains[Player1])
		
		Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('introm3a'))
		WaitSeconds(5)
		Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('introm3b'), 3)
		WaitSeconds(5)
		Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('introm3c'), 3)
		WaitSeconds(5)
		Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('introm3d'), 3)
		WaitSeconds(5)
		Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('introm3e'), 3)
		WaitSeconds(5)
		ForkThread(
			function()
				WaitSeconds(2)
				M3_vismarker1:Destroy()
				M3_vismarker2:Destroy()
				M3_vismarker3:Destroy()
				WaitSeconds(2)
				if (Difficulty == 3) then
					ScenarioFramework.ClearIntel(ScenarioUtils.MarkerToPosition('M3_vismarker1'), 60)
					ScenarioFramework.ClearIntel(ScenarioUtils.MarkerToPosition('M3_vismarker2'), 60)
					ScenarioFramework.ClearIntel(ScenarioUtils.MarkerToPosition('M3_vismarker3'), 60)
				end
			end
		)
	Cinematics.ExitNISMode()
	end
end

function Mission3()
	
	--Set up area
	ScenarioFramework.SetPlayableArea('stage3', true)
	
	--Set up Seraphim base
	ScenarioUtils.CreateArmyGroup('Seraphim', 'M3_engies')
	local platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M3_slg1', 'GrowthFormation')
	ScenarioFramework.PlatoonPatrolChain(platoon, 'M3_slg1')
	local platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M3_slg2', 'GrowthFormation')
	ScenarioFramework.PlatoonPatrolChain(platoon, 'M3_slg2')
	local platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M3_sag', 'NoFormation')
		for _, unit in platoon:GetPlatoonUnits() do
			ScenarioFramework.GroupPatrolChain({unit}, 'M3_sag')
		end
	
	--Seraphim base AI
	M3SeraAI.SeraphimM3BaseAI()
	
	--Set up UEF base and Civilian city
	ScenarioUtils.CreateArmyGroup('UEFAlly', 'M3_engies')
	local platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEFAlly', 'M3_lg1', 'GrowthFormation')
	ScenarioFramework.PlatoonPatrolChain(platoon, 'M3_landchain1')
	local platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEFAlly', 'M3_lg2', 'GrowthFormation')
	ScenarioFramework.PlatoonPatrolChain(platoon, 'M3_landchain2')
	local platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEFAlly', 'M3_ag', 'NoFormation')
		for _, unit in platoon:GetPlatoonUnits() do
			ScenarioFramework.GroupPatrolChain({unit}, 'M3_uag')
		end
	ScenarioInfo.Civ2 = ScenarioUtils.CreateArmyGroup('UEFCivilian', 'M3_buildingscivilian')
	
	--UEF base AI
	M3UEFAI.UEFM3BaseAI()
	
	--Cinematics
	ForkThread(IntroMission3)
	
	--Spawn trucks and gate them out
	ScenarioFramework.M3GateTrigger = ScenarioFramework.CreateAreaTrigger(SendTruckThroughGate, ScenarioUtils.AreaToRect('gate'),
       (categories.uec0001), false, false, ArmyBrains[ScenarioInfo.UEFCivilian], 3, true)
	local truck1 = ScenarioUtils.CreateArmyUnit('UEFCivilian', 'truck1')
	ScenarioFramework.CreateUnitToMarkerDistanceTrigger(SendTruckThroughGate, truck1, ScenarioUtils.MarkerToPosition('gate_truck'), 10)
	IssueMove({truck1}, ScenarioUtils.MarkerToPosition('gate_truck'))
    
	local truck2 = ScenarioUtils.CreateArmyUnit('UEFCivilian', 'truck2')
	ScenarioFramework.CreateUnitToMarkerDistanceTrigger(SendTruckThroughGate, truck2, ScenarioUtils.MarkerToPosition('gate_truck'), 10)
	IssueMove({truck2}, ScenarioUtils.MarkerToPosition('gate_truck'))
	
	local truck3 = ScenarioUtils.CreateArmyUnit('UEFCivilian', 'truck3')
	ScenarioFramework.CreateUnitToMarkerDistanceTrigger(SendTruckThroughGate, truck3, ScenarioUtils.MarkerToPosition('gate_truck'), 10)
	IssueMove({truck3}, ScenarioUtils.MarkerToPosition('gate_truck'))
	
	local truck4 = ScenarioUtils.CreateArmyUnit('UEFCivilian', 'truck4')
	ScenarioFramework.CreateUnitToMarkerDistanceTrigger(SendTruckThroughGate, truck4, ScenarioUtils.MarkerToPosition('gate_truck'), 10)
	IssueMove({truck4}, ScenarioUtils.MarkerToPosition('gate_truck'))
	
	local truck5 = ScenarioUtils.CreateArmyUnit('UEFCivilian', 'truck5')
	ScenarioFramework.CreateUnitToMarkerDistanceTrigger(SendTruckThroughGate, truck5, ScenarioUtils.MarkerToPosition('gate_truck'), 10)
	IssueMove({truck5}, ScenarioUtils.MarkerToPosition('gate_truck'))
	
	local truck6 = ScenarioUtils.CreateArmyUnit('UEFCivilian', 'truck6')
	ScenarioFramework.CreateUnitToMarkerDistanceTrigger(SendTruckThroughGate, truck6, ScenarioUtils.MarkerToPosition('gate_truck'), 10)
	IssueMove({truck6}, ScenarioUtils.MarkerToPosition('gate_truck'))
	
	local truck7 = ScenarioUtils.CreateArmyUnit('UEFCivilian', 'truck7')
	ScenarioFramework.CreateUnitToMarkerDistanceTrigger(SendTruckThroughGate, truck7, ScenarioUtils.MarkerToPosition('gate_truck'), 10)
	IssueMove({truck7}, ScenarioUtils.MarkerToPosition('gate_truck'))
	
	--Objectives
	ScenarioInfo.M3P2 = Objectives.CategoriesInArea(
    'primary',                      -- type
    'incomplete',                   -- complete
    'Destroy the Seraphim base threatening the civilians.',    -- title
    'The Seraphim have a large base nearby, they must be eliminated.',  -- description
    'kill',                         -- action
    {                               -- target
        MarkUnits = true,
        Requirements = {
            {   
                Area = 'serabasestage3',
                Category = categories.FACTORY,
                CompareOp = '<=',
                Value = 0,
                ArmyIndex = Seraphim,
            },
        },
    }
	)
	ScenarioInfo.M3P2:AddResultCallback(
    function(result)
        if result then
            ForkThread(FinishMission3)
        end
    end
	)
	ScenarioInfo.M3P3 = Objectives.Protect(
    'primary',                      -- type
    'incomplete',                   -- complete
    'Protect UEF Civilians',    -- title
    'This UEF town is under seige by the Seraphim, defend them from the aliens.',  -- description
    {
        Units = ScenarioInfo.Civ2,              -- target
        MarkUnits = true,
		ShowProgress = false,
		NumRequired = '35',
	}
	)
	ScenarioInfo.M3P3:AddResultCallback(
		function(result)
			if not result then
				ForkThread(Mission_Failed)
			end
		end
	)
	table.insert(AssignedObjectives, ScenarioInfo.M3P3)
	WaitSeconds(60)
	local units = GetUnitsInRect(ScenarioUtils.AreaToRect('civ1'))
    for k, v in units do
        if v and not v:IsDead() and (v:GetAIBrain() == ArmyBrains[UEFCivilian]) then
            ScenarioFramework.GiveUnitToArmy(v, Player1)
        end
    end
end

function Mission4()

end

function FinishMission1()
    Mission2()
end

function FinishMission2()
    Mission3()
end

function FinishMission3()
    Mission4()
end

function NIS1Units()
	
	-- Spawn units for introductory battle
	ScenarioInfo.nis1units = {}
	local nis1group1 = ScenarioUtils.CreateArmyGroup('Seraphim', 'nis1_landunits')
	table.insert(ScenarioInfo.nis1units, nis1group1)
	
	local nis1group2 = ScenarioUtils.CreateArmyGroup('Seraphim', 'nis1_airunits')
	table.insert(ScenarioInfo.nis1units, nis1group2)
	
	ScenarioUtils.CreateArmyGroup('Seraphim', 'nis1_se')
	
	local nis1group3 = ScenarioUtils.CreateArmyGroup('UEFAlly', 'nis1_landunits')
	table.insert(ScenarioInfo.nis1units, nis1group3)
	for _, unit in nis1group3 do
		ScenarioFramework.GroupPatrolChain({unit}, 'nis1_uefpatrol1')
	end
	
	local nis1group4 = ScenarioUtils.CreateArmyGroup('UEFAlly', 'nis1_airunits')
	table.insert(ScenarioInfo.nis1units, nis1group4)
	for _, unit in nis1group4 do
		ScenarioFramework.GroupPatrolChain({unit}, 'nis1_uefpatrol2')
	end
	
	local nis1uefbuildings = ScenarioUtils.CreateArmyGroup('UEFAlly', 'nis1_buildings')
	table.insert(ScenarioInfo.nis1units, nis1uefbuildings)
	
	for k, v in nis1group1 do
        IssueAggressiveMove({v}, ScenarioUtils.MarkerToPosition('nis1_seramovea'))
    end
	for k, v in nis1group2 do
        IssueAggressiveMove({v}, ScenarioUtils.MarkerToPosition('nis1_seramovea'))
    end
end

function Kill_Game()
    UnlockInput()
    ScenarioFramework.EndOperation(ScenarioInfo.OpComplete, ScenarioInfo.OpComplete, true)
end

function Mission_Failed()
    ScenarioFramework.EndOperationSafety()
    ScenarioFramework.FlushDialogueQueue()
    for k, v in AssignedObjectives do
        if(v and v.Active) then
            v:ManualResult(false)
        end
    end
    ScenarioInfo.OpComplete = false
    ForkThread(
        function()
            WaitSeconds(5)
            UnlockInput()
            Kill_Game()
        end
    )
end

function PlayerDeath()
    if (not ScenarioInfo.OpEnded) then
        ScenarioFramework.CDRDeathNISCamera(ScenarioInfo.CoopCDR[coop])
        ScenarioFramework.EndOperationSafety()
        ScenarioInfo.OpComplete = false
        for _, v in AssignedObjectives do
            if(v and v.Active) then
                v:ManualResult(false)
            end
        end
        ForkThread(
            function()
                WaitSeconds(3)
                UnlockInput()
                KillGame()
            end
        )
    end
end

function DestroyUnit(unit)
    unit:Destroy()
end

function NIS1KillUnits()
    local flipToggle = false
    for _, group in ScenarioInfo.nis1units do
        for _, unit in group do
            if unit and not unit.Dead then
                unit:Kill()
                if flipToggle then
                    WaitSeconds(0.1)
                    flipToggle = false
                else
                    WaitSeconds(0.1)
                    flipToggle = true
                end
            end
        end
    end
end

function SendTruckThroughGate(units)
    for k, truck in units do
        if not truck.GateStarted then
            truck.GateStarted = true
            ScenarioFramework.FakeTeleportUnit(truck, true)
        end
    end
end
		
		