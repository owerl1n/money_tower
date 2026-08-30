---@diagnostic disable: undefined-doc-name
-- game/ui/levelStatsPanel.lua
-- Общая отрисовка "порогов очков": число порога (или "?"), алмаз слева
-- от числа, если порог достигнут. Используется и в LevelComplete,
-- и в LevelSelectScene, чтобы вид был идентичным в обоих местах.

local gfx <const> = playdate.graphics

LevelStatsPanel = {}

---Рисует строки порогов с алмазами по заданным координатам.
---@param entries table Список записей вида { threshold=число, textX=, textY=, gemX=, gemY= }
---@param score number Текущий/сохранённый счёт для сравнения с порогами
---@param gemImage playdate.graphics.image Картинка алмаза
---@param font playdate.graphics.font Шрифт для чисел порогов
function LevelStatsPanel.draw(entries, score, gemImage, font)
    gfx.setImageDrawMode(gfx.kDrawModeFillBlack)

    for _, entry in ipairs(entries) do
        local reached = score >= entry.threshold
        local text    = reached and tostring(entry.threshold) or "?"

        local tw, th = font:getTextWidth(text), font:getHeight()
        font:drawTextAligned(text, entry.textX, entry.textY - th / 2, kTextAlignment.left)

        if reached and gemImage then
            local gw, gh = gemImage:getSize()
            gfx.setImageDrawMode(gfx.kDrawModeCopy)
            gemImage:draw(entry.gemX - gw / 2, entry.gemY - gh / 2)
            gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
        end
    end

    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

return LevelStatsPanel