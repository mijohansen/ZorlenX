COMBAT_SCANNER = {}

-- @TODO Need to implement 

function ZorlenX_resetCombatScanner()
  COMBAT_SCANNER.scanTime = 0
  COMBAT_SCANNER.lastTarget = false
  COMBAT_SCANNER.looseEnemies = 0
  COMBAT_SCANNER.activeEnemies = 0
  COMBAT_SCANNER.totalEnemyHP = 0
  COMBAT_SCANNER.castersWithAggroCount = 0
  COMBAT_SCANNER.myCCApplied = false
  COMBAT_SCANNER.highestHealth = false
  COMBAT_SCANNER.lowestHealth = false
  COMBAT_SCANNER.isBossFight = false
  COMBAT_SCANNER.totemExists = false
  COMBAT_SCANNER.enemiesAggroPlayer = 0
  COMBAT_SCANNER.ccAbleTargetExists = false
  COMBAT_SCANNER.ccsApplied = {}
  return COMBAT_SCANNER
end

function ZorlenX_CurrentTargetFingerPrint()
  if UnitExists("target") then
    return UnitName("target") .. "/" .. UnitLevel("target") .. "/" .. UnitHealth("target")
  end
end

-- /script local cs = ZorlenX_CombatScan() ZorlenX_Debug(cs)
function ZorlenX_CombatScan()

  if ZorlenX_TimeLock("CombatScan",1) then
    return COMBAT_SCANNER
  end

  -- resetting values
  ZorlenX_resetCombatScanner()
  if not UnitAffectingCombat("player") then
    return COMBAT_SCANNER
  end

  --defining some locals
  local activeLooseEnemies = {}
  local enemiesAggroPlayer = {}
  local castersWithAggro = {}
  local enemyesAggroingCasters = {}
  local enemiesAoeRange = {}
  local scanStart = GetTime()
  local activeEnemiesHp = {}

  for cc_spellname,applied in pairs(sheepSafe.ccs) do
    COMBAT_SCANNER.ccsApplied[cc_spellname] = false
  end

  COMBAT_SCANNER.lastTarget = ZorlenX_CurrentTargetFingerPrint()

  for i = 1, 12 do
    TargetNearestEnemy()
    if not UnitExists("target") then
      break
    end
    local current_target_name = ZorlenX_CurrentTargetFingerPrint()

    -- break iteration if we probably have orignial target...
    if i > 8 and COMBAT_SCANNER.lastTarget == current_target_name then
      break
    end

    -- determines the CCed targets we have..
    local targetIsCrowdControlled = false
    for cc_spellname, applied in pairs(sheepSafe.ccs) do
      if Zorlen_checkDebuff(cc_spellname,"target") then
        COMBAT_SCANNER.ccsApplied[cc_spellname] = true
        targetIsCrowdControlled	=	true
      end
    end

    if ZorlenX_IsTotem("target") then
      COMBAT_SCANNER.totemExists = true
    end

    if Zorlen_isEnemyTargetingYou() then
      enemiesAggroPlayer[current_target_name] = 1
    end

    if Zorlen_isActiveEnemy("target") and not targetIsCrowdControlled then
      activeLooseEnemies[current_target_name] = 1
      if ZorlenX_isUnitCCable("target") then
        ZorlenX_Log(current_target_name .. " is ccAble.")
        COMBAT_SCANNER.ccAbleTargetExists = true
      end
    end

    if Zorlen_isActiveEnemy("target") and UnitExists("targettarget") and UnitIsFriend("player","targettarget") and isSoftTarget("targettarget") then
      enemyesAggroingCasters[current_target_name] = true
      castersWithAggro[UnitName("targettarget")] = true
    end

    if Zorlen_isActiveEnemy("target") and CheckInteractDistance("target",2) then
      enemiesAoeRange[current_target_name] = 1
    end

    if Zorlen_isActiveEnemy("target") and ZorlenX_mobIsBoss("target") then
      COMBAT_SCANNER.isBossFight = true
    end

    local TargetHealth = UnitHealth("target")
    if Zorlen_isActiveEnemy("target") then
      activeEnemiesHp[current_target_name] = TargetHealth
    end

    -- health targeting
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
  COMBAT_SCANNER.looseEnemies          = table_length(activeLooseEnemies)
  COMBAT_SCANNER.enemiesAggroPlayer    = table_length(enemiesAggroPlayer)
  COMBAT_SCANNER.castersWithAggro      = table_keys(castersWithAggro)
  COMBAT_SCANNER.castersWithAggroCount = table_length(castersWithAggro)
  COMBAT_SCANNER.enemiesAoeRange       = table_length(enemiesAoeRange) 
  COMBAT_SCANNER.scanTime              = round(GetTime() - scanStart, 4)
  COMBAT_SCANNER.activeEnemies         = table_length(activeEnemiesHp) 
  COMBAT_SCANNER.totalEnemyHP          = table_sum(activeEnemiesHp) 

  ZorlenX_UpdateCombatFrame()
  return COMBAT_SCANNER
