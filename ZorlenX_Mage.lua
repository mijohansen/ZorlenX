-- at this point lacks target.
function ZorlenX_Mage(dps, dps_pet, heal, rez, buff)

  local locked = Zorlen_isChanneling() or Zorlen_isCasting()
  
  if locked then
    return true
  end

  if ZorlenX_MageRestoreMana() then
    return true
  end

  -- added evocation on low mana.
  if ZorlenX_MageOnLowManaEvocation() then
    return true
  end
  
  if targetEnemyAggroingCasters() then
    if Zorlen_checkDebuffByName(LOCALIZATION_ZORLEN.Frostbolt, "target") and castFrostbolt(1) then
      return true
    else
      -- targeting function is run, we go back to assist on Master target.
      LazyPigMultibox_AssistMaster()
    end
  end
  
  if ZorlenX_MageDPS() then
    return true
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
  --Zorlen_debug("scorch_stack: " .. scorch_stack .. ", target_hp: " .. target_hp .. ", player_hp: " .. player_hp);
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
  if ZorlenX_MageSmartScorch() then
    return true
  end
  if ZorlenX_MageCombustion() then
    return true
  end
  if castFireBlast()  then
    return true
  end

  if castFireball() then
    return true
  end
  if Zorlen_checkCooldownByName("Fireball") and not isShootActive() then
    castShoot()
  end
  return false
end

function ZorlenX_MageConjure()
  if UnitAffectingCombat("player") then
    return
  end
  if Zorlen_isChanneling() or Zorlen_isCasting() then
    return
  end
  if Zorlen_GiveContainerItemCountByName("Conjured Spring Water") < 60 then 
    return Zorlen_castSpellByName("Conjure Water")
  end
  if Zorlen_IsSpellKnown("Conjure Mana Jade") and not manaJadeExists() then 
    return Zorlen_castSpellByName("Conjure Mana Jade")
  end
  if Zorlen_IsSpellKnown("Conjure Mana Agate") and not manaAgateExists() then 
    return Zorlen_castSpellByName("Conjure Mana Agate")
  end
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
  if Zorlen_isChanneling() or Zorlen_isCasting() or UnitAffectingCombat("player") then
    return false
  end
  if Zorlen_ManaPercent("player") < 10 then
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