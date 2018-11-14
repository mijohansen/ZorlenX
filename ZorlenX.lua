--[[
@TODO
* TopMeOff functionalitey into the addon: https://github.com/Bergador/TopMeOff/blob/master/TopMeOff.lua
* Autotrade from Master to Slaves. Slaves will allways have full stacks of stuff.
* Need a real immune mob list. create from database
* Berserking should pop at some point for trolls
* evocation and other mana+ stuff dont need to be used when total enemy HP is below player HP
* Voidwalker should try to taunt enemies attacking cloth.
* Need combat strategies (heavy melee: ) / (Heavy Magic)
]]

function ZorlenX_OnLoad()
  ZorlenX_resetCombatScanner()
  sheepSafe:OnLoad()
  this:RegisterEvent("ADDON_LOADED")
  this:RegisterEvent("PLAYER_LOGIN")
  this:RegisterEvent("CHAT_MSG_ADDON")
  this:RegisterEvent("PARTY_MEMBERS_CHANGED")
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
  if(event == "PARTY_MEMBERS_CHANGED") then
    ZorlenX_Log("Party Members changed, updating stuff..")

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

-- COMBAT FUNCTIONS

function ZorlenX_DpsSingle()
  return ZorlenX_UseClassScript(false, false)
end

function ZorlenX_DpsSingleBurst()
  return ZorlenX_UseClassScript(false, true)
end

function ZorlenX_DpsAoe()
  return ZorlenX_UseClassScript(true, false)
end

function ZorlenX_DpsAoeBurst()
  return ZorlenX_UseClassScript(true, true)
end

function ZorlenX_DpsPanic()
  return ZorlenX_UseClassScript(false, false, true)
end

-- /script ZorlenX_UseClassScript()
function ZorlenX_UseClassScript(aoe, burst, panic)
  if not ZorlenX_TimeLock("ZorlenX_UseClassScript" , 0.5) then
    return false
  end

  if not LPMULTIBOX.STATUS then
    ZorlenX_Log("LPMULTIBOX is turned off.")
    return
  end

  local dps = LPMULTIBOX.SCRIPT_DPS
  local dps_pet = LPMULTIBOX.SCRIPT_DPSPET
  local heal = LPMULTIBOX.SCRIPT_HEAL or LPMULTIBOX.SCRIPT_FASTHEAL

  -- little trick to get slave status regardless of who is the party leader
  local isSlave = (true and IsControlKeyDown())
  burst = (true and burst)
  panic = (true and panic)
  -- just to get up if we know you are drinking.
  if isDrinkingActive() and Zorlen_ManaPercent("player") == 100 then
    SitOrStand()
  end

  if isTroll() and Zorlen_HealthPercent("player") < 25 and castBerserking() then
    ZorlenX_Log("Tried to cast berserking.")
    return true
  end

  -- spesific function for when casting evaluating target etc.
  if UnitExists("target") and Zorlen_isEnemy("target") then
    if Zorlen_isBreakOnDamageCC("target") or UnitIsDeadOrGhost("target") then
      backOffTarget()
      ZorlenX_Log("Tried to back off target.")
    end
  end

  -- We will not change target unless player is idle
  if not Zorlen_isCastingOrChanneling() then
    -- use health stone on low HP
    if Zorlen_HealthPercent("player") < 25 and Zorlen_inCombat() and useHealthstone() then
      ZorlenX_Log("Tried to use health stone.")
      return true
    end

    -- healers use mana potions
    if heal and playerIsManaUser() and Zorlen_ManaPercent("player") < 20 and Zorlen_inCombat() and useManaPotion() then
      ZorlenX_Log("Tried to use mana potion.")
      return true
    end

    -- other players use health potions
    if not heal and Zorlen_HealthPercent("player") < 20 and Zorlen_inCombat() and useHealthPotion() then
      ZorlenX_Log("Tried to use health potion.")
      return true
    end

    if not panic and not (isDireBearForm() or isBearForm()) and ZorlenX_TimeLock("DcrCleanTimeLock" , 1.5) and Dcr_Clean(false,false) then
      ZorlenX_Log("Tried to decursive.")
      return
    end

    -- added support for SheepSafe, just running the script when not Channeling or casting
    -- this should also stop casting... CC is more important, or is it?
    if not aoe and isSlave and ZorlenX_ccAbleTargetExists() and ZorlenX_SheepSafeUntargeted() then
      ZorlenX_Log("Tried to Crowdcontrol target.")
      return 
    end

    if not Zorlen_inCombat() and playerIsManaUser() and ZorlenX_OutOfCombat() then
      ZorlenX_Log("Doing quick out of combat stuff")
      return true
    end
    
    if dps or dps_pet or heal  then
      if isPaladin("player") then
        ZorlenX_Paladin(dps, dps_pet, heal, aoe, burst, panic, isSlave)
      elseif isShaman("player") then
        -- ZorlenX_Shaman(dps, dps_pet, heal, aoe, burst, panic, isSlave)
      elseif isDruid("player") then
        ZorlenX_Druid(dps, dps_pet, heal, aoe, burst, panic, isSlave)
      elseif isPriest("player") then
        ZorlenX_Priest(dps, dps_pet, heal, aoe, burst, panic, isSlave)
      elseif isWarlock("player") then
        ZorlenX_Warlock(dps, dps_pet, heal, aoe, burst, panic, isSlave)
      elseif isMage("player") then
        ZorlenX_Mage(dps, dps_pet, heal, aoe, burst, panic, isSlave)
      elseif isHunter("player") then
        -- ZorlenX_Hunter(dps, dps_pet, heal, aoe, burst, panic, isSlave)
      elseif isRogue("player") then
        -- ZorlenX_Rogue(dps, dps_pet, heal, aoe, burst, panic, isSlave)
      elseif isWarrior("player") then
        -- ZorlenX_Warrior(dps, dps_pet, heal, aoe, burst, panic, isSlave)
      end
    end	
  end

  if LPMULTIBOX.FA_DISMOUNT and LazyPigMultibox_Dismount() then
    ZorlenX_Log("Tried to Dismount")
    return 
  end

  if LazyPigMultibox_Schedule() or LazyPigMultibox_ScheduleSpell() then
    ZorlenX_Log("Tried to cast LazyPigMultibox scheduled spell.")
    return
  end

  return nil
