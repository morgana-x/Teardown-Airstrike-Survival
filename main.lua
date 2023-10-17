
--This script will run on all levels when mod is active.
--Modding documentation: http://teardowngame.com/modding
--API reference: http://teardowngame.com/modding/api.html
#include "tdmp/utilities.lua"
#include "tdmp/player.lua"
#include "tdmp/hooks.lua"
#include "tdmp/json.lua"
#include "tdmp/networking.lua"

#include "config.lua"

active = GetBool('savegame.mod.airstrikeDisableAtMapStart')

next_missle = 0
next_big_missle = 0

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
    if (#missiles > GetInt('savegame.mod.airstrikeMaxMissiles')) then
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

function draw(dt)
    if menuActive then
        if (InputDown('esc')) then
            menuActive = false
        end
        active = drawDebugMenu(true, active)

    end
end


