

local lpm_shard_bag = nil
--local lpm_warlock_curse = "Curse of Shadow"
--local lpm_pet = "Voidwalker"

-- Fire Lock
local lpm_pet = "Imp"
local lpm_firelock = true

function ZorlenX_Warlock(dps, dps_pet, heal, aoe, burst, panic, isSlave)
  --ZorlenX_Debug({dps, dps_pet, heal, aoe, burst, panic, isSlave})
  local manapercent = UnitMana("player") / UnitManaMax("player")
  local healthpercent = UnitHealth("player") / UnitHealthMax("player")
  local player_affected = UnitAffectingCombat("player")
  local unique_curse = nil

  if isMageInGroup() or (isGrouped() and lpm_firelock) then
    local lpm_warlock_curse = LOCALIZATION_ZORLEN.CurseOfTheElements
  elseif isGrouped() then
    local lpm_warlock_curse = LOCALIZATION_ZORLEN.CurseOfShadow
  else
    local lpm_warlock_curse = LOCALIZATION_ZORLEN.CurseOfAgony
  end
  if LPMULTIBOX.UNIQUE_SPELL and Zorlen_IsSpellKnown(lpm_warlock_curse) then
    unique_curse = true
  end
  -- this seem to not happen... Why?
  if not panic and not aoe and dps_pet then
    -- this spell only summons.
    LazyPigMultibox_WarlockPet(lpm_pet)
  end	

  if UnitAffectingCombat("player") and Zorlen_HealthPercent("player") < 15 and LazyPigMultibox_IsPetSpellKnown("Sacrifice") and not Zorlen_checkBuffByName("Sacrifice", "player") and not Zorlen_checkBuffByName("Blessing of Protection", "player") then
    zSacrifice();
    if isSlave then
      LazyPigMultibox_Annouce("lpm_slaveannouce","Sacrifice");
    end
  end

  if Zorlen_isCastingOrChanneling() then
    return true
  end

  if dps_pet then
    Warlock_PetSuffering()
  end

  local CS = ZorlenX_CombatScan()
  if (CS.looseEnemies > 1 or not isGrouped()) and not panic and not aoe and targetEnemyAttackingCasters() then
    if (CheckInteractDistance("target", 2) and not Zorlen_isDieingEnemy("target") or not isGrouped())
    and ((not fearIsApplied() and castFear()) or castDeathCoil()) then
      ZorlenX_PetAttack()
      ZorlenX_Log("Trying to deal with enemies attacking casters.")
      return true
    end
  end

  -- Just do a scream in chaotic situations.
  if not aoe and ZorlenX_shouldDoMassFear() and castHowlOfTerror() then
    ZorlenX_Log("Doing mass fear...")
    return
  end

  if not aoe and dps and targetMainTarget(isSlave) and ZorlenX_WarlockDPS(lpm_warlock_curse) then
    ZorlenX_Log("Doing normal ZorlenX_WarlockDPS")
    ZorlenX_PetAttack()
    return true
  end

  if aoe and dps and ZorlenX_WarlockAoe() then
    ZorlenX_Log("Doing ZorlenX_WarlockAoe")
    ZorlenX_PetAttack()
    return true
  end

  -- if we have dotted all targets, focus on killing the one with highest HP
  if aoe and dps and targetHighestHP() and ZorlenX_WarlockDPS(nil) then
    return true
  end

  if Zorlen_ManaPercent("player") < 70 and Zorlen_HealthPercent("player") > 75 and castLifeTap() then
    return
  end	

end


-- /script ZorlenX_WarlockAoe()

function ZorlenX_WarlockAoe()
  return targetAndEnsureDots({
      LOCALIZATION_ZORLEN.CurseOfAgony,
      LOCALIZATION_ZORLEN.Corruption,
      LOCALIZATION_ZORLEN.Immolate,
      LOCALIZATION_ZORLEN.SiphonLife
    })
end 

