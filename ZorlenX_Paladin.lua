local unique_seal = "Seal of Wisdom"
local unique_judgement = "Judgement of Wisdom"
--local unique_seal = "Seal of the Crusader"
--local unique_judgement = "Judgement of the Crusader"
--local unique_seal = "Seal of Righteousness"


function ZorlenX_Paladin(dps, dps_pet, heal, aoe, burst, panic, isSlave)
  
	if Zorlen_isCastingOrChanneling()  then
		return true
	end
  
	if LazyPigMultibox_SmartSkillPaladin() then 
		return true
	end
	
	if heal and QuickHeal() then
    TargetUnit("playertarget") --trying to fix overheal issue by reselecting the player target
	end
  
  if targetEnemyAttackingCasters() and CheckInteractDistance("target", 3) and not Zorlen_isDieingEnemy("target") and castHammerOfJustice() then
    return true
  end
  
	if LazyPigMultibox_SmartWrath() then
		return
	end

	--if dps then
	--	castAttack()
	--else
	--	stopAttack()
	--end
  if targetMainTarget(isSlave) then
    castAttack()
    if ZorlenX_WisdomJudgement() then
      ZorlenX_Log("Doing Seal of wisdom.")
      return true
    end
  else
    stopAttack()
  end
end

function LazyPigMultibox_MultiSeal(dmg)
	if Zorlen_isEnemy("target") then 
		local active_seal = isSealActive()
		local judgement_range = LazyPigMultibox_IsSpellInRangeAndActionBar("Judgement")
    if active_seal and Zorlen_checkCooldownByName("Judgement") then
      castJudgement()
    end
  end
end

function ZorlenX_SealWisdom()
  local target_hp = ZorlenX_GetTargetCurHP()
  local player_hp = UnitHealthMax("player")
	if Zorlen_isEnemy("target") and isSealActive() and target_hp > 1.5 * player_hp then 
		local judgement_range = LazyPigMultibox_IsSpellInRangeAndActionBar("Judgement")
    local judged = Zorlen_checkDebuffByName("Judgement of Wisdom", "target")
    if not judged and isSealActive() and Zorlen_checkCooldownByName("Judgement") then
      return castJudgement()
    end
  end
  if not isSealActive() then 
    return Zorlen_castSpellByName("Seal of Wisdom")
  end
  return false
end

function LazyPigMultibox_SealCrusader(mode, dmg)
	if mode and Zorlen_isEnemy("target") then 
		local active_seal = isSealActive()
		local judgement_range = LazyPigMultibox_IsSpellInRangeAndActionBar("Judgement")
    local judged = Zorlen_checkDebuffByName(unique_judgement, "target")
    if(not judged and active_seal) and Zorlen_checkCooldownByName("Judgement") then
      castJudgement()
    end
    if not active_seal then 
      Zorlen_castSpellByName(unique_seal);
    end	
  end
end 

function LazyPigMultibox_SmartSeal(mode, dmg)
	if mode and Zorlen_isEnemy("target") then 
		local active_seal = isSealActive()
		local judgement_range = LazyPigMultibox_IsSpellInRangeAndActionBar("Judgement")
			
		if judgement_range and ((UnitClassification("target") == "elite" or UnitClassification("target") == "rareelite") and UnitHealth("target") > 4*UnitHealthMax("player") or UnitClassification("target") == "worldboss") then	
			if(not Zorlen_checkDebuffByName(unique_judgement, "target") or active_seal) and Zorlen_checkCooldownByName("Judgement") then
				castJudgement()
				if not active_seal then 
					Zorlen_castSpellByName(unique_seal);
				end	
			end
		end
	elseif dmg and CheckInteractDistance("target", 3) then
		castSealOfRighteousness()
	end	
end

function LazyPigMultibox_SmartSkillPaladin()
	local unit_help = nil
	
	if UnitAffectingCombat("player") then
		unit_help = Zorlen_GiveGroupUnitWithLowestHealth()
	end
	
	if Zorlen_HealthPercent("player") < 25 and UnitAffectingCombat("player") and not Zorlen_checkDebuffByName("Forbearance", "player") and (Zorlen_castSpellByName("Divine Shield") or Zorlen_castSpellByName("Divine Protection")) then
		return true
    
	elseif not unit_help or not UnitAffectingCombat(unit_help) then
    return false
    
	elseif not ZorlenX_UnitIsTank(unit_help) and Zorlen_IsSpellKnown("Blessing of Protection") and Zorlen_HealthPercent(unit_help) < 20 and CheckInteractDistance(unit_help, 1) and not Zorlen_checkDebuffByName("Forbearance", unit_help) and not Zorlen_checkBuffByName("Blessing of Protection", unit_help) and LazyPigMultibox_TargetUnit(unit_help) and Zorlen_castSpellByName("Blessing of Protection") then
		LazyPigMultibox_Annouce("lpm_slaveannouce","Blessing of Protection - "..GetUnitName(unit_help))
		LazyPigMultibox_Message("Blessing of Protection - "..GetUnitName(unit_help))	
		return true
	
	elseif Zorlen_IsSpellKnown("Lay on Hands") and CheckInteractDistance(unit_help, 1) and Zorlen_ManaPercent("player") < 10 and Zorlen_HealthPercent(unit_help) < 10 and LazyPigMultibox_TargetUnit(unit_help) and Zorlen_castSpellByName("Lay on Hands") then
		LazyPigMultibox_Annouce("lpm_slaveannouce","Lay on Hands - "..GetUnitName(unit_help))
		LazyPigMultibox_Message("Lay on Hands - "..GetUnitName(unit_help))
		return true
	
	elseif Zorlen_IsSpellKnown("Divine Favor") and Zorlen_HealthPercent(unit_help) < 40 and UnitAffectingCombat("player") and Zorlen_castSpellByName("Divine Favor") then
		return true	
		
	end
	return nil
