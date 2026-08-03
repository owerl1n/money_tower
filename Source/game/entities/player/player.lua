local pd <const> = playdate
local gfx <const> = playdate.graphics

import "game/entities/player/scorePopup"
import "game/entities/player/promptHint"

class('Player').extends(AnimatedSprite)

playerImageTable = gfx.imagetable.new("images/mage-table-17-17")
assert(playerImageTable, "playerImageTable not found")

local SHOOT_COOLDOWN = 20
local BASE_SPELL_COST = 5

function Player:init(x, y, levelComplete)
    Player.super.init(self, playerImageTable)

    self:addState("idle", 1, 1)
    self:addState("run", 1, 1)
    self:addState("jump", 1, 1)
    self:addState("dash", 1, 1)
    self:addState("death", 2, 2, {
        tickStep = 1,
        loop     = false,
    })
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

    self.coyoteFrames          = 0
    self.coyoteMaxFrames       = 3

    -- Death
    self._deathBounceX         = 0
    self._deathBounceY         = 0
    self._restartTriggered     = false

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

    self.atExit                = false

    self._portalCooldown       = 0

    self._nearbyNPC            = nil
    self.promptHint            = PromptHint(self) 

    self.scorePopup            = ScorePopup(self, self.promptHint)

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

    self.taxMultiplier         = 1

    self._blockIndicator       = nil

    self.levelComplete         = levelComplete
end

function Player:showScorePopup(amount)
    self.scorePopup:addScore(amount)
end

function Player:collisionResponse(other)
    local tag = other:getTag()
    if tag == TAGS.Pickup or tag == TAGS.Hazard or tag == TAGS.Exit then
        return gfx.sprite.kCollisionTypeOverlap
    end
    return gfx.sprite.kCollisionTypeSlide
end

function Player:update()
    if self.y > 140 or self.y < -20 or self.x < -20 or self.x > 220 then
        if not self._restartTriggered then
            self:die()
            self:_triggerRestart()
        end
        return
    end

    if self.dead then
        self:_clearBlockIndicator()
        self:_clearNearbyNPC()
        self:updateDeathBounce()
        return
    end

    if isGamePaused() then
        self:updateAnimation()
        return
    end

    if self._portalCooldown and self._portalCooldown > 0 then
        self._portalCooldown -= 1
    end

    self:updateAnimation()

    if not isGamePaused() then
        self:handleAbilityInput()
        self:_updateBlockIndicator()
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
    return self.jumpBuffer > 0 and (self.touchingGround or self.coyoteFrames > 0)
end

function Player:handleState()
    if self.currentState == "idle" then
        self:applyGravity()
        if self.atExit then
            self.xVelocity = 0
        else
            self:handleGroundInput()
        end
    elseif self.currentState == "run" then
        self:applyGravity()
        if self.atExit then
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

        if not self.atExit then
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
            local tileX = math.floor(self._lastProjectile.x / 16) * 16 + 8
            local tileY = math.floor(self._lastProjectile.y / 16) * 16 + 8

            local occupied = isAreaBlocked(tileX - 8, tileY - 8, 16, 16)

            if not occupied then
                PlacedBlock(tileX, tileY)
                self._lastProjectile:remove()
                self._lastProjectile = nil
                self:_clearBlockIndicator()
                print("[Player] блок размещён")
            else
                print("[Player] клетка занята — блок не поставлен")
            end
        elseif self._shootCooldown <= 0 then
            local cost = BASE_SPELL_COST * self.taxMultiplier
            if TreasureManager.trySpend(cost) then
                local dir            = (self.globalFlip == 1) and -1 or 1
                local p              = Projectile(self.x + dir * 10, self.y, dir)
                self._lastProjectile = p
                self._shootCooldown  = SHOOT_COOLDOWN
                print("[Player] выстрел dir=" .. dir)
            end
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
            local tileX = math.floor(self._lastBounceProjectile.x / 16) * 16 + 8
            local tileY = math.floor(self._lastBounceProjectile.y / 16) * 16 + 8

            local occupied = isAreaBlocked(tileX - 8, tileY - 8, 16, 16)

            if not occupied then
                BounceBlock(tileX, tileY)
                self._lastBounceProjectile:remove()
                self._lastBounceProjectile = nil
                self:_clearBlockIndicator()
            else
                print("[Player] клетка занята — BounceBlock не поставлен")
            end
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

        -- проверяем площадь коллайдера игрока (10x13, с центром чуть смещён)
        local blocked = isAreaBlocked(tx - 5, ty - 6.5, 3, 13, self._anchorMarker)

        if blocked then
            print("[Anchor] телепорт заблокирован — место занято")
            return
        end

        SmokeEffect(self.x, self.y, "anchor")
        self:clearAnchor()
        self:moveTo(tx, ty)
        self.xVelocity = 0
        SmokeEffect(tx, ty, "anchor")
        print("[Anchor] teleport to " .. tx .. "," .. ty)
    else
        self._anchorX = self.x
        self._anchorY = self.y
        self._anchorMarker = AnchorMarker(self.x, self.y)
        SmokeEffect(self.x, self.y, "anchor")
        print("[Anchor] placed at " .. self.x .. "," .. self.y)
    end
end

