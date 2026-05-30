local pd  <const> = playdate
local gfx <const> = playdate.graphics

class('PlacedBlock').extends(gfx.sprite)

local blockImage = nil


tileset = gfx.imagetable.new("level/tileset-table-16-16")
assert(tileset, "PlacedBlock: не удалось загрузить tileset-table-16-16")

local function loadImage()
    if blockImage then return end

    -- тайл 861 — один из Solid (индекс в imagetable, 1-based)
    blockImage = tileset[861]
    assert(blockImage, "PlacedBlock: тайл 861 не найден")
end

function PlacedBlock:init(x, y)
    loadImage()
    PlacedBlock.super.init(self, blockImage)

    self:setCenter(0.5, 0.5)
    self:moveTo(x, y)
    self:setZIndex(Z_INDEXES.Hazard - 1)
    self:setCollideRect(0, 0, 16, 16)
    self:setTag(TAGS.Block)
    self:add()

    print("[PlacedBlock] размещён x=" .. x .. " y=" .. y)
end