end


-- OUT OF COMBAT RUN
-- /script ZorlenX_OutOfCombat()
function ZorlenX_OutOfCombat()
  -- Doing some spam avoide here.
  if ZorlenX_TimeLock("OutOfCombat", 1) then
    return false
  end

  if isDrinkingActive() and Zorlen_ManaPercent("player") == 100 then
    SitOrStand()
  end

  if ZorlenX_DruidEnsureCasterForm() then
    ZorlenX_Log("Ensuring Caster Form for druid")
    return true
  end

  -- casting doesnt affect trade. just trade!
  -- need to toggle so that concurrency never happens.
  if isMageInGroup() and ZorlenX_Toggle("OutOfCombatToggler") or ZorlenX_OrderDrinks() then
    ZorlenX_Log("Ordering Drinks")
  elseif isWarlockInGroup() and ZorlenX_OrderHealthstone() then
    ZorlenX_Log("Ordering Healthstone")
  end

  if Zorlen_isCastingOrChanneling() or Zorlen_inCombat() then
    ZorlenX_Log("In Combat og already casting skipping.")
    return true
  end

  if LPMULTIBOX.SCRIPT_REZ and not Zorlen_isMoving() and LazyPigMultibox_Rez() then
    ZorlenX_Log("Rezzing")
    return true 
  end

  if LPMULTIBOX.SCRIPT_BUFF and LazyPigMultibox_UnitBuff() then
    ZorlenX_Log("Buffing")
    return true
  end

  if isWarlock("player")  and not Zorlen_isMoving() and LazyPigMultibox_SmartSS() then
    ZorlenX_Log("Creating Soulstone")
    return true
  end

  if isWarlock("player")  and not Zorlen_isMoving() and ZorlenX_CreateHealthStone() then
    ZorlenX_Log("Creating Healthstone")
    return true
  end

  if isMage("player") and not Zorlen_isMoving() and  Zorlen_ManaPercent("player") > 60 and ZorlenX_MageConjure() then
    ZorlenX_Log("Conjuring water")
    return true
  end

  --if Zorlen_isMoving() and Zorlen_ManaPercent("player") > 90 then 
  -- throw som hots around.
  --end
  if Zorlen_Drink() then
    return true
  end
  return false
end

-- Utility Functions

function FollowLeader()
  if isGrouped() and not Zorlen_isCastingOrChanneling()  then
    local leader = LazyPigMultibox_ReturnLeaderUnit()
    FollowUnit(leader)
  end
end

function isSoftTarget(unit)
  if isMage(unit) or isWarlock(unit) or isPriest(unit) or isHunter(unit) or isRogue(unit) then
    return true
  end
  if isCasterForm() then
    return true
  end
  return false
end

function playerIsManaUser()
  local u = "player"
  return isCasterForm(u) or isShaman(u) or isWarlock(u) or isPriest(u) or isMage(u) or isPaladin(u) or isHunter(u)
end

function ZorlenX_isOutside()
  return not ZorlenX_inRaidOrDungeon()
end

function ZorlenX_inRaidOrDungeon()
  return (LazyPig_Raid() or LazyPig_Dungeon())
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

function isRareTarget()
  local target_type = UnitClassification("target")
  return (target_type == "elite" or target_type == "rareelite" or target_type == "worldboss")
end

function ZorlenX_GetTargetCurHP()
  local target_hp = MobHealth_GetTargetCurHP()
  if not target_hp then
    target_hp = 0
  end
  return target_hp
end

