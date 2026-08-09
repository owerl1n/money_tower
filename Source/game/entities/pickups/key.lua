local pd  <const> = playdate
local gfx <const> = playdate.graphics

import "libs/AnimatedSprite"
import "game/core/assets"
import "game/entities/hazards/bounceBlock"

-- game/entities/pickups/key.lua
-- Подбираемый ключ с анимацией вращения, гравитацией и отскоком от BounceBlock.
-- Падает вниз до твёрдой поверхности, при подборе открывает все KeyBlock на уровне.

class('Key').extends(AnimatedSprite)

local keyTable = gfx.imagetable.new("images/key-table-16-16")
assert(keyTable, "Assets: не удалось загрузить images/key-table-16-16")

local GRAVITY = 0.75

function Key:init(x, y, entity)
    Key.super.init(self, keyTable)

    self:addState("spin", 1, 8, {
        tickStep = 4,
        loop     = true,
    })

    self:setCenter(0.5, 0.5)
    self:moveTo(x, y)
    self:setCollideRect(4, 2, 8, 12)
    self:setZIndex(Z_INDEXES.Pickup)
    self:setTag(TAGS.Pickup)
    self:add()

    self.collected      = false
    self.yVelocity      = 0
    self.touchingGround = false
    self._peakY         = nil  -- верхняя точка падения, нужна для расчёта отскока

    self:playAnimation()

    print("[Key] spawned x=" .. x .. " y=" .. y)
end

function Key:update()
    if self.collected then return end

    if isGamePaused() then
        return
    end
    self:updateAnimation()

    -- Отслеживаем "верхнюю" точку падения (минимальный y), пока не касаемся земли —
    -- нужно, чтобы BounceBlock мог вернуть ключ примерно на ту же высоту
    if not self.touchingGround then
        if self._peakY == nil or self.y < self._peakY then
            self._peakY = self.y
        end
    end

    self.yVelocity += GRAVITY
    if self.touchingGround then
        self.yVelocity = 0
    end

    local _, _, collisions, len = self:moveWithCollisions(self.x, self.y + self.yVelocity)

    self.touchingGround = false

    for i = 1, len do
        local col   = collisions[i]
        local other = col.other
        local tag   = other.getTag and other:getTag()

        if col.type == gfx.sprite.kCollisionTypeSlide and col.normal.y == -1 then
            self.touchingGround = true
            self._peakY = nil
        end

        if tag == TAGS.BounceBlock and col.normal.y == -1 then
            local targetY   = self._peakY or (self.y - 40)
            self.yVelocity  = BounceBlock.getBounceVelocity(GRAVITY, targetY, self.y)
            self._peakY     = targetY
            self.touchingGround = false
        end
    end
end

function Key:collisionResponse(other)
    local tag = other.getTag and other:getTag()
    if other.type == "Solid" or tag == TAGS.Block or tag == TAGS.BounceBlock
        or tag == TAGS.CrumblingBlock or tag == TAGS.KeyBlock then
        return gfx.sprite.kCollisionTypeSlide
    end
    -- игрок, снаряды, хазарды, порталы, другие пикапы — проходим сквозь
    return gfx.sprite.kCollisionTypeOverlap
end

function Key:collect()
    if self.collected then return end
    self.collected = true

    print("[Key] собран, открываем KeyBlock'и")

    KeyBlock.openAll()

    self:remove()
end