local pd  <const> = playdate
local gfx <const> = playdate.graphics

import "libs/LDtk"

-- game/animTile.lua
class('AnimTile').extends(AnimatedSprite)

local animations = {
    portal = { firstFrame = 1, lastFrame = 6, speed = 4 },
    --lava  = { firstFrame = 30, lastFrame = 34, speed = 4 },
}

function AnimTile:init(x, y, animName)
    local imagetable = gfx.imagetable.new("images/portal-table-16-18")
    AnimTile.super.init(self, imagetable)
    
    local anim = animations[animName]
    self:addState(animName, 1, 6, {
        tickStep = 4,
        loop = true
    })
    
    self:setCenter(0, 0)
    self:moveTo(x, y)
    self:setZIndex(50)
    self:playAnimation()
end