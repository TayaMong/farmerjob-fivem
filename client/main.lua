local QBCore = exports['qb-core']:GetCoreObject()
local allItems = exports.ox_inventory:Items()
local placing = false
local ghostProp = nil
local model = `prop_plant_fern_02b`
local rotation = 0.0
local plants = {}           -- [plantId] = prop entity
local plantOwners = {}      -- [plantId] = citizenid
local registeredTargets = {} -- [plantId] = true
local growthPerc = {}       -- [plantId] = 0~100
local plantSeed = {}       -- [plantId] = "weed", "tomato", dll


local plantingZone = lib.zones.poly({
    points = {
        vec3(293.77, 6628.06, 28.25),
        vec3(244.18, 6628.03, 28.84),
        vec3(244.15, 6597.43, 29.0),
        vec3(293.79, 6596.12, 29.23),
    },
    thickness = 5.0,
    debug = false
})

-- ===============================
-- USE ITEM
-- ===============================
exports('usePotBunga', function()
    if placing then return end
    placing = true

    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local spawnPos = pedCoords + forward * 1.5

    ghostProp = CreateObject(model, spawnPos.x, spawnPos.y, spawnPos.z, false, false, false)
    SetEntityAlpha(ghostProp, 120, false)
    SetEntityCollision(ghostProp, false, false)
    FreezeEntityPosition(ghostProp, true)
    rotation = 0.0

    CreateThread(function()
        while placing do
            Wait(0)
            local hit, coords = RaycastFromCamera(10.0)
            if hit and coords then
                SetEntityCoords(ghostProp, coords.x, coords.y, coords.z, false, false, false, true)
                SetEntityHeading(ghostProp, rotation)
            end

            local scroll = GetControlNormal(0, 14)
            if scroll > 0 then rotation = rotation + 5 end
            if scroll < 0 then rotation = rotation - 5 end

            local tooClose = false
            local insideZone = coords and plantingZone:contains(coords)

            if coords then
                for _, obj in pairs(plants) do
                    if DoesEntityExist(obj) then
                        if #(GetEntityCoords(obj) - coords) < 3.0 then
                            tooClose = true
                            break
                        end
                    end
                end
            end

            if tooClose or not insideZone then
                SetEntityAlpha(ghostProp, 80, false)
            else
                SetEntityAlpha(ghostProp, 120, false)
            end

            if not tooClose and insideZone and IsControlJustPressed(0, 38) then
                local ped = PlayerPedId()
                exports['np_progressbar']:Progress({
                name = "pbnanam",
                duration = 5000, -- 5 detik
                label = "Sedang menanam...",
                useWhileDead = false,
                canCancel = true,
                controlDisables = {
                disableMovement = false,
                disableCarMovement = false,
                disableMouse = false,
                disableCombat = true,
                },
                prop = {},
                propTwo = {}
                }, function(cancelled)
                    if not cancelled then
                        -- finished
                    else
                        -- cancelled
                    end
                end)
                TaskStartScenarioInPlace(ped, "world_human_gardener_plant", 0, true)

                local currentCoords = GetEntityCoords(ghostProp)
                FreezeEntityPosition(ghostProp, true)
                SetEntityCoords(ghostProp, currentCoords)

                Wait(5000)
                ClearPedTasks(ped)

                TriggerServerEvent('potbunga:server:placePlant', currentCoords, rotation)
                DeleteEntity(ghostProp)
                placing = false
            end

            if IsControlJustPressed(0, 38) and not insideZone then
                TriggerEvent('QBCore:Notify', "Kamu hanya bisa menanam di area yang ditentukan", "error")
            end

            if IsControlJustPressed(0, 322) then
                DeleteEntity(ghostProp)
                placing = false
            end
        end
    end)
end)

-- ===============================
-- OX_TARGET
-- ===============================
local function registerTarget(obj, plantId)
    exports.ox_target:addLocalEntity(obj, {
        {
            name = 'plant_status',
            icon = 'fa-solid fa-seedling',
            label = (plantSeed[plantId] or "Unknown") .. ' | Check Growth ',
            distance = 2.5,
            onSelect = function()
                TriggerEvent('QBCore:Notify', (plantSeed[plantId] or "Unknown") .. " - Growth: " .. (growthPerc[plantId] or 0) .. "%", "info")
            end
        },
        {
            name = 'pickup_plant',
            icon = 'fa-solid fa-hand-holding',
            label = 'Panen',
            distance = 2.5,
            onSelect = function()
                if growthPerc[plantId] and growthPerc[plantId] < 100 then
                    TriggerEvent('QBCore:Notify', "Tanaman belum matang!", "error")
                    return
                end

                local ped = PlayerPedId()
                FreezeEntityPosition(ped, true)

                RequestAnimDict("anim@amb@clubhouse@tutorial@bkr_tut_ig3@")
                while not HasAnimDictLoaded("anim@amb@clubhouse@tutorial@bkr_tut_ig3@") do Wait(0) end

                TaskPlayAnim(ped, "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 8.0, -8, 5000, 49, 0, false, false, false)
                exports['np_progressbar']:Progress({
                name = "pbPickup",
                duration = 5000, -- 5 detik
                label = "Sedang memanen...",
                useWhileDead = false,
                canCancel = true,
                controlDisables = {
                disableMovement = false,
                disableCarMovement = false,
                disableMouse = false,
                disableCombat = true,
                },
                prop = {},
                propTwo = {}
                }, function(cancelled)
                    if not cancelled then
                        -- finished
                    else
                        -- cancelled
                    end
                end)
                Wait(5000)

                ClearPedTasks(ped)
                FreezeEntityPosition(ped, false)

                TriggerServerEvent('potbunga:server:pickupPlant', plantId)
            end
        },
        {
            name = 'add_compost',
            icon = 'fa-solid fa-leaf',
            label = 'Tambah Kompos',
            distance = 2.5,
            onSelect = function()
                TriggerServerEvent('potbunga:server:useCompost', plantId)
            end
        }
    })
end

-- ===============================
-- SPAWN
-- ===============================
local function spawnPlantEntity(id, coords, heading, owner, growth, seed)
    if plants[id] and DoesEntityExist(plants[id]) then return end

    local obj = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(obj, heading)
    FreezeEntityPosition(obj, true)
    SetEntityAsMissionEntity(obj, true)

    plants[id] = obj
    plantOwners[id] = owner
    growthPerc[id] = growth or 0
    plantSeed[id] = seed or "Unknown"


    if not registeredTargets[id] then
        registerTarget(obj, id)
        registeredTargets[id] = true
    end
end

RegisterNetEvent('potbunga:client:sendPlants', function(dbPlants)
    for _, data in pairs(dbPlants) do
        spawnPlantEntity(data.id, vector3(data.x, data.y, data.z), data.heading, data.citizenid, data.growth, data.seed)
    end
end)

RegisterNetEvent('potbunga:client:spawnPlant', function(plantId, coords, heading, owner, seed)
    spawnPlantEntity(plantId, coords, heading, owner, 0, seed)
end)


RegisterNetEvent('potbunga:client:deletePlant', function(plantId)
    local obj = plants[plantId]
    if obj and DoesEntityExist(obj) then
        SetEntityAsMissionEntity(obj, true, true)
        DeleteEntity(obj)
    end
    plants[plantId] = nil
    plantOwners[plantId] = nil
    registeredTargets[plantId] = nil
    growthPerc[plantId] = nil
end)

-- ===============================
-- PLAYER LOADED
-- ===============================
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('potbunga:server:getPlants')
end)

