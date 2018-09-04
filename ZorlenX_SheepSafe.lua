BINDING_HEADER_SheepSafe = "SheepSafe";	BINDING_NAME_SheepSafe = 
"SheepSafe";

BINDING_HEADER_SheepSafe = "SheepSafe";	BINDING_NAME_SheepSafeUntargeted = 
"SheepSafe Untargeted Target";

BINDING_HEADER_SheepSafe = "SheepSafe";	BINDING_NAME_FindUntargetedTarget = 
"Find Untargeted Target";

BINDING_HEADER_SheepSafe = "SheepSafe";	BINDING_NAME_SheepSafeCombo = 
"SheepSafe Targetted/Untargetted Combo";


--
-- SheepSafe
--
-- Copyright (c) 2005 Steve Kehlet
--
-- Revised to not sheep	non aggrored targets with SheepSafeUntargeted by Faithkills
-- Revised to not sheep	already	crowd controlled targets by Faithkills
-- Druid, Priest, Warlock added	by Faithkills
-- Raid	support	added by Faithkills
-- Key Binding Support by Faithkills
-- Visual Pretargetting	with Detect Magic for mages by Faithkills
--   (have framework for other classes but not sure what appropriate spell for it is)

sheepSafe = {}
sheepSafe.version = "2.1.3b"
sheepSafe.ccSlot = nil
sheepSafe.notificationSent = {}
sheepSafe.preTargetSpellCast = false
sheepSafe.inCombat = false
sheepSafe.lastMessage =	0;
sheepSafe.coolDown = 5;
sheepSafe.nextEventIsSheepBreaker = false;
sheepSafe.tattleMargin = 0.6;
sheepSafe.sheepMolester = ""
sheepSafe.sheepee = ""
sheepSafe.sheepBrokeTime = 0
sheepSafe.sheepHitTime = 0

sheepSafe.dots = {}
sheepSafe.dots["Spell_Shadow_CurseOfSargeras"] = true
sheepSafe.dots["Spell_Shadow_AbominationExplosion"] = true
sheepSafe.dots["Spell_Fire_Fireball02"]	= true
sheepSafe.dots["Spell_Fire_FlameBolt"] = true
sheepSafe.dots["Spell_Shadow_ShadowWordPain"] =	true
sheepSafe.dots["Spell_Holy_SearingLight"] = true
sheepSafe.dots["Ability_Hunter_Quickshot"] = true
sheepSafe.dots["Spell_Fire_FlameShock"]	= true
sheepSafe.dots["Spell_Fire_SelfDestruct"] = true
sheepSafe.dots["Spell_Arcane_StarFire"]	= true
sheepSafe.dots["Spell_Frost_IceStorm"] = true
sheepSafe.dots["Spell_Fire_Immolation"]	= true
sheepSafe.dots["Spell_Nature_StarFall"]	= true
sheepSafe.dots["Spell_Fire_Incinerate"]	= true
sheepSafe.dots["Spell_Shadow_LifeDrain02"] = true
sheepSafe.dots["Spell_Shadow_Haunting"]	= true
sheepSafe.dots["Spell_Nature_Cyclone"] = true
sheepSafe.dots["Spell_Nature_InsectSwarm"] = true
sheepSafe.dots["Spell_Shadow_Requiem"] = true

sheepSafe.ccs =	{}
sheepSafe.ccs["Spell_Nature_Polymorph"]	= true
sheepSafe.ccs["Ability_Sap"] = true
sheepSafe.ccs["Spell_Frost_ChainsOfIce"] = true	
sheepSafe.ccs["Spell_Nature_Slow"] = true
sheepSafe.ccs["Spell_Nature_Sleep"] = true
sheepSafe.ccs["Spell_Shadow_Cripple"] =	true
sheepSafe.ccs["Spell_Shadow_MindSteal"]	= true
sheepSafe.ccs["Ability_GolemStormBolt"]	= true

sheepSafe.molestVerbs = {}
sheepSafe.molestVerbs["hits"] = "hit"
sheepSafe.molestVerbs["crit"] = "hit"
sheepSafe.molestVerbs["crits"] = "hit"

