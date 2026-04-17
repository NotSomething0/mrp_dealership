---@class CTestDriveManager
---@field activeTests table<number, table> -- Maps source to test data
CTestDriveManager = lib.class('CTestDriveManager')

-- Configuration constants
local CONFIG = {
    TestDuration = 60, -- Seconds
    SpawnCoords = vec4(-895.5, -3298.5, 13.9, 58.0),
    ReturnCoords = vec3(-893.0, -3291.0, 13.9)
}

function CTestDriveManager:constructor()
    self.activeTests = {}
    print('^2[TestDriveManager]^7 Initialized')
end

---Starts a test drive for a player
---@param source number Player server ID
---@param model string Vehicle model name
function CTestDriveManager:startTestDrive(source, model)
    if self.activeTests[source] then
        return TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Already on a test drive!' })
    end

    -- Create the vehicle server-side (recommended for persistence/control)
    local vehicle = CreateVehicleServerSetter(joaat(model), "automobile", CONFIG.SpawnCoords.x, CONFIG.SpawnCoords.y,
        CONFIG.SpawnCoords.z, CONFIG.SpawnCoords.w)

    -- Wait for vehicle to exist
    while not DoesEntityExist(vehicle) do Wait(0) end

    local networkId = NetworkGetNetworkIdFromEntity(vehicle)

    self.activeTests[source] = {
        entity = vehicle,
        netId = networkId,
        startTime = os.time(),
        timer = SetTimeout(CONFIG.TestDuration * 1000, function()
            self:endTestDrive(source, "Time expired!")
        end)
    }

    -- Tell client to teleport into vehicle
    TriggerClientEvent('testdrive:client:setupVehicle', source, networkId, CONFIG.TestDuration)
end

---Ends the test drive and cleans up
---@param source number Player server ID
---@param reason string Message to show the player
function CTestDriveManager:endTestDrive(source, reason)
    local data = self.activeTests[source]
    if not data then return end

    -- Cleanup vehicle
    if DoesEntityExist(data.entity) then
        DeleteEntity(data.entity)
    end

    -- Teleport player back to showroom
    local ped = GetPlayerPed(source)
    SetEntityCoords(ped, CONFIG.ReturnCoords.x, CONFIG.ReturnCoords.y, CONFIG.ReturnCoords.z, false, false, false, false)

    self.activeTests[source] = nil
    TriggerClientEvent('ox_lib:notify', source, { type = 'inform', description = reason })
end

-- Create the singleton instance
local manager = CTestDriveManager:new()

-- Export for use in other scripts
exports('GetManager', function()
    return manager
end)
