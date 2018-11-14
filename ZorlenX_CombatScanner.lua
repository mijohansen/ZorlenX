COMBAT_SCANNER = {}

function ZorlenX_resetCombatScanner()
  COMBAT_SCANNER.activeEnemies = 0
  COMBAT_SCANNER.castersWithAggroCount = 0
  COMBAT_SCANNER.ccAbleTargetExists = false
  COMBAT_SCANNER.ccAbleTargetName = false
  COMBAT_SCANNER.ccsApplied = {}
  COMBAT_SCANNER.enemiesAggroPlayer = 0
  COMBAT_SCANNER.enemiesInAoeRange = 0
  COMBAT_SCANNER.enemyAggroingCasterName  = false
  COMBAT_SCANNER.highestHealth = false
  COMBAT_SCANNER.highestHealthName = false
  COMBAT_SCANNER.isBossFight = false
  COMBAT_SCANNER.lastTarget = false
  COMBAT_SCANNER.looseEnemies = 0
  COMBAT_SCANNER.lowestHealth = false
  COMBAT_SCANNER.lowestHealthName = false
  COMBAT_SCANNER.myCCApplied = false
  COMBAT_SCANNER.scanIterations = 0
  COMBAT_SCANNER.scanTime = 0
  COMBAT_SCANNER.totalEnemyHP = 0
  COMBAT_SCANNER.totemExists = false
  return COMBAT_SCANNER
end

function ZorlenX_CurrentTargetName()
  if UnitExists("target") then
    return UnitName("target") .. "/" .. UnitLevel("target")
  end
end

function ZorlenX_CurrentTargetFingerPrint()
  if UnitExists("target") then
    return UnitName("target") .. "/" .. UnitLevel("target") .. "/" .. UnitHealth("target")
  end
end

