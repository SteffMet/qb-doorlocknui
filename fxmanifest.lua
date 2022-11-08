fx_version 'cerulean'
games { 'gta5' }

version '1.0.0'
description 'Fixed version of thelindat\'s nui_doorlock'
versioncheck 'https://raw.githubusercontent.com/thelindat/nui_doorlock/main/fxmanifest.lua'

server_scripts {
	'config.lua',
	'server/main.lua'
}

client_scripts {

	'config.lua',
	'client/main.lua'
}


ui_page {
    'html/door.html',
}

files {
	'html/door.html',
	'html/main.js', 
	'html/style.css',

	'html/sounds/*.ogg',
}
