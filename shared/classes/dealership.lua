local IS_SERVER <const> = IsDuplicityVersion()
local INVALID_BLIP_ID <const> = 0

---Sets the name for a blip
---@param blip number
---@param name string
local function SetBlipName(blip, name)
  BeginTextCommandSetBlipName("STRING")
  AddTextComponentString(name)
  EndTextCommandSetBlipName(blip)
end

---@class CDealership
---@field private private { m_config: CDealershipConfig, m_name: string, m_blip: number, m_point: CPoint, m_showroom: CShowroom, m_vehicleCreationPoints: table }
CDealership = lib.class('CDealership')

---Create a new instance of CDealership
---@param config CDealershipConfig
---@param dealershipName string
---@param dealershipBlip table
---@param dealershipPoint table
---@param dealershipShowroom table
function CDealership:constructor(config, dealershipName, dealershipBlip, dealershipPoint, dealershipShowroom, dealershipVehicleCreationPoints)
  self.private.m_config = config
  self.private.m_name = dealershipName
  self.private.m_blip = INVALID_BLIP_ID
  self.private.m_showroom = CShowroom:new(config, dealershipName, dealershipShowroom)

  if not IS_SERVER then
    self:createBlip(dealershipBlip)
    self:createPoint(dealershipPoint)
    self:createSelectionMenu()
  end

  self:setVehicleCreationCoordinates(dealershipVehicleCreationPoints)
end

---Get the name of the dealership
---@return string dealershipName
function CDealership:getName()
  return self.private.m_name
end

---Get the blip handle for the dealership
---@return number dealershipBlip
function CDealership:getBlip()
  assert(not IS_SERVER, 'CDealership:getBlip is only availble on the client')

  return self.private.m_blip
end

---Get the point associated with the dealership
---@return CPoint dealershipPoint
function CDealership:getPoint()
  return self.private.m_point
end

---Get the dealership showroom
---@return CShowroom dealershipShowroom
function CDealership:getShowroom()
  return self.private.m_showroom
end

---comment
---@return table
function CDealership:getVehicleCreationPoints()
  return self.private.m_vehicleCreationPoints
end

---Sets the creation points
---@param vehicleCreationCoordinates table
function CDealership:setVehicleCreationCoordinates(vehicleCreationCoordinates)
  self.private.m_vehicleCreationPoints = {}

  for creationPointIndex = 1, #vehicleCreationCoordinates do
    local creationPoint = vehicleCreationCoordinates[creationPointIndex]

    if type(creationPoint) ~= 'table' then
      warn(('Creation point %d for dealership %s is not a table with x, y, z, and h properties skipping'):format(creationPointIndex, self:getName()))
      goto continue
    end

    if not creationPoint?.x or not creationPoint?.y or not creationPoint?.z then
      warn(('Creation point %d for dealership %s is missing the x, y or z property skipping'):format(creationPointIndex, self:getName()))
      goto continue
    end

    if not creationPoint?.h then
      warn(('Creation point %d for dealership %s is missing the heading property assuming heading is zero.'):format(creationPointIndex, self:getName()))
      creationPoint.h = 0
    end

    table.insert(self.private.m_vehicleCreationPoints, {
      coordinates = vector3(creationPoint.x, creationPoint.y, creationPoint.z),
      heading = creationPoint.h
    })

    ::continue::
  end
end

---Validates blipInfo and provides a helpful warning if validation fails
---@param blipInfo table
---@return boolean valid
local function validateBlipInfo(blipInfo)
  if type(blipInfo) ~= 'table' then
    warn('Failed to create blip: blipInfo must be a table')
    return false
  end

  if type(blipInfo.coordinate) ~= 'table' then
    warn('Failed to create blip: blipInfo.coordinate must be a table {x, y, z}')
    return false
  end
  if type(blipInfo.coordinate.x) ~= 'number' then
    warn('Failed to create blip: blipInfo.coordinate.x must be a number')
    return false
  end
  if type(blipInfo.coordinate.y) ~= 'number' then
    warn('Failed to create blip: blipInfo.coordinate.y must be a number')
    return false
  end
  if type(blipInfo.coordinate.z) ~= 'number' then
    warn('Failed to create blip: blipInfo.coordinate.z must be a number')
    return false
  end

  if type(blipInfo.spriteId) ~= 'number' then
    warn('Failed to create blip: blipInfo.spriteId must be a number')
    return false
  end

  if type(blipInfo.colour) ~= 'number' then
    warn('Failed to create blip: blipInfo.colour must be a number')
    return false
  end

  if type(blipInfo.scale) ~= 'number' then
    warn('Failed to create blip: blipInfo.scale must be a number')
    return false
  end

  if type(blipInfo.label) ~= 'string' or blipInfo.label == '' then
    warn('Failed to create blip: blipInfo.label must be a non-empty string')
    return false
  end

  return true
