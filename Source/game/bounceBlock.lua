local pd  <const> = playdate
local gfx <const> = playdate.graphics

class('BounceBlock').extends(gfx.sprite)

local bounceImage = nil

t = gfx.imagetable.new("images/glyphs-table-16-16")
assert(t, "BounceBlock: не удалось загрузить")
bounceImage = t[3]
assert(bounceImage, "BounceBlock: тайл not found")


-- Минимальный и максимальный импульс отскока
local BOUNCE_MIN    = -4.5   -- слабый отскок (упал с малой высоты)
local BOUNCE_MAX    = -10.0  -- сильный отскок (упал с большой высоты)
local HEIGHT_SCALE  = 60     -- пикселей падения для максимального отскока

function BounceBlock:init(x, y)

    BounceBlock.super.init(self, bounceImage)

    self:setCenter(0.5, 0.5)
    self:moveTo(x, y)
    self:setZIndex(Z_INDEXES.Hazard - 1)
    self:setCollideRect(0, 0, 16, 16)
    self:setTag(TAGS.BounceBlock)
    self:add()

    print("[BounceBlock] размещён x=" .. x .. " y=" .. y)
end

-- Вычисляет импульс отскока по высоте падения (в пикселях выше блока)
function BounceBlock.getBounceVelocity(gravity, targetY, currentY)
    local pixelsToRise = currentY - targetY
    if pixelsToRise <= 0 then
        return -math.sqrt(2 * gravity * 4)
    end
    return -math.sqrt(2 * gravity * pixelsToRise)
end