QBCore = nil
local doorInfo = {}

Citizen.CreateThread(function()
	local xPlayers = #QBCore.Functions.GetPlayers()
	local path = GetResourcePath(GetCurrentResourceName())
	path = path:gsub('//', '/')..'/server/states.json'
	local file = io.open(path, 'r')
	if not file or xPlayers == 0 then
		file = io.open(path, 'a')
		for k,v in pairs(Config.DoorList) do
			doorInfo[k] = v.locked
		end
	else
		local data = file:read('*a')
		file:close()
		if #json.decode(data) > #Config.DoorList then -- Config.DoorList contains less doors than states.json, so don't restore states
			return
		elseif #json.decode(data) > 0 then
			for k,v in pairs(json.decode(data)) do
				doorInfo[k] = v
			end
		end
	end
end)

AddEventHandler('onResourceStop', function(resourceName)
	if (GetCurrentResourceName() ~= resourceName) then
	  return
	end
	local path = GetResourcePath(resourceName)
	path = path:gsub('//', '/')..'/server/states.json'
	local file = io.open(path, 'r+')
	if file and doorInfo then
		local json = json.encode(doorInfo)
		file:write(json)
		file:close()
	end
end)

TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)

RegisterServerEvent('nui_doorlock:updateState')
AddEventHandler('nui_doorlock:updateState', function(doorID, locked, src, usedLockpick)
	local playerId = source
	local xPlayer = QBCore.Functions.GetPlayer(playerId)
	--local PlayerData = QBCore.Functions.GetPlayerData()

	if type(doorID) ~= 'number' then
		print(('nui_doorlock: %s (%s) didn\'t send a number! (Sent %s)'):format(xPlayer.PlayerData.name(), xPlayer.PlayerData.steam(), doorID))
		return
	end

	if type(locked) ~= 'boolean' then
		print(('nui_doorlock: %s (%s) attempted to update invalid state! (Sent %s)'):format(xPlayer.PlayerData.name(), xPlayer.PlayerData.steam(), locked))
		return
	end

	if not Config.DoorList[doorID] then
		print(('nui_doorlock: %s (%s) attempted to update invalid door! (Sent %s)'):format(xPlayer.PlayerData.name(), xPlayer.PlayerData.steam(), doorID))
		return
	end
	
	if not IsAuthorized(xPlayer, Config.DoorList[doorID], doorInfo[doorID], usedLockpick) then
		return
	end

	doorInfo[doorID] = locked
	if not src then TriggerClientEvent('nui_doorlock:setState', -1, playerId, doorID, locked)
	else TriggerClientEvent('nui_doorlock:setState', -1, playerId, doorID, locked, src) end

	if Config.DoorList[doorID].autoLock then
		Citizen.SetTimeout(Config.DoorList[doorID].autoLock, function()
			if doorInfo[doorID] == true then return end
			doorInfo[doorID] = true
			TriggerClientEvent('nui_doorlock:setState', -1, -1, doorID, true)
		end)
	end
end)

QBCore.Functions.CreateCallback('nui_doorlock:getDoorInfo', function(source, cb)
	cb(doorInfo)
end)

function IsAuthorized(xPlayer, doorID, locked, usedLockpick)
--	local jobName, grade = {}, {}
--	jobName[1] = xPlayer.job.name
--	grade[1] = xPlayer.job.grade
	local src = source
	local xPlayer = QBCore.Functions.GetPlayer(src)
	local jobname = xPlayer.PlayerData.job.name
	local gradename = xPlayer.PlayerData.job.grade.level
	local canOpen = false

	if not canOpen and doorID.authorizedJobs then
		for job,rank in pairs(doorID.authorizedJobs) do
			if job == xPlayer.PlayerData.job.name and rank <= xPlayer.PlayerData.job.grade.level then
				canOpen = true
				if canOpen then break end
			end
		end
		for job,rank in pairs(doorID.authorizedJobs) do
			if job == xPlayer.PlayerData.gang.name then
				canOpen = true
				if canOpen then break end
			end
		end
		for job,rank in pairs(doorID.authorizedJobs) do
			if job == xPlayer.PlayerData.citizenid then
				canOpen = true
				if canOpen then break end
			end
		end

		
		if not canOpen and not doorID.items then
			print(('nui_doorlock: %s (%s) was not authorized to open a locked door!'):format(xPlayer.PlayerData.name, xPlayer.PlayerData.steam))
		end
	end

	
	return canOpen
end

RegisterServerEvent('qb-doorlock:server:updateState')
AddEventHandler('qb-doorlock:server:updateState', function(doorID, state)
	local playerId = source
	local xPlayer = QBCore.Functions.GetPlayer(playerId)
	
	TriggerClientEvent('nui_doorlock:setState', -1, playerId, doorID, state)

end)





RegisterCommand('newdoor', function(playerId, args, rawCommand)
	TriggerClientEvent('nui_doorlock:newDoorSetup', playerId, args)
end, true)

