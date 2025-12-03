--[[
    EC Admin Ultimate - Complete FiveM Vehicle Database
    All default GTA V vehicles organized by class
    Used for quick spawning and custom vehicle pack detection
]]

VehicleDatabase = {}

--[[ 
    COMPLETE GTA V VEHICLE DATABASE
    All default vehicles organized by class
]]
VehicleDatabase.DefaultVehicles = {
    -- COMPACTS
    compacts = {
        { model = 'blista', name = 'Blista' },
        { model = 'blista2', name = 'Blista Compact' },
        { model = 'blista3', name = 'Blista Go Go Monkey' },
        { model = 'brioso', name = 'Brioso R/A' },
        { model = 'dilettante', name = 'Dilettante' },
        { model = 'dilettante2', name = 'Dilettante (Merryweather)' },
        { model = 'issi2', name = 'Issi' },
        { model = 'issi3', name = 'Issi Classic' },
        { model = 'issi4', name = 'Apocalypse Issi' },
        { model = 'issi5', name = 'Future Shock Issi' },
        { model = 'issi6', name = 'Nightmare Issi' },
        { model = 'panto', name = 'Panto' },
        { model = 'prairie', name = 'Prairie' },
        { model = 'rhapsody', name = 'Rhapsody' }
    },
    
    -- SEDANS
    sedans = {
        { model = 'asea', name = 'Asea' },
        { model = 'asea2', name = 'Asea (Taxi)' },
        { model = 'asterope', name = 'Asterope' },
        { model = 'cog55', name = 'Cognoscenti 55' },
        { model = 'cog552', name = 'Cognoscenti 55 (Armored)' },
        { model = 'cognoscenti', name = 'Cognoscenti' },
        { model = 'cognoscenti2', name = 'Cognoscenti (Armored)' },
        { model = 'emperor', name = 'Emperor' },
        { model = 'emperor2', name = 'Emperor (Rusty)' },
        { model = 'emperor3', name = 'Emperor (Beater)' },
        { model = 'fugitive', name = 'Fugitive' },
        { model = 'glendale', name = 'Glendale' },
        { model = 'glendale2', name = 'Glendale Custom' },
        { model = 'ingot', name = 'Ingot' },
        { model = 'intruder', name = 'Intruder' },
        { model = 'premier', name = 'Premier' },
        { model = 'primo', name = 'Primo' },
        { model = 'primo2', name = 'Primo Custom' },
        { model = 'regina', name = 'Regina' },
        { model = 'schafter2', name = 'Schafter' },
        { model = 'schafter3', name = 'Schafter V12' },
        { model = 'schafter4', name = 'Schafter LWB' },
        { model = 'schafter5', name = 'Schafter V12 (Armored)' },
        { model = 'schafter6', name = 'Schafter LWB (Armored)' },
        { model = 'stanier', name = 'Stanier' },
        { model = 'stratum', name = 'Stratum' },
        { model = 'stretch', name = 'Stretch' },
        { model = 'superd', name = 'Super Diamond' },
        { model = 'surge', name = 'Surge' },
        { model = 'tailgater', name = 'Tailgater' },
        { model = 'warrener', name = 'Warrener' },
        { model = 'washington', name = 'Washington' }
    },
    
    -- SUVS
    suvs = {
        { model = 'baller', name = 'Baller' },
        { model = 'baller2', name = 'Baller (2nd Gen)' },
        { model = 'baller3', name = 'Baller LE' },
        { model = 'baller4', name = 'Baller LE LWB' },
        { model = 'baller5', name = 'Baller LE (Armored)' },
        { model = 'baller6', name = 'Baller LE LWB (Armored)' },
        { model = 'bjxl', name = 'BeeJay XL' },
        { model = 'cavalcade', name = 'Cavalcade' },
        { model = 'cavalcade2', name = 'Cavalcade (2nd Gen)' },
        { model = 'contender', name = 'Contender' },
        { model = 'dubsta', name = 'Dubsta' },
        { model = 'dubsta2', name = 'Dubsta (Tuned)' },
        { model = 'dubsta3', name = 'Dubsta 6x6' },
        { model = 'fq2', name = 'FQ 2' },
        { model = 'granger', name = 'Granger' },
        { model = 'gresley', name = 'Gresley' },
        { model = 'habanero', name = 'Habanero' },
        { model = 'huntley', name = 'Huntley S' },
        { model = 'landstalker', name = 'Landstalker' },
        { model = 'mesa', name = 'Mesa' },
        { model = 'mesa2', name = 'Mesa (Merryweather)' },
        { model = 'mesa3', name = 'Mesa (Off-Road)' },
        { model = 'patriot', name = 'Patriot' },
        { model = 'radi', name = 'Radius' },
        { model = 'rocoto', name = 'Rocoto' },
        { model = 'seminole', name = 'Seminole' },
        { model = 'serrano', name = 'Serrano' },
        { model = 'xls', name = 'XLS' },
        { model = 'xls2', name = 'XLS (Armored)' }
    },
    
    -- COUPES
    coupes = {
        { model = 'cogcabrio', name = 'Cognoscenti Cabrio' },
        { model = 'exemplar', name = 'Exemplar' },
        { model = 'f620', name = 'F620' },
        { model = 'felon', name = 'Felon' },
        { model = 'felon2', name = 'Felon GT' },
        { model = 'jackal', name = 'Jackal' },
        { model = 'oracle', name = 'Oracle XS' },
        { model = 'oracle2', name = 'Oracle' },
        { model = 'sentinel', name = 'Sentinel' },
        { model = 'sentinel2', name = 'Sentinel XS' },
        { model = 'windsor', name = 'Windsor' },
        { model = 'windsor2', name = 'Windsor Drop' },
        { model = 'zion', name = 'Zion' },
        { model = 'zion2', name = 'Zion Cabrio' }
    },
    
    -- MUSCLE
    muscle = {
        { model = 'blade', name = 'Blade' },
        { model = 'buccaneer', name = 'Buccaneer' },
        { model = 'buccaneer2', name = 'Buccaneer Custom' },
        { model = 'chino', name = 'Chino' },
        { model = 'chino2', name = 'Chino Custom' },
        { model = 'coquette3', name = 'Coquette BlackFin' },
        { model = 'dominator', name = 'Dominator' },
        { model = 'dominator2', name = 'Pisswasser Dominator' },
        { model = 'dominator3', name = 'Dominator GTX' },
        { model = 'dukes', name = 'Dukes' },
        { model = 'dukes2', name = 'Duke O\'Death' },
        { model = 'gauntlet', name = 'Gauntlet' },
        { model = 'gauntlet2', name = 'Redwood Gauntlet' },
        { model = 'hermes', name = 'Hermes' },
        { model = 'hotknife', name = 'Hotknife' },
        { model = 'faction', name = 'Faction' },
        { model = 'faction2', name = 'Faction Custom' },
        { model = 'faction3', name = 'Faction Custom Donk' },
        { model = 'moonbeam', name = 'Moonbeam' },
        { model = 'moonbeam2', name = 'Moonbeam Custom' },
        { model = 'nightshade', name = 'Nightshade' },
        { model = 'phoenix', name = 'Phoenix' },
        { model = 'picador', name = 'Picador' },
        { model = 'ratloader', name = 'Rat Loader' },
        { model = 'ratloader2', name = 'Rat Truck' },
        { model = 'ruiner', name = 'Ruiner' },
        { model = 'ruiner2', name = 'Ruiner 2000' },
        { model = 'ruiner3', name = 'Ruiner (Wreck)' },
        { model = 'sabregt', name = 'Sabre Turbo' },
        { model = 'sabregt2', name = 'Sabre Turbo Custom' },
        { model = 'slamvan', name = 'Slamvan' },
        { model = 'slamvan2', name = 'Lost Slamvan' },
        { model = 'slamvan3', name = 'Slamvan Custom' },
        { model = 'stalion', name = 'Stalion' },
        { model = 'stalion2', name = 'Burger Shot Stallion' },
        { model = 'tampa', name = 'Tampa' },
        { model = 'tampa2', name = 'Weaponized Tampa' },
        { model = 'vigero', name = 'Vigero' },
        { model = 'virgo', name = 'Virgo' },
        { model = 'virgo2', name = 'Virgo Classic Custom' },
        { model = 'virgo3', name = 'Virgo Classic' },
        { model = 'voodoo', name = 'Voodoo' },
        { model = 'voodoo2', name = 'Voodoo Custom' }
    },
    
    -- SPORTS CLASSICS
    sportsclassics = {
        { model = 'btype', name = 'Roosevelt' },
        { model = 'btype2', name = 'Franken Stange' },
        { model = 'btype3', name = 'Roosevelt Valor' },
        { model = 'casco', name = 'Casco' },
        { model = 'coquette2', name = 'Coquette Classic' },
        { model = 'deluxo', name = 'Deluxo' },
        { model = 'dynasty', name = 'Dynasty' },
        { model = 'fagaloa', name = 'Fagaloa' },
        { model = 'feltzer3', name = 'Stirling GT' },
        { model = 'gt500', name = 'GT500' },
        { model = 'infernus2', name = 'Infernus Classic' },
        { model = 'jb700', name = 'JB 700' },
        { model = 'mamba', name = 'Mamba' },
        { model = 'manana', name = 'Manana' },
        { model = 'monroe', name = 'Monroe' },
        { model = 'peyote', name = 'Peyote' },
        { model = 'pigalle', name = 'Pigalle' },
        { model = 'rapidgt3', name = 'Rapid GT Classic' },
        { model = 'retinue', name = 'Retinue' },
        { model = 'stinger', name = 'Stinger' },
        { model = 'stingergt', name = 'Stinger GT' },
        { model = 'stromberg', name = 'Stromberg' },
        { model = 'torero', name = 'Torero' },
        { model = 'tornado', name = 'Tornado' },
        { model = 'tornado2', name = 'Tornado Cabrio' },
        { model = 'tornado3', name = 'Tornado (Rusty)' },
        { model = 'tornado4', name = 'Tornado Cabrio (Rusty)' },
        { model = 'tornado5', name = 'Tornado Custom' },
        { model = 'tornado6', name = 'Tornado Rat Rod' },
        { model = 'turismo2', name = 'Turismo Classic' },
        { model = 'viseris', name = 'Viseris' },
        { model = 'z190', name = 'Z190' },
        { model = 'ztype', name = 'Z-Type' }
    },
    
    -- SPORTS
    sports = {
        { model = '9f', name = '9F' },
        { model = '9f2', name = '9F Cabrio' },
        { model = 'alpha', name = 'Alpha' },
        { model = 'banshee', name = 'Banshee' },
        { model = 'banshee2', name = 'Banshee 900R' },
        { model = 'bestiagts', name = 'Bestia GTS' },
        { model = 'blista', name = 'Blista' },
        { model = 'buffalo', name = 'Buffalo' },
        { model = 'buffalo2', name = 'Buffalo S' },
        { model = 'buffalo3', name = 'Sprunk Buffalo' },
        { model = 'carbonizzare', name = 'Carbonizzare' },
        { model = 'comet2', name = 'Comet' },
        { model = 'comet3', name = 'Comet Retro Custom' },
        { model = 'comet4', name = 'Comet Safari' },
        { model = 'comet5', name = 'Comet SR' },
        { model = 'coquette', name = 'Coquette' },
        { model = 'elegy', name = 'Elegy RH8' },
        { model = 'elegy2', name = 'Elegy Retro Custom' },
        { model = 'feltzer2', name = 'Feltzer' },
        { model = 'flashgt', name = 'Flash GT' },
        { model = 'furoregt', name = 'Furore GT' },
        { model = 'fusilade', name = 'Fusilade' },
        { model = 'futo', name = 'Futo' },
        { model = 'gb200', name = 'GB200' },
        { model = 'hotring', name = 'Hotring Sabre' },
        { model = 'jester', name = 'Jester' },
        { model = 'jester2', name = 'Jester (Racecar)' },
        { model = 'jester3', name = 'Jester Classic' },
        { model = 'khamelion', name = 'Khamelion' },
        { model = 'kuruma', name = 'Kuruma' },
        { model = 'kuruma2', name = 'Kuruma (Armored)' },
        { model = 'lynx', name = 'Lynx' },
        { model = 'massacro', name = 'Massacro' },
        { model = 'massacro2', name = 'Massacro (Racecar)' },
        { model = 'neon', name = 'Neon' },
        { model = 'ninef', name = 'Ninef' },
        { model = 'ninef2', name = 'Ninef Cabrio' },
        { model = 'omnis', name = 'Omnis' },
        { model = 'pariah', name = 'Pariah' },
        { model = 'penumbra', name = 'Penumbra' },
        { model = 'raiden', name = 'Raiden' },
        { model = 'rapidgt', name = 'Rapid GT' },
        { model = 'rapidgt2', name = 'Rapid GT Cabrio' },
        { model = 'raptor', name = 'Raptor' },
        { model = 'revolter', name = 'Revolter' },
        { model = 'ruston', name = 'Ruston' },
        { model = 'schafter3', name = 'Schafter V12' },
        { model = 'schlagen', name = 'Schlagen GT' },
        { model = 'schwarzer', name = 'Schwarzer' },
        { model = 'sentinel3', name = 'Sentinel Classic' },
        { model = 'seven70', name = 'Seven-70' },
        { model = 'specter', name = 'Specter' },
        { model = 'specter2', name = 'Specter Custom' },
        { model = 'streiter', name = 'Streiter' },
        { model = 'sultan', name = 'Sultan' },
        { model = 'sultanrs', name = 'Sultan RS' },
        { model = 'surano', name = 'Surano' },
        { model = 'tampa2', name = 'Weaponized Tampa' },
        { model = 'tropos', name = 'Tropos Rallye' },
        { model = 'verlierer2', name = 'Verlierer' },
        { model = 'vstr', name = 'V-STR' }
    },
    
    -- SUPER
    super = {
        { model = 'adder', name = 'Adder' },
        { model = 'autarch', name = 'Autarch' },
        { model = 'banshee2', name = 'Banshee 900R' },
        { model = 'bullet', name = 'Bullet' },
        { model = 'cheetah', name = 'Cheetah' },
        { model = 'cyclone', name = 'Cyclone' },
        { model = 'entityxf', name = 'Entity XF' },
        { model = 'entity2', name = 'Entity XXR' },
        { model = 'fmj', name = 'FMJ' },
        { model = 'gp1', name = 'GP1' },
        { model = 'infernus', name = 'Infernus' },
        { model = 'italigtb', name = 'Itali GTB' },
        { model = 'italigtb2', name = 'Itali GTB Custom' },
        { model = 'nero', name = 'Nero' },
        { model = 'nero2', name = 'Nero Custom' },
        { model = 'osiris', name = 'Osiris' },
        { model = 'penetrator', name = 'Penetrator' },
        { model = 'pfister811', name = 'Pfister 811' },
        { model = 'prototipo', name = 'X80 Proto' },
        { model = 'reaper', name = 'Reaper' },
        { model = 'sc1', name = 'SC1' },
        { model = 'scramjet', name = 'Scramjet' },
        { model = 'sheava', name = 'ETR1' },
        { model = 'sultanrs', name = 'Sultan RS' },
        { model = 't20', name = 'T20' },
        { model = 'taipan', name = 'Taipan' },
        { model = 'tempesta', name = 'Tempesta' },
        { model = 'tezeract', name = 'Tezeract' },
        { model = 'turismor', name = 'Turismo R' },
        { model = 'tyrant', name = 'Tyrant' },
        { model = 'tyrus', name = 'Tyrus' },
        { model = 'vacca', name = 'Vacca' },
        { model = 'vagner', name = 'Vagner' },
        { model = 'vigilante', name = 'Vigilante' },
        { model = 'visione', name = 'Visione' },
        { model = 'voltic', name = 'Voltic' },
        { model = 'voltic2', name = 'Rocket Voltic' },
        { model = 'xa21', name = 'XA-21' },
        { model = 'zentorno', name = 'Zentorno' }
    },
    
    -- MOTORCYCLES
    motorcycles = {
        { model = 'akuma', name = 'Akuma' },
        { model = 'avarus', name = 'Avarus' },
        { model = 'bagger', name = 'Bagger' },
        { model = 'bati', name = 'Bati 801' },
        { model = 'bati2', name = 'Bati 801RR' },
        { model = 'bf400', name = 'BF400' },
        { model = 'carbonrs', name = 'Carbon RS' },
        { model = 'chimera', name = 'Chimera' },
        { model = 'cliffhanger', name = 'Cliffhanger' },
        { model = 'daemon', name = 'Daemon' },
        { model = 'daemon2', name = 'Daemon (Lost)' },
        { model = 'defiler', name = 'Defiler' },
        { model = 'diablous', name = 'Diabolus' },
        { model = 'diablous2', name = 'Diabolus Custom' },
        { model = 'double', name = 'Double T' },
        { model = 'enduro', name = 'Enduro' },
        { model = 'esskey', name = 'Esskey' },
        { model = 'faggio', name = 'Faggio' },
        { model = 'faggio2', name = 'Faggio Sport' },
        { model = 'faggio3', name = 'Faggio Mod' },
        { model = 'fcr', name = 'FCR 1000' },
        { model = 'fcr2', name = 'FCR 1000 Custom' },
        { model = 'gargoyle', name = 'Gargoyle' },
        { model = 'hakuchou', name = 'Hakuchou' },
        { model = 'hakuchou2', name = 'Hakuchou Drag' },
        { model = 'hexer', name = 'Hexer' },
        { model = 'innovation', name = 'Innovation' },
        { model = 'lectro', name = 'Lectro' },
        { model = 'manchez', name = 'Manchez' },
        { model = 'nemesis', name = 'Nemesis' },
        { model = 'nightblade', name = 'Nightblade' },
        { model = 'oppressor', name = 'Oppressor' },
        { model = 'oppressor2', name = 'Oppressor Mk II' },
        { model = 'pcj', name = 'PCJ 600' },
        { model = 'ratbike', name = 'Rat Bike' },
        { model = 'ruffian', name = 'Ruffian' },
        { model = 'sanchez', name = 'Sanchez' },
        { model = 'sanchez2', name = 'Sanchez (Livery)' },
        { model = 'sanctus', name = 'Sanctus' },
        { model = 'shotaro', name = 'Shotaro' },
        { model = 'sovereign', name = 'Sovereign' },
        { model = 'thrust', name = 'Thrust' },
        { model = 'vader', name = 'Vader' },
        { model = 'vindicator', name = 'Vindicator' },
        { model = 'vortex', name = 'Vortex' },
        { model = 'wolfsbane', name = 'Wolfsbane' },
        { model = 'zombiea', name = 'Zombie Bobber' },
        { model = 'zombieb', name = 'Zombie Chopper' }
    },
    
    -- OFF-ROAD
    offroad = {
        { model = 'bfinjection', name = 'BF Injection' },
        { model = 'bifta', name = 'Bifta' },
        { model = 'blazer', name = 'Blazer' },
        { model = 'blazer2', name = 'Blazer Lifeguard' },
        { model = 'blazer3', name = 'Hot Rod Blazer' },
        { model = 'blazer4', name = 'Street Blazer' },
        { model = 'blazer5', name = 'Blazer Aqua' },
        { model = 'bodhi2', name = 'Bodhi' },
        { model = 'brawler', name = 'Brawler' },
        { model = 'caracara', name = 'Caracara' },
        { model = 'dloader', name = 'Duneloader' },
        { model = 'dubsta3', name = 'Dubsta 6x6' },
        { model = 'dune', name = 'Dune Buggy' },
        { model = 'dune2', name = 'Space Docker' },
        { model = 'dune3', name = 'Dune FAV' },
        { model = 'dune4', name = 'Ramp Buggy' },
        { model = 'dune5', name = 'Ramp Buggy (Arena War)' },
        { model = 'freecrawler', name = 'Freecrawler' },
        { model = 'insurgent', name = 'Insurgent Pick-Up' },
        { model = 'insurgent2', name = 'Insurgent' },
        { model = 'insurgent3', name = 'Insurgent Pick-Up Custom' },
        { model = 'kalahari', name = 'Kalahari' },
        { model = 'kamacho', name = 'Kamacho' },
        { model = 'marshall', name = 'Marshall' },
        { model = 'menacer', name = 'Menacer' },
        { model = 'mesa3', name = 'Mesa (Off-Road)' },
        { model = 'monster', name = 'Liberator' },
        { model = 'nightshark', name = 'Nightshark' },
        { model = 'rancherxl', name = 'Rancher XL' },
        { model = 'rancherxl2', name = 'Rancher XL (Snow)' },
        { model = 'rebel', name = 'Rebel' },
        { model = 'rebel2', name = 'Rusty Rebel' },
        { model = 'rcbandito', name = 'RC Bandito' },
        { model = 'riata', name = 'Riata' },
        { model = 'sandking', name = 'Sandking XL' },
        { model = 'sandking2', name = 'Sandking SWB' },
        { model = 'technical', name = 'Technical' },
        { model = 'technical2', name = 'Technical Aqua' },
        { model = 'technical3', name = 'Technical Custom' },
        { model = 'trophytruck', name = 'Trophy Truck' },
        { model = 'trophytruck2', name = 'Desert Raid' }
    },
    
    -- VANS
    vans = {
        { model = 'bison', name = 'Bison' },
        { model = 'bison2', name = 'Bison (2nd Gen)' },
        { model = 'bison3', name = 'Bison (3rd Gen)' },
        { model = 'bobcatxl', name = 'Bobcat XL' },
        { model = 'boxville', name = 'Boxville' },
        { model = 'boxville2', name = 'Boxville (Post Op)' },
        { model = 'boxville3', name = 'Boxville (Humane Labs)' },
        { model = 'boxville4', name = 'Boxville (RON)' },
        { model = 'boxville5', name = 'Armored Boxville' },
        { model = 'burrito', name = 'Burrito' },
        { model = 'burrito2', name = 'Burrito (Snow)' },
        { model = 'burrito3', name = 'Burrito (Gang)' },
        { model = 'burrito4', name = 'Burrito (Bug Stars)' },
        { model = 'burrito5', name = 'Burrito (The Lost)' },
        { model = 'camper', name = 'Camper' },
        { model = 'gburrito', name = 'Gang Burrito' },
        { model = 'gburrito2', name = 'Gang Burrito (The Lost)' },
        { model = 'journey', name = 'Journey' },
        { model = 'minivan', name = 'Minivan' },
        { model = 'minivan2', name = 'Minivan Custom' },
        { model = 'paradise', name = 'Paradise' },
        { model = 'pony', name = 'Pony' },
        { model = 'pony2', name = 'Pony (Weed)' },
        { model = 'rumpo', name = 'Rumpo' },
        { model = 'rumpo2', name = 'Rumpo (Deludamol)' },
        { model = 'rumpo3', name = 'Rumpo Custom' },
        { model = 'speedo', name = 'Speedo' },
        { model = 'speedo2', name = 'Speedo (Clown)' },
        { model = 'speedo4', name = 'Speedo Custom' },
        { model = 'surfer', name = 'Surfer' },
        { model = 'surfer2', name = 'Surfer (Rusty)' },
        { model = 'taco', name = 'Taco Van' },
        { model = 'youga', name = 'Youga' },
        { model = 'youga2', name = 'Youga Classic' }
    },
    
    -- COMMERCIAL
    commercial = {
        { model = 'benson', name = 'Benson' },
        { model = 'biff', name = 'Biff' },
        { model = 'cerberus', name = 'Cerberus (Apocalypse)' },
        { model = 'cerberus2', name = 'Cerberus (Future Shock)' },
        { model = 'cerberus3', name = 'Cerberus (Nightmare)' },
        { model = 'hauler', name = 'Hauler' },
        { model = 'hauler2', name = 'Hauler Custom' },
        { model = 'mule', name = 'Mule' },
        { model = 'mule2', name = 'Mule (Jetsam)' },
        { model = 'mule3', name = 'Mule (Postal)' },
        { model = 'mule4', name = 'Mule Custom' },
        { model = 'packer', name = 'Packer' },
        { model = 'phantom', name = 'Phantom' },
        { model = 'phantom2', name = 'Phantom Wedge' },
        { model = 'phantom3', name = 'Phantom Custom' },
        { model = 'pounder', name = 'Pounder' },
        { model = 'pounder2', name = 'Pounder Custom' },
        { model = 'stockade', name = 'Stockade' },
        { model = 'stockade3', name = 'Stockade (Snow)' },
        { model = 'terbyte', name = 'Terrorbyte' }
    },
    
    -- INDUSTRIAL
    industrial = {
        { model = 'bulldozer', name = 'Bulldozer' },
        { model = 'cutter', name = 'Cutter' },
        { model = 'dump', name = 'Dump' },
        { model = 'flatbed', name = 'Flatbed' },
        { model = 'guardian', name = 'Guardian' },
        { model = 'handler', name = 'Dock Handler' },
        { model = 'mixer', name = 'Mixer' },
        { model = 'mixer2', name = 'Mixer (Ramp Car)' },
        { model = 'rubble', name = 'Rubble' },
        { model = 'tiptruck', name = 'Tipper' },
        { model = 'tiptruck2', name = 'Tipper (2nd Gen)' }
    },
    
    -- UTILITY
    utility = {
        { model = 'airtug', name = 'Airtug' },
        { model = 'caddy', name = 'Caddy' },
        { model = 'caddy2', name = 'Caddy (Golf)' },
        { model = 'caddy3', name = 'Caddy (Rusty)' },
        { model = 'docktug', name = 'Docktug' },
        { model = 'forklift', name = 'Forklift' },
        { model = 'mower', name = 'Lawn Mower' },
        { model = 'ripley', name = 'Ripley' },
        { model = 'sadler', name = 'Sadler' },
        { model = 'sadler2', name = 'Sadler (Snow)' },
        { model = 'scrap', name = 'Scrap Truck' },
        { model = 'towtruck', name = 'Towtruck' },
        { model = 'towtruck2', name = 'Towtruck (Large)' },
        { model = 'tractor', name = 'Tractor (Rusty)' },
        { model = 'tractor2', name = 'Fieldmaster' },
        { model = 'tractor3', name = 'Tractor (Snow)' },
        { model = 'utillitruck', name = 'Utility Truck' },
        { model = 'utillitruck2', name = 'Utility Truck (Cherrypicker)' },
        { model = 'utillitruck3', name = 'Utility Truck (Lift)' }
    },
    
    -- EMERGENCY
    emergency = {
        { model = 'ambulance', name = 'Ambulance' },
        { model = 'fbi', name = 'FIB' },
        { model = 'fbi2', name = 'FIB Buffalo' },
        { model = 'firetruk', name = 'Fire Truck' },
        { model = 'lguard', name = 'Lifeguard' },
        { model = 'pbus', name = 'Prison Bus' },
        { model = 'police', name = 'Police Cruiser' },
        { model = 'police2', name = 'Police Buffalo' },
        { model = 'police3', name = 'Police Interceptor' },
        { model = 'police4', name = 'Police Ranger' },
        { model = 'policeb', name = 'Police Bike' },
        { model = 'policeold1', name = 'Police Rancher (Cut)' },
        { model = 'policeold2', name = 'Police Roadcruiser (Cut)' },
        { model = 'policet', name = 'Police Transporter' },
        { model = 'polmav', name = 'Police Maverick' },
        { model = 'pranger', name = 'Park Ranger' },
        { model = 'predator', name = 'Police Predator' },
        { model = 'riot', name = 'Riot Van' },
        { model = 'riot2', name = 'RCV' },
        { model = 'sheriff', name = 'Sheriff Cruiser' },
        { model = 'sheriff2', name = 'Sheriff SUV' }
    },
    
    -- PLANES
    planes = {
        { model = 'alphaz1', name = 'Alpha-Z1' },
        { model = 'avenger', name = 'Avenger' },
        { model = 'avenger2', name = 'Avenger (Interior)' },
        { model = 'besra', name = 'Besra' },
        { model = 'blimp', name = 'Blimp' },
        { model = 'blimp2', name = 'Blimp (Atomic)' },
        { model = 'blimp3', name = 'Blimp (Xero)' },
        { model = 'bombushka', name = 'RM-10 Bombushka' },
        { model = 'cargoplane', name = 'Cargo Plane' },
        { model = 'cuban800', name = 'Cuban 800' },
        { model = 'dodo', name = 'Dodo' },
        { model = 'duster', name = 'Duster' },
        { model = 'hydra', name = 'Hydra' },
        { model = 'jet', name = 'Jet' },
        { model = 'lazer', name = 'P-996 LAZER' },
        { model = 'luxor', name = 'Luxor' },
        { model = 'luxor2', name = 'Luxor Deluxe' },
        { model = 'mammatus', name = 'Mammatus' },
        { model = 'microlight', name = 'Ultralight' },
        { model = 'miljet', name = 'Miljet' },
        { model = 'mogul', name = 'Mogul' },
        { model = 'molotok', name = 'V-65 Molotok' },
        { model = 'nimbus', name = 'Nimbus' },
        { model = 'nokota', name = 'P-45 Nokota' },
        { model = 'pyro', name = 'Pyro' },
        { model = 'rogue', name = 'Rogue' },
        { model = 'seabreeze', name = 'Seabreeze' },
        { model = 'shamal', name = 'Shamal' },
        { model = 'starling', name = 'LF-22 Starling' },
        { model = 'stunt', name = 'Mallard' },
        { model = 'titan', name = 'Titan' },
        { model = 'tula', name = 'Tula' },
        { model = 'velum', name = 'Velum' },
        { model = 'velum2', name = 'Velum (5-Seater)' },
        { model = 'vestra', name = 'Vestra' },
        { model = 'volatol', name = 'Volatol' }
    },
    
    -- HELICOPTERS
    helicopters = {
        { model = 'akula', name = 'Akula' },
        { model = 'annihilator', name = 'Annihilator' },
        { model = 'buzzard', name = 'Buzzard' },
        { model = 'buzzard2', name = 'Buzzard Attack Chopper' },
        { model = 'cargobob', name = 'Cargobob' },
        { model = 'cargobob2', name = 'Cargobob (Jetsam)' },
        { model = 'cargobob3', name = 'Cargobob (TPE)' },
        { model = 'cargobob4', name = 'Cargobob (LSPD)' },
        { model = 'frogger', name = 'Frogger' },
        { model = 'frogger2', name = 'Frogger (TPE)' },
        { model = 'havok', name = 'Havok' },
        { model = 'hunter', name = 'Hunter' },
        { model = 'maverick', name = 'Maverick' },
        { model = 'polmav', name = 'Police Maverick' },
        { model = 'savage', name = 'Savage' },
        { model = 'seasparrow', name = 'Sea Sparrow' },
        { model = 'skylift', name = 'Skylift' },
        { model = 'supervolito', name = 'SuperVolito' },
        { model = 'supervolito2', name = 'SuperVolito Carbon' },
        { model = 'swift', name = 'Swift' },
        { model = 'swift2', name = 'Swift Deluxe' },
        { model = 'valkyrie', name = 'Valkyrie' },
        { model = 'valkyrie2', name = 'Valkyrie MOD.0' },
        { model = 'volatus', name = 'Volatus' }
    },
    
    -- BOATS
    boats = {
        { model = 'dinghy', name = 'Dinghy' },
        { model = 'dinghy2', name = 'Dinghy (2-Seater)' },
        { model = 'dinghy3', name = 'Dinghy (Heist)' },
        { model = 'dinghy4', name = 'Dinghy (Yacht)' },
        { model = 'jetmax', name = 'Jetmax' },
        { model = 'marquis', name = 'Marquis' },
        { model = 'predator', name = 'Police Predator' },
        { model = 'seashark', name = 'Seashark' },
        { model = 'seashark2', name = 'Seashark (Lifeguard)' },
        { model = 'seashark3', name = 'Seashark (Yacht)' },
        { model = 'speeder', name = 'Speeder' },
        { model = 'speeder2', name = 'Speeder (Yacht)' },
        { model = 'squalo', name = 'Squalo' },
        { model = 'suntrap', name = 'Suntrap' },
        { model = 'toro', name = 'Toro' },
        { model = 'toro2', name = 'Toro (Yacht)' },
        { model = 'tropic', name = 'Tropic' },
        { model = 'tropic2', name = 'Tropic (Yacht)' },
        { model = 'tug', name = 'Tug' }
    }
}

