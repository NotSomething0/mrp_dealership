local config <const> = CDealershipConfig:new()

RegisterNetEvent('mimesis:dealerships:recieveShowroomState', function(dealershipName, vehicleDisplaySlots)
    local dealerships = config:getDealerships()

    for dealershipIndex = 1, #dealerships do
        local dealership = dealerships[dealershipIndex]

        if dealership:getName() == dealershipName then
            local dealershipShowroom = dealership:getShowroom()

            dealershipShowroom:setVehicleDisplaySlots(vehicleDisplaySlots)
            break
        end
    end
end)

RegisterNetEvent('mimesis:dealerships:updateShowroomSlot', function(dealershipName, vehicleDisplaySlot)
    local dealerships = config:getDealerships()

    for dealershipIndex = 1, #dealerships do
        local dealership = dealerships[dealershipIndex]

        if dealership:getName() == dealershipName then
            local dealershipShowroom = dealership:getShowroom()

            dealershipShowroom:createShowroomVehicle(vehicleDisplaySlot.index, vehicleDisplaySlot.vehicleModel,vehicleDisplaySlot.vehicleModelPrice, vehicleDisplaySlot.coordinates, vehicleDisplaySlot.heading)
            break
        end
    end
end)
