--[[


@TODO
* TopMeOff functionalitey into the addon: https://github.com/Bergador/TopMeOff/blob/master/TopMeOff.lua
* Autotrade from Master to Slaves. Slaves will allways have full stacks of stuff.
* 
Berserking should pop at some point. 

]]

function ZorlenX_OnLoad()
  ZorlenX_resetCombatScanner()
  sheepSafe:OnLoad()
  this:RegisterEvent("ADDON_LOADED")
  this:RegisterEvent("PLAYER_LOGIN")
  this:RegisterEvent("CHAT_MSG_ADDON")
end

function ZorlenX_OnEvent(event)
  if(event == "CHAT_MSG_ADDON" and arg4 ~= GetUnitName("player")) then
    -- routing everything through the LPM announce function

    ZorlenX_MessageReceiver(arg1, arg2, arg4)
    LazyPigMultibox_Annouce(arg1, arg2, arg4)
  end

  if(event == "ADDON_LOADED") then
    --just ensure that macros are created.
    -- ZorlenX_Log("Updating macros")
  end
  sheepSafe:OnEvent(event)
end

-- for anouncements still use LazyPigMultibox_Annouce(mode, message, sender)
function ZorlenX_MessageReceiver(mode, message, sender)
  local sender_name = sender or "Player"
  if mode == "zorlenx_request_trade" then
    ZorlenX_Log("Message Received from " .. arg4 .. ": " .. arg1 .. " - " .. arg2)
    ZorlenX_RequestSmartTrade(message,sender_name)
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

-- Eventhough I can count active enemies there will be need to solve for
-- CC etc.
function ZorlenX_DpsMultiTarget()
  return ZorlenX_UseClassScript(true)
end

function ZorlenX_DpsSingleTarget()
  return ZorlenX_UseClassScript()
end

function ZorlenX_isOutside()
  return not ZorlenX_inRaidOrDungeon()
end

function ZorlenX_inRaidOrDungeon()
  return (LazyPig_Raid() or LazyPig_Dungeon())
end


-- /script ZorlenX_UseClassScript()
function ZorlenX_UseClassScript(multitarget, spellcaster)
  local time = GetTime()
  if LPM_TIMER.SCRIPT_USE < time then	
    LPM_TIMER.SCRIPT_USE = time + 0.5
    local dps = LPMULTIBOX.SCRIPT_DPS
    local dps_pet = LPMULTIBOX.SCRIPT_DPSPET
    local heal = LPMULTIBOX.SCRIPT_HEAL or LPMULTIBOX.SCRIPT_FASTHEAL
    local playerIsSlave = not ZorlenX_PlayerIsLeader() and LazyPigMultibox_SlaveCheck()
    if not LPMULTIBOX.STATUS then
      ZorlenX_Log("LPMULTIBOX.STATUS is turned off.")
      return
    end

    if not Zorlen_isCastingOrChanneling() then
      -- added support for Decursive, just running the script when not Channeling or casting
      if Dcr_Clean(false,false) then
        ZorlenX_Log("Tried to decursive.")
        return
      end
      -- performing combat scan
      local COMBAT_SCANNER = ZorlenX_CombatScan()
      -- added support for SheepSafe, just running the script when not Channeling or casting
      if COMBAT_SCANNER.ccAbleTargetExists and (COMBAT_SCANNER.looseEnemies > 1) and ZorlenX_SheepSafeUntargeted() then
        ZorlenX_Log("Tried to sheepsafe.")
        return 
      end


      --  ingen targeting foregår før class scripts
      if dps or dps_pet or heal  then
        --doing some default targeting probably good to do that before running class scripts?
        --if COMBAT_SCANNER.looseEnemies == 1 then
        --end
        --LazyPigMultibox_AssistMaster()
        dps = dps and Zorlen_isEnemy("target") and ( isGrouped() or LPMULTIBOX.AM_ENEMY or Zorlen_isActiveEnemy("target") and (LPMULTIBOX.AM_ACTIVEENEMY and LPMULTIBOX.AM_ACTIVENPCENEMY))
        ZorlenX_Log("Running class script.")
        if isPaladin("player") then
          ZorlenX_Paladin(dps, dps_pet, heal, multitarget);
        elseif isShaman("player") then
          --ZorlenX_Shaman(dps, dps_pet, heal, multitarget);
        elseif isDruid("player") then
          ZorlenX_Druid(dps, dps_pet, heal, multitarget);	
        elseif isPriest("player") then
          ZorlenX_Priest(dps, dps_pet, heal, multitarget);
        elseif isWarlock("player") then
          ZorlenX_Warlock(dps, dps_pet, heal, multitarget);
        elseif isMage("player") then
          ZorlenX_Mage(dps, dps_pet, heal, multitarget);
        elseif isHunter("player") then
          --ZorlenX_Hunter(dps, dps_pet, heal, multitarget);
        elseif isRogue("player") then
          --ZorlenX_Rogue(dps, dps_pet, heal, multitarget);
        elseif isWarrior("player") then
          --ZorlenX_Warrior(dps, dps_pet, heal, multitarget);
        end
        return true
      end	
    end

    -- spesific function for when casting evaluating target etc.
    -- We will not change target unless player is idle
    if Zorlen_isCasting() and UnitExists("target") and Zorlen_isEnemy("target") then
      if ZorlenX_IsCrowdControlled() or UnitIsDeadOrGhost("target") then
        SpellStopCasting()
        ZorlenX_Log("Tried to stop spell due to bad target.")
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

