local pd  <const> = playdate
local gfx <const> = playdate.graphics

import "game/core/assets"

class('LevelComplete').extends()

-- Позиции отрисовки очков/вопросов на картинке images/level_finished.
-- Порядок соответствует порядку порогов в self._thresholds.
local POS = {
    { x = 101, y = 64 },
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

    -- Пороги очков для звёзд этого уровня (см. game/core/scoreConfig.lua)
    self._thresholds = ScoreConfig.getStarThresholds(self._currentLevel)
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

-- Сколько звёзд заработано при текущем счёте
function LevelComplete:getStarsEarned()
    local score = TreasureManager.score
    local stars = 0
    for i = 1, #self._thresholds do
        if score >= self._thresholds[i] then
            stars = i
        end
    end
    return stars
end

function LevelComplete:update()
    if not self._active then return end
    self._timer += 1

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

    gfx.setImageDrawMode(gfx.kDrawModeFillBlack)

    local collected = TreasureManager.score

    for i = 1, #self._thresholds do
        local pos       = POS[i] or POS[#POS]
        local threshold = self._thresholds[i]

        -- Порог достигнут — показываем число порога.
        -- Не достигнут (в т.ч. если очков вообще 0) — показываем "?".
        local text = collected >= threshold and tostring(threshold) or "?"

        local tw, th    = ScoreFont:getTextWidth(text), ScoreFont:getHeight()
        ScoreFont:drawText(text, pos.x - tw / 2, pos.y - th / 2)
    end

    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end