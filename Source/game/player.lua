local pd <const> = playdate
local gfx <const> = playdate.graphics

import "libs/AnimatedSprite"

class('Player').extends(AnimatedSprite)

function Player:init(x, y)
    local playerImagetable = gfx.imagetable.new("images/mage-table-15-17")

    Player.super.init(self, playerImagetable)

    self:setCenter(0.5, 1)
    self:moveTo(x, y)
    self:setCollideRect(4, 4, 8, 12)
    self:setZIndex(100)
    --self:setGroups({ 1 })
    --self:setCollidesWithGroups({ 2, 3, 4, 5 })  -- добавили группу 5 (interact triggers)

    self:addState("idle", 1, 1)
    self:addState("run", 1, 1, { tickStep = 4, loop = true })
    self:addState("jump", 1, 1)
    self:addState("fall", 1, 1)
    -- Анимация подбирания: 8-й кадр, проигрывается один раз
    self:addState("collect", 1, 1, {
        loop = true,   -- зацикливаем на одном кадре — он никуда не уйдёт сам
        tickStep = 999,  -- фактически не двигается
    })

    self:setDefaultState("idle")
    self:playAnimation()

    -- Физика
    self.vx = 0
    self.vy = 0

    self.gravity = 0.05
    self.jumpForce = -5.5
    self.jumpCutOff = -3.5
    self.speed = 1.75
    self.maxFallSpeed = 10

    -- Состояние
    self.onGround = false
    self.wasOnGround = false
    self.facingRight = true
    self.canRotateLevel = false
    self.standingOnPlatform = nil
    self.jumping = false
    self.collecting = false       -- флаг анимации подбирания
    self.nearInteractive = false  -- флаг для HUD: рядом есть интерактивный объект

    self.jumpBufferTime = 0
    self.jumpBufferMax = 5
    self.coyoteTime = 0
    self.coyoteMax = 5
end

function Player:update()
    if not self.collecting then
        self:handleInput()
    end
    self:handleMovementAndCollisions()
    if not self.collecting then
        self:updateAnimationState()
    end
    print(self.onGround)
    Player.super.update(self)
end

function Player:handleInput()
    local moveInput = 0

    if pd.buttonIsPressed(pd.kButtonLeft) then
        moveInput = -1
        self.facingRight = false
        self.globalFlip = gfx.kImageFlippedX
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        moveInput = 1
        self.facingRight = true
        self.globalFlip = gfx.kImageUnflipped
    end

    self.vx = moveInput * self.speed

    if pd.buttonJustPressed(pd.kButtonA) then
        self.jumpBufferTime = self.jumpBufferMax
        --print(self.jumpBufferTime) 5
        --print(self.jumpBufferMax) 5
    end

    if self.jumpBufferTime > 0 and (self.onGround or self.coyoteTime > 0) then
        self:beginJump()
        self.jumpBufferTime = 0
        self.coyoteTime = 0
    end

    if self.jumping and pd.buttonJustReleased(pd.kButtonA) then
        self:cutJump()
    end

    if self.jumpBufferTime > 0 then
        self.jumpBufferTime -= 1
    end
end

function Player:beginJump()
    self.vy = self.jumpForce
    self.jumping = true
    self.onGround = false
end

function Player:cutJump()
    if self.vy < 0 then
        self.vy = math.max(self.vy, self.jumpCutOff)
    end
    self.jumping = false
end

function Player:collisionResponse(other)
    if other.type == "platform" or other.type == "rotation_trigger" or other.type == "interact_trigger" then
        return gfx.sprite.kCollisionTypeOverlap
    end
    return gfx.sprite.kCollisionTypeSlide
end