-- 
function FollowLeader()
  if isGrouped() and not Zorlen_isCastingOrChanneling()  then
    local leader = LazyPigMultibox_ReturnLeaderUnit()
    FollowUnit(leader)
  end
end



function ZorlenX_OutOfCombat()
  -- Doing some spam avoide here.
  if ZorlenX_TimeLock("OutOfCombat", 1) then
    return true
  end

  if isDrinkingActive() and Zorlen_ManaPercent("player") == 100 then
    SitOrStand()
  end

  if ZorlenX_OrderDrinks() then
    return
  end

  if ZorlenX_DruidEnsureCasterForm() then
    return true
  end

  if Zorlen_isCastingOrChanneling() or UnitAffectingCombat("player") then
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
    ZorlenX_Log("Buffing complete", LPMULTIBOX)
    return
  end

  if Zorlen_isMoving() and Zorlen_ManaPercent("player") > 90 then 
    -- throw som hots around.
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

function ZorlenX_PetAttack()
  if Zorlen_isActiveEnemy("target") then
    if not LazyPigMultibox_CheckDelayMode(true) or not UnitExists("pettarget") or UnitIsPartyLeader("player") then
      PetAttack()
    end	
  elseif not LazyPigMultibox_UtilizeTarget() then
    PetPassiveMode()
    PetFollow()
  end
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
-- Zorlen_MakeMacro(LOCALIZATION_ZORLEN.EatMacroName, "/zorlen eat", 0, "Spell_Misc_Food", nil, 1, show)
-- /script ZorlenX_createMacros()
function ZorlenX_createMacros()
  local res = Zorlen_MakeMacro("1DPS", "/script ZorlenX_UseClassScript()", 0, "Ability_Druid_Maul", nil, 1,1)
  ZorlenX_Debug(res)
  Zorlen_MakeMacro("2DPS", "/script ZorlenX_UseClassScript()", 0, "Ability_Druid_Bash", nil, 1,1)
  Zorlen_MakeMacro("3AOE", "/script ZorlenX_UseClassScript()" , 0, "Ability_Whirlwind", nil, 1,1)
  Zorlen_MakeMacro("4OUT", "/script ZorlenX_OutOfCombat()"   , 0, "Spell_Misc_Drink", nil, 1,1)
  Zorlen_MakeMacro("0FOL", "/script FollowLeader()"         , 0, "Ability_Rogue_Sprint", nil, 1,1)
  Zorlen_MakeMacro("RELOADUI", "/console reloadui", 0, "Ability_Creature_Cursed_04", nil, 1, 1)
  Zorlen_MakeMacro("LEADER", "/console LazyPigMultibox_MakeMeLeader()", 0, "Hunter_Sniper", nil, 1, 1)

end

----------------- debug utilities -------
function ZorlenX_Debug(value)
  DEFAULT_CHAT_FRAME:AddMessage("---")
  DEFAULT_CHAT_FRAME:AddMessage(to_string(value))
end

function ZorlenX_Log(msg,value)
  local playerTargetName = UnitName("playertarget")
  if not playerTargetName then
    playerTargetName = "<Unknown>"
  end
  ChatFrame3:AddMessage("[" .. playerTargetName .. "]" .. msg,to_string(value))
end

ZORLENX_TIMELOCKS = {}
-- returns if something is timelocked. If not creates a new lock.
function ZorlenX_TimeLock(name,seconds)
  if ZORLENX_TIMELOCKS[name] and (ZORLENX_TIMELOCKS[name] + seconds) > GetTime() then
    return true
  else
    ZORLENX_TIMELOCKS[name] = GetTime()
    return false
  end
end

function round(input, places)
  if not places then places = 0 end
  if type(input) == "number" and type(places) == "number" then
    local pow = 1
    for i = 1, places do pow = pow * 10 end
    return math.floor(input * pow + 0.5) / pow
  end
end

function table_sum(t)
    local sum = 0
    for k,v in pairs(t) do
        sum = sum + v
    end
    return sum
end

function table_length(T)
  local count = 0
  for _ in pairs(T) do 
    count = count + 1 
  end
  return count
end

function table_keys(T)
  local count = 0
  local keyset={}
  for k,v in pairs(T) do 
    count = count + 1 
    keyset[count]=k
  end
  return keyset
end

function table_print(tt, indent, done)
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