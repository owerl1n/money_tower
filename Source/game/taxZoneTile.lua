local pd  <const> = playdate
local gfx <const> = playdate.graphics

-- game/taxZoneTile.lua
-- Один тайл декоративного слоя зоны налога с лёгким парением,
-- как у Treasure — та же идея, случайная фаза на каждый тайл,
-- чтобы они колыхались не синхронно.

class('TaxZoneTile').extends(gfx.sprite)

local FLOAT_AMPLITUDE = 1.5
local FLOAT_SPEED     = 0.05

function TaxZoneTile:init(x, y, image, zIndex)
    TaxZoneTile.super.init(self, image)

    self:setCenter(0, 0)
    self._baseX      = x
    self._baseY      = y
    self._floatPhase = math.random() * math.pi * 2

    self:moveTo(x, y)
    self:setZIndex(zIndex or (Z_INDEXES.Hazard - 5))
    self:setCollisionsEnabled(false) -- зона не блокирует, эту роль играет логика LDtk.has_tile_at
    self:add()
end

function TaxZoneTile:update()
    if isGamePaused() then return end

    self._floatPhase += FLOAT_SPEED
    local offsetY = math.sin(self._floatPhase) * FLOAT_AMPLITUDE
    self:moveTo(self._baseX, self._baseY + offsetY)
end