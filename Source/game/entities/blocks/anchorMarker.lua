local gfx <const> = playdate.graphics

import "game/core/assets"

class('AnchorMarker').extends(gfx.sprite)

function AnchorMarker:init(x, y)
    AnchorMarker.super.init(self, Glyphs[4])
    self:setCenter(0.5, 0.5)
    self:moveTo(x, y)
    self:setZIndex(Z_INDEXES.Player - 2)
    self:setCollideRect(2, 2, 10, 10)
    self:setTag(TAGS.AnchorMark)
    self:add()
end