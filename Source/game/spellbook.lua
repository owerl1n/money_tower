local pd  <const> = playdate
local gfx <const> = playdate.graphics
local ease <const> = pd.easingFunctions

import "libs/AnimatedSprite"

class('SpellBook').extends(AnimatedSprite)

local BOOK_W       = 107
local TARGET_X     = 100
local TARGET_Y     = 50
local OFFSCREEN_X  = 200 + BOOK_W / 2

local SLIDE_IN_MS  = 350
local SLIDE_OUT_MS = 250

-- Позиции иконок внутри книги (относительно центра книги)
local ICON_OFFSET_Y_TOP    = -28   -- верхняя иконка
local ICON_OFFSET_Y_BOTTOM =  20   -- нижняя иконка
local ICON_SCALE           = 1.0   -- масштаб (если хочешь нарисуй x2 сам и убери scale)

local CRANK_THRESHOLD = 90  -- градусов для переключения

imagetable = gfx.imagetable.new("images/book-table-107-97")
assert(imagetable, "SpellBook: не удалось загрузить images/book-table-107-97")
-- ── SpellBook ─────────────────────────────────────────────────────────────────

function SpellBook:init(levelComplete, onSpellSelected)


    SpellBook.super.init(self, imagetable)

    self._levelComplete = levelComplete

    self:addState("opening", 1, 9, {
        tickStep = 4,
        loop = false,
        onAnimationEndEvent = function(sprite)
            sprite:changeState("open")
        end
    })

    self:addState("open", 10, 10, {})

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

    self._bookState  = "closed"
    self._slideTimer = nil

    -- Глифы: загружаем imagetable иконок
    self._glyphs = gfx.imagetable.new("images/glyphs-table-16-16")
    assert(self._glyphs, "SpellBook: не удалось загрузить images/glyphs-table-16-16")

    -- Текущий выбранный слот: 1 (верх) или 2 (низ)
    self._selectedSlot  = 1
    self._crankAccum    = 0   -- накопленный угол кранка

    self._onSpellSelected = onSpellSelected
end

-- ── Публичный API ─────────────────────────────────────────────────────────────

function SpellBook:isActive()
    return self._bookState ~= "closed"
end

function SpellBook:onButtonB()
    if self._bookState == "closed" then
        if self._levelComplete and self._levelComplete:isActive() then return end
        self:_open()
    elseif self._bookState == "sliding_in" or self._bookState == "open" then
        self:_close()
    end
end

function SpellBook:onButtonA()
    if self._bookState == "sliding_in" or self._bookState == "open" then
        self:_close()
    end
end

-- Вызывать из Game:handleCrank()
function SpellBook:onCrank(change)
    if self._bookState ~= "open" then return end

    self._crankAccum += change
    

    if self._crankAccum >= CRANK_THRESHOLD then
        self._crankAccum = 0
        self:_selectSlot(2)
    elseif self._crankAccum <= -CRANK_THRESHOLD then
        self._crankAccum = 0
        self:_selectSlot(1)
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

    -- Рисуем иконки только когда книга на месте
    if self._bookState == "open" then
        self:_drawIcons()
    end
end

-- ── Внутренние: выбор слота ───────────────────────────────────────────────────

function SpellBook:_selectSlot(slot)
    if self._selectedSlot == slot then return end
    self._selectedSlot = slot
    local name = slot == 1 and "TOP" or "BOTTOM"
    print("[SpellBook] выбрано: " .. name .. " (слот " .. slot .. ")")
end

function SpellBook:_drawIcons()
    if not self._glyphs then return end

    local bx = math.floor(self.x)
    local by = math.floor(self.y)

    local icon1 = self._glyphs[1]
    local icon2 = self._glyphs[2]
    if not icon1 or not icon2 then return end

    local iw, ih = icon1:getSize()  -- 16×16

    -- Позиции центров иконок
    local topX    = bx + 30
    local topY    = by + ICON_OFFSET_Y_TOP
    local bottomX = bx
    local bottomY = by + ICON_OFFSET_Y_BOTTOM

    -- Рисуем иконки через drawScaled (или drawWithTransform если нужен пиксель-идеал)
    local function drawIconScaled(icon, cx, cy, scale)
        local dw = iw * scale
        local dh = ih * scale
        icon:drawScaled(math.floor(cx - dw / 2), math.floor(cy - dh / 2), scale)
    end
    drawIconScaled(icon1, topX,    topY,    ICON_SCALE)
    drawIconScaled(icon2, bottomX, bottomY, ICON_SCALE)
    --rectangle
    -- Индикатор выбора: маленький прямоугольник слева от активной иконки
    gfx.setColor(gfx.kColorBlack)
    local selY = (self._selectedSlot == 1) and topY or bottomY
    local selX = bx - (iw * ICON_SCALE) / 2 + 36
    gfx.fillRect(math.floor(selX), math.floor(selY - 3), 4, 6)
end

-- ── Внутренние: анимация ──────────────────────────────────────────────────────

function SpellBook:_open()
    self._bookState  = "sliding_in"
    self._crankAccum = 0
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
    -- Сообщаем о выборе перед закрытием
    if self._onSpellSelected then
        self._onSpellSelected(self._selectedSlot)
    end
    self._bookState = "closing"
    self:moveTo(TARGET_X, TARGET_Y)
    self:changeState("closing")
    self:playAnimation()
end

function SpellBook:_startSlideIn()
    if self._slideTimer then self._slideTimer:remove() end

    local startX = OFFSCREEN_X
    local dist   = TARGET_X - startX

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
    local dist   = OFFSCREEN_X - startX

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