end

function LazyPigMultibox_SmartWrath()
	local boss = UnitClassification("target") == "worldboss"
	if(not boss and Zorlen_isDieingEnemy("target")) then
		if(Zorlen_IsSpellKnown("Hammer of Wrath") and Zorlen_checkCooldownByName("Hammer of Wrath")) then
			return Zorlen_castSpellByName("Hammer of Wrath")
		end	
	end
end

function LazyPigMultibox_HammerOnAggro()
	if Zorlen_isEnemy("target") and UnitExists("targettarget") and UnitIsFriend("targettarget", "player") and UnitIsPlayer("targettarget") and CheckInteractDistance("target", 2) and Zorlen_checkCooldownByName("Hammer of Justice") and (SpellStopCasting() or 1) and Zorlen_castSpellByName("Hammer of Justice") then
		LazyPigMultibox_Annouce("lpm_slaveannouce","Hammer of Justice")
		return true
	end
	return false
end

function LazyPigMultibox_SmartIntervention()
		local cddi = Zorlen_checkCooldownByName("Divine Intervention")
		if cddi and UnitAffectingCombat("player") then
			if Zorlen_isCasting() then SpellStopCasting() end
			local InRaid = UnitInRaid("player")
			local PLAYER = "player"
			local group = nil
			local NumMembers = nil
			local counter = nil
			local u = nil
					
			local primary_rez_class = nil
			local secondary_rez_class = nil
			local master_class = nil
				
			if InRaid then
				NumMembers = GetNumRaidMembers()
				counter = 1
				group = "raid"
			else
				NumMembers = GetNumPartyMembers()
				counter = 0
				group = "party"
			end
						
			while counter <= NumMembers do
				if counter == 0 then
					u = PLAYER
				else
					u = group..""..counter
				end
				if(UnitExists(u) and not UnitIsDeadOrGhost(u) and not UnitIsUnit(u, "player") and UnitHealth(u) > 0 and UnitIsConnected(u) and (isPaladin(u) or isPriest(u) or isDruid(u)) and not Zorlen_checkBuffByName("Divine Intervention", u)) then
					if UnitIsPartyLeader(u) then
						master_class = u
						break
							
					elseif(isPaladin(u) or isPriest(u)) then
						primary_rez_class = u
							
					else
						secondary_rez_class = u
					end
				end
				counter = counter + 1
			end
				
			master_class = master_class or primary_rez_class or secondary_rez_class
			
			if master_class then
				TargetUnit(master_class)
				Zorlen_castSpellByName("Divine Intervention")
				
				LazyPigMultibox_Annouce("lpm_slaveannouce","Divine Intervention - "..GetUnitName(master_class))
				LazyPigMultibox_Message("Divine Intervention - "..GetUnitName(master_class))
			end
		elseif cddi then
			LazyPigMultibox_Annouce("lpm_slaveannouce","Divine Intervention - Only in Combat")
			LazyPigMultibox_Message("Divine Intervention - Only in Combat")
		else
			LazyPigMultibox_Annouce("lpm_slaveannouce","Divine Intervention - CD")
			LazyPigMultibox_Message("Divine Intervention - CD")
		end	
	return
end

function ZorlenX_WisdomJudgement()
  if Zorlen_isEnemy("target") then
    if not LazyPigMultibox_IsSpellInRangeAndActionBar("Judgement") then
      return false
    end
    if not isSealActive() then
      return castSealOfWisdom()
    end
    if isSealActive() and Zorlen_checkCooldownByName("Judgement") then
      return castJudgement()
    end
  end
end


function castHammerOfJustice(SpellRank)
	local z = {}
	z.Rank = SpellRank
	z.SpellName = LOCALIZATION_ZORLEN.HammerOfJustice
	z.DebuffName = z.SpellName
	z.DebuffTimer = 1
	return Zorlen_CastCommonRegisteredSpell(z)
end
