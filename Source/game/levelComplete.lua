local pd  <const> = playdate
local gfx <const> = playdate.graphics

class('LevelComplete').extends()

local THRESHOLDS = { 10, 20 }  -- два порога, меняй под себя

-- координаты чисел, меняй под себя
local POS = {
    { x = 101,  y = 64 },
    { x = 102, y = 80 },
}

function LevelComplete:init()
    self._active  = false
    self._image   = gfx.image.new("images/level_finished")
    self._timer   = 0
end

function LevelComplete:trigger()
    if self._active then return end
    self._active = true
    self._timer  = 0
    print("[LevelComplete] triggered")
end

function LevelComplete:isActive()
    return self._active
end

function LevelComplete:update()
    if not self._active then return end
    self._timer += 1
end

function LevelComplete:draw()
    if not self._active then return end

    -- картинка по центру экрана
    gfx.setImageDrawMode(gfx.kDrawModeCopy)  -- сброс перед картинкой
    self._image:drawCentered(100, 60)

    gfx.setImageDrawMode(gfx.kDrawModeFillBlack)

    for i = 1, 2 do
        local collected = CoinManager.score
        local threshold = THRESHOLDS[i]
        local text = collected >= threshold and tostring(threshold) or tostring(collected)
        local tw, th = gfx.getTextSize(text)
        gfx.drawText(text, POS[i].x - tw / 2, POS[i].y - th / 2)
    end

    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end