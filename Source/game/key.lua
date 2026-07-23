local pd  <const> = playdate
local gfx <const> = playdate.graphics

import "libs/AnimatedSprite"
import "game/assets"


class('Key').extends(AnimatedSprite)

local keyTable = gfx.imagetable.new("images/key-table-16-16")
assert(keyTable, "Assets: не удалось загрузить images/key-table-16-16")


function Key:init(x, y, entity)
    Key.super.init(self, keyTable)

    self:addState("spin", 1, 8, {
        tickStep = 4,
        loop     = true,
    })

    self:setCenter(0.5, 0.5)
    self:moveTo(x, y)
    self:setCollideRect(2, 2, 12, 12)
    self:setZIndex(Z_INDEXES.Pickup)
    self:setTag(TAGS.Pickup)
    self:add()

    self.collected = false

    self:playAnimation()

    print("[Key] spawned x=" .. x .. " y=" .. y)
end

function Key:update()
    if Game.instance and Game.instance.spellbook:isActive() then
        return
    end
    self:updateAnimation()
end

function Key:collect()
    if self.collected then return end
    self.collected = true

    print("[Key] собран, открываем KeyBlock'и")

    KeyBlock.openAll()

    self:remove()
end