sheepSafe.damageEvents = {}
sheepSafe.damageEvents["CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE"] = true
sheepSafe.damageEvents["CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE"] =	true
sheepSafe.damageEvents["CHAT_MSG_SPELL_SELF_DAMAGE"] = true
sheepSafe.damageEvents["CHAT_MSG_SPELL_PARTY_DAMAGE"] =	true
sheepSafe.damageEvents["CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE"]	= true
sheepSafe.damageEvents["CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE"] = true
sheepSafe.damageEvents["CHAT_MSG_COMBAT_FRIENDLYPLAYER_HITS"] = true
sheepSafe.damageEvents["CHAT_MSG_COMBAT_SELF_HITS"] = true
sheepSafe.damageEvents["CHAT_MSG_COMBAT_PET_HITS"] = true
sheepSafe.damageEvents["CHAT_MSG_COMBAT_PARTY_HITS"] = true
--sheepSafe.damageEvents["CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE"] = true
sheepSafe.damageEvents["CHAT_MSG_SPELL_PET_DAMAGE"] = true

sheepSafeConfig = {}

function sheepSafe:OnLoad()
  sheepSafe:chat("SheepSafe v"..self.version.." loaded.  Baaaahhhh.")
  this:RegisterEvent("PLAYER_ENTERING_WORLD")
  this:RegisterEvent("PLAYER_LEAVING_WORLD")
  this:RegisterEvent("VARIABLES_LOADED")
  SLASH_SHEEPSAFE1="/sheepsafe";
  SlashCmdList["SHEEPSAFE"] = self.Command;
end

function sheepSafe:OnEvent()
  if (event ==	"PLAYER_ENTERING_WORLD") then
    this:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    this:RegisterEvent("PLAYER_TARGET_CHANGED")
    this:RegisterEvent("PLAYER_REGEN_ENABLED")
    this:RegisterEvent("PLAYER_REGEN_DISABLED")
    if sheepSafeConfig.tattle then
      this:RegisterEvent("CHAT_MSG_SPELL_BREAK_AURA")
      this:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER")
      for evnt in self.damageEvents do
        sheepSafe:d(evnt)
        this:RegisterEvent(evnt)
      end
    end

  elseif (event == "VARIABLES_LOADED" ) then
    if not sheepSafe.ConfigDefaults then
      self:SetDefaults()
    end
    if not sheepSafeConfig then
      sheepSafeConfig = {}
    end
    for key, value in pairs(sheepSafe.ConfigDefaults) do
      if (sheepSafeConfig[key] == nil) then
        sheepSafeConfig[key] = value;
      end
    end
    self:SetClassDefaults()
    if self.ccicon then
      self:ScanActionBar()
    end

  elseif (event == "PLAYER_LEAVING_WORLD") then
    this:UnregisterEvent("ACTIONBAR_SLOT_CHANGED")
    this:UnregisterEvent("PLAYER_TARGET_CHANGED")
    this:UnregisterEvent("PLAYER_REGEN_ENABLED")
    this:UnregisterEvent("PLAYER_REGEN_DISABLED")
    if sheepSafeConfig.tattle then
      this:UnregisterEvent("CHAT_MSG_SPELL_BREAK_AURA")
      this:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER")
      for evnt in self.damageEvents do
        sheepSafe:d(evnt)
        this:UnregisterEvent(evnt)
      end
    end
  elseif (event == "ACTIONBAR_SLOT_CHANGED") then
    sheepSafe:ScanActionBar()
  elseif (event == "PLAYER_TARGET_CHANGED") then
    self.notificationSent =	{}
    self.preTargetSpellCast	= false
  elseif (event == "PLAYER_REGEN_ENABLED") then
    self.inCombat =	false
  elseif (event == "PLAYER_REGEN_DISABLED") then
    self.inCombat =	true
  elseif sheepSafeConfig.tattle and event == "CHAT_MSG_SPELL_BREAK_AURA" and string.find(arg1, self.cc.." is removed.") then
    local discard, discard, tsheepee = string.find(arg1, "^([%a ]+)'s "..self.cc.." is removed.")
    sheepSafe:d("possible sheepee : "..tsheepee)
    if (GetTime() - sheepSafe.sheepHitTime) <= sheepSafe.tattleMargin then
      sheepSafe:d("caught a sheep breaker")
      sheepSafe:SendMessage("#### "..sheepSafe:nilSafe(sheepSafe.sheepMolester).." broke "..self.ccverb2.."!!!")
    else
      sheepSafe.sheepBrokeTime = GetTime()
      sheepSafe:d("sheepBrokeTime set to : "..tostring(sheepSafe.sheepBrokeTime))
    end

  elseif sheepSafeConfig.tattle and self.damageEvents[event] and string.find(arg1, " for ") then  -- self.nextEventIsSheepBreaker and
    discard, discard, sheepSafe.sheepMolester = string.find(arg1, "^(%a+)")
    if sheepSafe.sheepMolester == "Your" or sheepSafe.sheepMolester == "You" then
      sheepSafe.sheepMolester = "I"
    end
    sheepSafe:d("sheep molester set to : "..sheepSafe.sheepMolester)
    local tsheepee = sheepSafe:findSheepee(arg1)
    sheepSafe:d("possible sheepee : "..tsheepee)

    if (GetTime() - sheepSafe.sheepBrokeTime) <= sheepSafe.tattleMargin then 	  	
      sheepSafe:d("caught a sheep breaker")

      local tsheepee = sheepSafe:findSheepee(arg1)
      sheepSafe:d("possible sheepee : "..tsheepee)
      sheepSafe:SendMessage("#### "..sheepSafe:nilSafe(sheepSafe.sheepMolester).." broke "..self.ccverb2.."!!!")
    else
      sheepSafe.sheepHitTime = GetTime()
      sheepSafe:d("sheepHitTime set to : "..tostring(sheepSafe.sheepHitTime).." sheepmolester set to : "..sheepSafe.sheepMolester)
    end
  end