-- potensial we do a combat scan every second. Things might have changed.
-- /script local cs = ZorlenX_CombatScan() ZorlenX_Debug(cs)
function ZorlenX_CombatScan()
  if ZorlenX_TimeLock("CombatScan",1) then
    return COMBAT_SCANNER
  end
  if not UnitAffectingCombat("player") then
    return COMBAT_SCANNER
  end
  -- resetting values
  ZorlenX_resetCombatScanner()
  --defining some locals
  local activeEnemiesHp = {}
  local activeLooseEnemies = {}
  local castersWithAggro = {}
  local enemiesAggroPlayer = {}
  local enemiesInAoeRange = {}
  local enemyScanRounds = {}
  local enemyesAggroingCasters = {}
  local scanStart = GetTime()

  -- creating CC-targets
  if sheepSafe.ccicon then
    COMBAT_SCANNER.ccsApplied[sheepSafe.ccicon] = false
  end
  if isWarlock("player") then
    COMBAT_SCANNER.ccsApplied["Spell_Shadow_Possession"] = false
  end
  -- setting what target we had before scan.
  COMBAT_SCANNER.lastTarget = ZorlenX_CurrentTargetFingerPrint()

  for i = 1, 10 do
    TargetNearestEnemy()
    if not UnitExists("target") then
      break
    end

    local currentTargetFingerprint = ZorlenX_CurrentTargetFingerPrint()
    local targetIsActiveEnemy = Zorlen_isActiveEnemy("target")
    local currentTargetHealth = UnitHealth("target")
    local currentTargetHealthAbs = ZorlenX_GetTargetCurHP()
    if not enemyScanRounds[currentTargetFingerprint] then
      enemyScanRounds[currentTargetFingerprint] = 0
    end
    -- break iteration if we probably have orignial target...
    if i > 5 and COMBAT_SCANNER.lastTarget == currentTargetFingerprint then
      break
    end

    -- break iteration if we have the original target and we are seeing it for the second time
    if enemyScanRounds[currentTargetFingerprint] == 2 and (COMBAT_SCANNER.lastTarget == currentTargetFingerprint or not COMBAT_SCANNER.lastTarget) then
      break
    end

    -- her regner vi iterasjonen som startet.
    COMBAT_SCANNER.scanIterations = i 

    if ZorlenX_IsTotem("target") then
      COMBAT_SCANNER.totemExists = true
    end

    if Zorlen_isEnemyTargetingYou() then
      enemiesAggroPlayer[currentTargetFingerprint] = 1
    end

    if enemyScanRounds[currentTargetFingerprint] == 0 then
      if targetIsActiveEnemy then
        if ZorlenX_isUnitCCable("target") then
          ZorlenX_Log("Target is ccAble.")
          COMBAT_SCANNER.ccAbleTargetExists = true
          COMBAT_SCANNER.ccAbleTargetName = ZorlenX_CurrentTargetName()
        end
        activeLooseEnemies[currentTargetFingerprint] = 1
      else
        -- determines the CCed targets we have..
        -- doing it just once pr scan pr target.
        -- this should probably do some smarter caching in the future as we do extensive calls to UnitDebuff() which could be done once pr target.
        -- need also check for banish...
        for ccSpellname, applied in pairs(COMBAT_SCANNER.ccsApplied) do
          if ZorlenX_targetIsValidForMyCC(ccSpellname) and Zorlen_checkDebuff(ccSpellname, "target" ) then
            COMBAT_SCANNER.ccsApplied[ccSpellname] = true
          end
        end
      end
    end

    if targetIsActiveEnemy and UnitExists("targettarget") and UnitIsFriend("player","targettarget") and isSoftTarget("targettarget") then
      enemyesAggroingCasters[currentTargetFingerprint] = true
      castersWithAggro[UnitName("targettarget")] = true
      COMBAT_SCANNER.enemyAggroingCasterName = ZorlenX_CurrentTargetName()
    end

    if targetIsActiveEnemy and CheckInteractDistance("target",2) then
      enemiesInAoeRange[currentTargetFingerprint] = 1
    end

    if targetIsActiveEnemy and ZorlenX_mobIsBoss("target") then
      COMBAT_SCANNER.isBossFight = true
    end

    -- health targeting
    if targetIsActiveEnemy and currentTargetHealthAbs then
      if not COMBAT_SCANNER.highestHealth or currentTargetHealthAbs > COMBAT_SCANNER.highestHealth then
        COMBAT_SCANNER.highestHealth = currentTargetHealthAbs
        COMBAT_SCANNER.highestHealthName = ZorlenX_CurrentTargetName()
      end
      if not COMBAT_SCANNER.lowestHealth or currentTargetHealthAbs < COMBAT_SCANNER.lowestHealth then
        COMBAT_SCANNER.lowestHealth = currentTargetHealthAbs
        COMBAT_SCANNER.lowestHealthName = ZorlenX_CurrentTargetName()
      end
    end

    if targetIsActiveEnemy and not activeEnemiesHp[currentTargetFingerprint] then
      activeEnemiesHp[currentTargetFingerprint] = currentTargetHealthAbs
    end

    -- just counting how many times we a have scanned this target
    enemyScanRounds[currentTargetFingerprint] = enemyScanRounds[currentTargetFingerprint] + 1
  end
  -- counting active loose enemies++
  COMBAT_SCANNER.activeEnemies         = table_length(activeEnemiesHp) 
  COMBAT_SCANNER.castersWithAggro      = table_keys(castersWithAggro)
  COMBAT_SCANNER.castersWithAggroCount = table_length(castersWithAggro)
  COMBAT_SCANNER.enemiesAggroPlayer    = table_length(enemiesAggroPlayer)
  COMBAT_SCANNER.enemiesInAoeRange     = table_length(enemiesInAoeRange) 
  COMBAT_SCANNER.looseEnemies          = table_length(activeLooseEnemies)
  COMBAT_SCANNER.myCCApplied           = COMBAT_SCANNER.ccsApplied[sheepSafe.ccicon]
  COMBAT_SCANNER.scanTime              = round(GetTime() - scanStart, 4)
  COMBAT_SCANNER.totalEnemyHP          = table_sum(activeEnemiesHp) 

  ZorlenX_UpdateCombatFrame()
  return COMBAT_SCANNER
end

function ZorlenX_ccIsApplied(cc_spellname)
  local CS = ZorlenX_CombatScan()
  return CS.ccsApplied[cc_spellname]
end

function ZorlenX_shouldDoMassFear()
  local CS = ZorlenX_CombatScan()
  return (CS.castersWithAggroCount > 2) and (CS.enemiesInAoeRange > 3)
end

function ZorlenX_ccAbleTargetExists()
  local CS = ZorlenX_CombatScan()
  return CS.ccAbleTargetExists and (CS.looseEnemies > 1)
end

function ZorlenX_myCcIsApplied()
  return ZorlenX_ccIsApplied(sheepSafe.ccicon)
end

