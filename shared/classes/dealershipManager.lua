local IS_SERVER <const> = IsDuplicityVersion()
local INVALID_BLIP_ID <const> = -1

---@param dealershipIndex number
---@param dealershipConfiguration table
---@return boolean valid
---@return string validationError
local function validateDealership(dealershipIndex, dealershipConfiguration)
  if type(dealershipConfiguration?.name) ~= 'string' then
    return false, ('Dealership at index #%d is missing the required \'name\' component.'):format(dealershipIndex)
  end

  if type(dealershipConfiguration?.point) ~= 'table' then
    return false, ('Dealership at index #%d is missing the required \'point\' component.'):format(dealershipIndex)
  end

  if not dealershipConfiguration?.blip then
    return false, ('Dealership "%s" is missing the required \'blip\' component.'):format(dealershipConfiguration.name)
  end

  if not dealershipConfiguration?.interact then
    return false, ('Dealership "%s" is missing the required \'interact\' component.'):format(dealershipConfiguration.name)
  end

  if not dealershipConfiguration?.spawns then
    return false, ('Dealership "%s" is missing the required \'spawns\' component.'):format(dealershipConfiguration.name)
  end

  return true, ('Validated dealership "%s"'):format(dealershipConfiguration.name)
end

---@class CDealershipManager
---@field private private { m_dealerships: table<string, CDealership>, m_config: CDealershipConfig }
CDealershipManager = lib.class('CDealershipManager')

---Creates a new instance of CDealershipManager
---@param config CDealershipConfig The configuration store for dealerships
function CDealershipManager:constructor(config)
  self.private = {}
  self.private.m_dealerships = {}
  self.private.m_config = config

  self:initializeDealerships()
end

---Initializes dealerships from the configuration
function CDealershipManager:initializeDealerships()
  local dealershipConfigs = self.private.m_config:getDealerships()

  if type(dealershipConfigs) ~= 'table' then
    warn('Failed to initialize dealerships: Invalid or missing dealership configuration')
    return
  end

  for dealershipIndex = 1, #dealershipConfigs do
    local rawDelaership = dealershipConfigs[dealershipIndex]

    if validateDealership(dealershipIndex, rawDelaership) then
      local dealership = CDealership:new(
        self.private.m_config,
        rawDelaership?.name,
        rawDelaership?.blip,
        rawDelaership?.point,
        rawDelaership?.showroom,
        rawDelaership?.spawns
      )
    else
      warn('warning!')
    end
  end
end

---Get a dealership by its index
---@param dealershipIndex number
---@return CDealership?
function CDealershipManager:getDealershipByIndex(dealershipIndex)
  return self.private.m_dealerships[dealershipIndex]
end

---Get a dealership by its name
---@param dealershipName string
---@return CDealership?
function CDealershipManager:getDealershipByName(dealershipName)
  for dealershipIndex = 1, #self.private.m_dealerships do
    local dealership = self:getDealershipByIndex(dealershipIndex)

    if dealership:getName() == dealershipName then
      return dealership
    end
  end
end

---Gets all dealerships
---@return table<string, CDealership> A table of all dealerships, keyed by name
function CDealershipManager:getAllDealerships()
  return self.private.m_dealerships
end

---Serializes all dealerships for network transmission
---@return table A table containing serialized dealership data
function CDealershipManager:serialize()
  local serializedData = {}

  for name, dealership in pairs(self.private.m_dealerships) do
    local showroom = dealership:getShowroom()
    local serializedSlots = {}

    -- Assuming CShowroom has a getVehicleDisplaySlots method that returns a table of CVehicleDisplaySlot
    local slots = showroom:getVehicleDisplaySlots() or {}
    for _, slot in ipairs(slots) do
      table.insert(serializedSlots, slot:serialize())
    end

    serializedData[name] = {
      name = dealership:getName(),
      showroom = {
        slots = serializedSlots
      }
    }
  end

  return serializedData
end

---Deserializes dealership data and updates showroom states
---@param serializedData table A table containing serialized dealership data
function CDealershipManager:deserialize(serializedData)
  if not serializedData or type(serializedData) ~= "table" then
    warn("Invalid serialized data: Expected a table")
    return
  end

  for name, data in pairs(serializedData) do
    local dealership = self:getDealershipByName(name)
    if dealership then
      local showroom = dealership:getShowroom()
      -- Assuming CShowroom has a setVehicleDisplaySlots method (from previous conversation)
      showroom:setVehicleDisplaySlots(data.showroom.slots or {})
    else
      warn(("Cannot deserialize data for unknown dealership '%s'"):format(name))
    end
  end
end

---Destroys all dealerships (e.g., for cleanup)
function CDealershipManager:destroy()
  for _, dealership in pairs(self.private.m_dealerships) do
    local showroom = dealership:getShowroom()
    if showroom and showroom.destroyShowroom then
      showroom:destroyShowroom()
    end
    -- Add any additional cleanup (e.g., remove blips or points on client)
    if not IS_SERVER then
      local blip = dealership:getBlip()

      if blip and blip ~= INVALID_BLIP_ID then
        RemoveBlip(blip)
      end
    end
  end
  self.private.m_dealerships = {}
end