function Player:handleMovementAndCollisions()
    local wasOnGround = self.touchingGround
    local _, _, collisions, length = self:moveWithCollisions(self.x + self.xVelocity, self.y + self.yVelocity)

    if Game.instance and Game.instance.level then
        self.taxMultiplier = Game.instance.level:getTaxMultiplierAt(self.x, self.y)
    end

    self.touchingGround = false
    self.touchingCeiling = false
    self.touchingWall = false
    local died = false
    local touchedExit = false
    local touchedNPC = nil

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
            if not self.atExit then
                died = true
            end
        elseif collisionTag == TAGS.CrumblingBlock then
            if collision.normal.y == -1 then
                self.touchingGround = true -- ← добавь это
                self.doubleJumpAvailable = true
                self.dashAvailable = true
                collisionObject:onPlayerLanded()
            elseif collision.normal.y == 1 then
                self.touchingCeiling = true
                self.jumpHoldFrames = 0
            end
            if collision.normal.x ~= 0 then
                self.touchingWall = true
            end
        elseif collisionTag == TAGS.Pickup then
            collisionObject:collect()
        elseif collisionTag == TAGS.Portal then
            collisionObject:teleport(self)
        elseif collisionTag == TAGS.NPC then
            touchedNPC = collisionObject
        elseif collisionTag == TAGS.Exit then
            touchedExit = true
            self._lastExitX = collisionObject.x + 8
            self._lastExitY = collisionObject.y
        elseif collisionTag == TAGS.BounceBlock then
            if collision.normal.y == -1 then
                local targetY            = self._peakY or (self.y - 20) --TODO строка (self.y - x) где x - коэф который можно редактировать
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

    if self.touchingGround then
        self.coyoteFrames = self.coyoteMaxFrames
    else
        if self.coyoteFrames > 0 then
            self.coyoteFrames -= 1
        end
    end

    if touchedNPC then
        self._nearbyNPC = touchedNPC
        self.promptHint:show()
    else
        self:_clearNearbyNPC()
    end

    if self.xVelocity < 0 then
        self.globalFlip = 1
    elseif self.xVelocity > 0 then
        self.globalFlip = 0
    end

    if died then
        self:die()
    elseif touchedExit and not self.atExit then
        self:onExitTouch()
    end
end

function Player:onExitTouch()
    self.atExit = true
    self.xVelocity = 0
    if self.levelComplete then
        local px = self._lastExitX or self.x
        local py = self._lastExitY or self.y
        self.levelComplete:trigger()
    end
end

function Player:die()
    if self.dead then return end

    self._restartTriggered = false
    self.dead = true
    self.atExit = false

    -- случайный отскок: X влево или вправо, Y всегда вверх
    local bounceX = (math.random(0, 1) == 0 and -1 or 1) * (1.5 + math.random() * 2.0)
    local bounceY = -(2.5 + math.random() * 2.0)
    self._deathBounceX = bounceX
    self._deathBounceY = bounceY

    self:changeState("death")   -- ← вместо setImage

    -- отключаем коллизии
    self:setCollisionsEnabled(false)

    pd.timer.performAfterDelay(800, function()
        self:setCollisionsEnabled(true)
        self.dead = false
        self._deathBounceX = 0
        self._deathBounceY = 0
        -- возвращаем анимацию
        self:playAnimation()
    end)
end

function Player:handleGroundInput()
    if self:playerJumped() then
        self:changeToJumpState()
    elseif pd.buttonJustPressed(pd.kButtonA) and self.dashAvailable and self.dashAbility then
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
    self.coyoteFrames = 0
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

function Player:updateDeathBounce()
    -- гравитация применяется и во время смерти
    self._deathBounceY += self.gravity
    self:moveBy(self._deathBounceX, self._deathBounceY)
    -- горизонтальное затухание
    self._deathBounceX *= 0.92
end

function Player:_triggerRestart()
    if self._restartTriggered then return end
    self._restartTriggered = true

    if self.levelComplete and self.levelComplete._onRestart then
        self.levelComplete._onRestart()
    end
end

function Player:_updateBlockIndicator()
    local projectile = self._lastProjectile or self._lastBounceProjectile

    if projectile and projectile.x then
        local tileX = math.floor(projectile.x / 16) * 16 + 8
        local tileY = math.floor(projectile.y / 16) * 16 + 8

        if not self._blockIndicator then
            self._blockIndicator = BlockIndicator(tileX, tileY)
        else
            self._blockIndicator:moveTo(tileX, tileY)
        end

        local occupied = isAreaBlocked(tileX - 8, tileY - 8, 16, 16)
        self._blockIndicator:setBlocked(occupied)
    else
        self:_clearBlockIndicator()
    end
end

function Player:_clearBlockIndicator()
    if self._blockIndicator then
        self._blockIndicator:remove()
        self._blockIndicator = nil
    end
end

function Player:_clearNearbyNPC()
    if self._nearbyNPC then
        self._nearbyNPC = nil
        self.promptHint:hide()
    end
end

function Player:collisionResponse(other)
    local tag = other:getTag()
    if tag == TAGS.Pickup or tag == TAGS.Hazard or tag == TAGS.Exit
        or tag == TAGS.Projectile or tag == TAGS.AnchorMark or tag == TAGS.Portal
        or tag == TAGS.NPC then
        return gfx.sprite.kCollisionTypeOverlap
    end
    return gfx.sprite.kCollisionTypeSlide
end