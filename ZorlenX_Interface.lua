function ZorlenX_EnsureMacroInBinding(targetBinding, name, command, texture)
  local success = Zorlen_MakeMacro(name, "/script " .. command, 0, texture, nil, 1,1)
  if success then
    local macroIndex = GetMacroIndexByName(name)
    PickupMacro(macroIndex)
    PlaceAction(targetBinding)
  else
    ZorlenX_Log("Error creating Macro")
  end
end
-- /script ZorlenX_ConfigureAddons()
function ZorlenX_ConfigureAddons()
  local aux = require 'aux'; 
  local tooltip_settings = aux.character_data'tooltip';
  tooltip_settings.value = true
  tooltip_settings.merchant_buy = true 
  tooltip_settings.disenchant_value = true 
  tooltip_settings.disenchant_distribution = true 
end
-- /script ZorlenX_InitInterface()
-- /script DisableAddOn("pfQuest")
function ZorlenX_InitInterface()
  --combat
  ZorlenX_EnsureMacroInBinding(61,"DPS",    "ZorlenX_DpsSingle()",      "Ability_Druid_Maul")
  ZorlenX_EnsureMacroInBinding(62,"DPSx",   "ZorlenX_DpsSingleBurst()", "Ability_Druid_Bash")
  ZorlenX_EnsureMacroInBinding(63,"AOE",    "ZorlenX_DpsAoe()",         "Ability_Whirlwind")
  ZorlenX_EnsureMacroInBinding(64,"AOEx",   "ZorlenX_DpsAoeBurst()",    "Ability_Whirlwind")
  ZorlenX_EnsureMacroInBinding(65,"PANIC",  "ZorlenX_DpsPanic()",       "Ability_Druid_Cower")

  ZorlenX_EnsureMacroInBinding(1,"DPS",    "ZorlenX_DpsSingle()",      "Ability_Druid_Maul")
  ZorlenX_EnsureMacroInBinding(2,"DPSx",   "ZorlenX_DpsSingleBurst()", "Ability_Druid_Bash")
  ZorlenX_EnsureMacroInBinding(3,"AOE",    "ZorlenX_DpsAoe()",         "Ability_Whirlwind")
  ZorlenX_EnsureMacroInBinding(4,"AOEx",   "ZorlenX_DpsAoeBurst()",    "Ability_Whirlwind")
  ZorlenX_EnsureMacroInBinding(5,"PANIC",  "ZorlenX_DpsPanic()",       "Ability_Druid_Cower")
  --other
  ZorlenX_EnsureMacroInBinding(10,"OOC",    "ZorlenX_OutOfCombat()",          "Spell_Misc_Drink")
  ZorlenX_EnsureMacroInBinding(70,"OOC",    "ZorlenX_OutOfCombat()",          "Spell_Misc_Drink")
  ZorlenX_EnsureMacroInBinding(49,"FOLLOW", "FollowLeader()",                 "Ability_Rogue_Sprint")
  ZorlenX_EnsureMacroInBinding(51,"LEADER", "LazyPigMultibox_MakeMeLeader()", "Ability_Rogue_Sprint")
  ZorlenX_EnsureMacroInBinding(58,"RESET",  "ResetInstances()",               "Ability_CheapShot")
  ZorlenX_EnsureMacroInBinding(60,"RELOAD", "ReloadUI()",                     "Ability_Creature_Cursed_04")
end
-- Zorlen_MakeMacro(name, macro, percharacter, macroicontecture, iconindex, replace, show, nocreate, replacemacroindex, replacemacroname)
-- Zorlen_MakeMacro(LOCALIZATION_ZORLEN.EatMacroName, "/zorlen eat", 0, "Spell_Misc_Food", nil, 1, show)
-- /script ZorlenX_createMacros()
function ZorlenX_createMacros()
  local res = Zorlen_MakeMacro("1DPS", "/script ZorlenX_UseClassScript()", 0, "Ability_Druid_Maul", nil, 1,1)
  Zorlen_MakeMacro("2DPS", "/script ZorlenX_UseClassScript()", 0, "Ability_Druid_Bash", nil, 1,1)
  Zorlen_MakeMacro("3AOE", "/script ZorlenX_UseClassScript()" , 0, "Ability_Whirlwind", nil, 1,1)
  Zorlen_MakeMacro("4OUT", "/script ZorlenX_OutOfCombat()"   , 0, "Spell_Misc_Drink", nil, 1,1)
  Zorlen_MakeMacro("0FOL", "/script FollowLeader()"         , 0, "Ability_Rogue_Sprint", nil, 1,1)
  Zorlen_MakeMacro("RELOADUI", "/console reloadui", 0, "Ability_Creature_Cursed_04", nil, 1, 1)
  Zorlen_MakeMacro("LEADER", "/console LazyPigMultibox_MakeMeLeader()", 0, "Hunter_Sniper", nil, 1, 1)
end

-- /script ZorlenX_Debug(SMARTBUFF_Buffs["PartyX"]["Thorns"]["HUNTER"])
-- SMARTBUFF_Buffs["Party"]["Thorns"]["WPET"] = true