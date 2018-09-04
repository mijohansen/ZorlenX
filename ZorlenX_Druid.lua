function ZorlenX_Druid(dps, dps_pet, heal, rez, buff)

  local cat_form = isCatForm()
  local bear_form = isDireBearForm() or isBearForm()
  local caster_form = isCasterForm()
  local moonkin_form = isMoonkinForm()

  if Zorlen_isCastingOrChanneling() then
    return true
  end

  if heal and not cat_form and not bear_form and not moonkin_form then
    QuickHeal();
  end

  if dps then
    if (caster_form or moonkin_form) and castWrath() then
      return true	
    elseif bear_form and LazyPigMultibox_AttackBear() then
      castAttack();
      return true	
    elseif cat_form and LazyPigMultibox_AttackCat() then
      castAttack();
      return true	
    end
  end
end

function ZorlenX_DruidEnsureCasterForm()
  if isDireBearForm() and CastSpellByName(LOCALIZATION_ZORLEN.DireBearForm)then
    return true
  end
  if isBearForm() and CastSpellByName(LOCALIZATION_ZORLEN.BearForm) then
    return true
  end
end

--------   All functions below this line will only load if you are playing the corresponding class   --------
if not Zorlen_isCurrentClassDruid then return end

function LazyPigMultibox_AttackCat()
  local percent = (UnitHealth("target") / UnitHealthMax("target")) * 100
  if (isComboPoints(5) or isComboPoints(4) and percent<=25) and Zorlen_castSpellByName("Rip") then
    return true	
  else
    if not isProwlActive() and castFaerieFire() then
      return true	
    elseif Zorlen_checkDebuffByName("Rake", "target") and Zorlen_castSpellByName("Claw") then
      return true	
    elseif Zorlen_castSpellByName("Rake") then
      return true	
    end
  end
end

function LazyPigMultibox_AttackBear()
  if castFaerieFire() then
    return true	
  elseif not Zorlen_isEnemyTargetingYou() and Zorlen_checkCooldownByName("Growl") and not Zorlen_isEnemyPlayer("target") and UnitExists("targettarget") and Zorlen_castSpellByName("Growl") then 
    return true	
  elseif Zorlen_castSpellByName("Maul") then
    return true	
  end
end

-- /script ZorlenX_AttackBear()
function ZorlenX_AttackBear()
  --ZorlenX_CombatScan() --just for debugging while grinding.
  if UnitExists("target") then
    local result = CheckInteractDistance("target",2)
    -- ZorlenX_Log(result)
  end
  if isDireBearForm() or isBearForm() then
    if not Zorlen_isEnemyTargetingYou() and Zorlen_checkCooldownByName("Growl") and not Zorlen_isEnemyPlayer("target") and UnitExists("targettarget") and Zorlen_castSpellByName("Growl") then 
      return true	
    elseif Zorlen_castSpellByName("Maul") then
      return true	
    end
  elseif Zorlen_HealthPercent("player") < 90 and Zorlen_ManaPercent("player") > 50  and castMaxRejuvenation(nil, "player") then
    return true
  elseif not UnitAffectingCombat("target") and Zorlen_ManaPercent("player") > 50 and castMoonfire() then
    return true
  else
    -- ensures bear form
    return castBearForm()
  end
end 