function ZorlenX_SmartPetTaunt()
  if LazyPigMultibox_IsPetSpellKnown(LOCALIZATION_ZORLEN.Torment) and isSoftTarget("targettarget") then
    zTorment()
  end
end

function ZorlenX_PetAttack()
  if Zorlen_isActiveEnemy("target") then
    if not LazyPigMultibox_CheckDelayMode(true) or not UnitExists("pettarget") or UnitIsPartyLeader("player") then
      PetAttack()
      ZorlenX_SmartPetTaunt()
    end	
  elseif not LazyPigMultibox_UtilizeTarget() then
    PetPassiveMode()
    PetFollow()
  end
end

function isTroll()
  return Zorlen_isCurrentRaceTroll
end

function isUndead()
  return Zorlen_isCurrentRaceUndead
end

function isDruidInGroup()
  return ZorlenX_classInGroup("DRUID")
end



function isHunterInGroup()
  return ZorlenX_classInGroup("HUNTER") 
end

function isPaladinInGroup()
  return ZorlenX_classInGroup("PALADIN") 
end

function isPriestInGroup()
  return ZorlenX_classInGroup("PRIEST") 
end

function isMageInGroup()
  return ZorlenX_classInGroup("MAGE") 
end

function isRogueInGroup()
  return ZorlenX_classInGroup("ROGUE") 
end

function isShamanInGroup()
  return ZorlenX_classInGroup("SHAMAN") 
end

function isWarlockInGroup()
  return ZorlenX_classInGroup("WARLOCK") 
end

function isWarriorInGroup()
  return ZorlenX_classInGroup("WARRIOR") 
end

function ZorlenX_classInGroup(className)
  local counter = nil
  local u = nil

  if UnitInRaid("player") then
    NumMembers = GetNumRaidMembers()
    counter = 1
    groupType = "raid"
  else
    NumMembers = GetNumPartyMembers()
    counter = 0
    groupType = "party"
  end

  while counter <= NumMembers do
    local unit = groupType .. "" .. counter
    if Zorlen_isClass(className, unit) and CheckInteractDistance(unit,2) then
      return true
    end
    counter = counter + 1
  end
  return false
end

function playerHaveHealthstone()
  local healthstoneNames =  {
    "Minor Healthstone",
    "Lesser Healthstone",
    "Healthstone",
    "Greater Healthstone",
    "Major Healthstone"
  }
  local existingHealthstoneName = false
  for i, healthstoneName in ipairs(healthstoneNames) do
    if Zorlen_GiveContainerItemCountByName(healthstoneName) == 1 then
      existingHealthstoneName = healthstoneName
    end
  end
  return existingHealthstoneName
end

function useHealthstone()
  local healthstoneName = playerHaveHealthstone()
  if healthstoneName and Zorlen_useContainerItemByName(healthstoneName) then
    return true  
  end
end

function playerHaveManaPotion()
  local potionItemIDs = { 
    13444,	-- Major Mana Potion
    13443,	-- Superior Mana Potion
    6149,	-- Greater Mana Potion
    3827,	-- Mana Potion
    3385,	-- Lesser Mana Potion
    2455,	-- Minor Mana Potion
  }
  for i, potionItemID in ipairs(potionItemIDs) do
    if Zorlen_GiveContainerItemCountByItemID(potionItemID) > 0 then
      return potionItemID
    end
  end
  return false
end

function playerHaveHealthPotion()
  local potionItemIDs = { 
    13446,	-- Major Healing Potion
    3928,	-- Superior Healing Potion
    1710,	-- Greater Healing Potion
    929,	-- Healing Potion
    4596,	-- Discolored Healing Potion
    858,	-- Lesser Healing Potion
    118,	-- Minor Healing Potion
  }
  for i, potionItemID in ipairs(potionItemIDs) do
    if Zorlen_GiveContainerItemCountByItemID(potionItemID) > 0 then
      return potionItemID
    end
  end
  return false
end

function useHealthPotion()
  local potionItemID = playerHaveHealthPotion()
  if not potionItemID then
    return false
  end
  return Zorlen_useContainerItemByItemID(potionItemID)
end

function useManaPotion()
  local potionItemID = playerHaveManaPotion()
  if not potionItemID then
    return false
  end
  return Zorlen_useContainerItemByItemID(potionItemID)
end
----------------- debug utilities -------
function ZorlenX_Debug(value)
  DEFAULT_CHAT_FRAME:AddMessage(to_string(value))
end

function ZorlenX_Log(msg,value)
  local playerTargetName = "<NoTarget>"
  if UnitExists("target") then
    local targetName = UnitName("target")
    if targetName then
      playerTargetName = targetName
    end
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
ZORLENX_TOGGLES = {}
function ZorlenX_Toggle(name)
  if ZORLENX_TOGGLES[name] then
    ZORLENX_TOGGLES[name] = false
    return true
  else
    ZORLENX_TOGGLES[name] = true
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