end

function sheepSafe.Command(args)
  if not string.find(args," ") and sheepSafeConfig[args] ~= nil and type(sheepSafeConfig[args]) == "boolean" then
    if args	== "pretarget" and not sheepSafe.preTargetSpell then
      sheepSafe:p("pretargetting not available for your class")
    elseif args == "createmacro" then
      sheepSafe:CreateMacro();
    else
      sheepSafeConfig[args]	= not sheepSafeConfig[args]
      sheepSafe:p(args.." "..sheepSafe:boolToOnOff(sheepSafeConfig[args]))
    end
  else
    sheepSafe:p("invalid command, valid switches are warning, alert, tattle, debug, toggle")
  end
end

function sheepSafe:SheepSafe()
  if self == nil then
    self = sheepSafe
  end
  
  if not Zorlen_IsSpellKnown(self.cc) then
    ZorlenX_Log("Spell "..self.cc.." is unknown. Aborting.")
    return false
  end

  if self.ccSlot == nil then
    ZorlenX_Log("Can't find "..self.cc.." on your action bar.	Please	add it.")
    return false
  end

  if not UnitName("target") then
    ZorlenX_Log("No target.")
    return false
  end

  if Zorlen_isBreakOnDamageCC("target") then
    ZorlenX_Log("Target is Crowd Controlled, skipping...");
    return false
  end

  if not UnitCanAttack("player", "target") then
    ZorlenX_Log("Can't attack	that target.")
    return false
  end

  if UnitHealth("target") == 0 then
    ZorlenX_Log("Can't "..self.ccverb2.." target, target is dead.")
    return false
  end

  local creatureType =	UnitCreatureType("target")

  if not string.find(self.validtargets, creatureType) then
    ZorlenX_Log("Can't " .. self.ccverb2 .. " that target: not " .. self.validtargetsdesc)
    return false
  end

  local isUsable, notEnoughMana = IsUsableAction(self.ccSlot)
  if (isUsable	~= 1) then
    ZorlenX_Log(self.cc.." not ready.")
    return false
  end

  if (IsActionInRange(self.ccSlot) == 0) then
    ZorlenX_Log(self.cc.." not in range.")
    return false
  end

  local start,	duration, enable = GetActionCooldown(self.ccSlot)
  if (duration	~= 0) then
    ZorlenX_Log(self.cc.." not ready,	in cooldown.")
    return false
  end

  sheepSafe:d("pretarget:"..sheepSafe:BtoS(sheepSafeConfig.pretarget).." incombat:"..sheepSafe:BtoS(self.inCombat))
  local tmpp =	sheepSafe:nilSafe(self.preTargetSpell)
  if tmpp then
    ZorlenX_Log("pretarget spell: "..tmpp)
  end
  ZorlenX_Log("pretarget cast:"..sheepSafe:BtoS(self.preTargetSpellCast))
  if not self.inCombat	and sheepSafeConfig.pretarget and self.preTargetSpell and not self.preTargetSpellCast and not sheepSafe:AnyoneAggroed() then
    sheepSafe:NotifyPotentialSheepBreakers()
    CastSpellByName(self.preTargetSpell)
    self.preTargetSpellCast	= true
    return false
  end

  local message = "#### "..self.ccverb1.." "..UnitName("target").." ("..UnitHealth("target").."% health"
  local targetTarget =	UnitName("targettarget")
  if (targetTarget) then
    message =	message..", attacking "..targetTarget
  end
  message = message..")"

  sheepSafe:p(message)
  UseAction(self.ccSlot)

  if sheepSafeConfig.warning then
    sheepSafe:NotifyPotentialSheepBreakers()
    sheepSafe.scheduler.Schedule(.5, self.PeriodicCheckWhileCasting)
  end

  return true
