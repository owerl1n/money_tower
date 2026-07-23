local gfx <const> = playdate.graphics

import "game/assets"

class('AnchorMarker').extends(gfx.sprite)

function AnchorMarker:init(x, y)
    AnchorMarker.super.init(self, Glyphs[4])
    self:setCenter(0.5, 0.5)
    self:moveTo(x, y)
    self:setZIndex(Z_INDEXES.Player - 2)
    self:setCollideRect(0, 0, 16, 16)
    self:setTag(TAGS.AnchorMark)
    self:add()
end