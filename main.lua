
--This script will run on all levels when mod is active.
--Modding documentation: http://teardowngame.com/modding
--API reference: http://teardowngame.com/modding/api.html
#include "tdmp/utilities.lua"
#include "tdmp/player.lua"
#include "tdmp/hooks.lua"
#include "tdmp/json.lua"
#include "tdmp/networking.lua"

function defaultValues()
    SetBool('savegame.mod.airstrikeDisableAtMapStart', true)
    SetInt('savegame.mod.airstrikeRange', 250)
    SetInt('savegame.mod.airstrikeHeight', 200)
    SetInt('savegame.mod.airstrikeMaxDistance', 300)
    SetFloat('savegame.mod.airstrikeDelay', 0.1)
end

if not (GetBool('savegame.mod.airstrikeDefaultSetup')) then
    defaultValues()
    SetBool('savegame.mod.airstrikeDefaultSetup', true)
end
active = GetBool('savegame.mod.airstrikeDisableAtMapStart')

next_missle = 0
next_big_missle = 0

delay = 0.1
delay_big = 10;
amount = 1

maxMissiles = 20
startHeight = GetInt("savegame.mod.airstrikeHeight")
maxRange = startHeight

strikeRange =  GetInt("savegame.mod.airstrikeRange")

local missiles = {}

function shoot_missile(pos, dir, big)
    local d = {}
    d[0] = pos
    d[1] = dir
    d[3] = 0
    if (big) then
        d[4] = true
    end
    table.insert(missiles, 0, d)
end

function trail(p, b)
    ParticleReset()
    ParticleTile(0)
    ParticleColor(1,0.6,0.3,0.2,0.2,0.2)
    ParticleCollide(0)
    ParticleGravity(0,0.1)
    ParticleDrag(0.8)
    ParticleEmissive(1,0)
    if (b) then
        ParticleRadius(2, 1)
        ParticleEmissive(2,0)
        ParticleColor(1,0.7,0.4,0.2,0.2,0.2)
    end
    SpawnParticle(p,Vec(math.random(-1,1),math.random(-1,1),math.random(-1,1)),1)
end

function init()
    strikeRange = 250 or GetInt("savegame.mod.airstrikeRange")
    if (strikeRange == 0) then
        strikeRange = 300
        SetInt("savegame.mod.airstrikeRange", 300)
    end

    active = GetBool('savegame.mod.airstrikeDisableAtMapStart')

end

if (TDMP_LocalSteamID) then
    TDMP_RegisterEvent("nexp", function(data, sender)
        local unpacked = json.decode(data)
        Explosion(unpacked[1], unpacked[2])
        --DebugPrint("Spawned explosion")
    end) 
    TDMP_RegisterEvent("mspwn", function(data, sender)
        local unpacked = json.decode(data)
        shoot_missile(unpacked[1], unpacked[2], unpacked[3])
       -- DebugPrint("Spawned missile")
    end) 
end
function ezBC(e, d)
    TDMP_ServerStartEvent(e, {
		Receiver = 1,--TDMP.Enums.Receiver.All, -- As a host we don't need to send that event to ourself, otherwise we'd get in loop of restarting map again and again
		Reliable = true,

		DontPack = false, -- We're sending empty string so no need to pack it or do anything with it
		Data = d
	})
end
function NetworkedExplosion(pos, size)
    if not TDMP_LocalSteamID then return end
    if not TDMP_IsServer() then return end
   -- DebugPrint("Spawning explosion")
    local raw = {
        pos, 
        size 
    }
    --local d = "" -- json.encode(raw)
    --TDMP_BroadcastEvent("nExplosion", true, true, d)
    ezBC("nexp", raw)
end
function NetworkedMissile(pos, dir, big)
    if not TDMP_LocalSteamID then return end
    if not TDMP_IsServer() then return end
    if (big == nil) then
        big = false
    end
    --DebugPrint("Spawning missile")
    local raw = { 
        pos, 
        dir,
        big
     }
    --local d = "" --json.encode(raw) --"{" .. "{" + table.concat(pos, ", ") + "}, " .. "{" + table.concat(dir, ", ") + "}, " + tostring(big) + "}"--json.encode(raw)
    --TDMP_BroadcastEvent("mspwn", true, true, d)
    ezBC("mspwn", raw)
end

function missile_tick()
    for _, m in ipairs(missiles) do

        m[0] =  VecAdd(m[0], m[1])

        m[3] = m[3] + VecLength(m[1])

        if (m[3] > GetInt('savegame.mod.airstrikeHeight')) then
            table.remove(missiles,_)
            m = nil

        else

            trail(m[0], m[4])
            PointLight(m[0],1,1,1,2)
            DrawLine(m[0],VecAdd(m[0], VecScale(m[1], (m[4] and -10) or 1)),1,1,1,1)

            local hit, p, n, s = QueryClosestPoint(m[0], 1)

            if hit then
                if (not TDMP_LocalSteamID ) then 
                    Explosion(m[0], (m[4] and 5) or 1)
                else 
                    if ( TDMP_LocalSteamID and TDMP_IsServer()) then
                        NetworkedExplosion(m[0], (m[4] and 5) or 1)
                    end
                end
                table.remove(missiles,_)
                --missiles[_] = nil
                m = nil
            end

        end
    end
end