-- Get all vehicles in a flat list
function VehicleDatabase.GetAllVehicles()
    local allVehicles = {}
    
    for class, vehicles in pairs(VehicleDatabase.DefaultVehicles) do
        for _, vehicle in ipairs(vehicles) do
            table.insert(allVehicles, {
                model = vehicle.model,
                name = vehicle.name,
                class = class
            })
        end
    end
    
    return allVehicles
end

-- Get vehicles by class
function VehicleDatabase.GetVehiclesByClass(className)
    return VehicleDatabase.DefaultVehicles[className] or {}
end

-- Search vehicles by name or model
function VehicleDatabase.SearchVehicles(query)
    if not query or query == '' then
        return VehicleDatabase.GetAllVehicles()
    end
    
    local results = {}
    local lowerQuery = string.lower(query)
    
    for class, vehicles in pairs(VehicleDatabase.DefaultVehicles) do
        for _, vehicle in ipairs(vehicles) do
            if string.find(string.lower(vehicle.model), lowerQuery) or
               string.find(string.lower(vehicle.name), lowerQuery) then
                table.insert(results, {
                    model = vehicle.model,
                    name = vehicle.name,
                    class = class
                })
            end
        end
    end
    
    return results
end

-- Check if a vehicle is a default GTA V vehicle
function VehicleDatabase.IsDefaultVehicle(model)
    for _, vehicles in pairs(VehicleDatabase.DefaultVehicles) do
        for _, vehicle in ipairs(vehicles) do
            if string.lower(vehicle.model) == string.lower(model) then
                return true
            end
        end
    end
    return false
end

-- Get vehicle display name
function VehicleDatabase.GetVehicleName(model)
    for _, vehicles in pairs(VehicleDatabase.DefaultVehicles) do
        for _, vehicle in ipairs(vehicles) do
            if string.lower(vehicle.model) == string.lower(model) then
                return vehicle.name
            end
        end
    end
    return model -- Return model if not found
end

return VehicleDatabase
