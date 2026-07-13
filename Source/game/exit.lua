local pd  <const> = playdate
local gfx <const> = playdate.graphics

class('Exit').extends(gfx.sprite)

local exitTileset = gfx.imagetable.new("level/tileset-table-16-16")
assert(exitTileset, "exit: не удалось загрузить tileset")
local img = exitTileset[153]


function Exit:init(x, y, entity)
    Exit.super.init(self, img)

    self:setCenter(0, 0)
    self:moveTo(x, y)
    self:setZIndex(50)
    self:setCollideRect(1, 1, 14, 14)
    self:setTag(TAGS.Exit)
    self:add()
end