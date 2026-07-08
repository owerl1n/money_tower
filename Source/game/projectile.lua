local pd  <const> = playdate
local gfx <const> = playdate.graphics

import "libs/AnimatedSprite"

class('Projectile').extends(AnimatedSprite)

local imagetable = nil

local SPEED       = 4
local TILE_SIZE   = 16


imagetable = gfx.imagetable.new("images/projectile-table-16-16")
assert(imagetable, "Projectile: не удалось загрузить projectile-table-16-16")



function Projectile:init(x, y, direction)

    Projectile.super.init(self, imagetable)

    self:addState("fly", 1, 4, {
        tickStep = 3,
        loop     = true,
    })
    self:playAnimation()

    self.direction = direction  -- -1 влево, 1 вправо
    self.globalFlip = direction == -1 and 1 or 0

    self._portalCooldown = 0   -- ← добавить

    self:setCenter(0.5, 0.5)
    self:moveTo(x, y)
    self:setZIndex(Z_INDEXES.Player - 1)
    self:setCollideRect(6, 5, 3, 5)
    self:setTag(TAGS.Projectile)
end

function Projectile:update()
    if Game.instance and Game.instance.spellbook:isActive() then
        return
    end

    if self._portalCooldown > 0 then      -- ← добавить
        self._portalCooldown -= 1
    end

    self:updateAnimation()

    local newX = self.x + self.direction * SPEED
    local _, _, collisions, len = self:moveWithCollisions(newX, self.y)

    for i = 1, len do
        local col = collisions[i]
        local tag = col.other:getTag()

        if tag == TAGS.Portal then                 -- ← добавить
            col.other:teleport(self)
            return
        end

        if col.type == gfx.sprite.kCollisionTypeSlide then
            SmokeEffect(self.x, self.y, "projectile")
            self.destroyed = true
            self:remove()
            return
        end
    end

    if self.x < -TILE_SIZE or self.x > 200 + TILE_SIZE then
        self.destroyed = true
        self:remove()
    end
end

function Projectile:collisionResponse(other)
    local tag = other:getTag()
    if tag == TAGS.Player or tag == TAGS.Exit or tag == TAGS.AnchorMark
        or tag == TAGS.Portal then       -- ← добавить
        return gfx.sprite.kCollisionTypeOverlap
    end
    return gfx.sprite.kCollisionTypeSlide
end