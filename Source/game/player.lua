local pd <const> = playdate
local gfx <const> = playdate.graphics

import "game/coinPopup"

class('Player').extends(AnimatedSprite)

playerImageTable = gfx.imagetable.new("images/mage-table-16-16")
assert(playerImageTable, "playerImageTable not found")

local SHOOT_COOLDOWN = 20

function Player:init(x, y, levelComplete)
    Player.super.init(self, playerImageTable)

    self:addState("idle", 1, 1)
    self:addState("run", 1, 1)
    self:addState("jump", 1, 1)
    self:addState("dash", 1, 1)
    self:playAnimation()

    self:moveTo(x, y)
    self:setZIndex(Z_INDEXES.Player)
    self:setCollideRect(3, 3, 10, 13)
    self:setTag(TAGS.Player)

    -- Physics
    self.xVelocity             = 0
    self.yVelocity             = 0
    self.gravity               = 0.85
    self.maxSpeed              = 2
    self.jumpVelocity          = -4.5
    self.drag                  = 0.1
    self.minimumAirSpeed       = 0.5

    -- jump
    self.jumpBufferAmount      = 5
    self.jumpBuffer            = 0
    self.jumpHoldForce         = -0.4
    self.jumpHoldMaxFrames     = 8
    self.jumpHoldFrames        = 0
    self.jumpMinCutoffSpeed    = -1.4

    -- Abilities
    self.doubleJumpAbility     = false
    self.dashAbility           = false

    -- Double Jump
    self.doubleJumpAvailable   = true

    -- Dash
    self.dashAvailable         = true
    self.dashSpeed             = 8
    self.dashMinimumSpeed      = 3
    self.dashDrag              = 0.8

    -- State
    self.touchingGround        = false
    self.touchingCeiling       = false
    self.touchingWall          = false
    self.dead                  = false

    self.atPortal              = false

    self.coinPopup             = CoinPopup(self)

    -- Spell: projectile
    self.projectileAbility     = false
    self._shootCooldown        = 0

    self._lastProjectile       = nil

    -- Spell: anchor
    self.anchorAbility         = false
    self._anchorX              = nil
    self._anchorY              = nil
    self._anchorMarker         = nil

    -- BounceBlock
    self._fallFromY            = nil
    self._peakY                = nil
    self.bounceBlockAbility    = false
    self._lastBounceProjectile = nil
    self._bounceShootCooldown  = 0

    self.levelComplete         = levelComplete
end

function Player:showCoinPopup(amount)
    self.coinPopup:addCoins(amount)
end

function Player:collisionResponse(other)
    local tag = other:getTag()
    if tag == TAGS.Pickup or tag == TAGS.Hazard or tag == TAGS.Portal then
        return gfx.sprite.kCollisionTypeOverlap
    end
    return gfx.sprite.kCollisionTypeSlide
end

function Player:update()
    if self.dead then return end
    if Game.instance and Game.instance.spellbook:isActive() then
        self:updateAnimation()
        return
    end

    self:updateAnimation()

    if not (Game.instance and Game.instance.spellbook:isActive()) then
        self:handleAbilityInput()
    end

    self:updateJumpBuffer()
    self:handleState()
    self:handleMovementAndCollisions()
end

function Player:updateJumpBuffer()
    self.jumpBuffer -= 1
    if self.jumpBuffer <= 0 then self.jumpBuffer = 0 end
    if pd.buttonJustPressed(pd.kButtonA) then
        self.jumpBuffer = self.jumpBufferAmount
    end
end

function Player:playerJumped()
    return self.jumpBuffer > 0
end

function Player:handleState()
    if self.currentState == "idle" then
        self:applyGravity()
        if self.atPortal then
            self.xVelocity = 0
        else
            self:handleGroundInput()
        end
    elseif self.currentState == "run" then
        self:applyGravity()
        if self.atPortal then
            self:changeToIdleState()
        else
            self:handleGroundInput()
        end
    elseif self.currentState == "jump" then
        if self.touchingGround then self:changeToIdleState() end
        if self._peakY == nil or self.y < self._peakY then
            self._peakY = self.y
        end
        self:applyGravity()
        self:applyDrag(self.drag)

        -- Variable jump height
        if self.jumpHoldFrames > 0 then
            if pd.buttonIsPressed(pd.kButtonA) then
                self.yVelocity += self.jumpHoldForce
                self.jumpHoldFrames -= 1
            else
                self.jumpHoldFrames = 0
                if self.yVelocity < self.jumpMinCutoffSpeed then
                    self.yVelocity = self.jumpMinCutoffSpeed
                end
            end
        end

        if not self.atPortal then
            self:handleAirInput()
        end
    elseif self.currentState == "dash" then
        self:applyDrag(self.dashDrag)
        if math.abs(self.xVelocity) <= self.dashMinimumSpeed then
            self:changeToFallState()
        end
    end
