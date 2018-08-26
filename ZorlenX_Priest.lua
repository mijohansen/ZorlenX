function ZorlenX_Priest(dps, dps_pet, heal)
	
	local locked = Zorlen_isChanneling() or Zorlen_isCasting()
	local shadow_form = Zorlen_checkBuffByName("Shadowform", "player")
	
	if locked then
		return
	end
	
	
	if heal and not shadow_form then
		local result = QuickHeal()
    if Zorlen_isCasting() then
      ZorlenX_Logging("Casting heal with QuickHeal")
      return
    end
	end
	
	if not heal and not shadow_form and Zorlen_castSpellByName("Shadowform") then
    ZorlenX_Log("Aquiring ShadowForm.")
		return
		
	elseif castInnerFire() then
    ZorlenX_Log("Aquiring InnerFire.")
		return
		
	elseif UnitAffectingCombat("player") and (Zorlen_isEnemyTargetingYou("target") or Zorlen_HealthPercent("player") < 50) and (LazyPig_Raid() or LazyPig_Dungeon() or Zorlen_HealthPercent("player") < 75) and (Zorlen_checkCooldownByName("Fade") or Zorlen_checkCooldownByName("Power Word: Shield") or Zorlen_checkCooldownByName("Stoneform")) then 
		if Zorlen_isCasting() then 
			SpellStopCasting();
			return 
		elseif isShootActive() then
			stopShoot();
			return
		elseif (Zorlen_castSpellByName("Fade") or castPowerWordShield() or CheckInteractDistance("target", 3) and Zorlen_castSpellByName("Stoneform")) then
			return
		end
	end	
	
	if dps then
    ZorlenX_PriestDps()
  else
    if heal and not isShootActive() and targetLowestHP() then
      -- just do some extra Wanding when in healmode
      ZorlenX_Log("Starting to use wand on target with lowest HP.")
      castShoot()
    end
	end
end

function ZorlenX_PriestDps()
		--local plague_stack = Zorlen_GetDebuffStack("Spell_Shadow_BlackPlague", "target")
    local plague_stack = 5
    local smite_enabled = false
		local fly_range = LazyPigMultibox_IsSpellInRangeAndActionBar("Mind Flay")
		local hi_mana = Zorlen_ManaPercent("player") > 20
		local inner_active = Zorlen_checkBuffByName("Inner Focus", "player")
    local target_hp = MobHealth_GetTargetCurHP()
    local target_type = UnitClassification("target")
    local rare_target = (target_type == "elite" or target_type == "rareelite" or target_type == "worldboss")
    local shadow_form = Zorlen_checkBuffByName("Shadowform", "player")
    if not target_hp then
      target_hp = 0
    end
    if COMBAT_SCANNER.totemExists and Zorlen_TargetTotem() then
      DEFAULT_CHAT_FRAME:AddMessage("Targeting Totem for destruction")
      if not isShootActive() then
        castShoot()
      end
      return true
    end
		if isShootActive() and (not Zorlen_IsTimer("ShadowRotation") or hi_mana or plague_stack < 5) then
			stopShoot();
			return
		end
		
		if Zorlen_HealthPercent("target") > 50 and Zorlen_checkCooldownByName("Mind Blast") and Zorlen_castSpellByName("Inner Focus") then
			return

		elseif not inner_active and not Zorlen_IsTimer("ShadowWordPain") and hi_mana and target_hp > UnitHealthMax("player") and castShadowWordPain() then
			Zorlen_SetTimer(1, "ShadowWordPain");
			Zorlen_SetTimer(9, "ShadowRotation");
			return
		
    elseif not inner_active and (rare_target or target_hp > 2*UnitHealthMax("player")) and castVampiricEmbrace() then
			return
		
		elseif (inner_active or isShadowWordPain() and Zorlen_ManaPercent("player") > 40) and castMindBlast() then
			Zorlen_SetTimer(9, "ShadowRotation");
			return
		
		elseif not Zorlen_IsTimer("ShadowWordPain") and (not Zorlen_IsTimer("ShadowRotation") or plague_stack < 5) and castShadowWordPain(1) then
			Zorlen_SetTimer(1, "ShadowWordPain");
			Zorlen_SetTimer(9, "ShadowRotation");
			return
		
		elseif fly_range and Zorlen_ManaPercent("player") > 20 and castMindFlay() then 
			Zorlen_SetTimer(9, "ShadowRotation");
			return
		
		elseif fly_range and (not Zorlen_IsTimer("ShadowRotation") or plague_stack < 5) and castMindFlay(1) then
			Zorlen_SetTimer(9, "ShadowRotation");
			return

		elseif not shadow_form and smite_enabled and castSmite() then
			return
			
		elseif plague_stack == 5 and not hi_mana and Zorlen_IsTimer("ShadowRotation") then
			castShoot();		
    elseif not hi_mana and not isShootActive() then
      castShoot();
    end
end