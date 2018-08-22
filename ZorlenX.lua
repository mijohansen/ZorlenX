    

function ZorlenX_UseClassScript()
	local time = GetTime()
	if LPM_TIMER.SCRIPT_USE < time then	
		LPM_TIMER.SCRIPT_USE = time + 0.25
		
		local rez = LPMULTIBOX.SCRIPT_REZ
		local dps = LPMULTIBOX.SCRIPT_DPS
		local dps_pet = LPMULTIBOX.SCRIPT_DPSPET
		local buff = LPMULTIBOX.SCRIPT_BUFF
		local heal = LPMULTIBOX.SCRIPT_HEAL or LPMULTIBOX.SCRIPT_FASTHEAL
		local leader = LazyPigMultibox_ReturnLeaderUnit()
		local check1 = LazyPigMultibox_SlaveCheck()
		local check2 = leader and UnitIsUnit("player", leader)
		local check3 = GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0
		
		if not LPMULTIBOX.STATUS then
			return
		end
    
    
    if not Zorlen_isChanneling() and not Zorlen_isCasting() then
      --ClearTarget()
      -- result = Dcr_Clean(false,false)
      --Zorlen_debug("The result of Dcr_Clean is: "..tostring(result))
      
      -- added support for Decursive, just running the script when not Channeling or casting
      if Dcr_Clean(false,false) then
        return
      end
      -- added support for SheepSafe, just running the script when not Channeling or casting
      if SheepSafeUntargeted() then 
        return 
      end
    end
		

    if not check2 and check1 then
			--Wenlock: Changed to using LazyPigMultibox_SmartEnemyTarget
			--LazyPigMultibox_AssistMaster();
			--Zorlen_debug("Using smart enemy target instead!") bad idea... reverting.
      if not UnitAffectingCombat("player") then
        LazyPigMultibox_AssistMaster()
      else
        LazyPigMultibox_AssistMaster()
        --LazyPigMultibox_TargetNearestEnemy(true, false)
      end
      --LazyPigMultibox_FollowMaster()
		end	
		
		if LPMULTIBOX.FA_DISMOUNT and LazyPigMultibox_Dismount() then
			return 
		end
		
		if LazyPigMultibox_Schedule() or LazyPigMultibox_ScheduleSpell() then
			return
		end
		
		if UnitExists("target") and (not Zorlen_isEnemy("target") or UnitIsDeadOrGhost("target"))  then
				-- Wenlock: what whats this supposed to be?
		end
    
		if sheepSafe:IsCrowdControlled() then
		  ClearTarget();
		end
    
		if dps or dps_pet or heal or rez or buff then
			
			local class = UnitClass("player")

			dps = dps and Zorlen_isEnemy("target") and (check2 or check3 or LPMULTIBOX.AM_ENEMY or Zorlen_isActiveEnemy("target") and (LPMULTIBOX.AM_ACTIVEENEMY or not UnitIsPlayer("target") and LPMULTIBOX.AM_ACTIVENPCENEMY))
			rez = rez and not UnitAffectingCombat("player")
			buff = buff and not UnitAffectingCombat("player") and not Zorlen_isEnemy("target")
			
			if dps and check2 and LazyPigMultibox_CheckDelayMode(true) then
				LazyPigMultibox_Annouce("lpm_masterattack", "")
			elseif LPM_TIMER.MASTERATTACK ~= 0 and LPM_TIMER.MASTERATTACK < time and not LPMULTIBOX.AM_ENEMY then
				dps = nil
			end
		
			LPM_DEBUG("LazyPigMultibox_UseClassScript")
			if class == "Paladin" then
				ZorlenX_Paladin(dps, dps_pet, heal, rez, buff);
			elseif class == "Shaman" then
				ZorlenX_Shaman(dps, dps_pet, heal, rez, buff);
			elseif class == "Druid" then
				ZorlenX_Druid(dps, dps_pet, heal, rez, buff);		
			elseif class == "Priest" then
				ZorlenX_Priest(dps, dps_pet, heal, rez, buff);
			elseif class == "Warlock" then
				ZorlenX_Warlock(dps, dps_pet, heal, rez, buff);
			elseif class == "Mage" then
				ZorlenX_Mage(dps, dps_pet, heal, rez, buff);
			elseif class == "Hunter" then
				ZorlenX_Hunter(dps, dps_pet, heal, rez, buff);
			elseif class == "Paladin" then
				ZorlenX_Paladin(dps, dps_pet, heal, rez, buff);
			elseif class == "Rogue" then
				ZorlenX_Rogue(dps, dps_pet, heal, rez, buff);
			elseif class == "Warrior" then
				ZorlenX_Warrior(dps, dps_pet, heal, rez, buff);
			end
			return true
		end	
		return nil
	end	
end

function FollowLeader()
  if isGrouped() then
    local leader = LazyPigMultibox_ReturnLeaderUnit()
    FollowUnit(leader)
  end
end

function isGrouped()
  return GetNumPartyMembers() > 0 or UnitInRaid("player")
end

local serve_time

function ZorlenX_RequestSmartTrade(message,sender_name)
  local time = GetTime()
  if not serve_time then
    serve_time = time - 1
  end
  if serve_time < time then
    serve_time = time + 1
  else 
    return false
  end
  if TradeFrame:IsVisible() then
    return AcceptTrade()
  end


  if message == "WATER" and Nok_ServeDrinks(sender_name) then
    return true
  elseif message == "HEALTHSTONE" and Nok_ServeHealthstone(sender_name) then
    player_is_serving = true
    return true
  elseif message == "POTIONS" and Nok_ServePortions(sender_name) then
    player_is_serving = true
    return true
  end