end

SheepSafe = sheepSafe.SheepSafe

function sheepSafe:NotifyPotentialSheepBreakers()
  local i
  local tName = UnitName("target")
  local tLang
  if this then
    tLang =	this.language
  else
    tLang =	nil
  end

  if not sheepSafeConfig.warning then
    return
  end

  for i = 1, GetNumRaidMembers() do

    local name = UnitName("raid"..i)
    sheepSafe:d("NotifyPotentialSheepBreakers checking "..name)
    if not UnitIsUnit("player","raid"..i) then
      if (name and not self.notificationSent[name]) then
        if (UnitIsUnit("target", "raid"..i.."target")) then
          SendChatMessage("#### I'm "..self.ccverb1.." your target ("..tName.."),	please change targets!", "WHISPER", tLang, name)
          self.notificationSent[name] = 1
        end

        local petName =	UnitName("raidpet"..i)
        if (petName and	not self.notificationSent[petName] and UnitIsUnit("target", "raidpet"..i.."target")) then
          SendChatMessage("#### I'm "..self.ccverb1.." your PET's	target ("..tName.."), please change its	target!", "WHISPER", tLang, name)
          self.notificationSent[petName] = 1
        end
      end
    end
  end


  for i = 1, GetNumPartyMembers() do

    local name = UnitName("party"..i)
    sheepSafe:d("NotifyPotentialSheepBreakers	checking "..name)
    if (name and not self.notificationSent[name]) then
      if (UnitIsUnit("target", "party"..i.."target")) then
        SendChatMessage("#### I'm "..self.ccverb1.." your target ("..tName.."), please change targets!", "WHISPER",	tLang, name)
        self.notificationSent[name]	= 1
      end

      local petName = UnitName("partypet"..i)
      if (petName and not self.notificationSent[petName] and	UnitIsUnit("target", "partypet"..i.."target")) then
        SendChatMessage("#### I'm "..self.ccverb1.." your PET's target ("..tName.."), please change	its target!", "WHISPER", tLang,	name)
        self.notificationSent[petName] = 1
      end

    end
  end
end

