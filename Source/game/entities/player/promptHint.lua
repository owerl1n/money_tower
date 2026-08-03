local pd  <const> = playdate
local gfx <const> = playdate.graphics

-- game/entities/player/promptHint.lua
-- Подсказка-иконка кнопки A над головой игрока.
-- Показывается, пока игрок стоит в триггере NPC.
-- ScorePopup учитывает её видимость и поднимается выше (см. scorePopup.lua)

class('PromptHint').extends()

local OFFSET_Y = 18 -- совпадает с базовым офсетом ScorePopup

local buttonImage = gfx.image.new("images/a_button")
assert(buttonImage, "PromptHint: не удалось загрузить images/a_button")

function PromptHint:init(player)
    self._player  = player
    self._visible = false
end

function PromptHint:show()
    self._visible = true
end

function PromptHint:hide()
    self._visible = false
end

function PromptHint:isVisible()
    return self._visible
end

-- Нужно ScorePopup, чтобы понять, насколько подняться выше подсказки
function PromptHint:getHeight()
    local _, h = buttonImage:getSize()
    return h
end

-- Вызывать из Game.hud.draw(), поверх спрайтов
function PromptHint:draw()
    if not self._visible then return end

    local p = self._player
    local w, h = buttonImage:getSize()

    local drawX = math.floor(p.x - w / 2)
    local drawY = math.floor(p.y - OFFSET_Y - h / 2)

    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    buttonImage:draw(drawX, drawY)
end