end

---Creates dealership blip
---@param blipInfo table
function CDealership:createBlip(blipInfo)
  assert(not IS_SERVER, 'CDealership:createBlip is only availble on the client')

  if not validateBlipInfo(blipInfo) then
    return
  end

  local blip = AddBlipForCoord(blipInfo.coordinate.x, blipInfo.coordinate.y, blipInfo.coordinate.z)

  SetBlipSprite(blip, blipInfo.spriteId)
  SetBlipColour(blip, blipInfo.colour)
  SetBlipScale(blip, blipInfo.scale)
  SetBlipAsShortRange(blip, true)
  SetBlipName(blip, blipInfo.label)

  self.private.m_blip = blip
end

---Check if dealership point info is valid
---@param pointInfo table
---@return boolean valid
local function validatePointInfo(pointInfo)
  if type(pointInfo) ~= 'table' then
    warn('Failed to create point: pointInfo must be a table')
    return false
  end

  if type(pointInfo.coordinates) ~= 'table' then
    warn('Failed to create blip: pointInfo.coordinate must be a table {x, y, z}')
    return false
  end
  if type(pointInfo.coordinates.x) ~= 'number' then
    warn('Failed to create blip: pointInfo.coordinate.x must be a number')
    return false
  end
  if type(pointInfo.coordinates.y) ~= 'number' then
    warn('Failed to create blip: pointInfo.coordinate.y must be a number')
    return false
  end
  if type(pointInfo.coordinates.z) ~= 'number' then
    warn('Failed to create blip: pointInfo.coordinate.z must be a number')
    return false
  end

  if type(pointInfo.distance) ~= 'number' then
    warn('Failed to create blip: pointInfo.distance must be a number')
    return false
  end

  return true
end

---Create the dealership point
---@param pointInfo table
function CDealership:createPoint(pointInfo)
  assert(not IS_SERVER, 'CDealership:createPoint is only availble on the client')

  if not validatePointInfo(pointInfo) then
    return
  end

  local point = lib.points.new({
    coords = vector3(pointInfo.coordinates.x, pointInfo.coordinates.y, pointInfo.coordinates.z),
    distance = pointInfo.distance,
    dealership = self
  })

  function point:onEnter()
    TriggerServerEvent('mimesis:dealerships:requestShowroomState', self.dealership:getName())
  end

  function point:onExit()
    local dealershipShowroom = self.dealership:getShowroom()
    dealershipShowroom:destroyShowroom()
  end

  self.private.m_point = point
end

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

function CDealership:createSelectionMenu()
  local allVehicles = self.private.m_config:getVehicles()
  local vehiclesToInclude = {}
  local vehicleCategories = self.private.m_showroom:getSoldVehicleCategories()

  for categoryIndex = 1, #vehicleCategories do
    local categoryName = vehicleCategories[categoryIndex]
    local vehiclesInCategory = allVehicles[categoryName]

    if vehiclesInCategory then
      vehiclesToInclude[categoryName] = {}

      for modelIndex = 1, #vehiclesInCategory do
        local vehicleInfo = vehiclesInCategory[modelIndex]
        local vehicleModel = vehicleInfo.model
        local vehicleLabel = getVehicleLabel(vehicleModel)
        local vehiclePrice = vehicleInfo.price

        table.insert(vehiclesToInclude[categoryName], {
          model = vehicleModel,
          label = vehicleLabel,
          price = vehiclePrice
        })
      end
    end
  end

  local menuOptions = {}

  for vehicleCategory in pairs(vehiclesToInclude) do
    table.insert(menuOptions, {
      icon = 'car',
      label = vehicleCategory,
      values = vehiclesToInclude[vehicleCategory],
      args = { category = vehicleCategory }
    })
  end

  lib.registerMenu({
    id = ('dealership:%s'):format(self:getName()),
    title = self:getName(),
    position = 'top-right',
    options = menuOptions
  }, function(_, vehicleModelIndex, args)
    local vehicleCategory = args.category
    local dealershipShowroom = self:getShowroom()
    dealershipShowroom:updateShowroomSlot(vehicleCategory, vehicleModelIndex)
  end)
end

function CDealership:getAvailableVehicleCreationPoint()
  local vehicleCreationPoints = self:getVehicleCreationPoints()
  local vehiclePool = GetGamePool('CVehicle')

  for creationPointIndex = 1, #vehicleCreationPoints do
    local creationPoint = vehicleCreationPoints[creationPointIndex]
    local isAvailable = true

    for poolIndex = 1, #vehiclePool do
      local vehicleIndex = vehiclePool[poolIndex]
      local vehicleCoordinates = GetEntityCoords(vehicleIndex)
      if #(creationPoint.coordinates - vehicleCoordinates) < 5 then
        isAvailable = false
        break
      end
    end

    if isAvailable then
      return creationPoint
    end
  end
end
