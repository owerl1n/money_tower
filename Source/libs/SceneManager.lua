--[[
    SceneManager.lua
    Система сцен для Playdate с поддержкой переходов.

    ИСПОЛЬЗОВАНИЕ:
    ──────────────
    import "libs/SceneManager"

    -- Регистрация сцен
    SceneManager.register("splash",  SplashScene)
    SceneManager.register("game",    GameScene)

    -- Переход (из любого места)
    SceneManager.go("game", { level = 1 })
    SceneManager.go("game", { level = 2 }, SceneManager.transitions.wipeLeft)
    SceneManager.go("credits", nil, SceneManager.transitions.fade)

    -- В pd.update():
    function pd.update()
        SceneManager.update()        -- обновляет сцену + переход
        gfx.sprite.update()
        SceneManager.drawOverlay()   -- рисует draw() сцены + overlay перехода
        pd.timer.updateTimers()
    end

    -- В pd.cranked():
    function pd.cranked(change, acceleratedChange)
        SceneManager.cranked(change, acceleratedChange)
    end

    СТРУКТУРА СЦЕНЫ:
    ────────────────
    MySene = {}

    function MyScene:enter(params)  end   -- после завершения перехода "in"
    function MyScene:exit()         end   -- перед началом перехода "out"
    function MyScene:update()       end   -- логика + ввод каждый кадр
    function MyScene:draw()         end   -- прямое рисование поверх спрайтов
    function MyScene:cranked(c, ac) end   -- (опционально) crank

    ПЕРЕХОДЫ:
    ─────────
    SceneManager.transitions.cut        -- мгновенно (по умолчанию)
    SceneManager.transitions.fade       -- fade to black
    SceneManager.transitions.dither     -- dissolve через dither-паттерны
    SceneManager.transitions.wipeLeft
    SceneManager.transitions.wipeRight
]]

import 'CoreLibs/graphics'
import 'CoreLibs/timer'

local pd  <const> = playdate
local gfx <const> = pd.graphics
local W   <const> = playdate.display.getWidth()/2   -- 200
local H   <const> = playdate.display.getHeight()/2  -- 120

-- ── Вспомогательная: чёрный overlay с dither-прозрачностью ───────────────────

local function drawBlackOverlay(alpha)
    if alpha <= 0 then return end
    if alpha >= 1 then
        gfx.setColor(gfx.kColorClear)
        gfx.fillRect(0, 0, W, H)
        return
    end

    gfx.setDitherPattern(alpha, gfx.image.kDitherTypeBayer8x8)
    gfx.fillRect(0, 0, W, H)
    gfx.setColor(gfx.kColorClear)
end

-- ── Easing ────────────────────────────────────────────────────────────────────

local function easeInOut(t)
    return t < 0.5 and 2 * t * t or 1 - (-2 * t + 2)^2 / 2
end

-- ── Встроенные переходы ───────────────────────────────────────────────────────

local _transitions = {}

_transitions.cut = {
    duration = 0,
    drawOut  = function(p) end,
    drawIn   = function(p) end,
}

_transitions.fade = {
    duration = 700,
    drawOut = function(p) drawBlackOverlay(1 - p) end,
    drawIn  = function(p) drawBlackOverlay(p) end,
}

_transitions.dither = {
    duration = 600,
    drawOut = function(p) drawBlackOverlay(1 - p) end,
    drawIn  = function(p) drawBlackOverlay(p) end,
}

_transitions.wipeLeft = {
    duration = 500,
    drawOut = function(p)
        -- Чёрная полоса наезжает справа, закрывая экран
        local x = W - math.floor(p * W)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(x, 0, W - x, H)
    end,
    drawIn = function(p)
        -- Открываем слева направо
        local w = math.floor(p * W)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(w, 0, W - w, H)
    end,
}

_transitions.wipeRight = {
    duration = 500,
    drawOut = function(p)
        local w = math.floor(p * W)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(0, 0, w, H)
    end,
    drawIn = function(p)
        local x = math.floor((1 - p) * W)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(0, 0, x, H)
    end,
}

-- ── SceneManager ──────────────────────────────────────────────────────────────
-- Глобальная переменная — доступна из любого файла после import

SceneManager = {
    transitions = _transitions,

    _registry    = {},   -- name → scene table/class
    _current     = nil,  -- текущая активная сцена
    _currentName = nil,

    _transitioning   = false,
    _transitionPhase = nil,   -- "out" | "in"
    _transitionDef   = nil,
    _transitionTimer = nil,
    _pendingName     = nil,
    _pendingParams   = nil,
    _overlayDraw     = nil,   -- функция рисования overlay на текущем кадре
}

-- ── Регистрация сцены ─────────────────────────────────────────────────────────

