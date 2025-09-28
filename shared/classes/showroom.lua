local IS_SERVER <const> = IsDuplicityVersion()
local INVALID_SLOT_INDEX <const> = -1
local INVALID_VEHICLE_INDEX <const> = 0

local function getVehicleLabel(model)
    local make = GetLabelText(GetMakeNameFromVehicleModel(model))
    local name = GetLabelText(GetDisplayNameFromVehicleModel(model))
    if make == "NULL" then
        return name
    elseif name == "NULL" then
        return make
    end
    return ("%s %s"):format(make, name)
end

---@class CShowroom
---@field private private { m_config: CConfigStore, m_dealershipName:string, m_soldVehicleCategories: table, m_vehicleDisplaySlots: CVehicleDisplaySlot[], m_currentlySelectedDisplaySlot: CVehicleDisplaySlot? }
CShowroom = lib.class('CShowroom')

---Create a new instance of CShowroom
---@param config CConfigStore
---@param dealershipName string
---@param showroomInfo table
function CShowroom:constructor(config, dealershipName, showroomInfo)
    self.private.m_config = config
    self.private.m_dealershipName = dealershipName

    self:setSoldVehicleCategories(showroomInfo.soldVehicleCategories)

    if not IS_SERVER then
        self.private.m_currentlySelectedDisplaySlot = nil
    end

    if IS_SERVER then
        self:setVehicleDisplaySlots(showroomInfo.slots)
    end
end

function CShowroom:updateShowroomSlot(vehicleCategory, vehicleModelIndex)
    TriggerServerEvent('mimesis:dealership:requestUpdateShowroomSlot', self.private.m_dealershipName,
        self.private.m_currentlySelectedDisplaySlot:getIndex(), vehicleCategory, vehicleModelIndex)
end

---Get the entire showroom state
---@param serialize boolean Should the display slots be serialized to a table
---@return CVehicleDisplaySlot[]|table
function CShowroom:getShowroomState(serialize)
    local showroomState = {}

    for displaySlotIndex, displaySlot in pairs(self.private.m_vehicleDisplaySlots) do
        if serialize then
            showroomState[displaySlotIndex] = displaySlot:serialize()
        else
            showroomState[displaySlotIndex] = displaySlot
        end
    end

    return showroomState
end

---Get the sold vehicle categories
---@return table soldVehicleCategories
function CShowroom:getSoldVehicleCategories()
    return self.private.m_soldVehicleCategories
end

---Get showroom slots
---@return CVehicleDisplaySlot[]
function CShowroom:getVehicleDisplaySlots()
    return self.private.m_vehicleDisplaySlots
end

---comment
---@param displaySlotIndex number
---@return CVehicleDisplaySlot?
function CShowroom:getVehicleDisplaySlot(displaySlotIndex)
    return self.private.m_vehicleDisplaySlots[displaySlotIndex]
end

---Set the sold vehicle categories
---@param vehicleCategories table
function CShowroom:setSoldVehicleCategories(vehicleCategories)
    if type(vehicleCategories) ~= 'table' or #vehicleCategories < 1 then
        ---@todo: set defaults or something idk
        error('bad')
        return
    end

    self.private.m_soldVehicleCategories = {}

    for categoryIndex = 1, #vehicleCategories do
        local category = vehicleCategories[categoryIndex]:lower()
        table.insert(self.private.m_soldVehicleCategories, category)
    end
end

