local DEFAULT_CONFIG <const> = {
  vehicleCategories = {
    ['Super'] = {
      { model = `adder`, price = 999999 }
    }
  }
}

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

---@class CDealershipConfig
---@diagnostic disable-next-line: duplicate-doc-field
---@field private private { m_vehicles: table, m_dealerships: table }
CDealershipConfig = lib.class('CDealershipConfig')

---@diagnostic disable-next-line: duplicate-set-field
function CDealershipConfig:constructor()
  self.private.m_vehicles = {}
  self.private.m_dealerships = {}

  self:setVehicleCategories()
  self:setDealerships()
end

---Get dealerships
---@return CDealership[]
function CDealershipConfig:getDealerships()
  return self.private.m_dealerships
end

---Set dealerships
function CDealershipConfig:setDealerships()
  local rawDealerships = GetConvar('mimesis:dealership:dealerships', 'default')

  if rawDealerships == 'default' then
    warn('mimesis:dealership:dealerships is unset using default dealerships')
    return
  end

  local dealerships = json.decode(rawDealerships)

  if not dealerships then
    error('Failed to parse mimesis:dealership:dealerships correct your configuration and restart the resource')
  end

  for dealershipIndex = 1, #dealerships do
    local dealership = dealerships[dealershipIndex]
    local valid, validationMessage = validateDealership(dealershipIndex, dealership)

    if valid then
      self.private.m_dealerships[dealershipIndex] = CDealership:new(self, dealership.name, dealership.blip, dealership.point, dealership.showroom, dealership.spawns)
    else
      warn(validationMessage)
    end
  end
end

---@return table
function CDealershipConfig:getVehicles()
  return self.private.m_vehicles
end

---@param category string
---@return table
function CDealershipConfig:getVehiclesByCategory(category)
  local vehicles = self:getVehicles()
  local vehiclesFromCategory = vehicles[category]

  if not vehiclesFromCategory then
    warn(('Vehicle category %s does not exist'):format(category))
    return {}
  end

  return vehiclesFromCategory
end

---Get a random vehicle model from the passed vehicle category
---@param vehicleCategory string
---@return number vehicleModel
function CDealershipConfig:getRandomVehicleFromCategory(vehicleCategory)
  local vehiclesByCategory = self.private.m_vehicles

  if not vehiclesByCategory[vehicleCategory] then
    warn(('Failed to get random vehicle model from category %s as the category does not exist.'):format(vehicleCategory))
    return 0
  end

  local vehiclesFromCategory = vehiclesByCategory[vehicleCategory]
  local vehiclesFromCategoryLength = #vehiclesFromCategory

  if vehiclesFromCategoryLength < 1 then
    warn(('Failed to get random vehicle model from category %s as the category is empty.'):format(vehicleCategory))
    return 0
  end

  return vehiclesFromCategory[math.random(1, vehiclesFromCategoryLength)]
end

---Sets the 
function CDealershipConfig:setVehicleCategories()
  local rawVehicles = GetConvar('mimesis:dealership:vehicleCategories', 'default')

  if rawVehicles == 'default' then
    ---@todo: add default vehicle categories
    warn('mimesis:dealership:vehicleCategories is unset using default vehicle categories')
    return
  end

  local vehiclesDecoded = json.decode(rawVehicles)

  if not vehiclesDecoded then
    ---@todo: add default vehicle categories
    warn('Failed to decode mimesis:dealership:vehicleCategories using default vehicle categories')
    return DEFAULT_CONFIG.vehicleCategories
  end

  for category, vehicles in pairs(vehiclesDecoded) do
    category = category:lower()

    self.private.m_vehicles[category] = {}

    for _, vehicleInfo in pairs(vehicles) do
      local model = vehicleInfo.model
      vehicleInfo.model = model
      table.insert(self.private.m_vehicles[category], vehicleInfo)
    end
  end
end