RegisterCommand('testdoors', function(playerId, args)
	local doorno = tonumber(args[1])
	local doorlock = tostring(args[2])
	local lock = true
	print(doorlock)
	
	
	if doorlock == "false" then lock = nil 
		print(doorno, lock)
		TriggerEvent('qb-doorlock:server:updateState', playerId, doorno, lock)
	elseif doorlock == "true" then
		lock = true
		print(doorno, lock)
		TriggerEvent('qb-doorlock:server:updateState', playerId, doorno, lock)
		
	end
end, true)




RegisterServerEvent('nui_doorlock:newDoorCreate')
AddEventHandler('nui_doorlock:newDoorCreate', function(model, heading, coords, jobs, item, doorLocked, maxDistance, slides, garage, doubleDoor, doorname)
	local src = source
	xPlayer = QBCore.Functions.GetPlayer(src)
	if not IsPlayerAceAllowed(src, 'command.newdoor') then print(xPlayer.getName().. 'attempted to create a new door but does not have permission') return end
	doorLocked = tostring(doorLocked)
	slides = tostring(slides)
	garage = tostring(garage)
	local newDoor = {}
	if jobs[1] then auth = tostring("['"..jobs[1].."']=0") end
	if jobs[2] then auth = auth..', '..tostring("['"..jobs[2].."']=0") end
	if jobs[3] then auth = auth..', '..tostring("['"..jobs[3].."']=0") end
	if jobs[4] then auth = auth..', '..tostring("['"..jobs[4].."']=0") end

	if auth then newDoor.authorizedJobs = { auth } end
	if item then newDoor.items = { item } end
	newDoor.locked = doorLocked
	newDoor.maxDistance = maxDistance
	newDoor.slides = slides
	if not doubleDoor then
		newDoor.garage = garage
		newDoor.objHash = model
		newDoor.objHeading = heading
		newDoor.objCoords = coords
		newDoor.fixText = false
	else
		newDoor.doors = {
			{objHash = model[1], objHeading = heading[1], objCoords = coords[1]},
			{objHash = model[2], objHeading = heading[2], objCoords = coords[2]}
		}
	end
		newDoor.audioRemote = false
		newDoor.lockpick = false
	local path = GetResourcePath(GetCurrentResourceName())
	path = path:gsub('//', '/')..'/config.lua'

	file = io.open(path, 'a+')
	if not doorname then label = '\n\n-- UNNAMED DOOR CREATED BY '..xPlayer.getName()..'\ntable.insert(Config.DoorList, {'
	else
		label = '\n\n-- '..doorname.. '\ntable.insert(Config.DoorList, {'
	end
	file:write(label)
	for k,v in pairs(newDoor) do
		if k == 'authorizedJobs' then
			local str =  ('\n	%s = { %s },'):format(k, auth)
			file:write(str)
		elseif k == 'doors' then
			local doorStr = {}
			for i=1, 2 do
				table.insert(doorStr, ('	{objHash = %s, objHeading = %s, objCoords = %s}'):format(model[i], heading[i], coords[i]))
			end
			local str = ('\n	%s = {\n	%s,\n	%s\n },'):format(k, doorStr[1], doorStr[2])
			file:write(str)
		elseif k == 'items' then
			local str = ('\n	%s = { \'%s\' },'):format(k, item)
			file:write(str)
		else
			local str = ('\n	%s = %s,'):format(k, v)
			file:write(str)
		end
	end
	file:write([[
		
	-- oldMethod = true,
	-- audioLock = {['file'] = 'metal-locker.ogg', ['volume'] = 0.6},
	-- audioUnlock = {['file'] = 'metallic-creak.ogg', ['volume'] = 0.7},
	-- autoLock = 1000]])
	file:write('\n})')
	file:close()
	local doorID = #Config.DoorList + 1
	
	if jobs[4] then newDoor.authorizedJobs = { [jobs[1]] = 0, [jobs[2]] = 0, [jobs[3]] = 0, [jobs[4]] = 0 }
	elseif jobs[3] then newDoor.authorizedJobs = { [jobs[1]] = 0, [jobs[2]] = 0, [jobs[3]] = 0 }
	elseif jobs[2] then newDoor.authorizedJobs = { [jobs[1]] = 0, [jobs[2]] = 0 }
	elseif jobs[1] then newDoor.authorizedJobs = { [jobs[1]] = 0 } end
	if item then newDoor.Items = { item } end

	Config.DoorList[doorID] = newDoor
	doorInfo[doorID] = doorLocked 
	TriggerClientEvent('nui_doorlock:newDoorAdded', -1, newDoor, doorID, doorLocked)
end)



-- Test command that causes all doors to change state
--[[RegisterCommand('testdoors', function(playerId, args, rawCommand)
	for k, v in pairs(doorInfo) do
		if v == true then lock = false else lock = true end
		doorInfo[k] = lock
		print(doorInfo)
		TriggerClientEvent('nui_doorlock:setState', -1, k, lock)
	end
end, true)]]--



-- VERSION CHECK
