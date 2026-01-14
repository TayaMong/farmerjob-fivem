# farmerjob-fivem by WAROENG MODS OPPUNG (TAYA)
for QbCore and Qbox
This script must contain nopixel progress bar or you can edit it, if you use nopixel then you must create its resource folder as np_progressbar

DONT SELL THIS RESOURCE OR YOU'LL HAVE TROUBLE WITH APPLICABLE LAW

## Requirements
 [nopixel progressbar] https://github.com/rohKane/progressbar

# For ox inventory users, add to your items.lua 
```lua
-- =========================
-- SEEDS
-- =========================
['lettuce_seed'] = {
    label = 'Lettuce Seed',
    weight = 10,
    stack = true,
    close = true,
    description = 'Bibit selada',
    client = {
        export = 'ngetest.usePotBunga'
    }
},

['tomato_seed'] = {
    label = 'Tomato Seed',
    weight = 10,
    stack = true,
    close = true,
    description = 'Bibit tomat',
    client = {
        export = 'ngetest.usePotBunga'
    }
},

['cucumber_seed'] = {
    label = 'Cucumber Seed',
    weight = 10,
    stack = true,
    close = true,
    description = 'Bibit timun',
    client = {
        export = 'ngetest.usePotBunga'
    }
},


-- =========================
-- HARVEST
-- =========================
['lettuce'] = {
    label = 'Lettuce',
    weight = 100,
    stack = true,
    close = true,
    description = 'Selada segar hasil panen',
},

['tomato'] = {
    label = 'Tomato',
    weight = 100,
    stack = true,
    close = true,
    description = 'Tomat segar hasil panen',
},

['cucumber'] = {
    label = 'Cucumber',
    weight = 100,
    stack = true,
    close = true,
    description = 'Timun segar hasil panen',
},
['compost'] = {
    label = 'Kompos',
    weight = 100,
    stack = true,
    close = true,
    description = 'Untuk mempercepat pertumbuhan tanaman.'
},

