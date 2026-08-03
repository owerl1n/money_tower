local pd  <const> = playdate
local gfx <const> = playdate.graphics

import "libs/AnimatedSprite"

-- game/entities/effects/smokeEffect.lua
-- Одноразовая анимация дыма. Удаляет себя по окончании.
-- Использование:
--   SmokeEffect(x, y, "block")   -- кадры 1-12, при размещении блока
--   SmokeEffect(x, y, "anchor")  -- кадры 13-18, при якоре

class('SmokeEffect').extends(AnimatedSprite)

smokeImagetable = gfx.imagetable.new("images/smoke-table-48-32")
assert(smokeImagetable, "SmokeEffect: не удалось загрузить images/smoke-table-48-32")


function SmokeEffect:init(x, y, kind)
    SmokeEffect.super.init(self, smokeImagetable)

    -- "block" → кадры 1-12, "anchor" → кадры 13-18
    local firstName, lastFrame
    if kind == "anchor" then
        firstName = "anchor"
        self:addState(firstName, 9, 14, {
            tickStep = 2,
            loop     = false,
            onAnimationEndEvent = function(sprite)
                sprite:remove()
            end,
        })
    elseif kind =="block" then
        firstName = "block"
        self:addState(firstName, 17, 24, {
            tickStep = 2,
            loop     = false,
            onAnimationEndEvent = function(sprite)
                sprite:remove()
            end,
        })
    elseif kind =="projectile" then
        firstName = "projectile"
        self:addState(firstName, 1, 5, {
            tickStep = 2,
            loop     = false,
            onAnimationEndEvent = function(sprite)
                sprite:remove()
            end,
        })
    elseif kind =="lockBlock" then
        firstName = "lockBlock"
        self:addState(firstName, 25, 31, {
            tickStep = 1,
            loop     = false,
            onAnimationEndEvent = function(sprite)
                sprite:remove()
            end,
        })
    end

    self:setCenter(0.5, 0.5)
    self:moveTo(x, y)
    self:setZIndex(Z_INDEXES.Player + 10)  -- поверх игрока
    self:setIgnoresDrawOffset(false)

    self:changeState(firstName)
    self:playAnimation()
end

function SmokeEffect:update()
    if isGamePaused() then
        return
    end
    self:updateAnimation()
end