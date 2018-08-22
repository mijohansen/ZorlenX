COMBAT_SCANNER = {}
COMBAT_SCANNER.activeLooseEnemyCount = 0
COMBAT_SCANNER.myCCApplied = false
COMBAT_SCANNER.highestHealth = 999999
COMBAT_SCANNER.lowestHealth = 0
COMBAT_SCANNER.isBossFight = false
COMBAT_SCANNER.totemExists = false
COMBAT_SCANNER.targetAttackingMe = false
COMBAT_SCANNER.targetAttackingCloth = false
COMBAT_SCANNER.ccApplied = {}

function ZorlenX_ccIsApplied(cc_spellname)
	SheepSafe_ccIsApplied(cc_spellname)

end
-- UntargetedTarget
function ZorlenX_CombatScan()
  if self == nil then
   	self = sheepSafe
  end
  local last_scan_time = GetTime()
  local my_cc_is_applied = false
  local activeLooseEnemies = {}
  local enemiesTargetingYou = {}
  local highest_health = 0
  local lowest_health = 999999
  local is_boss_fight = false
  local activeLooseEnemyCount = 0

  
  COMBAT_SCANNER.last_scan_time = last_scan_time
  COMBAT_SCANNER.totemExists = false
  COMBAT_SCANNER.isBossFight = false
  
  for i = 1, 10 do
    TargetNearestEnemy()
    if not UnitExists("target") then
      break
    end
    local current_target_health = MobHealth_GetTargetCurHP()
    local current_target_name = UnitName("target").." - "..UnitLevel("target")
	local targetIsCrowdControlled = false
	for cc_spellname,applied in pairs(sheepSafe.ccs) do
		COMBAT_SCANNER.ccApplied[cc_spellname] = Zorlen_checkDebuff(cc_spellname,"target")
		if COMBAT_SCANNER.ccApplied[cc_spellname then
			targetIsCrowdControlled=true
		end
	end

    if Zorlen_isActiveEnemy("target") and not targetIsCrowdControlled then
      activeLooseEnemies[current_target_name] = 1
    end
	
	if Zorlen_isEnemyTargetingYou() then
		enemiesTargetingYou[current_target_name] = 1
	end

	if ZorlenX_mobIsBoss("target") then
	  COMBAT_SCANNER.isBossFight = true
	end
	
	if current_target_health and current_target_health > highest_health then
	  highest_health = current_target_health
	end
	if current_target_health and current_target_health < lowest_health then
	  lowest_health = current_target_health
	end
	
	if ZorlenX_IsTotem("target") then
	  COMBAT_SCANNER.totemExists = true
	end
  end
  
  -- counting active loose enemies
  for k,v in pairs(activeLooseEnemies) do
    activeLooseEnemyCount = activeLooseEnemyCount + 1
  end
  COMBAT_SCANNER.activeLooseEnemyCount = activeLooseEnemyCount
  COMBAT_SCANNER.highestHealth = highest_health
  COMBAT_SCANNER.lowestHealth = lowest_health
  COMBAT_SCANNER.isBossFight = is_boss_fight
  
  -- just getting back to the previous playertarget
  TargetUnit("playertarget")
  return my_cc_is_applied, activeLooseEnemyCount
end

function targetSheepable()
end

function targetLowestHP()
end

function targetShacklable()
end

function targetHighestHP()
end

function targetAttackingMe()
end

function targetAttackingMe()
end

function sheepSafe:FindUntargetedTarget()
  if not sheepSafeConfig.toggle then
    return false
  end
  if self == nil then
   	self = sheepSafe
  end
  local myCCisApplied = ZorlenX_ccIsApplied(sheepSafe.ccicon)
  local activeLooseEnemyCount = COMBAT_SCANNER.activeLooseEnemyCount
  local checkRaidAndPartyTargets = false
  if myCCisApplied then
    -- not targeting is done yet. 
    sheepSafe:p("Aborting: I have a cc already.");
    return false
  end
  --sheepSafe:p("SheepSafe thinks it have ".. activeLooseEnemyCount .. " active loose enemies.");
  if activeLooseEnemyCount < 2 then
    sheepSafe:p("Aborting: Too few loose enemies.");
    return false
  end
  -- main loop to find the actual target
  for i = 1, 10 do
    TargetNearestEnemy()
    if (not UnitCanAttack("player", "target")) then
      -- case where player was targeting nothing/friend, and	no enemies in vicinity
      break
    end
    

    if ZorlenX_mobIsBoss("target") then
      break
    end
    
    eName = UnitName("target")
    if eName and Zorlen_isActiveEnemy("target") then
      --sheepSafe.d(":: "..sheepSafe.nonil(name))
      --sheepSafe:p("checking target: ".. eName);
      if not self.inCombat then
        self.inCombat =	UnitExists("targettarget")
        -- probably should check that the target is player/party/raid
        -- but	this will do for now
      end
      
      local clear = true
      local wrkUnit
      local wrkTarget
      if checkRaidAndPartyTargets then
        for i =	1, GetNumRaidMembers() do
          wrkUnit	= "raid"..i
          wrkTarget = wrkUnit.."target"
          name = UnitName(wrkUnit)

          if not UnitIsUnit("player",wrkUnit) then
            if (name and UnitIsUnit("target", wrkTarget)) then
              sheepSafe:p(name.." is targeting "..eName..", skipping")
              clear =	false
              break
          end
          
          wrkUnit	= "raidpet"..i
          wrkTarget = wrkUnit.."target"

          petName	= UnitName(wrkUnit)
          if (petName and	UnitIsUnit("target", wrkTarget)) then
            sheepSafe:p(name.." ("..name.."'s pet) is targeting "..eName..", skipping")
            clear =	false
            break
          end
        end
      end

        for i =	1, GetNumPartyMembers()	do
          wrkUnit	= "party"..i
          wrkTarget = wrkUnit.."target"
          name = UnitName(wrkUnit)

          if (name and UnitIsUnit("target", wrkTarget)) then
            sheepSafe:p(name.." is targeting "..eName..", skipping")
            clear =	false
            break
          end

          wrkUnit	= "partypet"..i
          petName	= UnitName(wrkUnit)
          wrkTarget = wrkUnit.."target"
          
          if (petName and	UnitIsUnit("target", wrkTarget)) then
            sheepSafe:p(name.." ("..name.."'s pet) is targeting "..eName..", skipping")
            clear =	false
            break
          end
        end
     

        --	if clear then
        --		clear =	(UnitReaction("target",	"player") <= 3);
        --	end
      end
      if (UnitIsFriend("player","target")) then
        sheepSafe:d(UnitName("target").." is a friend");
      else
        sheepSafe:d(UnitName("target").." is not a friend");
      end
	
      creatureType = UnitCreatureType("target")
      
      if (clear and not string.find(self.validtargets, creatureType))	then
        sheepSafe:d("Can't "..self.ccverb2.." ".. eName .." : not "..self.validtargetsdesc)
        clear =	false
      end

      if clear then
        clear =	UnitExists("targettarget")
      end

      if clear then
        clear =	not sheepSafe:IsCrowdControlled()
      end
	
      if clear and self.class ~= "WARLOCK" then
        clear =	not sheepSafe:IsDotted()
      end
      
      if clear and (Zorlen_HealthPercent("target") > 60) and Nok_GetTargetCurHP() > UnitHealthMax("player") then
          sheepSafe:p(eName.." is an untargeted target.")
          return true
      end
      
    end
   end
   --sheepSafe:p("Sorry, no untargeted undotted hostile targets.")
   TargetUnit("playertarget")
   return false
end

FindUntargetedTarget = sheepSafe.FindUntargetedTarget