end

function ZorlenX_ccIsApplied(cc_spellname)
  return COMBAT_SCANNER.ccsApplied[cc_spellname]
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

-- will target the first target that have a friendly target as target
function targetFallbackTarget()
  for i = 1, 6 do
    TargetNearestEnemy()
    if UnitIsFriend("player","targettarget") then
      return true
    end
  end
end

function targetMainTarget()
  LazyPigMultibox_AssistMaster()
  if not Zorlen_isActiveEnemy("target") then
    if ZorlenX_inRaidOrDungeon() and targetLowestHP() then
      return true
    elseif targetEnemyAttackingMe() then
      return true
    elseif targetFallbackTarget() then
      return true
    else
      ZorlenX_Log("Couldnt aquire a target. :-/")
      return false
    end
  else
    -- LPM mastertarget is active... kill it!
    return true
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
  if not (COMBAT_SCANNER.enemiesAggroPlayer > 0) then
    return false
  end
  for i = 1, 6 do
    TargetNearestEnemy()
    if Zorlen_isEnemyTargetingYou() then
      return true
    end
  end
end

function targetEnemyAttackingCasters()
  if not (COMBAT_SCANNER.castersWithAggroCount > 0) then
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
  local checkRaidAndPartyTargets = false
  if myCCisApplied then
    -- not targeting is done yet. 
    sheepSafe:p("Aborting: I have a cc already.");
    return false
  end

  if COMBAT_SCANNER.looseEnemies < 2 then
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

  if not isWarlock("player") and ZorlenX_IsDotted() then
    return false
  end
  -- ok this seem to be a good target...
  if Zorlen_HealthPercent("target") > 60 and ZorlenX_GetTargetCurHP() > UnitHealthMax("player") then
    return true
  end
end 


local zorlenx_frame_count = 1
function zorlenx_unique_frame_name()
  zorlenx_frame_count = zorlenx_frame_count + 1
  return 'zorlenx_frame_' .. zorlenx_frame_count
end

-- /script ZorlenX_CreateCombatFrame()
ZORLENX_COMBAT_TABLE = {}
ZORLENX_COMBAT_TABLE.values = {}
ZORLENX_COMBAT_TABLE.keys = {}
function ZorlenX_CreateCombatFrame()
  local localCombatScanner = ZorlenX_resetCombatScanner()
  local frame = CreateFrame("Frame",nil,UIParent)
  frame:SetFrameStrata("BACKGROUND")
  frame:SetWidth(180) -- Set these to whatever height/width is needed 
  frame:SetHeight(600) -- for your Texture
  frame:SetPoint('RIGHT',-120,-500)
  --local t = frame:CreateTexture(nil,"BACKGROUND")
  --t:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Factions.blp")
  --t:SetAllPoints(frame)
  --frame.texture = t
  local font = [[Fonts\ARIALN.TTF]]

  local row_number = 0
  local line_spacing = 15
  for key, value in pairs (localCombatScanner) do
    local value_text = frame:CreateFontString(nil, zorlenx_unique_frame_name())
    value_text:SetFont(font, 12)
    value_text:SetText("-")
    value_text:SetPoint('TOPRIGHT', 0, row_number * line_spacing)
    ZORLENX_COMBAT_TABLE.values[key] = value_text
    local key_text = frame:CreateFontString(nil, zorlenx_unique_frame_name())
    key_text:SetFont(font, 12)
    key_text:SetText(key)
    key_text:SetPoint('TOPLEFT', 0 , row_number * line_spacing)
    ZORLENX_COMBAT_TABLE.keys[key] = key_text
    row_number = row_number + 1
  end
  frame:Show()
  return frame
end

ZorlenX_CreateCombatFrame()

function ZorlenX_UpdateCombatFrame()
  for key, value in pairs (COMBAT_SCANNER) do
    if key ~= "ccsApplied" and ZORLENX_COMBAT_TABLE.values[key] then
      ZORLENX_COMBAT_TABLE.values[key]:SetText(to_string(value))
    end
  end
end
