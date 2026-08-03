local pd  <const> = playdate
local gfx <const> = pd.graphics

class('Spike').extends(gfx.sprite)

local tileset = gfx.imagetable.new("level/tileset-table-16-16")
assert(tileset, "Spike: не удалось загрузить tileset")

local CONFIGS = {
    Small  = { frame = 444,  collider = { x=2, y=10, w=12, h=6  } },
    Medium = { frame = 530,  collider = { x=1, y=6,  w=14, h=10 } },
    Large  = { frame = 2212, collider = { x=0, y=2,  w=16, h=14 } },
}

-- угол поворота для каждого направления (Up = 0, стандартное положение)
local ROTATION = {
    Up    = 0,
    Right = 90,
    Down  = 180,
    Left  = 270,
}

-- поворачивает прямоугольник коллайдера вокруг центра тайла 16x16
local function rotateCollider(c, angle)
    if angle == 0 then
        return c.x, c.y, c.w, c.h
    elseif angle == 180 then
        return 16 - c.x - c.w, 16 - c.y - c.h, c.w, c.h
    elseif angle == 90 then
        -- поворот по часовой: (x,y,w,h) -> новые координаты
        return 16 - c.y - c.h, c.x, c.h, c.w
    elseif angle == 270 then
        return c.y, 16 - c.x - c.w, c.h, c.w
    end
    return c.x, c.y, c.w, c.h
end

function Spike:init(x, y, entity)
    Spike.super.init(self)

    local size   = entity.fields.Size or "Medium"
    local config = CONFIGS[size] or CONFIGS.Medium

    local direction = (entity.fields.Direction) or "Up"
    local angle     = ROTATION[direction] or 0

    local baseImage = tileset[config.frame]
    local image     = angle == 0 and baseImage or baseImage:rotatedImage(angle)

    self:setImage(image)
    self:setCenter(0, 0)
    self:moveTo(x, y)
    self:setZIndex(Z_INDEXES.Hazard)

    local cx, cy, cw, ch = rotateCollider(config.collider, angle)
    self:setCollideRect(cx, cy, cw, ch)

    self:setTag(TAGS.Hazard)
    self:add()
end