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
    SetFloat('savegame.mod.airstrikeDelay', 0.1)
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

function drawbuttons()
    UiColor(1,1,1,1)
    drawBoolButton("Automatically start strike at start of level", 'savegame.mod.airstrikeDisableAtMapStart')

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
        UiColor(1,0.5,0.2)
        UiFont("bold.ttf", 30)
        drawbutton("Reset Options", defaultValues)
        UiFont("bold.ttf", 20)
        UiTranslate(0,30)
        drawbuttons()
        drawSlider("Range of missile attack", "savegame.mod.airstrikeRange", "x", 100, 400,250 )
        drawSlider("Start height", "savegame.mod.airstrikeHeight", "x", 0, 600, 300 )
        drawSliderFloat("Delay", "savegame.mod.airstrikeDelay", "x", 0, 500, 10)
        --drawSlider("Maximum travel distance (before despawn)", "savegame.mod.airstrikeMaxDistance", "x", 100, GetInt('savegame.mod.airstrikeHeight') * 2, 250 )
    UiPop()
end
if not (GetBool('savegame.mod.airstrikeDefaultSetup')) then
    defaultValues()
    SetBool('savegame.mod.airstrikeDefaultSetup', true)
end
function draw()
    drawDebugMenu()

end