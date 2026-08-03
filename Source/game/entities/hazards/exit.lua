local pd  <const> = playdate
local gfx <const> = playdate.graphics

import "game/core/assets"

class('Exit').extends(gfx.sprite)

local img = Tileset[153]


function Exit:init(x, y, entity)
    Exit.super.init(self, img)

    self:setCenter(0, 0)
    self:moveTo(x, y)
    self:setZIndex(Z_INDEXES.Hazard)
    self:setCollideRect(1, 1, 14, 14)
    self:setTag(TAGS.Exit)
    self:add()
end