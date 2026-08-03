local pd  <const> = playdate
local gfx <const> = playdate.graphics

import "libs/AnimatedSprite"
import "game/entities/hazards/bounceBlock"

-- game/entities/enemies/debtCollector.lua
-- Обычный (наземный) враг. Патрулирует влево-вправо, подчиняется гравитации,
-- отскакивает от BounceBlock так же, как игрок. Проходит сквозь порталы,
-- "съедает" монеты/сокровища без начисления очков и активирует CrumblingBlock.

class('DebtCollector').extends(AnimatedSprite)

local imagetable = gfx.imagetable.new("images/debt_collector-table-16-16")
assert(imagetable, "DebtCollector: не удалось загрузить images/debt_collector-table-16-16")

local DEFAULT_SPEED = 1
local GRAVITY = 0.85
local TELEPORT_COOLDOWN = 35 -- кадров игнорировать порталы после телепорта

function DebtCollector:init(x, y, entity)
    DebtCollector.super.init(self, imagetable)

    self:addState("walk", 1, 1, {
        loop = true,
    })

    -- Направление старта: entity.fields.Direction = "left"/"right"
    self._direction = 1
    if entity and entity.fields and entity.fields.Direction then
        if string.lower(entity.fields.Direction) == "left" then
            self._direction = -1
        end
    end

    -- Скорость: entity.fields.Speed (Float), у каждого своя
    self._speed = DEFAULT_SPEED
    if entity and entity.fields and entity.fields.Speed then
        self._speed = entity.fields.Speed
    end

    self:setCenter(0.5, 0.5)
    self:moveTo(x, y)
    self:setZIndex(Z_INDEXES.Hazard)
    self:setCollideRect(2, 2, 12, 12)
    self:setTag(TAGS.Hazard)
    self:add()

    self.yVelocity      = 0
    self.touchingGround = false
    self._peakY         = nil -- верхняя точка падения, нужна для расчёта отскока

    self._portalCooldown = 0

    self:changeState("walk")
    self:playAnimation()

    print("[DebtCollector] spawned x=" .. x .. " y=" .. y)
end

function DebtCollector:update()
    if isGamePaused() then
        return
    end

    if self._portalCooldown > 0 then
        self._portalCooldown -= 1
    end

    self:updateAnimation()

    -- Отслеживаем "верхнюю" точку падения (минимальный y), пока не касаемся земли —
    -- нужно, чтобы BounceBlock мог вернуть врага примерно на ту же высоту
    if not self.touchingGround then
        if self._peakY == nil or self.y < self._peakY then
            self._peakY = self.y
        end
    end

    self.yVelocity += GRAVITY
    if self.touchingGround then
        self.yVelocity = 0
    end

    local newX = self.x + self._direction * self._speed
    local newY = self.y + self.yVelocity

    local _, _, collisions, len = self:moveWithCollisions(newX, newY)

    self.touchingGround = false

    for i = 1, len do
        local col   = collisions[i]
        local other = col.other
        local tag   = other.getTag and other:getTag()

        if col.type == gfx.sprite.kCollisionTypeSlide then
            if col.normal.y == -1 then
                self.touchingGround = true
                self._peakY = nil
            end
            if col.normal.x ~= 0 then
                self._direction = -self._direction
            end
        end

        if tag == TAGS.Portal then
            if self._portalCooldown <= 0 then
                other:teleport(self)
                self._portalCooldown = TELEPORT_COOLDOWN
            end
            return
        elseif tag == TAGS.Pickup then
            -- Монетки/сокровища просто исчезают, очки за них НЕ начисляются
            if other.getValue then -- отличаем Treasure от Key по наличию getValue()
                other:destroy()
            end
        elseif tag == TAGS.CrumblingBlock then
            if col.normal.y == -1 then
                self.touchingGround = true
                self._peakY = nil
            end
            if other.onPlayerLanded then
                other:onPlayerLanded()
            end
        elseif tag == TAGS.BounceBlock then
            if col.normal.y == -1 then
                local targetY = self._peakY or (self.y - 20)    --TODO строка (self.y - x) где x - коэф который можно редактировать
                self.yVelocity = BounceBlock.getBounceVelocity(GRAVITY, targetY, self.y)
                self._peakY = targetY
                self.touchingGround = false
            end
        end
    end
end

function DebtCollector:collisionResponse(other)
    if other.type == "Solid" then
        return gfx.sprite.kCollisionTypeSlide
    end

    local tag = other.getTag and other:getTag()
    if tag == TAGS.Block or tag == TAGS.BounceBlock
        or tag == TAGS.CrumblingBlock or tag == TAGS.KeyBlock then
        return gfx.sprite.kCollisionTypeSlide
    end

    -- Игрок, снаряды, монетки, порталы, якорь и т.п. — просто проходим сквозь
    return gfx.sprite.kCollisionTypeOverlap
end