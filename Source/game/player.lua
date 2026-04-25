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
    self.jumpCutOff = -3        -- Минимальная скорость при отпускании кнопки
    self.speed = 2
    self.maxFallSpeed = 6
    self.onGround = false
    self.jumping = false        -- Флаг активного прыжка
end

function Player:update()
    self:handleInput()
    self:applyPhysics()
    Player.super.update(self)
end

function Player:handleInput()
    -- Движение влево/вправо
    if pd.buttonIsPressed(pd.kButtonLeft) then
        self.vx = -self.speed
        self.globalFlip = gfx.kImageFlippedX
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        self.vx = self.speed
        self.globalFlip = gfx.kImageUnflipped
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
    -- Гравитация
    if not self.onGround then
        self.vy += self.gravity
        if self.vy > self.maxFallSpeed then
            self.vy = self.maxFallSpeed
        end
    end

    -- Горизонтальное движение
    if self.vx ~= 0 then
        local actualX, actualY, collisions = self:moveWithCollisions(self.x + self.vx, self.y)
    end

    -- Вертикальное движение
    if self.vy ~= 0 then
        local actualX, actualY, collisions, length = self:moveWithCollisions(self.x, self.y + self.vy)
        
        self.onGround = false
        
        -- Проверка коллизий
        if length > 0 then
            for i = 1, length do
                local collision = collisions[i]
                -- Если столкнулись снизу (normal.y == -1 означает что под нами пол)
                if collision.normal.y == -1 and self.vy > 0 then
                    self.vy = 0
                    self.onGround = true
                    self.jumping = false  -- Приземлились — прыжок завершён
                -- Если столкнулись сверху (ударились головой)
                elseif collision.normal.y == 1 and self.vy < 0 then
                    self.vy = 0
                    self.jumping = false
                end
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