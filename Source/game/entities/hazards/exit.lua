local pd  <const> = playdate
local gfx <const> = playdate.graphics

import "libs/AnimatedSprite"

-- game/entities/hazards/exit.lua
-- Выход с уровня в виде печатной машинки.
-- Игрок касается — проигрывается анимация "typing", по её окончании
-- (или по скипу кнопкой A) запускается экран финиша уровня (LevelComplete).

class('Exit').extends(AnimatedSprite)

-- поправь путь/имя файла под свой ассет
local typewriterImagetable = gfx.imagetable.new("images/typewriter-table-16-16")
assert(typewriterImagetable, "Exit: не удалось загрузить images/typewriter-table-16-16")

local FRAMES_COUNT = #typewriterImagetable
local TICK_STEP     = 2 -- скорость анимации печати — подстрой под свой спрайт

function Exit:init(x, y, entity)
    Exit.super.init(self, typewriterImagetable)

    self:addState("idle", 1, 1, { loop = true })

    self:addState("typing", 1, FRAMES_COUNT, {
        tickStep     = TICK_STEP,
        loop         = false,
        nextAnimation = "done", -- чтобы не обнулился currentState после конца анимации
        onAnimationEndEvent = function(sprite)
            sprite:_onTypingFinished()
        end,
    })

    self:addState("done", FRAMES_COUNT, FRAMES_COUNT, { loop = true })

    self:setCenter(0, 0)
    self:moveTo(x, y)
    self:setZIndex(Z_INDEXES.Hazard)
    self:setCollideRect(1, 1, 14, 14)
    self:setTag(TAGS.Exit)
    self:add()

    self._onFinished = nil
    self._finished    = false

    self:changeState("idle")
    self:playAnimation()
end

function Exit:update()
    if isGamePaused() then return end
    self:updateAnimation()
end

-- Запускает анимацию печатной машинки при касании игроком.
-- onFinished(wasSkipped) вызывается один раз по завершении (или скипе).
function Exit:playFinishAnimation(onFinished)
    if self._finished then
        if onFinished then onFinished(false) end
        return
    end

    self._onFinished = onFinished

    if self.currentState ~= "typing" then
        self:changeState("typing")
    end
end

-- Мгновенно завершает анимацию печати (по нажатию A игроком)
function Exit:skipFinishAnimation()
    if self._finished then return end
    self._finished = true
    self:changeState("done")

    if self._onFinished then
        self._onFinished(true)
        self._onFinished = nil
    end
end

function Exit:isFinished()
    return self._finished
end

function Exit:_onTypingFinished()
    if self._finished then return end
    self._finished = true

    if self._onFinished then
        self._onFinished(false)
        self._onFinished = nil
    end
    -- смена на состояние "done" произойдёт автоматически через nextAnimation
end