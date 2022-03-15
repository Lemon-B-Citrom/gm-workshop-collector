Files in this directly need to manually be copied into GarrysMod\garrysmod\lua\menu

If you have other menu mods, such as Addon managers, you may need to edit your own menu.lua manually. After copying workshop_collector_menu.lua, simply add...

    include( "workshop_collector_menu.lua" ) -- Workshop Collector

...inside of your menu.lua