-- ===============================
-- RAYCAST
-- ===============================
function RaycastFromCamera(distance)
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local direction = RotationToDirection(camRot)
    local dest = camCoords + direction * distance

    local rayHandle = StartShapeTestRay(
        camCoords.x, camCoords.y, camCoords.z,
        dest.x, dest.y, dest.z,
        17,
        PlayerPedId(),
        0
    )

    local _, hit, endCoords = GetShapeTestResult(rayHandle)
    return hit == 1, endCoords
end

function RotationToDirection(rot)
    local z = math.rad(rot.z)
    local x = math.rad(rot.x)
    local cosX = math.cos(x)
    return vector3(-math.sin(z)*cosX, math.cos(z)*cosX, math.sin(x))
end

RegisterNetEvent('potbunga:client:updateGrowthPerc', function(plantId, growth)
    growthPerc[plantId] = growth
end)

--==================
--shop
--==================
-- client/main.lua

local pedModel = `a_m_m_hillbilly_01`
local pedCoords = vector4(396.97, 6601.85, 27.37, 355.22)
local spawnedPed = nil

local function SpawnPed()
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do
        Wait(100)
    end

    spawnedPed = CreatePed(4, pedModel, pedCoords.x, pedCoords.y, pedCoords.z, pedCoords.w, false, true)
    
    -- Biar ped ga kabur, ga bisa digeser, ga bisa diserang
    SetBlockingOfNonTemporaryEvents(spawnedPed, true)
    SetPedFleeAttributes(spawnedPed, 0, false)
    SetPedCombatAttributes(spawnedPed, 17, true) -- ped ga bisa menyerang
    SetEntityInvincible(spawnedPed, true)
    FreezeEntityPosition(spawnedPed, true)
    
    -- Animasi idle biar hidup
    TaskStartScenarioInPlace(spawnedPed, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)
end

-- Spawn ped saat player masuk
CreateThread(function()
    Wait(1000)
    SpawnPed()
end)


local function playWateringEmote(ped, animDict, animName, propHash, propOffset, propRot, effectName, duration)
    -- Spawn prop
    local coords = GetEntityCoords(ped)
    local prop = CreateObject(propHash, coords.x, coords.y, coords.z, true, true, true)
    
    -- Attach ke tangan
    local boneID = GetPedBoneIndex(ped, 0x8CBD) -- tangan kanan
    AttachEntityToEntity(prop, ped, boneID, propOffset.x, propOffset.y, propOffset.z, propRot.x, propRot.y, propRot.z, false, false, false, true, 1, true)

    -- Load anim
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(100)
    end

    -- Play anim
    TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, duration, 49, 0, false, false, false)
  	FreezeEntityPosition(ped, true)
  
	Wait(5000)

  	DeleteEntity(prop)
    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)
end

-- Command /haloo -> menyiram
RegisterNetEvent('potbunga:client:wateringCan', function()
    local ped = PlayerPedId()
    local canHash = GetHashKey('prop_wateringcan')
    exports['np_progressbar']:Progress({
                name = "pbWatering",
                duration = 5000, -- 5 detik
                label = "Sedang memupuk...",
                useWhileDead = false,
                canCancel = true,
                controlDisables = {
                disableMovement = false,
                disableCarMovement = false,
                disableMouse = false,
                disableCombat = true,
                },
                prop = {},
                propTwo = {}
                }, function(cancelled)
                    if not cancelled then
                        -- finished
                    else
                        -- cancelled
                    end
                end)
    playWateringEmote(
        ped,
        "missfbi3_waterboard", -- anim menyiram
        "waterboard_loop_player",
        canHash,
        vector3(0.15, 0.0, 0.4),
        vector3(0.0, -180.0, -140.0),
        "ent_sht_water",
        5000
    )
end)

