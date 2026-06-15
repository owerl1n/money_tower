local pd  <const> = playdate
local gfx <const> = playdate.graphics

import "libs/AnimatedSprite"
import "game/coinManager"

class('Coin').extends(AnimatedSprite)

local coinImagetable = nil

coinImagetable = gfx.imagetable.new("images/coin-table-11-11")
assert(coinImagetable, "Не удалось загрузить images/coin-table-11-11")

function Coin:init(x, y, entity)
    Coin.super.init(self, coinImagetable)

    self:addState("spin", 1, 7, {
        tickStep = 4,
        loop = true
    })

    self:setCenter(0.5, 0.5)
    self:moveTo(x, y)
    self:setCollideRect(2, 2, 7, 7)
    self:setZIndex(Z_INDEXES.Pickup)
    self:setTag(TAGS.Pickup)

    self.collected = false

    self:playAnimation()

    print("[Coin] spawned x=" .. x .. " y=" .. y)
end

function Coin:update()
    if Game.instance and Game.instance.spellbook:isActive() then
        return  -- анимация монеток замирает
    end
    self:updateAnimation()
end

function Coin:collect()
    if self.collected then return end
    self.collected = true

    local amount = 5
    CoinManager.addCoins(amount)

    -- Показываем попап над игроком
    if Game.instance and Game.instance.player then
        Game.instance.player:showCoinPopup(amount)
    end

    self:remove()
end