---Get a random vehicle model from the
---@return number
function CShowroom:getRandomVehicle()
    local vehicleCategories = self:getSoldVehicleCategories()
    local randomCategory = vehicleCategories[math.random(1, #vehicleCategories)]

    return self.private.m_config:getRandomVehicleFromCategory(randomCategory)
end

---Get the vehicle index from the specified slot index
---@param displaySlotIndex number
---@return number vehicleIndex
function CShowroom:getVehicleFromDisplaySlot(displaySlotIndex)
    local displaySlot = self.private.m_vehicleDisplaySlots[displaySlotIndex]

    if getmetatable(displaySlot) ~= CVehicleDisplaySlot then
        warn(('Attempted to get vehicle from display slot %s but it does not exist.'):format(displaySlotIndex))
        return INVALID_VEHICLE_INDEX
    end

    local vehicleIndex = displaySlot:getVehicleIndex()

    if not DoesEntityExist(vehicleIndex) then
        return INVALID_VEHICLE_INDEX
    end

    return vehicleIndex
end

---Get the current showroom display slot from the passed vehicle index or false if the vehicle isn't assigned a slot
---@param vehicleIndex number Vehicle handle
---@return CVehicleDisplaySlot|false vehicleDisplaySlot Vehicle slot
function CShowroom:getDisplaySlotFromVehicle(vehicleIndex)
    local vehicleDisplaySlots = self:getVehicleDisplaySlots()

    for displaySlotIndex = 1, #vehicleDisplaySlots do
        local vehicleDisplaySlot = vehicleDisplaySlots[displaySlotIndex]

        if vehicleDisplaySlot:getVehicleIndex() == vehicleIndex then
            return vehicleDisplaySlot
        end
    end

    return false
end

function CShowroom:createShowroomVehicles()
    local vehicleDisplaySlots = self:getVehicleDisplaySlots()

    for slotIndex, slotInfo in pairs(vehicleDisplaySlots) do
        local vehicleModel = slotInfo:getVehicleModel()
        local vehicleModelPrice = slotInfo:getVehicleModelPrice()
        local vehicleCoordinates = slotInfo:getCoordinates()
        local vehicleHeading = slotInfo:getHeading()

        self:createShowroomVehicle(slotIndex, vehicleModel, vehicleModelPrice, vehicleCoordinates, vehicleHeading)
    end
end

---Sets the currently selected vehicle
---@param selectedVehicle number
---@return CVehicleDisplaySlot? vehicleDisplaySlot
function CShowroom:setCurrentlySelectedDisplaySlot(selectedVehicle)
    local vehicleDisplaySlot = self:getDisplaySlotFromVehicle(selectedVehicle)

    if not vehicleDisplaySlot then
        return
    end

    self.private.m_currentlySelectedDisplaySlot = vehicleDisplaySlot

    return vehicleDisplaySlot
end

function CShowroom:addVehicleTargets(vehicleIndex)
    local dealershipName = self.private.m_dealershipName

    exports.ox_target:addLocalEntity(vehicleIndex, {
        label = 'Switch',
        icon = 'fa-solid fa-key',
        distance = 1.5,
        onSelect = function(data)
            self:setCurrentlySelectedDisplaySlot(data.entity)
            lib.showMenu(('dealership:%s'):format(dealershipName))
        end
    })

    exports.ox_target:addLocalEntity(vehicleIndex, {
        label = "Purchase",
        distance = 1.5,
        onSelect = function(data)
            local vehicleDisplaySlot = self:setCurrentlySelectedDisplaySlot(data.entity)

            if not vehicleDisplaySlot then
                return
            end

            local vehicleDisplayName = getVehicleLabel(vehicleDisplaySlot:getVehicleModel())

            local input = lib.inputDialog(
                ("Are you sure you want to purchase %s for $%s"):format(vehicleDisplayName,
                    vehicleDisplaySlot:getVehicleModelPrice()), {
                    { type = "checkbox", label = "Send to garage" }
                })

            if input then
                local storeVehicle = input[1]

                TriggerServerEvent('mimesis:dealerships:requestPurchaseVehicle',
                    dealershipName,
                    vehicleDisplaySlot:getIndex(),
                    storeVehicle
                )
            end

            self:setCurrentlySelectedDisplaySlot(INVALID_SLOT_INDEX)
        end
    })

    exports.ox_target:addLocalEntity(vehicleIndex, {
        label = "Test drive",
        distance = 1.5,
        onSelect = function(data)
            print('Test drive selected')
        end
    })
end

---Remove all targets for the locally passed vehicle
---@param vehicleIndex number
function CShowroom:removeVehicleTargets(vehicleIndex)
    exports.ox_target:removeLocalEntity(vehicleIndex)
end

function CShowroom:createShowroomVehicle(displaySlotIndex, vehicleModel, vehicleModelPrice, vehicleCoordinates, vehicleHeading)
    assert(not IS_SERVER, 'CDealership:createVehicle is not availble on the server')

    local vehicleDisplaySlot = self.private.m_vehicleDisplaySlots[displaySlotIndex]

    if not vehicleDisplaySlot then
        warn(('Attempted to create a showroom vehicle for display slot %s but the slot does not exist.'):format(
            displaySlotIndex))
        return
    end

    local success, err = pcall(lib.requestModel, vehicleModel)

    if not success then
        warn(('Failed to load vehicle model: %s'):format(err))
        return
    end

    if DoesEntityExist(vehicleDisplaySlot:getVehicleIndex()) then
        DeleteEntity(vehicleDisplaySlot:getVehicleIndex())
    end

    local isNetwork = false
    local netMissionEntity = false
    local vehicleIndex = CreateVehicle(vehicleModel, vehicleCoordinates.x, vehicleCoordinates.y, vehicleCoordinates.z,
        vehicleHeading, isNetwork, netMissionEntity)

    SetModelAsNoLongerNeeded(vehicleModel)

    local vehiclelockCannotEnter = 10

    SetVehicleOnGroundProperly(vehicleIndex)
    SetVehicleDoorsLocked(vehicleIndex, vehiclelockCannotEnter)
    FreezeEntityPosition(vehicleIndex, true)

    vehicleDisplaySlot:setVehicleModel(vehicleModel)
    vehicleDisplaySlot:setVehicleModelPrice(vehicleModelPrice)
    vehicleDisplaySlot:setVehicleIndex(vehicleIndex)

    self:addVehicleTargets(vehicleIndex)
    --self:setSlotVehicle(slotIndex, vehicleIndex)
end

---@param serializedData table
function CShowroom:setVehicleDisplaySlots(serializedData)
    self.private.m_vehicleDisplaySlots = {}

    if type(serializedData) ~= 'table' then
        warn(('CShowroom:setVehicleDisplaySlots: Failed to set vehicle display slots expected serializedData to be a table got %s')
            :format(type(serializedData)))
        return
    end

    for displaySlotIndex, displaySlotData in ipairs(serializedData) do
        if not displaySlotData?.vehicleModel then
            local randomVehicleInfo = self:getRandomVehicle()

            displaySlotData.vehicleModel = randomVehicleInfo.model
            displaySlotData.vehicleModelPrice = randomVehicleInfo.price
        end

        self.private.m_vehicleDisplaySlots[displaySlotIndex] = CVehicleDisplaySlot:new(
            displaySlotIndex,
            vector3(displaySlotData.coordinates.x, displaySlotData.coordinates.y, displaySlotData.coordinates.z),
            displaySlotData.heading,
            displaySlotData.vehicleModel,
            displaySlotData.vehicleModelPrice
        )
    end

    if not IS_SERVER then
        self:createShowroomVehicles()
    end
end

---Deletes all vehicles created in the showroom
function CShowroom:destroyShowroom()
    assert(not IS_SERVER, 'CShowroom:destroyShowroom is not avalible on the server')

    for displaySlotIndex = 1, #self.private.m_vehicleDisplaySlots do
        local displaySlot = self.private.m_vehicleDisplaySlots[displaySlotIndex]
        local vehicleIndex = displaySlot:getVehicleIndex()

        if DoesEntityExist(vehicleIndex) then
            DeleteEntity(vehicleIndex)
        end

        displaySlot:setVehicleIndex(INVALID_VEHICLE_INDEX)
    end
end