function Player:handleMovementAndCollisions()
    self.canRotateLevel = false
    self.nearInteractive = false   -- сбрасываем каждый кадр
    self.wasOnGround = self.onGround

    if not self.onGround then
        self.vy += self.gravity
        if self.vy > self.maxFallSpeed then
            self.vy = self.maxFallSpeed
        end
    end

    -- Горизонтальное движение
    if self.vx ~= 0 then
        local actualX, actualY, collisions, length = self:moveWithCollisions(self.x + self.vx, self.y)

        if length > 0 then
            for i = 1, length do
                local collision = collisions[i]
                local other = collision.other

                if other.type == "rotation_trigger" then
                    self.canRotateLevel = true
                end
                if other.type == "interact_trigger" then
                    self.nearInteractive = true
                end
                if other.type == "solid" then
                    self.vx = 0
                end
            end
        end

        if self.onGround and self.standingOnPlatform then
            if not self:isAbovePlatform(self.standingOnPlatform) then
                self.onGround = false
                self.standingOnPlatform = nil
            end
        end
    end

    -- Вертикальное движение
    if self.vy ~= 0 then
        local oldY = self.y
        local actualX, actualY, collisions, length = self:moveWithCollisions(self.x, self.y + self.vy)

        self.onGround = false

        if length > 0 then
            for i = 1, length do
                local collision = collisions[i]
                local other = collision.other

                if other.type == "rotation_trigger" then
                    self.canRotateLevel = true
                end
                if other.type == "interact_trigger" then
                    self.nearInteractive = true
                end

                if other.type == "Solid" then
                    print("solid")
                    if collision.normal.y == -1 then
                        self.vy = 0
                        self.onGround = true
                        self.standingOnPlatform = other
                    elseif collision.normal.y == 1 then
                        self.vy = 0
                    end

                elseif other.type == "platform" then
                    if self.vy >= 0 and collision.normal.y == -1 then
                        local platformTop = other.y
                        if oldY <= platformTop + 3 then
                            self:moveTo(self.x, platformTop)
                            self.vy = 0
                            self.onGround = true
                            self.standingOnPlatform = other
                        end
                    end
                end
            end
        end

        if self.onGround and self.standingOnPlatform then
            if not self:isAbovePlatform(self.standingOnPlatform) then
                self.onGround = false
                self.standingOnPlatform = nil
            end
        end
    end

    if self.onGround then
        self.jumping = false
    end

    if self.wasOnGround and not self.onGround then
        self.coyoteTime = self.coyoteMax
    end

    if self.coyoteTime > 0 then
        self.coyoteTime -= 1
    end

    -- Overlap-проверка (persist)
    local overlapping = self:overlappingSprites()
    for _, sprite in ipairs(overlapping) do
        if sprite.type == "rotation_trigger" then
            self.canRotateLevel = true
        end
        if sprite.type == "interact_trigger" then
            self.nearInteractive = true
        end
    end

    local screenWidth = 400 / 2 -- display scale = 2, значит игровое поле 200px
    if self.x < 0 then
        self:moveTo(screenWidth, self.y)
    elseif self.x > screenWidth then
        self:moveTo(0, self.y)
    end
end

function Player:updateAnimationState()
    local currentState = self.currentState

    if not self.onGround then
        if self.vy < 0 and currentState ~= "jump" then
            self:changeState("jump")
        elseif self.vy > 0 and currentState ~= "fall" then
            self:changeState("fall")
        end
    else
        if math.abs(self.vx) > 0.1 then
            if currentState ~= "run" then
                self:changeState("run")
            end
        else
            if currentState ~= "idle" then
                self:changeState("idle")
            end
        end
    end
end

function Player:collectCat(onDone)
    self.collecting = true
    self.vx = 0
    self:changeState("collect")
    -- Сразу сообщаем Game — она сама решит когда грузить следующий уровень
    if onDone then onDone() end
end

-- Универсальный метод взаимодействия.
-- Каждый интерактивный объект должен иметь:
--   obj.interactType  -- строка: "pickup", "lever", "button", "item_use" и т.п.
--   obj:onInteract(player)  -- метод который вызовется
--
-- Level.getCurrentSide().interactives — список всех интерактивных объектов стороны.
-- nearInteractive проверяется снаружи (в game.lua) через триггер-зону.
function Player:interact(objects)
    if not objects or #objects == 0 then
        print("interact: no objects")
        return
    end

    print("interact: checking", #objects, "objects")

    for _, obj in ipairs(objects) do
        if obj.collected then
            -- уже собран/использован — пропускаем
        elseif obj.onInteract then
            print("interact: calling onInteract on", obj.interactType or tostring(obj))
            obj:onInteract(self)
        else
            print("interact: object has no onInteract:", tostring(obj))
        end
    end
end

function Player:isAbovePlatform(platform)
    local platformCollide = platform:getCollideRect()

    if math.abs(self.y - platform.y) > 0 then
        return false
    end

    local playerLeft = self.x - 4
    local playerRight = self.x + 4
    local platformLeft = platform.x + platformCollide.x
    local platformRight = platform.x + platformCollide.x + platformCollide.width

    return playerRight > platformLeft and playerLeft < platformRight
end