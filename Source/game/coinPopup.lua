local pd  <const> = playdate
local gfx <const> = playdate.graphics

-- game/coinPopup.lua
-- Рисуется напрямую в GameScene:draw(), не спрайт.
-- Поэтому гарантированно поверх всех тайлов и спрайтов.

class('CoinPopup').extends()

local DISPLAY_FRAMES = 60   -- 1 секунда при 60 fps
local OFFSET_Y       = 18   -- пикселей выше центра игрока

function CoinPopup:init(player)
    self._player = player
    self._timer  = 0
    self._amount = 0
end

function CoinPopup:addCoins(amount)
    self._amount += amount
    self._timer   = DISPLAY_FRAMES
end

-- Вызывать каждый кадр из Game:update()
function CoinPopup:update()
    if self._timer > 0 then
        self._timer -= 1
        if self._timer == 0 then
            --self._amount = 0
        end
    end
end

-- Вызывать из GameScene:draw() — рисует поверх всего
function CoinPopup:draw()
    if self._timer <= 0 then return end

    -- Мигание в последние 20 кадров
    if self._timer <= 20 and self._timer % 4 < 2 then return end

    local text = tostring(self._amount)
    local p    = self._player

    local drawX = p.x
    local drawY = p.y - OFFSET_Y

    local tw, th = gfx.getTextSize(text)

    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned(
        text,
        math.floor(drawX),
        math.floor(drawY - th/2),
        kTextAlignment.center
    )
    gfx.setImageDrawMode(gfx.kDrawModeCopy)  -- сбрасываем после себя
end