end

function Player:handleAbilityInput()
    self:handleAnchorInput()

    if self._shootCooldown > 0 then
        self._shootCooldown -= 1
    end

    if self.projectileAbility and pd.buttonJustPressed(pd.kButtonDown) then
        if self._lastProjectile and self._lastProjectile.x then
            local overAnchor = self._anchorMarker and
                math.abs(self._lastProjectile.x - self._anchorMarker.x) < 10 and
                math.abs(self._lastProjectile.y - self._anchorMarker.y) < 10

            if not overAnchor then
                PlacedBlock(
                    math.floor(self._lastProjectile.x / 16) * 16 + 8,
                    math.floor(self._lastProjectile.y / 16) * 16 + 8
                )
                self._lastProjectile:remove()
                self._lastProjectile = nil
                print("[Player] блок размещён")
            else
                print("[Player] блок заблокирован — снаряд над меткой якоря")
            end
        elseif self._shootCooldown <= 0 then
            local dir            = (self.globalFlip == 1) and -1 or 1
            local p              = Projectile(self.x + dir * 10, self.y, dir)
            self._lastProjectile = p
            self._shootCooldown  = SHOOT_COOLDOWN
            print("[Player] выстрел dir=" .. dir)
        end
    end

    if self._lastProjectile and self._lastProjectile.destroyed then
        self._lastProjectile = nil
    end

    if self._bounceShootCooldown > 0 then
        self._bounceShootCooldown -= 1
    end

    if self.bounceBlockAbility and pd.buttonJustPressed(pd.kButtonDown) then
        if self._lastBounceProjectile and self._lastBounceProjectile.x then
            BounceBlock(
                math.floor(self._lastBounceProjectile.x / 16) * 16 + 8,
                math.floor(self._lastBounceProjectile.y / 16) * 16 + 8
            )
            self._lastBounceProjectile:remove()
            self._lastBounceProjectile = nil
        elseif self._bounceShootCooldown <= 0 then
            local dir                  = (self.globalFlip == 1) and -1 or 1
            local p                    = Projectile(self.x + dir * 10, self.y, dir)
            self._lastBounceProjectile = p
            self._bounceShootCooldown  = SHOOT_COOLDOWN
        end
    end

    if self._lastBounceProjectile and self._lastBounceProjectile.destroyed then
        self._lastBounceProjectile = nil
    end
end

function Player:clearAnchor()
    self._anchorX = nil
    self._anchorY = nil
    if self._anchorMarker then
        self._anchorMarker:remove()
        self._anchorMarker = nil
    end
end

function Player:handleAnchorInput()
    if not self.anchorAbility then return end
    if not pd.buttonJustPressed(pd.kButtonDown) then return end

    if self._anchorX then
        local tx, ty = self._anchorX, self._anchorY
        -- дым на старой позиции (откуда телепортируемся)
        SmokeEffect(self.x, self.y, "anchor")
        self:clearAnchor()
        self:moveTo(tx, ty)
        self.xVelocity = 0
        -- дым на новой позиции (куда прилетели)
        SmokeEffect(tx, ty, "anchor")
        print("[Anchor] teleport to " .. tx .. "," .. ty)
    else
        self._anchorX = self.x
        self._anchorY = self.y
        self._anchorMarker = AnchorMarker(self.x, self.y)
        -- дым при постановке якоря
        SmokeEffect(self.x, self.y, "anchor")
        print("[Anchor] placed at " .. self.x .. "," .. self.y)
    end
end

function Player:handleMovementAndCollisions()
    local _, _, collisions, length = self:moveWithCollisions(self.x + self.xVelocity, self.y + self.yVelocity)

    self.touchingGround = false
    self.touchingCeiling = false
    self.touchingWall = false
    local died = false
    local touchedPortal = false

    for i = 1, length do
        local collision = collisions[i]
        local collisionType = collision.type
        local collisionObject = collision.other
        local collisionTag = collisionObject:getTag()

        if collisionType == gfx.sprite.kCollisionTypeSlide then
            if collision.normal.y == -1 then
                self.touchingGround = true
                self.doubleJumpAvailable = true
                self.dashAvailable = true
            elseif collision.normal.y == 1 then
                self.touchingCeiling = true
                self.jumpHoldFrames = 0
            end
            if collision.normal.x ~= 0 then
                self.touchingWall = true
            end
        end

        if collisionTag == TAGS.Hazard then
            died = true
        elseif collisionTag == TAGS.Pickup then
            collisionObject:collect()
        elseif collisionTag == TAGS.Portal then
            touchedPortal = true
            self._lastPortalX = collisionObject.x + 8
            self._lastPortalY = collisionObject.y
        elseif collisionTag == TAGS.BounceBlock then
            if collision.normal.y == -1 then
                local targetY            = self._peakY or (self.y - 40)
                self.yVelocity           = BounceBlock.getBounceVelocity(self.gravity, targetY, self.y)
                self.doubleJumpAvailable = false
                self.dashAvailable       = true
                self._peakY              = targetY
                self.touchingGround      = false
                self:changeState("jump")
                print("[BounceBlock] targetY=" .. math.floor(targetY) .. " v=" .. string.format("%.2f", self.yVelocity))
            end
        end
    end

    if self.xVelocity < 0 then
        self.globalFlip = 1
    elseif self.xVelocity > 0 then
        self.globalFlip = 0
    end

    if died then
        self:die()
    elseif touchedPortal and not self.atPortal then
        self:onPortalTouch()
    end
