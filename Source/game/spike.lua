local pd <const> = playdate
local gfx <const> = pd.graphics

class('Spike').extends(gfx.sprite)

-- тот же tileset что в placedBlock.lua
local tileset = gfx.imagetable.new("level/tileset-table-16-16")
assert(tileset, "Spike: не удалось загрузить tileset")

local CONFIGS = {
    Small  = { frame = 444, collider = { x=2, y=10, w=12, h=6  } },
    Medium = { frame = 530, collider = { x=1, y=6,  w=14, h=10 } },
    Large  = { frame = 2212, collider = { x=0, y=2,  w=16, h=14 } },
}

function Spike:init(x, y, entity)
    Spike.super.init(self)

    local size = entity.fields.size
    local config = CONFIGS[size]

    self:setImage(tileset[config.frame])
    self:setCenter(0, 0)
    self:moveTo(x, y)
    self:setZIndex(Z_INDEXES.Hazard)
    self:setCollideRect(
        config.collider.x,
        config.collider.y,
        config.collider.w,
        config.collider.h
    )
    self:setTag(TAGS.Hazard)
    self:add()
end