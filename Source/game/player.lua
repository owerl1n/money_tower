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

    self:addState("idle", 1, 1)
    self:setDefaultState("idle")
    self:playAnimation()
    
    -- Физика
    self.vx = 0
    self.vy = 0
    self.gravity = 0.5
    self.jumpForce = -5.5
    self.jumpCutOff = -3.5        -- Минимальная скорость при отпускании кнопки
    self.speed = 2
    self.maxFallSpeed = 6
    self.onGround = false
    self.jumping = false        -- Флаг активного прыжка
end

function Player:update()
    self:handleInput()
    self:applyPhysics()
    self:checkPickups()
    Player.super.update(self)
    --print(self.onGround)
end

function Player:handleInput()
    -- Движение влево/вправо
    if pd.buttonIsPressed(pd.kButtonLeft) then
        self.vx = -self.speed
        self.globalFlip = gfx.kImageFlippedX
        --print("LEFT pressed, vx =", self.vx)  -- ← добавьте
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        self.vx = self.speed
        self.globalFlip = gfx.kImageUnflipped
        --print("RIGHT pressed, vx =", self.vx)
    else
        self.vx = 0
    end

    -- Начало прыжка
    if pd.buttonJustPressed(pd.kButtonA) and self.onGround then
        self.vy = self.jumpForce
        self.onGround = false
        self.jumping = true
    end

    -- Отпустили кнопку A во время прыжка — обрезаем высоту
    if self.jumping and pd.buttonJustReleased(pd.kButtonA) then
        if self.vy < 0 then  -- Только если ещё летим вверх
            self.vy = math.max(self.vy, self.jumpCutOff)
        end
        self.jumping = false
    end
end

function Player:applyPhysics()
    -- Проверяем землю отдельным зондом (+1px вниз)
    local _, _, groundCollisions, groundCount = self:moveWithCollisions(self.x, self.y + 1)
    self.onGround = false
    for i = 1, groundCount do
        if groundCollisions[i].normal.y == -1 then
            self.onGround = true
            break
        end
    end
    -- Возвращаем спрайт обратно если никуда не двигались
    self:moveTo(self.x, self.y)  -- зонд не должен двигать спрайт

    -- Гравитация
    if not self.onGround then
        self.vy += self.gravity
        if self.vy > self.maxFallSpeed then
            self.vy = self.maxFallSpeed
        end
    else
        if self.vy > 0 then self.vy = 0 end
    end

    -- Горизонтальное движение
    if self.vx ~= 0 then
        self:moveWithCollisions(self.x + self.vx, self.y)
    end

    -- Вертикальное движение
    if self.vy ~= 0 then
        local _, _, collisions, length = self:moveWithCollisions(self.x, self.y + self.vy)
        for i = 1, length do
            local col = collisions[i]
            if col.normal.y == -1 and self.vy > 0 then
                self.vy = 0
                self.jumping = false
            elseif col.normal.y == 1 and self.vy < 0 then
                self.vy = 0
                self.jumping = false
            end
        end
    end


    -- Wrap экрана по горизонтали
    -- local screenWidth = 200
    -- if self.x < 0 then
    --     self:moveTo(screenWidth, self.y)
    -- elseif self.x > screenWidth then
    --     self:moveTo(0, self.y)
    -- end
end

function Player:checkPickups()
    local overlaps = self:overlappingSprites()
    for _, sprite in ipairs(overlaps) do
        if sprite.collect then
            sprite:collect()
        end
    end
end

-- function Player:collisionResponse(other)
--     if other.type == "coin" or other.type == "rotation_trigger" or other.type == "interact_trigger" then
--         return gfx.sprite.kCollisionTypeOverlap
--     end
--     return gfx.sprite.kCollisionTypeSlide
-- end