end

function Player:onPortalTouch()
    self.atPortal = true
    self.xVelocity = 0
    if self.levelComplete then
        local px = self._lastPortalX or self.x
        local py = self._lastPortalY or self.y
        self.levelComplete:trigger()
    end
end

function Player:die()
    self.xVelocity = 0
    self.yVelocity = 0
    self.dead = true
    self.atPortal = false
    self:setCollisionsEnabled(false)
    pd.timer.performAfterDelay(200, function()
        self:setCollisionsEnabled(true)
        self.dead = false
    end)
end

function Player:handleGroundInput()
    if self:playerJumped() then
        self:changeToJumpState()
    elseif pd.buttonJustPressed(pd.kButtonB) and self.dashAvailable and self.dashAbility then
        self:changeToDashState()
    elseif pd.buttonIsPressed(pd.kButtonLeft) then
        self:changeToRunState("left")
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        self:changeToRunState("right")
    else
        self:changeToIdleState()
    end
end

function Player:handleAirInput()
    -- Дэш на A в воздухе (только если dashAbility активна и A только что нажата)
    -- jumpBuffer сбрасывается при прыжке, поэтому A без прыжка = дэш
    if pd.buttonJustPressed(pd.kButtonA) and self.dashAvailable and self.dashAbility then
        -- jumpHoldFrames > 0 значит мы только что прыгнули и ещё держим A — не дэшим
        if self.jumpHoldFrames <= 0 then
            self:changeToDashState()
            return
        end
    end

    if self:playerJumped() and self.doubleJumpAvailable and self.doubleJumpAbility then
        self.doubleJumpAvailable = false
        self:changeToJumpState()
    elseif pd.buttonJustPressed(pd.kButtonDown) and self.dashAvailable and self.dashAbility then
        self:changeToDashState()
    elseif pd.buttonIsPressed(pd.kButtonLeft) then
        self.xVelocity = -self.maxSpeed
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        self.xVelocity = self.maxSpeed
    end
end

function Player:changeToIdleState()
    self._peakY = nil
    self.xVelocity = 0
    self:changeState("idle")
end

function Player:changeToRunState(direction)
    self._peakY = nil
    if direction == "left" then
        self.xVelocity = -self.maxSpeed
        self.globalFlip = 1
    elseif direction == "right" then
        self.xVelocity = self.maxSpeed
        self.globalFlip = 0
    end
    self:changeState("run")
end

function Player:changeToJumpState()
    self._peakY = self.y
    self.yVelocity = self.jumpVelocity
    self.jumpBuffer = 0
    self.jumpHoldFrames = self.jumpHoldMaxFrames
    self:changeState("jump")
end

function Player:changeToFallState()
    self:changeState("jump")
end

function Player:changeToDashState()
    self.dashAvailable = false
    self.yVelocity = 0
    if pd.buttonIsPressed(pd.kButtonLeft) then
        self.xVelocity = -self.dashSpeed
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        self.xVelocity = self.dashSpeed
    else
        if self.globalFlip == 1 then
            self.xVelocity = -self.dashSpeed
        else
            self.xVelocity = self.dashSpeed
        end
    end
    self:changeState("dash")
end

function Player:applyGravity()
    self.yVelocity += self.gravity
    if self.touchingGround or self.touchingCeiling then
        self.yVelocity = 0
    end
end

function Player:applyDrag(amount)
    if self.xVelocity > 0 then
        self.xVelocity -= amount
    elseif self.xVelocity < 0 then
        self.xVelocity += amount
    end
    if math.abs(self.xVelocity) < self.minimumAirSpeed or self.touchingWall then
        self.xVelocity = 0
    end
end

function Player:collisionResponse(other)
    local tag = other:getTag()
    if tag == TAGS.Pickup or tag == TAGS.Hazard or tag == TAGS.Portal
        or tag == TAGS.Projectile or tag == TAGS.AnchorMark then
        return gfx.sprite.kCollisionTypeOverlap
    end
    return gfx.sprite.kCollisionTypeSlide
end