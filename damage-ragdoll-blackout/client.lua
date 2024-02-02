local isBlackedOut = false
local oldBodyDamage = 0
local oldSpeed = 0
local shotsToRagdoll = 0
local shotsRequired = 3

local BONES = {
    --[[Pelvis]] [11816] = true,
    --[[SKEL_L_Thigh]] [58271] = true,
    -- Add more bones as needed
}

local function blackout()
    if not isBlackedOut then
        isBlackedOut = true
        Citizen.CreateThread(function()
            DoScreenFadeOut(100)
            while not IsScreenFadedOut() do
                Citizen.Wait(0)
            end
            Citizen.Wait(Config.BlackoutTime)
            DoScreenFadeIn(250)
            isBlackedOut = false
        end)
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = GetPlayerPed(-1)

        if HasEntityBeenDamagedByAnyPed(ped) then
            local hit, bone = GetPedLastDamageBone(ped)
            hit = Bool(hit)

            if hit and BONES[bone] then
                shotsToRagdoll = shotsToRagdoll + 1

                if shotsToRagdoll >= shotsRequired then
                    SetPedToRagdoll(ped, 5000, 5000, 0, 0, 0, 0)
                    shotsToRagdoll = 0
                    blackout()  -- Trigger blackout on ragdoll
                end
            end
        end

        ClearEntityLastDamageEntity(ped)

        local vehicle = GetVehiclePedIsIn(ped, false)
        if DoesEntityExist(vehicle) then
            if Config.BlackoutFromDamage then
                local currentDamage = GetVehicleBodyHealth(vehicle)

                if currentDamage ~= oldBodyDamage then
                    if not isBlackedOut and (currentDamage < oldBodyDamage) and ((oldBodyDamage - currentDamage) >= Config.BlackoutDamageRequired) then
                        blackout()
                    end
                    oldBodyDamage = currentDamage
                end
            end

            if Config.BlackoutFromSpeed then
                local currentSpeed = GetEntitySpeed(vehicle) * 2.23

                if currentSpeed ~= oldSpeed then
                    if not isBlackedOut and (currentSpeed < oldSpeed) and ((oldSpeed - currentSpeed) >= Config.BlackoutSpeedRequired) then
                        blackout()
                    end
                    oldSpeed = currentSpeed
                end
            end
        else
            oldBodyDamage = 0
            oldSpeed = 0
        end

        if isBlackedOut and Config.DisableControlsOnBlackout then
            DisableControlAction(0, 71, true)  -- veh forward
            DisableControlAction(0, 72, true)  -- veh backwards
            DisableControlAction(0, 63, true)  -- veh turn left
            DisableControlAction(0, 64, true)  -- veh turn right
            DisableControlAction(0, 75, true)  -- disable exit vehicle
        end
    end
end)

function Bool(num)
    return num == 1 or num == true
end
