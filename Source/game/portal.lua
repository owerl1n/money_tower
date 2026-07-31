local pd  <const> = playdate
local gfx <const> = playdate.graphics

import "libs/AnimatedSprite"

-- game/portal.lua
-- Портал телепортирует игрока к парному порталу.
-- Порталы связываются полем entity.fields.PairId (число) в LDtk —
-- на уровне должно быть ровно 2 портала с одинаковым PairId.

class('Portal').extends(AnimatedSprite)

local portalImagetable = nil
portalImagetable = gfx.imagetable.new("images/portal-table-16-18")
assert(portalImagetable, "Portal: не удалось загрузить images/portal-table-16-18")

local TELEPORT_COOLDOWN = 35 -- кадров игрок игнорирует порталы после телепорта

-- pairId -> список порталов текущего уровня
Portal._registry = {}

function Portal:init(x, y, entity)
    Portal.super.init(self, portalImagetable)

    self:addState("idle", 1, 6, {
        tickStep = 4,
        loop = true,
    })

    self:setCenter(0.5, 0.5)
    self:moveTo(x, y)
    self:setZIndex(Z_INDEXES.Hazard)
    self:setCollideRect(5, 2, 7, 14)
    self:setTag(TAGS.Portal)
    self:add()

    self._pairId  = (entity and entity.fields and entity.fields.PairId) or 0
    self._partner = nil

    if not Portal._registry[self._pairId] then
        Portal._registry[self._pairId] = {}
    end
    table.insert(Portal._registry[self._pairId], self)

    local group = Portal._registry[self._pairId]
    if #group == 2 then
        group[1]._partner = group[2]
        group[2]._partner = group[1]
    elseif #group > 2 then
        print("[Portal] ⚠️ больше двух порталов с PairId=" .. tostring(self._pairId))
    end

    self:changeState("idle")
    self:playAnimation()

    print("[Portal] spawned x=" .. x .. " y=" .. y .. " pairId=" .. tostring(self._pairId))
end

-- Вызывать при загрузке нового уровня (в Level:goToLevel), иначе
-- пары со старого уровня останутся в памяти
function Portal.resetRegistry()
    Portal._registry = {}
end

function Portal:update()
    if isGamePaused() then
        return
    end
    self:updateAnimation()
end

function Portal:teleport(sprite)
    if not self._partner then
        print("[Portal] нет пары для телепорта")
        return
    end
    if sprite._portalCooldown and sprite._portalCooldown > 0 then
        return
    end

    local tx, ty = self._partner.x, self._partner.y

    -- размеры коллайдера зависят от того, кто телепортируется
    local hw, hh = 5, 6.5      -- по умолчанию под игрока (10x13)
    if sprite:getTag() == TAGS.Projectile then
        hw, hh = 1.5, 2.5      -- под снаряд (3x5)
    end

    local blocked = isAreaBlocked(tx - hw, ty - hh, hw * 2, hh * 2, self._partner)

    if blocked then
        print("[Portal] телепорт заблокирован — выход занят")
        return
    end

    SmokeEffect(self.x, self.y, "anchor")
    sprite:moveTo(tx, ty)
    sprite._portalCooldown = TELEPORT_COOLDOWN
    SmokeEffect(tx, ty, "anchor")

    print("[Portal] телепорт " .. self.x .. "," .. self.y .. " -> " .. tx .. "," .. ty)
end

function Portal:collisionResponse(other)
    return gfx.sprite.kCollisionTypeOverlap
end