end

function ZorlenX_PickupContainerItemByName(item_name)
  local ParentID, ItemID = Zorlen_GiveContainerItemSlotNumberByName(item_name)
  PickupContainerItem(ParentID, ItemID)
end

function ZorlenX_DropItemOnPlayerByName(player_name)
  local sender_unit = LazyPigMultibox_ReturnUnit(player_name)
  DropItemOnUnit(sender_unit)
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

function ZorlenX_OrderDrinks()
  if usesMana(player) and not isMage("player") and not Zorlen_isMoving() and isGrouped() and Zorlen_notInCombat() then
    Zorlen_UpdateDrinkItemInfo()
    local bag, slot, fullcount, level = Zorlen_GetDrinkSlotNumber()
    if not fullcount then
      fullcount = 0
    end
    if fullcount < 5 then
      Zorlen_debug("Request water, only "..fullcount.." drinks left.")
      return LazyPigMultibox_Annouce("lpm_request_trade", "WATER")
    end
  end
  return false
end

function ZorlenX_ServeDrinks(player_name)
  if isMage("player") and ZorlenX_MageWaterCount() > 15 then
    local water_name = ZorlenX_MageWaterName()
    ZorlenX_PickupContainerItemByName(water_name)
    ZorlenX_DropItemOnPlayerByName(player_name)
    return true
  end
  return false
end

function ZorlenX_ServeHealthstone(player_name)
  --if isWarlock("player") and Nok_MageWaterCount() > 15 then
  --  local water_name = Nok_MageWaterName()
  --  Nok_PickupContainerItemByName(water_name)
  --  Nok_DropItemOnPlayerByName(player_name)
  --  return true
  --end
  return false
end

function ZorlenX_ServePortions(player_name)
  return false
end

function ZorlenX_MageConjure()
		if Zorlen_isChanneling() or Zorlen_isCasting() or UnitAffectingCombat("player") then
			return false
		end
    if Zorlen_ManaPercent("player") < 10 then
      return false
    end
    if isMage("player") and Nok_MageWaterCount() < 60 and Zorlen_castSpellByName("Conjure Water") then 
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

function ZorlenX_OutOfCombat()
    if isDrinkingActive() and Zorlen_ManaPercent("player") > 95  then
      SitOrStand()
    end
    
    if ZorlenX_OrderDrinks() then
      return
    end
    
    if Zorlen_isChanneling() or Zorlen_isCasting() or UnitAffectingCombat("player") then
			return
		end

    if not Zorlen_isMoving() and LazyPigMultibox_Rez() then
      return 
    end
    
    if not Zorlen_isMoving() and isWarlock("player") and LazyPigMultibox_SmartSS() then
      return
    end
    
    if not Zorlen_isMoving() and isMage("player") and ZorlenX_MageConjure() then
      return
    end

    if LazyPigMultibox_UnitBuff() then
      return
    end
    
    if Zorlen_Drink() then
      return
    end
end

function ZorlenX_UnitIsTank(unit)
  return isWarrior(unit) or isBearForm(unit) or isDireBearForm(unit)
end

function ZorlenX_GetTargetCurHP()
  local target_hp = MobHealth_GetTargetCurHP()
  if not target_hp then
    target_hp = 0
  end
  return target_hp
end

function ZorlenX_IsTotem(unit)
    if not UnitExists(unit) then
      return false
    end
    local targetName = UnitName(unit)
  	local t = {
      [LOCALIZATION_ZORLEN.GreaterHealingWard] = true,
      [LOCALIZATION_ZORLEN.LavaSpoutTotem] = true,
      [LOCALIZATION_ZORLEN.TremorTotem] = true,
      [LOCALIZATION_ZORLEN.EarthbindTotem] = true,
      [LOCALIZATION_ZORLEN.HealingStreamTotem] = true,
      [LOCALIZATION_ZORLEN.ManaTideTotem] = true,
      [LOCALIZATION_ZORLEN.ManaSpringTotem] = true,
      [LOCALIZATION_ZORLEN.SearingTotem] = true,
      [LOCALIZATION_ZORLEN.MagmaTotem] = true,
      [LOCALIZATION_ZORLEN.FireNovaTotem] = true,
      [LOCALIZATION_ZORLEN.GroundingTotem] = true,
      [LOCALIZATION_ZORLEN.WindfuryTotem] = true,
      [LOCALIZATION_ZORLEN.FlametongueTotem] = true,
      [LOCALIZATION_ZORLEN.StrengthOfEarthTotem] = true,
      [LOCALIZATION_ZORLEN.GraceOfAirTotem] = true,
      [LOCALIZATION_ZORLEN.StoneskinTotem] = true,
      [LOCALIZATION_ZORLEN.WindwallTotem] = true,
      [LOCALIZATION_ZORLEN.FireResistanceTotem] = true,
      [LOCALIZATION_ZORLEN.FrostResistanceTotem] = true,
      [LOCALIZATION_ZORLEN.NatureResistanceTotem] = true,
      [LOCALIZATION_ZORLEN.PoisonCleansingTotem] = true
	}
  return t[targetName]
end