function sheepSafe:PeriodicCheckWhileCasting()
  --sheepSafe.d("Re-checking potential	sheep breakers")
  sheepSafe:NotifyPotentialSheepBreakers()
  if (IsCurrentAction(sheepSafe.ccSlot)) then
    sheepSafe.scheduler.Schedule(.5,	sheepSafe.PeriodicCheckWhileCasting)
  end
end

function sheepSafe:ScanActionBar()
  sheepSafe.ccSlot = nil
  if not self.ccicon then
    return
  end
  sheepSafe:d("rescanning action bar...")
  local slot
  for slot=1, 120, 1 do 
    if (not GetActionText(slot)) then	-- ignore any Player macros :-)
      local text = GetActionTexture(slot)
      if (text) then
        if (string.find(text, self.ccicon))	then 
          sheepSafe:d("found "..self.cc.." at slot "..slot)
          self.ccSlot = slot
          break
        end
      end
    end
  end
end

-- Scheduler
-- We hook the PlayerFrame_OnUpdate function, which gets called	every frame
-- refrehs (i.e. about 30fps), and restore it when all jobs are	completed.
sheepSafe.scheduler = {}
sheepSafe.scheduler.queue = {}
sheepSafe.scheduler.lastCheck =	GetTime()
sheepSafe.scheduler.OriginalPlayerFrameOnUpdate	= PlayerFrame_OnUpdate
sheepSafe.scheduler.hooked = false

function sheepSafe.scheduler.PlayerFrameOnUpdate(elapsed)
  if (GetTime() >= sheepSafe.scheduler.lastCheck + .1)	then
    sheepSafe.scheduler.lastCheck = GetTime()
    sheepSafe.scheduler.CheckQueue()
  end
  sheepSafe.scheduler.OriginalPlayerFrameOnUpdate(elapsed)
end

function sheepSafe.scheduler.Schedule(secsFromNow, func)
  local job = {
    when = GetTime() + secsFromNow,
    func = func
  }
  --sheepSafe.d("scheduling job: now: "..GetTime()..",	when: "..job.when)
  table.insert(sheepSafe.scheduler.queue, job)
  -- hook the PlayerFrame_OnUpdate function
  if (not sheepSafe.scheduler.hooked) then
    sheepSafe.scheduler.hooked = true
    PlayerFrame_OnUpdate = sheepSafe.scheduler.PlayerFrameOnUpdate
  end
end

function sheepSafe.scheduler.CheckQueue()
  local numJobs = table.getn(sheepSafe.scheduler.queue)
  if (numJobs == 0) then
    -- restore the PlayerFrame_OnUpdate function if no jobs
    PlayerFrame_OnUpdate = sheepSafe.scheduler.OriginalPlayerFrameOnUpdate
    sheepSafe.scheduler.hooked = false
    return
  end

  local i = 1
  while i <= table.getn(sheepSafe.scheduler.queue) do
    local job	= sheepSafe.scheduler.queue[i]
    if (job.when <= GetTime()) then
      --sheepSafe.d("executing job, now: "..GetTime()..", when: "..job.when)
      job.func()
      table.remove(sheepSafe.scheduler.queue, i)
    else
      i = i + 1
    end
  end
end


function ZorlenX_SheepSafeUntargeted()
  if self == nil then
    self = sheepSafe
  end
  if not self.cc then
    return false
  end
  if UnitAffectingCombat("player") and ZorlenX_FindUntargetedTarget() then 
    return sheepSafe:SheepSafe()
  end
end


-- Utilities

function sheepSafe:chat(msg)
  DEFAULT_CHAT_FRAME:AddMessage(msg,0,.4,.8)
end

function sheepSafe:p(msg)
  sheepSafe:chat("## SheepSafe: "..msg)
  sheepSafe:trace(msg)
end

function sheepSafe:d(msg)
  if (sheepSafeConfig.debug) then
    sheepSafe:chat("### SheepSafe: "..msg)
  end
  sheepSafe:trace(msg)
end

-- provide optional Tracer module support, for debugging problems
function sheepSafe:trace(msg)
  if (tracer) then
    tracer.Log("SheepSafe", msg)
  end
end