function airstrike(l,w)
    if TDMP_LocalSteamID and (not TDMP_IsServer()) then
        return
    end
    if not active then return end
    if (#missiles > maxMissiles) then
        return
    end
    airstrike_big(l,w)
    if (GetTime() < next_missle) then
        return;
    end
    next_missle = GetTime() + GetFloat("savegame.mod.airstrikeDelay")
    for i=0, amount do
        local pos = Vec(math.random(-w,w),GetInt("savegame.mod.airstrikeHeight"),math.random(-l,l))
        --Shoot(pos,Vec(0, -1, 0),1)
        if (TDMP_LocalSteamID) then 
            NetworkedMissile(pos, Vec(0, -1, 0), false )
        else
            shoot_missile(pos, Vec(0, -1, 0))
        end
    end

end
function airstrike_big(l,w)
    if not active then return end
    if (GetTime() < next_big_missle) then
        return;
    end
    next_big_missle = GetTime() + delay_big
    local pos = Vec(math.random(-w,w),GetInt("savegame.mod.airstrikeHeight"),math.random(-l,l))
    if (TDMP_LocalSteamID) then
        NetworkedMissile(pos, Vec(0, -1, 0), true)
    else
        shoot_missile(pos, Vec(0, -1, 0), true)
    end

end
function init()
end

menuActive = false

function tick(dt)
    if PauseMenuButton( "Airstrike Options") then
        menuActive = not menuActive
	end
    --[[if PauseMenuButton( "Airstrike Toggle") then
		active = not active;
	end--]]

    airstrike(GetInt("savegame.mod.airstrikeRange"),GetInt("savegame.mod.airstrikeRange"));
    missile_tick();
end


function update(dt)
end
function drawbutton(text,f)

    local sx,sy = UiGetTextSize(text)
    b = UiImageBox('ui/common/box-outline-4.png', sx,-sy/2,2,2) or UiTextButton(text,sx,sy) 

    sy = sy * 0.5

    UiTranslate(sx,-sy)---sy)


    --[[b = b or UiBlankButton(sy,sy)
    UiRect(sy,sy)]]

    UiTranslate(-sx,sy)--,sy)
    UiTranslate(0,24)
    if b then
        f()
    end
end

function drawBoolButton(text, str)
    UiColor(1,0,0,1)
    if (GetBool(str)) then
        UiColor(0,1,0,1)
    end
    drawbutton(text, function()
        SetBool(str, not GetBool(str))
    end)
end

function defaultValues()
    SetBool('savegame.mod.airstrikeDisableAtMapStart', true)
    SetInt('savegame.mod.airstrikeRange', 250)
    SetInt('savegame.mod.airstrikeHeight', 200)
    SetInt('savegame.mod.airstrikeMaxDistance', 300)
end
local dbgMenuWidth = 620
local dbgMenuHeight = 500
function drawSlider(text, key, axis, min, max, default)
    local sx,sy = UiGetTextSize(text)
    sy = sy * 0.5
    UiTranslate(0,sy)
    UiColor(1,1,1)
    UiText(text)
    UiTranslate(sx,0)
    UiColor(0,1,0)
    UiText(GetInt(key, max / 2))
    UiTranslate(-sx,0)
    UiTranslate(0,sy)
    UiColor(1,1,1)
    UiImageBox('ui/common/box-outline-4.png', (max - min + 20),20,2,2)
    UiTranslate(-min)
    value, done = UiSlider("ui/common/dot.png", axis, GetInt(key) or default, min, max)
    SetInt(key, value)
    UiTranslate(0,sy + 20 + 10)
    UiTranslate(min)
end
function drawSliderFloat(text, key, axis, min, max, default)
    local sx,sy = UiGetTextSize(text)
    sy = sy * 0.5
    UiTranslate(0,sy)
    UiColor(1,1,1)
    UiText(text)
    UiTranslate(sx,0)
    UiColor(0,1,0)
    UiText(GetFloat(key))
    UiTranslate(-sx,0)
    UiTranslate(0,sy)
    UiColor(1,1,1)
    UiImageBox('ui/common/box-outline-4.png', ((max - min) + 20),20,2,2)
    UiTranslate(-min)
    value, done = UiSlider("ui/common/dot.png", axis, (GetFloat(key) or default) * 100, min , max )
    SetFloat(key, value/100)
    UiTranslate(0,sy + 20 + 10)
    UiTranslate(min)
end



function drawDebugMenu()
    --UiEnableInput()
    UiMakeInteractive()
    UiPush()
        UiTranslate(  UiWidth() /2 - dbgMenuWidth/2, UiHeight() /2 - dbgMenuHeight/2)
        UiColor(0.1,0.1,0.1,0.5)
 
        UiRect(dbgMenuWidth,dbgMenuHeight)

        UiColor(1,1,1,1)
        UiFont("bold.ttf", 24)
        UiText('Options')
        UiFont("bold.ttf", 20)
        UiTranslate(0,30)
        UiFont("bold.ttf", 30)
        UiColor(1,0.5,0.2)
        drawbutton("Reset Options", defaultValues)
        if active then
            UiColor(0,1,0)
        else
            UiColor(1,0,0)
        end

        drawbutton("Airstrike Active", function() active = not active end)
        drawBoolButton("Automatically start strike at start of level", 'savegame.mod.airstrikeDisableAtMapStart')
        UiFont("bold.ttf", 20)
        drawSlider("Range of missile attack", "savegame.mod.airstrikeRange", "x", 100, 400,250 )
        drawSlider("Start height", "savegame.mod.airstrikeHeight", "x", 0, 600, 300 )
        drawSliderFloat("Delay", "savegame.mod.airstrikeDelay", "x", 0, 500, 10)
        --drawSlider("Maximum travel distance (before despawn)", "savegame.mod.airstrikeMaxDistance", "x", 100, GetInt('savegame.mod.airstrikeHeight') * 2, 250 )
    UiPop()
end

function draw(dt)
    if menuActive then
        if (InputDown('esc')) then
            menuActive = false
        end
        drawDebugMenu()

    end
end


