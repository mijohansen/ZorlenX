function ZorlenX_OnLoad()
  ZorlenX_resetCombatScanner()
  sheepSafe:OnLoad()
  ZorlenX_createMacros()
end

function ZorlenX_OnEvent(event)
  if(event == "CHAT_MSG_ADDON" and arg4 ~= GetUnitName("player")) then
    -- routing everything through the LPM announce function
    ZorlenX_MessageReceiver(arg1, arg2, arg4);
    LazyPigMultibox_Annouce(arg1, arg2, arg4);
  end
  sheepSafe:OnEvent()
end

-- for anouncements still use LazyPigMultibox_Annouce(mode, message, sender)
function ZorlenX_MessageReceiver(mode, message, sender)
  local sender_name = sender or "Player"
  if mode == "zorlenx_request_trade" then
    ZorlenX_RequestSmartTrade(message,sender_name);
  end 
end


function isSoftTarget(unit)
  if isMage(unit) or isWarlock(unit) or isPriest(unit) or isHunter(unit) or isRogue(unit) then
    return true
  end
  if isDruid(unit) and not isBearForm(unit) then
    return true
  end
  return false
end

-- /script ZorlenX_UseClassScript()
function ZorlenX_UseClassScript()
  local time = GetTime()
  if LPM_TIMER.SCRIPT_USE < time then	
    LPM_TIMER.SCRIPT_USE = time + 0.5
    local dps = LPMULTIBOX.SCRIPT_DPS
    local dps_pet = LPMULTIBOX.SCRIPT_DPSPET
    local heal = LPMULTIBOX.SCRIPT_HEAL or LPMULTIBOX.SCRIPT_FASTHEAL
    local playerIsSlave = not ZorlenX_PlayerIsLeader() and LazyPigMultibox_SlaveCheck()
    if not LPMULTIBOX.STATUS then
      ZorlenX_Logging("LPMULTIBOX.STATUS is turned off.")
      return
    end

    if playerIsSlave and not Zorlen_isChanneling() and not Zorlen_isCasting() then
      -- added support for Decursive, just running the script when not Channeling or casting
      if Dcr_Clean(false,false) then
        ZorlenX_Logging("Tried to decursive.")
        return
      end
      -- performing combat scan
      local COMBAT_SCANNER = ZorlenX_CombatScan()
      -- added support for SheepSafe, just running the script when not Channeling or casting
      if COMBAT_SCANNER.ccAbleTargetExists and (COMBAT_SCANNER.activeLooseEnemyCount > 1) and ZorlenX_SheepSafeUntargeted() then
        ZorlenX_Logging("Tried to sheepsafe.")
        return 
      end



      --  ingen targeting foregår før class scripts
      if dps or dps_pet or heal  then
        --doing some default selection when
        if COMBAT_SCANNER.activeLooseEnemyCount == 1 then
          LazyPigMultibox_AssistMaster()
        end

        dps = dps and Zorlen_isEnemy("target") and ( isGrouped() or LPMULTIBOX.AM_ENEMY or Zorlen_isActiveEnemy("target") and (LPMULTIBOX.AM_ACTIVEENEMY and LPMULTIBOX.AM_ACTIVENPCENEMY))
        if isPaladin("player") then
          ZorlenX_Paladin(dps, dps_pet, heal);
        elseif isShaman("player") then
          --ZorlenX_Shaman(dps, dps_pet, heal);
        elseif isDruid("player") then
          ZorlenX_Druid(dps, dps_pet, heal);	
        elseif isPriest("player") then
          ZorlenX_Priest(dps, dps_pet, heal);
        elseif isWarlock("player") then
          ZorlenX_Warlock(dps, dps_pet, heal);
        elseif isMage("player") then
          ZorlenX_Mage(dps, dps_pet, heal);
        elseif isHunter("player") then
          --ZorlenX_Hunter(dps, dps_pet, heal);
        elseif isRogue("player") then
          --ZorlenX_Rogue(dps, dps_pet, heal);
        elseif isWarrior("player") then
          --ZorlenX_Warrior(dps, dps_pet, heal);
        end
        return true
      end	
    end

    -- spesific function for when casting evaluating target etc.
    -- We will not change target unless player is idle
    if playerIsSlave and Zorlen_isCasting() and UnitExists("target") and Zorlen_isEnemy("target") then
      if ZorlenX_IsCrowdControlled() or UnitIsDeadOrGhost("target") then
        SpellStopCasting();
      end
    end

    if LPMULTIBOX.FA_DISMOUNT and LazyPigMultibox_Dismount() then
      return 
    end

    if LazyPigMultibox_Schedule() or LazyPigMultibox_ScheduleSpell() then
      return
    end

    return nil
  else
    return
  end	
