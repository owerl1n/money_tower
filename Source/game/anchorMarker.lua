local gfx <const> = playdate.graphics

class('AnchorMarker').extends(gfx.sprite)

local glyphs = nil

glyphs = gfx.imagetable.new("images/glyphs-table-16-16")
assert(glyphs, "AnchorMarker: не удалось загрузить glyphs-table-16-16")

function AnchorMarker:init(x, y)
    AnchorMarker.super.init(self, glyphs[4])
    self:setCenter(0.5, 0.5)
    self:moveTo(x, y)
    self:setZIndex(Z_INDEXES.Player - 2)
    self:setCollideRect(0, 0, 16, 16)
    self:setTag(TAGS.AnchorMark)
    self:add()
end