QBCore = exports['qb-core']:GetCoreObject()

local getOutDict = 'switch@franklin@bed'
local getOutAnim = 'sleep_getup_rubeyes'
local canLeaveBed = true
local bedOccupying = nil
local bedObject = nil
local bedOccupyingData = nil
local closestBed = nil
local doctorCount = 0
local CurrentDamageList = {}
local cam = nil
local playerArmor = nil
inBedDict = "anim@gangops@morgue@table@"
inBedAnim = "body_search"
isInHospitalBed = false
isBleeding = 0
bleedTickTimer, advanceBleedTimer = 0, 0
fadeOutTimer, blackoutTimer = 0, 0
legCount = 0
armcount = 0
headCount = 0
playerHealth = nil
isDead = false
isStatusChecking = false
statusChecks = {}
statusCheckTime = 0
healAnimDict = "mini@cpr@char_a@cpr_str"
healAnim = "cpr_pumpchest"
injured = {}

BodyParts = {
    ['HEAD'] =          { label = Lang:t('body.head'),          causeLimp = false, isDamaged = false, severity = 0 },
    ['NECK'] =          { label = Lang:t('body.neck'),          causeLimp = false, isDamaged = false, severity = 0 },
    ['SPINE'] =         { label = Lang:t('body.spine'),         causeLimp = true, isDamaged = false, severity = 0 },
    ['UPPER_BODY'] =    { label = Lang:t('body.upper_body'),    causeLimp = false, isDamaged = false, severity = 0 },
    ['LOWER_BODY'] =    { label = Lang:t('body.lower_body'),    causeLimp = true, isDamaged = false, severity = 0 },
    ['LARM'] =          { label = Lang:t('body.left_arm'),      causeLimp = false, isDamaged = false, severity = 0 },
    ['LHAND'] =         { label = Lang:t('body.left_hand'),     causeLimp = false, isDamaged = false, severity = 0 },
    ['LFINGER'] =       { label = Lang:t('body.left_fingers'),  causeLimp = false, isDamaged = false, severity = 0 },
    ['LLEG'] =          { label = Lang:t('body.left_leg'),      causeLimp = true, isDamaged = false, severity = 0 },
    ['LFOOT'] =         { label = Lang:t('body.left_foot'),     causeLimp = true, isDamaged = false, severity = 0 },
    ['RARM'] =          { label = Lang:t('body.right_arm'),     causeLimp = false, isDamaged = false, severity = 0 },
    ['RHAND'] =         { label = Lang:t('body.right_hand'),    causeLimp = false, isDamaged = false, severity = 0 },
    ['RFINGER'] =       { label = Lang:t('body.right_fingers'), causeLimp = false, isDamaged = false, severity = 0 },
    ['RLEG'] =          { label = Lang:t('body.right_leg'),     causeLimp = true, isDamaged = false, severity = 0 },
    ['RFOOT'] =         { label = Lang:t('body.right_foot'),    causeLimp = true, isDamaged = false, severity = 0 },
}

-- Functions

local function loadAnimDict(dict)
	while(not HasAnimDictLoaded(dict)) do
		RequestAnimDict(dict)
		Wait(1)
	end
end

RegisterNetEvent('hospital:client:ambulanceAlert', function(coords, text)
    local street1, street2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street1name = GetStreetNameFromHashKey(street1)
    local street2name = GetStreetNameFromHashKey(street2)
    QBCore.Functions.Notify({text = text, caption = street1name.. ' ' ..street2name}, 'ambulance')
    PlaySound(-1, "Lose_1st", "GTAO_FM_Events_Soundset", 0, 0, 1)
    local transG = 250
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    local blip2 = AddBlipForCoord(coords.x, coords.y, coords.z)
    local blipText = Lang:t('info.ems_alert', {text = text})
    SetBlipSprite(blip, 153)
    SetBlipSprite(blip2, 161)
    SetBlipColour(blip, 1)
    SetBlipColour(blip2, 1)
    SetBlipDisplay(blip, 4)
    SetBlipDisplay(blip2, 8)
    SetBlipAlpha(blip, transG)
    SetBlipAlpha(blip2, transG)
    SetBlipScale(blip, 0.8)
    SetBlipScale(blip2, 2.0)
    SetBlipAsShortRange(blip, false)
    SetBlipAsShortRange(blip2, false)
    PulseBlip(blip2)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(blipText)
    EndTextCommandSetBlipName(blip)
    while transG ~= 0 do
        Wait(180 * 4)
        transG = transG - 1
        SetBlipAlpha(blip, transG)
        SetBlipAlpha(blip2, transG)
        if transG == 0 then
            RemoveBlip(blip)
            return
        end
    end
end)




RegisterNetEvent('hospital:client:SetDoctorCount', function(amount)
    doctorCount = amount
end)

-- Threads

CreateThread(function()
    for _, station in pairs(Config.Locations["stations"]) do
        local blip = AddBlipForCoord(station.coords.x, station.coords.y, station.coords.z)
        SetBlipSprite(blip, 61)
        SetBlipAsShortRange(blip, true)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 25)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(station.label)
        EndTextCommandSetBlipName(blip)
    end
end)

RegisterNetEvent('hospital:client:Revive', function()
    local player = PlayerPedId()

    exports["CR-GunshotWound-QBCore"]:CRGSW_DeathReset(player)
    print("Reset all GSW Effects")
    Wait(100)

    if IsEntityDead(player) then
        exports["CR-GunshotWound-QBCore"]:CRGSW_Revive(player)
        print("Revived")
    end

    SetEntityMaxHealth(player, 200)
    SetEntityHealth(player, 200)
    ClearPedBloodDamage(player)
    TriggerServerEvent('hud:server:RelieveStress', 100)
    QBCore.Functions.Notify(Lang:t('info.healthy'))
end)