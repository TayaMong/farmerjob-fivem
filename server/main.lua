local QBCore = exports['qb-core']:GetCoreObject()

-- Place plant
RegisterNetEvent('potbunga:server:placePlant', function(coords, heading)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid

    exports.oxmysql:execute("SELECT COUNT(*) as total FROM pot_bunga WHERE citizenid = ?", { citizenid }, function(result)
        if result[1].total >= 10 then
            TriggerClientEvent('QBCore:Notify', src, "Kamu sudah mencapai limit 10 tanaman!", "error")
            return
        end

        local seedMap = {
            ['lettuce_seed'] = 'lettuce',
            ['tomato_seed'] = 'tomato',
            ['cucumber_seed'] = 'cucumber'
        }

        local plantType, usedSeed
        for seedItem, plant in pairs(seedMap) do
            if Player.Functions.GetItemByName(seedItem) then
                plantType = plant
                usedSeed = seedItem
                break
            end
        end

        if not plantType then
            TriggerClientEvent('QBCore:Notify', src, "Kamu tidak punya bibit!", "error")
            return
        end

        Player.Functions.RemoveItem(usedSeed, 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[usedSeed], "remove")

        exports.oxmysql:insert(
            "INSERT INTO pot_bunga (citizenid, model, x, y, z, heading, seed, growth, has_compost) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
            { citizenid, 'prop_plant_fern_02b', coords.x, coords.y, coords.z, heading, plantType, 0, 0 },
            function(insertId)
                TriggerClientEvent('potbunga:client:spawnPlant', -1, insertId, coords, heading, citizenid, plantType)
            end
        )
    end)
end)

-- Get all plants
RegisterNetEvent('potbunga:server:getPlants', function()
    local src = source
    exports.oxmysql:execute("SELECT * FROM pot_bunga", {}, function(result)
        TriggerClientEvent('potbunga:client:sendPlants', src, result)
    end)
end)

-- Pickup plant
RegisterNetEvent('potbunga:server:pickupPlant', function(plantId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid

    exports.oxmysql:execute("SELECT * FROM pot_bunga WHERE id = ?", { plantId }, function(result)
        if not result[1] then return end
        local data = result[1]

        if data.citizenid ~= citizenid then
            TriggerClientEvent('QBCore:Notify', src, "Bukan milikmu!", "error")
            return
        end

        if not data.seed or data.seed == '' then
            TriggerClientEvent('QBCore:Notify', src, "Tanaman rusak (seed tidak ditemukan)", "error")
            return
        end

        if data.growth < 100 then
            TriggerClientEvent('QBCore:Notify', src, "Tanaman belum matang!", "error")
            return
        end

        local amount = math.random(5,10)
        Player.Functions.AddItem(data.seed, amount)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[data.seed], "add")

        exports.oxmysql:execute("DELETE FROM pot_bunga WHERE id = ?", { plantId })
        TriggerClientEvent('potbunga:client:deletePlant', -1, plantId)
        TriggerClientEvent('QBCore:Notify', src, "Kamu memanen "..amount.." "..data.seed.."!", "success")
    end)
end)

-- Use compost
RegisterNetEvent('potbunga:server:useCompost', function(plantId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if not Player.Functions.GetItemByName('compost') then
        TriggerClientEvent('QBCore:Notify', src, "Kamu tidak punya kompos!", "error")
        return
    end

    exports.oxmysql:execute("UPDATE pot_bunga SET has_compost = 1 WHERE id = ?", { plantId })
    TriggerClientEvent('potbunga:client:wateringCan', src)
    Player.Functions.RemoveItem('compost', 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['compost'], "remove")
    TriggerClientEvent('QBCore:Notify', src, "Kompos ditambahkan, tanaman bisa tumbuh maksimal 100%!", "success")
end)

-- Server growth loop
Citizen.CreateThread(function()
    while true do
        exports.oxmysql:execute("SELECT id, growth, has_compost FROM pot_bunga WHERE growth < 100", {}, function(results)
            for _, plant in pairs(results) do
                local maxGrowth = plant.has_compost == 1 and 100 or 50
                local newGrowth = math.min(plant.growth + 10, maxGrowth)
                exports.oxmysql:execute("UPDATE pot_bunga SET growth = ? WHERE id = ?", { newGrowth, plant.id })
                TriggerClientEvent('potbunga:client:updateGrowthPerc', -1, plant.id, newGrowth)
            end
        end)
        Wait(12000)
    end
end)