function SceneManager.register(name, scene)
    SceneManager._registry[name] = scene
end

-- ── Переход к сцене ───────────────────────────────────────────────────────────

function SceneManager.go(name, params, transition)
    assert(SceneManager._registry[name],
        "SceneManager: неизвестная сцена '" .. tostring(name) .. "'")

    if SceneManager._transitioning then
        print("SceneManager: переход уже идёт, go('" .. name .. "') проигнорирован")
        return
    end

    local tr = transition or _transitions.cut
    SceneManager._pendingName   = name
    SceneManager._pendingParams = params
    SceneManager._transitionDef = tr

    if tr.duration == 0 then
        -- cut: мгновенная смена
        if SceneManager._current and SceneManager._current.exit then
            SceneManager._current:exit()
        end
        SceneManager._doSwitch()
        -- При cut тоже нужен один кадр черноты чтобы не мелькало
        -- _doSwitch уже поставил overlayDraw = чёрный экран,
        -- но нам нужно убрать его на следующем кадре
        playdate.timer.performAfterDelay(1, function()
            SceneManager._overlayDraw = nil
        end)
        return
    end

    -- Анимированный переход
    SceneManager._transitioning   = true
    SceneManager._transitionPhase = "out"
    
    if SceneManager._current and SceneManager._current.exit then
        SceneManager._current:exit()
    end

    SceneManager._startPhase("out")
end

-- ── Внутренняя: запускает одну фазу перехода ─────────────────────────────────

function SceneManager._startPhase(phase)
    local duration = SceneManager._transitionDef.duration

    local timer = playdate.timer.new(duration)
    SceneManager._transitionTimer = timer

    timer.updateCallback = function(t)
        local progress = easeInOut(t.currentTime / duration)
        if phase == "out" then
            SceneManager._overlayDraw = function()
                SceneManager._transitionDef.drawOut(progress)
            end
        else
            SceneManager._overlayDraw = function()
                SceneManager._transitionDef.drawIn(progress)
            end
        end
    end

    timer.timerEndedCallback = function()
        if phase == "out" then
            -- Держим экран закрытым пока не начнётся фаза "in"
            SceneManager._overlayDraw = function()
                gfx.setColor(gfx.kColorBlack)
                gfx.fillRect(0, 0, W * 2, H * 2)
            end
            SceneManager._doSwitch()
            SceneManager._transitionPhase = "in"
            SceneManager._startPhase("in")
        else
            SceneManager._transitioning   = false
            SceneManager._overlayDraw     = nil
            SceneManager._transitionTimer = nil
        end
    end
end

-- ── Внутренняя: создаёт экземпляр новой сцены и вызывает enter ───────────────

function SceneManager._doSwitch()
    local proto = SceneManager._registry[SceneManager._pendingName]

    local instance
    if proto.new then
        instance = proto:new()
    else
        instance = setmetatable({}, { __index = proto })
    end

    SceneManager._current     = instance
    SceneManager._currentName = SceneManager._pendingName
    SceneManager._pendingName = nil

    -- params сохраняем ДО очистки
    local params = SceneManager._pendingParams
    SceneManager._pendingParams = nil



    if instance.enter then
        instance:enter(params)
    end
end


function SceneManager.flashBlack(duration, onDone)
    local blackImg    = gfx.image.new(W * 2, H * 2, gfx.kColorBlack)
    local blackSprite = gfx.sprite.new(blackImg)
    blackSprite:setCenter(0, 0)
    blackSprite:moveTo(0, 0)
    blackSprite:setZIndex(1000)
    blackSprite:setIgnoresDrawOffset(true)
    blackSprite:add()

    playdate.timer.performAfterDelay(duration or 1, function()
        blackSprite:remove()
        if onDone then onDone() end
    end)

    return blackSprite
end



function SceneManager.update()
    if SceneManager._current and SceneManager._current.update then
        SceneManager._current:update()
    end
end

-- Вызывать после gfx.sprite.update()
function SceneManager.drawOverlay()
    if SceneManager._current and SceneManager._current.draw then
        SceneManager._current:draw()
    end
    if SceneManager._overlayDraw then
        local ox, oy = gfx.getDrawOffset()
        gfx.setDrawOffset(0, 0)
        SceneManager._overlayDraw()
        gfx.setDrawOffset(ox, oy)
    end
end

-- Вызывать в pd.cranked()
function SceneManager.cranked(change, acceleratedChange)
    if SceneManager._current and SceneManager._current.cranked then
        SceneManager._current:cranked(change, acceleratedChange)
    end
end

-- ── Утилиты ───────────────────────────────────────────────────────────────────

function SceneManager.currentName()
    return SceneManager._currentName
end

function SceneManager.isTransitioning()
    return SceneManager._transitioning
end