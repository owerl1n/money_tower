-- game/ui/levelStatsPanel.lua
local gfx <const> = playdate.graphics

LevelStatsPanel = {}

local DOT_SIZE = 1   -- размер одной точки в пикселях
local DOT_GAP  = 3   -- расстояние между точками (шаг), подстрой под вкус

-- Рисует ряд точек по горизонтали от startX до endX на высоте y (центр точки).
local function drawDots(startX, endX, y)
    if endX <= startX then return end

    gfx.setColor(gfx.kColorBlack)
    local x = startX
    while x < endX do
        gfx.fillRect(x, y - DOT_SIZE / 2, DOT_SIZE, DOT_SIZE)
        x += DOT_GAP
    end
end

---Рисует строки порогов: число слева, точки-пунктир, иконка справа.
---@param entries table Список записей:
---  { threshold=, textX=, textY=, gemX=, gemY=,
---    icon=опционально своя картинка вместо gemImage,
---    forceIcon=опционально true — показать иконку всегда, а не только при reached (для замка) }
---@param score number Текущий/сохранённый счёт
---@param gemImage playdate.graphics.image Картинка алмаза (иконка по умолчанию)
---@param font playdate.graphics.font Шрифт для чисел порогов
function LevelStatsPanel.draw(entries, score, gemImage, font)
    gfx.setImageDrawMode(gfx.kDrawModeFillBlack)

    for _, entry in ipairs(entries) do
        local reached = score >= entry.threshold
        local icon    = entry.icon or gemImage
        local showIcon = entry.forceIcon or reached

        -- Если иконка принудительная (замок) — числа не показываем, только "?"
        local text = (entry.forceIcon and "?") or (reached and tostring(entry.threshold) or "?")

        local tw, th = font:getTextWidth(text), font:getHeight()
        font:drawText(text, entry.textX, entry.textY - th / 2)

        -- ── Точки от конца текста до начала иконки ───────────────────────────
        local iw = icon and select(1, icon:getSize()) or 0
        local dotsStartX = entry.textX + tw + 3
        local dotsEndX   = entry.gemX - iw / 2 - 3
        drawDots(dotsStartX, dotsEndX, entry.textY)

        if showIcon and icon then
            local iw2, ih = icon:getSize()
            gfx.setImageDrawMode(gfx.kDrawModeCopy)
            icon:draw(entry.gemX - iw2 / 2, entry.gemY - ih / 2)
            gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
        end
    end

    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

return LevelStatsPanel