end

function FollowLeader()
  if isGrouped() then
    local leader = LazyPigMultibox_ReturnLeaderUnit()
    FollowUnit(leader)
  end
end



function ZorlenX_OutOfCombat()
  if isDrinkingActive() and Zorlen_ManaPercent("player") > 95 then
    SitOrStand()
  end

  if ZorlenX_OrderDrinks() then
    return
  end

  if Zorlen_isChanneling() or Zorlen_isCasting() or UnitAffectingCombat("player") then
    return
  end

  if LPMULTIBOX.SCRIPT_REZ and not Zorlen_isMoving() and LazyPigMultibox_Rez() then
    return 
  end

  if not Zorlen_isMoving() and isWarlock("player") and LazyPigMultibox_SmartSS() then
    return
  end

  if not Zorlen_isMoving() and isMage("player") and ZorlenX_MageConjure() then
    return
  end

  if LPMULTIBOX.SCRIPT_BUFF and LazyPigMultibox_UnitBuff() then
    return
  end

  if Zorlen_Drink() then
    return
  end
end

function ZorlenX_PlayerIsLeader()
  local leader = LazyPigMultibox_ReturnLeaderUnit()
  return (leader and UnitIsUnit("player", leader))
end

function isGrouped()
  return GetNumPartyMembers() > 0 or UnitInRaid("player")
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


function ZorlenX_tableLength(T)
  local count = 0
  for _ in pairs(T) do 
    count = count + 1 
  end
  return count
end

function ZorlenX_tableKeys(T)
  local count = 0
  local keyset={}
  for k,v in pairs(T) do 
    count = count + 1 
    keyset[count]=k
  end
  return keyset
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
  if UnitClassification("target") == "worldboss" or bosses[unitName] then
    return true
  end
  return false
end
-- Zorlen_MakeMacro(name, macro, percharacter, macroicontecture, iconindex, replace, show, nocreate, replacemacroindex, replacemacroname)
function ZorlenX_createMacros()
  Zorlen_MakeMacro(".DPS", "/script ZorlenX_UseClassScript()",  0, "Hunter_SniperShot", nil, 1, 1, nil)
  Zorlen_MakeMacro(".DPS2", "/script ZorlenX_UseClassScript()", 0, "Hunter_SniperShot", nil, 1, 1, nil)
  Zorlen_MakeMacro(".AOE", "/script ZorlenX_UseClassScript()" , 0, "Hunter_SniperShot", nil, 1, 1, nil)
  Zorlen_MakeMacro(".PREP", "/script ZorlenX_OutOfCombat()"   , 0, "Hunter_SniperShot", nil, 1, 1, nil)
  Zorlen_MakeMacro(".Follow", "/script ZorlenX_OutOfCombat()" , 0, "Hunter_SniperShot", nil, 1, 1, nil)
end

----------------- debug utilities -------
function ZorlenX_Debug(value)
  DEFAULT_CHAT_FRAME:AddMessage("---")
  DEFAULT_CHAT_FRAME:AddMessage(to_string(value))
end

function ZorlenX_Logging(msg,value)
  ChatFrame3:AddMessage(msg,to_string(value))
end

function table_print (tt, indent, done)
  done = done or {}
  indent = indent or 0
  if type(tt) == "table" then
    local sb = {}
    for key, value in pairs (tt) do
      table.insert(sb, string.rep (" ", indent)) -- indent it
      if type (value) == "table" and not done [value] then
        done [value] = true
        table.insert(sb, key .. " = {\n");
        table.insert(sb, table_print (value, indent + 2, done))
        table.insert(sb, string.rep (" ", indent)) -- indent it
        table.insert(sb, "}\n");
      elseif "number" == type(key) then
        table.insert(sb, string.format("\"%s\"\n", tostring(value)))
      else
        table.insert(sb, string.format(
            "%s = \"%s\"\n", tostring (key), tostring(value)))
      end
    end
    return table.concat(sb)
  else
    return tt .. "\n"
  end
end

function to_string( tbl )
  if  "nil"       == type( tbl ) then
    return tostring(nil)
  elseif  "table" == type( tbl ) then
    return table_print(tbl)
  elseif  "string" == type( tbl ) then
    return tbl
  else
    return tostring(tbl)
  end
end