function fearIsApplied()
  return ZorlenX_ccIsApplied("Spell_Shadow_Possession")
end 

function isHardMob()
  return (UnitClassification("target") == "elite") or (UnitClassification("target") == "rareelite")	or (UnitClassification("target") == "worldboss")	
end
function ZorlenX_WarlockDPS(curse)
  local player_mana_percent = (UnitMana("player") / UnitManaMax("player")) * 100
  local player_hp_percent = (UnitHealth("player") / UnitHealthMax("player")) * 100
  local hard_mob = isHardMob()
  local dot_unit = hard_mob or player_mana_percent <= 100 or UnitIsPlayer("target")
  local drainok = Zorlen_IsSpellKnown("Drain Life") and LazyPigMultibox_IsSpellInRangeAndActionBar("Drain Life")
  local target_hp = ZorlenX_GetTargetCurHP()
  local targetImmuneToShadow = immuneToShadow()

  -- all spells that are finishers are shadow...
  if not targetImmuneToShadow and Zorlen_isDieingEnemy("target") and LazyPigMultibox_WarlockFinisher() then
    return true
  end 
  if player_mana_percent <= 25 and player_hp_percent >= 65 and castLifeTap() then
    return true
  end
  if not targetImmuneToShadow then
    if Zorlen_checkBuffByName("Shadow Trance", "player")  and castShadowBolt() then
      return true	
    elseif not isCorruption() and castCorruption() then
      return true 	
    elseif player_mana_percent > 25 and (player_hp_percent > 60 or not drainok) then
      if(dot_unit or moving and UnitAffectingCombat("target")) then
        if curse and target_hp > UnitHealthMax("player") and not Zorlen_checkDebuffByName(lpm_warlock_curse,"target") and Zorlen_castSpellByName(lpm_warlock_curse) then
          return true
        elseif not curse and (UnitHealthMax("target") > 2*UnitHealthMax("player") or Zorlen_isEnemyPlayer("target")) and castAmplifyCurse() then
          return true
        elseif not curse and castCurseOfAgony() then
          return true
        elseif dot_unit and castSiphonLife() then
          return true
        end	
      end
    end
  end
  if lpm_firelock and not Zorlen_isDieingEnemy("target") and castConflagrate() then 
    return true
  end
  
  if isGrouped() and lpm_firelock and Zorlen_HealthPercent("target") < 50 and castSearingPain() then 
    return true
  end

  if not isImmolate() and castImmolate() then
    return true
  end

  if not Zorlen_isMoving() and not targetImmuneToShadow then
    if castShadowBolt() then
      return true
    end

    if not Zorlen_IsTimer("DLOCK") and drainok and castDrainLife() then 
      Zorlen_SetTimer(2, "DLOCK")
      return				
    end
  end

end


function LazyPigMultibox_WarlockPet(pet)
  function SummonMinion()
    local check = Zorlen_IsSpellKnown("Summon "..pet) and (pet == "Imp" or Zorlen_GiveSoulShardCount() > 0) 
    if check then
      if Zorlen_castSpellByName("Fel Domination") then 
        return 
      elseif (Zorlen_checkBuffByName("Shadow Trance", "player") or not (Zorlen_isEnemy("target") and UnitExists("targettarget") and UnitIsPlayer("targettarget") and UnitIsFriend("targettarget","player"))) and Zorlen_castSpellByName("Summon "..pet) then
        return
      end
    end	
  end

  if Zorlen_IsTimer("LockPetSummon") then
    return
  end

  if UnitHealth("pet") > 0 then
    if not LazyPigMultibox_IsPetSpellOnActionBar("PET_ACTION_ATTACK") then
      Zorlen_SetTimer(2, "LockPetSummon");
      SummonMinion();
      return
    elseif Zorlen_IsSpellKnown("Soul Link") and not Zorlen_checkBuffByName("Soul Link", "player") and Zorlen_castSpellByName("Soul Link") then
      return
    end	
  else
    Zorlen_SetTimer(2, "LockPetSummon");
    SummonMinion();
    return
  end
