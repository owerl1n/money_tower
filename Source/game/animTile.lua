local pd  <const> = playdate
local gfx <const> = playdate.graphics

import "libs/LDtk"

-- game/animTile.lua
class('AnimTile').extends(AnimatedSprite)

local animations = {
    portal = { firstFrame = 1, lastFrame = 6, speed = 4 },
}

local imagetable = gfx.imagetable.new("images/portal-table-16-18")
assert(imagetable, "no portal image has been found")


function AnimTile:init(x, y, animName)

    AnimTile.super.init(self, imagetable)

    self:addState("portal", 1, 6, {
        tickStep = 4,
        loop = true
    })

    self:setCenter(0, 0)
    self:moveTo(x, y)
    self:setZIndex(50)

    -- Коллизия — вся плитка 16×18
    self:setCollideRect(0, 0, 16, 18)
    self:setTag(TAGS.Portal)

    self:playAnimation()
end