function sheepSafe:SheepSafeCombo()
  if UnitExists("target")	and UnitCanAttack("player", "target") then
    sheepSafe:SheepSafe()
  else
    sheepSafe:SheepSafeUntargeted()
  end
end

SheepSafeCombo = sheepSafe.SheepSafeCombo

function sheepSafe:AnyoneAggroed()

  local name
  local nameTarget
  local petName
  local wrkUnit
  local wrkTarget

  if UnitAffectingCombat("player") or (UnitExists("pet") and UnitAffectingCombat("pet")) then
    return true
  end

  for i =	1, GetNumRaidMembers() do
    wrkUnit	= "raid"..i
    wrkTarget = wrkUnit.."target"
    name = UnitName(wrkUnit)

    if UnitAffectingCombat(wrkUnit) then
      return true
    end

    sheepSafe:d("checking "..name.."'s target")

--		if not UnitIsUnit("player",wrkUnit) then
    if name	and UnitExists(wrkTarget) and not UnitIsFriend(wrkUnit,wrkTarget) and UnitExists(wrkTarget.."target") then
      sheepSafe:d(name.." has	a target that has a target "..UnitName(wrkTarget.."target")..",	likely aggroed")
      return true;
    end

    wrkUnit	= "raidpet"..i
    wrkTarget = wrkUnit.."target"
    petName	= UnitName(wrkUnit)

    if petName then
      if UnitAffectingCombat(wrkUnit) then
        return true
      end
      sheepSafe:d(name.." has	a pet called "..petName)
      if UnitExists(wrkTarget) and not UnitIsFriend(wrkUnit,wrkTarget) and UnistExists(wrkTarget.."target") then
        sheepSafe:d(petName.." has a target that has a target "..UnitName(wrkTarget.."target")..", likely aggroed")
        return true;
      end
    end
--		end
  end

  for i =	1, GetNumPartyMembers()	do
    wrkUnit	= "party"..i
    wrkTarget = wrkUnit.."target"
    name = UnitName(wrkUnit)

    if UnitAffectingCombat(wrkUnit) then
      return true
    end

    sheepSafe:d("checking "..name.."'s target")

    if name	and UnitExists(wrkTarget) and not UnitIsFriend(wrkUnit,wrkTarget) and UnitExists(wrkTarget.."target") then
      sheepSafe:d(name.." has	a target that has a target "..UnitName(wrkTarget.."target")..",	likely aggroed")
      return true;
    end

    wrkUnit	= "partypet"..i
    wrkTarget = wrkUnit.."target"
    petName	= UnitName(wrkUnit)

    if petName then
      if UnitAffectingCombat(wrkUnit) then
        return true
      end
      sheepSafe:d(name.." has	a pet called "..petName)
      if UnitExists(wrkTarget) and not UnitIsFriend(wrkUnit,wrkTarget) and UnistExists(wrkTarget.."target") then
        sheepSafe:d(petName.." has a target that has a target "..UnitName(wrkTarget.."target")..", likely aggroed")
        return true;
      end
    end
  end
  sheepSafe:d("no	one has	a target that has a target, l.ikely no one is aggroed")
  return false
end

function ZorlenX_IsDotted()
  local tdb
  local stripped
  for i=1,16 do
    tdb = UnitDebuff("target",i);
    if tdb then
      stripped = string.sub(tdb,17)
      if sheepSafe.dots[stripped] then
        return true
      end
    else
      return false
    end
  end
end

function sheepSafe:SendMessage(message)
  if ((GetTime() - self.lastMessage) <= self.coolDown) then
    return
  end
  self.lastMessage = GetTime()
  if not sheepSafeConfig.alert then
    sheepSafe:p(message)
  elseif (GetNumRaidMembers() > 0) then
    SendChatMessage(message, "RAID")
  elseif (GetNumPartyMembers() > 0) then
    SendChatMessage(message, "PARTY")
  else
    sheepSafe:p(message)
  end
end

