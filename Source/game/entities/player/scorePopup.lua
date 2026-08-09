local pd  <const> = playdate
local gfx <const> = playdate.graphics

-- game/entities/player/scorePopup.lua
-- Рисуется напрямую в GameScene:draw(), не спрайт.
-- Поэтому гарантированно поверх всех тайлов и спрайтов.

class('ScorePopup').extends()

local DISPLAY_FRAMES = 60   -- 1 секунда при 60 fps
local OFFSET_Y       = 18   -- пикселей выше центра игрока

function ScorePopup:init(player, hint)
    self._player = player
    self._hint   = hint
    self._timer  = 0
    self._amount = 0
end

function ScorePopup:addScore(amount)
    self._amount += amount
    self._timer   = DISPLAY_FRAMES
end

-- Вызывать каждый кадр из Game:update()
function ScorePopup:update()
    if self._timer > 0 then
        self._timer -= 1
        if self._timer == 0 then
            --self._amount = 0
        end
    end
end

function ScorePopup:draw()
    if self._timer <= 0 then return end
    if self._timer <= 20 and self._timer % 4 < 2 then return end

    local text = tostring(self._amount)
    local p    = self._player

    -- Если сейчас видна подсказка "A" — поднимаем цифры очков выше неё
    local extraOffset = 0
    if self._hint and self._hint:isVisible() then
        extraOffset = self._hint:getHeight() + 4
    end
    if p.taxIndicator and p.taxMultiplier > 1 then
        local _, th = gfx.getTextSize("x" .. p.taxMultiplier)
        extraOffset += th + 4
    end

    local drawX = p.x
    local drawY = p.y - OFFSET_Y - extraOffset

    local tw, th = gfx.getTextSize(text)

    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned(
        text,
        math.floor(drawX),
        math.floor(drawY - th/2),
        kTextAlignment.center
    )
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end