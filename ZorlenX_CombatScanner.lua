COMBAT_SCANNER = {}

function ZorlenX_ccIsApplied(cc_spellname)
  return COMBAT_SCANNER.ccsApplied[cc_spellname]
end

-- /script local cs = ZorlenX_CombatScan() ZorlenX_Debug(cs)
-- UntargetedTarget
function ZorlenX_CombatScan()
  if COMBAT_SCANNER.lastScanTime and (COMBAT_SCANNER.lastScanTime + 1) > GetTime() then
    return COMBAT_SCANNER
  end
  if self == nil then
    self = sheepSafe
  end
  -- resetting values
  COMBAT_SCANNER.lastScanDuration = 0
  COMBAT_SCANNER.lastScanCount = 0
  COMBAT_SCANNER.lastScanTime = GetTime()
  COMBAT_SCANNER.activeLooseEnemyCount = 0
  COMBAT_SCANNER.myCCApplied = false
  COMBAT_SCANNER.highestHealth = nil
  COMBAT_SCANNER.lowestHealth = nil
  COMBAT_SCANNER.isBossFight = false
  COMBAT_SCANNER.totemExists = false
  COMBAT_SCANNER.targetAttackingMe = false
  COMBAT_SCANNER.targetAttackingCloth = false
  COMBAT_SCANNER.ccAbleTargetExists = false
  COMBAT_SCANNER.ccsApplied = {}

  --defining some locals
  local activeLooseEnemies = {}
  local enemiesTargetingYou = {}
  local castersWithAggro = {}
  local enemyesAggroingCasters= {}


  for cc_spellname,applied in pairs(sheepSafe.ccs) do
    COMBAT_SCANNER.ccsApplied[cc_spellname] = false
  end

  for i = 1, 10 do
    TargetNearestEnemy()
    if not UnitExists("target") then
      break
    end
    -- determines the CCed targets we have..
    local targetIsCrowdControlled = false
    for cc_spellname,applied in pairs(sheepSafe.ccs) do
      if Zorlen_checkDebuff(cc_spellname,"target") then
        COMBAT_SCANNER.ccsApplied[cc_spellname] = true
        targetIsCrowdControlled	=	true
      end
    end
    if ZorlenX_IsTotem("target") then
      COMBAT_SCANNER.totemExists = true
    end

    local current_target_name = UnitName("target").." - "..UnitLevel("target")
    if Zorlen_isEnemyTargetingYou() then
      enemiesTargetingYou[current_target_name] = 1
    end

    if Zorlen_isActiveEnemy("target") and not targetIsCrowdControlled then
      activeLooseEnemies[current_target_name] = 1
      if ZorlenX_isUnitCCable("target") then
        COMBAT_SCANNER.ccAbleTargetExists = true
      end
    end

    if Zorlen_isActiveEnemy("target") and UnitExists("targettarget") and UnitIsFriend("player","targettarget") and isSoftTarget("targettarget") then
      enemyesAggroingCasters[current_target_name] = true
      castersWithAggro[UnitName("targettarget")] = true
    end

    if Zorlen_isActiveEnemy("target") and ZorlenX_mobIsBoss("target") then
      COMBAT_SCANNER.isBossFight = true
    end

    -- health targeting
    local TargetHealth = UnitHealth("target")
    if Zorlen_isActiveEnemy("target") and not targetIsCrowdControlled and TargetHealth then
      if not COMBAT_SCANNER.highestHealth or TargetHealth > COMBAT_SCANNER.highestHealth then
        COMBAT_SCANNER.highestHealth = TargetHealth
      end
      if not COMBAT_SCANNER.lowestHealth or TargetHealth < COMBAT_SCANNER.lowestHealth then
        COMBAT_SCANNER.lowestHealth = TargetHealth
      end
    end
  end

  -- counting active loose enemies++
  COMBAT_SCANNER.activeLooseEnemyCount = ZorlenX_tableLength(activeLooseEnemies)
  COMBAT_SCANNER.enemiesTargetingYouCount = ZorlenX_tableLength(enemiesTargetingYou)
  COMBAT_SCANNER.castersWithAggro = ZorlenX_tableKeys(castersWithAggro)
  COMBAT_SCANNER.castersWithAggroCount = ZorlenX_tableLength(castersWithAggro)
  COMBAT_SCANNER.lastScanDuration = GetTime() - COMBAT_SCANNER.lastScanTime

  return COMBAT_SCANNER
end



function targetLowestHP()
  if not COMBAT_SCANNER.lowestHealth then
    return false
  end
  for i = 1, 6 do
    TargetNearestEnemy()
    local TargetHealth = UnitHealth("target")
    if Zorlen_isActiveEnemy("target") and (COMBAT_SCANNER.lowestHealth + 10) > TargetHealth then
      return true
    end
  end
end

function targetHighestHP()
  if not COMBAT_SCANNER.highestHealth then
    return false
  end
  if Zorlen_isActiveEnemy("target") and (COMBAT_SCANNER.highestHealth - 10) < TargetHealth and not ZorlenX_IsCrowdControlled() then
    return true
  end
end

function targetEnemyAttackingMe()
  if not COMBAT_SCANNER.enemiesTargetingYouCount > 0 then
    return false
  end
  for i = 1, 6 do
    TargetNearestEnemy()
    if Zorlen_isEnemyTargetingYou() then
      return true
    end
  end
end

function targetEnemyAggroingCasters()
  if not COMBAT_SCANNER.castersWithAggroCount > 0 then
    return false
  end
  for i = 1, 6 do
    TargetNearestEnemy()
    if Zorlen_isActiveEnemy() and UnitIsFriend("player","targettarget") and isSoftTarget("targettarget") then
      return true
    end
  end
end

function targetBoss()
  if not COMBAT_SCANNER.isBossFight then
    return false
  end
  for i = 1, 6 do
    TargetNearestEnemy()
    if Zorlen_isActiveEnemy() and ZorlenX_mobIsBoss("target") then
      return true
    end
  end
end

function ZorlenX_FindUntargetedTarget()
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

  if activeLooseEnemyCount < 2 then
    sheepSafe:p("Aborting: Too few loose enemies.");
    return false
  end

  if not COMBAT_SCANNER.ccAbleTargetExists then
    return false
  end
  -- main loop to find the actual target
  for i = 1, 6 do
    TargetNearestEnemy()
    TargetName = UnitName("target")

    if not UnitCanAttack("player", "target") or not TargetName or not Zorlen_isActiveEnemy("target") then
      -- case where player was targeting nothing/friend, and no enemies in vicinity
      break
    end
    if ZorlenX_isUnitCCable("target") then
      return true
    end
  end
end

function ZorlenX_isUnitCCable(unit) 
  if self == nil then
    self = sheepSafe
  end
  if ZorlenX_mobIsBoss("target") then
    return false
  end
  local targetCreatureType = UnitCreatureType("target")
  if creaturetype and not string.find(self.validtargets, targetCreatureType) then
    return false
  end

  if ZorlenX_IsCrowdControlled() then
    return false
  end

  if self.class ~= "WARLOCK" and sheepSafe:IsDotted() then
    return false
  end
  -- ok this seem to be a good target...
  if Zorlen_HealthPercent("target") > 60 and ZorlenX_GetTargetCurHP() > UnitHealthMax("player") then
    sheepSafe:p(TargetName.." is an untargeted target.")
    return true
  end
end 

