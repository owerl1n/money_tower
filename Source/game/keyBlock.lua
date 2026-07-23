local pd  <const> = playdate
local gfx <const> = playdate.graphics

import "game/smokeEffect"
import "game/assets"

class('KeyBlock').extends(gfx.sprite)


KeyBlock._registry = {}

function KeyBlock:init(x, y)
    KeyBlock.super.init(self, Tileset[203])

    self:setCenter(0, 0)
    self:moveTo(x, y)
    self:setZIndex(Z_INDEXES.Hazard - 1)
    self:setCollideRect(0, 0, 16, 16)
    self:setTag(TAGS.KeyBlock)
    self:add()

    self._opened = false

    table.insert(KeyBlock._registry, self)

    print("[KeyBlock] spawned x=" .. x .. " y=" .. y)
end

-- Проигрывает дым и убирает блок (коллизии выключаются сразу,
-- чтобы игрок не застрял внутри, пока дым ещё виден)
function KeyBlock:open()
    if self._opened then return end
    self._opened = true

    self:setCollisionsEnabled(false)
    self:setVisible(false)

    SmokeEffect(self.x + 8, self.y + 8, "lockBlock")

    print("[KeyBlock] открыт/исчез at " .. self.x .. "," .. self.y)

    self:remove()
end

-- Вызывается при подборе ключа
function KeyBlock.openAll()
    for _, block in ipairs(KeyBlock._registry) do
        block:open()
    end
    KeyBlock._registry = {}
end

-- Вызывать при загрузке нового уровня (в Level:goToLevel),
-- иначе блоки со старого уровня останутся в реестре
function KeyBlock.resetRegistry()
    KeyBlock._registry = {}
end