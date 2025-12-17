local config <const> = CDealershipConfig:new()

RegisterNetEvent('mimesis:dealerships:requestShowroomState', function(dealershipName)
    local dealerships = config:getDealerships()

    for dealershipIndex = 1, #dealerships do
        local dealership = dealerships[dealershipIndex]

        if dealership:getName() == dealershipName then
            local dealershipShowroom = dealership:getShowroom()

            TriggerClientEvent('mimesis:dealerships:recieveShowroomState', source --[[@as number]], dealershipName, dealershipShowroom:getShowroomState(true))
        end
    end
end)

RegisterNetEvent('mimesis:dealership:requestUpdateShowroomSlot', function(dealershipName, displaySlotIndex, vehicleCategory, vehicleCategoryIndex)
    local dealerships = config:getDealerships()

    for dealershipIndex = 1, #dealerships do
        local dealership = dealerships[dealershipIndex]

        if dealership:getName() == dealershipName then
            local dealershipShowroom = dealership:getShowroom()
            local vehicleDisplaySlot = dealershipShowroom:getVehicleDisplaySlot(displaySlotIndex)

            if not vehicleDisplaySlot then
                warn(('Attempted to update vehicle display slot at index %s but it does not exist.'):format(displaySlotIndex))
                return
            end

            local vehicleInfo = config:getVehiclesByCategory(vehicleCategory)[vehicleCategoryIndex]

            vehicleDisplaySlot:setVehicleModel(vehicleInfo.model)
            vehicleDisplaySlot:setVehicleModelPrice(vehicleInfo.price)

            TriggerClientEvent('mimesis:dealerships:updateShowroomSlot', source --[[@as number]], dealershipName, vehicleDisplaySlot:serialize())
        end
    end
end)

RegisterNetEvent('mimesis:dealerships:requestPurchaseVehicle', function(dealershipName, displaySlotIndex, storeVehicle)
    local player = Ox.GetPlayer(source)

    if not player then
        return
    end

    local dealerships = config:getDealerships()

    for dealershipIndex = 1, #dealerships do
        local dealership = dealerships[dealershipIndex]

        if dealership:getName() == dealershipName then
            local dealershipShowroom = dealership:getShowroom()
            local vehicleDisplaySlot = dealershipShowroom:getVehicleDisplaySlot(displaySlotIndex)

            if not vehicleDisplaySlot then
                warn(('Attempted to update vehicle display slot at index %s but it does not exist.'):format(displaySlotIndex))
                return
            end

            local vehicleModel = vehicleDisplaySlot:getVehicleModel()
            local vehicleModelPrice = vehicleDisplaySlot:getVehicleModelPrice()
            local playerAccount = player.getAccount()

            if not playerAccount or playerAccount.get('balance') < vehicleModelPrice then
                TriggerClientEvent('ox_lib:notify', player.source, {
                    title = 'Insufficient funds',
                    description = 'You do not have the appropriate funds to purchase this vehicle',
                    type = 'error'
                })
                return
            end

            local creationPoint = dealership:getAvailableVehicleCreationPoint()

            Ox.CreateVehicle({
                model = vehicleModel,
                owner = player.charId,
                stored = storeVehicle
            }, creationPoint.coordinates, creationPoint.heading)

            playerAccount.removeBalance(vehicleModelPrice)

            TriggerClientEvent('ox_lib:notify', player.source, {
                title = 'Vehicle successfully purchased',
                description = 'Your new vehicle is waiting for you outside!',
                type = 'success'
            })
        end
    end
end)
