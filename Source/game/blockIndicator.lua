local pd  <const> = playdate
local gfx <const> = playdate.graphics

import "game/assets"

-- game/blockIndicator.lua
-- Показывает крестик (Glyphs[6]) на клетке, где сейчас "висит" снаряд.
-- Если повторно нажать кнопку размещения, блок появится именно здесь.

class('BlockIndicator').extends(gfx.sprite)

function BlockIndicator:init(x, y)
    local glyph = Glyphs[6]
    assert(glyph, "BlockIndicator: не удалось загрузить Glyphs[6]")

    BlockIndicator.super.init(self, glyph)

    self:setCenter(0.5, 0.5)
    self:moveTo(x, y)
    self:setZIndex(Z_INDEXES.Player + 5) -- поверх игрока и снаряда
    self:setCollisionsEnabled(false)
    self:add()
end

-- Меняем отображение, если клетка занята (нельзя поставить блок)
function BlockIndicator:setBlocked(blocked)
    if blocked then
        self:setImageDrawMode(gfx.kDrawModeInverted)
    else
        self:setImageDrawMode(gfx.kDrawModeCopy)
    end
end