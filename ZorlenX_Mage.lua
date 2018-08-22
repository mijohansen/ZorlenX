function ZorlenX_Mage(dps, dps_pet, heal, rez, buff)
	local locked = Zorlen_isChanneling() or Zorlen_isCasting()
	
	if locked then
		return true
	end
  
  if Nok_MageRestoreMana() then
    return true
  end
  -- added evocation on low mana.
  if  Wenlock_MageOnLowManaEvocation() then
    return true
  end
  
	if buff then
		LazyPigMultibox_UnitBuff();
	end
  
  if Wenlock_MageDPS() then
    return true
	end
end

function LazypigMultibox_MageDPS(dps,locked)
  if dps and not locked then		
    if Zorlen_IsSpellKnown("Frostbolt") then
      castFrostbolt();
    else	
      castFireball();
    end	
  end	
end

function Wenlock_MageOnLowManaEvocation()
  if not Zorlen_IsSpellKnown("Evocation") or Zorlen_isMoving() or not Zorlen_inCombat() then
    return false
  end
  if Zorlen_ManaPercent("player") < 10 and Zorlen_checkCooldownByName("Evocation") then
    return Zorlen_castSpellByName("Evocation")
  end
  return false
end

function Wenlock_MageSmartScorch()
  if Zorlen_isDieingEnemy() or not Zorlen_IsSpellKnown("Scorch") then
    return false
  end
  local scorch_stack = Zorlen_GetDebuffStack("Spell_Fire_SoulBurn", "target")
  local target_hp = Nok_GetTargetCurHP()
  local player_hp = UnitHealthMax("player")
  --Zorlen_debug("scorch_stack: " .. scorch_stack .. ", target_hp: " .. target_hp .. ", player_hp: " .. player_hp);
  if target_hp > 2*player_hp and scorch_stack < 5 and cast_ManaEfficient_Scorch() then
    return true
  end
  return false
end

function Nok_MageCombustion()
  if Zorlen_isDieingEnemy() or not Zorlen_IsSpellKnown("Combustion") and not Zorlen_checkCooldownByName("Combustion") then
    return false
  end
  local target_hp = Nok_GetTargetCurHP()
  local player_hp = UnitHealthMax("player")
  if target_hp > 2*player_hp and Zorlen_ManaPercent("player") > 33 and Zorlen_castSpellByName("Combustion") then
    return true
  end
  return false
end

function Wenlock_MageDPS()
  if Wenlock_MageSmartScorch() then
    return true
  end
  if Nok_MageCombustion() then
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

function Wenlock_MageConjure()
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



function Nok_MageRestoreMana()
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
  