

Zorlen_MakeMacro("RELOADUI", "/console reloadui", nil, "Ability_Creature_Cursed_04", nil, 1, 1)
Zorlen_MakeMacro("FOLLOW", "/script FollowLeader()", nil, "Hunter_SniperShot", nil, 1, 1)

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

  if message == "WATER" and ZorlenX_ServeDrinks(sender_name) then
    return true
  elseif message == "HEALTHSTONE" and ZorlenX_ServeHealthstone(sender_name) then
    player_is_serving = true
    return true
  elseif message == "POTIONS" and ZorlenX_ServePortions(sender_name) then
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

function ZorlenX_OrderDrinks()
  if usesMana(player) and not isMage("player") and not Zorlen_isMoving() and isGrouped() and Zorlen_notInCombat() then
    Zorlen_UpdateDrinkItemInfo()
    local bag, slot, fullcount, level = Zorlen_GetDrinkSlotNumber()
    if not fullcount then
      fullcount = 0
    end
    if fullcount < 5 then
      Zorlen_debug("Request water, only "..fullcount.." drinks left.")
      return LazyPigMultibox_Annouce("zorlenx_request_trade", "WATER")
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
  --if isWarlock("player") and ZorlenX_MageWaterCount() > 15 then
  --  local water_name = ZorlenX_MageWaterName()
  --  ZorlenX_PickupContainerItemByName(water_name)
  --  ZorlenX_DropItemOnPlayerByName(player_name)
  --  return true
  --end
  return false
end

function ZorlenX_ServePortions(player_name)
  return false
end
