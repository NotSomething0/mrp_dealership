fx_version 'cerulean'
game 'gta5'
use_experimental_fxv2_oal 'yes'

author 'NotSomething <hello@notsomething.net>'

dependencies {
    'ox_lib',
    'ox_target',
    'ox_core'
}

shared_scripts {
    '@ox_lib/init.lua',
    '@ox_core/lib/init.lua',
    'shared/classes/vehicleDisplaySlot.lua',
    'shared/classes/showroom.lua',
    'shared/classes/dealership.lua',
    'shared/classes/configStore.lua',
}

server_scripts {
    'server/classes/sv_*.lua',
    'server/sv_main.lua',
}

client_scripts {
    'client/classes/*.lua',
    'client/cl_*.lua'
}