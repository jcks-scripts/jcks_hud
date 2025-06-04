local ESX, QBCore, QBX = nil, nil, nil

local ESX_Started = GetResourceState("es_extended") == "started"
local QBCore_Started = GetResourceState("qb-core") == "started"
local QBX_Started = GetResourceState("qbx_core") == "started"

if ESX_Started then
    ESX = exports["es_extended"]:getSharedObject()
elseif QBCore_Started then
    QBCore = exports["qb-core"]:GetCoreObject()
elseif QBX_Started then
    QBX = exports["qbx_core"]:GetCoreObject()
else
    print("Unsupported framework. Supported frameworks: ESX, QBCore, QBX")
end

local isHudVisible = true

local function updatePlayerStatus()
    local player = PlayerPedId()
    local health = math.max(0, math.min(100, GetEntityHealth(player) - 100))
    local armor = math.max(0, math.min(100, GetPedArmour(player)))
    local stamina = math.max(0, math.min(100, 100 - GetPlayerSprintStaminaRemaining(player)))

    SendNUIMessage({
        type = "StatusHUD",
        health = health,
        armor = armor,
        stamina = stamina
    })
end

local function updatePlayerNeeds()
    if ESX then
        TriggerEvent('esx_status:getStatus', 'hunger', function(hungerStatus)
            TriggerEvent('esx_status:getStatus', 'thirst', function(thirstStatus)
                SendNUIMessage({
                    type = "NeedsHUD",
                    food = math.max(0, math.min(100, math.floor(hungerStatus.getPercent()))),
                    water = math.max(0, math.min(100, math.floor(thirstStatus.getPercent())))
                })
            end)
        end)
    elseif QBCore or QBX then
        local hunger, thirst = 0, 0
        TriggerEvent('hud:client:UpdateNeeds', function(newHunger, newThirst)
            hunger, thirst = newHunger, newThirst
        end)
        SendNUIMessage({
            type = "NeedsHUD",
            food = math.max(0, math.min(100, hunger)),
            water = math.max(0, math.min(100, thirst))
        })
    end
end

-- Update player status and needs
Citizen.CreateThread(function()
    while true do
        Wait(200)
        updatePlayerStatus()
        updatePlayerNeeds()
    end
end)

-- Toggle HUD visibility when pause menu is active
Citizen.CreateThread(function()
    while true do
        Wait(200)
        local isPauseMenuActive = IsPauseMenuActive()
        if isPauseMenuActive and isHudVisible then
            isHudVisible = false
            SendNUIMessage({ type = "hideHUD" })
        elseif not isPauseMenuActive and not isHudVisible then
            isHudVisible = true
            SendNUIMessage({ type = "showHUD" })
        end
    end
end)