local pd  <const> = playdate
local gfx <const> = playdate.graphics
local ease <const> = pd.easingFunctions

import "libs/AnimatedSprite"

-- game/spellbook.lua
-- Книга заклинаний на базе AnimatedSprite.
--   B         → открыть (если закрыта и уровень не завершён)
--   A или B   → закрыть (если открыта/открывается)
--
-- Imagetable "images/book-table-107-97":
--   кадры 1-9   — анимация открытия
--   кадр  10    — открытая книга (loop)
--   кадры 11-14 — анимация закрытия

class('SpellBook').extends(AnimatedSprite)

local BOOK_W       = 107
local TARGET_X     = 100
local TARGET_Y     = 60
local OFFSCREEN_X  = 200 + BOOK_W / 2   -- за правым краем

local SLIDE_IN_MS  = 350
local SLIDE_OUT_MS = 250

-- ── SpellBook ─────────────────────────────────────────────────────────────────

function SpellBook:init(levelComplete)
    local imagetable = gfx.imagetable.new("images/book-table-107-97")
    assert(imagetable, "SpellBook: не удалось загрузить images/book-table-107-97")

    SpellBook.super.init(self, imagetable)

    -- Ссылка на LevelComplete для блокировки открытия
    self._levelComplete = levelComplete

    self:addState("opening", 1, 9, {
        tickStep = 4,
        loop = false,
        onAnimationEndEvent = function(sprite)
            sprite:changeState("open")
        end
    })

    self:addState("open", 10, 10, {
        --loop = true
    })

    self:addState("closing", 11, 14, {
        tickStep = 4,
        loop = false,
        onAnimationEndEvent = function(sprite)
            sprite:_startSlideOut()
        end
    })

    self:setCenter(0.5, 0.5)
    self:moveTo(OFFSCREEN_X, TARGET_Y)
    self:setZIndex(500)

    -- "closed" | "sliding_in" | "open" | "closing" | "sliding_out"
    self._bookState  = "closed"
    self._slideTimer = nil
end

-- ── Публичный API ─────────────────────────────────────────────────────────────

function SpellBook:isActive()
    return self._bookState ~= "closed"
end

function SpellBook:onButtonB()
    -- Не открываем если уровень завершён
    if self._bookState == "closed" then
        if self._levelComplete and self._levelComplete:isActive() then return end
        self:_open()
    elseif self._bookState == "sliding_in" or self._bookState == "open" then
        -- закрыть; игнорируем если уже закрывается
        self:_close()
    end
end

function SpellBook:onButtonA()
    if self._bookState == "sliding_in" or self._bookState == "open" then
        self:_close()
    end
end

function SpellBook:update()
    self:updateAnimation()
end

function SpellBook:draw()
    if self._bookState == "closed" then return end
    local img = self._image
    if img then
        img:drawCentered(math.floor(self.x), math.floor(self.y))
    end
end

-- ── Внутренние методы ─────────────────────────────────────────────────────────

function SpellBook:_open()
    self._bookState = "sliding_in"
    self:moveTo(OFFSCREEN_X, TARGET_Y)
    self:changeState("opening")
    self:playAnimation()
    self:_startSlideIn()
end

function SpellBook:_close()
    if self._slideTimer then
        self._slideTimer:remove()
        self._slideTimer = nil
    end
    self._bookState = "closing"
    self:moveTo(TARGET_X, TARGET_Y)
    self:changeState("closing")
    self:playAnimation()
end

function SpellBook:_startSlideIn()
    if self._slideTimer then self._slideTimer:remove() end

    local startX = OFFSCREEN_X
    local dist   = TARGET_X - startX   -- отрицательное число (едем влево) dist = -50

    -- easingFunctions.outBack(t, b, c, d): t=время, b=начало, c=дельта, d=длительность
    local timer = pd.timer.new(SLIDE_IN_MS)
    self._slideTimer = timer

    timer.updateCallback = function(t)
        local x = ease.outBack(t.currentTime, startX, dist, SLIDE_IN_MS)
        self:moveTo(x, TARGET_Y)
    end

    timer.timerEndedCallback = function()
        self:moveTo(TARGET_X, TARGET_Y)
        self._bookState  = "open"
        self._slideTimer = nil
    end
end

function SpellBook:_startSlideOut()
    if self._slideTimer then self._slideTimer:remove() end

    self._bookState = "sliding_out"
    local startX = TARGET_X
    local dist   = OFFSCREEN_X - startX --dist = 150

    local timer = pd.timer.new(SLIDE_OUT_MS)
    self._slideTimer = timer

    timer.updateCallback = function(t)
        local x = ease.inCubic(t.currentTime, startX, -dist, SLIDE_OUT_MS)
        self:moveTo(x, TARGET_Y)
    end

    timer.timerEndedCallback = function()
        self:moveTo(OFFSCREEN_X, TARGET_Y)
        self._bookState  = "closed"
        self._slideTimer = nil
    end
end