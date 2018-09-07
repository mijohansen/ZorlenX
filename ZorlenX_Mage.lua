-- at this point lacks target.
function ZorlenX_Mage(dps, dps_pet, heal, aoe, burst, panic, isSlave)
  if Zorlen_isCastingOrChanneling() then
    return true
  end

  if ZorlenX_MageRestoreMana() then
    return true
  end

  -- added evocation on low mana.
  if ZorlenX_MageOnLowManaEvocation() then
    return true
  end
  
  --if targetEnemyAttackingCasters() then
    --hurling a rank 1 frostbolt.
    --if not Zorlen_checkDebuffByName(LOCALIZATION_ZORLEN.Frostbolt, "target") and castFrostbolt(1) --then
      --return true
    --else
      --ZorlenX_Log("Failed to deal with enemy targeting casters.")
    --end
  --end
  
  -- we need to do some smart targeting here. For now. AssistMasterOrFirst and best.
  if ((aoe and targetHighestHP()) or targetMainTarget()) and ZorlenX_MageDPS() then
    return true
  end
  
  if Zorlen_ManaPercent("player") < 15 and not isShootActive() then
    -- need a default when very low on mana...
    -- just do some extra Wanding when in healmode
    ZorlenX_Log("Low mana. Starting to use wand on target.")
    castShoot()
  end
  
end

-- target mob that aggroes cloth with a frost bolt.

function ZorlenX_MageDefensiveMove()

end

function ZorlenX_MageOnLowManaEvocation()
  if not Zorlen_IsSpellKnown("Evocation") or Zorlen_isMoving() or not Zorlen_inCombat() then
    return false
  end
  if Zorlen_ManaPercent("player") < 10 and Zorlen_checkCooldownByName("Evocation") then
    return Zorlen_castSpellByName("Evocation")
  end
  return false
end

function ZorlenX_MageSmartScorch()
  if Zorlen_isDieingEnemy() or not Zorlen_IsSpellKnown("Scorch") then
    return false
  end
  local scorch_stack = Zorlen_GetDebuffStack("Spell_Fire_SoulBurn", "target")
  local target_hp = ZorlenX_GetTargetCurHP()
  local player_hp = UnitHealthMax("player")
  if target_hp > 2*player_hp and scorch_stack < 5 and cast_ManaEfficient_Scorch() then
    return true
  end
  return false
end

function ZorlenX_MageCombustion()
  if Zorlen_isDieingEnemy() or not Zorlen_IsSpellKnown("Combustion") and not Zorlen_checkCooldownByName("Combustion") then
    return false
  end
  local target_hp = ZorlenX_GetTargetCurHP()
  local player_hp = UnitHealthMax("player")
  if target_hp > 2*player_hp and Zorlen_ManaPercent("player") > 33 and Zorlen_castSpellByName("Combustion") then
    return true
  end
  return false
end

function ZorlenX_MageDPS()
  if Zorlen_isImmune("Fireball", "target") and castFrostbolt() then
    return true
  end
  
  if ZorlenX_MageSmartScorch() then
    return true
  end
  if ZorlenX_MageCombustion() then
    return true
  end
  if castFireBlast() then
    return true
  end

  if castFireball() then
    return true
  end
  return false
end


function ZorlenX_MageAOE()
  -- check if there exists enough targets to do aoe... +4
  --castArcaneExplosion()
  --LOCALIZATION_ZORLEN.FrostNova
end

function manaAgateExists()
  return (Zorlen_GiveContainerItemCountByName("Mana Agate") == 1)
end

function manaJadeExists()
  return (Zorlen_GiveContainerItemCountByName("Mana Jade") == 1)
end



function ZorlenX_MageRestoreMana()
  if Zorlen_ManaPercent("player") > 50 then
    return false
  end
  if manaAgateExists() and Zorlen_useContainerItemByName("Mana Agate") then
    return true
  end
  if manaJadeExists() and Zorlen_useContainerItemByName("Mana Jade") then
    return true
  end
  return false
end

function ZorlenX_MageWaterName()
  if Zorlen_IsSpellKnown("Conjure Water", 7) then
    return "Conjured Crystal Water"
  elseif Zorlen_IsSpellKnown("Conjure Water", 6) then
    return "Conjured Sparkling Water"
  elseif Zorlen_IsSpellKnown("Conjure Water", 5) then 
    return "Conjured Mineral Water"
  elseif Zorlen_IsSpellKnown("Conjure Water", 4) then 
    return "Conjured Spring Water"
  elseif Zorlen_IsSpellKnown("Conjure Water", 3) then
    return "Conjured Purified Water"
  elseif Zorlen_IsSpellKnown("Conjure Water", 2) then
    return "Conjured Fresh Water"
  elseif Zorlen_IsSpellKnown("Conjure Water", 1) then
    return "Conjured Water"
  end
end

function ZorlenX_MageWaterCount()
  local water_name = ZorlenX_MageWaterName()
  return Zorlen_GiveContainerItemCountByName(water_name)
end


function ZorlenX_MageConjure()
  if Zorlen_isCastingOrChanneling() or UnitAffectingCombat("player") then
    return false
  end
  if Zorlen_ManaPercent("player") < 25 then
    return false
  end
  if isMage("player") and ZorlenX_MageWaterCount() < 60 and Zorlen_castSpellByName("Conjure Water") then 
    return true
  end
  if Zorlen_IsSpellKnown("Conjure Mana Jade") and not manaJadeExists() and Zorlen_castSpellByName("Conjure Mana Jade") then 
    return true 
  end
  if Zorlen_IsSpellKnown("Conjure Mana Agate") and not manaAgateExists() and Zorlen_castSpellByName("Conjure Mana Agate") then 
    return true
  end
  return false
end
