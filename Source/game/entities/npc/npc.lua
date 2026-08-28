local pd  <const> = playdate
local gfx <const> = playdate.graphics

import "libs/AnimatedSprite"
import "libs/pdDialogue"

-- game/entities/npc/npc.lua
-- Простой NPC с диалогом (pdDialogue).
-- Пока диалог открыт — время в игре стоит (см. isGamePaused() в game.lua).
-- Диалог начинается кнопкой A, пока игрок находится в триггере NPC
-- (см. Player:handleMovementAndCollisions и Game:handleInput).

class('NPC').extends(AnimatedSprite)

local imagetable = gfx.imagetable.new("images/npc-table-16-17")
assert(imagetable, "NPC: не удалось загрузить images/npc-table-16-17")

local DEFAULT_TEXT = "..."

function NPC:init(x, y, entity)
    NPC.super.init(self, imagetable)

    self:addState("idle", 1, 1, {
        loop = true,
    })

    -- Текст задаётся в LDtk строковым полем Text у Entity "NPC"
    self._text = DEFAULT_TEXT
    if entity and entity.fields and entity.fields.Text and entity.fields.Text ~= "" then
        self._text = entity.fields.Text
    end

    self:setCenter(0.5, 1)
    self:moveTo(x, y)
    self:setZIndex(Z_INDEXES.NPC)

    -- Триггер шире и выше самого спрайта — диалог можно начать,
    -- немного не доходя вплотную до NPC
    self:setCollideRect(-6, 0, 10, 12)
    self:setTag(TAGS.NPC)
    self:add()

    self:changeState("idle")
    self:playAnimation()

    print("[NPC] spawned x=" .. x .. " y=" .. y)
end

function NPC:update()
    if isGamePaused() then return end
    self:updateAnimation()
end

-- Запускает диалог. Прячет подсказку "A" на время разговора
-- и возвращает её обратно, если игрок всё ещё в триггере после закрытия.
function NPC:startDialogue()
    if pdDialogue.DialogueBox.enabled then return end

    local player = Game.instance and Game.instance.player
    if player and player.promptHint then
        player.promptHint:hide()
    end

    pdDialogue.say(self._text, {
        onClose = function()
            if Game.instance then
                Game.instance._suppressNextInput = true
            end
            if player and player.promptHint and player._nearbyNPC then
                player.promptHint:show()
            end
        end
    })

    print("[NPC] диалог начат")
end