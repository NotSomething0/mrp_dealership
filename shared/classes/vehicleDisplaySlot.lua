local INVALID_VEHICLE_INDEX <const> = 0

---@class CVehicleDisplaySlot
---@field private private { m_index: number, m_coordinates: vector3, m_heading: number, m_vehicleModel: string, m_vehicleModelPrice: number?, m_vehicleIndex: number }
CVehicleDisplaySlot = lib.class('CVehicleDisplaySlot')

---@param index number
---@param coordinates vector3
---@param heading number
---@param model string
---@param modelPrice number?
function CVehicleDisplaySlot:constructor(index, coordinates, heading, model, modelPrice)
  self.private.m_index = index
  self.private.m_coordinates = coordinates
  self.private.m_heading = heading
  self.private.m_vehicleModel = model
  self.private.m_vehicleModelPrice = modelPrice
  self.private.m_vehicleIndex = INVALID_VEHICLE_INDEX
end

---Get the display slot index
---@return number displaySlotIndex
function CVehicleDisplaySlot:getIndex()
  return self.private.m_index
end

---Get the vehicle index that is currently being displayed
---@return number
function CVehicleDisplaySlot:getVehicleIndex()
  return self.private.m_vehicleIndex
end

---@param vehicleIndex number
function CVehicleDisplaySlot:setVehicleIndex(vehicleIndex)
  self.private.m_vehicleIndex = vehicleIndex
end

-- Vehicle Model
---@return string
function CVehicleDisplaySlot:getVehicleModel()
  return self.private.m_vehicleModel
end

---Get the set vehicle models price
---@return number
function CVehicleDisplaySlot:getVehicleModelPrice()
  return self.private.m_vehicleModelPrice
end

---@param vehicleModel string
function CVehicleDisplaySlot:setVehicleModel(vehicleModel)
  self.private.m_vehicleModel = vehicleModel
end

---Set the price of the current vehicle model
---@param price number
function CVehicleDisplaySlot:setVehicleModelPrice(price)
  self.private.m_vehicleModelPrice = price
end

-- Coordinates
---@return vector3
function CVehicleDisplaySlot:getCoordinates()
  return self.private.m_coordinates
end

---@param coordinates vector3
function CVehicleDisplaySlot:setCoordinates(coordinates)
  self.private.m_coordinates = coordinates
end

-- Heading
---@return number
function CVehicleDisplaySlot:getHeading()
  return self.private.m_heading
end

---@param heading number
function CVehicleDisplaySlot:setHeading(heading)
  self.private.m_heading = heading
end

---@return table
function CVehicleDisplaySlot:serialize()
  local data = {
    index = self:getIndex(),
    coordinates = {
      x = self.private.m_coordinates.x,
      y = self.private.m_coordinates.y,
      z = self.private.m_coordinates.z
    },
    heading = self.private.m_heading,
    vehicleModel = self.private.m_vehicleModel,
    vehicleIndex = self.private.m_vehicleIndex,
    vehicleModelPrice = self.private.m_vehicleModelPrice
  }

  return data
end
