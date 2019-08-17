---
-- loader
--
-- loader script for the mod
--
-- Copyright (c) Wopster, 2019

local directory = g_currentModDirectory
local modName = g_currentModName

g_shuttleDriveDirectionModDirectory = directory
g_shuttleDriveDirectionModName = modName

local function installSpecializations(vehicleTypeManager, specializationManager, modDirectory, modName)
    g_specializationManager:addSpecialization("shuttleDriveDirection", "ShuttleDriveDirection", Utils.getFilename("ShuttleDriveDirection.lua", modDirectory), nil)
    for typeName, typeEntry in pairs(vehicleTypeManager:getVehicleTypes()) do
        if SpecializationUtil.hasSpecialization(Drivable, typeEntry.specializations)
                and not SpecializationUtil.hasSpecialization(ShuttleDriveDirection, typeEntry.specializations) then
            vehicleTypeManager:addSpecialization(typeName, modName .. ".shuttleDriveDirection")
        end
    end
end

local function validateVehicleTypes(vehicleTypeManager)
    installSpecializations(g_vehicleTypeManager, g_specializationManager, directory, modName)
end

local function inj_actionEventAccelerate(vehicle, superFunc, actionName, inputValue, ...)
    local spec = vehicle.spec_drivable
    local axisAccelerate = MathUtil.clamp(inputValue, 0, 1) * vehicle:getShuttleDriveDirection()
    spec.lastInputValues.axisAccelerate = axisAccelerate

    if vehicle.getHasGuidanceSystem ~= nil and vehicle:getHasGuidanceSystem() then
        local guidanceSpec = vehicle:guidanceSteering_getSpecTable("globalPositioningSystem")
        if guidanceSpec.guidanceSteeringIsActive then
            guidanceSpec.axisAccelerate = axisAccelerate
        end
    end
end

local function inj_actionEventBrake(vehicle, superFunc, actionName, inputValue, ...)
    if vehicle.lastSpeedReal > 0.0003 then
        local spec = vehicle.spec_drivable
        local shuttleDirection = vehicle:getShuttleDriveDirection()
        local signAxis = MathUtil.sign(spec.axisForward)

        if shuttleDirection == signAxis or not signAxis ~= 0 then
            local axisBrake = MathUtil.clamp(inputValue, 0, 1) * shuttleDirection
            spec.lastInputValues.axisBrake = axisBrake
        end

        if vehicle.getHasGuidanceSystem ~= nil and vehicle:getHasGuidanceSystem() then
            local guidanceSpec = vehicle:guidanceSteering_getSpecTable("globalPositioningSystem")
            if guidanceSpec.guidanceSteeringIsActive then
                local guidanceSignAxis = MathUtil.sign(guidanceSpec.axisForward)
                if shuttleDirection == guidanceSignAxis or not guidanceSignAxis ~= 0 then
                    guidanceSpec.axisBrake = MathUtil.clamp(inputValue, 0, 1) * shuttleDirection
                end
            end
        end
    end

    vehicle:setIsHoldingBrake(inputValue ~= 0)
end

local function updateWheelsPhysics(vehicle, superFunc, dt, currentSpeed, acceleration, doHandbrake, stopAndGoBraking)
    local spec = vehicle.spec_drivable
    if not vehicle:getIsAIActive() and spec.cruiseControl.state ~= Drivable.CRUISECONTROL_STATE_OFF then
        acceleration = acceleration * vehicle:getShuttleDriveDirection()
    end

    superFunc(vehicle, dt, currentSpeed, acceleration, doHandbrake, stopAndGoBraking)
end

local function init()
    VehicleTypeManager.validateVehicleTypes = Utils.prependedFunction(VehicleTypeManager.validateVehicleTypes, validateVehicleTypes)
    WheelsUtil.updateWheelsPhysics = Utils.overwrittenFunction(WheelsUtil.updateWheelsPhysics, updateWheelsPhysics)
    Drivable.actionEventAccelerate = Utils.overwrittenFunction(Drivable.actionEventAccelerate, inj_actionEventAccelerate)
    Drivable.actionEventBrake = Utils.overwrittenFunction(Drivable.actionEventBrake, inj_actionEventBrake)
end

init()
