local pd  <const> = playdate
local gfx <const> = playdate.graphics

class('LevelComplete').extends()

local THRESHOLDS = { 10, 20 }

local POS = {
    { x = 101,  y = 64 },
    { x = 102, y = 80 },
}

-- задержка перед тем как принимать ввод (чтобы не скипнуть случайно)
local INPUT_DELAY = 30  -- кадров

function LevelComplete:init(currentLevel, onNext, onRestart)
    self._active       = false
    self._image        = gfx.image.new("images/level_finished")
    self._timer        = 0
    self._inputReady   = false
    self._currentLevel = currentLevel or 1
    self._onNext       = onNext    -- callback: следующий уровень
    self._onRestart    = onRestart -- callback: рестарт
end

function LevelComplete:trigger()
    if self._active then return end
    self._active     = true
    self._timer      = 0
    self._inputReady = false
    print("[LevelComplete] triggered")
end

function LevelComplete:isActive()
    return self._active
end

function LevelComplete:update()
    if not self._active then return end
    self._timer += 1

    -- разрешаем ввод через INPUT_DELAY кадров
    if not self._inputReady and self._timer >= INPUT_DELAY then
        self._inputReady = true
    end

    if not self._inputReady then return end

    if pd.buttonJustPressed(pd.kButtonA) then
        self._active = false
        if self._onNext then self._onNext() end
    elseif pd.buttonJustPressed(pd.kButtonB) then
        self._active = false
        if self._onRestart then self._onRestart() end
    end
end

function LevelComplete:draw()
    if not self._active then return end

    self._image:drawCentered(100, 60)

    -- мигание подсказки после INPUT_DELAY
    -- if self._inputReady and (self._timer // 20) % 2 == 0 then
    --     gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
    --     gfx.drawTextAligned("A: next  B: restart", 100, 100, kTextAlignment.center)
    -- end

    gfx.setImageDrawMode(gfx.kDrawModeFillBlack)

    for i = 1, 2 do
        local collected = TreasureManager.score
        local threshold = THRESHOLDS[i]
        local text = collected >= threshold and tostring(threshold) or tostring(collected)
        local tw, th = gfx.getTextSize(text)
        gfx.drawText(text, POS[i].x - tw / 2, POS[i].y - th / 2)
    end

    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end