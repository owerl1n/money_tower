local pd  <const> = playdate
local gfx <const> = playdate.graphics

import "libs/AnimatedSprite"

-- game/flyingEnemy.lua
-- Летающий враг (глаз). Патрулирует влево-вправо на фиксированной высоте.
-- Разворачивается при столкновении с твёрдым (стены, блоки).
-- Проходит сквозь порталы (телепортируется), подбирает монеты/сокровища
-- и активирует CrumblingBlock при касании.

class('FlyingEnemy').extends(AnimatedSprite)

local imagetable = gfx.imagetable.new("images/eye-table-16-16")
assert(imagetable, "FlyingEnemy: не удалось загрузить images/eye-table-16-16")

local DEFAULT_SPEED = 1.5
local TELEPORT_COOLDOWN = 35 -- кадров игнорировать порталы после телепорта

function FlyingEnemy:init(x, y, entity)
    FlyingEnemy.super.init(self, imagetable)

    self:addState("fly", 1, 1, {
        loop = true,
    })

    -- Направление старта можно задать в LDtk полем entity.fields.Direction = "left"/"right"
    self._direction = 1
    if entity and entity.fields and entity.fields.Direction then
        if string.lower(entity.fields.Direction) == "left" then
            self._direction = -1
        end
    end

    -- Скорость можно задать в LDtk полем entity.fields.Speed (Float),
    -- чтобы у разных врагов была разная скорость
    self._speed = DEFAULT_SPEED
    if entity and entity.fields and entity.fields.Speed then
        self._speed = entity.fields.Speed
    end

    self:setCenter(0.5, 0.5)
    self:moveTo(x, y)
    self:setZIndex(Z_INDEXES.Hazard + 10)
    self:setCollideRect(2, 2, 12, 12)
    self:setTag(TAGS.Hazard)
    self:add()

    self._portalCooldown = 0

    self:changeState("fly")
    self:playAnimation()

    print("[FlyingEnemy] spawned x=" .. x .. " y=" .. y)
end

function FlyingEnemy:update()
    if Game.instance and Game.instance.spellbook:isActive() then
        return
    end

    if self._portalCooldown > 0 then
        self._portalCooldown -= 1
    end

    self:updateAnimation()

    local newX = self.x + self._direction * self._speed
    local _, _, collisions, len = self:moveWithCollisions(newX, self.y)

    for i = 1, len do
        local col   = collisions[i]
        local other = col.other
        local tag   = other.getTag and other:getTag()

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
            if other.onPlayerLanded then
                other:onPlayerLanded()
            end
        end

        -- Разворачиваемся только от по-настоящему твёрдого (стены, блоки).
        -- От игрока/пикапов/порталов враг НЕ отскакивает — иначе он "убегает"
        -- от игрока в тот же кадр, и игрок иногда не успевает зафиксировать
        -- собственное столкновение (из-за чего смерть срабатывала не всегда).
        if col.type == gfx.sprite.kCollisionTypeSlide then
            self._direction = -self._direction
        end
    end
end

function FlyingEnemy:collisionResponse(other)
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