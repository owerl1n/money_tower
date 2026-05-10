local pd  <const> = playdate
local gfx <const> = playdate.graphics

-- game/levelComplete.lua
-- Рисуется из GameScene:draw() поверх всего.

class('LevelComplete').extends()

-- Настраивай текст и задержки здесь (в кадрах)
local LINES = {
    { text = "hold 100 coins", delay = 0  },
    { text = "hold 200 coins", delay = 90 },
}

local OFFSET_Y = 2  -- пикселей выше центра портала

function LevelComplete:init()
    self._active  = false
    self._portalX = 0
    self._portalY = 0
    self._timer   = 0
end

function LevelComplete:trigger(portalX, portalY)
    if self._active then return end
    self._active  = true
    self._portalX = portalX
    self._portalY = portalY
    self._timer   = 0
    print("[LevelComplete] triggered x=" .. portalX .. " y=" .. portalY)
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

    local drawX = math.floor(self._portalX)
    local baseY = math.floor(self._portalY - OFFSET_Y)

    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)

    for i = 1, #LINES do
        local line = LINES[i]
        if self._timer >= line.delay then
            local tw, th = gfx.getTextSize(line.text)
            -- строки снизу вверх: i=1 ближайшая к порталу, i=2 выше
            local lineY = baseY - (i - 1) * (th + 6)

            gfx.drawText(line.text, 10, 15)
        end
    end

    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end