-- function that will cycle through targets check if dot misses and try to cast it if its not applied.
-- takes an array of dotts.
-- /script targetAndEnsureDots({"Moonfire"})
-- /script ZorlenX_Debug(Zorlen_GetSpellID("Hibernate"))
-- /script ZorlenX_Debug(Zorlen_checkDebuffByName("Hibernate", "target"))
-- /script ZorlenX_Debug(Zorlen_Button)
function targetAndEnsureDots(dotSpells)
  -- first doing a check to ensure that there is something to dot.
  -- no need to dot shit that is dead.
  if ZorlenX_TimeLock("targetAndEnsureDots",1.5) then
    return false
  end
  local CS = ZorlenX_CombatScan()
  local minimumDottableHp = UnitHealthMax("player") * 0.5
  if not CS.highestHealth or (CS.highestHealth < minimumDottableHp) then
    return false
  end

  -- first checking if all spells are ok...
  local workingDotSpells = {}
  for i, dotSpellname in pairs(dotSpells) do
    local zSpellname = dotSpellname .. ".Any"
    if Zorlen_Button[zSpellname] then
      workingDotSpells[dotSpellname] = true
    else
      if not Zorlen_Button[zSpellname] and Zorlen_IsSpellKnown(dotSpells) then
        ZorlenX_Log("Warning the spell " .. dotSpellname .. " needs to be on the actionbar to use it.")
      end
    end
  end
  local scannedTargets = {}
  local duplicateScans = 0 
  for i = 1, 4 do
    TargetNearestEnemy()
    if not UnitExists("target") then
      break
    end
    local currentTargetFingerprint = ZorlenX_CurrentTargetFingerPrint()
    local currentTargetHealthAbs = ZorlenX_GetTargetCurHP()
    if scannedTargets[currentTargetFingerprint] then
      duplicateScans = duplicateScans + 1
    end
    if duplicateScans == 2 then
      break
    end
    if Zorlen_isActiveEnemy("target") and currentTargetHealthAbs > minimumDottableHp then
      for dotSpellname, spellIsOk in pairs(workingDotSpells) do
        if spellIsOk and 
        isActionInRangeAndUsable(dotSpellname) and 
        not Zorlen_checkDebuffByName(dotSpellname, "target") and 
        Zorlen_castSpellByName(dotSpellname) then
          ZorlenX_Log("Dotted with " .. dotSpellname .. " as part of the AOE-rutine.")
          return true
        end 
      end
    end
    scannedTargets[currentTargetFingerprint] = true
  end
end

function isActionInRangeAndUsable(spellname)
  local zSpellname = spellname .. ".Any"
  if Zorlen_Button[zSpellname] then
    isUsable, notEnoughMana = IsUsableAction(Zorlen_Button[zSpellname])
    IsInRange = IsActionInRange(Zorlen_Button[zSpellname])
    return (isUsable and not notEnoughMana and IsInRange)
  end
end 

function targetLowestHP()
  local CS = ZorlenX_CombatScan()
  return targetEnemyByName(CS.lowestHealthName)
end

function targetHighestHP()
  local CS = ZorlenX_CombatScan()
  return targetEnemyByName(CS.highestHealthName)
end

function targetEnemyAttackingCasters()
  local CS = ZorlenX_CombatScan()
  if not (CS.castersWithAggroCount > 0) then
    return false
  end
  return targetEnemyByName(CS.enemyAggroingCasterName)
end

function targetEnemyByName(enemyName)
  if not enemyName then
    return false
  end
  if UnitExists("target") and enemyName == ZorlenX_CurrentTargetName() then
    return true
  end
  local preTargetFingerPrint = ZorlenX_CurrentTargetFingerPrint()
  for i = 1, 4 do
    TargetNearestEnemy()
    if not UnitExists("target") or preTargetFingerPrint == ZorlenX_CurrentTargetFingerPrint() then
      break
    end
    if enemyName == ZorlenX_CurrentTargetName() and 
    Zorlen_isActiveEnemy("target") and 
    not Zorlen_isBreakOnDamageCC("target") then
      return true
    end
  end
end

-- will target the first target that have a friendly target as target
function targetFallbackTarget()
  for i = 1, 3 do
    TargetNearestEnemy()
    if not UnitExists("target") then
      break
    end
    if UnitIsFriend("player","targettarget") then
      ZorlenX_Log("targetFallbackTarget(): Found Target")
      return true
    end
  end
end

function targetMainTarget(isSlave)
  if isSlave then
    LazyPigMultibox_AssistMaster()
  end
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



function targetEnemyAttackingMe()
  local CS = ZorlenX_CombatScan()
  if not (CS.enemiesAggroPlayer > 0) then
    return false
  end
  for i = 1, 4 do
    TargetNearestEnemy()
    if Zorlen_isEnemyTargetingYou() then
      return true
    end
  end
end



