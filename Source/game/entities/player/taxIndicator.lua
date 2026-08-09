local pd  <const> = playdate
local gfx <const> = playdate.graphics

-- game/entities/player/taxIndicator.lua
-- Показывает "x2" над игроком, пока он стоит в зоне налога
-- (player.taxMultiplier > 1). Учитывает высоту PromptHint,
-- если тот тоже виден, чтобы текст не накладывался на подсказку "A".

class('TaxIndicator').extends()

local OFFSET_Y = 18 -- базовый отступ от игрока, как у PromptHint/ScorePopup

function TaxIndicator:init(player, hint)
    self._player = player
    self._hint   = hint
end

function TaxIndicator:draw()
    local p = self._player
    if not p or p.taxMultiplier <= 1 then return end

    local text = "x" .. p.taxMultiplier

    -- Поднимаем текст выше подсказки "A", если она сейчас видна
    local extraOffset = 0
    if self._hint and self._hint:isVisible() then
        extraOffset = self._hint:getHeight() + 4
    end

    local drawX = p.x
    local drawY = p.y - OFFSET_Y - extraOffset

    local tw, th = gfx.getTextSize(text)

    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned(
        text,
        math.floor(drawX),
        math.floor(drawY - th / 2),
        kTextAlignment.center
    )
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end