function sheepSafe:CreateMacro()
  local macid = GetMacroIndexByName("SheepSafe")
  local iconid = sheepSafe:FindIconId(self.ccicon)
  if macid == 0 and iconid ~= 0 then
    macid =	CreateMacro("SheepSafe",iconid,"/script	SheepSafeCombo();",1,1)
  end
end

function sheepSafe:FindIconId(iconpath)
  for i =	1, GetNumMacroIcons() do
    if (string.find(GetMacroIconInfo(i), iconpath))	then
      return i;
    end
  end
  return 0	
end

function sheepSafe:BtoS(boo)
  if type(boo) ~= "boolean" then
    return "not boolean "..type(boo)
  elseif boo then
    return "true"
  else
    return "false"
  end
end

function sheepSafe:nilSafe(str)
  if str then
    return str
  else
    return "nil"
  end
end

function sheepSafe:boolToOnOff(bool)
  if bool	then
    return "on"
  else
    return "off"
  end
end

function sheepSafe:findSheepee(ar)
  local tresult = string.gsub (ar, "%a+", 
    function (str)
      return sheepSafe.molestVerbs[str] or str
    end
  )
  sheepSafe:d("tresult : "..tresult)
  local discard, discard, tsheepee = string.find(tresult," hit (.+) for ")
  if not tsheepee then
    tsheepee = ""
  end
  return tsheepee
end

function sheepSafe:SetClassDefaults()
  -- setting some defaults that can be used later
  if sheepSafeConfig.toggle == nil then
    sheepSafeConfig.toggle = true
  end
  self.cc = false
  if isMage("player") then
    self.cc	= "Polymorph";
    self.preTargetSpell = "Detect Magic";
    self.ccicon = "Spell_Nature_Polymorph";
    self.ccverb1 = "SHEEPING";
    self.ccverb2 = "sheep";
    self.validtargets = "Beast,Humanoid,Critter";
    self.validtargetsdesc =	"Beast,	Humanoid or Critter.";
    if sheepSafeConfig.pretarget == nil then
      sheepSafeConfig.pretarget = true
    end
    if sheepSafeConfig.tattle == nil then
      sheepSafeConfig.tattle = true
    end
  elseif isPriest("player") then
    self.cc	= "Shackle Undead";
    self.preTargetSpell = "Mind Vision";
    self.ccicon = "Spell_Nature_Slow";
    self.ccverb1 = "SHACKLING";
    self.ccverb2 = "shackle";
    self.validtargets = "Undead";
    self.validtargetsdesc =	"Undead.";
    if sheepSafeConfig.pretarget == nil then
      sheepSafeConfig.pretarget = false
    end
    if sheepSafeConfig.tattle == nil then
      sheepSafeConfig.tattle = false
    end
  elseif isWarlock("player") then
    self.cc	= "Banish";
    self.preTargetSpell = nil;
    self.ccicon = "Spell_Shadow_Cripple"
    self.ccverb1 = "BANISHING";
    self.ccverb2 = "banish";
    self.validtargets = "Demon,Elemental";
    self.validtargetsdesc =	"Demon or Elemental.";
    if sheepSafeConfig.pretarget == nil then
      sheepSafeConfig.pretarget = false
    end
    if sheepSafeConfig.tattle == nil then
      sheepSafeConfig.tattle = false
    end
  elseif isDruid("player") then
    self.cc	= "Hibernate";
    self.preTargetSpell = nil;
    self.ccicon = "Spell_Nature_Sleep";
    self.ccverb1 = "SLEEPING";
    self.ccverb2 = "sleep";
    self.validtargets = "Beast,Dragonkin";
    self.validtargetsdesc =	"Beast or Dragonkin.";
    if sheepSafeConfig.pretarget == nil then
      sheepSafeConfig.pretarget = false
    end
    if sheepSafeConfig.tattle == nil then
      sheepSafeConfig.tattle = false
    end
  else
    return
  end
end

function sheepSafe:SetDefaults()
  sheepSafe.ConfigDefaults = {}
  sheepSafe.ConfigDefaults.alert	= true
  sheepSafe.ConfigDefaults.warning = false
  sheepSafe.ConfigDefaults.debug	= false
end
