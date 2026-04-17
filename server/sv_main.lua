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
    local player = Ox.GetPlayer(source --[[@as number]])

    if not player then
        return
    end

    --[[
    local dealership = dealershipManager:getDealershipByName(dealershipName)

    if not dealership then
        TriggerClientEvent('ox_lib:notify', player.source, {
            title = 'Denied',
            description = ('Failed to purchase vehicle %s is not a valid dealership'):format(dealershipName),
            type = 'error'
        })
        return
    end

    local showroom = dealership:getShowroom()
    local displaySlot = showroom:getVehicleDisplaySlot(displaySLotIndex)

    if not displaySlot then
        TriggerClientEvent('ox_lib:notify', player.source, {
            title = 
        })
        return
    end
    ]]

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

            if not creationPoint then
                TriggerClientEvent('ox_lib:notify', player.source, {
                    title = 'No creation point',
                    description = 'No vehicle creation points are avaliable at this time.',
                    type = 'error'
                })
                return
            end

            Ox.CreateVehicle({
                model = vehicleModel,
                owner = player.charId,
                stored = storeVehicle
            }, creationPoint.coordinates, creationPoint.heading)

            playerAccount.removeBalance({
                amount = vehicleModelPrice,
                message = string.format('Vheicle'),
                overdraw = false
            })

            TriggerClientEvent('ox_lib:notify', player.source, {
                title = 'Vehicle successfully purchased',
                description = 'Your new vehicle is waiting for you outside!',
                type = 'success'
            })
        end
    end
end)