end

function Warlock_PetSuffering()
  if UnitAffectingCombat("pet") and UnitExists("pettarget") and Zorlen_isEnemy("target") and UnitAffectingCombat("target") and UnitExists("targettarget") and UnitIsPlayer("targettarget") and UnitIsFriend("targettarget","player") then
    if not Zorlen_IsTimer("LazyPigMultiboxSuffering") and zSuffering() then
      Zorlen_SetTimer(1, "LazyPigMultiboxSuffering")
      LazyPigMultibox_Annouce("lpm_slaveannouce","Suffering")
    end
  end
end

function LazyPigMultibox_WarlockFinisher()
  if not UnitAffectingCombat("player") or not UnitExists("target") then
    return
  end
  local player_hp_percent = (UnitHealth("player") / UnitHealthMax("player")) * 100
  local shard_maxcount = LazyPigMultibox_SetShardBagSize()
  local shard_count = Zorlen_GiveSoulShardCount()
  local enemy_player = Zorlen_isEnemyPlayer()
  local hard_mob = (UnitClassification("target") == "elite") or (UnitClassification("target") == "rareelite") or (UnitClassification("target") == "worldboss")
  local health_max = UnitHealthMax("target")
  local healthfraction = UnitHealth("target") / health_max 

  if player_hp_percent > 50 then	
    if Zorlen_IsSpellKnown("Shadowburn") and (enemy_player and (healthfraction < 0.6) and (shard_count >= 5) or hard_mob and (healthfraction < 0.1) and (shard_count >= 10)) then --
      if(Zorlen_checkCooldownByName("Shadowburn") and LazyPigMultibox_IsSpellInRangeAndActionBar("Shadowburn")) then	
        castShadowburn(nil, 1, nil)
        if(not Zorlen_checkCooldownByName("Shadowburn")) then
          --SlaveAnnouce("slave_msg", "Shadowburn !!!", GetUnitName("player"))
        end
      end	
      return
    elseif not Zorlen_isChanneling("Drain Soul") and not Zorlen_isMoving() and (shard_count < shard_maxcount) and (healthfraction <= 0.25 and hard_mob and health_max < 4*UnitHealthMax("player") or healthfraction <= 0.35 and not hard_mob or healthfraction <= 0.50 and health_max < UnitHealthMax("player") or 3*health_max < UnitHealthMax("player")) and Zorlen_GivesXP() and not isShadowburn() and not Zorlen_checkDebuffByName("Drain Soul", "target") and not Zorlen_checkBuffByName("Soul Siphon", "player") and castDrainSoul() then
      return
    end
  end	
end



-- /script ZorlenX_CreateHealthStone()
function ZorlenX_CreateHealthStone()
  if not isWarlock("player")  then
    return false
  end

  if playerHaveHealthstone() then
    return false
  end

  if Zorlen_isMoving() then
    return false
  end

  local healthstoneSpells = {
    LOCALIZATION_ZORLEN.CreateHealthstoneMajor,
    LOCALIZATION_ZORLEN.CreateHealthstoneGreater,
    LOCALIZATION_ZORLEN.CreateHealthstone,
    LOCALIZATION_ZORLEN.CreateHealthstoneLesser,
    LOCALIZATION_ZORLEN.CreateHealthstoneMinor
  }
  for i, healthstoneSpell in ipairs(healthstoneSpells) do
    if Zorlen_IsSpellKnown(healthstoneSpell) then
      return Zorlen_castSpellByName(healthstoneSpell)
    end
  end
end 


ZORLENX_IMMUNETOSHADOW = {}
ZORLENX_IMMUNETOSHADOW["Shadowfang Darksoul"] = true

function immuneToShadow()
  local name = UnitName("target")
  return ZORLENX_IMMUNETOSHADOW[name]
end