local pd  <const> = playdate
local gfx <const> = playdate.graphics

import "game/assets"

class('PlacedBlock').extends(gfx.sprite)

local blockImage = nil


blockImage = Tileset[861]
assert(blockImage, "PlacedBlock: тайл 861 не найден")


function PlacedBlock:init(x, y)

    PlacedBlock.super.init(self, blockImage)

    self:setCenter(0.5, 0.5)
    self:moveTo(x, y)
    self:setZIndex(Z_INDEXES.PlacedBlock)
    self:setCollideRect(0, 0, 16, 16)
    self:setTag(TAGS.Block)
    self:add()

    SmokeEffect(x, y, "block")

    print("[PlacedBlock] размещён x=" .. x .. " y=" .. y)
end