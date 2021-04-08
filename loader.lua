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
    if g_ShuttleSettings.shuttleSettings.active.active then
        if not vehicle:isHoldingBrake() then
            local spec = vehicle.spec_drivable
            local axisAccelerate = MathUtil.clamp(inputValue, 0, 1) * vehicle:getShuttleDriveDirection()
            spec.lastInputValues.axisAccelerate = axisAccelerate

            if vehicle.getHasGuidanceSystem ~= nil and vehicle:getHasGuidanceSystem() then
                local guidanceSpec = vehicle.spec_globalPositioningSystem
                if guidanceSpec.guidanceSteeringIsActive then
                    guidanceSpec.axisAccelerate = axisAccelerate
                end
            end
        end
    else
        superFunc(vehicle, actionName, inputValue, arg)
    end
end

local function inj_actionEventBrake(vehicle, superFunc, actionName, inputValue, ...)
    if g_ShuttleSettings.shuttleSettings.active.active then
        vehicle:setIsHoldingBrake(inputValue ~= 0)

        if vehicle:isHoldingBrake() and vehicle.lastSpeedReal > 0.0003 then
            -- Only brake when driving faster than 0.7km/h
            local spec = vehicle.spec_drivable
            local reverseSpec = vehicle.spec_reverseDriving
            local shuttleDirection = vehicle:getShuttleDriveDirection()
            local signAxis = MathUtil.sign(spec.axisForward)
            local reverseMode = 1
            if reverseSpec ~= nil then
                if reverseSpec.isReverseDriving then
                    reverseMode = -1
                else
                    reverseMode = 1
                end
            end

            if shuttleDirection == signAxis or not signAxis ~= 0 then
                local axisBrake = MathUtil.clamp(inputValue, 0, 1) * vehicle.movingDirection * reverseMode
                spec.lastInputValues.axisBrake = axisBrake
            end

            if vehicle.getHasGuidanceSystem ~= nil and vehicle:getHasGuidanceSystem() then
                local guidanceSpec = vehicle.spec_globalPositioningSystem
                if guidanceSpec.guidanceSteeringIsActive then
                    local guidanceSignAxis = MathUtil.sign(guidanceSpec.axisForward)
                    if shuttleDirection == guidanceSignAxis or not guidanceSignAxis ~= 0 then
                        guidanceSpec.axisBrake = MathUtil.clamp(inputValue, 0, 1) * vehicle.movingDirection * reverseMode
                    end
                end
            end
        end
    else
        superFunc(vehicle, actionName, inputValue, arg)
    end
end

local function updateWheelsPhysics(vehicle, superFunc, dt, currentSpeed, acceleration, doHandbrake, stopAndGoBraking)
    if g_ShuttleSettings.shuttleSettings.active.active then
        local spec = vehicle.spec_drivable
        if not vehicle:getIsAIActive() and spec.cruiseControl.state ~= Drivable.CRUISECONTROL_STATE_OFF then
            acceleration = acceleration * vehicle:getShuttleDriveDirection()
        end
    end
    superFunc(vehicle, dt, currentSpeed, acceleration, doHandbrake, stopAndGoBraking)
end

local function init(baseDirectory, modName)
    VehicleTypeManager.validateVehicleTypes = Utils.prependedFunction(VehicleTypeManager.validateVehicleTypes, validateVehicleTypes)
    WheelsUtil.updateWheelsPhysics = Utils.overwrittenFunction(WheelsUtil.updateWheelsPhysics, updateWheelsPhysics)
    Drivable.actionEventAccelerate = Utils.overwrittenFunction(Drivable.actionEventAccelerate, inj_actionEventAccelerate)
    Drivable.actionEventBrake = Utils.overwrittenFunction(Drivable.actionEventBrake, inj_actionEventBrake)

    source(Utils.getFilename("scripts/ShuttleSettings.lua", baseDirectory))
    source(Utils.getFilename("scripts/gui/newFrameReference.lua", baseDirectory))
    source(Utils.getFilename("scripts/gui/ShuttleSettingFrame.lua", baseDirectory))

    local modsSettingsPath = getUserProfileAppPath() .. "modsSettings/"
	createFolder(modsSettingsPath)

    Mission00.setMissionInfo = Utils.prependedFunction(Mission00.setMissionInfo, function(mission, missionInfo, missionDynamicInfo)
        getfenv(0).g_ShuttleSettings = ShuttleSettings:new(mission, missionInfo, missionDynamicInfo, baseDirectory, modName, modsSettingsPath, g_i18n, g_gui, g_gameSettings, g_depthOfFieldManager, g_mpLoadingScreen, g_shopConfigScreen, g_mapManager)
    end)


    
end

init(g_currentModDirectory, g_currentModName)
