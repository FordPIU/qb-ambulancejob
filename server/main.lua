local PlayerInjuries = {}
local PlayerWeaponWounds = {}
local QBCore = exports['qb-core']:GetCoreObject()
local doctorCount = 0
-- Events

-- Compatibility with txAdmin Menu's heal options.
-- This is an admin only server side event that will pass the target player id or -1.
RegisterNetEvent('hospital:server:ambulanceAlert', function(text)
    local src = source
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local players = QBCore.Functions.GetQBPlayers()
    for _, v in pairs(players) do
        if v.PlayerData.job.name == 'ambulance' and v.PlayerData.job.onduty then
            TriggerClientEvent('hospital:client:ambulanceAlert', v.PlayerData.source, coords, text)
        end
    end
end)

RegisterNetEvent('hospital:server:AddDoctor', function(job)
	if job == 'ambulance' then
		doctorCount = doctorCount + 1
		TriggerClientEvent("hospital:client:SetDoctorCount", -1, doctorCount)
	end
end)

RegisterNetEvent('hospital:server:RemoveDoctor', function(job)
	if job == 'ambulance' then
		doctorCount = doctorCount - 1
		TriggerClientEvent("hospital:client:SetDoctorCount", -1, doctorCount)
	end
end)

RegisterNetEvent('hospital:server:SendDoctorAlert', function()
    local players = QBCore.Functions.GetQBPlayers()
    for _, v in pairs(players) do
        if v.PlayerData.job.name == 'ambulance' and v.PlayerData.job.onduty then
			TriggerClientEvent('QBCore:Notify', v.PlayerData.source, Lang:t('info.dr_needed'), 'ambulance')
		end
	end
end)

-- Callbacks

QBCore.Functions.CreateCallback('hospital:GetDoctors', function(_, cb)
	local amount = 0
    local players = QBCore.Functions.GetQBPlayers()
    for _, v in pairs(players) do
        if v.PlayerData.job.name == 'ambulance' and v.PlayerData.job.onduty then
			amount = amount + 1
		end
	end
	cb(amount)
end)

-- Commands

QBCore.Commands.Add('911e', Lang:t('info.ems_report'), {{name = 'message', help = Lang:t('info.message_sent')}}, false, function(source, args)
	local src = source
	local message
	if args[1] then message = table.concat(args, " ") else message = Lang:t('info.civ_call') end
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local players = QBCore.Functions.GetQBPlayers()
    for _, v in pairs(players) do
        if v.PlayerData.job.name == 'ambulance' and v.PlayerData.job.onduty then
            TriggerClientEvent('hospital:client:ambulanceAlert', v.PlayerData.source, coords, message)
        end
    end
end)

QBCore.Commands.Add("revive", Lang:t('info.revive_player_a'), {{name = "id", help = Lang:t('info.player_id')}}, false, function(source, args)
	local src = source
	if args[1] then
		local Player = QBCore.Functions.GetPlayer(tonumber(args[1]))
		if Player then
			TriggerClientEvent('hospital:client:Revive', Player.PlayerData.source)
		else
			TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_online'), "error")
		end
	else
		TriggerClientEvent('hospital:client:Revive', src)
	end
end, "admin")

exports('GetDoctorCount', function() return doctorCount end)