function targetBoss()
  local CS = ZorlenX_CombatScan()
  if not CS.isBossFight then
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

  if ZorlenX_myCcIsApplied() then
    -- not targeting is done yet. 
    ZorlenX_Log("Aborting: I have a cc already.");
    return false
  end

  if not ZorlenX_ccAbleTargetExists() then
    ZorlenX_Log("No CCable target exists. Aborting CC.");
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

--/script ZorlenX_Debug(UnitCreatureType("target"))
function ZorlenX_targetIsValidForMyCC(spell)
  local targetCreatureType = UnitCreatureType("target")
  if spell == "Spell_Shadow_Possession" then
    return (targetCreatureType ~= "Undead")
  else
    return (targetCreatureType and string.find(sheepSafe.validtargets, targetCreatureType))
  end
end

function ZorlenX_isUnitCCable(unit) 
  if ZorlenX_mobIsBoss("target") then
    return false
  end

  -- target is wounded enough, never mind
  if Zorlen_HealthPercent("target") < 75  then
    return false
  end

  if not ZorlenX_targetIsValidForMyCC() then
    return false
  end

  -- low HP target, screw it
  if ZorlenX_GetTargetCurHP() < UnitHealthMax("player") then
    return false
  end

  if Zorlen_isCrowedControlled("target") then
    return false
  end

  if not isWarlock("player") and ZorlenX_IsDotted() then
    return false
  end
  -- ok this seem to be a good target...
  return true
end 

-- To solve the very strange behaviour on Elysium 
function ZorlenX_mobIsBoss(unit)
  local bosses = {}
  local unitName = UnitName(unit)
  bosses["Scarlet Commander Mograine"] = true
  bosses["High Inquisitor Whitemane"] = true
  bosses["Nekrum Gutchewer"] = true
  bosses["Shadowpriest Sezz'ziz"] = true
  bosses["Chief Ukorz Sandscalp"] = true
  bosses["Ruuzlu"] = true
  if UnitClassification(unit) == "worldboss" or bosses[unitName] then
    return true
  end
  return false
end

function ZorlenX_IsTotem(unit)
  if not UnitExists(unit) then
    return false
  end
  local targetName = UnitName(unit)
  local t = {
    [LOCALIZATION_ZORLEN.EarthbindTotem] = true,
    [LOCALIZATION_ZORLEN.FireNovaTotem] = true,
    [LOCALIZATION_ZORLEN.FireResistanceTotem] = true,
    [LOCALIZATION_ZORLEN.FlametongueTotem] = true,
    [LOCALIZATION_ZORLEN.FrostResistanceTotem] = true,
    [LOCALIZATION_ZORLEN.GraceOfAirTotem] = true,
    [LOCALIZATION_ZORLEN.GreaterHealingWard] = true,
    [LOCALIZATION_ZORLEN.GroundingTotem] = true,
    [LOCALIZATION_ZORLEN.HealingStreamTotem] = true,
    [LOCALIZATION_ZORLEN.LavaSpoutTotem] = true,
    [LOCALIZATION_ZORLEN.MagmaTotem] = true,
    [LOCALIZATION_ZORLEN.ManaSpringTotem] = true,
    [LOCALIZATION_ZORLEN.ManaTideTotem] = true,
    [LOCALIZATION_ZORLEN.NatureResistanceTotem] = true,
    [LOCALIZATION_ZORLEN.PoisonCleansingTotem] = true,
    [LOCALIZATION_ZORLEN.SearingTotem] = true,
    [LOCALIZATION_ZORLEN.StoneskinTotem] = true,
    [LOCALIZATION_ZORLEN.StrengthOfEarthTotem] = true,
    [LOCALIZATION_ZORLEN.TremorTotem] = true,
    [LOCALIZATION_ZORLEN.WindfuryTotem] = true,
    [LOCALIZATION_ZORLEN.WindwallTotem] = true,
  }
  return t[targetName]
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
ZORLENX_COMBAT_TABLE.ignore = {}
ZORLENX_COMBAT_TABLE.ignore["ccsApplied"] = true
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
    if not ZORLENX_COMBAT_TABLE.ignore[key] then
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
  end
  frame:Show()
  return frame
end

ZorlenX_CreateCombatFrame()

function ZorlenX_UpdateCombatFrame()
  for key, value in pairs (COMBAT_SCANNER) do
    if not ZORLENX_COMBAT_TABLE.ignore[key] and ZORLENX_COMBAT_TABLE.values[key] then
      ZORLENX_COMBAT_TABLE.values[key]:SetText(to_string(value))
    end
  end
end
