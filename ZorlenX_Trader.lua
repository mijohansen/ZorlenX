
ZORLENX_TRADER = {}

function ZorlenX_RequestSmartTrade(message,sender_name)

  if ZorlenX_TimeLock("RequestSmartTrade", 2) then
    return false
  end

  if TradeFrame:IsVisible() then
    return AcceptTrade()
  end

  if message == "WATER" and ZorlenX_ServeDrinks(sender_name) then
    return true
  elseif message == "HEALTHSTONE" and ZorlenX_ServeHealthstone(sender_name) then
    return true
  elseif message == "POTIONS" and ZorlenX_ServePortions(sender_name) then
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
  --if TradeFrame:IsVisible() then
  --  return false
  --end
  if usesMana(player) and not isMage("player") and not Zorlen_isMoving() and isGrouped() and Zorlen_notInCombat() then
    Zorlen_UpdateDrinkItemInfo()
    local bag, slot, fullcount, level = Zorlen_GetDrinkSlotNumber()
    if not fullcount then
      fullcount = 0
    end
    if fullcount < 5 then
      ZorlenX_Log("Request water, only " .. fullcount .. " drinks left.")
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

function ZorlenX_OrderHealthstone()
  if isWarlock("player") then
    return false
  end

  if Zorlen_isMoving() or not isGrouped() then
    return false
  end

  if healthstoneExists() then
    return false
  end
  ZorlenX_Log("Request healthstone mofos!")
  return LazyPigMultibox_Annouce("zorlenx_request_trade", "HEALTHSTONE")

end

function ZorlenX_ServeHealthstone(player_name)
  local healthstoneName = healthstoneExists()
  if isWarlock("player") and healthstoneName then
    local water_name = ZorlenX_MageWaterName()
    ZorlenX_PickupContainerItemByName(healthstoneName)
    ZorlenX_DropItemOnPlayerByName(player_name)
    return true
  end
  return false
end

function ZorlenX_ServePortions(player_name)
  return false
end
