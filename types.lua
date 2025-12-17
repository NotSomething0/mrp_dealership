---@diagnostic disable: missing-return

---@return CDealershipConfig
function CDealershipConfig:new()
end

---@param config CDealershipConfig
---@param dealershipName string
---@param dealershipBlip table
---@param dealershipPoint table
---@param dealershipShowroom table
---@param dealershipVehicleCreationPoints table
---@return CDealership
function CDealership:new(config, dealershipName,  dealershipBlip, dealershipPoint, dealershipShowroom, dealershipVehicleCreationPoints)
end

---@param config CDealershipConfig
---@param dealershipName string
---@param showroomInfo table
---@return CShowroom
function CShowroom:new(config, dealershipName, showroomInfo)
end

---@param index number
---@param coordinates vector3
---@param heading number
---@param model number
---@param modelPrice number?
---@return CVehicleDisplaySlot
function CVehicleDisplaySlot:new(index, coordinates, heading, model, modelPrice)
end
