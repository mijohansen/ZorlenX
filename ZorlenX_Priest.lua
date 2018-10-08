
function ZorlenX_Priest(dps, dps_pet, heal, aoe, burst, panic, isSlave)
  if Zorlen_isCastingOrChanneling() then
    return
  end

  local shadow_form = Zorlen_checkBuffByName("Shadowform", "player")

  -- just use inner fire on low mana.
  if Zorlen_ManaPercent("player") < 30 and castInnerFocus() then
    return true
  end
  
  if heal and not shadow_form then
    local result = QuickHeal()
    if Zorlen_isCasting() then
      ZorlenX_Log("Casting heal with QuickHeal")
      return
    end
  end
  
  if castInnerFire() then
    ZorlenX_Log("Aquiring InnerFire.")
    return
  end
  
  if isTroll() and castShadowguard() then
    ZorlenX_Log("Aquiring ShadowGuard.")
    return 
  end
  
  if not heal and not shadow_form and Zorlen_castSpellByName("Shadowform") then
    ZorlenX_Log("Aquiring ShadowForm.")
    return

  elseif UnitAffectingCombat("player") and (Zorlen_isEnemyTargetingYou("target") or Zorlen_HealthPercent("player") < 50) and (ZorlenX_inRaidOrDungeon() or Zorlen_HealthPercent("player") < 75) and (Zorlen_checkCooldownByName("Fade") or Zorlen_checkCooldownByName(LOCALIZATION_ZORLEN.PowerWordShield) or Zorlen_checkCooldownByName("Stoneform")) then 
    if Zorlen_isCasting() then 
      SpellStopCasting()
      return 
    elseif isShootActive() then
      stopShoot()
      return
    elseif (Zorlen_castSpellByName("Fade") or castPowerWordShield() or CheckInteractDistance("target", 3) and Zorlen_castSpellByName("Stoneform")) then
      return
    end
  end	

  -- targeting logic is broken...
  if dps and targetMainTarget() and ZorlenX_PriestDps() then
    ZorlenX_Log("Used ZorlenX_PriestDps.")
    return true
  end

-- /script ZorlenX_Debug(TargetUnit("party2"))
  local CS = ZorlenX_CombatScan()
  -- Fortitude casters with aggro
  
  if 
  CS.castersWithAggroCount > 0 and 
  powerWordShieldReady() 
  then
     
    for i, casterWithAggroName in pairs(CS.castersWithAggro) do
      local unit = LazyPigMultibox_ReturnUnit(casterWithAggroName)
      ZorlenX_Log("Checking " .. unit .. " with aggro to help...")
      if Zorlen_HealthPercent(unit) < 70 and not isWeakenedSoul(unit) and not isPowerWordShield(unit) and (TargetUnit(unit) or castPowerWordShield()) then
        return true
      end
    end
  end
-- /script castShadowguard()
  -- cast fear when
  if panic then
  
  end

  if targetMainTarget() then
    if isTroll() and isRareTarget() and not isHexOfWeakness("target") and castHexOfWeakness() then
      return true
    end
    if heal and not isShootActive() then
      -- just do some extra Wanding when in healmode
      ZorlenX_Log("Starting to use wand on target.")
      castShoot()
    end
  end
  ZorlenX_Log("No suitable action found.")
end


function isRareTarget()
  local target_type = UnitClassification("target")
  return (target_type == "elite" or target_type == "rareelite" or target_type == "worldboss")
end

function ZorlenX_PriestDps()
  --local plague_stack = Zorlen_GetDebuffStack("Spell_Shadow_BlackPlague", "target")
  local plague_stack = 5
  local smite_enabled = true
  local fly_range = LazyPigMultibox_IsSpellInRangeAndActionBar("Mind Flay")
  local hi_mana = Zorlen_ManaPercent("player") > 20
  local inner_active = Zorlen_checkBuffByName("Inner Focus", "player")
  local target_hp = MobHealth_GetTargetCurHP()
  local rare_target = isRareTarget()
  local shadow_form = Zorlen_checkBuffByName("Shadowform", "player")
  if not target_hp then
    target_hp = 0
  end
  if COMBAT_SCANNER.totemExists then
    Zorlen_TargetTotem()
    ZorlenX_Log("Targeting Totem for destruction")
    if not isShootActive() then
      castShoot()
    end
    return true
  end
  if isShootActive() and (not Zorlen_IsTimer("ShadowRotation") or hi_mana or plague_stack < 5) then
    stopShoot();
    return true
  end

  if Zorlen_HealthPercent("target") > 50 and Zorlen_checkCooldownByName("Mind Blast") and Zorlen_castSpellByName("Inner Focus") then
    return true

  elseif not inner_active and not Zorlen_IsTimer("ShadowWordPain") and hi_mana and target_hp > UnitHealthMax("player") and castShadowWordPain() then
    Zorlen_SetTimer(1, "ShadowWordPain");
    Zorlen_SetTimer(9, "ShadowRotation");
    return true

  elseif not inner_active and (rare_target or target_hp > 2*UnitHealthMax("player")) and castVampiricEmbrace() then
    return true

  elseif (inner_active or isShadowWordPain() and Zorlen_ManaPercent("player") > 40) and castMindBlast() then
    Zorlen_SetTimer(9, "ShadowRotation");
    return true

  elseif not Zorlen_IsTimer("ShadowWordPain") and (not Zorlen_IsTimer("ShadowRotation") or plague_stack < 5) and castShadowWordPain(1) then
    Zorlen_SetTimer(1, "ShadowWordPain");
    Zorlen_SetTimer(9, "ShadowRotation");
    return true

  elseif fly_range and Zorlen_ManaPercent("player") > 20 and castMindFlay() then 
    Zorlen_SetTimer(9, "ShadowRotation");
    return true

  elseif fly_range and (not Zorlen_IsTimer("ShadowRotation") or plague_stack < 5) and castMindFlay(1) then
    Zorlen_SetTimer(9, "ShadowRotation");
    return true 

  elseif not shadow_form and smite_enabled and castSmite() then
    return true

  elseif plague_stack == 5 and not hi_mana and Zorlen_IsTimer("ShadowRotation") and not isShootActive() then
    castShoot();
    return true
  elseif not hi_mana and not isShootActive() then
    castShoot();
    return true
  end
end

function powerWordShieldReady()
  return Zorlen_checkCooldownByName(LOCALIZATION_ZORLEN.PowerWordShield)
end

function castInnerFocus() 
	local SpellName = LOCALIZATION_ZORLEN.InnerFocus
	local EnemyTargetNotNeeded = 1
	local BuffName = SpellName
	return Zorlen_CastCommonRegisteredSpell(SpellRank, SpellName, nil, nil, nil, nil, EnemyTargetNotNeeded, BuffName)
end