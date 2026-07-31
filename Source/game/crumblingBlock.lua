local pd  <const> = playdate
local gfx <const> = playdate.graphics

import "game/assets"
import "libs/AnimatedSprite"


class('CrumblingBlock').extends(AnimatedSprite)

local RESPAWN_DELAY = 0  -- кадров до воскрешения (0 = никогда)

function CrumblingBlock:init(x, y)
    CrumblingBlock.super.init(self, Tileset)

    self:addState("solid", 53, 53, { loop = true })

    self:addState("crumbling", 53, 57, {
        tickStep = 8,
        loop     = false,
        onAnimationEndEvent = function(sprite)
            sprite:_crumble()
        end,
    })

    self:setDefaultState("solid")
    self:setCenter(0, 0)
    self:moveTo(x, y)
    self:setZIndex(Z_INDEXES.Hazard - 1)
    self:setCollideRect(0, 0, 16, 16)
    self:setTag(TAGS.CrumblingBlock)
    self:add()

    self._originX      = x
    self._originY      = y
    self._gone         = false
    self._respawnTimer = 0

    self:changeState("solid")
    self:playAnimation()
end

function CrumblingBlock:onPlayerLanded()
    if self.currentState == "crumbling" or self._gone then return end
    self:changeState("crumbling")
    print("[CrumblingBlock] crumbling at " .. self._originX .. "," .. self._originY)
end

function CrumblingBlock:update()
    if isGamePaused() then return end

    if self._gone then
        if RESPAWN_DELAY > 0 then
            self._respawnTimer += 1
            if self._respawnTimer >= RESPAWN_DELAY then
                self:_respawn()
            end
        end
        return
    end

    self:updateAnimation()


end


function CrumblingBlock:_crumble()
    self._gone         = true
    self._respawnTimer = 0
    self:setCollisionsEnabled(false)
    self:setVisible(false)
    if SmokeEffect then
        SmokeEffect(self._originX + 8, self._originY + 8, "block")
    end
    print("[CrumblingBlock] gone at " .. self._originX .. "," .. self._originY)
end

function CrumblingBlock:_respawn()
    self._gone = false
    self:setVisible(true)
    self:setCollisionsEnabled(true)
    self:changeState("solid")
    self:playAnimation()
    print("[CrumblingBlock] respawned at " .. self._originX .. "," .. self._originY)
end

function CrumblingBlock:collisionResponse(other)
    return gfx.sprite.kCollisionTypeSlide
end